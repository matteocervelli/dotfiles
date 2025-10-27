#!/usr/bin/env bash
# Docker Container Bootstrap Script
# Minimal setup for container environments
#
# Usage:
#   ./scripts/bootstrap/docker-bootstrap.sh [--profile PROFILE]
#
# Profiles:
#   minimal    - Shell + Git only (default)
#   dev        - Minimal + development tools

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Configuration
PROFILE="${1:-minimal}"

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Docker Container Bootstrap Script

Minimal setup for containerized dotfiles environments.

USAGE:
    $0 [--profile PROFILE]

PROFILES:
    minimal    Shell + Git configuration only (default)
    dev        Minimal + Python + Node.js + dev tools

EXAMPLES:
    $0                    # Default minimal profile
    $0 --profile dev      # Development profile

ENVIRONMENT:
    This script is designed to run inside Docker containers.
    It assumes a minimal Ubuntu 24.04 base with essential packages.

EXIT CODES:
    0    Success
    1    General error
    2    Wrong environment (not in container)

EOF
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if running in container
check_container_environment() {
    if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
        log_warning "Not running in a container environment"
        log_info "This script is optimized for Docker/Podman containers"
    fi
}

# Apply minimal dotfiles (shell + git)
apply_minimal_dotfiles() {
    log_step "Applying minimal dotfiles..."

    cd "$PROJECT_ROOT"

    # Stow shell configuration
    if [ -d "stow-packages/shell" ]; then
        log_info "Installing shell configuration..."
        stow -t "$HOME" -d stow-packages shell
        log_success "Shell configuration installed"
    else
        log_warning "Shell package not found, skipping"
    fi

    # Stow git configuration
    if [ -d "stow-packages/git" ]; then
        log_info "Installing git configuration..."
        stow -t "$HOME" -d stow-packages git
        log_success "Git configuration installed"
    else
        log_warning "Git package not found, skipping"
    fi
}

# Apply dev dotfiles (minimal + dev-env)
apply_dev_dotfiles() {
    log_step "Applying development dotfiles..."

    # First apply minimal
    apply_minimal_dotfiles

    cd "$PROJECT_ROOT"

    # Stow dev-env if available
    if [ -d "stow-packages/dev-env" ]; then
        log_info "Installing dev-env configuration..."
        stow -t "$HOME" -d stow-packages dev-env || {
            log_warning "Some dev-env files may have conflicts, continuing..."
        }
        log_success "Dev-env configuration installed"
    else
        log_info "Dev-env package not found (optional for dev profile)"
    fi
}

# Verify installation
verify_installation() {
    log_step "Verifying installation..."

    local errors=0

    # Check shell
    if [ -f "$HOME/.zshrc" ]; then
        log_success "Shell configuration: OK"
    else
        log_error "Shell configuration: MISSING"
        ((errors++))
    fi

    # Check git
    if [ -f "$HOME/.config/git/config" ] || [ -f "$HOME/.gitconfig" ]; then
        log_success "Git configuration: OK"
    else
        log_error "Git configuration: MISSING"
        ((errors++))
    fi

    # Check ZSH
    if command -v zsh >/dev/null 2>&1; then
        log_success "ZSH: $(zsh --version)"
    else
        log_error "ZSH: NOT FOUND"
        ((errors++))
    fi

    # Check Git
    if command -v git >/dev/null 2>&1; then
        log_success "Git: $(git --version)"
    else
        log_error "Git: NOT FOUND"
        ((errors++))
    fi

    # Check Stow
    if command -v stow >/dev/null 2>&1; then
        log_success "GNU Stow: $(stow --version | head -n1)"
    else
        log_error "GNU Stow: NOT FOUND"
        ((errors++))
    fi

    # Additional checks for dev profile
    if [ "$PROFILE" = "dev" ]; then
        if command -v python3 >/dev/null 2>&1; then
            log_success "Python: $(python3 --version)"
        else
            log_warning "Python: NOT FOUND (expected for dev profile)"
        fi

        if command -v node >/dev/null 2>&1; then
            log_success "Node.js: $(node --version)"
        else
            log_warning "Node.js: NOT FOUND (expected for dev profile)"
        fi
    fi

    if [ $errors -gt 0 ]; then
        log_error "Installation verification failed with $errors errors"
        return 1
    fi

    log_success "Installation verification passed"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    parse_args "$@"

    log_step "Docker Container Bootstrap"
    log_info "Profile: $PROFILE"
    echo ""

    # Check environment
    check_container_environment

    # Apply dotfiles based on profile
    case "$PROFILE" in
        minimal)
            apply_minimal_dotfiles
            ;;
        dev)
            apply_dev_dotfiles
            ;;
        *)
            log_error "Unknown profile: $PROFILE"
            log_info "Available profiles: minimal, dev"
            exit 1
            ;;
    esac

    # Verify installation
    verify_installation

    # Final message
    log_success "Docker container bootstrap complete!"
    echo ""
    log_info "Container is ready with profile: $PROFILE"
    log_info "Default shell: $(echo $SHELL)"
    echo ""
}

# Run main function
main "$@"
