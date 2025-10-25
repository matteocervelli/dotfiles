#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/detect-os.sh"
source "$SCRIPT_DIR/../utils/logger.sh"

OS=$(detect_os)

log_step "Installing Auto-Update for Dotfiles"

case "$OS" in
    macos)
        PLIST="$HOME/Library/LaunchAgents/com.dotfiles.autoupdate.plist"

        log_info "Installing LaunchAgent..."

        # Create LaunchAgents directory if it doesn't exist
        mkdir -p "$HOME/Library/LaunchAgents"

        # Copy and customize plist
        cp "$DOTFILES_DIR/system/macos/launch-agents/com.dotfiles.autoupdate.plist" "$PLIST"
        sed -i '' "s|YOUR_USERNAME|$USER|g" "$PLIST"
        sed -i '' "s|/Users/.*/dev/projects/dotfiles|$DOTFILES_DIR|g" "$PLIST"

        # Load LaunchAgent
        launchctl unload "$PLIST" 2>/dev/null || true
        launchctl load "$PLIST"

        log_success "Auto-update enabled (every 30 minutes)"
        log_info "View logs: tail -f /tmp/dotfiles-autoupdate.log"
        log_info "Disable: launchctl unload $PLIST"
        ;;

    ubuntu)
        log_info "Installing systemd timer..."

        # Copy and customize systemd files
        sudo cp "$DOTFILES_DIR/system/ubuntu/systemd/dotfiles-autoupdate.service" /etc/systemd/system/
        sudo cp "$DOTFILES_DIR/system/ubuntu/systemd/dotfiles-autoupdate.timer" /etc/systemd/system/

        sudo sed -i "s|YOUR_USERNAME|$USER|g" /etc/systemd/system/dotfiles-autoupdate.service
        sudo sed -i "s|/home/.*/dev/projects/dotfiles|$DOTFILES_DIR|g" /etc/systemd/system/dotfiles-autoupdate.service

        # Reload and enable
        sudo systemctl daemon-reload
        sudo systemctl enable dotfiles-autoupdate.timer
        sudo systemctl start dotfiles-autoupdate.timer

        log_success "Auto-update enabled (every 30 minutes)"
        log_info "View logs: journalctl -u dotfiles-autoupdate -f"
        log_info "Disable: sudo systemctl stop dotfiles-autoupdate.timer"
        ;;

    *)
        log_error "Unsupported OS: $OS"
        exit 1
        ;;
esac
