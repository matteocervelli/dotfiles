#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Installing Ubuntu Dependencies"

# Check if running on Ubuntu
if [ ! -f /etc/os-release ] || ! grep -q "ubuntu" /etc/os-release; then
    log_error "This script must be run on Ubuntu"
    exit 1
fi

# Update package lists
log_info "Updating package lists..."
sudo apt update

# Install GNU Stow
if ! command -v stow &> /dev/null; then
    log_info "Installing GNU Stow..."
    sudo apt install -y stow
else
    log_success "GNU Stow already installed"
fi

# Install 1Password CLI
if ! command -v op &> /dev/null; then
    log_info "Installing 1Password CLI..."

    # Add 1Password repository
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list

    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    sudo apt update && sudo apt install -y 1password-cli
else
    log_success "1Password CLI already installed"
fi

# Install Rclone
if ! command -v rclone &> /dev/null; then
    log_info "Installing Rclone..."
    sudo apt install -y rclone
else
    log_success "Rclone already installed"
fi

# Install yq (YAML processor)
if ! command -v yq &> /dev/null; then
    log_info "Installing yq..."
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
else
    log_success "yq already installed"
fi

# Install essential build tools
log_info "Installing build essentials..."
sudo apt install -y build-essential curl git

log_success "Ubuntu dependencies installed successfully!"
echo ""
log_info "Next steps:"
echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
echo "  2. Configure Rclone for R2: ./scripts/sync/setup-rclone.sh"
echo "  3. Run full installation: make install"
