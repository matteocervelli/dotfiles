#!/usr/bin/env bash
# =============================================================================
# Set Default Shell Script
# Sets the default shell for the current user (works for SSH, GUI, and local)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

# Configuration
DESIRED_SHELL="zsh"

# Detect the actual user (handle sudo)
if [[ -n "$SUDO_USER" ]]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="$USER"
fi

# Get the full path to the desired shell
get_shell_path() {
    local shell_name="$1"
    local shell_path=$(command -v "$shell_name" 2>/dev/null)

    if [[ -z "$shell_path" ]]; then
        log_error "Shell '$shell_name' not found in PATH"
        log_info "Install it first: sudo apt install $shell_name"
        exit 1
    fi

    echo "$shell_path"
}

# Check if shell is in /etc/shells
check_shell_in_etc_shells() {
    local shell_path="$1"

    if ! grep -q "^${shell_path}$" /etc/shells; then
        log_warning "Shell not in /etc/shells: $shell_path"
        log_info "Adding to /etc/shells..."
        echo "$shell_path" | sudo tee -a /etc/shells > /dev/null
        log_success "Added $shell_path to /etc/shells"
    else
        log_success "Shell is in /etc/shells: $shell_path"
    fi
}

# Get current shell
get_current_shell() {
    local current_shell=$(getent passwd "$TARGET_USER" | cut -d: -f7)
    echo "$current_shell"
}

# Set default shell using chsh
set_default_shell() {
    local shell_path="$1"
    local current_shell=$(get_current_shell)

    log_step "Setting Default Shell"
    log_info "Current shell: $current_shell"
    log_info "Desired shell: $shell_path"

    if [[ "$current_shell" == "$shell_path" ]]; then
        log_success "Shell already set to: $shell_path"
        return 0
    fi

    log_info "Changing default shell..."

    # Use chsh to change the shell
    # -s: specify shell
    if chsh -s "$shell_path" "$TARGET_USER"; then
        log_success "Default shell changed successfully!"
        log_info "Shell change will take effect:"
        log_info "  • New SSH sessions: immediately"
        log_info "  • GUI login: after logout/login"
        log_info "  • Current session: after reboot or new login"
    else
        log_error "Failed to change default shell"
        exit 1
    fi
}

# Verify shell change
verify_shell_change() {
    local expected_shell="$1"
    local actual_shell=$(get_current_shell)

    log_step "Verifying Shell Change"

    if [[ "$actual_shell" == "$expected_shell" ]]; then
        log_success "✅ Shell successfully changed!"
        log_info "User: $TARGET_USER"
        log_info "Shell: $actual_shell"
        echo ""
        log_info "The new shell will be active for:"
        log_info "  ✓ New SSH connections"
        log_info "  ✓ GUI sessions (after logout/login)"
        log_info "  ✓ Local terminal sessions (after reboot)"
        echo ""
        log_info "Test now:"
        log_info "  ssh $TARGET_USER@localhost"
        log_info "  echo \$SHELL"
        return 0
    else
        log_error "Shell change verification failed"
        log_info "Expected: $expected_shell"
        log_info "Actual:   $actual_shell"
        return 1
    fi
}

# Main function
main() {
    local shell_name="$DESIRED_SHELL"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --shell)
                shell_name="$2"
                shift 2
                ;;
            --help)
                cat << EOF
Set Default Shell Script

Usage:
  $0 [OPTIONS]

Options:
  --shell NAME    Shell to set as default (default: zsh)
  --help          Show this help message

Examples:
  # Set zsh as default
  $0

  # Set bash as default
  $0 --shell bash

  # Set fish as default
  $0 --shell fish

Description:
  This script sets the default shell for the current user across all access
  methods: SSH, GUI login, and local terminal sessions.

  The change is made by modifying /etc/passwd using chsh (change shell).

  Requirements:
  - Shell must be installed
  - Shell must be listed in /etc/shells
  - User must have permission to change shell

EOF
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                log_info "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    log_step "Default Shell Setup"
    log_info "User: $TARGET_USER"
    log_info "Desired shell: $shell_name"
    echo ""

    # Get shell path
    local shell_path=$(get_shell_path "$shell_name")
    log_success "Found shell: $shell_path"

    # Ensure shell is in /etc/shells
    check_shell_in_etc_shells "$shell_path"

    # Set default shell
    set_default_shell "$shell_path"

    # Verify change
    verify_shell_change "$shell_path"

    echo ""
    log_success "✅ Default shell setup complete!"
}

# Run main function
main "$@"
