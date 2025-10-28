#!/usr/bin/env bash
# Complete ZSH Setup: Oh My Zsh + Powerlevel10k
# Run this after stow packages are deployed
#
# Usage:
#   ./scripts/setup-zsh-complete.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source logger if available
if [[ -f "$SCRIPT_DIR/utils/logger.sh" ]]; then
    # shellcheck source=utils/logger.sh
    source "$SCRIPT_DIR/utils/logger.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[✓] $*"; }
    log_warning() { echo "[!] $*"; }
    log_error() { echo "[✗] $*"; }
    log_step() { echo ""; echo "==> $*"; echo ""; }
fi

echo ""
echo "========================================================================"
echo "  Complete ZSH Setup - Oh My Zsh + Powerlevel10k"
echo "========================================================================"
echo ""

# Check if ZSH is installed
if ! command -v zsh &> /dev/null; then
    log_error "ZSH is not installed"
    log_info "Install with: sudo dnf install -y zsh  (Fedora)"
    log_info "           or: sudo apt install -y zsh  (Ubuntu)"
    exit 1
fi

log_success "ZSH found at: $(command -v zsh)"

# Check if .zshrc exists (from stow)
if [[ ! -f "$HOME/.zshrc" ]]; then
    log_warning ".zshrc not found in home directory"
    log_info "Attempting to deploy shell stow package..."

    # Clean up macOS metadata files first (if on Linux/other OS)
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_info "Cleaning up macOS metadata files..."
        find "$PROJECT_ROOT/stow-packages" -name ".DS_Store" -type f -delete 2>/dev/null || true
        find "$PROJECT_ROOT/stow-packages" -name "._*" -type f -delete 2>/dev/null || true
    fi

    # Try to stow the shell package
    if [[ -d "$PROJECT_ROOT/stow-packages/shell" ]]; then
        cd "$PROJECT_ROOT/stow-packages" || exit 1
        if stow -t "$HOME" shell 2>&1; then
            log_success "Shell package deployed successfully"
            cd - > /dev/null || exit 1
        else
            log_error "Failed to deploy shell package"
            log_info "Try manually:"
            log_info "  cd $PROJECT_ROOT/stow-packages"
            log_info "  stow -t ~ shell"
            exit 1
        fi
    else
        log_error "Shell stow package not found at: $PROJECT_ROOT/stow-packages/shell"
        exit 1
    fi
fi

log_success ".zshrc found (from stow packages)"

# Install Oh My Zsh
log_step "Installing Oh My Zsh"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_success "Oh My Zsh already installed"
else
    log_info "Downloading and installing Oh My Zsh..."

    # Backup existing .zshrc if Oh My Zsh installer would overwrite it
    if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
        log_warning "Backing up .zshrc to .zshrc.pre-oh-my-zsh"
        cp "$HOME/.zshrc" "$HOME/.zshrc.pre-oh-my-zsh"
    fi

    # Install Oh My Zsh (unattended mode)
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Restore our .zshrc if it was backed up
    if [[ -f "$HOME/.zshrc.pre-oh-my-zsh" ]]; then
        log_info "Restoring stow-managed .zshrc..."
        mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc"
    fi

    log_success "Oh My Zsh installed successfully"
fi

# Install Powerlevel10k theme
log_step "Installing Powerlevel10k Theme"

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

if [[ -d "$P10K_DIR" ]]; then
    log_success "Powerlevel10k already installed"
else
    log_info "Cloning Powerlevel10k repository..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    log_success "Powerlevel10k installed successfully"
fi

# Install Oh My Zsh plugins
log_step "Installing Oh My Zsh Plugins"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions
if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    log_success "zsh-autosuggestions already installed"
else
    log_info "Installing zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log_success "zsh-autosuggestions installed successfully"
fi

# zsh-syntax-highlighting
if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    log_success "zsh-syntax-highlighting already installed"
else
    log_info "Installing zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log_success "zsh-syntax-highlighting installed successfully"
fi

# Install recommended fonts (optional but highly recommended)
log_step "Font Recommendations"

log_info "Powerlevel10k requires a Nerd Font for icons"
log_info "Recommended fonts:"
log_info "  - MesloLGS NF (automatic in some terminals)"
log_info "  - JetBrains Mono Nerd Font"
log_info "  - Fira Code Nerd Font"
echo ""
log_info "Download from: https://www.nerdfonts.com/font-downloads"
log_info "Or install with Homebrew (macOS): brew install font-meslo-lg-nerd-font"

# Check if already using ZSH
log_step "Shell Configuration"

CURRENT_SHELL=$(basename "$SHELL")

if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    log_warning "Current shell is: $SHELL"
    log_info "To make ZSH your default shell, run:"
    log_info "  sudo chsh -s $(command -v zsh) $(whoami)"
    log_info "Then logout and login again"
else
    log_success "ZSH is already your default shell"
fi

# Final instructions
log_step "Setup Complete!"

echo ""
log_success "Oh My Zsh + Powerlevel10k installed successfully!"
echo ""
log_info "Next steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. Powerlevel10k configuration wizard will run automatically"
echo "  3. Or configure manually: p10k configure"
echo ""
log_info "Your .zshrc is managed by stow from:"
log_info "  $PROJECT_ROOT/stow-packages/shell/.zshrc"
echo ""
log_info "Powerlevel10k config is at:"
log_info "  $PROJECT_ROOT/stow-packages/shell/.p10k.zsh"
echo ""

# Offer to start ZSH now
if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    read -p "Start ZSH now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        exec zsh
    fi
fi
