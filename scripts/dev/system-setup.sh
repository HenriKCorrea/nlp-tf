#!/bin/bash

# Install necessary packages
apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    man \
    less \
    vim \
    nano \
    rsync \
    wget \
    htop \
    direnv \
    tmux

# Create a new user with sudo privileges
adduser --disabled-password --gecos "" developer
echo "developer:changeme" | chpasswd # Set initial password as "changeme"
usermod -aG sudo developer
chage -d 0 developer # Force user to change password on first login
