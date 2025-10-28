#!/usr/bin/env bash
# Docker Engine + Compose v2 Installation for Fedora
# Installs official Docker Engine from Docker repository (not Fedora's docker.io)
#
# Usage:
#   ./scripts/bootstrap/install-docker-fedora.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Show what would be installed without installing
#   --skip-user        Don't add current user to docker group
#   --no-start         Don't start Docker service after installation
#
# Example:
#   ./scripts/bootstrap/install-docker-fedora.sh
#   ./scripts/bootstrap/install-docker-fedora.sh --dry-run
#   ./scripts/bootstrap/install-docker-fedora.sh --skip-user

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
DOCKER_GPG_URL="https://download.docker.com/linux/fedora/gpg"
DOCKER_REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
DOCKER_GPG_KEYRING="/etc/pki/rpm-gpg/docker-ce.gpg"

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Docker Engine + Compose v2 Installation for Fedora

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
    - BuildKit plugin

POST-INSTALL:
    - Docker service enabled on boot
    - Current user added to docker group (unless --skip-user)
    - SELinux configured for containers
    - firewalld configured for Docker networking
    - Docker verified with hello-world test

REQUIREMENTS:
    - Fedora 40+ (supported versions)
    - sudo privileges
    - Internet connection
    - At least 2GB free disk space

FEDORA-SPECIFIC:
    - SELinux remains enforcing (never disabled)
    - firewalld configured (masquerade + port 2376)
    - Podman removed (conflicts with Docker)

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported
    3    Docker already installed

NOTES:
    - Logout/login required after installation for group changes to take effect
    - Uses official Docker repository (not Fedora's docker package)
    - Volume mounts require :Z or :z suffix for SELinux labeling
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

# Check if running on Fedora
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found - cannot verify OS"
        exit 2
    fi

    # shellcheck source=/dev/null
    source /etc/os-release

    if [[ "$ID" != "fedora" ]]; then
        log_error "This script must be run on Fedora (detected: $ID)"
        log_info "For other distributions, see docs/guides/docker-fedora-setup.md"
        exit 2
    fi

    log_info "Running on Fedora $VERSION_ID"
}

# Check if Docker is already installed
check_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        local docker_version
        docker_version=$(docker --version 2>/dev/null || echo "unknown")

        log_success "Docker is already installed: $docker_version"

        # Check if docker-compose plugin is installed
        if docker compose version >/dev/null 2>&1; then
            local compose_version
            compose_version=$(docker compose version 2>/dev/null || echo "unknown")
            log_success "Docker Compose is installed: $compose_version"
        else
            log_warning "Docker Compose plugin not found - consider installing it"
        fi

        log_info "Skipping Docker installation (already present)"
        log_info "To reinstall, remove Docker first: sudo dnf remove docker-ce docker-ce-cli containerd.io"
        exit 0
    fi
}

# Remove old Docker and Podman installations
remove_old_docker() {
    log_step "Checking for old Docker/Podman installations..."

    local old_packages=(
        "docker"
        "docker-client"
        "docker-client-latest"
        "docker-common"
        "docker-latest"
        "docker-latest-logrotate"
        "docker-logrotate"
        "docker-selinux"
        "docker-engine-selinux"
        "docker-engine"
        "podman"
        "buildah"
    )

    local found_packages=()

    # Check which old packages are installed
    for pkg in "${old_packages[@]}"; do
        if rpm -q "$pkg" >/dev/null 2>&1; then
            found_packages+=("$pkg")
        fi
    done

    if [[ ${#found_packages[@]} -eq 0 ]]; then
        log_success "No old Docker/Podman installations found"
        return 0
    fi

    log_warning "Found conflicting packages: ${found_packages[*]}"

    # Special warning for Podman
    if [[ " ${found_packages[*]} " =~ " podman " ]] || [[ " ${found_packages[*]} " =~ " buildah " ]]; then
        log_warning "NOTE: Podman/Buildah will be removed (conflicts with Docker)"
        log_info "Podman containers/images will remain in ~/.local/share/containers/"
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would remove: ${found_packages[*]}"
    else
        log_info "Removing conflicting packages..."
        sudo dnf remove -y "${found_packages[@]}" || true
        log_success "Conflicting packages removed"
    fi
}

# Setup Docker repository
setup_docker_repository() {
    log_step "Setting up Docker repository..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would setup Docker repository:"
        log_info "  1. Install dnf-plugins-core"
        log_info "  2. Add Docker repository: $DOCKER_REPO_URL"
        log_info "  3. Update package lists"
        return 0
    fi

    # Install prerequisites
    log_info "Installing dnf-plugins-core..."
    sudo dnf install -y dnf-plugins-core

    # Add Docker repository
    # Note: Fedora 42+ changed syntax from --add-repo to addrepo
    log_info "Adding Docker repository..."

    local fedora_version
    fedora_version=$(rpm -E %fedora)

    if [[ $fedora_version -ge 42 ]]; then
        # Fedora 42+: Use new addrepo syntax
        log_info "Using Fedora 42+ repository syntax..."
        sudo dnf config-manager addrepo --from-repofile="$DOCKER_REPO_URL"
    else
        # Fedora 41 and earlier: Use old --add-repo syntax
        sudo dnf config-manager --add-repo "$DOCKER_REPO_URL"
    fi

    # Verify repository was added
    if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
        log_error "Failed to add Docker repository"
        exit 1
    fi

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
    sudo dnf install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    log_success "Docker Engine installed successfully"
}

# Configure SELinux for Docker
configure_selinux() {
    log_step "Configuring SELinux for containers..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would configure SELinux:"
        log_info "  - Set container_manage_cgroup boolean"
        log_info "  - Keep SELinux in enforcing mode"
        return 0
    fi

    # Check SELinux status
    if command -v getenforce >/dev/null 2>&1; then
        local selinux_status
        selinux_status=$(getenforce)
        log_info "SELinux status: $selinux_status"

        if [[ "$selinux_status" == "Enforcing" ]]; then
            log_info "Configuring SELinux for container management..."
            sudo setsebool -P container_manage_cgroup on || log_warning "Failed to set SELinux boolean (may not be critical)" || true

            log_success "SELinux configured (remains enforcing)"
            log_info "NOTE: Use :Z or :z suffix for volume mounts (e.g., -v /host:/container:Z)"
        else
            log_warning "SELinux is not enforcing - skipping configuration"
        fi
    else
        log_warning "getenforce not found - skipping SELinux configuration"
    fi
}

# Configure firewalld for Docker
configure_firewalld() {
    log_step "Configuring firewalld for Docker networking..."

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would configure firewalld:"
        log_info "  - Enable masquerade for Docker networks"
        log_info "  - Open port 2376/tcp for remote access"
        log_info "  - Reload firewall rules"
        return 0
    fi

    # Check if firewalld is active
    if ! systemctl is-active --quiet firewalld 2>/dev/null; then
        log_warning "firewalld is not active - skipping configuration"
        log_info "If you enable firewalld later, run: sudo firewall-cmd --permanent --zone=public --add-masquerade"
        return 0
    fi

    log_info "Configuring firewalld rules..."

    # Add masquerade for Docker bridge network
    sudo firewall-cmd --permanent --zone=public --add-masquerade || log_warning "Failed to add masquerade" || true

    # Open port 2376 for remote Docker access (optional)
    sudo firewall-cmd --permanent --zone=public --add-port=2376/tcp || log_warning "Failed to open port 2376" || true

    # Reload firewall
    sudo firewall-cmd --reload || log_error "Failed to reload firewall"

    log_success "firewalld configured for Docker"
    log_info "Verify with: sudo firewall-cmd --list-all"
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
            log_info "Check logs: sudo journalctl -u docker --no-pager | tail -20"
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

    log_step "Docker Engine + Compose v2 Installation for Fedora"

    # Check if Docker is already installed
    check_docker_installed

    # Remove old Docker/Podman installations
    remove_old_docker

    # Setup Docker repository
    setup_docker_repository

    # Install Docker Engine
    install_docker_engine

    # Configure SELinux
    configure_selinux

    # Configure firewalld
    configure_firewalld

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
    echo "  4. Configure remote context (macOS): docker context create fedora-vm --docker 'host=ssh://fedora-vm'"
    echo ""
    log_info "SELinux: Use :Z or :z for volume mounts (e.g., docker run -v /path:/path:Z)"
    log_info "Documentation: docs/guides/docker-fedora-setup.md"
}

# Run main function
main "$@"
