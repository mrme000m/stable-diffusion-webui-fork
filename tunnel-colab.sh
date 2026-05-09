#!/bin/bash

# Tunnel helper for Google Colab VM access via 136.114.50.82:2222
# Usage: Local: ./tunnel-colab.sh
#        Colab:  GH_TOKEN=xxx REPO=owner/repo ./tunnel-colab.sh

set -e

# Default repo - can be overridden via env var
REPO="${REPO:-mrme000m/stable-diffusion-webui-fork}"
SSH_DIR="$HOME/.colab-tunnel"

# Detect if running in Colab (multiple methods)
IN_COLAB=0
if [ -n "$COLAB_JUPYTER_IP" ] || [ -f "/content" ] || grep -q "googleusercontent" /etc/hosts 2>/dev/null; then
    IN_COLAB=1
fi

if [ "$IN_COLAB" = "1" ]; then
    echo "=== Setting up SSH server in Colab ==="
    
    # Get GH token from environment
    if [ -z "$GH_TOKEN" ]; then
        echo "Error: GH_TOKEN not set. Usage: GH_TOKEN=xxx REPO=owner/repo bash script.sh"
        exit 1
    fi
    
    # Install gh CLI if not present
    if ! command -v gh &>/dev/null; then
        echo "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install -y gh
    fi
    
    echo "Fetching SSH_PRIVATE_KEY from repo secrets..."
    SSH_KEY=$(gh secret view SSH_PRIVATE_KEY --repo "$REPO")
    
    mkdir -p ~/.ssh
    echo "$SSH_KEY" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519
    
    # Extract public key
    ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub
    
    # Install SSH server
    echo "Installing OpenSSH server..."
    sudo apt update -qq
    sudo apt install -y -qq openssh-server
    
    # Configure SSH for port 2222
    sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
    sudo sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
    
    # Restart SSH
    sudo service ssh restart 2>/dev/null || sudo /usr/sbin/sshd
    
    echo "✓ SSH server running on port 2222"
    echo ""
    echo "From your local machine, connect with:"
    echo "  ssh -i ~/.ssh/id_ed25519 -p 2222 m@136.114.50.82"
    
else
    # Local machine mode
    echo "=== Colab SSH Tunnel Setup (Local Mode) ==="
    
    # Try to detect repo, or use default
    if git rev-parse --git-dir > /dev/null 2>&1; then
        REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    fi
    
    if [ -z "$GH_TOKEN" ]; then
        read -p "Enter your GitHub Auth Token: " GH_TOKEN
        export GH_TOKEN
    fi
    
    echo "Fetching SSH_PRIVATE_KEY from repo secrets..."
    SSH_KEY=$(gh secret view SSH_PRIVATE_KEY --repo "$REPO")
    
    mkdir -p "$SSH_DIR"
    
    echo "$SSH_KEY" > "$SSH_DIR/id_ed25519"
    chmod 600 "$SSH_DIR/id_ed25519"
    touch "$SSH_DIR/known_hosts"
    
    cat > "$SSH_DIR/config" << CONFIG
Host colab-tunnel
    HostName 136.114.50.82
    Port 2222
    User m
    IdentityFile $SSH_DIR/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile $SSH_DIR/known_hosts
CONFIG
    
    echo "✓ SSH config created at $SSH_DIR/config"
    echo ""
    echo "Connect: ssh -F $SSH_DIR/config colab-tunnel"
fi
