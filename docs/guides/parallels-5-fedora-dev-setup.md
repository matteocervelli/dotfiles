# Guide 5: Fedora Development Environment Setup

**Purpose**: Transform a fresh Fedora VM into a complete development environment with Docker, dotfiles, shared folders, and remote control from macOS.

**Prerequisites**: Completed [Guide 4: Fedora VM Creation](parallels-4-fedora-vm-creation.md) - You have a Fedora VM with Parallels Tools installed.

**Result**: Fully configured development VM with Docker, dotfiles, shared folders, and remote Docker context from Mac Studio.

---

## Table of Contents

1. [Prerequisites Check](#prerequisites-check)
2. [SSH Configuration](#ssh-configuration)
3. [Parallels Shared Folders Setup](#parallels-shared-folders-setup)
4. [Bootstrap Installation](#bootstrap-installation)
5. [Docker Installation](#docker-installation)
6. [Docker with Shared Folders](#docker-with-shared-folders)
7. [systemd Auto-Update Service](#systemd-auto-update-service)
8. [Remote Docker Context](#remote-docker-context)
9. [Testing & Verification](#testing--verification)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites Check

### Required from Guide 4

Run these checks **inside the VM**:

```bash
# 1. Fedora version
cat /etc/fedora-release
# Expected: Fedora Linux 41 (Workstation Edition)

# 2. Parallels Tools version
cat /usr/lib/parallels-tools/version
# Expected: 19.x.x.xxxxx (or newer)

# 3. Parallels Tools service running
systemctl status prltools.service
# Expected: active (running)

# 4. Shared folders mount point exists
ls -la /media/psf/
# Expected: Directory exists

# 5. Network working
ping -c 3 google.com
# Expected: 3 packets transmitted, 3 received

# 6. Hostname correct
hostname
# Expected: fedora-dev4change

# 7. User is matteocervelli
whoami
# Expected: matteocervelli

# 8. User has sudo access
sudo -v
# Expected: Password prompt, then success
```

### From macOS: Verify Network Access

```bash
# Test ping from Mac Studio to VM
ping -c 3 fedora-dev4change

# Or via IP (find with: hostname -I in VM)
ping -c 3 10.211.55.XXX
```

**If all checks pass, proceed!** ✅

---

## SSH Configuration

### Overview

Configure SSH access to the Fedora VM for:
- ✅ **Local access** from Mac Studio (via Parallels Shared Network)
- ✅ **Passwordless authentication** with SSH keys
- ✅ **Remote Docker control** (Docker context)

### Step 1: Test Initial SSH Connection

**From Mac Studio terminal:**

```bash
# Test connection using hostname
ssh matteocervelli@fedora-dev4change

# Or use IP address (from hostname -I in VM)
ssh matteocervelli@10.211.55.XXX

# First connection will ask to accept host key
# Type: yes
# Enter your VM password
```

**Expected output:**
```
The authenticity of host 'fedora-dev4change (10.211.55.10)' can't be established.
ED25519 key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'fedora-dev4change' (ED25519) to the list of known hosts.
matteocervelli@fedora-dev4change's password: ********

matteocervelli@fedora-dev4change:~$
```

### Step 2: Setup SSH Key for Passwordless Access

**From Mac Studio:**

```bash
# Copy your SSH public key to VM
ssh-copy-id matteocervelli@fedora-dev4change

# Enter VM password when prompted
```

**Expected output:**
```
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/Users/matteocervelli/.ssh/id_ed25519.pub"
Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'matteocervelli@fedora-dev4change'"
and check to make sure that only the key(s) you wanted were added.
```

**Test passwordless login:**
```bash
# Should connect without password prompt
ssh matteocervelli@fedora-dev4change

# Test and exit
ssh matteocervelli@fedora-dev4change 'echo "SSH works!"'
exit
```

### Step 3: Add SSH Config Entry (Optional but Recommended)

**On Mac Studio, add to `~/.ssh/config`:**

```bash
# Edit SSH config
nano ~/.ssh/config

# Add these lines:
Host fedora-dev fedora-dev4change
    HostName fedora-dev4change
    User matteocervelli
    ForwardAgent yes
    ServerAliveInterval 60
```

**Test with shortcut:**
```bash
# Now you can use short name
ssh fedora-dev
```

---

## Parallels Shared Folders Setup

### Overview

Share Mac Studio folders with the Fedora VM for:
- ✅ **Project access** from VM (read/write)
- ✅ **Docker volume mounts** from Mac files
- ✅ **Asset synchronization** (R2 CDN assets)

### Step 1: Configure Shared Folders in Parallels

**From Mac Studio:**

1. **Stop the VM** (for configuration)
2. **Parallels Desktop** → VM Configuration (gear icon)
3. **Options** tab → **Sharing**
4. **Enable**: "Share Mac folders with Linux"
5. **Click +** to add folders:

   **Add these folders:**
   - `~/dev` → Share as: `dev` (read/write)
   - `~/media/cdn` → Share as: `cdn` (read/write)

6. **Click OK** to save
7. **Start the VM**

### Step 2: Verify Shared Folders in VM

**Inside the VM:**

```bash
# Check Parallels shared folders mount
ls -la /media/psf/
# Expected: Shows Home directory

# Verify shared folders
ls -la /media/psf/Home/dev/
ls -la /media/psf/Home/media/cdn/

# Test file access
ls -la /media/psf/Home/dev/projects/
```

### Step 3: Create Convenient Symlinks

**Inside the VM:**

```bash
# Create symlinks in home directory
cd ~
ln -s /media/psf/Home/dev dev-shared
ln -s /media/psf/Home/media/cdn cdn-shared

# Verify symlinks
ls -la ~/dev-shared/
ls -la ~/cdn-shared/

# Test read access
ls -la ~/dev-shared/projects/
```

---

## Bootstrap Installation

### Overview

The bootstrap script automates installation of:
- ✅ Development tools (@development-tools group)
- ✅ Essential utilities (stow, git, curl, wget, vim)
- ✅ Dotfiles dependencies (1Password CLI, rclone, yq, ImageMagick)
- ✅ GNU Stow packages (zsh, git, ssh)
- ✅ ZSH as default shell

### Step 1: Clone Dotfiles Repository

**Inside the VM:**

```bash
# Clone dotfiles to home directory
cd ~
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles

# Verify clone
ls -la
```

### Step 2: Run Bootstrap Script (VM Essentials Mode)

**Inside the VM:**

```bash
# Start timer to track installation time
time ./scripts/bootstrap/fedora-bootstrap.sh --vm-essentials

# This will:
# 1. Update system packages (dnf upgrade)
# 2. Install @development-tools group
# 3. Install essential utilities
# 4. Install dotfiles dependencies
# 5. Deploy GNU Stow packages
# 6. Setup ZSH as default shell
```

**What `--vm-essentials` installs:**
- ✅ System updates (dnf upgrade)
- ✅ Development tools (gcc, make, git, etc.)
- ✅ Essential utilities (stow, curl, wget, vim, htop, tree)
- ✅ 1Password CLI (for secrets management)
- ✅ rclone (for R2 asset sync)
- ✅ yq (YAML processor)
- ✅ ImageMagick (image processing)
- ✅ GNU Stow packages: zsh, git, ssh
- ❌ NO full package list (fast install for VMs)
- ❌ NO Docker (separate step next)

**Installation time:** ~10-15 minutes

### Step 3: Verify Bootstrap Results

**Inside the VM:**

```bash
# Check ZSH is default shell
echo $SHELL
# Expected: /bin/zsh

# If still /bin/bash, log out and back in

# Check Stow packages deployed
ls -la ~/.zshrc
ls -la ~/.gitconfig
ls -la ~/.ssh/config

# Check 1Password CLI
op --version

# Check rclone
rclone version

# Check git configured
git config --global user.name
git config --global user.email
```

**If ZSH not active, log out and back in:**
```bash
exit
# Then SSH back in
ssh fedora-dev
echo $SHELL  # Should now show /bin/zsh
```

---

## Docker Installation

### Overview

Install Docker Engine + Compose v2 using the official script from Issue #57.

### Step 1: Run Docker Installation Script

**Inside the VM:**

```bash
cd ~/dotfiles

# Install Docker Engine + Compose v2
./scripts/bootstrap/install-docker-fedora.sh

# This will:
# 1. Remove conflicting packages (Podman, old Docker)
# 2. Add official Docker repository
# 3. Install Docker Engine + Compose v2
# 4. Configure SELinux for containers
# 5. Configure firewalld for Docker
# 6. Enable Docker service on boot
# 7. Add user to docker group
# 8. Test with hello-world
```

**What the script does (from Issue #57):**
1. ✓ Verifies Fedora environment
2. ✓ Removes conflicting packages (old Docker, **Podman**)
3. ✓ Adds official Docker repository with GPG verification
4. ✓ Installs Docker Engine + Compose v2
5. ✓ Configures SELinux for containers (`container_manage_cgroup on`)
6. ✓ Configures firewalld for Docker networking
7. ✓ Enables Docker service on boot
8. ✓ Adds current user to docker group
9. ✓ Verifies installation with hello-world

**Installation time:** ~5-10 minutes

### Step 2: Activate Docker Group (Important!)

**You must log out and back in for docker group to take effect:**

```bash
# Exit the SSH session
exit

# SSH back in
ssh fedora-dev

# Verify docker group membership
groups
# Expected: should include "docker"

# Alternative: Use newgrp (temporary, current session only)
newgrp docker
```

### Step 3: Verify Docker Installation

**Inside the VM:**

```bash
# Check Docker version
docker --version
# Expected: Docker version 27.x.x

# Check Docker Compose version
docker compose version
# Expected: Docker Compose version v2.x.x

# Check Docker service status
sudo systemctl status docker
# Expected: active (running)

# Test Docker (should work WITHOUT sudo)
docker ps
# Expected: Empty list (no containers running)

# Test with hello-world
docker run hello-world
# Expected: "Hello from Docker!" message

# Test Docker Compose
docker compose version
# Expected: version output
```

### Step 4: Verify SELinux and Firewalld Configuration

**Inside the VM:**

```bash
# Check SELinux mode
getenforce
# Expected: Enforcing (Fedora default)

# Check Docker SELinux boolean
getsebool container_manage_cgroup
# Expected: container_manage_cgroup --> on

# Check firewalld zones
sudo firewall-cmd --list-all
# Expected: docker0 interface added, masquerade enabled

# Check Docker daemon running
docker info | grep -i "Server Version"
# Expected: Server Version: 27.x.x
```

---

## Docker with Shared Folders

### Overview

Test Docker can mount and access Parallels shared folders.

### Step 1: Test Docker with Shared Folder Mount

**Inside the VM:**

```bash
# Create test docker-compose file
cat > ~/test-docker-shared.yml <<'EOF'
version: '3.8'
services:
  test-shared:
    image: alpine:latest
    command: |
      sh -c "
        echo 'Testing shared folder access from Docker...';
        ls -la /mnt/cdn;
        echo 'Shared folder access successful!'
      "
    volumes:
      - /media/psf/Home/media/cdn:/mnt/cdn:ro
EOF

# Run test
docker compose -f ~/test-docker-shared.yml up

# Expected: Lists files from your Mac's ~/media/cdn folder
```

**Expected output:**
```
test-shared-1  | Testing shared folder access from Docker...
test-shared-1  | total 48
test-shared-1  | drwxrwxrwx    1 root     root          4096 Oct 27 10:00 .
test-shared-1  | drwxr-xr-x    1 root     root          4096 Oct 28 12:00 ..
test-shared-1  | drwxrwxrwx    1 root     root          4096 Oct 25 14:30 images
test-shared-1  | drwxrwxrwx    1 root     root          4096 Oct 26 16:00 videos
test-shared-1  | Shared folder access successful!
```

### Step 2: Clean Up Test

```bash
# Remove test file
rm ~/test-docker-shared.yml

# Clean up Docker
docker system prune -f
```

---

## systemd Auto-Update Service

### Overview

Configure systemd timer for automatic dotfiles updates (if script exists).

### Step 1: Check if Auto-Update Script Exists

**Inside the VM:**

```bash
cd ~/dotfiles
ls -la scripts/sync/install-autoupdate.sh
```

### Step 2: Install systemd Timer (if script exists)

**If script exists:**

```bash
# Run install script
./scripts/sync/install-autoupdate.sh

# This creates:
# - ~/.config/systemd/user/dotfiles-autoupdate.service
# - ~/.config/systemd/user/dotfiles-autoupdate.timer
```

### Step 3: Verify systemd Timer

**Inside the VM:**

```bash
# Check service status
systemctl --user status dotfiles-autoupdate.service

# Check timer status
systemctl --user status dotfiles-autoupdate.timer

# List active timers
systemctl --user list-timers

# Manual test
systemctl --user start dotfiles-autoupdate.service

# Check logs
journalctl --user -u dotfiles-autoupdate.service -n 50
```

**If script doesn't exist yet:**
- Skip this section
- Note it in Issue #58 validation results
- Continue to next section

---

## Remote Docker Context

### Overview

Configure Docker context on Mac Studio to control Fedora VM Docker remotely.

### Step 1: Verify SSH Access from Mac Studio

**On Mac Studio:**

```bash
# Test SSH connection
ssh fedora-dev whoami
# Expected: matteocervelli (no password prompt)

# Test Docker is running on VM
ssh fedora-dev 'docker ps'
# Expected: Container list (empty)
```

### Step 2: Create Docker Context on Mac Studio

**On Mac Studio:**

```bash
# Create Docker context for Fedora VM
docker context create fedora-dev4change \
  --docker "host=ssh://matteocervelli@fedora-dev4change"

# List contexts
docker context ls
# Expected: Shows 'fedora-dev4change' in list
```

### Step 3: Use Remote Docker Context

**On Mac Studio:**

```bash
# Switch to Fedora VM context
docker context use fedora-dev4change

# Test remote Docker (runs on Fedora VM!)
docker ps
# Expected: Empty list

# Run hello-world on remote VM
docker run hello-world
# Expected: "Hello from Docker!" (running on Fedora VM)

# Check Docker info (should show Fedora)
docker info | grep "Operating System"
# Expected: "Operating System: Fedora Linux 41 (Workstation Edition)"

# Switch back to local Docker
docker context use default

# Verify you're back on macOS Docker
docker info | grep "Operating System"
# Expected: "Operating System: Docker Desktop" or macOS
```

### Step 4: Verify Remote Context Works

**On Mac Studio:**

```bash
# Use remote context
docker context use fedora-dev4change

# Run a test container
docker run --rm alpine echo "Running on Fedora VM from Mac Studio!"
# Expected: Message printed

# Check from both sides:
# On Mac Studio:
docker ps -a

# On Fedora VM (SSH in):
ssh fedora-dev 'docker ps -a'

# Both should show same containers
```

---

## Testing & Verification

### Complete System Check

**Inside the VM, run all verification tests:**

```bash
# 1. Check Fedora version
cat /etc/fedora-release

# 2. Check hostname
hostname

# 3. Check Parallels Tools
prltools -v
systemctl status prltools.service

# 4. Check shared folders
ls -la /media/psf/Home/dev/
ls -la /media/psf/Home/media/cdn/

# 5. Check ZSH is default
echo $SHELL

# 6. Check dotfiles deployed
ls -la ~/.zshrc ~/.gitconfig

# 7. Check 1Password CLI
op --version

# 8. Check rclone
rclone version

# 9. Check Docker
docker --version
docker compose version
docker ps
docker run --rm alpine echo "Docker works!"

# 10. Check Docker with shared folder
docker run --rm -v /media/psf/Home/media/cdn:/mnt/cdn:ro alpine ls -la /mnt/cdn

# 11. Check network
ping -c 3 google.com

# 12. Check disk space
df -h

# 13. Check memory
free -h

# 14. Check CPU
nproc
```

### From macOS: Verify Remote Access

**On Mac Studio:**

```bash
# 1. Test SSH
ssh fedora-dev whoami

# 2. Test remote Docker context
docker context use fedora-dev4change
docker ps
docker info | grep "Operating System"

# 3. Switch back to local Docker
docker context use default

# 4. List all contexts
docker context ls
```

### Performance Test

**Inside the VM:**

```bash
# Run performance benchmarks
docker run --rm alpine sh -c "echo 'Performance test'; dd if=/dev/zero of=/dev/null bs=1M count=1000"

# Check Docker disk usage
docker system df
```

---

## Troubleshooting

### Issue: Docker Permission Denied

**Symptom**: `permission denied while trying to connect to the Docker daemon socket`

**Solution**:

```bash
# Check docker group membership
groups
# If 'docker' not shown:

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in (REQUIRED!)
exit
ssh fedora-dev

# Verify group membership
groups

# Test Docker
docker ps
```

### Issue: Docker Not Starting

**Symptom**: `Cannot connect to the Docker daemon`

**Solution**:

```bash
# Check Docker service status
sudo systemctl status docker

# If not running, start it
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# Check for errors
journalctl -u docker -n 50
```

### Issue: Shared Folders Not Visible

**Symptom**: `/media/psf/` is empty

**Solution**:

```bash
# Check Parallels Tools service
systemctl status prltools.service

# If not running:
sudo systemctl start prltools.service

# Restart Parallels Tools
sudo systemctl restart prltools.service

# Check mount
mount | grep psf

# Verify from macOS that sharing is enabled:
# VM Configuration → Options → Sharing → "Share Mac folders with Linux" enabled
```

### Issue: SELinux Blocking Docker

**Symptom**: Docker containers fail with permission errors

**Solution**:

```bash
# Check SELinux mode
getenforce

# Check Docker SELinux boolean
getsebool container_manage_cgroup

# If off, enable it:
sudo setsebool -P container_manage_cgroup on

# Check SELinux denials
sudo ausearch -m avc -ts recent

# Temporarily set to permissive (for debugging only):
sudo setenforce 0

# After fixing, set back to enforcing:
sudo setenforce 1
```

### Issue: Remote Docker Context Not Working

**Symptom**: Cannot connect to remote Docker

**Solution**:

```bash
# On Mac Studio:
# Test SSH connection first
ssh fedora-dev 'docker ps'

# If SSH works but Docker context doesn't:
# Remove context
docker context rm fedora-dev4change

# Recreate context
docker context create fedora-dev4change \
  --docker "host=ssh://matteocervelli@fedora-dev4change"

# Test again
docker context use fedora-dev4change
docker ps
```

---

## Next Steps

### VM is Ready for Development! 🎉

Your Fedora development VM is fully configured with:
- ✅ Docker Engine + Compose v2
- ✅ Dotfiles and development tools
- ✅ Shared folders with Mac Studio
- ✅ Remote Docker control from macOS
- ✅ SSH key authentication
- ✅ ZSH with Oh My Zsh

### Recommended Next Actions

1. **Take a VM Snapshot**:
   - Parallels: Actions → Take Snapshot
   - Name: "Fedora Dev - Fully Configured"
   - Allows rollback if needed

2. **Test with Real Projects**:
   - Clone a project to `~/dev-shared/`
   - Run Docker Compose services
   - Verify everything works

3. **Configure IDE**:
   - VSCode Remote SSH to VM
   - Or use Docker Desktop on macOS with remote context

4. **Update Issue #58**:
   - Document total installation time
   - Note any issues encountered
   - Provide feedback on guides

### Development Workflow

**From Mac Studio:**
```bash
# Use remote Docker context
docker context use fedora-dev4change

# Navigate to project (on Mac)
cd ~/dev/projects/my-project

# Run Docker Compose (executes on Fedora VM)
docker compose up -d

# View logs
docker compose logs -f

# Switch back to local Docker
docker context use default
```

**From Fedora VM:**
```bash
# Access shared projects
cd ~/dev-shared/projects/my-project

# Run Docker Compose locally
docker compose up -d
```

---

**Created**: 2025-10-28
**Last Updated**: 2025-10-28
**Status**: ✅ Complete
**Part of**: FASE 7 - Multi-Platform OS Configurations
**Related**: [Issue #58](https://github.com/matteocervelli/dotfiles/issues/58) - Validate Fedora VM Setup
**Related**: [Issue #57](https://github.com/matteocervelli/dotfiles/issues/57) - Docker Engine Installation for Fedora
**Related**: [Guide 4](parallels-4-fedora-vm-creation.md) - Fedora VM Creation
