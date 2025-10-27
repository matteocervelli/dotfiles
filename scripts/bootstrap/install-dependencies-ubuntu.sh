#!/usr/bin/env bash
# Ubuntu Package Installation Script
# Installs packages from system/ubuntu/packages.txt with repository setup
#
# Usage:
#   ./scripts/bootstrap/install-dependencies-ubuntu.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Show what would be installed without installing
#   --skip-repos       Skip repository setup (only install from default repos)
#   --essential-only   Install only essential packages (dev tools, git, stow)
#   --with-docker      Install Docker Engine + Compose v2 after package installation
#
# Example:
#   ./scripts/bootstrap/install-dependencies-ubuntu.sh
#   ./scripts/bootstrap/install-dependencies-ubuntu.sh --dry-run
#   ./scripts/bootstrap/install-dependencies-ubuntu.sh --essential-only

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
VM_ESSENTIALS=0
WITH_DOCKER=0
PACKAGE_FILE="$PROJECT_ROOT/system/ubuntu/packages.txt"

# Essential packages (always install these first)
ESSENTIAL_PACKAGES=(
    "build-essential"
    "curl"
    "wget"
    "git"
    "stow"
    "ca-certificates"
    "gnupg"
    "apt-transport-https"
    "software-properties-common"
)

# VM Essential packages (for --vm-essentials flag)
# Lightweight set for development VMs
VM_ESSENTIAL_PACKAGES=(
    # Build tools
    "build-essential"
    "autoconf"
    "cmake"
    "gcc"
    "pkg-config"

    # Version control & DevOps
    "git"
    "curl"
    "wget"
    "stow"

    # Shell
    "zsh"
    "bash-completion"

    # CLI editors
    "vim"
    "neovim"
    "tmux"

    # System monitoring
    "htop"
    "btop"
    "tree"

    # Modern CLI tools
    "fzf"
    "bat"
    "eza"
    "ripgrep"
    "fd-find"

    # JSON/YAML processing
    "jq"

    # Python
    "python3"
    "python3-pip"
    "pipx"

    # Node.js
    "nodejs"
    "npm"

    # Database clients
    "postgresql-client"
    "sqlite3"

    # Cloud & sync
    "rclone"

    # Image processing
    "imagemagick"
    "ffmpeg"

    # Security
    "ca-certificates"
    "gnupg"
    "openssl"

    # Utilities
    "apt-transport-https"
    "software-properties-common"
    "moreutils"
    "pv"
    "socat"
)

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Ubuntu Package Installation Script

Installs packages from system/ubuntu/packages.txt with proper repository setup.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Show detailed output
    --dry-run           Preview installation without making changes
    --skip-repos        Skip repository setup (use default repos only)
    --essential-only    Install only essential packages (git, stow, build tools)
    --vm-essentials     Install VM essential packages (dev tools, CLI utils, no GUI)
    --with-docker       Install Docker Engine + Compose v2 after package installation

EXAMPLES:
    $0                      # Full installation
    $0 --dry-run            # Preview what would be installed
    $0 --essential-only     # Quick install of essential tools (minimal)
    $0 --vm-essentials      # Install VM essentials (CLI dev environment)
    $0 --vm-essentials --with-docker  # VM setup with Docker

PACKAGE SOURCES:
    - Native APT packages: From system/ubuntu/packages.txt
    - Snap packages: Installed separately where specified
    - Flatpak apps: Installed separately where specified

REQUIREMENTS:
    - Ubuntu 24.04 LTS (Noble Numbat) or compatible
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
            --vm-essentials)
                VM_ESSENTIALS=1
                shift
                ;;
            --with-docker)
                WITH_DOCKER=1
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

# Check if running on Ubuntu
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found - cannot verify OS"
        exit 2
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script must be run on Ubuntu (detected: $ID)"
        exit 2
    fi

    log_info "Running on Ubuntu $VERSION_ID ($VERSION_CODENAME)"
}

# Setup required repositories
setup_repositories() {
    if [[ $SKIP_REPOS -eq 1 ]]; then
        log_info "Skipping repository setup (--skip-repos)"
        return 0
    fi

    log_step "Setting up third-party repositories..."

    # 1Password CLI Repository
    if ! dpkg -l | grep -q 1password-cli 2>/dev/null; then
        log_info "Setting up 1Password repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
                sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main" | \
                sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
        else
            log_info "[DRY RUN] Would setup 1Password repository"
        fi
    fi

    # GitHub CLI Repository
    if ! command -v gh >/dev/null 2>&1; then
        log_info "Setting up GitHub CLI repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
                sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
                sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        else
            log_info "[DRY RUN] Would setup GitHub CLI repository"
        fi
    fi

    # Tailscale Repository
    if ! command -v tailscale >/dev/null 2>&1; then
        log_info "Setting up Tailscale repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | \
                sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null

            curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | \
                sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
        else
            log_info "[DRY RUN] Would setup Tailscale repository"
        fi
    fi

    # Caddy Repository
    if ! command -v caddy >/dev/null 2>&1; then
        log_info "Setting up Caddy repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
                sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
                sudo tee /etc/apt/sources.list.d/caddy-stable.list > /dev/null
        else
            log_info "[DRY RUN] Would setup Caddy repository"
        fi
    fi

    # Update package lists after adding repositories
    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "Updating package lists..."
        sudo apt update
    fi

    log_success "Repository setup complete"
}

# Install essential packages
install_essential_packages() {
    log_step "Installing essential packages..."

    local packages_to_install=()

    # Check which packages need installation
    for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg " 2>/dev/null; then
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
        sudo apt update

        # Install essential packages
        sudo apt install -y "${packages_to_install[@]}"

        log_success "Essential packages installed"
    fi
}

# Install VM essential packages (dev environment without GUI apps)
install_vm_essentials() {
    log_step "Installing VM essential packages..."

    local packages_to_install=()

    # Check which packages need installation
    for pkg in "${VM_ESSENTIAL_PACKAGES[@]}"; do
        # Skip if already installed
        if ! dpkg -l | grep -q "^ii  $pkg " 2>/dev/null; then
            packages_to_install+=("$pkg")
        fi
    done

    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log_success "All VM essential packages already installed"
        return 0
    fi

    log_info "Installing ${#packages_to_install[@]} VM essential packages..."
    log_info "This includes: dev tools, CLI utilities, Python, Node.js, database clients"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install: ${packages_to_install[*]}"
    else
        # Update first
        sudo apt update

        # Install VM essential packages
        # Use --no-install-recommends to keep installation minimal
        sudo apt install -y --no-install-recommends "${packages_to_install[@]}" || {
            log_warning "Some packages failed to install, trying without --no-install-recommends"
            sudo apt install -y "${packages_to_install[@]}"
        }

        log_success "VM essential packages installed"
    fi
}

# Install yq (YAML processor) - critical for package management
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

    # Use xargs for efficient batch installation
    echo "$packages" | xargs sudo apt install -y

    log_success "Installed $package_count packages"
}

# Setup Snap (if not already available)
setup_snap() {
    if command -v snap >/dev/null 2>&1; then
        log_success "Snap already installed"
        return 0
    fi

    log_info "Installing Snap..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install snapd"
    else
        sudo apt install -y snapd
        log_success "Snap installed"
    fi
}

# Install recommended Snap packages
install_snap_packages() {
    if ! command -v snap >/dev/null 2>&1; then
        log_warning "Snap not available, skipping Snap packages"
        return 0
    fi

    log_step "Installing recommended Snap packages..."

    # Recommended Snap packages from package-mappings.yml
    local snap_packages=(
        "code:--classic"              # VS Code
        "flutter:--classic"            # Flutter SDK
        "deno"                         # Deno runtime
    )

    local installed_count=0

    for pkg_spec in "${snap_packages[@]}"; do
        # Parse package name and flags
        local pkg_name="${pkg_spec%%:*}"
        local pkg_flags="${pkg_spec#*:}"
        [[ "$pkg_flags" == "$pkg_name" ]] && pkg_flags=""

        # Check if already installed
        if snap list | grep -q "^${pkg_name} " 2>/dev/null; then
            [[ $VERBOSE -eq 1 ]] && log_success "$pkg_name already installed (snap)" || true
            continue
        fi

        log_info "Installing $pkg_name via Snap..."

        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY RUN] Would install: snap install $pkg_name $pkg_flags"
        else
            # shellcheck disable=SC2086
            sudo snap install "$pkg_name" $pkg_flags && ((installed_count++)) || log_warning "Failed to install $pkg_name"
        fi
    done

    if [[ $installed_count -gt 0 ]]; then
        log_success "Installed $installed_count Snap packages"
    else
        log_info "All recommended Snap packages already installed"
    fi
}

# Setup Flatpak
setup_flatpak() {
    if command -v flatpak >/dev/null 2>&1; then
        log_success "Flatpak already installed"
        return 0
    fi

    log_info "Installing Flatpak..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install flatpak and add Flathub"
    else
        sudo apt install -y flatpak
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

    log_step "Ubuntu Package Installation"

    # Update package lists first
    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "Updating package lists..."
        sudo apt update
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

    # Install VM essentials if requested
    if [[ $VM_ESSENTIALS -eq 1 ]]; then
        install_vm_essentials
        log_success "VM essential packages installation complete!"
        log_info "Installed ${#VM_ESSENTIAL_PACKAGES[@]} packages for VM development"
        exit 0
    fi

    # Setup repositories
    setup_repositories

    # Install all packages from list
    install_packages_from_list

    # Setup universal package managers
    setup_snap
    install_snap_packages  # Install recommended Snap packages

    setup_flatpak

    # Post-installation
    post_install

    # Install Docker if requested
    if [[ $WITH_DOCKER -eq 1 ]]; then
        log_step "Installing Docker Engine + Compose v2..."
        if [[ -x "$PROJECT_ROOT/scripts/bootstrap/install-docker.sh" ]]; then
            if [[ $DRY_RUN -eq 1 ]]; then
                log_info "[DRY RUN] Would run: $PROJECT_ROOT/scripts/bootstrap/install-docker.sh --dry-run"
            else
                "$PROJECT_ROOT/scripts/bootstrap/install-docker.sh" || log_warning "Docker installation encountered issues"
            fi
        else
            log_error "Docker installation script not found or not executable"
            log_info "Expected location: $PROJECT_ROOT/scripts/bootstrap/install-docker.sh"
        fi
    fi

    # Final summary
    log_success "Ubuntu package installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
    echo "  2. Configure Tailscale: sudo tailscale up"
    echo "  3. Install Snap apps: snap install code --classic"
    echo "  4. Install Flatpak apps: flatpak install flathub org.libreoffice.LibreOffice"
    echo "  5. Setup dotfiles: make install"
    [[ $WITH_DOCKER -eq 1 ]] && echo "  6. Log out/in for Docker group to take effect" || true
    echo ""
    log_info "Recommended: Reboot system to ensure all changes take effect"
}

# Run main function
main "$@"
