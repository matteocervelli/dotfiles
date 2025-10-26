#!/usr/bin/env bash
# Fedora Package Installation Script
# Installs packages from system/fedora/packages.txt with repository setup
#
# Usage:
#   ./scripts/bootstrap/install-dependencies-fedora.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Show what would be installed without installing
#   --skip-repos       Skip repository setup (only install from default repos)
#   --essential-only   Install only essential packages (dev tools, git, stow)
#
# Example:
#   ./scripts/bootstrap/install-dependencies-fedora.sh
#   ./scripts/bootstrap/install-dependencies-fedora.sh --dry-run
#   ./scripts/bootstrap/install-dependencies-fedora.sh --essential-only

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
SKIP_REPOS=0
ESSENTIAL_ONLY=0
PACKAGE_FILE="$PROJECT_ROOT/system/fedora/packages.txt"

# Essential packages (always install these first)
ESSENTIAL_PACKAGES=(
    "gcc"
    "gcc-c++"
    "make"
    "cmake"
    "curl"
    "wget"
    "git"
    "stow"
    "ca-certificates"
    "gnupg2"
)

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Fedora Package Installation Script

Installs packages from system/fedora/packages.txt with proper repository setup.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help         Show this help message
    -v, --verbose      Show detailed output
    --dry-run          Preview installation without making changes
    --skip-repos       Skip repository setup (use default repos only)
    --essential-only   Install only essential packages (git, stow, build tools)

EXAMPLES:
    $0                      # Full installation
    $0 --dry-run            # Preview what would be installed
    $0 --essential-only     # Quick install of essential tools

PACKAGE SOURCES:
    - Native DNF packages: From system/fedora/packages.txt
    - Flatpak apps: Installed separately where specified
    - COPR repositories: Enabled as needed

REQUIREMENTS:
    - Fedora Workstation 40+ or compatible RHEL-based distro
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
            --skip-repos)
                SKIP_REPOS=1
                shift
                ;;
            --essential-only)
                ESSENTIAL_ONLY=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if running on Fedora/RHEL
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found - cannot verify OS"
        exit 2
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    case "$ID" in
        fedora|rhel|centos|rocky|almalinux)
            log_info "Running on $NAME $VERSION_ID"
            ;;
        *)
            log_error "This script must be run on Fedora or RHEL-based distro (detected: $ID)"
            exit 2
            ;;
    esac
}

# Setup required repositories
setup_repositories() {
    if [[ $SKIP_REPOS -eq 1 ]]; then
        log_info "Skipping repository setup (--skip-repos)"
        return 0
    fi

    log_step "Setting up third-party repositories..."

    # Enable RPM Fusion (for multimedia codecs and additional software)
    if ! dnf repolist | grep -q rpmfusion 2>/dev/null; then
        log_info "Setting up RPM Fusion repositories..."
        if [[ $DRY_RUN -eq 0 ]]; then
            sudo dnf install -y \
                https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        else
            log_info "[DRY RUN] Would enable RPM Fusion repositories"
        fi
    fi

    # 1Password CLI Repository
    if ! rpm -q 1password-cli >/dev/null 2>&1; then
        log_info "Setting up 1Password repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
            sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc" > /etc/yum.repos.d/1password.repo'
        else
            log_info "[DRY RUN] Would setup 1Password repository"
        fi
    fi

    # GitHub CLI Repository
    if ! command -v gh >/dev/null 2>&1; then
        log_info "Setting up GitHub CLI repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        else
            log_info "[DRY RUN] Would setup GitHub CLI repository"
        fi
    fi

    # Tailscale Repository
    if ! command -v tailscale >/dev/null 2>&1; then
        log_info "Setting up Tailscale repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
        else
            log_info "[DRY RUN] Would setup Tailscale repository"
        fi
    fi

    # Caddy Repository (via COPR)
    if ! command -v caddy >/dev/null 2>&1; then
        log_info "Setting up Caddy COPR repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            sudo dnf install -y 'dnf-command(copr)'
            sudo dnf copr enable -y @caddy/caddy
        else
            log_info "[DRY RUN] Would setup Caddy COPR repository"
        fi
    fi

    # Google Cloud CLI Repository
    if ! command -v gcloud >/dev/null 2>&1; then
        log_info "Setting up Google Cloud CLI repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
        else
            log_info "[DRY RUN] Would setup Google Cloud CLI repository"
        fi
    fi

    log_success "Repository setup complete"
}

# Install essential packages
install_essential_packages() {
    log_step "Installing essential packages..."

    local packages_to_install=()

    # Check which packages need installation
    for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
        if ! rpm -q "$pkg" >/dev/null 2>&1; then
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
        sudo dnf check-update || true

        # Install essential packages
        sudo dnf install -y "${packages_to_install[@]}"

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

    # Install packages
    log_info "Installing packages (this may take a while)..."

    # DNF can handle multiple packages efficiently
    echo "$packages" | xargs sudo dnf install -y

    log_success "Installed $package_count packages"
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
        sudo dnf install -y flatpak
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        log_success "Flatpak installed with Flathub repository"
    fi
}

# Enable DNF performance optimizations
optimize_dnf() {
    log_info "Optimizing DNF configuration..."

    local dnf_conf="/etc/dnf/dnf.conf"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would optimize DNF with parallel downloads and fastest mirror"
        return 0
    fi

    # Backup original config
    if [[ ! -f "${dnf_conf}.backup" ]]; then
        sudo cp "$dnf_conf" "${dnf_conf}.backup"
    fi

    # Add performance optimizations if not already present
    if ! grep -q "max_parallel_downloads" "$dnf_conf"; then
        echo "max_parallel_downloads=10" | sudo tee -a "$dnf_conf" > /dev/null
        echo "fastestmirror=True" | sudo tee -a "$dnf_conf" > /dev/null
        echo "deltarpm=True" | sudo tee -a "$dnf_conf" > /dev/null
        log_success "DNF optimizations applied"
    else
        log_success "DNF already optimized"
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

    # Install Rust via rustup
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

    log_step "Fedora Package Installation"

    # Optimize DNF configuration
    optimize_dnf

    # Update package lists first
    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "Updating package metadata..."
        sudo dnf check-update || true
    fi

    # Install essential packages first
    install_essential_packages

    # Install yq (required for package management)
    install_yq

    if [[ $ESSENTIAL_ONLY -eq 1 ]]; then
        log_success "Essential packages installation complete!"
        log_info "To install all packages, run without --essential-only flag"
        exit 0
    fi

    # Setup repositories
    setup_repositories

    # Install all packages from list
    install_packages_from_list

    # Setup Flatpak
    setup_flatpak

    # Post-installation
    post_install

    # Final summary
    log_success "Fedora package installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
    echo "  2. Configure Tailscale: sudo tailscale up"
    echo "  3. Install Flatpak apps: flatpak install flathub org.libreoffice.LibreOffice"
    echo "  4. Setup dotfiles: make install"
    echo ""
    log_info "Recommended: Reboot system to ensure all changes take effect"
}

# Run main function
main "$@"
