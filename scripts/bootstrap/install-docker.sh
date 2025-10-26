#!/usr/bin/env bash
# Docker Engine + Compose v2 Installation for Ubuntu
# Installs official Docker Engine from Docker repository (not Ubuntu's docker.io)
#
# Usage:
#   ./scripts/bootstrap/install-docker.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Show what would be installed without installing
#   --skip-user        Don't add current user to docker group
#   --no-start         Don't start Docker service after installation
#
# Example:
#   ./scripts/bootstrap/install-docker.sh
#   ./scripts/bootstrap/install-docker.sh --dry-run
#   ./scripts/bootstrap/install-docker.sh --skip-user

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
SKIP_USER=0
NO_START=0

# Docker repository configuration
DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
DOCKER_GPG_KEYRING="/usr/share/keyrings/docker-archive-keyring.gpg"

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Docker Engine + Compose v2 Installation for Ubuntu

Installs official Docker Engine from Docker repository with Compose v2 plugin.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help         Show this help message
    -v, --verbose      Show detailed output
    --dry-run          Preview installation without making changes
    --skip-user        Don't add current user to docker group
    --no-start         Don't start Docker service after installation

EXAMPLES:
    $0                      # Full installation with defaults
    $0 --dry-run            # Preview what would be installed
    $0 --skip-user          # Install but don't modify user groups

WHAT GETS INSTALLED:
    - Docker Engine (latest stable)
    - Docker Compose v2 (plugin, not standalone)
    - Docker CLI tools
    - Containerd runtime

POST-INSTALL:
    - Docker service enabled on boot
    - Current user added to docker group (unless --skip-user)
    - Docker verified with hello-world test

REQUIREMENTS:
    - Ubuntu 24.04 LTS (Noble Numbat) or compatible
    - sudo privileges
    - Internet connection
    - At least 2GB free disk space

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported
    3    Docker already installed

NOTES:
    - Logout/login required after installation for group changes to take effect
    - Uses official Docker repository (not Ubuntu's docker.io package)
    - Storage driver: overlay2 (automatic)

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
            --skip-user)
                SKIP_USER=1
                shift
                ;;
            --no-start)
                NO_START=1
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
        log_info "For other distributions, see docs/guides/docker-ubuntu-setup.md"
        exit 2
    fi

    log_info "Running on Ubuntu $VERSION_ID ($VERSION_CODENAME)"
}

# Check if Docker is already installed
check_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        local docker_version
        docker_version=$(docker --version 2>/dev/null || echo "unknown")

        log_warning "Docker is already installed: $docker_version"
        log_info "To reinstall, remove Docker first: sudo apt remove docker-ce docker-ce-cli containerd.io"
        exit 3
    fi
}

# Remove old Docker installations
remove_old_docker() {
    log_step "Checking for old Docker installations..."

    local old_packages=(
        "docker"
        "docker-engine"
        "docker.io"
        "containerd"
        "runc"
    )

    local found_packages=()

    # Check which old packages are installed
    for pkg in "${old_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg " 2>/dev/null; then
            found_packages+=("$pkg")
        fi
    done

    if [[ ${#found_packages[@]} -eq 0 ]]; then
        log_success "No old Docker installations found"
        return 0
    fi

    log_warning "Found old Docker packages: ${found_packages[*]}"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would remove: ${found_packages[*]}"
    else
        log_info "Removing old Docker packages..."
        sudo apt-get remove -y "${found_packages[@]}" || true
        log_success "Old Docker packages removed"
    fi
}

# Setup Docker repository
setup_docker_repository() {
    log_step "Setting up Docker repository..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would setup Docker repository:"
        log_info "  1. Download GPG key from $DOCKER_GPG_URL"
        log_info "  2. Add Docker repository: $DOCKER_REPO_URL"
        log_info "  3. Update package lists"
        return 0
    fi

    # Install prerequisites
    log_info "Installing prerequisites..."
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    log_info "Adding Docker GPG key..."
    sudo mkdir -p "$(dirname "$DOCKER_GPG_KEYRING")"

    curl -fsSL "$DOCKER_GPG_URL" | sudo gpg --dearmor -o "$DOCKER_GPG_KEYRING"

    # Verify GPG key was added
    if [[ ! -f "$DOCKER_GPG_KEYRING" ]]; then
        log_error "Failed to add Docker GPG key"
        exit 1
    fi

    # Set up the repository
    log_info "Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_GPG_KEYRING] $DOCKER_REPO_URL \
        $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package lists
    log_info "Updating package lists..."
    sudo apt-get update

    log_success "Docker repository configured"
}

# Install Docker Engine
install_docker_engine() {
    log_step "Installing Docker Engine + Compose v2..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install:"
        log_info "  - docker-ce (Docker Engine)"
        log_info "  - docker-ce-cli (Docker CLI)"
        log_info "  - containerd.io (Container runtime)"
        log_info "  - docker-buildx-plugin (BuildKit)"
        log_info "  - docker-compose-plugin (Compose v2)"
        return 0
    fi

    # Install Docker packages
    log_info "Installing Docker packages (this may take a few minutes)..."
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    log_success "Docker Engine installed successfully"
}

# Configure Docker service
configure_docker_service() {
    log_step "Configuring Docker service..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would configure Docker service:"
        log_info "  - Enable Docker on boot"
        [[ $NO_START -eq 0 ]] && log_info "  - Start Docker service" || true
        return 0
    fi

    # Enable Docker service on boot
    log_info "Enabling Docker service on boot..."
    sudo systemctl enable docker

    # Start Docker service (unless --no-start)
    if [[ $NO_START -eq 0 ]]; then
        log_info "Starting Docker service..."
        sudo systemctl start docker

        # Wait for Docker to be ready
        local retries=10
        while [[ $retries -gt 0 ]]; do
            if sudo systemctl is-active --quiet docker; then
                break
            fi
            sleep 1
            ((retries--))
        done

        if [[ $retries -eq 0 ]]; then
            log_error "Docker service failed to start"
            exit 1
        fi

        log_success "Docker service started"
    else
        log_info "Skipping Docker service start (--no-start)"
    fi
}

# Add user to docker group
configure_user_permissions() {
    if [[ $SKIP_USER -eq 1 ]]; then
        log_info "Skipping user group configuration (--skip-user)"
        return 0
    fi

    log_step "Configuring user permissions..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would add user '$USER' to docker group"
        return 0
    fi

    # Add user to docker group
    log_info "Adding user '$USER' to docker group..."
    sudo usermod -aG docker "$USER"

    log_success "User added to docker group"
    log_warning "IMPORTANT: You must log out and log back in for group changes to take effect!"
    log_info "After logout/login, you can run docker commands without sudo"
}

# Verify Docker installation
verify_installation() {
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would verify Docker installation"
        return 0
    fi

    if [[ $NO_START -eq 1 ]]; then
        log_info "Skipping verification (Docker service not started)"
        return 0
    fi

    log_step "Verifying Docker installation..."

    # Check Docker version
    log_info "Docker version:"
    sudo docker version || log_error "Docker version check failed"

    # Check Docker Compose version
    log_info "Docker Compose version:"
    sudo docker compose version || log_error "Docker Compose version check failed"

    # Run hello-world test
    log_info "Running hello-world test..."
    if sudo docker run --rm hello-world >/dev/null 2>&1; then
        log_success "Docker hello-world test passed"
    else
        log_warning "Docker hello-world test failed (may need manual investigation)"
    fi

    # Check service status
    log_info "Docker service status:"
    sudo systemctl status docker --no-pager | head -3 || true

    log_success "Docker installation verified"
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

    log_step "Docker Engine + Compose v2 Installation"

    # Check if Docker is already installed
    check_docker_installed

    # Remove old Docker installations
    remove_old_docker

    # Setup Docker repository
    setup_docker_repository

    # Install Docker Engine
    install_docker_engine

    # Configure Docker service
    configure_docker_service

    # Configure user permissions
    configure_user_permissions

    # Verify installation
    verify_installation

    # Final summary
    echo ""
    log_success "Docker installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Log out and log back in (for docker group to take effect)"
    echo "  2. Test Docker: docker run hello-world"
    echo "  3. Test Compose: docker compose version"
    echo "  4. Configure remote context (macOS): docker context create ubuntu-vm --docker 'host=ssh://ubuntu-vm'"
    echo ""
    log_info "Documentation: docs/guides/docker-ubuntu-setup.md"
}

# Run main function
main "$@"
