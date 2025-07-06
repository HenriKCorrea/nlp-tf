#!/bin/bash

# Ensure current conda environment is nlp_env
if [[ "$CONDA_DEFAULT_ENV" != "nlp_env" ]]; then
    echo "Error: Please activate the 'nlp_env' conda environment before running this script."
    echo "conda create -n nlp_env python=3.12 -y"
    echo "conda activate nlp_env"
    exit 1
fi

# Ensure correct execution path
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Install necessary Python packages
pip install torch transformers huggingface_hub omegaconf datasets==2.16.1

# Run the Python script to generate embeddings
python "$SCRIPT_DIR/create_corpus_embeddings_processpool.py"
