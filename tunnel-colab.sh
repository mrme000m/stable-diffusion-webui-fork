#!/bin/bash

# Tunnel helper for Google Colab VM access via 136.114.50.82:2222
# Usage: ./tunnel-colab.sh

set -e

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
SSH_DIR="$HOME/.colab-tunnel"

echo "=== Colab SSH Tunnel Setup ==="
echo "Repo: $REPO"

# Ask for GitHub auth token if not already set
if [ -z "$GH_TOKEN" ]; then
    read -p "Enter your GitHub Auth Token: " GH_TOKEN
    export GH_TOKEN
fi

# Fetch SSH private key from repo secrets
echo "Fetching SSH_PRIVATE_KEY from repo secrets..."
SSH_KEY=$(gh secret view SSH_PRIVATE_KEY --repo "$REPO")

# Create SSH config directory
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
echo ""
echo "=== With port forwarding (local 8888 → colab 8888) ==="
echo "ssh -F $SSH_DIR/config -L 8888:localhost:8888 colab-tunnel"
echo ""
echo "=== To configure the Colab VM ==="
echo "After connecting, run:"
echo "  sudo apt-get update"
echo "  sudo apt-get install -y <your-packages>"
echo "  # Make other config changes as needed"
