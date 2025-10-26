# Guide 2: Development VM Setup

**Purpose**: Transform an empty Ubuntu VM into a complete development environment with Docker, dotfiles, and project bindings from Mac Studio.

**Prerequisites**: Completed [Guide 1: VM Creation](parallels-1-vm-creation.md) - You have an Ubuntu VM with Parallels Tools installed.

**Result**: Fully configured development VM with shared folders, Docker, dotfiles, R2 assets, and remote control from macOS.

---

## Table of Contents

1. [Prerequisites Check](#prerequisites-check)
2. [Parallels Shared Folders Setup](#parallels-shared-folders-setup)
3. [Docker Installation](#docker-installation)
4. [Dotfiles Integration](#dotfiles-integration)
5. [R2 Assets Workflow](#r2-assets-workflow)
6. [Project Setup with Mac Studio Bindings](#project-setup-with-mac-studio-bindings)
7. [Remote Docker Context](#remote-docker-context)
8. [Performance Optimization](#performance-optimization)
9. [Testing & Verification](#testing--verification)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites Check

### Required from Guide 1

Run these checks **inside the VM**:

```bash
# 1. Ubuntu version
lsb_release -a  # Should show Ubuntu 24.04 LTS

# 2. Parallels Tools installed
prltools -v  # Should show version number

# 3. Parallels Tools service running
systemctl status parallels-tools  # Should be active

# 4. Network working
ping -c 3 google.com  # Should succeed

# 5. SSH service running
systemctl status ssh  # Should be active
```

### From macOS: Verify SSH Access

```bash
# Test SSH from Mac Studio
ssh matteo@ubuntu-vm

# Or via IP (find with: hostname -I in VM)
ssh matteo@10.211.55.XXX
```

**If all checks pass, proceed!** ✅

---

## Parallels Shared Folders Setup

### Architecture Overview

**Central Library Strategy - Projects stay on macOS:**

```
Mac Studio: ~/dev/projects/                     Mac Studio: ~/media/cdn/
    ↓ Parallels shared folder                       ↓ Parallels shared folder
VM:         /media/psf/Home/dev/                VM:         /media/psf/Home/media/cdn/
    ↓ symlink for convenience                       ↓ symlink for convenience
VM:         ~/dev                                VM:         ~/cdn
```

**Benefits:**
- ✅ Zero duplication (single source of truth on macOS)
- ✅ Automatic sync (edit on macOS, instant VM access)
- ✅ Efficient storage (single copy on disk)
- ✅ Docker compatible (mount /media/psf/ in containers)

### Step 1: Configure Shared Folders in Parallels (macOS)

**From Mac Studio:**

1. **Open Parallels Desktop**
2. **Select Ubuntu VM** → Right-click → **Configure**
3. **Options Tab** → **Sharing**
4. **Share Mac folders with Linux**: ✅ Enable

**Add Custom Folders:**

Click **+** button and add:

1. **Development Directory**:
   - Folder: `/Users/matteo/dev`
   - Name: `dev` (or keep default)
   - Access rights: **Read and Write**

2. **CDN Assets Directory**:
   - Folder: `/Users/matteo/media/cdn`
   - Name: `cdn` (or keep default)
   - Access rights: **Read and Write**

**Important Settings:**
- ✅ **Share Mac folders with Linux**: Enabled
- ✅ **Share Mac user folders**: Optional (Home, Desktop, Documents)
- ❌ **Shared Profile**: Disabled (can cause permission issues)

Click **OK** to apply.

### Step 2: Verify Mount Points in VM

**Inside the VM:**

```bash
# Check Parallels shared folders
ls -la /media/psf/

# Should show:
# drwxr-xr-x 1 matteo matteo    0 Oct 26 10:00 Home

# Check specific folders
ls -la /media/psf/Home/dev/
ls -la /media/psf/Home/media/cdn/
```

**Expected**: You should see your macOS directories content.

### Step 3: Create Convenience Symlinks

```bash
# Create symlink to dev directory
ln -s /media/psf/Home/dev ~/dev

# Create symlink to CDN assets
ln -s /media/psf/Home/media/cdn ~/cdn

# Verify symlinks
ls -la ~ | grep -E "dev|cdn"
```

**Expected output:**
```
lrwxrwxrwx 1 matteo matteo   24 Oct 26 10:00 cdn -> /media/psf/Home/media/cdn
lrwxrwxrwx 1 matteo matteo   20 Oct 26 10:00 dev -> /media/psf/Home/dev
```

### Step 4: Test Read/Write Access

```bash
# Test write to dev folder
touch ~/dev/test-vm-access.txt
echo "VM can write!" > ~/dev/test-vm-access.txt

# Verify on macOS (from Mac Studio terminal)
cat ~/dev/test-vm-access.txt  # Should show "VM can write!"

# Clean up
rm ~/dev/test-vm-access.txt

# Test CDN access
ls ~/cdn/.r2-manifest.yml  # Should exist if R2 sync is setup
```

✅ **Shared folders working!**

---

## Docker Installation

### What Gets Installed

The installation script installs:
- **Docker Engine** (latest stable)
- **Docker CLI** (command-line)
- **containerd** (container runtime)
- **Docker Compose v2** (plugin)
- **Docker BuildKit** (buildx plugin)

### Installation Methods

#### Method 1: Bootstrap Script (Recommended)

```bash
# If not already cloned, clone dotfiles
cd ~
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles

# Install Docker via script
sudo ./scripts/bootstrap/install-docker.sh

# Or install full development environment (includes Docker)
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --with-docker
```

#### Method 2: Makefile

```bash
cd ~/dotfiles

# Ubuntu packages + Docker
make ubuntu-full

# Docker only
make docker-install
```

### Post-Install: Group Membership

**CRITICAL**: Log out and back in for group changes to take effect.

```bash
# Check if user is in docker group
groups | grep docker  # Should show "docker"

# If not, add manually
sudo usermod -aG docker $USER

# Log out and back in
exit
# Then SSH back in: ssh matteo@ubuntu-vm
```

### Verify Docker Installation

```bash
# Check Docker version
docker --version
# Expected: Docker version 27.x.x or later

# Check Docker Compose
docker compose version
# Expected: Docker Compose version v2.x.x or later

# Check Docker service
systemctl status docker
# Expected: active (running)

# Test Docker (no sudo needed)
docker run hello-world
# Expected: "Hello from Docker!"

# Check Docker info
docker info
```

✅ **Docker installed and working!**

---

## Dotfiles Integration

### Step 1: Clone Dotfiles Repository

**If not already cloned:**

```bash
cd ~
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles
```

### Step 2: Run Bootstrap Script

**Install all dependencies:**

```bash
# Make script executable
chmod +x scripts/bootstrap/install-dependencies-ubuntu.sh

# Run bootstrap
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh

# Or via Makefile
make ubuntu-base
```

**This installs:**
- Development tools (git, curl, wget, vim, tmux)
- Build essentials (gcc, make, autoconf)
- Python and pip
- Node.js and npm (via nvm)
- Rclone (for R2 asset sync)
- yq (YAML processor)
- GNU Stow (for dotfiles deployment)

**Duration**: 5-10 minutes

### Step 3: Deploy Dotfiles with GNU Stow

```bash
cd ~/dotfiles

# Install GNU Stow if not installed
sudo apt install -y stow

# Verify Stow version
stow --version

# Deploy all packages
make stow

# Or deploy specific packages
stow -t ~ zsh
stow -t ~ git
stow -t ~ ssh
stow -t ~ vim
```

**This creates symlinks:**
- `~/.zshrc` → `~/dotfiles/packages/zsh/.zshrc`
- `~/.gitconfig` → `~/dotfiles/packages/git/.gitconfig`
- `~/.ssh/config` → `~/dotfiles/packages/ssh/.ssh/config`

### Step 4: Configure ZSH

```bash
# Change default shell to ZSH
chsh -s $(which zsh)

# Install Oh My Zsh (if included in dotfiles)
# Or manually:
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Source new config
source ~/.zshrc
```

### Step 5: Configure Git

```bash
# Verify Git config
git config --list

# Set global config if needed
git config --global user.name "Matteo Cervelli"
git config --global user.email "your-email@example.com"

# Test Git
git status
```

### Step 6: Set Up SSH Keys

**Option A: Via 1Password CLI (Recommended)**

```bash
# Install 1Password CLI (if not in bootstrap)
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
  sudo tee /etc/apt/sources.list.d/1password.list

sudo apt update
sudo apt install -y 1password-cli

# Sign in to 1Password
op signin

# Retrieve SSH key
op read "op://Private/SSH Key/private key" > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
```

**Option B: Copy from macOS**

```bash
# From Mac Studio, copy SSH key to VM
scp ~/.ssh/id_ed25519 matteo@ubuntu-vm:~/.ssh/
scp ~/.ssh/id_ed25519.pub matteo@ubuntu-vm:~/.ssh/

# In VM, set permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

✅ **Dotfiles deployed and configured!**

---

## R2 Assets Workflow

### Central Library Architecture

**Single source of truth on macOS:**

```
R2 (Cloudflare Cloud Storage)
    ↓ rclone sync (automated or manual)
macOS: ~/media/cdn/  ← SINGLE SOURCE OF TRUTH
    ↓ Parallels shared folders (automatic, real-time)
VM: /media/psf/Home/media/cdn/  ← Read from macOS
    ↓ symlink (convenience)
VM: ~/cdn  ← Easy access
```

### Step 1: Verify CDN Symlink

```bash
# Check symlink exists (created in Step 2)
ls -la ~/cdn

# Should point to: /media/psf/Home/media/cdn/

# List CDN contents
ls ~/cdn/
```

### Step 2: Verify R2 Manifest

```bash
# Check manifest exists
ls ~/cdn/.r2-manifest.yml

# View manifest
cat ~/cdn/.r2-manifest.yml

# Or use yq to parse
yq eval '.version' ~/cdn/.r2-manifest.yml
```

### Step 3: Configure Rclone (If Needed)

**Only if you need to run rclone FROM the VM (optional):**

```bash
# Check if rclone is installed
rclone version

# Configure R2 remote (interactive)
rclone config

# Or copy config from macOS
scp ~/.config/rclone/rclone.conf matteo@ubuntu-vm:~/.config/rclone/

# Test connection
rclone lsd r2:your-bucket-name
```

### Step 4: Test Asset Access

```bash
# List assets
ls -lh ~/cdn/assets/
ls -lh ~/cdn/logos/
ls -lh ~/cdn/projects/

# Test read access
file ~/cdn/assets/some-image.png
identify ~/cdn/assets/some-image.png  # If ImageMagick installed

# Verify dimensions cache
ls ~/cdn/.dimensions-cache.json
cat ~/cdn/.dimensions-cache.json | jq . | head
```

### Step 5: Docker Volume Mounting

**Assets can be mounted in Docker containers:**

```bash
# Example: Mount CDN in container
docker run -it --rm \
  -v ~/cdn:/cdn:ro \
  ubuntu:24.04 \
  ls -la /cdn

# Example: docker-compose.yml
cat > test-compose.yml <<'EOF'
services:
  web:
    image: nginx:alpine
    volumes:
      - ~/cdn:/usr/share/nginx/html/cdn:ro
    ports:
      - "8080:80"
EOF

docker compose -f test-compose.yml up -d
curl http://localhost:8080/cdn/  # Should list assets

# Cleanup
docker compose -f test-compose.yml down
rm test-compose.yml
```

✅ **R2 assets accessible from VM!**

---

## Project Setup with Mac Studio Bindings

### Architecture

**Projects stay on Mac Studio, accessed via shared folders:**

```
Mac Studio: ~/dev/projects/my-app/
    ↓ Parallels shared folder
VM: /media/psf/Home/dev/projects/my-app/
    ↓ symlink ~/dev
VM: ~/dev/projects/my-app/  ← Work here
```

### Step 1: Verify Project Access

```bash
# List projects from Mac Studio
ls ~/dev/projects/

# Should show your macOS projects
# Example: APP-Discreto, WEB-SiteStudio4Change, etc.
```

### Step 2: Navigate to Projects

```bash
# Go to a project
cd ~/dev/projects/APP-Discreto/

# View files
ls -la

# Check Git status
git status
```

### Step 3: Docker Compose with Project Mounts

**Example: Run project in Docker with mounted code:**

```bash
cd ~/dev/projects/your-project/

# Example docker-compose.yml that uses shared folder
cat docker-compose.yml

# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Step 4: Development Workflow

**Edit on macOS, run in VM:**

1. **Open project in Cursor/VS Code on Mac Studio**
2. **Edit files on macOS** (native performance)
3. **Changes instantly available in VM** (shared folder)
4. **Run Docker containers in VM** (accessing shared files)
5. **Test from macOS browser** (via VM IP or hostname)

**Example Workflow:**

```bash
# Mac Studio: Edit code in Cursor
# /Users/matteo/dev/projects/my-app/src/index.ts

# VM: Changes are immediately visible
cd ~/dev/projects/my-app/
cat src/index.ts  # Shows latest changes

# VM: Run Docker build
docker compose build

# VM: Start services
docker compose up -d

# Mac Studio: Access service
curl http://ubuntu-vm:3000
```

### Step 5: Git Workflow from VM

```bash
cd ~/dev/projects/your-project/

# Git operations work normally
git status
git add .
git commit -m "feat: implement feature"
git push

# Or work from macOS (same repo)
```

✅ **Projects accessible with full Docker support!**

---

## Remote Docker Context

**Control VM Docker from Mac Studio terminal - no SSH needed for docker commands.**

### Step 1: Configure SSH for Docker (VM)

```bash
# In VM: Ensure SSH is accessible
sudo systemctl status ssh

# Verify from macOS
ssh matteo@ubuntu-vm docker ps
```

### Step 2: Create Docker Context (macOS)

**From Mac Studio:**

```bash
# Create remote context
docker context create ubuntu-vm \
  --docker "host=ssh://matteo@ubuntu-vm"

# Or with custom SSH key
docker context create ubuntu-vm \
  --docker "host=ssh://matteo@ubuntu-vm" \
  --description "Ubuntu VM on Parallels"

# List contexts
docker context ls

# Switch to VM context
docker context use ubuntu-vm

# Test - this now runs on VM!
docker ps
docker images
```

### Step 3: Switch Between Contexts

```bash
# Use VM Docker
docker context use ubuntu-vm
docker ps  # Lists containers on VM

# Use macOS Docker Desktop
docker context use default
docker ps  # Lists containers on Mac

# One-off command on specific context
docker --context ubuntu-vm ps
```

### Step 4: Test Remote Control

```bash
# From Mac Studio, using VM Docker
docker context use ubuntu-vm

# Run container on VM
docker run -d --name test-nginx -p 8080:80 nginx:alpine

# Check on VM (from macOS)
docker ps

# Access from Mac Studio browser
open http://ubuntu-vm:8080

# Cleanup
docker stop test-nginx
docker rm test-nginx
```

### Step 5: Docker Compose Remote

```bash
# From Mac Studio, in a project directory
cd ~/dev/projects/my-project/

# Use VM Docker context
docker context use ubuntu-vm

# Run docker-compose (executes on VM)
docker compose up -d

# View logs (from macOS)
docker compose logs -f

# Stop services
docker compose down

# Switch back to default
docker context use default
```

✅ **Remote Docker control from Mac Studio working!**

---

## Performance Optimization

### VM Resource Tuning

**Adjust in Parallels Desktop:**

1. **VM Configuration** → **Hardware** → **CPU & Memory**
   - **Processors**: 4-8 vCPU (based on workload)
   - **Memory**: 8-16 GB (based on project needs)
   - **Enable Adaptive Hypervisor**: ✅ On

2. **Graphics**:
   - **Memory**: 512 MB-1 GB
   - **3D Acceleration**: ✅ On

3. **Hard Disk**:
   - If running low on space, expand disk:
     - Shut down VM
     - VM Configuration → Hardware → Hard Disk → Edit
     - Increase size (e.g., 50 GB → 100 GB)
     - Start VM

### Docker Performance

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a

# Clean up volumes
docker volume prune

# Monitor Docker performance
docker stats
```

### System Performance

```bash
# Install monitoring tools
sudo apt install -y htop iotop nethogs

# Monitor CPU/Memory
htop

# Monitor disk I/O
sudo iotop

# Monitor network
sudo nethogs

# Check disk usage
df -h

# Check memory usage
free -h
```

### Parallels Optimization Settings

**In Parallels Desktop:**

1. **Options** → **Optimization**:
   - **Faster virtual machine**: ✅ On
   - **Adaptive Hypervisor**: ✅ On

2. **Options** → **Sharing**:
   - **Shared Profile**: ❌ Off (improves shared folder performance)

3. **Hardware** → **Hard Disk**:
   - **Disk Type**: Expanding (better than plain for development)

### Network Performance

```bash
# Test network speed to macOS
iperf3 -c <mac-ip>  # If iperf3 installed on both

# Test DNS resolution
time nslookup github.com

# Test internet speed
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
```

✅ **Performance optimized!**

---

## Testing & Verification

### Automated Testing Script

**Run comprehensive integration tests:**

```bash
cd ~/dotfiles

# Make script executable
chmod +x scripts/test/test-vm-integration.sh

# Run automated tests
./scripts/test/test-vm-integration.sh

# Run with verbose output
./scripts/test/test-vm-integration.sh --verbose
```

**11 Automated Tests:**
1. ✅ Parallels Tools installed
2. ✅ Parallels Tools service running
3. ✅ Shared folders mounted
4. ✅ CDN directory accessible
5. ✅ Read access to CDN
6. ✅ Write access to CDN
7. ✅ CDN symlink exists
8. ✅ Dev directory accessible
9. ✅ R2 manifest readable
10. ✅ Docker service running
11. ✅ Docker can mount CDN

**Expected Output:**
```
========================================
VM Integration Tests
========================================

✓ Parallels Tools installed
✓ Parallels Tools service running
✓ Shared folders mounted
✓ CDN directory accessible
✓ Read access to CDN
✓ Write access to CDN
✓ CDN symlink exists
✓ Dev directory accessible
✓ R2 manifest readable
✓ Docker service running
✓ Docker can mount CDN

========================================
Tests Passed: 11/11
Tests Failed: 0/11
========================================
```

### Manual Testing Checklist

**Use comprehensive checklist for detailed verification:**

```bash
# View checklist
cat ~/dotfiles/docs/checklists/vm-integration-checklist.md

# Or open in editor
vim ~/dotfiles/docs/checklists/vm-integration-checklist.md
```

**Checklist covers 75+ verification points:**
- Pre-test setup
- Parallels integration
- Shared folders
- File operations
- R2 assets workflow
- Project setup
- Docker integration
- Performance testing
- Final verification

### Quick Verification Commands

```bash
# 1. Parallels Tools
prltools -v

# 2. Shared folders
ls /media/psf/ && ls ~/dev && ls ~/cdn

# 3. Docker
docker ps && docker compose version

# 4. Dotfiles
ls -la ~/.zshrc && ls ~/dotfiles

# 5. Git
git config --list | grep user

# 6. SSH from macOS (run on Mac Studio)
ssh matteo@ubuntu-vm 'echo "SSH works!"'

# 7. Remote Docker from macOS (run on Mac Studio)
docker --context ubuntu-vm ps

# 8. Project access
ls ~/dev/projects/
```

✅ **All tests passing - VM fully configured!**

---

## Troubleshooting

### Issue: Shared Folders Not Visible

**Symptom**: `/media/psf/` is empty or missing folders

**Solution**:

```bash
# 1. Check Parallels Tools running
systemctl status parallels-tools
prltools -v

# 2. Restart Parallels Tools service
sudo systemctl restart parallels-tools

# 3. Check from macOS: Verify sharing enabled
# Parallels Desktop → VM Configuration → Options → Sharing

# 4. Reboot VM
sudo reboot

# 5. After reboot, verify
ls -la /media/psf/
```

### Issue: Permission Denied on Shared Folders

**Symptom**: Cannot read/write to `/media/psf/` folders

**Solution**:

```bash
# Check ownership
ls -la /media/psf/Home/dev/

# Ensure you're the owner on macOS
# From Mac Studio:
ls -la ~/dev/
chmod -R u+rw ~/dev/

# Disable Shared Profile in Parallels
# Parallels Desktop → Options → Sharing → Shared Profile: Off
```

### Issue: Docker Permission Denied

**Symptom**: `docker: permission denied while trying to connect`

**Solution**:

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
exit
# SSH back in

# Verify group membership
groups | grep docker

# Restart Docker service
sudo systemctl restart docker

# Test
docker ps  # Should work without sudo
```

### Issue: Remote Docker Context Fails

**Symptom**: `docker --context ubuntu-vm ps` fails with connection error

**Solution**:

```bash
# 1. Test SSH from macOS
ssh matteo@ubuntu-vm docker ps

# 2. If SSH fails, check SSH key
ssh-add -l  # On macOS
ssh-copy-id matteo@ubuntu-vm

# 3. Recreate Docker context
docker context rm ubuntu-vm
docker context create ubuntu-vm --docker "host=ssh://matteo@ubuntu-vm"

# 4. Test again
docker context use ubuntu-vm
docker ps
```

### Issue: CDN Assets Not Updating

**Symptom**: Changes on macOS not visible in VM

**Solution**:

```bash
# 1. Check shared folder mounted
ls /media/psf/Home/media/cdn/

# 2. Check symlink
ls -la ~/cdn

# 3. Force refresh (touch a file on macOS)
# From Mac Studio:
touch ~/media/cdn/.refresh

# In VM:
ls ~/cdn/.refresh  # Should show new timestamp

# 4. Restart Parallels Tools
sudo systemctl restart parallels-tools
```

### Issue: VM Performance Slow

**Solution**:

1. **Increase VM resources**:
   - Parallels Desktop → VM Configuration → Hardware
   - CPU: Add more vCPUs
   - Memory: Increase RAM

2. **Enable optimizations**:
   - Options → Optimization → Faster virtual machine: On
   - Options → Optimization → Adaptive Hypervisor: On

3. **Clean up Docker**:
   ```bash
   docker system prune -a
   docker volume prune
   ```

4. **Check macOS resources**:
   - Close other applications
   - Ensure Mac has sufficient free RAM
   - Check Activity Monitor

### Issue: Docker Containers Can't Access Shared Folders

**Symptom**: Container can't read files from mounted `/media/psf/`

**Solution**:

```bash
# 1. Test mount outside container first
ls ~/dev/projects/

# 2. Use absolute path in docker-compose.yml
# WRONG:
volumes:
  - ./src:/app/src

# CORRECT:
volumes:
  - ~/dev/projects/my-app/src:/app/src
  # Or
  - /media/psf/Home/dev/projects/my-app/src:/app/src

# 3. Check file permissions
ls -la ~/dev/projects/my-app/

# 4. Test with simple container
docker run -it --rm -v ~/dev:/dev:ro ubuntu:24.04 ls -la /dev
```

---

## Summary

### What You Now Have

✅ **Ubuntu VM** with Parallels Tools
✅ **Shared Folders** - Projects from Mac Studio instantly available
✅ **Docker** - Full container orchestration
✅ **Dotfiles** - Complete development environment
✅ **R2 Assets** - Central library accessible
✅ **Remote Control** - Manage VM Docker from macOS
✅ **Testing Suite** - Automated + manual verification

### Development Workflow

**Daily workflow:**

1. **Edit code on Mac Studio** (Cursor/VS Code)
2. **Changes instantly in VM** (shared folders)
3. **Run Docker in VM** (automated tests, builds)
4. **Control from macOS** (remote Docker context)
5. **Access services** (from Mac Studio browser)

### Next Steps

**Common tasks:**

```bash
# Start working on a project
cd ~/dev/projects/your-project/
docker compose up -d

# Deploy dotfiles changes
cd ~/dotfiles
git pull
make stow

# Update R2 assets (from macOS)
rclone sync r2:bucket ~/media/cdn/ --progress

# Clean Docker
docker system prune -a

# Update VM packages
sudo apt update && sudo apt upgrade -y
```

### Related Documentation

- [Guide 1: VM Creation](parallels-1-vm-creation.md) - How to create the VM
- [Testing Checklist](../checklists/vm-integration-checklist.md) - Complete verification
- [Test Script](../../scripts/test/test-vm-integration.sh) - Automated tests
- [CHANGELOG.md](../../CHANGELOG.md) - Implementation history

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Status**: ✅ Complete
**Part of**: FASE 4 - VM Ubuntu Setup
**Issue**: [#23](https://github.com/matteocervelli/dotfiles/issues/23)
