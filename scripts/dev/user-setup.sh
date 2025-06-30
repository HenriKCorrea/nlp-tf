#!/bin/bash

# Set script to exit on error and treat unset variables as an error
set -euo pipefail

# Navigate to user home directory
cd "$HOME" || exit

# Set environment variables
echo 'export HF_HOME="/workspace/.cache/huggingface"  # Default is ~/.cache/huggingface' >> ~/.bashrc 

# Install Miniconda for user if not already installed
if [ ! -d "$HOME/miniconda3" ]; then
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$HOME/miniconda3/miniconda.sh"
    bash "$HOME/miniconda3/miniconda.sh" -b -u -p "$HOME/miniconda3"
    rm "$HOME/miniconda3/miniconda.sh"
    source "$HOME/miniconda3/bin/activate"
    conda init --all
    conda deactivate
fi

# Clone the repository if it doesn't exist
if [ ! -d "nlp-tf" ]; then
    git clone https://github.com/henrikcorrea/nlp-tf.git
fi

# Navigate to the cloned repository
cd nlp-tf || exit

# Install Python dependencies using miniconda
if [ -f "requirement.txt" ]; then
    conda create -y -n nlp-tf-env python=3.9
    conda activate nlp-tf-env
    pip install -r requirement.txt
fi
