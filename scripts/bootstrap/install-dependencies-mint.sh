#!/usr/bin/env bash
# Linux Mint Package Installation Script
# Based on Ubuntu package installation with Mint-specific adjustments
#
# Usage:
#   ./scripts/bootstrap/install-dependencies-mint.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Show what would be installed without installing
#   --skip-repos       Skip repository setup (only install from default repos)
#   --essential-only   Install only essential packages (dev tools, git, stow)
#   --desktop          Install desktop packages (GUI applications)
#
# Example:
#   ./scripts/bootstrap/install-dependencies-mint.sh
#   ./scripts/bootstrap/install-dependencies-mint.sh --dry-run
#   ./scripts/bootstrap/install-dependencies-mint.sh --desktop

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Configuration
VERBOSE=0
DRY_RUN=0
SKIP_REPOS=0
ESSENTIAL_ONLY=0
DESKTOP=0

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

# Desktop essential packages (for Mint desktop profile)
# Includes development tools + GUI applications
DESKTOP_PACKAGES=(
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

    # GUI Applications (Mint desktop)
    "firefox"
    "chromium-browser"
    "libreoffice"
    "gimp"
    "inkscape"
    "thunderbird"
    "vlc"
    "timeshift"  # Mint-specific backup tool
    "gnome-system-monitor"
    "gparted"
)

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Linux Mint Package Installation Script

Installs packages for Linux Mint Cinnamon desktop environment.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Show detailed output
    --dry-run           Preview installation without making changes
    --skip-repos        Skip repository setup (use default repos only)
    --essential-only    Install only essential packages (git, stow, build tools)
    --desktop           Install desktop packages (full GUI environment)

EXAMPLES:
    $0                      # Full installation
    $0 --dry-run            # Preview what would be installed
    $0 --essential-only     # Quick install of essential tools (minimal)
    $0 --desktop            # Full desktop installation with GUI apps

REQUIREMENTS:
    - Linux Mint 21+ (based on Ubuntu 22.04+)
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
            --desktop)
                DESKTOP=1
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

# Check if running on Linux Mint
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found - cannot verify OS"
        exit 2
    fi

    source /etc/os-release

    if [[ "$ID" != "linuxmint" ]]; then
        log_error "This script must be run on Linux Mint (detected: $ID)"
        log_info "For Ubuntu, use: ./scripts/bootstrap/install-dependencies-ubuntu.sh"
        exit 2
    fi

    log_info "Running on Linux Mint $VERSION_ID ($VERSION_CODENAME)"
    log_info "Based on Ubuntu $UBUNTU_CODENAME"
}

# Setup required repositories (compatible with Mint)
setup_repositories() {
    if [[ $SKIP_REPOS -eq 1 ]]; then
        log_info "Skipping repository setup (--skip-repos)"
        return 0
    fi

    log_step "Setting up third-party repositories..."

    # 1Password CLI Repository (using Ubuntu compatibility)
    if ! dpkg -l | grep -q 1password-cli 2>/dev/null; then
        log_info "Setting up 1Password repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
                sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

            # Use Ubuntu codename for 1Password repo (Mint compatibility)
            source /etc/os-release
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
                sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
        else
            log_info "[DRY RUN] Would setup 1Password repository"
        fi
    fi

    # GitHub CLI Repository (using Ubuntu compatibility)
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

    # Tailscale Repository (using Ubuntu compatibility)
    if ! command -v tailscale >/dev/null 2>&1; then
        log_info "Setting up Tailscale repository..."
        if [[ $DRY_RUN -eq 0 ]]; then
            # Use Ubuntu codename for Tailscale
            source /etc/os-release
            curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_CODENAME}.noarmor.gpg | \
                sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null

            curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_CODENAME}.tailscale-keyring.list | \
                sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
        else
            log_info "[DRY RUN] Would setup Tailscale repository"
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
        sudo apt update
        sudo apt install -y "${packages_to_install[@]}"
        log_success "Essential packages installed"
    fi
}

# Install desktop packages (GUI + development)
install_desktop_packages() {
    log_step "Installing desktop packages..."

    local packages_to_install=()

    # Check which packages need installation
    for pkg in "${DESKTOP_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg " 2>/dev/null; then
            packages_to_install+=("$pkg")
        fi
    done

    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log_success "All desktop packages already installed"
        return 0
    fi

    log_info "Installing ${#packages_to_install[@]} desktop packages..."
    log_info "This includes: dev tools, CLI utilities, GUI applications"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install: ${packages_to_install[*]}"
    else
        sudo apt update
        sudo apt install -y "${packages_to_install[@]}" || {
            log_warning "Some packages failed to install, continuing..."
        }
        log_success "Desktop packages installed"
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
        # Detect architecture
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64)
                YQ_BINARY="yq_linux_amd64"
                ;;
            aarch64|arm64)
                YQ_BINARY="yq_linux_arm64"
                ;;
            *)
                log_error "Unsupported architecture: $ARCH"
                exit 1
                ;;
        esac

        YQ_VERSION="v4.40.5"
        cd /tmp
        wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz" -O yq.tar.gz
        tar xzf yq.tar.gz
        sudo mv "${YQ_BINARY}" /usr/local/bin/yq
        sudo chmod +x /usr/local/bin/yq
        rm -f yq.tar.gz yq.1 install-yq.sh

        log_success "yq installed successfully"
    fi
}

# Setup Snap (pre-installed on Mint but verify)
setup_snap() {
    if command -v snap >/dev/null 2>&1; then
        log_success "Snap already available"
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

# Install recommended Snap packages for desktop
install_snap_packages() {
    if ! command -v snap >/dev/null 2>&1; then
        log_warning "Snap not available, skipping Snap packages"
        return 0
    fi

    log_step "Installing recommended Snap packages..."

    # Recommended Snap packages for Mint desktop
    local snap_packages=(
        "code:--classic"              # VS Code
    )

    local installed_count=0

    for pkg_spec in "${snap_packages[@]}"; do
        local pkg_name="${pkg_spec%%:*}"
        local pkg_flags="${pkg_spec#*:}"
        [[ "$pkg_flags" == "$pkg_name" ]] && pkg_flags=""

        if snap list | grep -q "^${pkg_name} " 2>/dev/null; then
            [[ $VERBOSE -eq 1 ]] && log_success "$pkg_name already installed (snap)" || true
            continue
        fi

        log_info "Installing $pkg_name via Snap..."

        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY RUN] Would install: snap install $pkg_name $pkg_flags"
        else
            sudo snap install "$pkg_name" $pkg_flags && ((installed_count++)) || log_warning "Failed to install $pkg_name"
        fi
    done

    if [[ $installed_count -gt 0 ]]; then
        log_success "Installed $installed_count Snap packages"
    else
        log_info "All recommended Snap packages already installed"
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
    parse_args "$@"
    check_os

    [[ $DRY_RUN -eq 1 ]] && log_warning "DRY RUN MODE - No changes will be made" || true

    log_step "Linux Mint Package Installation"

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

    # Install desktop packages if requested
    if [[ $DESKTOP -eq 1 ]]; then
        install_desktop_packages
    fi

    # Setup repositories
    setup_repositories

    # Setup package managers
    setup_snap
    install_snap_packages

    # Post-installation
    post_install

    # Final summary
    log_success "Linux Mint package installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
    echo "  2. Configure Tailscale: sudo tailscale up"
    echo "  3. Install additional Snap apps: snap install <app> --classic"
    echo "  4. Setup dotfiles: make install"
    echo ""
    log_info "Mint-specific recommendations:"
    echo "  - Configure Timeshift for system snapshots"
    echo "  - Customize Cinnamon desktop in System Settings"
    echo "  - Install Mint themes and icons if desired"
}

# Run main function
main "$@"
