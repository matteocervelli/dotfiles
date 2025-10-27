#!/usr/bin/env bash
#
# Check All - Comprehensive Health Check
# Verify all dependencies and dotfiles configuration
#
# Usage:
#   ./check-all.sh           # Run all health checks
#   ./check-all.sh -v        # Verbose output

set -e

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/../utils/detect-os.sh"
source "$SCRIPT_DIR/../utils/logger.sh"

# Options
VERBOSE=false
VERBOSE_FLAG=""

# Statistics
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0

usage() {
    cat << EOF
Check All - Comprehensive dotfiles health check

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    -v, --verbose    Show verbose output for all checks
    -h, --help       Show this help message

DESCRIPTION:
    This script runs a comprehensive health check covering:

    1. Operating System Detection
    2. Required Command Availability
    3. GNU Stow Symlink Verification
    4. Git Configuration

EXIT CODES:
    0 - All health checks passed
    1 - One or more health checks failed

EXAMPLES:
    # Quick health check
    $(basename "$0")

    # Verbose health check
    $(basename "$0") -v
EOF
}

# Track a check result
track_check() {
    local status="$1"  # passed, warning, failed
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    case "$status" in
        passed)
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            ;;
        warning)
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            ;;
        failed)
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            ;;
    esac
}

# Check if a command exists
check_command() {
    local cmd="$1"
    local description="$2"
    local required="${3:-true}"  # Default: required

    if command -v "$cmd" &> /dev/null; then
        log_success "$cmd installed"
        if [ "$VERBOSE" = true ]; then
            local version=$($cmd --version 2>&1 | head -n1 || echo "version unknown")
            log_info "  $version"
        fi
        track_check "passed"
        return 0
    else
        if [ "$required" = "true" ]; then
            log_error "$cmd not found"
            log_info "  $description"
            track_check "failed"
        else
            log_warning "$cmd not found (optional)"
            log_info "  $description"
            track_check "warning"
        fi
        return 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            VERBOSE_FLAG="-v"
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
log_step "Running Comprehensive Health Checks"
log_info "Dotfiles directory: $DOTFILES_DIR"
echo ""

# ============================================================================
# 1. Operating System Detection
# ============================================================================
log_step "1. Operating System"

OS=$(detect_os)
case "$OS" in
    macos|ubuntu)
        log_success "Detected OS: $OS (supported)"
        track_check "passed"
        ;;
    linux)
        log_warning "Detected OS: Generic Linux (partial support)"
        log_info "  Some features may require Ubuntu-specific packages"
        track_check "warning"
        ;;
    *)
        log_error "Detected OS: $OS (unsupported)"
        log_info "  Supported platforms: macOS, Ubuntu"
        track_check "failed"
        ;;
esac

if [ "$VERBOSE" = true ]; then
    log_info "  System: $(uname -s)"
    log_info "  Release: $(uname -r)"
    log_info "  Machine: $(uname -m)"
fi

echo ""

# ============================================================================
# 2. Required Commands
# ============================================================================
log_step "2. Required Commands"

# Essential commands
check_command "git" "Install with: brew install git (macOS) or apt install git (Ubuntu)"
check_command "stow" "Install with: brew install stow (macOS) or apt install stow (Ubuntu)"

# Dotfiles-specific tools
check_command "op" "Install 1Password CLI: https://developer.1password.com/docs/cli/get-started/"
check_command "rclone" "Install with: brew install rclone (macOS) or apt install rclone (Ubuntu)"
check_command "yq" "Install with: brew install yq (macOS) or wget yq binary (Ubuntu)"

# Optional but recommended
check_command "gh" "Install GitHub CLI: brew install gh (macOS) or apt install gh (Ubuntu)" "false"
check_command "curl" "Install with: brew install curl (macOS) or apt install curl (Ubuntu)" "false"
check_command "wget" "Install with: brew install wget (macOS) or apt install wget (Ubuntu)" "false"

echo ""

# ============================================================================
# 3. GNU Stow Symlink Verification
# ============================================================================
log_step "3. GNU Stow Symlinks"

if [ -f "$SCRIPT_DIR/check-stow.sh" ]; then
    log_info "Running symlink verification..."
    echo ""

    # Run check-stow.sh and capture exit code
    if "$SCRIPT_DIR/check-stow.sh" $VERBOSE_FLAG; then
        # check-stow.sh passed
        log_success "Symlink verification passed"
        track_check "passed"
    else
        stow_exit_code=$?
        log_error "Symlink verification failed (see details above)"
        track_check "failed"
    fi
else
    log_warning "check-stow.sh not found, skipping symlink checks"
    log_info "  Expected: $SCRIPT_DIR/check-stow.sh"
    track_check "warning"
fi

echo ""

# ============================================================================
# 4. Git Configuration
# ============================================================================
log_step "4. Git Configuration"

if command -v git &> /dev/null; then
    # Check git user name
    git_name=$(git config --global user.name 2>/dev/null || echo "")
    if [ -n "$git_name" ]; then
        log_success "Git user.name configured"
        if [ "$VERBOSE" = true ]; then
            log_info "  Name: $git_name"
        fi
        track_check "passed"
    else
        log_warning "Git user.name not configured"
        log_info "  Set with: git config --global user.name 'Your Name'"
        track_check "warning"
    fi

    # Check git user email
    git_email=$(git config --global user.email 2>/dev/null || echo "")
    if [ -n "$git_email" ]; then
        log_success "Git user.email configured"
        if [ "$VERBOSE" = true ]; then
            log_info "  Email: $git_email"
        fi
        track_check "passed"
    else
        log_warning "Git user.email not configured"
        log_info "  Set with: git config --global user.email 'your@email.com'"
        track_check "warning"
    fi

    # Check git default branch
    git_branch=$(git config --global init.defaultBranch 2>/dev/null || echo "")
    if [ "$git_branch" = "main" ]; then
        log_success "Git default branch: main"
        track_check "passed"
    else
        log_warning "Git default branch not set to 'main'"
        log_info "  Current: ${git_branch:-not set}"
        log_info "  Set with: git config --global init.defaultBranch main"
        track_check "warning"
    fi
else
    log_error "Git not installed (checked in previous step)"
    track_check "failed"
fi

echo ""

# ============================================================================
# 5. Font Installation
# ============================================================================
log_step "5. Font Installation"

if is_macos; then
    FONTS_DIR="$HOME/Library/Fonts"

    # Check essential fonts (terminal + professional)
    essential_fonts=(
        "MesloLGS NF Regular.ttf"
        "MesloLGS NF Bold.ttf"
        "MesloLGS NF Italic.ttf"
        "MesloLGS NF Bold Italic.ttf"
        "Lato-Regular.ttf"
        "Lato-Bold.ttf"
        "Raleway-VF.ttf"
    )

    missing_essential=()
    for font in "${essential_fonts[@]}"; do
        if [ ! -f "$FONTS_DIR/$font" ]; then
            missing_essential+=("$font")
        fi
    done

    if [ ${#missing_essential[@]} -eq 0 ]; then
        log_success "All essential fonts installed"
        if [ "$VERBOSE" = true ]; then
            log_info "  Terminal: MesloLGS NF (4 variants)"
            log_info "  Professional: Lato (2 variants) + Raleway"
        fi
        track_check "passed"
    else
        log_error "Missing ${#missing_essential[@]} essential fonts"
        for font in "${missing_essential[@]}"; do
            log_info "  ✗ $font"
        done
        log_info "  Install with: ./scripts/fonts/install-fonts.sh --essential-only"
        track_check "failed"
    fi

    # Count total custom fonts
    if [ "$VERBOSE" = true ]; then
        total_fonts=$(find "$FONTS_DIR" -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.pcf.gz" \) 2>/dev/null | wc -l | tr -d ' ')
        log_info "  Total custom fonts: $total_fonts"
    fi
else
    log_info "Font checks are macOS-specific, skipping on this platform"
    track_check "passed"
fi

echo ""

# ============================================================================
# Summary Report
# ============================================================================
log_step "Summary Report"
echo ""
echo "  Total checks:        $TOTAL_CHECKS"
echo "  ✓ Passed:            $PASSED_CHECKS"
echo "  ! Warnings:          $WARNING_CHECKS"
echo "  ✗ Failed:            $FAILED_CHECKS"
echo ""

# Determine overall status
if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
    log_success "All health checks passed!"
    echo ""
    log_info "Your dotfiles environment is correctly configured."
    exit 0
elif [ $FAILED_CHECKS -eq 0 ]; then
    log_warning "Health checks passed with warnings"
    echo ""
    log_info "Review the warnings above and address them if needed."
    log_info "Your system is functional but some optional features may be unavailable."
    exit 0
else
    log_error "Health checks failed"
    echo ""
    log_info "Address the failed checks above before proceeding."
    log_info ""
    log_info "Common fixes:"
    echo "  1. Install missing dependencies: ./scripts/bootstrap/install.sh"
    echo "  2. Re-stow packages: ./scripts/stow/stow-all.sh restow"
    echo "  3. Sign in to 1Password: eval \$(op signin)"
    echo "  4. Configure Git: git config --global user.name 'Your Name'"
    echo ""
    log_info "For detailed help, run individual checks:"
    echo "  - Symlinks only: ./scripts/health/check-stow.sh -v"
    echo "  - Full check (verbose): ./scripts/health/check-all.sh -v"
    exit 1
fi
