#!/usr/bin/env bash
# VPS Ubuntu Headless Bootstrap Script
# Minimal installation optimized for cloud VPS (DigitalOcean, Hetzner, etc.)
#
# Features:
#   - Minimal package installation (headless, no GUI)
#   - Automatic security hardening (fail2ban, UFW, SSH)
#   - Monitoring integration (Prometheus node_exporter)
#   - Optional Docker installation
#   - Optimized for production use
#
# Usage:
#   ./scripts/bootstrap/vps-ubuntu-bootstrap.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Preview installation without making changes
#   --with-docker      Install Docker Engine + Compose v2
#   --skip-hardening   Skip security hardening (not recommended)
#   --skip-monitoring  Skip monitoring setup
#   --no-ufw           Don't configure UFW firewall
#
# Example:
#   ./scripts/bootstrap/vps-ubuntu-bootstrap.sh --with-docker

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
WITH_DOCKER=0
SKIP_HARDENING=0
SKIP_MONITORING=0
NO_UFW=0

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
VPS Ubuntu Headless Bootstrap Script

Minimal installation optimized for cloud VPS environments with automatic
security hardening and monitoring integration.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Show detailed output
    --dry-run               Preview installation without making changes
    --with-docker           Install Docker Engine + Compose v2
    --skip-hardening        Skip security hardening (not recommended)
    --skip-monitoring       Skip Prometheus node_exporter setup
    --no-ufw                Don't configure UFW firewall

EXAMPLES:
    $0                      # Minimal VPS setup with security hardening
    $0 --with-docker        # VPS setup with Docker
    $0 --dry-run            # Preview what would be installed

WHAT GETS INSTALLED:
    Core:
      - GNU Stow (dotfiles management)
      - Git, curl, wget (essential tools)
      - Build essentials (gcc, make, etc.)
      - 1Password CLI (secret management)
      - Rclone (cloud storage sync)
      - yq (YAML processor)

    Security (unless --skip-hardening):
      - fail2ban (brute-force protection)
      - UFW (firewall)
      - SSH hardening (key-only auth, no root login)
      - Automatic security updates

    Monitoring (unless --skip-monitoring):
      - Prometheus node_exporter
      - System metrics collection

    Optional:
      - Docker Engine + Compose v2 (with --with-docker)

POST-INSTALL CONFIGURATION:
    Security:
      - SSH: Key-only authentication, no root login
      - Firewall: Allow 22 (SSH), 80 (HTTP), 443 (HTTPS)
      - fail2ban: 5 failed attempts = 10min ban
      - Automatic updates: Enabled via unattended-upgrades

    Monitoring:
      - node_exporter: Listening on localhost:9100
      - Metrics: CPU, memory, disk, network

REQUIREMENTS:
    - Ubuntu 24.04 LTS or 22.04 LTS
    - Root or sudo privileges
    - Internet connection
    - At least 2GB free disk space
    - SSH key for authentication (password login will be disabled)

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported
    3    Missing requirements

WARNINGS:
    ⚠️  Security hardening will:
        - Disable SSH password authentication
        - Disable root SSH login
        - Enable UFW firewall (may disconnect SSH if not configured properly)

    ⚠️  Ensure you have SSH key access before running this script!

NOTES:
    - Designed for headless cloud VPS (DigitalOcean, Hetzner, Linode, etc.)
    - Minimal attack surface (no GUI packages)
    - Production-ready defaults
    - Optimized for low resource usage (2-4GB RAM)

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
            --with-docker)
                WITH_DOCKER=1
                shift
                ;;
            --skip-hardening)
                SKIP_HARDENING=1
                shift
                ;;
            --skip-monitoring)
                SKIP_MONITORING=1
                shift
                ;;
            --no-ufw)
                NO_UFW=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run '$0 --help' for usage information."
                exit 1
                ;;
        esac
    done
}

# Execute command (respects DRY_RUN flag)
execute() {
    if [[ $VERBOSE -eq 1 ]]; then
        log_info "Executing: $*"
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: $*"
        return 0
    fi

    "$@"
}

# Check OS compatibility
check_os() {
    log_step "Checking OS Compatibility"

    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect OS (missing /etc/os-release)"
        exit 2
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script is designed for Ubuntu (detected: $ID)"
        log_info "For other distributions, use:"
        log_info "  - Fedora: ./scripts/bootstrap/fedora-bootstrap.sh"
        log_info "  - Arch: ./scripts/bootstrap/arch-bootstrap.sh"
        exit 2
    fi

    log_success "Detected: $PRETTY_NAME ($VERSION_CODENAME)"

    # Recommend Ubuntu 24.04 LTS for VPS
    if [[ "$VERSION_ID" != "24.04" && "$VERSION_ID" != "22.04" ]]; then
        log_warning "Recommended Ubuntu version: 24.04 LTS (current: $VERSION_ID)"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking Prerequisites"

    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        log_info "Run: sudo -v"
        exit 3
    fi
    log_success "Sudo access verified"

    # Warn about SSH key requirement
    if [[ $SKIP_HARDENING -eq 0 ]]; then
        log_warning "⚠️  Security hardening will disable SSH password authentication"
        log_info "Ensure you have SSH key access before continuing!"

        if [[ -f "$HOME/.ssh/authorized_keys" ]]; then
            local key_count
            key_count=$(grep -c "^ssh-" "$HOME/.ssh/authorized_keys" 2>/dev/null || echo 0)
            log_success "Found $key_count SSH key(s) in authorized_keys"
        else
            log_error "No SSH keys found in ~/.ssh/authorized_keys"
            log_info "Add your SSH key first: ssh-copy-id user@vps"
            exit 3
        fi
    fi

    # Check disk space
    local free_space
    free_space=$(df / | awk 'NR==2 {print $4}')
    local free_gb=$((free_space / 1024 / 1024))

    if [[ $free_gb -lt 2 ]]; then
        log_warning "Low disk space: ${free_gb}GB free (recommended: 2GB+)"
    else
        log_success "Disk space: ${free_gb}GB free"
    fi
}

# Update system packages
update_system() {
    log_step "Updating System Packages"

    execute sudo apt-get update

    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "Upgrading packages (this may take a few minutes)..."
        execute sudo apt-get upgrade -y
        log_success "System packages updated"
    fi
}

# Install core dependencies
install_core_dependencies() {
    log_step "Installing Core Dependencies"

    local packages=(
        "stow"           # GNU Stow for dotfiles
        "git"            # Version control
        "curl"           # HTTP client
        "wget"           # File downloader
        "build-essential" # GCC, make, etc.
        "ca-certificates" # SSL certificates
        "gnupg"          # GPG for package verification
        "lsb-release"    # OS detection
    )

    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            log_success "$package already installed"
        else
            log_info "Installing $package..."
            execute sudo apt-get install -y "$package"
        fi
    done

    log_success "Core dependencies installed"
}

# Install 1Password CLI
install_1password_cli() {
    log_step "Installing 1Password CLI"

    if command -v op &> /dev/null; then
        log_success "1Password CLI already installed"
        return
    fi

    log_info "Adding 1Password repository..."

    execute curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    execute bash -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | sudo tee /etc/apt/sources.list.d/1password.list'

    execute sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    execute curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

    execute sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    execute curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    execute sudo apt-get update
    execute sudo apt-get install -y 1password-cli

    log_success "1Password CLI installed"
}

# Install Rclone
install_rclone() {
    log_step "Installing Rclone"

    if command -v rclone &> /dev/null; then
        log_success "Rclone already installed"
        return
    fi

    execute sudo apt-get install -y rclone
    log_success "Rclone installed"
}

# Install yq
install_yq() {
    log_step "Installing yq"

    if command -v yq &> /dev/null; then
        local yq_path
        yq_path=$(which yq)
        log_success "yq already installed at $yq_path"
        return
    fi

    local arch
    arch=$(uname -m)
    local yq_binary

    case "$arch" in
        x86_64)
            yq_binary="yq_linux_amd64"
            ;;
        aarch64|arm64)
            yq_binary="yq_linux_arm64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 2
            ;;
    esac

    local yq_version="v4.40.5"
    log_info "Installing yq $yq_version for $arch..."

    if [[ $DRY_RUN -eq 0 ]]; then
        cd /tmp
        wget -q "https://github.com/mikefarah/yq/releases/download/${yq_version}/${yq_binary}.tar.gz" -O yq.tar.gz
        tar xzf yq.tar.gz
        sudo mv "${yq_binary}" /usr/local/bin/yq
        sudo chmod +x /usr/local/bin/yq
        rm -f yq.tar.gz yq.1 install_yq.sh
        cd - > /dev/null
    fi

    log_success "yq installed"
}

# Main installation flow
main() {
    log_header "VPS Ubuntu Headless Bootstrap"
    log_info "Profile: vps-minimal"
    log_info "Target: Production VPS (DigitalOcean, Hetzner, etc.)"
    echo ""

    # Parse arguments
    parse_args "$@"

    # Show configuration
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "🔍 DRY RUN MODE - No changes will be made"
    fi

    log_info "Configuration:"
    log_info "  Docker: $([ $WITH_DOCKER -eq 1 ] && echo 'Yes' || echo 'No')"
    log_info "  Security Hardening: $([ $SKIP_HARDENING -eq 1 ] && echo 'Skipped' || echo 'Enabled')"
    log_info "  Monitoring: $([ $SKIP_MONITORING -eq 1 ] && echo 'Skipped' || echo 'Enabled')"
    log_info "  UFW Firewall: $([ $NO_UFW -eq 1 ] && echo 'Skipped' || echo 'Enabled')"
    echo ""

    # OS compatibility check
    check_os

    # Prerequisites check
    check_prerequisites

    # Update system
    update_system

    # Install core dependencies
    install_core_dependencies

    # Install dotfiles tools
    install_1password_cli
    install_rclone
    install_yq

    # Security hardening
    if [[ $SKIP_HARDENING -eq 0 ]]; then
        log_step "Security Hardening"
        if [[ -f "$SCRIPT_DIR/../security/harden-vps.sh" ]]; then
            local hardening_opts=""
            [[ $NO_UFW -eq 1 ]] && hardening_opts="$hardening_opts --no-ufw"
            [[ $DRY_RUN -eq 1 ]] && hardening_opts="$hardening_opts --dry-run"

            execute "$SCRIPT_DIR/../security/harden-vps.sh" $hardening_opts
        else
            log_warning "Security hardening script not found"
            log_info "Manual hardening recommended: ./scripts/security/harden-vps.sh"
        fi
    else
        log_warning "Security hardening skipped (not recommended for production)"
    fi

    # Monitoring setup
    if [[ $SKIP_MONITORING -eq 0 ]]; then
        log_step "Monitoring Integration"
        if [[ -f "$SCRIPT_DIR/../monitoring/setup-node-exporter.sh" ]]; then
            local monitoring_opts=""
            [[ $DRY_RUN -eq 1 ]] && monitoring_opts="--dry-run"

            execute "$SCRIPT_DIR/../monitoring/setup-node-exporter.sh" $monitoring_opts
        else
            log_warning "Monitoring setup script not found"
            log_info "Manual setup: ./scripts/monitoring/setup-node-exporter.sh"
        fi
    fi

    # Docker installation
    if [[ $WITH_DOCKER -eq 1 ]]; then
        log_step "Docker Installation"
        if [[ -f "$SCRIPT_DIR/install-docker.sh" ]]; then
            local docker_opts=""
            [[ $DRY_RUN -eq 1 ]] && docker_opts="--dry-run"

            execute "$SCRIPT_DIR/install-docker.sh" $docker_opts
        else
            log_error "Docker installation script not found"
            log_info "Install manually: ./scripts/bootstrap/install-docker.sh"
        fi
    fi

    # Summary
    echo ""
    log_header "Bootstrap Complete!"

    if [[ $DRY_RUN -eq 0 ]]; then
        log_success "VPS Ubuntu minimal setup completed successfully"
        echo ""
        log_info "Next steps:"
        echo "  1. Deploy dotfiles: cd ~/dotfiles && make stow"
        echo "  2. Configure 1Password: op signin"
        echo "  3. Setup SSH keys: ./scripts/setup-ssh-keys.sh"
        echo "  4. Configure Rclone: ./scripts/sync/setup-rclone.sh"

        if [[ $SKIP_HARDENING -eq 0 ]]; then
            echo ""
            log_warning "Security Changes Applied:"
            echo "  - SSH password authentication disabled"
            echo "  - Root SSH login disabled"
            if [[ $NO_UFW -eq 0 ]]; then
                echo "  - UFW firewall enabled (ports: 22, 80, 443)"
            fi
            echo "  - fail2ban active"
            echo "  - Automatic security updates enabled"
            echo ""
            log_info "⚠️  IMPORTANT: Test SSH connection in a new terminal before logging out!"
        fi

        if [[ $SKIP_MONITORING -eq 0 ]]; then
            echo ""
            log_info "Monitoring:"
            echo "  - Prometheus node_exporter running on localhost:9100"
            echo "  - Metrics available at http://localhost:9100/metrics"
        fi

        if [[ $WITH_DOCKER -eq 1 ]]; then
            echo ""
            log_info "Docker:"
            echo "  - Docker Engine installed and running"
            echo "  - Test with: docker run hello-world"
            echo "  - Setup remote context: ./scripts/docker/setup-remote-context.sh"
        fi
    else
        log_info "Dry run completed - no changes made"
    fi

    echo ""
    log_success "🎉 VPS bootstrap completed!"
}

# Run main function
main "$@"
