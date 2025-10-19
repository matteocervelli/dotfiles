#!/usr/bin/env bash
#
# Stow All Packages
# Install all stow packages in the stow-packages directory
#
# Usage:
#   ./stow-all.sh                # Install all packages
#   ./stow-all.sh -n             # Dry-run mode
#   ./stow-all.sh uninstall      # Uninstall all packages
#   ./stow-all.sh restow         # Re-install all packages

set -e

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
STOW_DIR="$DOTFILES_DIR/stow-packages"
STOW_PACKAGE_SCRIPT="$SCRIPT_DIR/stow-package.sh"

# Source logger if available
if [ -f "$SCRIPT_DIR/../utils/logger.sh" ]; then
    source "$SCRIPT_DIR/../utils/logger.sh"
else
    # Fallback logging functions (only if logger.sh not found)
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    log_step() { echo -e "${CYAN}==>${NC} $1"; }
    log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
    log_success() { echo -e "${GREEN}✓${NC} $1"; }
    log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
    log_error() { echo -e "${RED}✗${NC} $1" >&2; }
fi

# Default options
COMMAND="install"
DRY_RUN_FLAG=""
VERBOSE_FLAG="-v"

# Statistics
TOTAL_PACKAGES=0
SUCCESSFUL_PACKAGES=0
SKIPPED_PACKAGES=0
FAILED_PACKAGES=0

usage() {
    cat << EOF
Stow All Packages - Batch installer for all stow packages

USAGE:
    $(basename "$0") [OPTIONS] [COMMAND]

COMMANDS:
    install      Install all packages (default)
    uninstall    Uninstall all packages
    restow       Re-install all packages

OPTIONS:
    -n, --dry-run    Simulate actions without making changes
    -q, --quiet      Suppress detailed output
    -h, --help       Show this help message

EXAMPLES:
    # Install all packages
    $(basename "$0")

    # Dry-run to see what would be installed
    $(basename "$0") -n

    # Uninstall all packages
    $(basename "$0") uninstall

    # Re-install all packages
    $(basename "$0") restow

PACKAGE DETECTION:
    This script automatically detects all packages in:
    $STOW_DIR

    Empty packages (containing only .stow-local-ignore) are automatically skipped.
EOF
}

# Get all packages (directories in stow-packages/)
get_all_packages() {
    local packages=()

    # Find all directories in stow-packages (excluding hidden dirs)
    while IFS= read -r -d '' dir; do
        local package_name=$(basename "$dir")
        packages+=("$package_name")
    done < <(find "$STOW_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 | sort -z)

    echo "${packages[@]}"
}

# Process a single package
process_package() {
    local package="$1"
    local command="$2"

    log_info "Processing: $package ($command)"

    # Run stow-package.sh script
    if "$STOW_PACKAGE_SCRIPT" $DRY_RUN_FLAG $VERBOSE_FLAG "$command" "$package"; then
        SUCCESSFUL_PACKAGES=$((SUCCESSFUL_PACKAGES + 1))
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 2 ]; then
            # Package was skipped (empty)
            SKIPPED_PACKAGES=$((SKIPPED_PACKAGES + 1))
            return 0
        else
            # Package failed
            FAILED_PACKAGES=$((FAILED_PACKAGES + 1))
            log_error "Failed to $command package: $package"
            return 1
        fi
    fi
}

# Print summary report
print_summary() {
    echo ""
    log_step "Summary Report"
    echo ""
    echo "  Total packages:      $TOTAL_PACKAGES"
    echo "  ✓ Successful:        $SUCCESSFUL_PACKAGES"
    echo "  ⊘ Skipped (empty):   $SKIPPED_PACKAGES"
    echo "  ✗ Failed:            $FAILED_PACKAGES"
    echo ""

    if [ $FAILED_PACKAGES -eq 0 ]; then
        log_success "All packages processed successfully!"
        return 0
    else
        log_error "$FAILED_PACKAGES package(s) failed to process"
        return 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN_FLAG="-n"
            shift
            ;;
        -q|--quiet)
            VERBOSE_FLAG="-q"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        install|uninstall|restow)
            COMMAND="$1"
            shift
            ;;
        *)
            log_error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate dependencies
if [ ! -f "$STOW_PACKAGE_SCRIPT" ]; then
    log_error "stow-package.sh not found at: $STOW_PACKAGE_SCRIPT"
    exit 1
fi

if [ ! -x "$STOW_PACKAGE_SCRIPT" ]; then
    log_error "stow-package.sh is not executable"
    log_info "Run: chmod +x $STOW_PACKAGE_SCRIPT"
    exit 1
fi

# Main execution
log_step "Stow All Packages - $COMMAND"
log_info "Dotfiles directory: $DOTFILES_DIR"
log_info "Stow packages directory: $STOW_DIR"

if [ -n "$DRY_RUN_FLAG" ]; then
    log_warning "DRY-RUN MODE: No changes will be made"
fi

echo ""

# Get all packages
packages=($(get_all_packages))
TOTAL_PACKAGES=${#packages[@]}

if [ $TOTAL_PACKAGES -eq 0 ]; then
    log_warning "No packages found in $STOW_DIR"
    exit 0
fi

log_info "Found $TOTAL_PACKAGES package(s) to process"
echo ""

# Process each package
for package in "${packages[@]}"; do
    process_package "$package" "$COMMAND" || true
    echo ""  # Empty line between packages
done

# Print summary
print_summary
exit_code=$?

# Final message
echo ""
if [ $exit_code -eq 0 ]; then
    if [ -z "$DRY_RUN_FLAG" ]; then
        log_success "All dotfiles have been stowed successfully!"
        echo ""
        log_info "Next steps:"
        echo "  1. Restart your shell: exec \$SHELL"
        echo "  2. Verify configurations are loaded"
        echo "  3. Check symlinks: ls -la ~/"
    else
        log_success "Dry-run completed successfully!"
        echo ""
        log_info "Run without -n flag to apply changes"
    fi
else
    log_error "Some packages failed to process. Check the output above for details."
fi

exit $exit_code
