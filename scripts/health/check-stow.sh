#!/usr/bin/env bash
#
# Check Stow Symlinks
# Verify that GNU Stow symlinks are correctly pointing to the dotfiles repository
#
# Usage:
#   ./check-stow.sh           # Check all symlinks
#   ./check-stow.sh -v        # Verbose output

set -e

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
STOW_DIR="$DOTFILES_DIR/stow-packages"

# Source logger
source "$SCRIPT_DIR/../utils/logger.sh"

# Options
VERBOSE=false

# Statistics
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0

usage() {
    cat << EOF
Check Stow Symlinks - Verify dotfiles symlink correctness

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    -v, --verbose    Show all checks including successful ones
    -h, --help       Show this help message

DESCRIPTION:
    This script verifies that GNU Stow has correctly created symlinks
    for all dotfiles packages. It checks that:

    1. Critical dotfiles are symlinks (not regular files)
    2. Symlinks point to the correct location in the dotfiles repo
    3. Symlinks are not broken

EXIT CODES:
    0 - All symlinks are correct
    1 - One or more symlink issues detected

EXAMPLES:
    # Quick check (only shows issues)
    $(basename "$0")

    # Verbose check (shows all symlinks)
    $(basename "$0") -v
EOF
}

# Check a single symlink
check_symlink() {
    local link="$1"
    local expected_target="$2"
    local package_name="$3"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ -L "$link" ]; then
        # It's a symlink - check if it points to the right place
        actual_target=$(readlink "$link")

        # Resolve the actual target to absolute path for comparison
        # GNU Stow creates relative symlinks, so we need to resolve them
        if [ -e "$link" ]; then
            # Symlink target exists - resolve to absolute path
            resolved_target=$(readlink -f "$link" 2>/dev/null || realpath "$link" 2>/dev/null || echo "")
        else
            # Broken symlink - can't resolve
            resolved_target=""
        fi

        # Check if resolved target matches expected target
        if [ "$resolved_target" = "$expected_target" ]; then
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            if [ "$VERBOSE" = true ]; then
                log_success "$link → $actual_target"
            fi
            return 0
        elif [ -z "$resolved_target" ]; then
            # Broken symlink
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            log_error "$link → $actual_target (BROKEN LINK)"
            log_info "  Fix: cd $DOTFILES_DIR/stow-packages && stow -R $package_name"
            return 1
        else
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            log_warning "$link → $actual_target"
            log_warning "  Resolves to: $resolved_target"
            log_warning "  Expected: $expected_target"
            log_info "  Fix: cd $DOTFILES_DIR/stow-packages && stow -R $package_name"
            return 1
        fi
    elif [ -e "$link" ]; then
        # File exists but is not a symlink
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        log_error "$link exists but is NOT a symlink"
        log_info "  Fix: mv $link ${link}.backup && cd $DOTFILES_DIR/stow-packages && stow $package_name"
        return 1
    else
        # File doesn't exist (package not stowed)
        WARNING_CHECKS=$((WARNING_CHECKS + 1))
        log_warning "$link does not exist"
        log_info "  Package '$package_name' may not be stowed"
        log_info "  Fix: cd $DOTFILES_DIR/stow-packages && stow $package_name"
        return 1
    fi
}

# Check if a directory exists in stow-packages
package_exists() {
    local package="$1"
    [ -d "$STOW_DIR/$package" ]
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
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

# Main execution
log_step "Checking Stow Symlinks"
log_info "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Define expected symlinks for each package
# Format: link_path|expected_target|package_name

declare -a SYMLINKS=(
    # Shell package
    "$HOME/.zshrc|$STOW_DIR/shell/.zshrc|shell"
    "$HOME/.bashrc|$STOW_DIR/shell/.bashrc|shell"
    "$HOME/.config/shell/aliases.sh|$STOW_DIR/shell/.config/shell/aliases.sh|shell"
    "$HOME/.config/shell/exports.sh|$STOW_DIR/shell/.config/shell/exports.sh|shell"
    "$HOME/.config/shell/functions.sh|$STOW_DIR/shell/.config/shell/functions.sh|shell"

    # Git package (XDG-compliant structure)
    "$HOME/.config/git/config|$STOW_DIR/git/.config/git/config|git"
    "$HOME/.config/git/ignore|$STOW_DIR/git/.config/git/ignore|git"
    "$HOME/.ssh/allowed_signers|$STOW_DIR/git/.ssh/allowed_signers|git"

    # SSH package
    "$HOME/.ssh/config|$STOW_DIR/ssh/.ssh/config|ssh"
    "$HOME/.ssh/config.d/01-defaults.conf|$STOW_DIR/ssh/.ssh/config.d/01-defaults.conf|ssh"
    "$HOME/.ssh/config.d/10-github.conf|$STOW_DIR/ssh/.ssh/config.d/10-github.conf|ssh"
    "$HOME/.ssh/config.d/20-tailscale.conf|$STOW_DIR/ssh/.ssh/config.d/20-tailscale.conf|ssh"

    # GitHub CLI package (if exists)
    "$HOME/.config/gh/config.yml|$STOW_DIR/gh/.config/gh/config.yml|gh"
)

# Check each symlink
ISSUES_FOUND=false

for entry in "${SYMLINKS[@]}"; do
    IFS='|' read -r link expected_target package <<< "$entry"

    # Skip check if package doesn't exist in stow-packages
    if ! package_exists "$package"; then
        if [ "$VERBOSE" = true ]; then
            log_info "Skipping $link (package '$package' not found)"
        fi
        continue
    fi

    # Check the symlink
    if ! check_symlink "$link" "$expected_target" "$package"; then
        ISSUES_FOUND=true
    fi
done

# Print summary
echo ""
log_step "Summary Report"
echo ""
echo "  Total checks:        $TOTAL_CHECKS"
echo "  ✓ Passed:            $PASSED_CHECKS"
echo "  ! Warnings:          $WARNING_CHECKS"
echo "  ✗ Failed:            $FAILED_CHECKS"
echo ""

if [ "$ISSUES_FOUND" = false ] && [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
    log_success "All symlinks are correct!"
    echo ""
    log_info "Your dotfiles are properly stowed and working correctly."
    exit 0
elif [ $FAILED_CHECKS -eq 0 ]; then
    log_warning "Some symlinks have warnings but no critical failures"
    echo ""
    log_info "Review the warnings above. Some packages may not be stowed."
    log_info "Run: cd $DOTFILES_DIR && ./scripts/stow/stow-all.sh"
    exit 0
else
    log_error "Found $FAILED_CHECKS critical symlink issue(s)"
    echo ""
    log_info "Review the errors above and apply suggested fixes."
    log_info "Common fixes:"
    echo "  1. Backup conflicting files: mv ~/.file ~/.file.backup"
    echo "  2. Re-stow packages: cd $DOTFILES_DIR && ./scripts/stow/stow-all.sh restow"
    echo "  3. Check for conflicts: cd $DOTFILES_DIR/stow-packages && stow -n -v shell"
    exit 1
fi
