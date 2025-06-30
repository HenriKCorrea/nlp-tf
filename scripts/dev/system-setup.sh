#!/bin/bash

# Restore distro packages (will increase disk from 16MB to 1GB)
# Maybe try apt-get update && apt-get install -y --no-install-recommends \
unminimize

# Install necessary packages
apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    man \
    less \
    vim \
    nano \
    rsync

# Create a new user with sudo privileges
adduser --disabled-password --gecos "" developer
usermod -aG sudo developer
chage -d 0 developer # Force user to change password on first login
