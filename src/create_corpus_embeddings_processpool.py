# %%
# Install python dependencies
#%pip install torch transformers huggingface_hub omegaconf datasets==2.16.1 
# Optinal python packages for better user experience
#%pip install ipywidgets nbconvert

# %%
# Import necessary libraries
import torch
import omegaconf
import collections
import os
import re
import gc
from pathlib import Path
from typing import Any
from collections import OrderedDict
from transformers import DPRContextEncoder, AutoTokenizer, DPRConfig, GPT2TokenizerFast
from huggingface_hub import hf_hub_download
from datasets import load_dataset, Dataset
from concurrent.futures import ProcessPoolExecutor, as_completed
import time

# Setup external services authentication
HF_TOKEN = os.getenv('HF_TOKEN')

# Configure cache settings
CACHE_DIR = Path("./cache")
CACHE_DIR.mkdir(exist_ok=True)
CORPUS_CACHE_DIR = CACHE_DIR / "corpus_embeddings"

# %%
def rename_keys_substring(ordered_dict: OrderedDict[str, Any], find_pattern, replace_pattern):
    """
    Rename keys in an OrderedDict by replacing substring occurrences using regular expressions.
    
    Args:
        ordered_dict: The OrderedDict to modify
        find_pattern: The regex pattern to find in keys
        replace_pattern: The replacement pattern (can include backreferences like \\1, \\2)
    
    Returns:
        New Mapping with renamed keys
    """
    new_dict = OrderedDict[str, Any]()
    compiled_pattern = re.compile(find_pattern)
    
    for key, value in ordered_dict.items():
        if not compiled_pattern.search(key):
            continue
            
        new_key = compiled_pattern.sub(replace_pattern, key)
        new_dict[new_key] = value
    return new_dict


# %%
def setup_model_on_device(device: str) -> tuple[DPRContextEncoder, GPT2TokenizerFast]:
    """
    Setup model on the specified device.

    Args:
        device: Device to load the model on, either 'cuda' or 'cpu'.

    Returns:
        Tuple containing the context encoder and tokenizer.
    """
    torch.serialization.add_safe_globals(
        [
            omegaconf.dictconfig.ContainerMetadata,
            omegaconf.dictconfig.DictConfig,
            omegaconf.base.Metadata,
            omegaconf.nodes.AnyNode,
            omegaconf.listconfig.ListConfig,
            collections.defaultdict,
            Any,
            dict,
            list,
            int,
        ]
    )

    # Load model state dict (shared across all GPUs)
    checkpoint_path = hf_hub_download(
        repo_id="NTU-NLP-sg/xCodeEval-nl-code-starencoder-ckpt-37",
        filename="dpr_biencoder.37.pt",
        repo_type="model",
        token=HF_TOKEN,
    )
    state_dict = torch.load(checkpoint_path, map_location=device)

    # Retrieve fine-tuned weights
    ctx_state_dict = rename_keys_substring(
        state_dict["model_dict"],
        r"ctx_model\.(embeddings|encoder)\.([Ll]ayer|token|word|position_embeddings)",
        r"ctx_encoder.bert_model.\1.\2",
    )

    # Initialize encoder
    pretrained_model_name = state_dict["encoder_params"]["encoder"][
        "pretrained_model_cfg"
    ]
    encoder_config = DPRConfig.from_pretrained(
        pretrained_model_name,
        token=HF_TOKEN,
    )

    ctx_encoder = DPRContextEncoder.from_pretrained(
        None, state_dict=ctx_state_dict, config=encoder_config, token=HF_TOKEN
    )
    ctx_encoder = ctx_encoder.to(device).eval()

    # Compile for optimization
    if hasattr(torch, "compile"):
        ctx_encoder = torch.compile(ctx_encoder, mode="default")

    # Initialize tokenizer
    tokenizer: GPT2TokenizerFast = AutoTokenizer.from_pretrained(
        pretrained_model_name, config=encoder_config
    )
    tokenizer.pad_token = tokenizer.eos_token

    return ctx_encoder, tokenizer

# %%
def process_shard_on_gpu(gpu_id: int, shard: Dataset) -> Dataset:
    """
    Process a single shard of the dataset on the specified GPU.
    
    Args:
        gpu_id: The ID of the GPU to use for processing
        shard: The dataset shard to process
    
    Returns:
        Dataset with embeddings added
    """
    print(f"GPU {gpu_id}: Starting processing of {len(shard)} documents")
    # Set device for this process
    deviceType = "cuda" if torch.cuda.is_available() else "cpu"
    device = f"{deviceType}:{gpu_id}"
    torch.cuda.set_device(gpu_id)
    
    # Load model on this specific GPU
    ctx_encoder_gpu, tokenizer_gpu = setup_model_on_device(device)
    
    # Create embedding function for this GPU
    def embed_codes_gpu(batch):
        inputs = tokenizer_gpu(
            batch["source_code"],
            padding="max_length",
            truncation=True,
            max_length=1024,
            return_tensors="pt"
        )
        inputs = {k: v.to(device, non_blocking=True) for k, v in inputs.items()}

        # TODO: Check performance if using float32 instead of bfloat16
        # bfloat16 is more memory efficient on GPUs like RTX 3090
        # but may have lower precision than float32
        with torch.no_grad(), torch.amp.autocast(device_type=deviceType, dtype=torch.float32, enabled=True):
            embeddings = ctx_encoder_gpu(**inputs).pooler_output
            embeddings_cpu = embeddings.detach().cpu().to(torch.float32).tolist()
            return {"embedding": embeddings_cpu}
    
    # Process the shard
    try:
        shard_with_embeddings = shard.map(
            embed_codes_gpu,
            batched=True,
            batch_size=48,
            desc=f"GPU {gpu_id}"
        )
        
        print(f"GPU {gpu_id}: Successfully processed {len(shard_with_embeddings)} documents")
        return shard_with_embeddings
        
    except Exception as e:
        print(f"GPU {gpu_id}: Error during processing: {e}")
        raise e
    # finally:
        # Clean up GPU memory
        # torch.cuda.empty_cache()

# %%
def process_with_processpool(corpus: Dataset):
    """
    Process the dataset using a process pool for true parallel execution.
    Each process gets its own CUDA context.
    """
    
    # Get number of available GPUs
    num_gpus = torch.cuda.device_count()
    print(f"Found {num_gpus} GPUs available")
    
    if num_gpus < 2:
        raise RuntimeError("At least 2 GPUs are required for this operation.")
    
    # Calculate shard sizes
    total_docs = len(corpus)
    docs_per_gpu = total_docs // num_gpus
    remainder = total_docs % num_gpus
    
    print(f"Total documents: {total_docs}")
    print(f"Documents per GPU: {docs_per_gpu}")
    print(f"Remainder documents: {remainder}")
    
    # Create shards and distribute workload across GPUs
    shards = []
    start_idx = 0
    for gpu_id in range(num_gpus):
        # Give remainder documents to first few GPUs
        shard_size = docs_per_gpu + (1 if gpu_id < remainder else 0)
        end_idx = start_idx + shard_size
        
        shard = corpus.select(range(start_idx, end_idx))
        shards.append((gpu_id, shard))
        
        print(f"GPU {gpu_id}: Processing documents {start_idx} to {end_idx-1} ({shard_size} docs)")
        start_idx = end_idx
    
    # Process shards in parallel using processes
    with ProcessPoolExecutor(max_workers=num_gpus) as executor:
        futures = []
        for gpu_id, shard in shards:
            future = executor.submit(process_shard_on_gpu, gpu_id, shard)
            futures.append((gpu_id, future))
        
        # Monitor progress
        print(f"[{time.strftime('%H:%M:%S')}] Starting parallel processing on {num_gpus} GPUs...")
        
        shard_results = [None] * num_gpus
        completed_count = 0
        
        for future in as_completed([f for _, f in futures]):
            # Find which GPU this future belongs to
            gpu_id = next(gid for gid, f in futures if f is future)
            
            try:
                result = future.result()
                shard_results[gpu_id] = result
                completed_count += 1
                print(f"[{time.strftime('%H:%M:%S')}] GPU {gpu_id} completed! ({completed_count}/{num_gpus} GPUs finished)")
            except Exception as e:
                print(f"[{time.strftime('%H:%M:%S')}] GPU {gpu_id} failed: {e}")
                raise e
        
        print(f"[{time.strftime('%H:%M:%S')}] All GPUs completed processing!")
        print(f"[{time.strftime('%H:%M:%S')}] Please wait for the main process to combine results...")
    
    # Combine all shard results
    print("Combining results from all GPUs...")
    combined_data = {}
    
    # Get all keys from first shard
    first_shard = shard_results[0]
    for key in first_shard.features.keys():
        combined_data[key] = []
    
    # Combine data from all shards
    for shard_result in shard_results:
        for key in combined_data.keys():
            combined_data[key].extend(shard_result[key])
    
    # Create final dataset
    corpus_with_embeddings = Dataset.from_dict(combined_data)
    
    print(f"Combined dataset created with {len(corpus_with_embeddings)} documents")
    return corpus_with_embeddings

# %%
# Check if cache exists and load, otherwise process corpus
if CORPUS_CACHE_DIR.exists():
    try:
        print(f"Loading corpus cache from {CORPUS_CACHE_DIR}")
        corpus_with_embeddings = Dataset.load_from_disk(str(CORPUS_CACHE_DIR))
        print(f"Cache loaded successfully. Documents: {len(corpus_with_embeddings)}")
    except Exception as e:
        print(f"Failed to load cache: {e}")
        print("Cache directory exists but contains invalid data. Recreating cache...")
        corpus_with_embeddings = None
else:
    corpus_with_embeddings = None

if corpus_with_embeddings is None:
    print("No cache found. Processing corpus...")
    
    # Load corpus dataset
    corpus = load_dataset(
        "NTU-NLP-sg/xCodeEval",
        "retrieval_corpus",
        trust_remote_code=True,
        split="test",
        revision="467d25a839086383794b58055981221b82c0d107",
        token=HF_TOKEN,
    )
    
    # Generate embeddings
    corpus_with_embeddings = process_with_processpool(corpus)  # Limit to first 1000 documents for testing
    
    print("Embeddings generated successfully!")
    print(f"Saving corpus cache to {CORPUS_CACHE_DIR}")
    corpus_with_embeddings.save_to_disk(str(CORPUS_CACHE_DIR))
    print("Cache saved successfully!")

# Display information about the processed corpus
print(f"\nCorpus information:")
print(f"Number of documents: {len(corpus_with_embeddings)}")
if len(corpus_with_embeddings) > 0:
    print(f"Embedding dimension: {len(corpus_with_embeddings[0]['embedding'])}")
    print(f"Sample document keys: {list(corpus_with_embeddings[0].keys())}")
    print(f"Sample source code (first 200 chars): {corpus_with_embeddings[0]['source_code'][:200]}...")


