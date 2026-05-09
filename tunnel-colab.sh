#!/bin/bash

# Tunnel helper for Google Colab VM access via 136.114.50.82:2222
# Usage: Locally: ./tunnel-colab.sh
#        In Colab: GH_TOKEN=xxx ./tunnel-colab.sh (runs server setup mode)

set -e

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
SSH_DIR="$HOME/.colab-tunnel"

# Detect if running in Colab
if [ -n "$COLAB_JUPYTER_IP" ] || grep -q "googleusercontent" /etc/hosts 2>/dev/null || [ -n "$IN_COLAB" ]; then
    echo "=== Setting up SSH server in Colab ==="
    
    # Get GH token from environment or prompt
    if [ -z "$GH_TOKEN" ]; then
        echo "Error: GH_TOKEN not set. Set it as env var: GH_TOKEN=xxx"
        exit 1
    fi
    
    # Install gh CLI if not present
    if ! command -v gh &>/dev/null; then
        echo "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo apt-add-repository https://cli.github.com/packages
        sudo apt update && sudo apt install -y gh
    fi
    
    # Fetch SSH public key from repo secrets
    echo "Fetching SSH keys from repo secrets..."
    SSH_KEY=$(gh secret view SSH_PRIVATE_KEY --repo "$REPO")
    
    mkdir -p ~/.ssh
    echo "$SSH_KEY" > ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519
    
    # Create authorized_keys for incoming SSH connections
    SSH_DIR="$HOME/.ssh"
    mkdir -p "$SSH_DIR"
    
    # Extract public key
    ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub
    
    # Install and configure SSH server
    sudo apt update -qq
    sudo apt install -y -qq openssh-server
    
    # Configure SSH to run on port 2222
    sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
    sudo sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    # Restart SSH service
    sudo service ssh restart || sudo /usr/sbin/sshd
    
    echo "✓ SSH server running on port 2222"
    echo "✓ Your public key is authorized"
    echo ""
    echo "From your local machine, connect with:"
    echo "  ssh -p 2222 -i ~/.ssh/id_ed25519 m@136.114.50.82"
    
else
    # Local machine mode
    echo "=== Colab SSH Tunnel Setup (Local Mode) ==="
    
    # Ask for GitHub auth token if not set
    if [ -z "$GH_TOKEN" ]; then
        read -p "Enter your GitHub Auth Token: " GH_TOKEN
        export GH_TOKEN
    fi
    
    # Fetch SSH private key from repo secrets
    echo "Fetching SSH_PRIVATE_KEY from repo secrets..."
    SSH_KEY=$(gh secret view SSH_PRIVATE_KEY --repo "$REPO")
    
    mkdir -p "$SSH_DIR"
    
    # Save SSH key
    echo "$SSH_KEY" > "$SSH_DIR/id_ed25519"
    chmod 600 "$SSH_DIR/id_ed25519"
    
    # Create known_hosts placeholder
    touch "$SSH_DIR/known_hosts"
    
    # SSH config for tunnel
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
    echo "=== Connect to Colab VM ==="
    echo "ssh -F $SSH_DIR/config colab-tunnel"
fi
