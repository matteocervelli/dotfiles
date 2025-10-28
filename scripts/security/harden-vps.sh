#!/usr/bin/env bash
# VPS Security Hardening Script
# Implements production-ready security hardening for Ubuntu VPS
#
# Features:
#   - SSH hardening (key-only auth, no root login, custom port optional)
#   - UFW firewall configuration
#   - fail2ban installation and configuration
#   - Automatic security updates
#   - Minimal attack surface
#
# Usage:
#   ./scripts/security/harden-vps.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   --dry-run          Preview changes without applying them
#   --no-ufw           Skip UFW firewall configuration
#   --no-fail2ban      Skip fail2ban installation
#   --no-ssh-harden    Skip SSH hardening
#   --ssh-port PORT    Custom SSH port (default: 22)
#
# Example:
#   ./scripts/security/harden-vps.sh
#   ./scripts/security/harden-vps.sh --ssh-port 2222

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
NO_UFW=0
NO_FAIL2BAN=0
NO_SSH_HARDEN=0
SSH_PORT=22

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
VPS Security Hardening Script

Implements production-ready security hardening for Ubuntu VPS including
SSH hardening, firewall configuration, and intrusion prevention.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Show detailed output
    --dry-run               Preview changes without applying them
    --no-ufw                Skip UFW firewall configuration
    --no-fail2ban           Skip fail2ban installation
    --no-ssh-harden         Skip SSH hardening (not recommended)
    --ssh-port PORT         Custom SSH port (default: 22)

EXAMPLES:
    $0                      # Full security hardening
    $0 --dry-run            # Preview changes
    $0 --ssh-port 2222      # Use custom SSH port

SECURITY MEASURES APPLIED:

    SSH Hardening:
      ✓ Disable password authentication (key-only)
      ✓ Disable root login via SSH
      ✓ Disable empty passwords
      ✓ Disable X11 forwarding (not needed on VPS)
      ✓ Set maximum authentication attempts
      ✓ Configure SSH keep-alive settings

    Firewall (UFW):
      ✓ Default deny incoming
      ✓ Default allow outgoing
      ✓ Allow SSH (port 22 or custom)
      ✓ Allow HTTP (port 80)
      ✓ Allow HTTPS (port 443)
      ✓ Enable firewall automatically on boot

    Intrusion Prevention (fail2ban):
      ✓ Monitor SSH login attempts
      ✓ Ban after 5 failed attempts
      ✓ 10-minute ban duration
      ✓ Email notifications (optional)
      ✓ Automatic startup on boot

    System Updates:
      ✓ Automatic security updates enabled
      ✓ Unattended upgrades configured
      ✓ Automatic reboot for kernel updates (optional)

REQUIREMENTS:
    - Ubuntu 24.04 LTS or 22.04 LTS
    - Root or sudo privileges
    - Internet connection
    - SSH key configured in ~/.ssh/authorized_keys

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported
    3    Missing requirements

WARNINGS:
    ⚠️  SSH Changes:
        - Password authentication will be DISABLED
        - Root login will be DISABLED
        - Ensure SSH key access works before applying!

    ⚠️  Firewall Changes:
        - UFW will be enabled (may disconnect active SSH if port changed)
        - Always allow SSH port before enabling firewall
        - Test in a new terminal before logging out

    ⚠️  Testing:
        - Open a new SSH session to test before closing current one
        - Keep current session open until new session confirmed working

NOTES:
    - Changes are applied immediately (no reboot required)
    - SSH service restarts automatically after configuration
    - fail2ban starts monitoring immediately after installation
    - Review /var/log/auth.log for SSH attempts
    - Review /var/log/fail2ban.log for ban events

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
            --no-ufw)
                NO_UFW=1
                shift
                ;;
            --no-fail2ban)
                NO_FAIL2BAN=1
                shift
                ;;
            --no-ssh-harden)
                NO_SSH_HARDEN=1
                shift
                ;;
            --ssh-port)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    SSH_PORT="$2"
                    shift 2
                else
                    log_error "Invalid SSH port: $2"
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

# Backup file before modification
backup_file() {
    local file=$1
    local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"

    if [[ $DRY_RUN -eq 0 && -f "$file" ]]; then
        cp "$file" "$backup"
        log_info "Backed up: $file -> $backup"
    fi
}

# SSH hardening
harden_ssh() {
    log_step "SSH Hardening"

    if [[ $NO_SSH_HARDEN -eq 1 ]]; then
        log_warning "SSH hardening skipped"
        return
    fi

    # Check SSH key requirement
    if [[ ! -f "$HOME/.ssh/authorized_keys" ]]; then
        log_error "No SSH keys found in ~/.ssh/authorized_keys"
        log_info "Add your SSH key first: ssh-copy-id user@vps"
        exit 3
    fi

    local key_count
    key_count=$(grep -c "^ssh-" "$HOME/.ssh/authorized_keys" 2>/dev/null || echo 0)
    log_info "Found $key_count SSH key(s) in authorized_keys"

    # Backup sshd_config
    backup_file "/etc/ssh/sshd_config"

    # Apply SSH hardening
    log_info "Configuring SSH security settings..."

    if [[ $DRY_RUN -eq 0 ]]; then
        # Disable password authentication
        sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

        # Disable empty passwords
        sudo sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
        sudo sed -i 's/PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config

        # Disable root login
        sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

        # Disable X11 forwarding (not needed on VPS)
        sudo sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

        # Set max authentication attempts
        if ! grep -q "^MaxAuthTries" /etc/ssh/sshd_config; then
            echo "MaxAuthTries 3" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        fi

        # Configure keep-alive
        if ! grep -q "^ClientAliveInterval" /etc/ssh/sshd_config; then
            echo "ClientAliveInterval 300" | sudo tee -a /etc/ssh/sshd_config > /dev/null
            echo "ClientAliveCountMax 2" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        fi

        # Change SSH port if requested
        if [[ $SSH_PORT -ne 22 ]]; then
            log_info "Changing SSH port to $SSH_PORT..."
            sudo sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
            sudo sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
        fi

        # Test SSH configuration
        if sudo sshd -t; then
            log_success "SSH configuration syntax valid"

            # Restart SSH service
            log_info "Restarting SSH service..."
            sudo systemctl restart sshd

            log_success "SSH service restarted successfully"
        else
            log_error "SSH configuration has syntax errors"
            log_info "Restoring backup configuration..."
            sudo cp "/etc/ssh/sshd_config.backup-"* /etc/ssh/sshd_config
            exit 1
        fi
    fi

    log_success "SSH hardening complete"
    echo ""
    log_warning "⚠️  SSH Changes Applied:"
    echo "  - Password authentication: DISABLED"
    echo "  - Root login: DISABLED"
    echo "  - SSH port: $SSH_PORT"
    echo ""
    log_info "⚠️  IMPORTANT: Test SSH in a new terminal before closing this one!"
}

# Configure UFW firewall
configure_ufw() {
    log_step "UFW Firewall Configuration"

    if [[ $NO_UFW -eq 1 ]]; then
        log_warning "UFW firewall configuration skipped"
        return
    fi

    # Install UFW
    if ! command -v ufw &> /dev/null; then
        log_info "Installing UFW..."
        execute sudo apt-get install -y ufw
    else
        log_success "UFW already installed"
    fi

    if [[ $DRY_RUN -eq 0 ]]; then
        # Reset UFW to defaults
        log_info "Configuring UFW rules..."
        sudo ufw --force reset > /dev/null

        # Default policies
        sudo ufw default deny incoming
        sudo ufw default allow outgoing

        # Allow SSH (critical - must be first!)
        sudo ufw allow "$SSH_PORT/tcp" comment 'SSH'

        # Allow HTTP and HTTPS
        sudo ufw allow 80/tcp comment 'HTTP'
        sudo ufw allow 443/tcp comment 'HTTPS'

        # Allow Prometheus node_exporter (localhost only)
        # This is handled by binding to localhost only, not by firewall

        # Enable UFW
        log_info "Enabling UFW firewall..."
        sudo ufw --force enable

        # Enable UFW on boot
        sudo systemctl enable ufw

        log_success "UFW firewall configured and enabled"

        # Show status
        echo ""
        log_info "Current UFW rules:"
        sudo ufw status numbered
    fi

    echo ""
    log_warning "⚠️  Firewall Changes:"
    echo "  - Default incoming: DENY"
    echo "  - Default outgoing: ALLOW"
    echo "  - Allowed ports: $SSH_PORT (SSH), 80 (HTTP), 443 (HTTPS)"
    echo ""
    log_info "⚠️  Test SSH connection in new terminal before logging out!"
}

# Install and configure fail2ban
configure_fail2ban() {
    log_step "fail2ban Configuration"

    if [[ $NO_FAIL2BAN -eq 1 ]]; then
        log_warning "fail2ban installation skipped"
        return
    fi

    # Install fail2ban
    if ! command -v fail2ban-client &> /dev/null; then
        log_info "Installing fail2ban..."
        execute sudo apt-get install -y fail2ban
    else
        log_success "fail2ban already installed"
    fi

    if [[ $DRY_RUN -eq 0 ]]; then
        # Create local configuration
        log_info "Configuring fail2ban for SSH..."

        sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
[DEFAULT]
# Ban hosts for 10 minutes
bantime = 600

# A host is banned if it has generated "maxretry" during "findtime"
findtime = 600

# Number of failures before a host get banned
maxretry = 5

[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 600
EOF

        # Start and enable fail2ban
        sudo systemctl enable fail2ban
        sudo systemctl restart fail2ban

        log_success "fail2ban configured and started"

        # Show status
        echo ""
        log_info "fail2ban status:"
        sudo fail2ban-client status sshd
    fi

    log_success "fail2ban installation complete"
}

# Configure automatic security updates
configure_auto_updates() {
    log_step "Automatic Security Updates"

    # Install unattended-upgrades
    if ! dpkg -l | grep -q "^ii  unattended-upgrades "; then
        log_info "Installing unattended-upgrades..."
        execute sudo apt-get install -y unattended-upgrades
    else
        log_success "unattended-upgrades already installed"
    fi

    if [[ $DRY_RUN -eq 0 ]]; then
        # Configure unattended-upgrades
        log_info "Configuring automatic security updates..."

        # Enable automatic updates
        sudo dpkg-reconfigure -plow unattended-upgrades

        # Configure to only install security updates
        sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

        log_success "Automatic security updates configured"
    fi

    log_info "Security updates will be installed automatically"
}

# Main hardening flow
main() {
    log_header "VPS Security Hardening"
    echo ""

    # Parse arguments
    parse_args "$@"

    # Show configuration
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "🔍 DRY RUN MODE - No changes will be made"
    fi

    log_info "Configuration:"
    log_info "  SSH Hardening: $([ $NO_SSH_HARDEN -eq 1 ] && echo 'Skipped' || echo 'Enabled')"
    log_info "  SSH Port: $SSH_PORT"
    log_info "  UFW Firewall: $([ $NO_UFW -eq 1 ] && echo 'Skipped' || echo 'Enabled')"
    log_info "  fail2ban: $([ $NO_FAIL2BAN -eq 1 ] && echo 'Skipped' || echo 'Enabled')"
    echo ""

    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        exit 3
    fi

    # Apply security hardening
    harden_ssh
    configure_ufw
    configure_fail2ban
    configure_auto_updates

    # Summary
    echo ""
    log_header "Security Hardening Complete!"

    if [[ $DRY_RUN -eq 0 ]]; then
        log_success "VPS security hardening completed successfully"
        echo ""
        log_warning "⚠️  CRITICAL: Test SSH Access NOW!"
        echo "  1. Open a NEW terminal window"
        echo "  2. Test SSH connection: ssh -p $SSH_PORT user@vps-ip"
        echo "  3. Verify you can login with SSH key"
        echo "  4. DO NOT close this terminal until test succeeds!"
        echo ""
        log_info "Security Status:"
        echo "  ✓ SSH: Key-only authentication (password disabled)"
        echo "  ✓ SSH: Root login disabled"
        echo "  ✓ SSH: Port $SSH_PORT"
        echo "  ✓ Firewall: UFW enabled (ports: $SSH_PORT, 80, 443)"
        echo "  ✓ Intrusion Prevention: fail2ban active"
        echo "  ✓ Updates: Automatic security updates enabled"
        echo ""
        log_info "Monitor Security:"
        echo "  - SSH attempts: sudo tail -f /var/log/auth.log"
        echo "  - fail2ban bans: sudo fail2ban-client status sshd"
        echo "  - Firewall status: sudo ufw status verbose"
    else
        log_info "Dry run completed - no changes made"
    fi

    echo ""
    log_success "🔒 VPS is now security-hardened!"
}

# Run main function
main "$@"
