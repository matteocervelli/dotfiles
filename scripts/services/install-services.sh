#!/usr/bin/env bash
#
# macOS Services Installation Script
# Installs Automator workflows to ~/Library/Services/ for Services menu integration
#
# Usage:
#   ./install-services.sh [OPTIONS]
#
# Options:
#   --essential-only     Install only essential workflows
#   --all                Install all workflows (default)
#   --dry-run            Show what would be installed without installing
#   --force              Overwrite existing workflows
#   --verbose            Show detailed output
#   -h, --help           Show this help message

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SERVICES_CONFIG="$DOTFILES_DIR/system/macos/services/services.yml"
SERVICES_BACKUP="$DOTFILES_DIR/system/macos/services"
TARGET_DIR="$HOME/Library/Services"

# Source utilities
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/../utils/detect-os.sh"

# Options
INSTALL_MODE="all"
DRY_RUN=false
FORCE=false
VERBOSE=false

# Statistics
INSTALLED_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

usage() {
    cat << EOF
macOS Services Installation Script

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    --essential-only     Install only essential workflows (4 workflows)
                        File to MD, File to TXT, MD to Rich Text, open-in-vscode

    --all                Install all workflows (6 workflows, default)
                        Includes: conversion tools, development tools, CDN helpers

    --dry-run            Preview what would be installed without making changes

    --force              Overwrite existing workflows (default: skip if installed)

    --verbose            Show detailed output including workflow names

    -h, --help           Show this help message

DESCRIPTION:
    This script installs Automator workflows from the dotfiles backup to
    ~/Library/Services/ for integration with macOS Services menu.

    Workflows are organized by category:
    - Conversion: File format converters (MD, TXT, Rich Text)
    - Development: Editor launchers (VS Code, Cursor)
    - CDN: Asset management helpers

    The script:
    - Copies .workflow bundles to ~/Library/Services/
    - Sets proper permissions (755 for directories, 644 for files)
    - Removes quarantine attributes (xattr)
    - Rebuilds Services menu cache
    - Tracks installation statistics

    Supported Platforms:
    - macOS: Full support with Services menu integration

EXAMPLES:
    # Install only essential workflows (fast, bootstrap)
    $(basename "$0") --essential-only

    # Preview installation
    $(basename "$0") --all --dry-run

    # Install all workflows
    $(basename "$0") --all

    # Force reinstall with verbose output
    $(basename "$0") --all --force --verbose

EXIT CODES:
    0 - Success
    1 - Error occurred
    2 - Invalid arguments

For more information, see: $DOTFILES_DIR/system/macos/services/README.md
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --essential-only)
            INSTALL_MODE="essential"
            shift
            ;;
        --all)
            INSTALL_MODE="all"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 2
            ;;
    esac
done

# Check if running on macOS
check_macos() {
    if [ "$(uname -s)" != "Darwin" ]; then
        log_error "This script must be run on macOS"
        log_info "macOS Services are only available on macOS"
        exit 1
    fi
}

# Check required tools
check_requirements() {
    local missing=false

    if ! command -v yq &> /dev/null; then
        log_error "yq is not installed"
        log_info "Install with: brew install yq"
        missing=true
    fi

    if [ "$missing" = true ]; then
        exit 1
    fi
}

# Validate configuration files
validate_config() {
    if [ ! -f "$SERVICES_CONFIG" ]; then
        log_error "Configuration file not found: $SERVICES_CONFIG"
        exit 1
    fi

    if [ ! -d "$SERVICES_BACKUP" ]; then
        log_error "Services backup directory not found: $SERVICES_BACKUP"
        exit 1
    fi
}

# Get workflows for installation mode
get_workflows() {
    local mode="$1"
    local workflows=()

    if [ "$mode" = "essential" ]; then
        # Essential workflows from services.yml
        workflows=(
            "File to MD.workflow"
            "File to TXT.workflow"
            "MD to Rich Text.workflow"
            "open-in-vscode.workflow"
        )
    else
        # All workflows
        workflows=(
            "File to MD.workflow"
            "File to TXT.workflow"
            "MD to Rich Text.workflow"
            "open-in-vscode.workflow"
            "Open in Cursor.workflow"
            "Retrieve CDN url.workflow"
        )
    fi

    printf '%s\n' "${workflows[@]}"
}

# Install a single workflow
install_workflow() {
    local workflow="$1"
    local source="$SERVICES_BACKUP/$workflow"
    local target="$TARGET_DIR/$workflow"

    if [ ! -d "$source" ]; then
        log_error "Workflow not found: $workflow"
        ((FAILED_COUNT++))
        return 1
    fi

    # Check if already installed
    if [ -d "$target" ] && [ "$FORCE" = false ]; then
        if [ "$VERBOSE" = true ]; then
            log_info "Skipping (already installed): $workflow"
        fi
        ((SKIPPED_COUNT++))
        return 0
    fi

    # Dry-run mode
    if [ "$DRY_RUN" = true ]; then
        if [ "$VERBOSE" = true ]; then
            log_info "Would install: $workflow"
        fi
        ((INSTALLED_COUNT++))
        return 0
    fi

    # Copy workflow
    if [ -d "$target" ]; then
        log_info "Overwriting: $workflow"
        rm -rf "$target"
    else
        if [ "$VERBOSE" = true ]; then
            log_info "Installing: $workflow"
        fi
    fi

    cp -R "$source" "$target" || {
        log_error "Failed to copy: $workflow"
        ((FAILED_COUNT++))
        return 1
    }

    # Set permissions
    chmod -R 755 "$target" || {
        log_warning "Failed to set permissions: $workflow"
    }

    # Remove quarantine attribute
    if xattr -d com.apple.quarantine "$target" 2>/dev/null; then
        if [ "$VERBOSE" = true ]; then
            log_info "Removed quarantine: $workflow"
        fi
    fi

    ((INSTALLED_COUNT++))
    return 0
}

# Refresh Services menu cache
refresh_services_cache() {
    if [ "$DRY_RUN" = true ]; then
        log_info "Would rebuild Services menu cache"
        return 0
    fi

    log_info "Rebuilding Services menu cache..."
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
        -kill -r -domain local -domain system -domain user &> /dev/null || {
        log_warning "Failed to rebuild Services cache (may require restart)"
    }
}

# Display statistics
show_statistics() {
    local total=$((INSTALLED_COUNT + SKIPPED_COUNT + FAILED_COUNT))
    local mode_text=""

    if [ "$INSTALL_MODE" = "essential" ]; then
        mode_text=" (essential mode)"
    else
        mode_text=" (all workflows)"
    fi

    echo ""
    log_step "Installation Statistics$mode_text"

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY-RUN MODE - No changes made"
    fi

    if [ "$INSTALLED_COUNT" -gt 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            log_success "Would install: $INSTALLED_COUNT workflow(s)"
        else
            log_success "Installed: $INSTALLED_COUNT workflow(s)"
        fi
    fi

    if [ "$SKIPPED_COUNT" -gt 0 ]; then
        log_info "Skipped: $SKIPPED_COUNT workflow(s) (already installed)"
    fi

    if [ "$FAILED_COUNT" -gt 0 ]; then
        log_error "Failed: $FAILED_COUNT workflow(s)"
    fi

    if [ "$DRY_RUN" = false ]; then
        echo ""
        log_info "Target directory: $TARGET_DIR"
        log_info "Workflows available in: Right-click → Services menu"

        if [ "$INSTALLED_COUNT" -gt 0 ]; then
            log_info "Tip: Restart Finder if workflows don't appear immediately"
            log_info "     Run: killall Finder"
        fi
    fi
}

# Verify installation
verify_installation() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi

    local installed=0
    local total=0

    while IFS= read -r workflow; do
        ((total++))
        if [ -d "$TARGET_DIR/$workflow" ]; then
            ((installed++))
        fi
    done < <(get_workflows "$INSTALL_MODE")

    if [ "$VERBOSE" = true ]; then
        echo ""
        log_step "Verification"
        log_info "Installed: $installed/$total workflows"
    fi
}

# Main installation function
main() {
    log_step "macOS Services Installation"

    # Pre-flight checks
    check_macos
    check_requirements
    validate_config

    # Create target directory if needed
    if [ ! -d "$TARGET_DIR" ] && [ "$DRY_RUN" = false ]; then
        log_info "Creating Services directory: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    fi

    # Display mode
    if [ "$INSTALL_MODE" = "essential" ]; then
        log_info "Mode: Essential workflows only (4 workflows)"
    else
        log_info "Mode: All workflows (6 workflows)"
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY-RUN: No changes will be made"
    fi

    echo ""
    log_step "Installing Workflows"

    # Install workflows
    while IFS= read -r workflow; do
        install_workflow "$workflow"
    done < <(get_workflows "$INSTALL_MODE")

    # Refresh Services cache
    if [ "$INSTALLED_COUNT" -gt 0 ]; then
        echo ""
        refresh_services_cache
    fi

    # Verify installation
    verify_installation

    # Show statistics
    show_statistics

    # Exit code
    if [ "$FAILED_COUNT" -gt 0 ]; then
        exit 1
    fi

    exit 0
}

# Run main function
main
