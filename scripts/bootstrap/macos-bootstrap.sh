#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Installing macOS Dependencies"

# Check if running on macOS
if [ "$(uname -s)" != "Darwin" ]; then
    log_error "This script must be run on macOS"
    exit 1
fi

# Install Homebrew
if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    log_success "Homebrew already installed"
fi

# Update Homebrew
log_info "Updating Homebrew..."
brew update

# Install GNU Stow
if ! command -v stow &> /dev/null; then
    log_info "Installing GNU Stow..."
    brew install stow
else
    log_success "GNU Stow already installed"
fi

# Install 1Password CLI
if ! command -v op &> /dev/null; then
    log_info "Installing 1Password CLI..."
    brew install --cask 1password-cli
else
    log_success "1Password CLI already installed"
fi

# Install Rclone
if ! command -v rclone &> /dev/null; then
    log_info "Installing Rclone..."
    brew install rclone
else
    log_success "Rclone already installed"
fi

# Install yq (YAML processor)
if ! command -v yq &> /dev/null; then
    log_info "Installing yq..."
    brew install yq
else
    log_success "yq already installed"
fi

log_success "macOS dependencies installed successfully!"
echo ""
log_info "Next steps:"
echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
echo "  2. Configure Rclone for R2: ./scripts/sync/setup-rclone.sh"
echo "  3. Run full installation: make install"
