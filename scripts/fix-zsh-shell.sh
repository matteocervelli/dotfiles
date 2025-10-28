#!/usr/bin/env bash
# Quick fix to set ZSH as default shell
# Run this on your Fedora VM if bootstrap didn't set ZSH correctly

set -e

echo "Fixing ZSH as default shell..."

# Get ZSH path
ZSH_PATH=$(command -v zsh)

if [[ -z "$ZSH_PATH" ]]; then
    echo "Error: ZSH not installed"
    echo "Install with: sudo dnf install -y zsh"
    exit 1
fi

echo "Found ZSH at: $ZSH_PATH"

# Add to /etc/shells if not present
if ! grep -q "^${ZSH_PATH}$" /etc/shells 2>/dev/null; then
    echo "Adding ZSH to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
else
    echo "ZSH already in /etc/shells"
fi

# Change shell
echo "Changing shell to ZSH..."
sudo chsh -s "$ZSH_PATH" "$(whoami)"

# Verify
if getent passwd "$(whoami)" | grep -q "$ZSH_PATH"; then
    echo "✓ ZSH successfully set as default shell"
    echo "✓ Logout and login again for changes to take effect"
else
    echo "✗ Failed to set ZSH as default shell"
    echo "Try manually: sudo chsh -s $ZSH_PATH"
    exit 1
fi

echo ""
echo "Current shell: $SHELL"
echo "After logout, your shell will be: $ZSH_PATH"
