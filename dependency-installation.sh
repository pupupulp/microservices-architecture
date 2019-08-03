#!/bin/bash

# Setup docker key and repository
KEY_BASE=https://download.docker.com/linux/ubuntu/gpg \
    && curl -fsSL ${KEY_BASE} | apt-key add - \
    && apt-key fingerprint 0EBFCD88 \
    && add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"

# Update apt repositories
apt-get update

# Install dependencies
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    virtualbox

# Install docker
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io

# Install docker-compose
BASE="https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" \
    && curl -L ${BASE} -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Install docker-machine
BASE=https://github.com/docker/machine/releases/download/v0.16.0 \
    && curl -L ${BASE}/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine \
    && install /tmp/docker-machine /usr/local/bin/docker-machine

# Install docker plugin local-persist
BASE="https://raw.githubusercontent.com/CWSpear/local-persist/master/scripts/install.sh" \
    && curl -fsSL ${BASE} | bash