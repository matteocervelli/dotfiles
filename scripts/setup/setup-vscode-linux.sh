#!/usr/bin/env bash
################################################################################
# setup-vscode-linux.sh
#
# Setup VS Code on Linux with settings sync from dotfiles
#
# Features:
# - Install VS Code from Microsoft official repository
# - Stow VS Code settings from dotfiles (symlinks)
# - Install all extensions from synced list (92 extensions)
# - Verify installation and configuration
#
# Dual Setup:
# - Native VS Code on Linux (this script)
# - Remote SSH from macOS (already configured in Guide 2)
#
# Usage: ./scripts/setup/setup-vscode-linux.sh
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Check for required tools
check_requirements() {
    local missing=0

    if ! command -v stow >/dev/null 2>&1; then
        log_error "GNU Stow not found. Install it first:"
        echo "  sudo apt-get install stow"
        missing=1
    fi

    if [[ ! -d "$HOME/dev/projects/dotfiles" ]]; then
        log_error "Dotfiles repository not found at $HOME/dev/projects/dotfiles"
        log_info "Clone the repository or check shared folder mount"
        missing=1
    fi

    if [[ $missing -eq 1 ]]; then
        exit 1
    fi
}

log_section "VS Code Setup for Linux"
log_info "This script will:"
echo ""
echo "  1. Add Microsoft repository"
echo "  2. Install VS Code (official)"
echo "  3. Stow settings from dotfiles (symlinks)"
echo "  4. Install 92 extensions from synced list"
echo "  5. Verify installation"
echo ""
log_info "Estimated time: 10-15 minutes (extension installation)"
echo ""

read -p "Do you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installation cancelled"
    exit 0
fi

check_requirements

# Check for sudo
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    log_warning "Some operations require sudo privileges"
    log_info "You may be prompted for your password"
fi

# Install VS Code
log_section "Installing VS Code"

if command -v code >/dev/null 2>&1; then
    log_success "VS Code already installed: $(code --version | head -1)"
    read -p "Do you want to reinstall/update? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping VS Code installation"
        SKIP_VSCODE_INSTALL=true
    else
        SKIP_VSCODE_INSTALL=false
    fi
else
    SKIP_VSCODE_INSTALL=false
fi

if [[ "$SKIP_VSCODE_INSTALL" != "true" ]]; then
    log_info "Adding Microsoft GPG key and repository..."

    # Download Microsoft GPG key
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg

    # Install GPG key
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg

    # Add VS Code repository
    sudo sh -c 'echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

    # Clean up
    rm /tmp/packages.microsoft.gpg

    log_success "Microsoft repository added"

    # Update package lists
    log_info "Updating package lists..."
    sudo apt-get update

    # Install VS Code
    log_info "Installing VS Code..."
    sudo apt-get install -y code

    log_success "VS Code installed: $(code --version | head -1)"
fi

# Stow VS Code settings
log_section "Syncing VS Code Settings"

log_info "Stowing VS Code settings from dotfiles..."

DOTFILES_DIR="$HOME/dev/projects/dotfiles"
cd "$DOTFILES_DIR"

# Check if vscode package exists
if [[ ! -d "stow-packages/vscode" ]]; then
    log_error "VS Code stow package not found: stow-packages/vscode/"
    log_error "Make sure dotfiles repository is up to date"
    exit 1
fi

# Resolve actual path (in case of symlinks/mounts)
DOTFILES_REAL=$(readlink -f "$DOTFILES_DIR" || realpath "$DOTFILES_DIR" || pwd)
log_info "Using dotfiles at: $DOTFILES_REAL"

# Backup existing settings if they exist and are not symlinks
VSCODE_CONFIG="$HOME/.config/Code/User"
if [[ -d "$VSCODE_CONFIG" ]] && [[ ! -L "$VSCODE_CONFIG/settings.json" ]]; then
    log_warning "Existing VS Code settings found (not symlinks)"
    BACKUP_DIR="$HOME/.config/Code/User.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backing up to: $BACKUP_DIR"
    mv "$VSCODE_CONFIG" "$BACKUP_DIR"
    mkdir -p "$VSCODE_CONFIG"
    log_success "Backup created"
fi

# Stow vscode package with explicit absolute path
STOW_DIR="$(readlink -f "$DOTFILES_REAL/stow-packages" || realpath "$DOTFILES_REAL/stow-packages")"
log_info "Stow directory: $STOW_DIR"

cd "$STOW_DIR"
if stow -v -t ~ -d "$STOW_DIR" vscode 2>&1 | tee /tmp/vscode-stow.log; then
    log_success "VS Code settings stowed via stow command"
else
    log_warning "Stow command failed, falling back to manual symlinks"
    log_info "Creating symlinks manually..."

    # Create symlinks manually
    VSCODE_SRC="$STOW_DIR/vscode/.config/Code/User"
    VSCODE_DST="$HOME/.config/Code/User"

    mkdir -p "$VSCODE_DST"

    ln -sf "$VSCODE_SRC/settings.json" "$VSCODE_DST/settings.json"
    ln -sf "$VSCODE_SRC/keybindings.json" "$VSCODE_DST/keybindings.json"
    ln -sf "$VSCODE_SRC/extensions.txt" "$VSCODE_DST/extensions.txt"

    log_success "Manual symlinks created"
fi

# Verify symlinks
log_info "Verifying symlinks..."
if [[ -L "$HOME/.config/Code/User/settings.json" ]]; then
    log_success "settings.json: $(readlink $HOME/.config/Code/User/settings.json)"
else
    log_error "settings.json: Not a symlink!"
fi

if [[ -L "$HOME/.config/Code/User/keybindings.json" ]]; then
    log_success "keybindings.json: $(readlink $HOME/.config/Code/User/keybindings.json)"
else
    log_error "keybindings.json: Not a symlink!"
fi

if [[ -L "$HOME/.config/Code/User/extensions.txt" ]]; then
    log_success "extensions.txt: $(readlink $HOME/.config/Code/User/extensions.txt)"
else
    log_warning "extensions.txt: Not a symlink"
fi

# Install extensions
log_section "Installing VS Code Extensions"

EXTENSIONS_FILE="$HOME/.config/Code/User/extensions.txt"

if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    log_error "Extensions list not found: $EXTENSIONS_FILE"
    log_error "Expected from stow package"
    exit 1
fi

# Count total extensions
TOTAL_EXTENSIONS=$(grep -v '^#' "$EXTENSIONS_FILE" | grep -v '^$' | wc -l)
log_info "Found $TOTAL_EXTENSIONS extensions to install"
log_warning "This will take 10-15 minutes..."
echo ""

# Install extensions with progress
CURRENT=0
FAILED=()

while IFS= read -r ext; do
    # Skip comments and empty lines
    [[ "$ext" =~ ^#.*$ || -z "$ext" ]] && continue

    CURRENT=$((CURRENT + 1))
    echo -ne "\r${BLUE}[${CURRENT}/${TOTAL_EXTENSIONS}]${NC} Installing: ${ext}..."

    if code --install-extension "$ext" > /dev/null 2>&1; then
        echo -ne "\r${GREEN}[✓ ${CURRENT}/${TOTAL_EXTENSIONS}]${NC} Installed: ${ext}$(printf ' %.0s' {1..20})\n"
    else
        echo -ne "\r${RED}[✗ ${CURRENT}/${TOTAL_EXTENSIONS}]${NC} Failed: ${ext}$(printf ' %.0s' {1..20})\n"
        FAILED+=("$ext")
    fi
done < "$EXTENSIONS_FILE"

echo ""

# Report failed installations
if [[ ${#FAILED[@]} -gt 0 ]]; then
    log_warning "${#FAILED[@]} extension(s) failed to install:"
    for ext in "${FAILED[@]}"; do
        echo "  - $ext"
    done
    echo ""
    log_info "You can try installing them manually later:"
    echo "  code --install-extension <extension-id>"
else
    log_success "All extensions installed successfully!"
fi

# Verify installation
log_section "Verifying Installation"

# VS Code version
VSCODE_VERSION=$(code --version | head -1)
log_success "VS Code version: $VSCODE_VERSION"

# Installed extensions count
INSTALLED_COUNT=$(code --list-extensions | wc -l)
log_info "Extensions installed: $INSTALLED_COUNT / $TOTAL_EXTENSIONS"

if [[ $INSTALLED_COUNT -eq $TOTAL_EXTENSIONS ]]; then
    log_success "All extensions verified"
elif [[ $INSTALLED_COUNT -ge $((TOTAL_EXTENSIONS - 5)) ]]; then
    log_warning "Most extensions installed ($INSTALLED_COUNT / $TOTAL_EXTENSIONS)"
else
    log_warning "Some extensions missing ($INSTALLED_COUNT / $TOTAL_EXTENSIONS)"
fi

# Settings verification
if [[ -L "$HOME/.config/Code/User/settings.json" ]]; then
    log_success "Settings synced via symlink"
else
    log_warning "Settings not symlinked"
fi

# Final summary
log_section "Setup Complete!"
echo ""
log_success "VS Code native installation completed"
echo ""
echo "Configuration:"
echo "  ${GREEN}✓${NC} VS Code: $VSCODE_VERSION"
echo "  ${GREEN}✓${NC} Extensions: $INSTALLED_COUNT installed"
echo "  ${GREEN}✓${NC} Settings: Symlinked from dotfiles"
echo "  ${GREEN}✓${NC} Keybindings: Symlinked from dotfiles"
echo ""
echo "Launch VS Code:"
echo "  ${BLUE}code${NC}          - Open VS Code"
echo "  ${BLUE}code .${NC}        - Open current directory"
echo "  ${BLUE}code file.txt${NC} - Open specific file"
echo ""

# Remote SSH info
log_section "Remote SSH Access (from macOS)"
echo ""
log_info "Your macOS can also access this VM via VS Code Remote-SSH"
echo ""
echo "From macOS VS Code:"
echo "  1. Install extension: ${YELLOW}Remote - SSH${NC}"
echo "  2. Press: ${YELLOW}Cmd+Shift+P${NC}"
echo "  3. Type: ${YELLOW}Remote-SSH: Connect to Host${NC}"
echo "  4. Select: ${GREEN}ubuntu-dev${NC} (already configured in Guide 2)"
echo ""
echo "This gives you TWO ways to use VS Code:"
echo "  ${GREEN}✓${NC} Native: VS Code running directly in Linux GUI"
echo "  ${GREEN}✓${NC} Remote: VS Code on macOS editing Linux files via SSH"
echo ""

log_success "All done! Start coding! 🚀"
echo ""
