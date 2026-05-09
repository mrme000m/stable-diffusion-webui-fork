#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

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
