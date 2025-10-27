#!/usr/bin/env bash
# Prometheus Node Exporter Setup Script
# Installs and configures Prometheus node_exporter for system metrics
#
# Features:
#   - Installs latest node_exporter from official releases
#   - Configures systemd service for automatic startup
#   - Binds to localhost only (security)
#   - Collects CPU, memory, disk, network metrics
#   - Low resource overhead (~10MB RAM)
#
# Usage:
#   ./scripts/monitoring/setup-node-exporter.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Preview installation without making changes
#   --bind-all         Bind to all interfaces (0.0.0.0) instead of localhost
#   --port PORT        Custom port (default: 9100)
#   --version VERSION  Specific node_exporter version (default: latest)
#
# Example:
#   ./scripts/monitoring/setup-node-exporter.sh
#   ./scripts/monitoring/setup-node-exporter.sh --port 9200

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
BIND_ALL=0
NODE_EXPORTER_PORT=9100
NODE_EXPORTER_VERSION="latest"

# Installation paths
NODE_EXPORTER_USER="node_exporter"
NODE_EXPORTER_BIN="/usr/local/bin/node_exporter"
NODE_EXPORTER_SERVICE="/etc/systemd/system/node_exporter.service"

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Prometheus Node Exporter Setup Script

Installs and configures Prometheus node_exporter for system metrics collection.
Provides CPU, memory, disk, network, and other system metrics.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Show detailed output
    --dry-run               Preview installation without making changes
    --bind-all              Bind to all interfaces (0.0.0.0) instead of localhost
    --port PORT             Custom port (default: 9100)
    --version VERSION       Specific node_exporter version (default: latest)

EXAMPLES:
    $0                      # Standard installation (localhost:9100)
    $0 --dry-run            # Preview installation
    $0 --bind-all           # Expose metrics externally (less secure)
    $0 --port 9200          # Use custom port

WHAT GETS INSTALLED:
    - Prometheus node_exporter binary (latest version)
    - Systemd service for automatic startup
    - Dedicated node_exporter user (no shell, no home)

METRICS COLLECTED:
    - CPU usage and load average
    - Memory usage (total, free, cached)
    - Disk I/O and usage
    - Network traffic (bytes, packets)
    - System uptime and boot time
    - File descriptor usage
    - Context switches and interrupts

REQUIREMENTS:
    - Ubuntu 24.04 LTS or 22.04 LTS
    - Root or sudo privileges
    - Internet connection
    - ~10MB disk space
    - ~10MB RAM

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported
    3    Missing requirements

SECURITY:
    Default Configuration:
      - Binds to localhost only (127.0.0.1:9100)
      - Not accessible from external network
      - No authentication (use firewall/VPN for remote access)
      - Dedicated non-privileged user

    External Access (--bind-all):
      - Metrics accessible from network
      - Use with firewall rules or Tailscale VPN
      - Consider adding authentication proxy (nginx + basic auth)

INTEGRATION:
    Prometheus Configuration:
      - Add this scrape target to prometheus.yml:

        scrape_configs:
          - job_name: 'node'
            static_configs:
              - targets: ['vps-hostname:9100']

    Grafana Dashboard:
      - Import dashboard: 1860 (Node Exporter Full)
      - URL: https://grafana.com/grafana/dashboards/1860

    Test Metrics:
      - curl http://localhost:9100/metrics

NOTES:
    - Starts automatically on boot
    - Low resource overhead (~10MB RAM, <1% CPU)
    - Metrics updated every 15s (Prometheus scrape interval)
    - Safe to run on production systems

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
            --bind-all)
                BIND_ALL=1
                shift
                ;;
            --port)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    NODE_EXPORTER_PORT="$2"
                    shift 2
                else
                    log_error "Invalid port: $2"
                    exit 1
                fi
                ;;
            --version)
                if [[ -n "$2" ]]; then
                    NODE_EXPORTER_VERSION="$2"
                    shift 2
                else
                    log_error "Version not specified"
                    exit 1
                fi
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

# Get latest node_exporter version
get_latest_version() {
    if [[ "$NODE_EXPORTER_VERSION" != "latest" ]]; then
        echo "$NODE_EXPORTER_VERSION"
        return
    fi

    local version
    version=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

    if [[ -z "$version" ]]; then
        log_error "Failed to fetch latest version"
        exit 1
    fi

    echo "$version"
}

# Detect architecture
detect_architecture() {
    local arch
    arch=$(uname -m)

    case "$arch" in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armv7"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 2
            ;;
    esac
}

# Check if node_exporter is already installed
check_existing_installation() {
    if systemctl is-active --quiet node_exporter 2>/dev/null; then
        log_warning "node_exporter service is already running"
        log_info "To reinstall, stop and disable first:"
        log_info "  sudo systemctl stop node_exporter"
        log_info "  sudo systemctl disable node_exporter"
        exit 3
    fi

    if [[ -f "$NODE_EXPORTER_BIN" ]]; then
        log_warning "node_exporter binary already exists at $NODE_EXPORTER_BIN"
        log_info "Remove it first: sudo rm $NODE_EXPORTER_BIN"
        exit 3
    fi
}

# Create node_exporter user
create_user() {
    log_step "Creating node_exporter User"

    if id "$NODE_EXPORTER_USER" &>/dev/null; then
        log_success "User $NODE_EXPORTER_USER already exists"
        return
    fi

    log_info "Creating dedicated user: $NODE_EXPORTER_USER"
    execute sudo useradd --no-create-home --shell /bin/false "$NODE_EXPORTER_USER"

    log_success "User created"
}

# Download and install node_exporter
install_node_exporter() {
    log_step "Installing Node Exporter"

    local version
    version=$(get_latest_version)
    log_info "Version: $version"

    local arch
    arch=$(detect_architecture)
    log_info "Architecture: $arch"

    local download_url="https://github.com/prometheus/node_exporter/releases/download/v${version}/node_exporter-${version}.linux-${arch}.tar.gz"
    local temp_dir="/tmp/node_exporter_install"

    if [[ $DRY_RUN -eq 0 ]]; then
        # Create temp directory
        mkdir -p "$temp_dir"
        cd "$temp_dir"

        # Download
        log_info "Downloading node_exporter..."
        if ! wget -q --show-progress "$download_url" -O node_exporter.tar.gz; then
            log_error "Failed to download node_exporter"
            rm -rf "$temp_dir"
            exit 1
        fi

        # Extract
        log_info "Extracting archive..."
        tar xzf node_exporter.tar.gz

        # Find binary
        local binary_path
        binary_path=$(find . -name "node_exporter" -type f | head -1)

        if [[ ! -f "$binary_path" ]]; then
            log_error "node_exporter binary not found in archive"
            rm -rf "$temp_dir"
            exit 1
        fi

        # Install binary
        log_info "Installing to $NODE_EXPORTER_BIN..."
        sudo cp "$binary_path" "$NODE_EXPORTER_BIN"
        sudo chown "$NODE_EXPORTER_USER:$NODE_EXPORTER_USER" "$NODE_EXPORTER_BIN"
        sudo chmod +x "$NODE_EXPORTER_BIN"

        # Cleanup
        cd - > /dev/null
        rm -rf "$temp_dir"

        log_success "node_exporter installed"
    fi
}

# Create systemd service
create_systemd_service() {
    log_step "Creating Systemd Service"

    local listen_address="127.0.0.1"
    if [[ $BIND_ALL -eq 1 ]]; then
        listen_address="0.0.0.0"
        log_warning "⚠️  Binding to all interfaces (0.0.0.0) - metrics will be externally accessible!"
    fi

    log_info "Listen address: ${listen_address}:${NODE_EXPORTER_PORT}"

    if [[ $DRY_RUN -eq 0 ]]; then
        sudo tee "$NODE_EXPORTER_SERVICE" > /dev/null << EOF
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$NODE_EXPORTER_USER
Group=$NODE_EXPORTER_USER
ExecStart=$NODE_EXPORTER_BIN \\
  --web.listen-address=${listen_address}:${NODE_EXPORTER_PORT}

SyslogIdentifier=node_exporter
Restart=always
RestartSec=5

# Security hardening
NoNewPrivileges=true
ProtectHome=true
ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true

[Install]
WantedBy=multi-user.target
EOF

        log_success "Systemd service created"
    fi
}

# Start and enable service
start_service() {
    log_step "Starting Node Exporter Service"

    if [[ $DRY_RUN -eq 0 ]]; then
        # Reload systemd
        sudo systemctl daemon-reload

        # Enable service
        sudo systemctl enable node_exporter

        # Start service
        sudo systemctl start node_exporter

        # Wait for startup
        sleep 2

        # Check status
        if systemctl is-active --quiet node_exporter; then
            log_success "node_exporter service is running"
        else
            log_error "node_exporter service failed to start"
            log_info "Check logs: sudo journalctl -u node_exporter -n 50"
            exit 1
        fi
    fi
}

# Verify installation
verify_installation() {
    log_step "Verifying Installation"

    if [[ $DRY_RUN -eq 0 ]]; then
        local metrics_url="http://127.0.0.1:${NODE_EXPORTER_PORT}/metrics"

        log_info "Testing metrics endpoint..."
        if curl -s "$metrics_url" | head -n 5 > /dev/null; then
            log_success "Metrics endpoint responding"

            # Count metrics
            local metric_count
            metric_count=$(curl -s "$metrics_url" | grep -c "^node_" || echo 0)
            log_info "Exporting $metric_count node metrics"
        else
            log_error "Metrics endpoint not responding"
            exit 1
        fi
    fi
}

# Main installation flow
main() {
    log_header "Prometheus Node Exporter Setup"
    echo ""

    # Parse arguments
    parse_args "$@"

    # Show configuration
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "🔍 DRY RUN MODE - No changes will be made"
    fi

    log_info "Configuration:"
    log_info "  Version: $NODE_EXPORTER_VERSION"
    log_info "  Port: $NODE_EXPORTER_PORT"
    log_info "  Bind address: $([ $BIND_ALL -eq 1 ] && echo '0.0.0.0 (all interfaces)' || echo '127.0.0.1 (localhost only)')"
    echo ""

    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        exit 3
    fi

    # Check existing installation
    check_existing_installation

    # Install node_exporter
    create_user
    install_node_exporter
    create_systemd_service
    start_service
    verify_installation

    # Summary
    echo ""
    log_header "Node Exporter Installation Complete!"

    if [[ $DRY_RUN -eq 0 ]]; then
        log_success "Prometheus node_exporter installed and running"
        echo ""
        log_info "Service Information:"
        echo "  - Status: sudo systemctl status node_exporter"
        echo "  - Logs: sudo journalctl -u node_exporter -f"
        echo "  - Restart: sudo systemctl restart node_exporter"
        echo ""
        log_info "Metrics Endpoint:"
        if [[ $BIND_ALL -eq 1 ]]; then
            echo "  - URL: http://your-vps-ip:${NODE_EXPORTER_PORT}/metrics"
            log_warning "  ⚠️  Metrics are externally accessible - use firewall/VPN!"
        else
            echo "  - URL: http://localhost:${NODE_EXPORTER_PORT}/metrics"
            echo "  - Access remotely via SSH tunnel:"
            echo "    ssh -L 9100:localhost:${NODE_EXPORTER_PORT} user@vps"
        fi
        echo ""
        log_info "Prometheus Configuration:"
        echo "  Add to prometheus.yml scrape_configs:"
        echo ""
        echo "    - job_name: 'node'"
        echo "      static_configs:"
        echo "        - targets: ['vps-hostname:${NODE_EXPORTER_PORT}']"
        echo ""
        log_info "Grafana Dashboard:"
        echo "  - Import dashboard ID: 1860 (Node Exporter Full)"
        echo "  - URL: https://grafana.com/grafana/dashboards/1860"
        echo ""
        log_info "Test metrics:"
        echo "  curl http://localhost:${NODE_EXPORTER_PORT}/metrics | head -n 20"
    else
        log_info "Dry run completed - no changes made"
    fi

    echo ""
    log_success "📊 Monitoring setup complete!"
}

# Run main function
main "$@"
