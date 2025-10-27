#!/usr/bin/env bash
# Docker Remote Context Setup Script
# Configures Docker to connect to remote VPS via SSH
#
# Features:
#   - Creates Docker context for remote VPS
#   - Uses SSH for secure connection
#   - Works with Tailscale VPN for secure access
#   - Allows switching between local and remote Docker
#   - No TCP port exposure required (SSH only)
#
# Usage:
#   ./scripts/docker/setup-remote-context.sh [OPTIONS] <hostname>
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --name NAME        Context name (default: hostname)
#   --user USER        SSH user (default: current user)
#   --port PORT        SSH port (default: 22)
#   --set-default      Set as default Docker context
#   --test             Test connection after setup
#
# Example:
#   ./scripts/docker/setup-remote-context.sh vps.example.com
#   ./scripts/docker/setup-remote-context.sh --name prod-vps --user ubuntu vps-ip
#   ./scripts/docker/setup-remote-context.sh --set-default vps.tailscale-alias

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Configuration
VERBOSE=0
CONTEXT_NAME=""
SSH_USER="${USER}"
SSH_PORT=22
SET_DEFAULT=0
TEST_CONNECTION=0
HOSTNAME=""

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Docker Remote Context Setup Script

Configures Docker to connect to a remote VPS via SSH, enabling you to manage
remote Docker containers from your local machine.

USAGE:
    $0 [OPTIONS] <hostname>

ARGUMENTS:
    hostname            VPS hostname or IP address (required)

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Show detailed output
    --name NAME             Context name (default: hostname)
    --user USER             SSH user (default: $USER)
    --port PORT             SSH port (default: 22)
    --set-default           Set as default Docker context
    --test                  Test connection after setup

EXAMPLES:
    # Basic setup
    $0 vps.example.com

    # Custom SSH user and port
    $0 --user ubuntu --port 2222 vps.example.com

    # Set as default context
    $0 --name production --set-default prod-vps.com

    # With Tailscale
    $0 --name vps-tailscale vps-hostname.tailscale-alias

WHAT THIS DOES:
    1. Creates a new Docker context pointing to remote VPS
    2. Configures SSH connection for secure communication
    3. Optionally sets as default context
    4. Tests connection if requested

USAGE AFTER SETUP:
    # List contexts
    docker context ls

    # Switch to remote context
    docker context use <context-name>

    # Run commands on remote Docker
    docker ps
    docker images
    docker-compose up -d

    # Switch back to local
    docker context use default

REQUIREMENTS:
    - Docker installed locally
    - SSH access to remote VPS (key-based authentication)
    - Docker installed on remote VPS
    - User has docker group permissions on remote VPS
    - Network connectivity (direct or via Tailscale)

SECURITY:
    - Uses SSH for secure communication (no TCP port exposure)
    - Leverages existing SSH key authentication
    - Works through Tailscale VPN for added security
    - No Docker daemon exposed to internet

TAILSCALE INTEGRATION:
    If using Tailscale:
      1. Ensure both machines are on Tailscale network
      2. Use Tailscale hostname: hostname.tailscale-alias
      3. Connection is encrypted and requires no firewall rules

    Example:
      $0 --name vps vps-ubuntu.tailnet-name

TROUBLESHOOTING:
    If connection fails:
      1. Test SSH: ssh user@hostname
      2. Check Docker on remote: ssh user@hostname docker ps
      3. Verify user in docker group: ssh user@hostname groups
      4. Check Docker socket: ssh user@hostname ls -l /var/run/docker.sock

    Common issues:
      - User not in docker group: Add with 'sudo usermod -aG docker \$USER'
      - SSH key not configured: Set up with 'ssh-copy-id user@hostname'
      - Docker not running: Start with 'sudo systemctl start docker'

NOTES:
    - Context persists across Docker restarts
    - Can have multiple contexts configured
    - Switch contexts with 'docker context use <name>'
    - Remove context with 'docker context rm <name>'

EXIT CODES:
    0    Success
    1    General error
    2    Missing requirements
    3    Connection test failed

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
            --name)
                if [[ -n "$2" ]]; then
                    CONTEXT_NAME="$2"
                    shift 2
                else
                    log_error "Context name not specified"
                    exit 1
                fi
                ;;
            --user)
                if [[ -n "$2" ]]; then
                    SSH_USER="$2"
                    shift 2
                else
                    log_error "SSH user not specified"
                    exit 1
                fi
                ;;
            --port)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    SSH_PORT="$2"
                    shift 2
                else
                    log_error "Invalid SSH port: $2"
                    exit 1
                fi
                ;;
            --set-default)
                SET_DEFAULT=1
                shift
                ;;
            --test)
                TEST_CONNECTION=1
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Run '$0 --help' for usage information."
                exit 1
                ;;
            *)
                if [[ -z "$HOSTNAME" ]]; then
                    HOSTNAME="$1"
                    shift
                else
                    log_error "Multiple hostnames provided"
                    exit 1
                fi
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$HOSTNAME" ]]; then
        log_error "Hostname is required"
        echo "Usage: $0 [OPTIONS] <hostname>"
        echo "Run '$0 --help' for more information."
        exit 1
    fi

    # Set default context name if not provided
    if [[ -z "$CONTEXT_NAME" ]]; then
        CONTEXT_NAME="$HOSTNAME"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking Prerequisites"

    # Check Docker installed locally
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed locally"
        log_info "Install Docker: https://docs.docker.com/get-docker/"
        exit 2
    fi
    log_success "Docker installed locally"

    # Check Docker running locally
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running locally"
        log_info "Start Docker: sudo systemctl start docker (Linux) or Docker Desktop (macOS)"
        exit 2
    fi
    log_success "Docker daemon running locally"

    # Check SSH connectivity
    log_info "Testing SSH connection to $HOSTNAME..."
    if ssh -p "$SSH_PORT" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${SSH_USER}@${HOSTNAME}" "echo SSH connection OK" &> /dev/null; then
        log_success "SSH connection successful"
    else
        log_error "Cannot connect via SSH to ${SSH_USER}@${HOSTNAME}:${SSH_PORT}"
        log_info "Test manually: ssh -p $SSH_PORT ${SSH_USER}@${HOSTNAME}"
        exit 2
    fi

    # Check Docker on remote
    log_info "Checking Docker on remote VPS..."
    if ssh -p "$SSH_PORT" "${SSH_USER}@${HOSTNAME}" "command -v docker" &> /dev/null; then
        log_success "Docker installed on remote VPS"
    else
        log_error "Docker is not installed on remote VPS"
        log_info "Install Docker on VPS: ./scripts/bootstrap/install-docker.sh"
        exit 2
    fi

    # Check Docker permissions on remote
    log_info "Checking Docker permissions on remote..."
    if ssh -p "$SSH_PORT" "${SSH_USER}@${HOSTNAME}" "docker ps" &> /dev/null; then
        log_success "User has Docker permissions on remote"
    else
        log_error "User ${SSH_USER} cannot run Docker on remote VPS"
        log_info "Add user to docker group: ssh ${SSH_USER}@${HOSTNAME} 'sudo usermod -aG docker ${SSH_USER}'"
        log_info "Then logout and login again for group changes to take effect"
        exit 2
    fi
}

# Create Docker context
create_context() {
    log_step "Creating Docker Context"

    # Check if context already exists
    if docker context inspect "$CONTEXT_NAME" &> /dev/null; then
        log_warning "Context '$CONTEXT_NAME' already exists"
        log_info "Remove it first: docker context rm $CONTEXT_NAME"
        exit 3
    fi

    # Build SSH URL
    local ssh_url="ssh://${SSH_USER}@${HOSTNAME}"
    if [[ $SSH_PORT -ne 22 ]]; then
        ssh_url="${ssh_url}:${SSH_PORT}"
    fi

    log_info "Creating context '$CONTEXT_NAME'..."
    log_info "SSH URL: $ssh_url"

    if [[ $VERBOSE -eq 1 ]]; then
        docker context create "$CONTEXT_NAME" --docker "host=$ssh_url"
    else
        docker context create "$CONTEXT_NAME" --docker "host=$ssh_url" > /dev/null
    fi

    log_success "Context '$CONTEXT_NAME' created"
}

# Set as default context
set_default_context() {
    if [[ $SET_DEFAULT -eq 1 ]]; then
        log_step "Setting Default Context"

        log_info "Setting '$CONTEXT_NAME' as default Docker context..."
        docker context use "$CONTEXT_NAME"

        log_success "Default context set to '$CONTEXT_NAME'"
        log_warning "All docker commands will now run on remote VPS"
        log_info "Switch back to local: docker context use default"
    fi
}

# Test connection
test_connection() {
    if [[ $TEST_CONNECTION -eq 1 ]]; then
        log_step "Testing Docker Connection"

        log_info "Switching to context '$CONTEXT_NAME'..."
        local original_context
        original_context=$(docker context show)

        docker context use "$CONTEXT_NAME" > /dev/null

        log_info "Running test command: docker version"
        if docker version &> /dev/null; then
            log_success "Connection test successful"

            # Show Docker info
            echo ""
            log_info "Remote Docker Information:"
            docker version --format '  Server Version: {{.Server.Version}}'
            docker version --format '  OS/Arch: {{.Server.Os}}/{{.Server.Arch}}'
            docker info --format '  Containers: {{.Containers}} ({{.ContainersRunning}} running)'
            docker info --format '  Images: {{.Images}}'
        else
            log_error "Connection test failed"
            docker context use "$original_context" > /dev/null
            exit 3
        fi

        # Restore original context if needed
        if [[ $SET_DEFAULT -eq 0 ]]; then
            log_info "Restoring original context: $original_context"
            docker context use "$original_context" > /dev/null
        fi
    fi
}

# Main setup flow
main() {
    log_header "Docker Remote Context Setup"
    echo ""

    # Parse arguments
    parse_args "$@"

    # Show configuration
    log_info "Configuration:"
    log_info "  Context Name: $CONTEXT_NAME"
    log_info "  Hostname: $HOSTNAME"
    log_info "  SSH User: $SSH_USER"
    log_info "  SSH Port: $SSH_PORT"
    log_info "  Set as Default: $([ $SET_DEFAULT -eq 1 ] && echo 'Yes' || echo 'No')"
    log_info "  Test Connection: $([ $TEST_CONNECTION -eq 1 ] && echo 'Yes' || echo 'No')"
    echo ""

    # Check prerequisites
    check_prerequisites

    # Create context
    create_context

    # Set as default
    set_default_context

    # Test connection
    test_connection

    # Summary
    echo ""
    log_header "Docker Context Setup Complete!"

    log_success "Remote Docker context '$CONTEXT_NAME' configured successfully"
    echo ""
    log_info "Usage:"
    echo "  # List all contexts"
    echo "  docker context ls"
    echo ""
    echo "  # Switch to remote context"
    echo "  docker context use $CONTEXT_NAME"
    echo ""
    echo "  # Run commands on remote Docker"
    echo "  docker ps"
    echo "  docker images"
    echo "  docker run hello-world"
    echo ""
    echo "  # Switch back to local Docker"
    echo "  docker context use default"
    echo ""
    log_info "Current context: $(docker context show)"

    if [[ $SET_DEFAULT -eq 1 ]]; then
        log_warning "⚠️  Default context is now '$CONTEXT_NAME' (remote VPS)"
        log_info "All docker commands will run on remote VPS until you switch back"
    fi

    echo ""
    log_success "🐳 Remote Docker access configured!"
}

# Run main function
main "$@"
