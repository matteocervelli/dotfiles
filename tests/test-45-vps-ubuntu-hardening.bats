#!/usr/bin/env bats
# Tests for Issue #45 - VPS Ubuntu Security Hardening & Headless Setup
#
# Tests the VPS bootstrap, security hardening, monitoring, and Docker remote
# context scripts.
#
# Usage:
#   bats tests/test-45-vps-ubuntu-hardening.bats
#
# Note: These are unit tests for scripts, not integration tests.
# Full VPS setup requires actual Ubuntu VPS system.

setup() {
    # Project root directory
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

    # Scripts to test
    VPS_BOOTSTRAP="$PROJECT_ROOT/scripts/bootstrap/vps-ubuntu-bootstrap.sh"
    SECURITY_SCRIPT="$PROJECT_ROOT/scripts/security/harden-vps.sh"
    MONITORING_SCRIPT="$PROJECT_ROOT/scripts/monitoring/setup-node-exporter.sh"
    DOCKER_CONTEXT_SCRIPT="$PROJECT_ROOT/scripts/docker/setup-remote-context.sh"
}

# =============================================================================
# File Existence Tests
# =============================================================================

@test "VPS bootstrap script exists" {
    [ -f "$VPS_BOOTSTRAP" ]
}

@test "VPS bootstrap script is executable" {
    [ -x "$VPS_BOOTSTRAP" ]
}

@test "Security hardening script exists" {
    [ -f "$SECURITY_SCRIPT" ]
}

@test "Security hardening script is executable" {
    [ -x "$SECURITY_SCRIPT" ]
}

@test "Monitoring setup script exists" {
    [ -f "$MONITORING_SCRIPT" ]
}

@test "Monitoring setup script is executable" {
    [ -x "$MONITORING_SCRIPT" ]
}

@test "Docker remote context script exists" {
    [ -f "$DOCKER_CONTEXT_SCRIPT" ]
}

@test "Docker remote context script is executable" {
    [ -x "$DOCKER_CONTEXT_SCRIPT" ]
}

# =============================================================================
# VPS Bootstrap Script Tests
# =============================================================================

@test "VPS bootstrap shows help with --help" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VPS Ubuntu Headless Bootstrap" ]]
    [[ "$output" =~ "USAGE:" ]]
}

@test "VPS bootstrap shows help with -h" {
    run "$VPS_BOOTSTRAP" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VPS Ubuntu Headless Bootstrap" ]]
}

@test "VPS bootstrap supports --dry-run flag" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--dry-run" ]]
}

@test "VPS bootstrap supports --with-docker flag" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--with-docker" ]]
}

@test "VPS bootstrap supports --skip-hardening flag" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--skip-hardening" ]]
}

@test "VPS bootstrap supports --skip-monitoring flag" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--skip-monitoring" ]]
}

@test "VPS bootstrap supports --no-ufw flag" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--no-ufw" ]]
}

@test "VPS bootstrap mentions vps-minimal profile" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "vps-minimal" ]] || [[ "$output" =~ "Profile: vps-minimal" ]]
}

@test "VPS bootstrap mentions security hardening" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Security" ]] || [[ "$output" =~ "security" ]]
    [[ "$output" =~ "fail2ban" ]]
    [[ "$output" =~ "UFW" ]] || [[ "$output" =~ "firewall" ]]
}

@test "VPS bootstrap mentions monitoring" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Monitoring" ]] || [[ "$output" =~ "monitoring" ]]
    [[ "$output" =~ "node_exporter" ]]
}

@test "VPS bootstrap warns about SSH key requirement" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SSH key" ]] || [[ "$output" =~ "authorized_keys" ]]
}

# =============================================================================
# Security Hardening Script Tests
# =============================================================================

@test "Security script shows help with --help" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VPS Security Hardening" ]]
    [[ "$output" =~ "USAGE:" ]]
}

@test "Security script shows help with -h" {
    run "$SECURITY_SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "VPS Security Hardening" ]]
}

@test "Security script supports --dry-run flag" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--dry-run" ]]
}

@test "Security script supports --no-ufw flag" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--no-ufw" ]]
}

@test "Security script supports --no-fail2ban flag" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--no-fail2ban" ]]
}

@test "Security script supports --no-ssh-harden flag" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--no-ssh-harden" ]]
}

@test "Security script supports --ssh-port flag" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--ssh-port" ]]
}

@test "Security script mentions SSH hardening features" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "password authentication" ]] || [[ "$output" =~ "PasswordAuthentication" ]]
    [[ "$output" =~ "root login" ]] || [[ "$output" =~ "PermitRootLogin" ]]
}

@test "Security script mentions fail2ban configuration" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "fail2ban" ]]
    [[ "$output" =~ "5 failed attempts" ]] || [[ "$output" =~ "maxretry" ]]
    [[ "$output" =~ "10-minute ban" ]] || [[ "$output" =~ "ban duration" ]]
}

@test "Security script mentions UFW firewall rules" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "UFW" ]] || [[ "$output" =~ "firewall" ]]
    [[ "$output" =~ "port 22" ]] || [[ "$output" =~ "SSH" ]]
    [[ "$output" =~ "port 80" ]] || [[ "$output" =~ "HTTP" ]]
    [[ "$output" =~ "port 443" ]] || [[ "$output" =~ "HTTPS" ]]
}

@test "Security script mentions automatic security updates" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "automatic" ]] || [[ "$output" =~ "unattended-upgrades" ]]
    [[ "$output" =~ "security updates" ]] || [[ "$output" =~ "Security Updates" ]]
}

@test "Security script warns about SSH password authentication" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DISABLED" ]] || [[ "$output" =~ "disabled" ]]
    [[ "$output" =~ "SSH key" ]] || [[ "$output" =~ "authorized_keys" ]]
}

# =============================================================================
# Monitoring Setup Script Tests
# =============================================================================

@test "Monitoring script shows help with --help" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Prometheus Node Exporter" ]]
    [[ "$output" =~ "USAGE:" ]]
}

@test "Monitoring script shows help with -h" {
    run "$MONITORING_SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Prometheus Node Exporter" ]]
}

@test "Monitoring script supports --dry-run flag" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--dry-run" ]]
}

@test "Monitoring script supports --bind-all flag" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--bind-all" ]]
}

@test "Monitoring script supports --port flag" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--port" ]]
}

@test "Monitoring script supports --version flag" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--version" ]]
}

@test "Monitoring script mentions default port 9100" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "9100" ]]
}

@test "Monitoring script mentions metrics types" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CPU" ]] || [[ "$output" =~ "cpu" ]]
    [[ "$output" =~ "memory" ]] || [[ "$output" =~ "Memory" ]]
    [[ "$output" =~ "disk" ]] || [[ "$output" =~ "Disk" ]]
    [[ "$output" =~ "network" ]] || [[ "$output" =~ "Network" ]]
}

@test "Monitoring script mentions localhost binding by default" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "localhost" ]] || [[ "$output" =~ "127.0.0.1" ]]
}

@test "Monitoring script mentions Prometheus integration" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Prometheus" ]] || [[ "$output" =~ "prometheus" ]]
    [[ "$output" =~ "scrape" ]] || [[ "$output" =~ "prometheus.yml" ]]
}

@test "Monitoring script mentions Grafana dashboard" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Grafana" ]] || [[ "$output" =~ "grafana" ]]
    [[ "$output" =~ "dashboard" ]] || [[ "$output" =~ "1860" ]]
}

# =============================================================================
# Docker Remote Context Script Tests
# =============================================================================

@test "Docker context script shows help with --help" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Docker Remote Context" ]]
    [[ "$output" =~ "USAGE:" ]]
}

@test "Docker context script shows help with -h" {
    run "$DOCKER_CONTEXT_SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Docker Remote Context" ]]
}

@test "Docker context script requires hostname argument" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "hostname" ]] || [[ "$output" =~ "<hostname>" ]]
}

@test "Docker context script supports --name flag" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--name" ]]
}

@test "Docker context script supports --user flag" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--user" ]]
}

@test "Docker context script supports --port flag" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--port" ]]
}

@test "Docker context script supports --set-default flag" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--set-default" ]]
}

@test "Docker context script supports --test flag" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--test" ]]
}

@test "Docker context script mentions SSH connection" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SSH" ]] || [[ "$output" =~ "ssh" ]]
}

@test "Docker context script mentions Tailscale integration" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Tailscale" ]] || [[ "$output" =~ "tailscale" ]]
}

@test "Docker context script mentions context switching" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "docker context use" ]] || [[ "$output" =~ "context ls" ]]
}

@test "Docker context script fails without hostname" {
    run "$DOCKER_CONTEXT_SCRIPT"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "required" ]] || [[ "$output" =~ "Hostname" ]]
}

# =============================================================================
# Script Integration Tests
# =============================================================================

@test "VPS bootstrap references security hardening script" {
    grep -q "harden-vps.sh" "$VPS_BOOTSTRAP"
}

@test "VPS bootstrap references monitoring setup script" {
    grep -q "setup-node-exporter.sh" "$VPS_BOOTSTRAP"
}

@test "VPS bootstrap references Docker installation script" {
    grep -q "install-docker.sh" "$VPS_BOOTSTRAP"
}

@test "Security script sources logger utility" {
    grep -q "source.*logger.sh" "$SECURITY_SCRIPT"
}

@test "Monitoring script sources logger utility" {
    grep -q "source.*logger.sh" "$MONITORING_SCRIPT"
}

@test "Docker context script sources logger utility" {
    grep -q "source.*logger.sh" "$DOCKER_CONTEXT_SCRIPT"
}

# =============================================================================
# Script Content Validation Tests
# =============================================================================

@test "Security script has SSH hardening function" {
    grep -q "harden_ssh" "$SECURITY_SCRIPT"
}

@test "Security script has UFW configuration function" {
    grep -q "configure_ufw" "$SECURITY_SCRIPT"
}

@test "Security script has fail2ban configuration function" {
    grep -q "configure_fail2ban" "$SECURITY_SCRIPT"
}

@test "Security script has automatic updates function" {
    grep -q "configure_auto_updates" "$SECURITY_SCRIPT"
}

@test "Monitoring script has user creation function" {
    grep -q "create_user" "$MONITORING_SCRIPT"
}

@test "Monitoring script has node_exporter installation function" {
    grep -q "install_node_exporter" "$MONITORING_SCRIPT"
}

@test "Monitoring script has systemd service creation function" {
    grep -q "create_systemd_service" "$MONITORING_SCRIPT"
}

@test "Docker context script has prerequisites check function" {
    grep -q "check_prerequisites" "$DOCKER_CONTEXT_SCRIPT"
}

@test "Docker context script has context creation function" {
    grep -q "create_context" "$DOCKER_CONTEXT_SCRIPT"
}

# =============================================================================
# Security Validation Tests
# =============================================================================

@test "Security script disables password authentication" {
    grep -q "PasswordAuthentication no" "$SECURITY_SCRIPT"
}

@test "Security script disables root login" {
    grep -q "PermitRootLogin no" "$SECURITY_SCRIPT"
}

@test "Security script configures fail2ban jail" {
    grep -q "jail.local" "$SECURITY_SCRIPT"
}

@test "Security script configures UFW default deny incoming" {
    grep -q "default deny incoming" "$SECURITY_SCRIPT"
}

@test "Security script allows SSH through firewall" {
    grep -q "ufw allow.*22\|ufw allow.*SSH" "$SECURITY_SCRIPT"
}

@test "Monitoring script binds to localhost by default" {
    grep -q "127.0.0.1" "$MONITORING_SCRIPT"
}

@test "Monitoring script creates dedicated user" {
    grep -q "useradd.*node_exporter" "$MONITORING_SCRIPT"
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "VPS bootstrap has comprehensive help text" {
    run "$VPS_BOOTSTRAP" --help
    [ "$status" -eq 0 ]
    # Check for key sections
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
    [[ "$output" =~ "EXAMPLES:" ]]
    [[ "$output" =~ "REQUIREMENTS:" ]]
}

@test "Security script has comprehensive help text" {
    run "$SECURITY_SCRIPT" --help
    [ "$status" -eq 0 ]
    # Check for key sections
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
    [[ "$output" =~ "EXAMPLES:" ]]
    [[ "$output" =~ "SECURITY MEASURES" ]]
}

@test "Monitoring script has comprehensive help text" {
    run "$MONITORING_SCRIPT" --help
    [ "$status" -eq 0 ]
    # Check for key sections
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
    [[ "$output" =~ "EXAMPLES:" ]]
    [[ "$output" =~ "INTEGRATION:" ]]
}

@test "Docker context script has comprehensive help text" {
    run "$DOCKER_CONTEXT_SCRIPT" --help
    [ "$status" -eq 0 ]
    # Check for key sections
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
    [[ "$output" =~ "EXAMPLES:" ]]
    [[ "$output" =~ "TROUBLESHOOTING:" ]]
}
