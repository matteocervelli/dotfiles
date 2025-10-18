#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/detect-os.sh"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Dotfiles Installation"
log_info "Repository: $DOTFILES_DIR"

# Detect OS
OS=$(detect_os)
log_info "Detected OS: $OS"

# Run OS-specific bootstrap
case "$OS" in
    macos)
        log_info "Running macOS bootstrap..."
        "$SCRIPT_DIR/macos-bootstrap.sh"
        ;;
    ubuntu)
        log_info "Running Ubuntu bootstrap..."
        "$SCRIPT_DIR/ubuntu-bootstrap.sh"
        ;;
    *)
        log_error "Unsupported OS: $OS"
        log_info "Supported: macos, ubuntu"
        exit 1
        ;;
esac

# Backup existing configs
log_step "Backing up existing configurations"
if [ -f "$DOTFILES_DIR/scripts/backup/snapshot.sh" ]; then
    "$DOTFILES_DIR/scripts/backup/snapshot.sh"
else
    log_warning "Backup script not found, skipping..."
fi

# Stow packages
log_step "Installing dotfiles (stow packages)"
if [ -f "$DOTFILES_DIR/scripts/stow/stow-all.sh" ]; then
    "$DOTFILES_DIR/scripts/stow/stow-all.sh"
else
    log_error "Stow script not found: $DOTFILES_DIR/scripts/stow/stow-all.sh"
    exit 1
fi

# Health check
log_step "Running health checks"
if [ -f "$DOTFILES_DIR/scripts/health/check-all.sh" ]; then
    "$DOTFILES_DIR/scripts/health/check-all.sh"
else
    log_warning "Health check script not found, skipping..."
fi

log_success "Dotfiles installation complete!"
echo ""
log_info "Next steps:"
echo "  1. Restart your shell: exec \$SHELL"
echo "  2. Sign in to 1Password: eval \$(op signin)"
echo "  3. Configure Rclone: ./scripts/sync/setup-rclone.sh"
echo "  4. Run health check: make health"
