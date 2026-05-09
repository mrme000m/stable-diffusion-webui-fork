#!/bin/bash

# SSH Tunnel Setup for Colab VM
# Local: ./tunnel-colab.sh
# Colab: bash tunnel-colab.sh

set -e

REPO="${REPO:-mrme000m/stable-diffusion-webui-fork}"

# Detect Colab
IN_COLAB=0
if [ -n "$COLAB_JUPYTER_IP" ] || [ -d "/content" ] || grep -q "googleusercontent" /etc/hosts 2>/dev/null; then
    IN_COLAB=1
fi

if [ "$IN_COLAB" = "1" ]; then
    echo "=== Setting up SSH server in Colab ==="
    
    sudo apt update -qq && sudo apt install -y -qq openssh-server curl > /dev/null
    
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Fetch public key from repo
    PUBKEY_URL="https://raw.githubusercontent.com/${REPO}/refs/heads/master/colab-pubkey.txt"
    echo "Fetching public key from repo..."
    curl -s "$PUBKEY_URL" > ~/.ssh/authorized_keys
    
    if [ ! -s ~/.ssh/authorized_keys ]; then
        echo "Error: Could not fetch public key from $PUBKEY_URL"
        exit 1
    fi
    
    chmod 600 ~/.ssh/authorized_keys
    echo "✓ Public key configured"
    
    # Configure SSH server for port 2222
    sudo bash -c 'echo "Port 2222" >> /etc/ssh/sshd_config'
    sudo bash -c 'echo "PermitRootLogin yes" >> /etc/ssh/sshd_config'
    sudo bash -c 'echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config'
    
    sudo service ssh restart 2>/dev/null || sudo /usr/sbin/sshd
    
    echo "✓ SSH server running on port 2222"
    echo ""
    echo "From your local machine, connect with:"
    echo "  ssh -i ~/.ssh/id_ed25519 -p 2222 m@136.114.50.82"
    
else
    # Local mode
    echo "=== Local SSH Tunnel Setup ==="
    
    if git rev-parse --git-dir > /dev/null 2>&1; then
        REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    fi
    
    [ -z "$GH_TOKEN" ] && read -p "GitHub Token: " GH_TOKEN && export GH_TOKEN
    
    SSH_DIR="$HOME/.colab-tunnel"
    mkdir -p "$SSH_DIR"
    
    SSH_KEY=$(gh secret view SSH_PRIVATE_KEY --repo "$REPO")
    echo "$SSH_KEY" > "$SSH_DIR/id_ed25519"
    chmod 600 "$SSH_DIR/id_ed25519"
    
    cat > "$SSH_DIR/config" << CONFIG
Host colab-tunnel
    HostName 136.114.50.82
    Port 2222
    User m
    IdentityFile $SSH_DIR/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile $SSH_DIR/known_hosts
CONFIG
    
    touch "$SSH_DIR/known_hosts"
    
    echo "✓ SSH config created at $SSH_DIR/config"
    echo ""
    echo "Connect: ssh -F $SSH_DIR/config colab-tunnel"
fi
