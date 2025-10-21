#!/usr/bin/env bash
#
# Unstow All Packages
# Remove all stow package symlinks from the home directory
#
# Usage:
#   ./unstow-all.sh                # Unstow all packages (with confirmation)
#   ./unstow-all.sh -n             # Dry-run mode
#   ./unstow-all.sh --force        # Skip confirmation prompt

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
DRY_RUN_FLAG=""
VERBOSE_FLAG="-v"
FORCE=false

# Statistics
TOTAL_PACKAGES=0
SUCCESSFUL_PACKAGES=0
SKIPPED_PACKAGES=0
FAILED_PACKAGES=0

usage() {
    cat << EOF
Unstow All Packages - Batch uninstaller for all stow packages

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    -n, --dry-run    Simulate actions without making changes
    -q, --quiet      Suppress detailed output
    -f, --force      Skip confirmation prompt
    -h, --help       Show this help message

EXAMPLES:
    # Unstow all packages (with confirmation)
    $(basename "$0")

    # Dry-run to see what would be unstowed
    $(basename "$0") -n

    # Force unstow without confirmation
    $(basename "$0") --force

DESCRIPTION:
    This script removes all symlinks created by stow packages.
    It will ask for confirmation before proceeding unless --force is used.

WARNING:
    This operation will remove all dotfile symlinks managed by this
    repository. Make sure you have backups if needed.

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

    log_info "Processing: $package (uninstall)"

    # Run stow-package.sh script with uninstall command
    if "$STOW_PACKAGE_SCRIPT" $DRY_RUN_FLAG $VERBOSE_FLAG "uninstall" "$package"; then
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
            log_error "Failed to uninstall package: $package"
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

# Confirmation prompt
ask_confirmation() {
    if [ "$FORCE" = true ]; then
        return 0
    fi

    echo ""
    log_warning "WARNING: This will remove all dotfile symlinks managed by this repository!"
    echo ""
    echo "Packages to be unstowed:"
    for pkg in "${packages[@]}"; do
        echo "  - $pkg"
    done
    echo ""

    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled by user"
        exit 0
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
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
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
log_step "Unstow All Packages"
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

log_info "Found $TOTAL_PACKAGES package(s) to unstow"

# Ask for confirmation (unless dry-run or force)
if [ -z "$DRY_RUN_FLAG" ]; then
    ask_confirmation
fi

echo ""

# Process each package
for package in "${packages[@]}"; do
    process_package "$package" || true
    echo ""  # Empty line between packages
done

# Print summary
print_summary
exit_code=$?

# Final message
echo ""
if [ $exit_code -eq 0 ]; then
    if [ -z "$DRY_RUN_FLAG" ]; then
        log_success "All dotfile symlinks have been removed successfully!"
        echo ""
        log_info "Your home directory is now clean of managed dotfiles."
        log_info "To restore dotfiles, run: ./scripts/stow/stow-all.sh"
    else
        log_success "Dry-run completed successfully!"
        echo ""
        log_info "Run without -n flag to actually remove symlinks"
    fi
else
    log_error "Some packages failed to unstow. Check the output above for details."
fi

exit $exit_code
