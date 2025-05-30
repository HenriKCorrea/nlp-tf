import datasets

retrieval_nl_code_dataset = datasets.load_dataset("NTU-NLP-sg/xCodeEval", "retrieval_nl_code", trust_remote_code=True)
print(retrieval_nl_code_dataset)

retrieval_corpus_code_dataset = datasets.load_dataset("NTU-NLP-sg/xCodeEval", "retrieval_corpus", trust_remote_code=True)
print(retrieval_corpus_code_dataset)
