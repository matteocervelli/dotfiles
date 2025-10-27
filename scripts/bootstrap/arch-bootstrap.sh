#!/usr/bin/env bash
# Arch Linux Bootstrap Script
# Automated setup for Arch Linux development environment with AUR support
#
# Usage:
#   ./scripts/bootstrap/arch-bootstrap.sh [OPTIONS]
#
# Options:
#   -h, --help           Show this help message
#   -v, --verbose        Show detailed output
#   --dry-run            Show what would be done without making changes
#   --with-packages      Install all packages from system/arch/packages.txt
#   --profile <name>     Use specific profile (future: arch-dev, arch-minimal)
#   --skip-aur           Skip AUR helper installation (pacman only)
#   --essential-only     Install only essential tools (stow, git, 1password, rclone)
#   --aur-helper <name>  Choose AUR helper: yay (default), paru, or trizen
#
# Example:
#   ./scripts/bootstrap/arch-bootstrap.sh                    # Minimal setup
#   ./scripts/bootstrap/arch-bootstrap.sh --with-packages    # Full package install
#   ./scripts/bootstrap/arch-bootstrap.sh --dry-run          # Preview actions
#   ./scripts/bootstrap/arch-bootstrap.sh --aur-helper paru  # Use paru instead of yay

set -euo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"
# shellcheck source=../utils/detect-os.sh
source "$PROJECT_ROOT/scripts/utils/detect-os.sh"

# Configuration
VERBOSE=0
DRY_RUN=0
WITH_PACKAGES=0
SKIP_AUR=0
ESSENTIAL_ONLY=0
PROFILE=""
AUR_HELPER="yay"

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Arch Linux Bootstrap Script - Automated Development Environment Setup

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help           Show this help message
    -v, --verbose        Show detailed output
    --dry-run            Preview actions without making changes
    --with-packages      Install all packages from system/arch/packages.txt
    --profile <name>     Use specific profile (future support)
    --skip-aur           Skip AUR helper installation (pacman only)
    --essential-only     Install only essential tools (quick setup)
    --aur-helper <name>  Choose AUR helper: yay (default), paru, or trizen

EXAMPLES:
    $0                          # Minimal setup (stow, git, 1password, rclone)
    $0 --with-packages          # Full development environment
    $0 --dry-run                # Preview what would be installed
    $0 --essential-only         # Quick essential-only setup
    $0 --aur-helper paru        # Use paru instead of yay

PHASES:
    1. OS verification (Arch Linux detection)
    2. System update (pacman -Syu)
    3. Essential tools (base-devel, stow, git)
    4. AUR helper installation (yay/paru/trizen)
    5. Dotfiles core (1Password CLI, rclone, yq, ImageMagick)
    6. Stow package deployment
    7. Optional: Full package installation (--with-packages)

REQUIREMENTS:
    - Arch Linux (rolling release)
    - sudo privileges
    - Internet connection
    - Base system already installed

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported
    3    Missing dependencies

ARCH-SPECIFIC:
    - Uses Pacman for official packages
    - Uses AUR helper (yay/paru) for community packages
    - Installs base-devel group (build tools)
    - Rolling release - always latest packages
    - Manual configuration expected

AUR HELPERS:
    - yay (default): Go-based, fast, actively maintained
    - paru: Rust-based alternative, similar features
    - trizen: Perl-based, older but stable

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
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --with-packages)
                WITH_PACKAGES=1
                shift
                ;;
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --skip-aur)
                SKIP_AUR=1
                shift
                ;;
            --essential-only)
                ESSENTIAL_ONLY=1
                shift
                ;;
            --aur-helper)
                AUR_HELPER="$2"
                if [[ ! "$AUR_HELPER" =~ ^(yay|paru|trizen)$ ]]; then
                    log_error "Invalid AUR helper: $AUR_HELPER (must be yay, paru, or trizen)"
                    exit 1
                fi
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

# Check if running on Arch Linux
check_os() {
    local os
    os=$(detect_os)

    if [[ "$os" != "arch" ]]; then
        log_error "This script must be run on Arch Linux (detected: $os)"
        log_info "For other distros, see: scripts/bootstrap/"
        exit 2
    fi

    # Get detailed Arch version
    if [[ -f /etc/os-release ]]; then
        local arch_version
        arch_version=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
        log_info "Running on: $arch_version"
    else
        log_warning "/etc/os-release not found"
    fi

    # Verify Pacman is available
    if ! command -v pacman &> /dev/null; then
        log_error "Pacman package manager not found"
        exit 3
    fi

    log_success "OS verification passed"
}

# Execute command with dry-run support
execute() {
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would execute: $*"
        return 0
    fi

    if [[ $VERBOSE -eq 1 ]]; then
        log_info "Executing: $*"
    fi

    "$@"
}

# =============================================================================
# Phase 1: System Update
# =============================================================================

update_system() {
    log_step "Phase 1: System Update"

    log_info "Synchronizing package databases and upgrading system..."
    log_warning "This may take several minutes on a fresh install"

    execute sudo pacman -Syu --noconfirm

    log_success "System updated"
}

# =============================================================================
# Phase 2: Essential Tools
# =============================================================================

install_essential_tools() {
    log_step "Phase 2: Essential Development Tools"

    # Check if base-devel group is installed
    if ! pacman -Qg base-devel &> /dev/null; then
        log_info "Installing base-devel group..."
        execute sudo pacman -S --noconfirm base-devel
    else
        log_success "base-devel already installed"
    fi

    # Essential packages
    local essential_packages=(
        "stow"
        "git"
        "curl"
        "wget"
        "ca-certificates"
    )

    log_info "Installing essential packages..."
    for package in "${essential_packages[@]}"; do
        if ! pacman -Q "$package" &> /dev/null 2>&1; then
            log_info "Installing $package..."
            execute sudo pacman -S --noconfirm "$package"
        else
            if [[ $VERBOSE -eq 1 ]]; then
                log_success "$package already installed"
            fi
        fi
    done

    log_success "Essential tools installed"
}

# =============================================================================
# Phase 3: AUR Helper Installation
# =============================================================================

install_aur_helper() {
    log_step "Phase 3: AUR Helper Installation"

    if [[ $SKIP_AUR -eq 1 ]]; then
        log_info "Skipping AUR helper installation (--skip-aur enabled)"
        return 0
    fi

    # Check if AUR helper is already installed
    if command -v "$AUR_HELPER" &> /dev/null; then
        log_success "$AUR_HELPER already installed"
        return 0
    fi

    log_info "Installing $AUR_HELPER from AUR..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would clone https://aur.archlinux.org/${AUR_HELPER}.git"
        log_info "[DRY-RUN] Would build and install $AUR_HELPER"
        return 0
    fi

    # Clone AUR helper repository
    local temp_dir="/tmp/${AUR_HELPER}-install"
    rm -rf "$temp_dir"
    git clone "https://aur.archlinux.org/${AUR_HELPER}.git" "$temp_dir"

    # Build and install
    cd "$temp_dir"
    makepkg -si --noconfirm

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    # Verify installation
    if command -v "$AUR_HELPER" &> /dev/null; then
        log_success "$AUR_HELPER installed successfully"
    else
        log_error "$AUR_HELPER installation failed"
        return 1
    fi
}

# =============================================================================
# Phase 4: Dotfiles Core Dependencies
# =============================================================================

install_1password_cli() {
    if command -v op &> /dev/null; then
        log_success "1Password CLI already installed"
        return 0
    fi

    log_info "Installing 1Password CLI from AUR..."

    if [[ $SKIP_AUR -eq 1 ]]; then
        log_warning "Cannot install 1Password CLI without AUR helper"
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would install: $AUR_HELPER -S --noconfirm 1password-cli"
        return 0
    fi

    # Install via AUR
    execute "$AUR_HELPER" -S --noconfirm 1password-cli
}

install_rclone() {
    if command -v rclone &> /dev/null; then
        log_success "Rclone already installed"
        return 0
    fi

    log_info "Installing Rclone..."
    execute sudo pacman -S --noconfirm rclone
}

install_yq() {
    if command -v yq &> /dev/null; then
        log_success "yq already installed"
        return 0
    fi

    log_info "Installing yq..."

    if [[ $SKIP_AUR -eq 1 ]]; then
        log_warning "Cannot install yq without AUR helper (not in official repos)"
        log_info "Manually installing yq binary..."

        local yq_arch
        # Detect architecture
        case "$(uname -m)" in
            x86_64)
                yq_arch="amd64"
                ;;
            aarch64|arm64)
                yq_arch="arm64"
                ;;
            *)
                log_error "Unsupported architecture: $(uname -m)"
                return 1
                ;;
        esac

        local yq_url="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${yq_arch}"

        if [[ $DRY_RUN -eq 0 ]]; then
            sudo wget -qO /usr/local/bin/yq "$yq_url"
            sudo chmod +x /usr/local/bin/yq
        else
            log_info "[DRY-RUN] Would download yq from $yq_url"
        fi
    else
        # Install via AUR
        execute "$AUR_HELPER" -S --noconfirm yq
    fi
}

install_imagemagick() {
    if command -v convert &> /dev/null; then
        log_success "ImageMagick already installed"
        return 0
    fi

    log_info "Installing ImageMagick..."
    execute sudo pacman -S --noconfirm imagemagick
}

install_dotfiles_core() {
    log_step "Phase 4: Dotfiles Core Dependencies"

    install_1password_cli
    install_rclone
    install_yq
    install_imagemagick

    log_success "Dotfiles core dependencies installed"
}

# =============================================================================
# Phase 5: Stow Package Deployment
# =============================================================================

deploy_stow_packages() {
    log_step "Phase 5: Stow Package Deployment"

    # Verify we're in dotfiles directory
    if [[ ! -f "$PROJECT_ROOT/CLAUDE.md" ]]; then
        log_error "Not in dotfiles directory (CLAUDE.md not found)"
        return 1
    fi

    # Core packages to deploy
    local stow_packages=(
        "zsh"
        "git"
        "ssh"
    )

    log_info "Deploying stow packages to home directory..."

    for package in "${stow_packages[@]}"; do
        local package_path="$PROJECT_ROOT/packages/$package"

        if [[ -d "$package_path" ]]; then
            log_info "Deploying package: $package"

            if [[ $DRY_RUN -eq 0 ]]; then
                cd "$PROJECT_ROOT/packages" || exit 1
                stow -t "$HOME" "$package" 2>&1 || {
                    log_warning "Stow conflict for $package (may already be deployed)"
                }
                cd - > /dev/null || exit 1
            else
                log_info "[DRY-RUN] Would deploy: stow -t $HOME $package"
            fi
        else
            log_warning "Package not found: $package_path"
        fi
    done

    # Set ZSH as default shell if installed
    if command -v zsh &> /dev/null; then
        local current_shell
        current_shell=$(basename "$SHELL")

        if [[ "$current_shell" != "zsh" ]]; then
            log_info "Setting ZSH as default shell..."
            execute sudo chsh -s "$(command -v zsh)" "$(whoami)"
        else
            log_success "ZSH already set as default shell"
        fi
    else
        log_info "Installing ZSH..."
        execute sudo pacman -S --noconfirm zsh
        execute sudo chsh -s "$(command -v zsh)" "$(whoami)"
    fi

    log_success "Stow packages deployed"
}

# =============================================================================
# Phase 6: Full Package Installation (Optional)
# =============================================================================

install_full_packages() {
    log_step "Phase 6: Full Package Installation"

    local packages_file="$PROJECT_ROOT/system/arch/packages.txt"

    if [[ ! -f "$packages_file" ]]; then
        log_warning "packages.txt not found at $packages_file"
        log_info "Skipping full package installation"
        return 0
    fi

    log_info "Installing packages from $packages_file..."
    log_warning "This may take 30-60 minutes depending on your connection"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would install packages from $packages_file"
        return 0
    fi

    # Read packages and install
    while IFS= read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^# ]] && continue

        log_info "Installing $package..."
        sudo pacman -S --noconfirm "$package" || {
            log_warning "Failed to install $package (may need AUR)"
            if [[ $SKIP_AUR -eq 0 ]] && command -v "$AUR_HELPER" &> /dev/null; then
                "$AUR_HELPER" -S --noconfirm "$package" || {
                    log_error "Failed to install $package from AUR"
                }
            fi
        }
    done < "$packages_file"

    log_success "Full package installation complete"
}

# =============================================================================
# Phase 7: Arch-Specific Information
# =============================================================================

arch_specific_info() {
    log_step "Phase 7: Arch-Specific Information"

    log_info "Rolling Release: Arch Linux uses a rolling release model"
    log_info "Regular updates: Run 'sudo pacman -Syu' frequently"

    if [[ $VERBOSE -eq 1 ]]; then
        # Show some system info
        log_info "Kernel: $(uname -r)"
        log_info "Architecture: $(uname -m)"

        if command -v pacman &> /dev/null; then
            local package_count
            package_count=$(pacman -Q | wc -l)
            log_info "Installed packages: $package_count"
        fi
    fi

    log_success "Arch-specific checks complete"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    echo "========================================================================"
    echo "  Arch Linux Bootstrap - Automated Development Environment Setup"
    echo "========================================================================"
    echo ""

    # Parse arguments
    parse_args "$@"

    # Show configuration
    if [[ $VERBOSE -eq 1 ]]; then
        log_info "Configuration:"
        log_info "  Dry run: $DRY_RUN"
        log_info "  With packages: $WITH_PACKAGES"
        log_info "  Essential only: $ESSENTIAL_ONLY"
        log_info "  Skip AUR: $SKIP_AUR"
        log_info "  AUR helper: $AUR_HELPER"
        [[ -n "$PROFILE" ]] && log_info "  Profile: $PROFILE"
    fi

    # Dry run warning
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
        echo ""
    fi

    # Execute phases
    check_os

    if [[ $ESSENTIAL_ONLY -eq 0 ]]; then
        update_system
    else
        log_info "Skipping system update (--essential-only)"
    fi

    install_essential_tools

    if [[ $SKIP_AUR -eq 0 ]]; then
        install_aur_helper
    fi

    install_dotfiles_core
    deploy_stow_packages

    if [[ $WITH_PACKAGES -eq 1 ]]; then
        install_full_packages
    else
        log_info ""
        log_info "Skipping full package installation"
        log_info "To install all packages, run:"
        log_info "  $0 --with-packages"
    fi

    if [[ $ESSENTIAL_ONLY -eq 0 ]]; then
        arch_specific_info
    fi

    # Success message
    echo ""
    echo "========================================================================"
    echo "  Bootstrap Complete!"
    echo "========================================================================"
    echo ""
    log_success "Arch Linux development environment setup successful"

    # Next steps
    echo ""
    log_info "Next steps:"
    echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
    echo "  2. Configure Rclone for R2: ./scripts/sync/setup-rclone.sh"
    echo "  3. Run health check: ./scripts/health/check-all.sh"

    if [[ $WITH_PACKAGES -eq 0 ]]; then
        echo "  4. Install all packages: $0 --with-packages"
    fi

    # Shell restart reminder
    if [[ $(basename "$SHELL") != "zsh" ]]; then
        echo ""
        log_warning "Shell changed to ZSH - restart terminal or run: exec zsh"
    fi

    # Dry run reminder
    if [[ $DRY_RUN -eq 1 ]]; then
        echo ""
        log_info "This was a dry-run. Run without --dry-run to apply changes"
    fi
}

# Run main function
main "$@"
