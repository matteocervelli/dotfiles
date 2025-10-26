# Docker on Ubuntu 24.04 LTS - Complete Setup Guide

Complete guide for setting up Docker Engine + Compose v2 on Ubuntu 24.04 LTS, with Parallels VM configuration and remote Docker context from macOS.

**Target Environment**: Ubuntu 24.04 LTS (Noble Numbat) on Parallels VM (Apple Silicon/Intel)

**Related Documentation**:
- **NEW**: [Parallels VM Creation Guide](parallels-vm-creation.md) - Complete step-by-step guide to create Ubuntu VM from ISO
- [TASK.md](../TASK.md) - Implementation tracking

> **Note**: If you haven't created your Ubuntu VM yet, start with the [Parallels VM Creation Guide](parallels-vm-creation.md) first. This guide assumes Ubuntu is already installed.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Docker Installation](#docker-installation)
4. [Parallels VM Configuration](#parallels-vm-configuration)
5. [Remote Docker Context (macOS)](#remote-docker-context-macos)
6. [Post-Installation](#post-installation)
7. [Troubleshooting](#troubleshooting)
8. [Performance Optimization](#performance-optimization)

---

## Prerequisites

### Required

- ✅ Ubuntu 24.04 LTS installed (Parallels VM or bare metal)
  - **Need to create a VM?** See [Parallels VM Creation Guide](parallels-vm-creation.md)
- ✅ sudo privileges
- ✅ Internet connection
- ✅ At least 2GB free disk space (10GB+ recommended)

### Recommended

- ✅ Dotfiles bootstrap already complete (`make install`)
- ✅ SSH access via Tailscale configured
- ✅ Parallels Tools installed (for VM)
  - **Installation instructions**: See [Part 3](parallels-vm-creation.md#part-3-parallels-tools-installation) of VM Creation Guide

---

## Quick Start

### Option 1: Docker Only

```bash
# Install Docker Engine + Compose v2
sudo ./scripts/bootstrap/install-docker.sh

# Or via Makefile
make docker-install
```

### Option 2: Full Ubuntu Setup with Docker

```bash
# Install all Ubuntu packages + Docker
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --with-docker

# Or via Makefile
make ubuntu-full
```

### Verification

```bash
# Check Docker version
docker --version
docker compose version

# Run hello-world test
docker run hello-world

# Check service status
systemctl status docker
```

---

## Docker Installation

### What Gets Installed

The installation script (`install-docker.sh`) installs:

1. **Docker Engine** (latest stable from official Docker repository)
2. **Docker CLI** (command-line interface)
3. **containerd** (container runtime)
4. **Docker Compose v2** (plugin, not standalone binary)
5. **Docker BuildKit** (buildx plugin for advanced builds)

### Installation Methods

#### Method 1: Script (Recommended)

```bash
# Full installation
sudo ./scripts/bootstrap/install-docker.sh

# Dry-run (preview only)
sudo ./scripts/bootstrap/install-docker.sh --dry-run

# Install without adding user to docker group
sudo ./scripts/bootstrap/install-docker.sh --skip-user

# Install without starting service
sudo ./scripts/bootstrap/install-docker.sh --no-start
```

#### Method 2: Makefile

```bash
# Ubuntu packages + Docker
make ubuntu-full

# Docker only
make docker-install
```

### Post-Install Requirements

**IMPORTANT**: After Docker installation, you must **log out and log back in** for group changes to take effect.

```bash
# Log out
exit

# Or restart session
sudo systemctl restart gdm  # For GUI
```

### Why Official Docker Repository?

Ubuntu's default `docker.io` package is often outdated. This installation uses the official Docker repository for:

- ✅ Latest stable versions
- ✅ Faster security updates
- ✅ Docker Compose v2 plugin included
- ✅ Better ARM64 support

---

## Parallels VM Configuration

### Recommended VM Resources

For Docker workloads on Parallels:

| Resource | Minimum | Recommended | Heavy Workloads |
|----------|---------|-------------|-----------------|
| **CPU** | 2 vCPU | 4 vCPU | 8 vCPU |
| **RAM** | 4 GB | 8 GB | 16 GB |
| **Disk** | 32 GB | 50 GB | 100 GB+ |

### Configure Parallels VM

1. **Open Parallels Desktop**
2. **Select your Ubuntu VM** → Right-click → **Configure**
3. **Hardware Tab**:
   - **CPU & Memory**: Allocate 4-8 vCPU, 8GB RAM
   - **Graphics**: 512MB-1GB video memory (headless: 256MB)
   - **Network**: Shared Network (for internet) or Bridged (for static IP)

### Shared Folders Setup

Share macOS development directory with Ubuntu:

#### Step 1: Enable Shared Folders in Parallels

1. **VM Configuration** → **Options** → **Sharing**
2. **Share Mac folders with Linux**: Enable
3. **Share custom folders**: Add `/Users/matteo/dev`
4. **Access rights**: Read and Write

#### Step 2: Mount in Ubuntu

```bash
# Parallels shared folders are automatically mounted at:
/media/psf/<folder-name>

# For /Users/matteo/dev:
/media/psf/Home/dev

# Create convenient symlink
ln -s /media/psf/Home/dev ~/dev-shared

# Or create permanent mount point
sudo mkdir -p /mnt/dev
echo "/media/psf/Home/dev /mnt/dev none bind 0 0" | sudo tee -a /etc/fstab
sudo mount -a
```

#### Step 3: Verify Shared Folders

```bash
# List all Parallels shared folders
ls -la /media/psf/

# Test read/write access
touch ~/dev-shared/test.txt
ls ~/dev-shared/test.txt
rm ~/dev-shared/test.txt
```

### Install Parallels Tools

**Required for optimal performance and shared folders.**

```bash
# Insert Parallels Tools disk (VM menu → Install Parallels Tools)

# Mount and install
sudo mkdir -p /mnt/cdrom
sudo mount /dev/cdrom /mnt/cdrom
cd /mnt/cdrom
sudo ./install

# Reboot
sudo reboot
```

---

## Remote Docker Context (macOS)

Access Ubuntu VM Docker from macOS without SSH into the VM every time.

### Prerequisites

- ✅ Docker installed on Ubuntu VM
- ✅ SSH access to Ubuntu VM (via Tailscale or local network)
- ✅ Docker CLI installed on macOS (`brew install docker`)

### Step 1: Configure SSH Access

Ensure you can SSH into Ubuntu VM:

```bash
# From macOS
ssh ubuntu-vm  # Or your Tailscale hostname

# Or via IP
ssh matteo@<ubuntu-vm-ip>
```

If SSH works, you're ready for Docker context.

### Step 2: Create Docker Context on macOS

```bash
# Create context for Ubuntu VM
docker context create ubuntu-vm \
  --description "Parallels Ubuntu 24.04 LTS VM" \
  --docker "host=ssh://ubuntu-vm"

# Or with user@host
docker context create ubuntu-vm \
  --description "Parallels Ubuntu 24.04 LTS VM" \
  --docker "host=ssh://matteo@ubuntu-vm"

# List all contexts
docker context ls

# Switch to Ubuntu context
docker context use ubuntu-vm
```

### Step 3: Test Remote Docker

```bash
# Use Ubuntu Docker from macOS
docker context use ubuntu-vm
docker version
docker ps
docker run hello-world

# Switch back to macOS Docker Desktop
docker context use default
```

### Step 4: Convenience Aliases (Optional)

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Docker context switchers
alias docker-vm='docker context use ubuntu-vm'
alias docker-mac='docker context use default'
alias docker-vm-ps='docker context use ubuntu-vm && docker ps && docker context use default'
```

### Common Remote Docker Commands

```bash
# Always use ubuntu-vm context
docker --context ubuntu-vm ps
docker --context ubuntu-vm run -d nginx
docker --context ubuntu-vm compose up -d

# Or switch context once
docker context use ubuntu-vm
docker ps
docker compose up -d
```

---

## Post-Installation

### 1. Verify Installation

```bash
# Docker version
docker --version
# Output: Docker version 24.0.x, build xxxxx

# Docker Compose version (v2 plugin)
docker compose version
# Output: Docker Compose version v2.x.x

# Docker info
docker info

# Service status
systemctl status docker
```

### 2. Run Hello World

```bash
# Pull and run hello-world
docker run hello-world

# Expected output:
# Hello from Docker!
# This message shows that your installation appears to be working correctly.
```

### 3. Test Docker Compose

```bash
# Create test compose file
mkdir -p ~/docker-test
cd ~/docker-test

cat > docker-compose.yml <<EOF
version: '3.8'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
EOF

# Start service
docker compose up -d

# Check running containers
docker compose ps

# Test (from Ubuntu)
curl http://localhost:8080

# Clean up
docker compose down
cd ~
rm -rf ~/docker-test
```

### 4. Enable Docker on Boot (Already Done)

Docker service is automatically enabled during installation:

```bash
# Verify enabled
systemctl is-enabled docker
# Output: enabled

# Manual enable (if needed)
sudo systemctl enable docker
```

---

## Troubleshooting

### Permission Denied Errors

**Symptom**: `permission denied while trying to connect to the Docker daemon socket`

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
exit

# Or use newgrp (temporary)
newgrp docker

# Verify group membership
groups | grep docker
```

### Docker Service Won't Start

**Symptom**: `systemctl status docker` shows failed

**Solution**:
```bash
# Check logs
sudo journalctl -u docker -n 50 --no-pager

# Restart service
sudo systemctl restart docker

# Check for port conflicts (especially 2375, 2376)
sudo netstat -tuln | grep 237

# Reset Docker
sudo systemctl stop docker
sudo rm -rf /var/lib/docker
sudo systemctl start docker
```

### Shared Folders Not Mounting

**Symptom**: `/media/psf/` is empty or folders not visible

**Solution**:
```bash
# Verify Parallels Tools installed
prltools -v

# Reinstall Parallels Tools
# VM menu → Install Parallels Tools
sudo /media/cdrom/install

# Check mount
mount | grep prl_fs

# Manual mount
sudo mount -t prl_fs -o rw,sync prl_fs /media/psf
```

### Remote Context Connection Fails

**Symptom**: `docker context use ubuntu-vm` → connection refused

**Solution**:
```bash
# Test SSH connection from macOS
ssh ubuntu-vm echo "SSH works"

# Check Docker socket permissions on Ubuntu
ls -l /var/run/docker.sock
# Should be: srw-rw---- 1 root docker

# Verify user in docker group
groups | grep docker

# Recreate context with explicit socket
docker context create ubuntu-vm \
  --docker "host=ssh://ubuntu-vm"
```

### Compose Command Not Found

**Symptom**: `docker compose` → command not found

**Solution**:
```bash
# Docker Compose v2 is a plugin, not standalone binary
# Verify installation
docker compose version

# If missing, reinstall Docker
sudo apt install docker-compose-plugin

# Legacy docker-compose (v1) is deprecated
# Use: docker compose (without hyphen)
```

---

## Performance Optimization

### Storage Driver

Docker automatically uses `overlay2` storage driver (best performance):

```bash
# Verify storage driver
docker info | grep "Storage Driver"
# Output: Storage Driver: overlay2
```

### Memory and CPU Tuning

Edit Docker daemon configuration:

```bash
# Create/edit daemon.json
sudo nano /etc/docker/daemon.json
```

Add:
```json
{
  "default-runtime": "runc",
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
```

Restart Docker:
```bash
sudo systemctl restart docker
```

### Build Cache

Use BuildKit for faster builds:

```bash
# Enable BuildKit (default in Docker 23+)
export DOCKER_BUILDKIT=1

# Or set in daemon.json
{
  "features": {
    "buildkit": true
  }
}
```

### Parallels VM Performance

1. **Enable Hypervisor**: VM Configuration → Hardware → CPU & Memory → Hypervisor: **Apple**
2. **Disable Adaptive Hypervisor**: Uncheck "Tune Windows for speed"
3. **SSD Optimization**: Ensure VM disk is on SSD (not HDD)
4. **Network Mode**: Use **Shared Network** for best compatibility

---

## Useful Commands

### Docker Management

```bash
# System info
docker info
docker system df  # Disk usage

# Clean up
docker system prune       # Remove unused data
docker system prune -a    # Remove ALL unused data
docker volume prune       # Remove unused volumes

# Container management
docker ps                 # Running containers
docker ps -a              # All containers
docker logs <container>   # View logs
docker exec -it <container> bash  # Enter container

# Image management
docker images             # List images
docker rmi <image>        # Remove image
docker pull <image>       # Download image
```

### Docker Compose

```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Rebuild and restart
docker compose up -d --build

# Scale services
docker compose up -d --scale web=3
```

---

## Next Steps

1. ✅ **Test Docker installation**: `docker run hello-world`
2. ✅ **Setup remote context**: Follow [Remote Docker Context](#remote-docker-context-macos) section
3. ✅ **Configure Parallels shared folders**: Edit code on macOS, run on Ubuntu
4. ✅ **Install dotfiles**: `make install` (if not already done)
5. ✅ **Setup development environment**: `make bootstrap`

---

## References

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Parallels Desktop Documentation](https://www.parallels.com/products/desktop/resources/)
- [Ubuntu Server Guide - Docker](https://ubuntu.com/server/docs/containers-docker)
- [Issue #22 - Ubuntu 24.04 LTS Bootstrap & Docker](https://github.com/matteocervelli/dotfiles/issues/22)

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Author**: Matteo Cervelli
**Part of**: FASE 4.2 - Ubuntu 24.04 LTS Bootstrap & Docker Setup
