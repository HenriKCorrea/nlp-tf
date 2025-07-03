#!/bin/bash

# Set script to exit on error and treat unset variables as an error
set -euo pipefail

# Navigate to user home directory
cd "$HOME" || exit

# Set environment variables (Default is ~/.cache/huggingface' >> ~/.bashrc)
# echo 'export HF_HOME="/workspace/.cache/huggingface"' >> "$HOME/.bashrc"

# Install Miniconda for user if not already installed
if [ ! -d "$HOME/miniconda3" ]; then
    mkdir -p "$HOME/miniconda3"
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

# Reminder to set git credentials
echo "Please set your git credentials using 'git config --global user.name \"Your Name\"
