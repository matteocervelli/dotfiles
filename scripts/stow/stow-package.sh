#!/usr/bin/env bash
#
# Stow Package Manager
# Wrapper around GNU Stow with --no-folding as default behavior
#
# Usage:
#   ./stow-package.sh install <package>    # Install package
#   ./stow-package.sh uninstall <package>  # Uninstall package
#   ./stow-package.sh restow <package>     # Re-install package
#   ./stow-package.sh -n install <package> # Dry-run mode
#
# Options:
#   -n, --dry-run    Simulate actions without making changes
#   -v, --verbose    Show detailed output
#   -h, --help       Show this help message

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
STOW_DIR="$DOTFILES_DIR/stow-packages"

# Default options
DRY_RUN=""
VERBOSE="-v"
TARGET_DIR="$HOME"

# Functions
usage() {
    cat << EOF
Stow Package Manager - Wrapper for GNU Stow with --no-folding

USAGE:
    $(basename "$0") [OPTIONS] COMMAND PACKAGE

COMMANDS:
    install PACKAGE      Install package (stow with --no-folding)
    uninstall PACKAGE    Uninstall package (stow -D)
    restow PACKAGE       Re-install package (stow -R with --no-folding)

OPTIONS:
    -n, --dry-run       Simulate actions without making changes
    -v, --verbose       Show detailed output (default)
    -q, --quiet         Suppress detailed output
    -t, --target DIR    Target directory (default: \$HOME)
    -h, --help          Show this help message

EXAMPLES:
    # Install shell package
    $(basename "$0") install shell

    # Dry-run install to see what would happen
    $(basename "$0") -n install shell

    # Uninstall git package
    $(basename "$0") uninstall git

    # Re-install cursor package (uninstall + install)
    $(basename "$0") restow cursor

ABOUT --no-folding:
    This script always uses --no-folding flag for GNU Stow.
    This means:
    - Creates real directories in target (e.g., ~/.config/shell/)
    - Creates individual symlinks for each file
    - Prevents entire directory symlinks (tree folding)
    - Ensures files remain as separate symlinks for clarity

WHY --no-folding:
    - Clearer visibility of what's symlinked
    - Easier to mix stowed and non-stowed files
    - Better control over individual files
    - GitHub repo remains single source of truth
EOF
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

validate_package() {
    local package="$1"
    local package_path="$STOW_DIR/$package"

    # Check if package directory exists
    if [ ! -d "$package_path" ]; then
        log_error "Package '$package' not found at: $package_path"
        log_info "Available packages:"
        ls -1 "$STOW_DIR" | sed 's/^/  - /'
        return 1
    fi

    # Check if package is empty (only has .stow-local-ignore or nothing)
    local file_count=$(find "$package_path" -type f ! -name '.stow-local-ignore' | wc -l)
    if [ "$file_count" -eq 0 ]; then
        log_warning "Package '$package' appears to be empty (no files to stow)"
        log_info "Skipping empty package..."
        return 2
    fi

    return 0
}

stow_install() {
    local package="$1"

    log_info "Installing package: $package"

    # Validate package
    if ! validate_package "$package"; then
        return $?
    fi

    # Build stow command
    local stow_cmd="stow --no-folding $VERBOSE $DRY_RUN -t \"$TARGET_DIR\" -d \"$STOW_DIR\" \"$package\""

    if [ -n "$DRY_RUN" ]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi

    # Execute stow
    log_info "Running: stow --no-folding $VERBOSE $DRY_RUN -d $STOW_DIR -t $TARGET_DIR $package"

    cd "$STOW_DIR"
    if stow --no-folding $VERBOSE $DRY_RUN -t "$TARGET_DIR" "$package" 2>&1; then
        if [ -z "$DRY_RUN" ]; then
            log_success "Package '$package' installed successfully"
        else
            log_success "Dry-run completed (no changes made)"
        fi
        return 0
    else
        log_error "Failed to install package '$package'"
        return 1
    fi
}

stow_uninstall() {
    local package="$1"

    log_info "Uninstalling package: $package"

    # Validate package exists (but allow empty packages for uninstall)
    if [ ! -d "$STOW_DIR/$package" ]; then
        log_error "Package '$package' not found at: $STOW_DIR/$package"
        return 1
    fi

    # Build stow command with -D flag
    log_info "Running: stow -D $VERBOSE $DRY_RUN -d $STOW_DIR -t $TARGET_DIR $package"

    cd "$STOW_DIR"
    if stow -D $VERBOSE $DRY_RUN -t "$TARGET_DIR" "$package" 2>&1; then
        if [ -z "$DRY_RUN" ]; then
            log_success "Package '$package' uninstalled successfully"
        else
            log_success "Dry-run completed (no changes made)"
        fi
        return 0
    else
        log_error "Failed to uninstall package '$package'"
        return 1
    fi
}

stow_restow() {
    local package="$1"

    log_info "Re-installing package: $package"

    # Validate package
    if ! validate_package "$package"; then
        return $?
    fi

    # Build stow command with -R flag (restow = uninstall + install)
    log_info "Running: stow -R --no-folding $VERBOSE $DRY_RUN -d $STOW_DIR -t $TARGET_DIR $package"

    cd "$STOW_DIR"
    if stow -R --no-folding $VERBOSE $DRY_RUN -t "$TARGET_DIR" "$package" 2>&1; then
        if [ -z "$DRY_RUN" ]; then
            log_success "Package '$package' re-installed successfully"
        else
            log_success "Dry-run completed (no changes made)"
        fi
        return 0
    else
        log_error "Failed to re-install package '$package'"
        return 1
    fi
}

# Parse arguments
COMMAND=""
PACKAGE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run)
            DRY_RUN="-n"
            shift
            ;;
        -v|--verbose)
            VERBOSE="-v"
            shift
            ;;
        -q|--quiet)
            VERBOSE=""
            shift
            ;;
        -t|--target)
            TARGET_DIR="$2"
            shift 2
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
            if [ -z "$PACKAGE" ]; then
                PACKAGE="$1"
            else
                log_error "Unknown argument: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$COMMAND" ]; then
    log_error "Command required (install, uninstall, or restow)"
    echo ""
    usage
    exit 1
fi

if [ -z "$PACKAGE" ]; then
    log_error "Package name required"
    echo ""
    usage
    exit 1
fi

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    log_error "GNU Stow is not installed"
    log_info "Install with: brew install stow"
    exit 1
fi

# Execute command
case $COMMAND in
    install)
        stow_install "$PACKAGE"
        ;;
    uninstall)
        stow_uninstall "$PACKAGE"
        ;;
    restow)
        stow_restow "$PACKAGE"
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
