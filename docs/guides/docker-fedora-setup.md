# Docker Engine + Compose v2 Setup Guide for Fedora

**Platform**: Fedora 40+ (ARM64/x86_64)
**Target Environment**: Development VM (Parallels on macOS)
**Installation Time**: 3-5 minutes
**Disk Space Required**: ~2GB

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Installation Methods](#installation-methods)
4. [Fedora-Specific Considerations](#fedora-specific-considerations)
5. [Post-Installation Configuration](#post-installation-configuration)
6. [Remote Docker Context (macOS)](#remote-docker-context-macos)
7. [Parallels VM Integration](#parallels-vm-integration)
8. [Performance Optimization](#performance-optimization)
9. [Troubleshooting](#troubleshooting)
10. [Uninstallation](#uninstallation)

---

## Quick Start

```bash
# Automated installation (recommended)
./scripts/bootstrap/install-docker-fedora.sh

# Or with Fedora bootstrap
./scripts/bootstrap/fedora-bootstrap.sh --with-docker

# Verify installation
docker --version
docker compose version
docker run hello-world
```

---

## Prerequisites

### System Requirements

- **Fedora**: Version 40+ (41, 42, 43 supported)
- **Architecture**: ARM64 (Apple Silicon via Parallels) or x86_64 (Intel/AMD)
- **RAM**: Minimum 4GB (8GB recommended for development)
- **Disk**: At least 2GB free space
- **Privileges**: sudo access required

### Check Your System

```bash
# Verify Fedora version
cat /etc/fedora-release

# Check architecture
uname -m

# Check disk space
df -h /

# Verify sudo access
sudo -v
```

---

## Installation Methods

### Method 1: Automated Script (Recommended)

```bash
# Full installation with defaults
./scripts/bootstrap/install-docker-fedora.sh

# Preview changes without installing
./scripts/bootstrap/install-docker-fedora.sh --dry-run

# Install without adding user to docker group
./scripts/bootstrap/install-docker-fedora.sh --skip-user

# Install without starting Docker service
./scripts/bootstrap/install-docker-fedora.sh --no-start
```

**What the script does**:
1. ✓ Verifies Fedora environment
2. ✓ Removes conflicting packages (old Docker, **Podman**)
3. ✓ Adds official Docker repository with GPG verification
4. ✓ Installs Docker Engine + Compose v2
5. ✓ Configures SELinux for containers
6. ✓ Configures firewalld for Docker networking
7. ✓ Enables Docker service on boot
8. ✓ Adds current user to docker group
9. ✓ Verifies installation with hello-world

### Method 2: Manual Installation

```bash
# 1. Install prerequisites
sudo dnf install -y dnf-plugins-core

# 2. Add Docker repository
sudo dnf config-manager --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

# 3. Install Docker packages
sudo dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 4. Start and enable Docker
sudo systemctl enable --now docker

# 5. Add user to docker group
sudo usermod -aG docker $USER

# 6. Configure SELinux (see section below)
sudo setsebool -P container_manage_cgroup on

# 7. Configure firewalld (see section below)
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --permanent --zone=public --add-port=2376/tcp
sudo firewall-cmd --reload

# 8. Logout and login for group changes to take effect
```

### Method 3: Integration with Fedora Bootstrap

```bash
# Full development environment + Docker
./scripts/bootstrap/fedora-bootstrap.sh --with-packages --with-docker

# Minimal environment + Docker
./scripts/bootstrap/fedora-bootstrap.sh --essential-only --with-docker
```

---

## Fedora-Specific Considerations

### SELinux (Do NOT Disable!)

Fedora uses **SELinux** (Security-Enhanced Linux) instead of Ubuntu's AppArmor. Docker works perfectly with SELinux enforcing.

#### Check SELinux Status

```bash
# Should return "Enforcing"
getenforce

# View SELinux status details
sestatus
```

#### Volume Mounts with SELinux

Docker volumes require **SELinux labels** for proper access. Use `:Z` (exclusive) or `:z` (shared) suffixes:

```bash
# Wrong (will cause permission denied)
docker run -v /host/data:/container/data nginx

# Correct - exclusive label (recommended for single container)
docker run -v /host/data:/container/data:Z nginx

# Correct - shared label (for multiple containers accessing same volume)
docker run -v /host/data:/container/data:z nginx
```

**When to use `:Z` vs `:z`**:
- **`:Z`** - Single container accesses the volume (more restrictive, more secure)
- **`:z`** - Multiple containers share the volume (less restrictive)

#### SELinux Troubleshooting

```bash
# Check for SELinux denials
sudo ausearch -m avc -ts recent

# View Docker-related denials
sudo ausearch -m avc -ts today | grep docker

# Temporarily set to permissive for testing (NOT for production!)
sudo setenforce 0

# Re-enable enforcing
sudo setenforce 1
```

### firewalld (Do NOT Disable!)

Fedora uses **firewalld** instead of Ubuntu's ufw for firewall management.

#### Configure firewalld for Docker

```bash
# Add masquerade (required for Docker bridge network)
sudo firewall-cmd --permanent --zone=public --add-masquerade

# Open port 2376 for remote Docker access (optional)
sudo firewall-cmd --permanent --zone=public --add-port=2376/tcp

# Reload firewall
sudo firewall-cmd --reload

# Verify configuration
sudo firewall-cmd --list-all
```

**Expected output**:
```
public (active)
  masquerade: yes
  ports: 2376/tcp
```

#### firewalld Troubleshooting

```bash
# Check firewall status
sudo firewall-cmd --state

# List all zones
sudo firewall-cmd --get-active-zones

# Test if port is open
sudo firewall-cmd --query-port=2376/tcp
```

### Podman Removal

Fedora ships with **Podman** by default, which conflicts with Docker. The installation script automatically removes it.

**Important Notes**:
- Podman containers/images remain in `~/.local/share/containers/`
- To backup Podman data before removal:
  ```bash
  podman save --output /tmp/podman-backup.tar $(podman images -q)
  ```
- To migrate to Docker after installation:
  ```bash
  docker load --input /tmp/podman-backup.tar
  ```

---

## Post-Installation Configuration

### User Group Changes

**After installation, you MUST logout and login** for docker group changes to take effect.

```bash
# Check if you're in docker group
groups | grep docker

# If not present, logout/login is required
exit  # Then login again

# Test Docker without sudo
docker run hello-world
```

### Docker Daemon Configuration

Create daemon configuration for production use:

```bash
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl restart docker
```

### Enable Parallel Downloads

Optimize DNF for future Docker updates:

```bash
# Enable faster mirrors and parallel downloads
echo 'fastestmirror=1' | sudo tee -a /etc/dnf/dnf.conf
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
```

---

## Remote Docker Context (macOS)

Access your Fedora VM's Docker daemon from macOS for seamless development.

### Setup SSH Access

Ensure SSH is configured in your `~/.ssh/config` (from dotfiles ssh package):

```bash
# macOS: ~/.ssh/config
Host fedora-vm
    HostName fedora-vm.tail-scale.ts.net
    User your-username
    Port 22
    IdentityAgent ~/.1password/agent.sock
```

### Create Docker Context

```bash
# On macOS
docker context create fedora-vm \
    --docker "host=ssh://fedora-vm"

# Use Fedora context
docker context use fedora-vm

# Verify connection
docker ps

# List contexts
docker context ls

# Switch back to local
docker context use default
```

### Test Remote Access

```bash
# Run container on Fedora VM from macOS
docker context use fedora-vm
docker run --rm hello-world

# Build images remotely
docker build -t myapp .

# View logs
docker logs <container-id>
```

---

## Parallels VM Integration

### Shared Folders with Docker

Mount macOS directories in Docker containers running on Fedora VM:

```bash
# Parallels shared folder: /media/psf/Home/dev/project
# Create convenient symlink on Fedora VM
ln -s /media/psf/Home/dev ~/dev-shared

# Use in Docker with SELinux label
docker run -v ~/dev-shared/project:/app:Z node:20 npm install
```

### Network Configuration

Parallels uses **Shared Network** mode by default:
- Fedora VM gets DHCP address (e.g., 10.211.55.X)
- Accessible from macOS via VM's IP
- Tailscale recommended for stable hostname

### Resource Allocation

Recommended VM settings for Docker development:
- **CPU**: 4 vCPUs (minimum 2)
- **RAM**: 8GB (minimum 4GB)
- **Disk**: 50GB (thin provisioned)
- **Network**: Shared Network + Tailscale

---

## Performance Optimization

### Docker BuildKit

BuildKit is enabled by default with Docker Compose v2. For legacy builds:

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Or add to ~/.bashrc or ~/.zshrc
echo 'export DOCKER_BUILDKIT=1' >> ~/.zshrc
```

### Prune Unused Resources

```bash
# Remove unused containers, networks, images
docker system prune

# Remove all unused images (not just dangling)
docker system prune -a

# Remove volumes (CAREFUL: data loss!)
docker system prune --volumes
```

### Optimize Layer Caching

```dockerfile
# Bad: Invalidates cache on any file change
COPY . /app
RUN npm install

# Good: Cache dependencies separately
COPY package*.json /app/
RUN npm install
COPY . /app
```

### Monitor Resource Usage

```bash
# View container stats
docker stats

# View image sizes
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# View disk usage
docker system df
```

---

## Troubleshooting

### Common Issues

#### Issue: "permission denied" when accessing volumes

**Cause**: Missing SELinux label on volume mount

**Solution**:
```bash
# Add :Z or :z suffix
docker run -v /host/path:/container/path:Z nginx
```

#### Issue: "docker: Got permission denied"

**Cause**: User not in docker group or not logged out/in

**Solution**:
```bash
# Verify docker group
groups | grep docker

# If missing, add user
sudo usermod -aG docker $USER

# Logout and login
exit  # Then login again
```

#### Issue: Docker containers can't access network

**Cause**: firewalld blocking Docker bridge network

**Solution**:
```bash
# Add masquerade
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --reload

# Restart Docker
sudo systemctl restart docker
```

#### Issue: "SELinux is preventing /usr/bin/dockerd..."

**Cause**: SELinux policy needs adjustment

**Solution**:
```bash
# Set container management boolean
sudo setsebool -P container_manage_cgroup on

# If persists, check audit log
sudo ausearch -m avc -ts recent | grep docker
```

#### Issue: Podman commands still work after installation

**Cause**: Podman alias in shell

**Solution**:
```bash
# Check for alias
alias | grep podman

# Remove from ~/.bashrc or ~/.zshrc
sed -i '/alias docker=podman/d' ~/.zshrc

# Reload shell
source ~/.zshrc
```

### Diagnostic Commands

```bash
# Check Docker service status
sudo systemctl status docker

# View Docker logs
sudo journalctl -u docker --no-pager | tail -50

# Check Docker info
docker info

# Test network connectivity
docker run --rm busybox ping -c 3 google.com

# Check SELinux contexts
ls -Z /var/lib/docker

# Verify firewalld rules
sudo firewall-cmd --list-all

# Check Docker daemon configuration
cat /etc/docker/daemon.json
```

### Get Help

- **Docker Docs**: https://docs.docker.com/engine/install/fedora/
- **Fedora Forums**: https://discussion.fedoraproject.org/
- **SELinux Guide**: https://docs.fedoraproject.org/en-US/quick-docs/getting-started-with-selinux/
- **Project Docs**: `docs/guides/docker-fedora-setup.md`

---

## Uninstallation

### Remove Docker Completely

```bash
# Stop and disable Docker
sudo systemctl stop docker
sudo systemctl disable docker

# Remove Docker packages
sudo dnf remove -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Remove user from docker group
sudo gpasswd -d $USER docker

# Remove Docker data (CAUTION: all containers/images will be lost)
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# Remove Docker repository
sudo rm /etc/yum.repos.d/docker-ce.repo

# Remove firewalld rules
sudo firewall-cmd --permanent --zone=public --remove-masquerade
sudo firewall-cmd --permanent --zone=public --remove-port=2376/tcp
sudo firewall-cmd --reload
```

### Reinstall Podman (Optional)

```bash
# Install Podman
sudo dnf install -y podman

# Verify
podman --version
podman run hello-world
```

---

## See Also

- [Docker Ubuntu Setup Guide](docker-ubuntu-setup.md) - Ubuntu version
- [Cross-Platform Analysis](../architecture/CROSS-PLATFORM-ANALYSIS.md) - Platform comparison
- [Fedora Bootstrap Guide](../guides/parallels-3-fedora-vm-creation.md) - VM setup
- [ADR-006: Docker Fedora Installation](../architecture/ADR/ADR-006-docker-fedora-installation.md) - Architecture decisions

---

**Document Version**: 1.0
**Last Updated**: 2025-10-28
**Maintained By**: Matteo Cervelli
**Tested On**: Fedora 40 ARM64 (Parallels on Mac Studio)
