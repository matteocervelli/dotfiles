#!/usr/bin/env bash
# Arch Linux Package Installation Script
# Installs packages from system/arch/packages.txt with AUR support
#
# Usage:
#   ./scripts/bootstrap/install-dependencies-arch.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Show what would be installed without installing
#   --skip-aur         Skip AUR packages (official repos only)
#   --essential-only   Install only essential packages (dev tools, git, stow)
#   --aur-helper       Specify AUR helper (yay|paru) [default: auto-detect]
#
# Example:
#   ./scripts/bootstrap/install-dependencies-arch.sh
#   ./scripts/bootstrap/install-dependencies-arch.sh --dry-run
#   ./scripts/bootstrap/install-dependencies-arch.sh --essential-only

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Configuration
VERBOSE=0
DRY_RUN=0
SKIP_AUR=0
ESSENTIAL_ONLY=0
AUR_HELPER=""
PACKAGE_FILE="$PROJECT_ROOT/system/arch/packages.txt"

# Essential packages (always install these first)
ESSENTIAL_PACKAGES=(
    "base-devel"
    "git"
    "curl"
    "wget"
    "stow"
    "ca-certificates"
    "gnupg"
)

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Arch Linux Package Installation Script

Installs packages from system/arch/packages.txt with AUR support.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help         Show this help message
    -v, --verbose      Show detailed output
    --dry-run          Preview installation without making changes
    --skip-aur         Skip AUR packages (install from official repos only)
    --essential-only   Install only essential packages (base-devel, git, stow)
    --aur-helper       Specify AUR helper (yay or paru) [default: auto-detect]

EXAMPLES:
    $0                      # Full installation with AUR
    $0 --dry-run            # Preview what would be installed
    $0 --essential-only     # Quick install of essential tools
    $0 --skip-aur           # Install only official packages

PACKAGE SOURCES:
    - Native Pacman packages: From system/arch/packages.txt
    - AUR packages: Via yay or paru (auto-installed if needed)
    - Flatpak apps: Installed separately where specified

REQUIREMENTS:
    - Arch Linux or Arch-based distro (Manjaro, EndeavourOS, etc.)
    - sudo privileges
    - Internet connection

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported
    3    Missing dependencies

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
            --skip-aur)
                SKIP_AUR=1
                shift
                ;;
            --essential-only)
                ESSENTIAL_ONLY=1
                shift
                ;;
            --aur-helper)
                if [[ -n "${2:-}" ]]; then
                    AUR_HELPER="$2"
                    shift 2
                else
                    log_error "Error: --aur-helper requires an argument"
                    exit 1
                fi
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate AUR helper if specified
    if [[ -n "$AUR_HELPER" ]] && [[ "$AUR_HELPER" != "yay" ]] && [[ "$AUR_HELPER" != "paru" ]]; then
        log_error "Invalid AUR helper: $AUR_HELPER (must be yay or paru)"
        exit 1
    fi
}

# Check if running on Arch Linux
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found - cannot verify OS"
        exit 2
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    case "$ID" in
        arch|manjaro|endeavouros|garuda|artix)
            log_info "Running on $NAME"
            ;;
        *)
            log_error "This script must be run on Arch Linux or Arch-based distro (detected: $ID)"
            exit 2
            ;;
    esac
}

# Detect or install AUR helper
setup_aur_helper() {
    if [[ $SKIP_AUR -eq 1 ]]; then
        log_info "Skipping AUR setup (--skip-aur)"
        return 0
    fi

    log_step "Setting up AUR helper..."

    # Auto-detect if not specified
    if [[ -z "$AUR_HELPER" ]]; then
        if command -v yay >/dev/null 2>&1; then
            AUR_HELPER="yay"
        elif command -v paru >/dev/null 2>&1; then
            AUR_HELPER="paru"
        fi
    fi

    # If already have an AUR helper, we're done
    if [[ -n "$AUR_HELPER" ]] && command -v "$AUR_HELPER" >/dev/null 2>&1; then
        log_success "Using AUR helper: $AUR_HELPER"
        return 0
    fi

    # Default to yay if nothing specified
    [[ -z "$AUR_HELPER" ]] && AUR_HELPER="yay"

    log_info "Installing AUR helper: $AUR_HELPER..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install $AUR_HELPER from AUR"
        return 0
    fi

    # Install AUR helper
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"

    case "$AUR_HELPER" in
        yay)
            git clone https://aur.archlinux.org/yay.git
            cd yay
            makepkg -si --noconfirm
            ;;
        paru)
            git clone https://aur.archlinux.org/paru.git
            cd paru
            makepkg -si --noconfirm
            ;;
    esac

    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "AUR helper $AUR_HELPER installed successfully"
}

# Optimize pacman configuration
optimize_pacman() {
    log_info "Optimizing pacman configuration..."

    local pacman_conf="/etc/pacman.conf"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would enable parallel downloads and color output"
        return 0
    fi

    # Backup original config
    if [[ ! -f "${pacman_conf}.backup" ]]; then
        sudo cp "$pacman_conf" "${pacman_conf}.backup"
    fi

    # Enable parallel downloads if not already enabled
    if ! grep -q "^ParallelDownloads" "$pacman_conf"; then
        sudo sed -i '/^#ParallelDownloads/c\ParallelDownloads = 5' "$pacman_conf"
        log_success "Enabled parallel downloads in pacman"
    fi

    # Enable color output
    if ! grep -q "^Color" "$pacman_conf"; then
        sudo sed -i 's/^#Color/Color/' "$pacman_conf"
        log_success "Enabled color output in pacman"
    fi

    # Enable verbose package lists
    if ! grep -q "^VerbosePkgLists" "$pacman_conf"; then
        sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' "$pacman_conf"
    fi

    log_success "Pacman optimizations applied"
}

# Install essential packages
install_essential_packages() {
    log_step "Installing essential packages..."

    local packages_to_install=()

    # Check which packages need installation
    for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
        if ! pacman -Q "$pkg" >/dev/null 2>&1; then
            packages_to_install+=("$pkg")
        fi
    done

    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log_success "All essential packages already installed"
        return 0
    fi

    log_info "Installing ${#packages_to_install[@]} essential packages..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install: ${packages_to_install[*]}"
    else
        # Update first
        sudo pacman -Sy

        # Install essential packages
        sudo pacman -S --needed --noconfirm "${packages_to_install[@]}"

        log_success "Essential packages installed"
    fi
}

# Install yq (YAML processor)
install_yq() {
    if command -v yq >/dev/null 2>&1; then
        log_success "yq already installed"
        return 0
    fi

    log_info "Installing yq (YAML processor)..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install yq from GitHub releases"
    else
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x /usr/local/bin/yq
        log_success "yq installed successfully"
    fi
}

# Install packages from package list
install_packages_from_list() {
    if [[ ! -f "$PACKAGE_FILE" ]]; then
        log_error "Package file not found: $PACKAGE_FILE"
        log_info "Run: ./scripts/apps/generate-linux-packages.sh"
        exit 1
    fi

    log_step "Installing packages from $PACKAGE_FILE..."

    # Read packages (skip comments and empty lines)
    local packages
    packages=$(grep -v '^#' "$PACKAGE_FILE" | grep -v '^$' || true)

    if [[ -z "$packages" ]]; then
        log_warning "No packages found in $PACKAGE_FILE"
        return 0
    fi

    local package_count
    package_count=$(echo "$packages" | wc -l | tr -d ' ')

    log_info "Found $package_count packages to install"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install the following packages:"
        echo "$packages" | head -20
        if [[ $package_count -gt 20 ]]; then
            echo "... and $((package_count - 20)) more packages"
        fi
        return 0
    fi

    # Install packages using pacman
    log_info "Installing packages (this may take a while)..."

    # Use --needed to skip already installed packages
    echo "$packages" | xargs sudo pacman -S --needed --noconfirm

    log_success "Installed $package_count packages"
}

# Install AUR packages
install_aur_packages() {
    if [[ $SKIP_AUR -eq 1 ]]; then
        log_info "Skipping AUR packages (--skip-aur)"
        return 0
    fi

    if [[ -z "$AUR_HELPER" ]] || ! command -v "$AUR_HELPER" >/dev/null 2>&1; then
        log_warning "AUR helper not available, skipping AUR packages"
        return 0
    fi

    log_step "Installing AUR packages..."

    # Common AUR packages from package-mappings.yml
    local aur_packages=(
        "visual-studio-code-bin"
        "google-chrome"
        "1password-cli"
        "lazygit"
        "lazydocker"
    )

    local installed_count=0

    for pkg in "${aur_packages[@]}"; do
        # Check if already installed
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            [[ $VERBOSE -eq 1 ]] && log_success "$pkg already installed (AUR)" || true
            continue
        fi

        log_info "Installing $pkg from AUR..."

        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY RUN] Would install: $AUR_HELPER -S --noconfirm $pkg"
        else
            "$AUR_HELPER" -S --noconfirm "$pkg" && ((installed_count++)) || log_warning "Failed to install $pkg"
        fi
    done

    if [[ $installed_count -gt 0 ]]; then
        log_success "Installed $installed_count AUR packages"
    else
        log_info "All AUR packages already installed or skipped"
    fi
}

# Setup Flatpak
setup_flatpak() {
    if command -v flatpak >/dev/null 2>&1; then
        log_success "Flatpak already installed"

        # Add Flathub if not already added
        if ! flatpak remote-list | grep -q flathub 2>/dev/null; then
            log_info "Adding Flathub repository..."
            if [[ $DRY_RUN -eq 0 ]]; then
                sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            fi
        fi
        return 0
    fi

    log_info "Installing Flatpak..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install flatpak and add Flathub"
    else
        sudo pacman -S --needed --noconfirm flatpak
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        log_success "Flatpak installed with Flathub repository"
    fi
}

# Post-installation steps
post_install() {
    log_step "Post-installation configuration..."

    # Install pyenv for Python version management
    if [[ ! -d "$HOME/.pyenv" ]]; then
        log_info "Installing pyenv..."
        if [[ $DRY_RUN -eq 0 ]]; then
            curl https://pyenv.run | bash
        else
            log_info "[DRY RUN] Would install pyenv"
        fi
    fi

    # Install nvm for Node.js version management
    if [[ ! -d "$HOME/.nvm" ]]; then
        log_info "Installing nvm..."
        if [[ $DRY_RUN -eq 0 ]]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        else
            log_info "[DRY RUN] Would install nvm"
        fi
    fi

    # Rust is typically installed via rustup on Arch
    if ! command -v rustup >/dev/null 2>&1; then
        log_info "Installing Rust via rustup..."
        if [[ $DRY_RUN -eq 0 ]]; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        else
            log_info "[DRY RUN] Would install rustup"
        fi
    fi

    log_success "Post-installation complete"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    parse_args "$@"

    # Check OS
    check_os

    [[ $DRY_RUN -eq 1 ]] && log_warning "DRY RUN MODE - No changes will be made" || true

    log_step "Arch Linux Package Installation"

    # Optimize pacman configuration
    optimize_pacman

    # Update package database first
    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "Updating package database..."
        sudo pacman -Sy
    fi

    # Install essential packages first
    install_essential_packages

    # Setup AUR helper
    setup_aur_helper

    # Install yq (required for package management)
    install_yq

    if [[ $ESSENTIAL_ONLY -eq 1 ]]; then
        log_success "Essential packages installation complete!"
        log_info "To install all packages, run without --essential-only flag"
        exit 0
    fi

    # Install all packages from list
    install_packages_from_list

    # Install AUR packages
    install_aur_packages

    # Setup Flatpak
    setup_flatpak

    # Post-installation
    post_install

    # Final summary
    log_success "Arch Linux package installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
    echo "  2. Configure Tailscale: sudo tailscale up"
    echo "  3. Install Flatpak apps: flatpak install flathub org.libreoffice.LibreOffice"
    echo "  4. Setup dotfiles: make install"
    echo ""
    log_info "Note: Arch is a rolling release - keep system updated with: sudo pacman -Syu"
}

# Run main function
main "$@"
