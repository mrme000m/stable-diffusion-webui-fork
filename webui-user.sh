#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install ngrok for tunneling if not installed
if ! command -v ngrok &> /dev/null; then
    echo "Installing ngrok..."
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com bookworm main" | sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt update && sudo apt install ngrok -y
fi

# Configure ngrok with auth token from GitHub secrets
if command -v gh &> /dev/null && [[ -n "$GH_TOKEN" ]]; then
    echo "Configuring ngrok with auth token..."
    REPO="mrme000m/stable-diffusion-webui-fork"
    NGROK_TOKEN=$(gh secret view NGROK_AUTHTOKEN --repo "$REPO" 2>/dev/null)
    if [[ -n "$NGROK_TOKEN" ]]; then
        ngrok config add-authtoken "$NGROK_TOKEN"
        echo "Ngrok configured with auth token"
    fi
fi

# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
#clone_dir="stable-diffusion-webui"

# Commandline arguments for webui.py, for example: export COMMANDLINE_ARGS="--medvram --opt-split-attention"
export COMMANDLINE_ARGS="--skip-torch-cuda-test --precision full --no-half --use-cpu all --listen --skip-python-version-check"
export STABLE_DIFFUSION_REPO="https://github.com/w-e-w/stablediffusion.git"

# python3 executable
python_cmd="python3"

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
export venv_dir="-"

# Install tokenizers with --prefer-binary flag - this gets run BEFORE requirements.install
# We set an env var that launch.py can check
export PIP_PREFER_BINARY=1

# install command for torch
export TORCH_COMMAND="pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu"

# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
#export GFPGAN_PACKAGE=""

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
#export ACCELERATE="True"

# Uncomment to disable TCMalloc
#export NO_TCMALLOC="True"

###########################################

