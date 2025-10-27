#!/usr/bin/env bash
# =============================================================================
# VM ZSH Setup Script
# Install Oh My Zsh plugins and tools for VM environment
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "VM ZSH Environment Setup"
echo ""

# =============================================================================
# Install Oh My Zsh Plugins
# =============================================================================

log_step "Installing Oh My Zsh Plugins"

# zsh-autosuggestions
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
    log_info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    log_success "✅ zsh-autosuggestions installed"
else
    log_info "✓ zsh-autosuggestions already installed"
fi

# zsh-syntax-highlighting
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
    log_info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    log_success "✅ zsh-syntax-highlighting installed"
else
    log_info "✓ zsh-syntax-highlighting already installed"
fi

echo ""
log_success "✅ Oh My Zsh plugins installed!"

# =============================================================================
# Install CLI Tools
# =============================================================================

log_step "Installing CLI Tools"

# Check if eza is installed
if ! command -v eza &> /dev/null; then
    log_info "Installing eza..."
    sudo apt update
    sudo apt install -y eza
    log_success "✅ eza installed"
else
    log_info "✓ eza already installed"
fi

echo ""
log_success "✅ CLI tools installed!"

# =============================================================================
# Verify Installation
# =============================================================================

log_step "Verifying Installation"

# Check Oh My Zsh plugins
if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
    log_success "✓ zsh-autosuggestions: OK"
else
    log_error "✗ zsh-autosuggestions: MISSING"
fi

if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
    log_success "✓ zsh-syntax-highlighting: OK"
else
    log_error "✗ zsh-syntax-highlighting: MISSING"
fi

# Check eza
if command -v eza &> /dev/null; then
    log_success "✓ eza: $(eza --version | head -1)"
else
    log_error "✗ eza: NOT FOUND"
fi

echo ""
log_success "✅ VM ZSH environment setup complete!"
echo ""
log_info "Next steps:"
log_info "  1. Restart SSH daemon: sudo systemctl restart ssh"
log_info "  2. Exit and reconnect: exit && ssh ubuntu-dev"
log_info "  3. Verify shell: echo \$SHELL"
