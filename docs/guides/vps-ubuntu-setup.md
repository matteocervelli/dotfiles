# VPS Ubuntu Security Hardening & Headless Setup Guide

**Issue**: [#45](https://github.com/matteocervelli/dotfiles/issues/45)
**Profile**: `vps-minimal`
**Target**: Ubuntu 24.04 LTS (Headless) on cloud VPS
**Created**: 2025-10-27
**Status**: ✅ Complete

---

## Overview

This guide covers complete setup of a production-ready Ubuntu VPS with security hardening, monitoring, and optional Docker installation. Designed for cloud providers like DigitalOcean, Hetzner, Linode, and AWS.

### Features

- **Minimal Installation**: Headless setup (no GUI), optimized for 2-4GB RAM
- **Security Hardening**: fail2ban, UFW firewall, SSH key-only authentication
- **Monitoring**: Prometheus node_exporter for system metrics
- **Docker Support**: Optional Docker Engine + Compose v2
- **Remote Access**: Docker remote context via SSH

### Profile: vps-minimal

- **Role**: `security`
- **Packages**: Essential tools only (no desktop applications)
- **Services**: SSH, UFW, fail2ban, node_exporter, Docker (optional)
- **Resource Usage**: < 500MB RAM idle, 2-10% CPU

---

## Prerequisites

### Before You Start

1. **VPS Requirements**:
   - Ubuntu 24.04 LTS or 22.04 LTS
   - x86_64 (AMD/Intel) architecture
   - Minimum 2GB RAM, 2 vCPU
   - 50GB+ disk space
   - Root or sudo access

2. **Local Machine Requirements**:
   - SSH key generated: `ssh-keygen -t ed25519 -C "your_email@example.com"`
   - SSH access to VPS: `ssh-copy-id user@vps-ip`
   - Git installed (to clone dotfiles repository)

3. **Security Requirements**:
   - **CRITICAL**: SSH key must be added to VPS before hardening
   - Password authentication will be disabled
   - Root login will be disabled
   - Test SSH connection first: `ssh user@vps-ip`

### VPS Providers

Tested and recommended providers:

| Provider | Plan | CPU | RAM | Disk | Price | Notes |
|----------|------|-----|-----|------|-------|-------|
| **Hetzner** | CX11 | 1 vCPU | 2GB | 20GB | €4.15/mo | Best value, AMD CPUs |
| **DigitalOcean** | Basic | 1 vCPU | 2GB | 50GB | $12/mo | Premium network |
| **Linode** | Shared | 1 vCPU | 2GB | 50GB | $12/mo | Good performance |
| **Vultr** | Regular | 1 vCPU | 2GB | 55GB | $12/mo | Multiple locations |

**Recommendation**: Hetzner CX11 (best price/performance for Europe)

---

## Quick Start

### 1. Initial VPS Setup

```bash
# SSH into VPS (first time, using password)
ssh root@your-vps-ip

# Create non-root user
adduser yourusername
usermod -aG sudo yourusername

# Copy SSH key from root to new user
mkdir -p /home/yourusername/.ssh
cp /root/.ssh/authorized_keys /home/yourusername/.ssh/
chown -R yourusername:yourusername /home/yourusername/.ssh
chmod 700 /home/yourusername/.ssh
chmod 600 /home/yourusername/.ssh/authorized_keys

# Test new user login (from local machine, new terminal)
ssh yourusername@your-vps-ip
```

### 2. Clone Dotfiles Repository

```bash
# On VPS (as non-root user)
cd ~
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
```

### 3. Run VPS Bootstrap

```bash
# Basic VPS setup (security + monitoring)
./scripts/bootstrap/vps-ubuntu-bootstrap.sh

# With Docker
./scripts/bootstrap/vps-ubuntu-bootstrap.sh --with-docker

# Dry run (preview changes)
./scripts/bootstrap/vps-ubuntu-bootstrap.sh --dry-run
```

### 4. Deploy Dotfiles

```bash
# Stow essential packages
make stow

# Or manually
stow -t ~ shell git ssh 1password
```

### 5. Test SSH Connection

**CRITICAL**: Before logging out, test SSH in a new terminal:

```bash
# From local machine (new terminal)
ssh yourusername@your-vps-ip

# Test sudo access
sudo whoami

# Should output: root
```

✅ **If successful**: Your VPS is ready!
❌ **If failed**: DO NOT close original SSH session, troubleshoot first

---

## Detailed Setup Steps

### Step 1: Security Hardening

The bootstrap script automatically applies security hardening:

```bash
# Manual security hardening (if needed)
./scripts/security/harden-vps.sh

# Dry run
./scripts/security/harden-vps.sh --dry-run

# Custom SSH port
./scripts/security/harden-vps.sh --ssh-port 2222
```

**What Gets Configured:**

1. **SSH Hardening**:
   - ✓ Password authentication: DISABLED
   - ✓ Root login: DISABLED
   - ✓ Empty passwords: DISABLED
   - ✓ X11 forwarding: DISABLED
   - ✓ Max auth attempts: 3
   - ✓ Keep-alive: 300s

2. **UFW Firewall**:
   - ✓ Default incoming: DENY
   - ✓ Default outgoing: ALLOW
   - ✓ Allowed ports:
     - 22 (SSH)
     - 80 (HTTP)
     - 443 (HTTPS)

3. **fail2ban**:
   - ✓ Monitor SSH login attempts
   - ✓ Ban after 5 failed attempts
   - ✓ Ban duration: 10 minutes
   - ✓ Auto-start on boot

4. **Automatic Updates**:
   - ✓ Security updates: ENABLED
   - ✓ Unattended upgrades: CONFIGURED
   - ✓ Automatic reboot: DISABLED (manual control)

### Step 2: Monitoring Setup

Prometheus node_exporter for system metrics:

```bash
# Manual monitoring setup (if needed)
./scripts/monitoring/setup-node-exporter.sh

# Bind to all interfaces (less secure, use with firewall)
./scripts/monitoring/setup-node-exporter.sh --bind-all

# Custom port
./scripts/monitoring/setup-node-exporter.sh --port 9200
```

**Metrics Collected:**

- CPU usage and load average
- Memory usage (total, free, cached, buffers)
- Disk I/O and usage (read/write ops, latency)
- Network traffic (bytes in/out, packets, errors)
- System uptime and boot time
- File descriptor usage
- Context switches and interrupts

**Accessing Metrics:**

```bash
# Local access (on VPS)
curl http://localhost:9100/metrics

# Remote access via SSH tunnel (from local machine)
ssh -L 9100:localhost:9100 yourusername@your-vps-ip

# Then visit: http://localhost:9100/metrics in browser
```

### Step 3: Docker Installation (Optional)

```bash
# Install Docker
./scripts/bootstrap/install-docker.sh

# Or during bootstrap
./scripts/bootstrap/vps-ubuntu-bootstrap.sh --with-docker
```

**Docker Configuration:**

- Docker Engine (latest stable)
- Docker Compose v2 (plugin)
- Systemd service (auto-start on boot)
- User added to docker group
- Storage driver: overlay2 (automatic)

**Post-Install:**

```bash
# Verify Docker
docker version
docker compose version

# Test Docker
docker run hello-world

# Start a service
docker run -d -p 8080:80 nginx
```

### Step 4: Remote Docker Context

Access Docker on VPS from local machine:

```bash
# From local machine
cd ~/dotfiles
./scripts/docker/setup-remote-context.sh --name vps-production your-vps-ip

# Set as default
./scripts/docker/setup-remote-context.sh --set-default --test vps-production

# Switch to remote context
docker context use vps-production

# Run commands on remote Docker
docker ps
docker images

# Switch back to local
docker context use default
```

**With Tailscale:**

```bash
# Use Tailscale hostname (more secure)
./scripts/docker/setup-remote-context.sh --name vps vps-hostname.tailscale-alias
```

---

## Configuration Options

### Bootstrap Script Options

```bash
./scripts/bootstrap/vps-ubuntu-bootstrap.sh [OPTIONS]

Options:
  --dry-run             Preview changes without applying
  --with-docker         Install Docker Engine + Compose v2
  --skip-hardening      Skip security hardening (not recommended)
  --skip-monitoring     Skip node_exporter setup
  --no-ufw              Don't configure UFW firewall
```

### Security Script Options

```bash
./scripts/security/harden-vps.sh [OPTIONS]

Options:
  --dry-run             Preview security changes
  --no-ufw              Skip UFW firewall
  --no-fail2ban         Skip fail2ban installation
  --no-ssh-harden       Skip SSH hardening (not recommended)
  --ssh-port PORT       Custom SSH port (default: 22)
```

### Monitoring Script Options

```bash
./scripts/monitoring/setup-node-exporter.sh [OPTIONS]

Options:
  --dry-run             Preview installation
  --bind-all            Bind to 0.0.0.0 (external access)
  --port PORT           Custom port (default: 9100)
  --version VERSION     Specific node_exporter version
```

---

## Post-Installation

### Verify Installation

```bash
# Check SSH configuration
sudo cat /etc/ssh/sshd_config | grep -E "(PasswordAuthentication|PermitRootLogin)"

# Check UFW status
sudo ufw status verbose

# Check fail2ban
sudo systemctl status fail2ban
sudo fail2ban-client status sshd

# Check node_exporter
sudo systemctl status node_exporter
curl http://localhost:9100/metrics | head -n 10

# Check Docker (if installed)
docker version
docker ps
```

### Monitor Security

```bash
# SSH login attempts
sudo tail -f /var/log/auth.log

# fail2ban activity
sudo tail -f /var/log/fail2ban.log

# fail2ban banned IPs
sudo fail2ban-client status sshd

# Unban IP
sudo fail2ban-client set sshd unbanip 1.2.3.4

# Firewall rules
sudo ufw status numbered

# System logs
sudo journalctl -f
```

### Prometheus + Grafana Integration

1. **Configure Prometheus** (on monitoring server):

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'vps-production'
    static_configs:
      - targets: ['vps-hostname:9100']
        labels:
          environment: 'production'
          role: 'vps'
```

2. **Import Grafana Dashboard**:
   - Dashboard ID: 1860 (Node Exporter Full)
   - URL: https://grafana.com/grafana/dashboards/1860

3. **Access via SSH Tunnel** (if node_exporter on localhost only):

```bash
# Create SSH tunnel from Prometheus server
ssh -L 9100:localhost:9100 user@vps-ip

# Or use Tailscale for secure access
```

---

## Troubleshooting

### SSH Access Issues

**Problem**: Cannot SSH after hardening

```bash
# From original SSH session (DO NOT CLOSE THIS)
sudo systemctl status sshd

# Check SSH configuration syntax
sudo sshd -t

# Restore backup configuration
sudo cp /etc/ssh/sshd_config.backup-* /etc/ssh/sshd_config
sudo systemctl restart sshd
```

**Problem**: SSH key not working

```bash
# Check authorized_keys permissions
ls -la ~/.ssh/authorized_keys
# Should be: -rw------- (600)

# Fix permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Verify key format
cat ~/.ssh/authorized_keys
# Should start with: ssh-ed25519, ssh-rsa, or ecdsa-sha2-nistp256
```

### Firewall Issues

**Problem**: Locked out after enabling UFW

```bash
# From VPS console (provider web console)
sudo ufw disable
sudo ufw allow 22/tcp
sudo ufw enable
```

**Problem**: Cannot access HTTP/HTTPS

```bash
# Check UFW rules
sudo ufw status numbered

# Add rules
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
```

### fail2ban Issues

**Problem**: Banned my own IP

```bash
# Check banned IPs
sudo fail2ban-client status sshd

# Unban your IP
sudo fail2ban-client set sshd unbanip YOUR_IP

# Whitelist your IP permanently
sudo tee -a /etc/fail2ban/jail.local << EOF
[sshd]
ignoreip = 127.0.0.1/8 YOUR_IP
EOF

sudo systemctl restart fail2ban
```

### Docker Issues

**Problem**: Permission denied accessing Docker

```bash
# Check user groups
groups

# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login again
exit
ssh user@vps-ip

# Verify
docker ps
```

**Problem**: Docker not starting

```bash
# Check Docker status
sudo systemctl status docker

# Check logs
sudo journalctl -u docker -n 50

# Restart Docker
sudo systemctl restart docker
```

### Monitoring Issues

**Problem**: node_exporter not accessible

```bash
# Check service status
sudo systemctl status node_exporter

# Check logs
sudo journalctl -u node_exporter -n 50

# Test locally
curl http://localhost:9100/metrics

# Check listening ports
sudo netstat -tlnp | grep 9100

# Restart service
sudo systemctl restart node_exporter
```

---

## Maintenance

### Regular Tasks

**Daily**:
- Monitor /var/log/auth.log for suspicious activity
- Check fail2ban status: `sudo fail2ban-client status sshd`

**Weekly**:
- Review system resource usage in Grafana
- Check for failed services: `sudo systemctl --failed`
- Review disk usage: `df -h`

**Monthly**:
- Review and update firewall rules
- Check for security updates: `sudo apt update && sudo apt list --upgradable`
- Review Docker images for updates: `docker images`

### Updating System

```bash
# Update packages
sudo apt update
sudo apt upgrade -y

# Auto-remove unused packages
sudo apt autoremove -y

# Clean package cache
sudo apt clean

# Check for reboot requirement
[ -f /var/run/reboot-required ] && echo "Reboot required" || echo "No reboot needed"

# Reboot if needed
sudo reboot
```

### Updating Docker

```bash
# Update Docker
sudo apt update
sudo apt install --only-upgrade docker-ce docker-ce-cli containerd.io

# Verify version
docker version
```

### Updating node_exporter

```bash
# Stop service
sudo systemctl stop node_exporter

# Backup binary
sudo cp /usr/local/bin/node_exporter /usr/local/bin/node_exporter.backup

# Reinstall (downloads latest version)
./scripts/monitoring/setup-node-exporter.sh

# Verify
curl http://localhost:9100/metrics | head -n 5
```

---

## Advanced Configuration

### Custom SSH Port

```bash
# Change SSH port to 2222
./scripts/security/harden-vps.sh --ssh-port 2222

# Update firewall
sudo ufw allow 2222/tcp comment 'SSH'
sudo ufw delete allow 22/tcp

# Test before closing session
ssh -p 2222 user@vps-ip
```

### Tailscale Integration

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate
sudo tailscale up

# Get Tailscale IP
tailscale ip -4

# Use Tailscale IP for SSH
ssh user@100.x.x.x

# Setup Docker remote context via Tailscale
./scripts/docker/setup-remote-context.sh vps-hostname.tailscale-alias
```

### Multiple VPS Management

```bash
# Clone dotfiles on each VPS
for vps in vps1 vps2 vps3; do
    ssh user@$vps "git clone https://github.com/user/dotfiles.git && cd dotfiles && ./scripts/bootstrap/vps-ubuntu-bootstrap.sh"
done

# Setup Docker contexts for each
./scripts/docker/setup-remote-context.sh --name vps1 vps1.example.com
./scripts/docker/setup-remote-context.sh --name vps2 vps2.example.com
./scripts/docker/setup-remote-context.sh --name vps3 vps3.example.com

# Switch between contexts
docker context use vps1
docker ps

docker context use vps2
docker ps
```

---

## Security Best Practices

### SSH Keys

- ✅ Use Ed25519 keys (modern, secure): `ssh-keygen -t ed25519`
- ✅ Protect private key with passphrase
- ✅ Use SSH agent: `ssh-add ~/.ssh/id_ed25519`
- ✅ Rotate keys periodically (annually)
- ❌ Never share private keys
- ❌ Don't use same key for all servers

### Firewall

- ✅ Default deny incoming, allow outgoing
- ✅ Only open required ports (SSH, HTTP, HTTPS)
- ✅ Use Tailscale for admin access (no exposed ports)
- ✅ Review rules periodically
- ❌ Don't expose unnecessary services
- ❌ Don't disable firewall

### Password Policy

- ✅ Disable SSH password authentication (use keys)
- ✅ Strong sudo password (20+ characters)
- ✅ Use 1Password for password management
- ❌ Never use weak passwords
- ❌ Don't reuse passwords

### Monitoring

- ✅ Monitor system metrics (CPU, RAM, disk)
- ✅ Set up alerts for high resource usage
- ✅ Review logs regularly
- ✅ Monitor SSH login attempts
- ❌ Don't ignore alerts
- ❌ Don't expose metrics publicly without authentication

---

## Resources

### Documentation

- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [fail2ban Wiki](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [Docker Documentation](https://docs.docker.com/)
- [Prometheus Node Exporter](https://github.com/prometheus/node_exporter)

### Related Guides

- [Ubuntu 24.04 Bootstrap Guide](../guides/linux-setup-guide.md)
- [Docker Installation Guide](../guides/docker-ubuntu-setup.md)
- [Multi-Platform Overview](../os-configurations/OVERVIEW.md)
- [Device Matrix](../os-configurations/DEVICE-MATRIX.md)

### Issue Tracking

- [Issue #45 - VPS Ubuntu Security Hardening](https://github.com/matteocervelli/dotfiles/issues/45)
- [FASE 7.7 - VPS Ubuntu Headless Setup](../TASK.md#77-vps-ubuntu-headless--security-hardening-issue-45)

---

**Created**: 2025-10-27
**Last Updated**: 2025-10-27
**Maintained By**: Matteo Cervelli
**Project**: [dotfiles](https://github.com/matteocervelli/dotfiles)
