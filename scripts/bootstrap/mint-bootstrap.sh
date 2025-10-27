#!/usr/bin/env bash
# Linux Mint Bootstrap Script
# Installs dotfiles on Linux Mint Cinnamon desktop
#
# Based on Ubuntu bootstrap with Mint-specific customizations
#
# Usage:
#   ./scripts/bootstrap/mint-bootstrap.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Show what would be done without executing
#   --skip-gui         Skip GUI application setup
#   --skip-cinnamon    Skip Cinnamon desktop configuration
#
# Example:
#   ./scripts/bootstrap/mint-bootstrap.sh
#   ./scripts/bootstrap/mint-bootstrap.sh --dry-run

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/../utils/logger.sh"

# Configuration
VERBOSE=0
DRY_RUN=0
SKIP_GUI=0
SKIP_CINNAMON=0

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Linux Mint Cinnamon Bootstrap Script

Installs dotfiles and configures Linux Mint Cinnamon desktop environment.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Show detailed output
    --dry-run           Preview actions without executing
    --skip-gui          Skip GUI application installation
    --skip-cinnamon     Skip Cinnamon desktop configuration

EXAMPLES:
    $0                  # Full installation
    $0 --dry-run        # Preview changes
    $0 --skip-gui       # CLI tools only

REQUIREMENTS:
    - Linux Mint 21+ (based on Ubuntu 22.04+)
    - sudo privileges
    - Internet connection

TARGET DEVICE:
    - Parallels Linux Mint Cinnamon (ARM64)
    - Profile: mint-desktop
    - Roles: development, productivity

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
            --skip-gui)
                SKIP_GUI=1
                shift
                ;;
            --skip-cinnamon)
                SKIP_CINNAMON=1
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
        exit 1
    fi

    source /etc/os-release

    if [[ "$ID" != "linuxmint" ]]; then
        log_error "This script must be run on Linux Mint (detected: $ID)"
        log_info "For Ubuntu, use: ./scripts/bootstrap/ubuntu-bootstrap.sh"
        exit 1
    fi

    log_info "Running on Linux Mint $VERSION_ID ($VERSION_CODENAME)"
    log_info "Based on Ubuntu $UBUNTU_CODENAME"
}

# Install dependencies (reuse Ubuntu script since Mint is Ubuntu-based)
install_dependencies() {
    log_step "Installing Linux Mint Dependencies"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install dependencies via install-dependencies-mint.sh"
        return 0
    fi

    # Use Mint-specific dependency installer if it exists, otherwise fall back to Ubuntu
    if [[ -x "$SCRIPT_DIR/install-dependencies-mint.sh" ]]; then
        log_info "Using Mint-specific dependency installer..."
        "$SCRIPT_DIR/install-dependencies-mint.sh" || {
            log_error "Failed to install dependencies"
            exit 1
        }
    else
        log_info "Using Ubuntu dependency installer (Mint is Ubuntu-based)..."
        "$SCRIPT_DIR/install-dependencies-ubuntu.sh" --vm-essentials || {
            log_error "Failed to install dependencies"
            exit 1
        }
    fi
}

# Install GUI applications for Mint desktop
install_gui_applications() {
    if [[ $SKIP_GUI -eq 1 ]]; then
        log_info "Skipping GUI applications (--skip-gui)"
        return 0
    fi

    log_step "Installing GUI Applications"

    local gui_packages=(
        # Browsers
        "firefox"
        "chromium-browser"

        # Development
        "code"  # VS Code (via snap if not available)

        # Productivity
        "libreoffice"
        "gimp"
        "inkscape"

        # Communication
        "thunderbird"

        # Utilities
        "timeshift"      # System backup (Mint-specific)
        "gnome-system-monitor"
        "gparted"

        # Media
        "vlc"
        "rhythmbox"
    )

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install GUI applications: ${gui_packages[*]}"
        return 0
    fi

    log_info "Installing GUI applications..."
    sudo apt update
    sudo apt install -y "${gui_packages[@]}" || log_warning "Some GUI packages failed to install"

    # Install VS Code via snap if not available via apt
    if ! command -v code &> /dev/null; then
        log_info "Installing VS Code via snap..."
        sudo snap install code --classic || log_warning "Failed to install VS Code"
    fi

    log_success "GUI applications installed"
}

# Configure Cinnamon desktop environment
configure_cinnamon() {
    if [[ $SKIP_CINNAMON -eq 1 ]]; then
        log_info "Skipping Cinnamon configuration (--skip-cinnamon)"
        return 0
    fi

    log_step "Configuring Cinnamon Desktop"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would configure Cinnamon desktop settings"
        return 0
    fi

    # Check if running in a desktop session
    if [[ -z "$DISPLAY" ]]; then
        log_warning "No display detected - skipping Cinnamon configuration"
        log_info "Run manually after logging into desktop: gsettings ..."
        return 0
    fi

    log_info "Applying Cinnamon settings..."

    # Theme and appearance
    gsettings set org.cinnamon.desktop.interface gtk-theme "Mint-Y-Dark-Aqua" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface icon-theme "Mint-Y-Aqua" 2>/dev/null || true
    gsettings set org.cinnamon.theme name "Mint-Y-Dark-Aqua" 2>/dev/null || true

    # Desktop behavior
    gsettings set org.cinnamon.desktop.wm.preferences button-layout ":minimize,maximize,close" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.wm.preferences focus-mode "click" 2>/dev/null || true

    # Panel settings
    gsettings set org.cinnamon panels-enabled "['1:0:bottom']" 2>/dev/null || true
    gsettings set org.cinnamon panel-zone-symbolic-icon-sizes '[{"panelId":1,"left":28,"center":28,"right":16}]' 2>/dev/null || true

    # Keyboard shortcuts (developer-friendly)
    gsettings set org.cinnamon.desktop.keybindings.media-keys terminal "['<Primary><Alt>t']" 2>/dev/null || true

    # File manager (Nemo) settings
    gsettings set org.nemo.preferences show-hidden-files true 2>/dev/null || true
    gsettings set org.nemo.preferences default-folder-viewer "list-view" 2>/dev/null || true

    log_success "Cinnamon desktop configured"
}

# Deploy stow packages
deploy_stow_packages() {
    log_step "Deploying Stow Packages"

    local stow_packages=(
        "shell"
        "git"
        "ssh"
        "1password"
        "vscode"
    )

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would deploy stow packages: ${stow_packages[*]}"
        return 0
    fi

    cd "$PROJECT_ROOT"

    for pkg in "${stow_packages[@]}"; do
        if [[ -d "stow-packages/$pkg" ]]; then
            log_info "Deploying $pkg..."
            stow -t ~ -d stow-packages "$pkg" 2>/dev/null || {
                log_warning "Failed to deploy $pkg (conflicts may exist)"
            }
        else
            log_warning "Package not found: stow-packages/$pkg"
        fi
    done

    log_success "Stow packages deployed"
}

# Setup SSH keys
setup_ssh_keys() {
    log_step "SSH Key Setup"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would setup SSH keys from 1Password"
        return 0
    fi

    log_info "Setting up device-specific SSH key from 1Password..."
    echo ""

    if command -v op &> /dev/null && eval $(op signin) 2>/dev/null; then
        "$SCRIPT_DIR/../setup-ssh-keys.sh" || {
            log_warning "SSH key setup skipped or failed"
            log_info "Run manually later: ./scripts/setup-ssh-keys.sh"
        }
    else
        log_warning "1Password CLI not available or not signed in - skipping SSH key setup"
        log_info "Sign in and run: ./scripts/setup-ssh-keys.sh"
    fi
}

# Setup ZSH as default shell
setup_zsh() {
    log_step "Setting up ZSH"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would setup ZSH as default shell"
        return 0
    fi

    if [[ -x "$SCRIPT_DIR/setup-vm-zsh.sh" ]]; then
        "$SCRIPT_DIR/setup-vm-zsh.sh" || log_warning "ZSH setup encountered issues"
    else
        log_info "Installing Oh My Zsh..."
        if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi

        # Set ZSH as default shell
        if [[ "$SHELL" != "$(which zsh)" ]]; then
            log_info "Setting ZSH as default shell..."
            sudo chsh -s "$(which zsh)" "$USER"
        fi
    fi

    log_success "ZSH setup complete"
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

    log_step "Linux Mint Cinnamon Bootstrap"
    log_info "Profile: mint-desktop"
    log_info "Roles: development, productivity"
    echo ""

    # Installation steps
    install_dependencies
    install_gui_applications
    configure_cinnamon
    deploy_stow_packages
    setup_ssh_keys
    setup_zsh

    # Final summary
    echo ""
    log_success "Linux Mint bootstrap completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Log out and log back in for shell changes to take effect"
    echo "  2. Configure Rclone for R2: ./scripts/sync/setup-rclone.sh"
    echo "  3. Sign in to 1Password: eval \$(op signin)"
    echo "  4. Configure Tailscale: sudo tailscale up"
    echo "  5. Customize Cinnamon: System Settings > Themes, Applets, Desklets"
    echo ""
    log_info "Mint-specific features:"
    echo "  - Timeshift: Configure system snapshots (recommended)"
    echo "  - Update Manager: Configure update preferences"
    echo "  - Nemo Actions: Add custom right-click actions"
    echo ""
}

# Run main function
main "$@"
