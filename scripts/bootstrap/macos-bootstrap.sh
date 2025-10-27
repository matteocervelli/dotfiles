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

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    log_success "Oh My Zsh already installed"
fi

# Install zsh-autosuggestions plugin
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    log_info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
    log_success "zsh-autosuggestions already installed"
fi

# Install zsh-syntax-highlighting plugin
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    log_info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
    log_success "zsh-syntax-highlighting already installed"
fi

# Install Powerlevel10k theme
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    log_info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
else
    log_success "Powerlevel10k already installed"
fi

log_success "macOS dependencies installed successfully!"

# Setup SSH keys
log_step "SSH Key Setup"
log_info "Setting up device-specific SSH key from 1Password..."
echo ""

if eval $(op signin) 2>/dev/null; then
    "$SCRIPT_DIR/../setup-ssh-keys.sh" || {
        log_warning "SSH key setup skipped or failed"
        log_info "Run manually later: ./scripts/setup-ssh-keys.sh"
    }
else
    log_warning "Not signed in to 1Password - skipping SSH key setup"
    log_info "Sign in and run: ./scripts/setup-ssh-keys.sh"
fi

echo ""
log_info "Next steps:"
echo "  1. If SSH keys not set up: ./scripts/setup-ssh-keys.sh"
echo "  2. Configure Rclone for R2: ./scripts/sync/setup-rclone.sh"
echo "  3. Deploy shell configuration: cd ~/dev/projects/dotfiles && stow -t ~ -d stow-packages shell"
echo "  4. Run full installation: make install"
