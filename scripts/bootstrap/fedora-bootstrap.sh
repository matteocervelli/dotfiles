#!/usr/bin/env bash
# Fedora Bootstrap Script
# Automated setup for Fedora Workstation development environment
#
# Usage:
#   ./scripts/bootstrap/fedora-bootstrap.sh [OPTIONS]
#
# Options:
#   -h, --help           Show this help message
#   -v, --verbose        Show detailed output
#   --dry-run            Show what would be done without making changes
#   --with-packages      Install all packages from system/fedora/packages.txt
#   --profile <name>     Use specific profile (future: fedora-dev, fedora-minimal)
#   --skip-repos         Skip repository setup
#   --essential-only     Install only essential tools (stow, git, 1password, rclone)
#
# Example:
#   ./scripts/bootstrap/fedora-bootstrap.sh                    # Minimal setup
#   ./scripts/bootstrap/fedora-bootstrap.sh --with-packages    # Full package install
#   ./scripts/bootstrap/fedora-bootstrap.sh --dry-run          # Preview actions

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
WITH_DOCKER=0
SKIP_REPOS=0
ESSENTIAL_ONLY=0
VM_ESSENTIALS=0
PROFILE=""

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Fedora Bootstrap Script - Automated Development Environment Setup

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help           Show this help message
    -v, --verbose        Show detailed output
    --dry-run            Preview actions without making changes
    --with-packages      Install all packages from system/fedora/packages.txt
    --with-docker        Install Docker Engine + Compose v2
    --profile <name>     Use specific profile (future support)
    --skip-repos         Skip repository setup (use default repos only)
    --essential-only     Install only essential tools (quick setup)
    --vm-essentials      Install VM-optimized package set (60+ packages, no GUI apps)

EXAMPLES:
    $0                          # Minimal setup (stow, git, 1password, rclone)
    $0 --vm-essentials          # VM-optimized development environment (60+ packages)
    $0 --with-packages          # Full development environment
    $0 --with-docker            # Minimal setup + Docker
    $0 --vm-essentials --with-docker  # VM essentials + Docker
    $0 --with-packages --with-docker  # Full environment + Docker
    $0 --dry-run                # Preview what would be installed
    $0 --essential-only         # Quick essential-only setup

PHASES:
    1. OS verification (Fedora detection)
    2. System update (dnf update)
    3. Essential tools (Development Tools, stow, git)
    4. Dotfiles core (1Password CLI, rclone, yq, ImageMagick)
    5. Stow package deployment
    6. Optional: Full package installation (--with-packages)
    7. Fedora-specific checks (SELinux, firewalld)

REQUIREMENTS:
    - Fedora Workstation 40+ or compatible RHEL-based distro
    - sudo privileges
    - Internet connection

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported
    3    Missing dependencies

FEDORA-SPECIFIC:
    - Uses DNF package manager
    - Checks SELinux status (informs, doesn't disable)
    - Checks firewalld status
    - Installs @development-tools group
    - RPM Fusion repositories (optional)

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
            --with-docker)
                WITH_DOCKER=1
                shift
                ;;
            --profile)
                PROFILE="$2"
                shift 2
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
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if running on Fedora
check_os() {
    local os
    os=$(detect_os)

    if [[ "$os" != "fedora" ]]; then
        log_error "This script must be run on Fedora (detected: $os)"
        log_info "For other distros, see: scripts/bootstrap/"
        exit 2
    fi

    # Get detailed Fedora version
    if [[ -f /etc/fedora-release ]]; then
        local fedora_version
        fedora_version=$(cat /etc/fedora-release)
        log_info "Running on: $fedora_version"
    else
        log_warning "/etc/fedora-release not found"
    fi

    # Verify DNF is available
    if ! command -v dnf &> /dev/null; then
        log_error "DNF package manager not found"
        exit 3
    fi

    log_success "OS verification passed"
}

# Check SELinux status
check_selinux() {
    if command -v getenforce &> /dev/null; then
        local selinux_status
        selinux_status=$(getenforce)

        case "$selinux_status" in
            Enforcing)
                log_info "SELinux: Enforcing (active security)"
                log_warning "Some operations may require SELinux context changes"
                ;;
            Permissive)
                log_info "SELinux: Permissive (logging only)"
                ;;
            Disabled)
                log_info "SELinux: Disabled"
                ;;
            *)
                log_warning "SELinux: Unknown status ($selinux_status)"
                ;;
        esac
    else
        log_info "SELinux tools not installed"
    fi
}

# Check firewalld status
check_firewalld() {
    if command -v firewall-cmd &> /dev/null; then
        if systemctl is-active --quiet firewalld; then
            log_info "Firewalld: Active"

            # Show active zones if verbose
            if [[ $VERBOSE -eq 1 ]]; then
                local active_zones
                active_zones=$(firewall-cmd --get-active-zones 2>/dev/null || echo "none")
                log_info "Active zones: $active_zones"
            fi
        else
            log_info "Firewalld: Inactive"
        fi
    else
        log_info "Firewalld not installed"
    fi
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

    log_info "Updating package metadata..."
    execute sudo dnf check-update || true  # Exit code 100 means updates available

    log_info "Upgrading installed packages (this may take several minutes)..."
    execute sudo dnf upgrade -y

    log_success "System updated"
}

# =============================================================================
# Phase 2: Essential Tools
# =============================================================================

install_essential_tools() {
    log_step "Phase 2: Essential Development Tools"

    # Install Development Tools group (Fedora 42+: "development-tools")
    if ! dnf group list installed 2>/dev/null | grep -qi "development-tools\|Development Tools"; then
        log_info "Installing development-tools group..."
        execute sudo dnf group install -y "development-tools"
    else
        log_success "Development Tools already installed"
    fi

    # Essential packages
    local essential_packages=(
        "stow"
        "git"
        "curl"
        "wget"
        "ca-certificates"
        "gnupg2"
    )

    log_info "Installing essential packages..."
    for package in "${essential_packages[@]}"; do
        if ! rpm -q "$package" &> /dev/null; then
            log_info "Installing $package..."
            execute sudo dnf install -y "$package"
        else
            if [[ $VERBOSE -eq 1 ]]; then
                log_success "$package already installed"
            fi
        fi
    done

    log_success "Essential tools installed"
}

# =============================================================================
# Phase 3: Dotfiles Core Dependencies
# =============================================================================

install_1password_cli() {
    if command -v op &> /dev/null; then
        log_success "1Password CLI already installed"
        return 0
    fi

    log_info "Installing 1Password CLI..."

    if [[ $SKIP_REPOS -eq 0 ]]; then
        # Add 1Password repository
        execute sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc

        # Create repo file
        if [[ $DRY_RUN -eq 0 ]]; then
            sudo sh -c 'cat > /etc/yum.repos.d/1password.repo << EOF
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF'
        else
            log_info "[DRY-RUN] Would create /etc/yum.repos.d/1password.repo"
        fi

        execute sudo dnf install -y 1password-cli
    else
        log_warning "Skipping 1Password CLI (--skip-repos enabled)"
    fi
}

install_rclone() {
    if command -v rclone &> /dev/null; then
        log_success "Rclone already installed"
        return 0
    fi

    log_info "Installing Rclone..."
    execute sudo dnf install -y rclone
}

install_yq() {
    if command -v yq &> /dev/null; then
        log_success "yq already installed"
        return 0
    fi

    log_info "Installing yq..."
    local yq_version="latest"
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
}

install_imagemagick() {
    if command -v convert &> /dev/null; then
        log_success "ImageMagick already installed"
        return 0
    fi

    log_info "Installing ImageMagick..."
    execute sudo dnf install -y ImageMagick
}

install_dotfiles_core() {
    log_step "Phase 3: Dotfiles Core Dependencies"

    install_1password_cli
    install_rclone
    install_yq
    install_imagemagick

    log_success "Dotfiles core dependencies installed"
}

# =============================================================================
# Phase 4: Stow Package Deployment
# =============================================================================

deploy_stow_packages() {
    log_step "Phase 4: Stow Package Deployment"

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
        local package_path="$PROJECT_ROOT/stow-packages/$package"

        if [[ -d "$package_path" ]]; then
            log_info "Deploying package: $package"

            if [[ $DRY_RUN -eq 0 ]]; then
                cd "$PROJECT_ROOT/stow-packages" || exit 1
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
        execute sudo dnf install -y zsh
        execute sudo chsh -s "$(command -v zsh)" "$(whoami)"
    fi

    log_success "Stow packages deployed"
}

# =============================================================================
# Phase 5: Full Package Installation (Optional)
# =============================================================================

install_vm_essentials() {
    log_step "Phase 5: VM Essential Packages"

    local install_script="$PROJECT_ROOT/scripts/bootstrap/install-dependencies-fedora.sh"

    if [[ ! -f "$install_script" ]]; then
        log_error "install-dependencies-fedora.sh not found"
        return 1
    fi

    log_info "Installing VM-optimized package set (~60 packages)..."
    log_info "This includes: dev tools, CLI editors, modern CLI utils, languages, DB clients"
    log_warning "This may take 10-15 minutes depending on your connection"

    if [[ $DRY_RUN -eq 1 ]]; then
        execute "$install_script" --vm-essentials --dry-run
    else
        execute "$install_script" --vm-essentials
    fi

    log_success "VM essential packages installed"
}

install_full_packages() {
    log_step "Phase 5: Full Package Installation"

    local install_script="$PROJECT_ROOT/scripts/bootstrap/install-dependencies-fedora.sh"

    if [[ ! -f "$install_script" ]]; then
        log_error "install-dependencies-fedora.sh not found"
        return 1
    fi

    log_info "Running full package installation..."
    log_warning "This may take 30-60 minutes depending on your connection"

    if [[ $DRY_RUN -eq 1 ]]; then
        execute "$install_script" --dry-run
    else
        execute "$install_script"
    fi

    log_success "Full package installation complete"
}

# =============================================================================
# Phase 6: Fedora-Specific Checks
# =============================================================================

fedora_specific_checks() {
    log_step "Phase 6: Fedora-Specific Checks"

    check_selinux
    check_firewalld

    # Optional: RPM Fusion suggestion
    if ! dnf repolist | grep -q rpmfusion; then
        log_info ""
        log_info "RPM Fusion repositories not detected"
        log_info "To install multimedia codecs and proprietary software:"
        log_info "  sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm"
        log_info "  sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
    fi

    log_success "Fedora-specific checks complete"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    echo "========================================================================"
    echo "  Fedora Bootstrap - Automated Development Environment Setup"
    echo "========================================================================"
    echo ""

    # Parse arguments
    parse_args "$@"

    # Show configuration
    if [[ $VERBOSE -eq 1 ]]; then
        log_info "Configuration:"
        log_info "  Dry run: $DRY_RUN"
        log_info "  With packages: $WITH_PACKAGES"
        log_info "  With Docker: $WITH_DOCKER"
        log_info "  Essential only: $ESSENTIAL_ONLY"
        log_info "  VM essentials: $VM_ESSENTIALS"
        log_info "  Skip repos: $SKIP_REPOS"
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
    install_dotfiles_core
    deploy_stow_packages

    if [[ $WITH_PACKAGES -eq 1 ]]; then
        install_full_packages
    elif [[ $VM_ESSENTIALS -eq 1 ]]; then
        install_vm_essentials
    else
        log_info ""
        log_info "Skipping package installation"
        log_info "To install VM essentials: $0 --vm-essentials"
        log_info "To install all packages: $0 --with-packages"
    fi

    # Docker installation (if requested)
    if [[ $WITH_DOCKER -eq 1 ]]; then
        log_step "Installing Docker Engine + Compose v2..."

        local docker_script="$PROJECT_ROOT/scripts/bootstrap/install-docker-fedora.sh"

        if [[ ! -f "$docker_script" ]]; then
            log_error "Docker installation script not found: $docker_script"
            exit 1
        fi

        if [[ $DRY_RUN -eq 1 ]]; then
            log_info "[DRY RUN] Would execute: $docker_script --dry-run"
        else
            log_info "Executing Docker installation script..."
            "$docker_script" || {
                log_error "Docker installation failed"
                log_info "See: docs/guides/docker-fedora-setup.md for manual installation"
                exit 1
            }
        fi

        log_success "Docker installation complete"
    else
        log_info ""
        log_info "Skipping Docker installation"
        log_info "To install Docker, run:"
        log_info "  $0 --with-docker"
        log_info "  OR: make docker-install-fedora"
    fi

    if [[ $ESSENTIAL_ONLY -eq 0 ]]; then
        fedora_specific_checks
    fi

    # Success message
    echo ""
    echo "========================================================================"
    echo "  Bootstrap Complete!"
    echo "========================================================================"
    echo ""
    log_success "Fedora development environment setup successful"

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
