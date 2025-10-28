# Guide 2: Ubuntu Development Environment Setup

**Purpose**: Transform an empty Ubuntu VM into a complete development environment with Docker, dotfiles, and project bindings from Mac Studio.

**Prerequisites**: Completed [Guide 1: Ubuntu VM Creation](parallels-1-ubuntu-vm-creation.md) - You have an Ubuntu VM with Parallels Tools installed.

**Result**: Fully configured development VM with shared folders, Docker, dotfiles, R2 assets, and remote control from macOS.

---

## Table of Contents

1. [Prerequisites Check](#prerequisites-check)
2. [SSH Configuration](#ssh-configuration)
3. [Parallels Shared Folders Setup](#parallels-shared-folders-setup)
4. [Docker Installation](#docker-installation)
5. [Dotfiles Integration](#dotfiles-integration)
6. [R2 Assets Workflow](#r2-assets-workflow)
7. [Project Setup with Mac Studio Bindings](#project-setup-with-mac-studio-bindings)
8. [Remote Docker Context](#remote-docker-context)
9. [Performance Optimization](#performance-optimization)
10. [Testing & Verification](#testing--verification)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites Check

### Required from Guide 1

Run these checks **inside the VM**:

```bash
# 1. Ubuntu version
lsb_release -a  # Should show Ubuntu 24.04 LTS

# 2. Parallels Tools version
cat /usr/lib/parallels-tools/version  # Should show version (e.g., 26.1.1.57288)

# 3. Parallels Tools service running
systemctl status prltoolsd  # Should be active (running)

# 4. Shared folders mounted (ARM64 FUSE-based)
ls -la /media/psf/  # Should show shared folders
mount | grep psf    # Should show type fuse.prl_fsd

# 5. Network working
ping -c 3 google.com  # Should succeed

# 6. SSH service running
systemctl status ssh  # Should be active
```

### From macOS: Verify SSH Access

```bash
# Test SSH from Mac Studio
ssh matteocervelli@ubuntu-dev4change

# Or via IP (find with: hostname -I in VM)
ssh matteocervelli@10.211.55.XXX
```

**If all checks pass, proceed!** ✅

---

## SSH Configuration

### Overview

Configure SSH access to the Ubuntu VM for:
- ✅ **Local access** from Mac Studio (via Parallels Shared Network)
- ✅ **Remote access** from MacBook/other devices (via Tailscale)
- ✅ **Connection multiplexing** for faster subsequent connections
- ✅ **Automatic agent forwarding** for Git operations

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Mac Studio (Host)                            │
│                                                                 │
│  ~/.ssh/config.d/25-vms.conf                                   │
│                                                                 │
│  ┌─────────────────────┐      ┌─────────────────────┐         │
│  │ Local Network       │      │ Tailscale Network   │         │
│  │ ssh ubuntu-dev      │      │ ssh ubuntu-dev-ts   │         │
│  │ 10.211.55.x:22     │      │ .ts.net:22          │         │
│  └──────────┬──────────┘      └──────────┬──────────┘         │
│             │                             │                     │
└─────────────┼─────────────────────────────┼─────────────────────┘
              │                             │
              │  Parallels Shared Network   │  Tailscale VPN
              ▼                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Ubuntu VM (ubuntu-dev4change)                      │
│                                                                 │
│  SSH Server listening on port 22                               │
│  User: matteocervelli                                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Step 1: Configure SSH on Mac Studio

The SSH configuration is managed via GNU Stow in the dotfiles repository.

**File locations:**
- Template: `stow-packages/ssh/.ssh/config.d/25-vms.conf.template`
- Actual config: `stow-packages/ssh/.ssh/config.d/25-vms.conf`
- Main config: `stow-packages/ssh/.ssh/config`

**The configuration has already been created with:**

```bash
# Local network access (from Mac Studio)
Host ubuntu-dev ubuntu-dev4change
    HostName ubuntu-dev4change
    User matteocervelli

# Tailscale network access (from any device in tailnet)
Host ubuntu-dev-tailscale ubuntu-dev-ts
    HostName ubuntu-dev4change.siamese-dominant.ts.net
    User matteocervelli

# Quick shortcuts
Host vm              # Local access shortcut
Host vm-remote       # Tailscale access shortcut
```

### Step 2: Test Local SSH Connection

**From Mac Studio terminal:**

```bash
# Test connection using hostname
ssh ubuntu-dev

# Or use full hostname
ssh ubuntu-dev4change

# Or use shortcut
ssh vm

# First connection will ask to accept host key
# Type: yes
```

**Expected output:**
```
The authenticity of host 'ubuntu-dev4change (10.211.55.3)' can't be established.
ED25519 key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'ubuntu-dev4change' (ED25519) to the list of known hosts.
Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-48-generic aarch64)

matteocervelli@ubuntu-dev4change:~$
```

### Step 3: Setup SSH Keys and Copy to VM

#### A. Ensure SSH Keys on Mac Studio

**The dotfiles repository includes automatic SSH key management:**

```bash
# Run the SSH key setup script
cd ~/dev/projects/dotfiles
./scripts/setup-ssh-keys.sh
```

**What this script does:**
1. Auto-detects your hostname (`studio4change`, `macbook4change`, etc.)
2. Checks for device-specific key in 1Password (`studio4change-ssh-key-2025`)
3. Retrieves and installs the key locally (`~/.ssh/id_ed25519`)
4. Sets correct permissions automatically

**If key doesn't exist in 1Password, it offers to generate one:**
```
Device: studio4change
1Password key name: studio4change-ssh-key-2025

Key not found in 1Password: studio4change-ssh-key-2025

Would you like to generate a new key?
Generate new SSH key? (yes/no): yes
```

**SSH Key Strategy:**
- **One SSH key per device** (more secure, traceable)
- Mac Studio: `studio4change-ssh-key-2025`
- MacBook Pro: `macbook4change-ssh-key-2025`
- Ubuntu VM: `ubuntu-dev4change-ssh-key-2025`
- All keys stored in 1Password vault `dev`

#### B. Copy SSH Public Key to VM

**For passwordless authentication:**

```bash
# From Mac Studio - copy your SSH public key to VM
ssh-copy-id ubuntu-dev

# Or manually (if ssh-copy-id not available)
cat ~/.ssh/id_ed25519.pub | ssh ubuntu-dev "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Set correct permissions on VM (if needed)
ssh ubuntu-dev "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
```

**Test passwordless login:**
```bash
# Should connect without password prompt
ssh ubuntu-dev
```

### Step 4: Configure Tailscale Access (Optional)

**For remote access from MacBook or other devices in your tailnet:**

#### A. Install Tailscale on Ubuntu VM

**From inside the VM:**

```bash
# Add Tailscale repository
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale (will generate authentication URL)
sudo tailscale up

# IMPORTANT: Headless authentication process:
# 1. The command will output an authentication URL like:
#    "To authenticate, visit: https://login.tailscale.com/a/xxxxxxxxxxxxxx"
# 2. Copy this entire URL
# 3. Open the URL in your Mac Studio browser
# 4. Sign in with your darkalis@ account
# 5. Approve the device connection
# 6. Return to the VM terminal - connection will complete automatically

# Verify connection (after authentication)
tailscale status

# Get Tailscale hostname
tailscale status | grep ubuntu
```

**Expected hostname:** `ubuntu-dev4change.siamese-dominant.ts.net`

#### B. Test Tailscale SSH Connection

**From Mac Studio (or MacBook):**

```bash
# Test Tailscale connection
ssh ubuntu-dev-ts

# Or use full hostname
ssh ubuntu-dev4change.siamese-dominant.ts.net

# Or use remote shortcut
ssh vm-remote
```

### Step 5: Configure SSH Server (VM)

**Optimize SSH server settings on the VM:**

```bash
# Edit SSH server config
sudo nano /etc/ssh/sshd_config

# Recommended settings (add/modify):
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes  # Change to 'no' after key setup
X11Forwarding no
ClientAliveInterval 60
ClientAliveCountMax 3

# Save and restart SSH
sudo systemctl restart ssh

# Verify SSH is running
systemctl status ssh
```

### Step 6: Verify SSH Configuration

**From Mac Studio:**

```bash
# Test all connection methods
ssh ubuntu-dev whoami              # Should print: matteocervelli
ssh ubuntu-dev-ts whoami           # Should print: matteocervelli (via Tailscale)
ssh vm whoami                      # Should print: matteocervelli
ssh vm-remote whoami               # Should print: matteocervelli (via Tailscale)

# Test connection multiplexing (second connection should be instant)
time ssh ubuntu-dev whoami         # First connection (~1-2s)
time ssh ubuntu-dev whoami         # Second connection (<0.1s - reuses connection)

# Test agent forwarding (for Git operations)
ssh ubuntu-dev "ssh -T git@github.com"
# Should show: Hi matteocervelli! You've successfully authenticated...
```

### Connection Methods Summary

| Method | Command | Network | Use Case |
|--------|---------|---------|----------|
| **Local (hostname)** | `ssh ubuntu-dev` | Parallels Shared Network | Mac Studio → VM |
| **Local (shortcut)** | `ssh vm` | Parallels Shared Network | Quick access from Studio |
| **Tailscale (hostname)** | `ssh ubuntu-dev-ts` | Tailscale VPN | MacBook → VM |
| **Tailscale (shortcut)** | `ssh vm-remote` | Tailscale VPN | Quick remote access |

### SSH Features Enabled

- ✅ **Connection Multiplexing**: Subsequent connections are instant (~0.1s)
- ✅ **Agent Forwarding**: Git operations work seamlessly
- ✅ **Keep Alive**: Connections don't timeout
- ✅ **Compression**: Faster data transfer on local network
- ✅ **Optimized Ciphers**: ChaCha20 for Tailscale (already encrypted)

### Troubleshooting SSH

**Connection refused:**
```bash
# Check SSH service on VM
ssh ubuntu-dev "sudo systemctl status ssh"

# Restart SSH service
ssh ubuntu-dev "sudo systemctl restart ssh"
```

**Permission denied:**
```bash
# Verify authorized_keys on VM
ssh ubuntu-dev "ls -la ~/.ssh/authorized_keys"
# Should be: -rw------- (600)

# Fix permissions if needed
ssh ubuntu-dev "chmod 600 ~/.ssh/authorized_keys"
```

**Tailscale connection fails:**
```bash
# Check Tailscale status on VM
ssh ubuntu-dev "tailscale status"

# Restart Tailscale
ssh ubuntu-dev "sudo systemctl restart tailscaled"
```

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
   - Folder: `/Users/matteocervelli/dev`
   - Name: `dev` (or keep default)
   - Access rights: **Read and Write**

2. **CDN Assets Directory**:
   - Folder: `/Users/matteocervelli/media/cdn`
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
ln -s /media/psf/dev ~/dev

# Create symlink to CDN assets
ln -s /media/psf/media/cdn ~/cdn

# Verify symlinks
ls -la ~ | grep -E "dev|cdn"
```

**Expected output:**
```
lrwxrwxrwx 1 matteo matteo   24 Oct 26 10:00 cdn -> /media/psf/media/cdn
lrwxrwxrwx 1 matteo matteo   20 Oct 26 10:00 dev -> /media/psf/dev
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

### Prerequisites

**IMPORTANT**: Dotfiles repository is already accessible via shared folder!

```bash
# Verify dotfiles are accessible from Mac Studio
ls ~/dev/projects/dotfiles

# Should show: CHANGELOG.md, Makefile, README.md, scripts/, etc.
```

**No need to clone** - the repository is shared from Mac Studio via Parallels.

### Installation Methods

#### Method 1: Bootstrap Script (Recommended)

```bash
# Navigate to mounted dotfiles
cd ~/dev/projects/dotfiles

# Install Docker via script
sudo ./scripts/bootstrap/install-docker.sh

# Or install full development environment (includes Docker)
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --with-docker
```

#### Method 2: Makefile

```bash
# Navigate to mounted dotfiles
cd ~/dev/projects/dotfiles

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
# Then SSH back in: ssh matteocervelli@ubuntu-dev4change
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

### Architecture: Shared vs Local

**Two approaches for dotfiles in VM:**

#### Approach A: Use Shared Dotfiles (Recommended for Testing)

- **Location**: `~/dev/projects/dotfiles` (shared from Mac Studio)
- **Pros**: Single source of truth, instant sync with Mac
- **Cons**: Stow creates symlinks pointing to shared folder
- **Best for**: Testing, temporary VMs, development

#### Approach B: Clone Locally (Recommended for Production)

- **Location**: `~/.config/dotfiles` (XDG Base Directory compliant)
- **Pros**: VM-specific config, independent from Mac
- **Cons**: Need to sync changes manually
- **Best for**: Long-term VMs, different config than Mac

**We'll use Approach A for this guide** (shared dotfiles).

### Step 1: Verify Dotfiles Access

**Dotfiles are already accessible via shared folder:**

```bash
# Check shared dotfiles
ls ~/dev/projects/dotfiles

# Should show: CHANGELOG.md, Makefile, README.md, scripts/, stow-packages/, etc.

# Navigate to dotfiles
cd ~/dev/projects/dotfiles
```

**Note**: No cloning needed - repository is shared from Mac Studio!

### Step 2: Run Bootstrap Script

**Choose installation level based on your needs:**

#### Option A: VM Essentials (✅ Recommended for VM)

```bash
# Navigate to shared dotfiles
cd ~/dev/projects/dotfiles

# Install VM essentials (CLI dev environment, no GUI apps)
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --vm-essentials
```

**VM Essentials includes (~50 packages):**
- **Build tools**: gcc, make, cmake, autoconf, pkg-config
- **Version control**: git, gh
- **CLI editors**: vim, neovim, tmux
- **System monitoring**: htop, btop, tree
- **Modern CLI tools**: fzf, bat, ripgrep, fd-find
- **JSON/YAML**: jq, yq
- **Programming**: Python 3.12, Node.js, npm
- **Database clients**: postgresql-client, sqlite3
- **Cloud**: rclone
- **Image processing**: imagemagick, ffmpeg
- **Utilities**: stow, curl, wget, moreutils, pv, socat

**Duration**: 3-5 minutes

#### Option B: Full Installation (For complete Mac replication)

```bash
# Full installation (116 packages including GUI apps)
cd ~/dev/projects/dotfiles
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh

# Or via Makefile
make ubuntu-base
```

**Warning**: Installs ALL packages from `system/ubuntu/packages.txt` including:
- GUI apps (browsers, IDE, office suite)
- Multiple language versions
- Packages that may not be available on ARM64

**Duration**: 10-15 minutes (may have failures on unavailable packages)

#### Option C: Minimal Essentials Only

```bash
# Only git, stow, build-essential (9 packages)
cd ~/dev/projects/dotfiles
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --essential-only
```

**Minimal essentials includes**: build-essential, git, stow, curl, wget, ca-certificates, gnupg

**Duration**: 1-2 minutes

### Step 3: Deploy Dotfiles with GNU Stow

```bash
# Navigate to shared dotfiles
cd ~/dev/projects/dotfiles

# Install GNU Stow if not installed
sudo apt install -y stow

# Verify Stow version
stow --version

# Deploy all packages
make stow

# Or deploy specific packages manually
cd ~/dev/projects/dotfiles/stow-packages
stow -t ~ shell
stow -t ~ git
stow -t ~ ssh
```

**Expected behavior:**

- ✅ `.zshrc` and `.p10k.zsh` are symlinked
- ✅ `.bashrc` is **NOT** overwritten (Ubuntu default preserved)
- ✅ `.gitconfig` and `.ssh/config` are symlinked
- ℹ️ If you want to use bash, manually source shared configs from `~/.config/shell/`

**Symlinks created (shared dotfiles):**

- `~/.zshrc` → `~/dev/projects/dotfiles/stow-packages/shell/.zshrc`
- `~/.gitconfig` → `~/dev/projects/dotfiles/stow-packages/git/.gitconfig`
- `~/.ssh/config` → `~/dev/projects/dotfiles/stow-packages/ssh/.ssh/config`

**Benefits of shared dotfiles:**

- ✅ Edit on Mac Studio, instantly available in VM
- ✅ Single source of truth
- ✅ Test dotfiles changes in VM before committing
- ⚠️ VM-specific configs should use `~/.config/` overrides

### Step 4: Install Oh My Zsh

**Install Oh My Zsh framework before setting zsh as default:**

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# When prompted "Do you want to change your default shell to zsh?"
# Answer: No (we'll do this properly in the next step)

# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Verify installation
ls -la ~/.oh-my-zsh
ls -la ~/.oh-my-zsh/custom/themes/powerlevel10k
```

**Expected result:**

- ✅ Oh My Zsh installed at `~/.oh-my-zsh`
- ✅ Powerlevel10k theme installed
- ⚠️ Shell NOT changed yet (we'll do this properly next)

### Step 5: Complete ZSH Setup (All-in-One)

**Quick Setup with Consolidated Script:**

```bash
# Navigate to shared dotfiles
cd ~/dev/projects/dotfiles

# Run consolidated VM ZSH setup script
./scripts/bootstrap/setup-vm-zsh.sh

# This script installs:
# - Oh My Zsh plugins (zsh-autosuggestions, zsh-syntax-highlighting)
# - CLI tools (eza)
# - Sets ZSH as default shell
```

**Or follow manual steps below:**

---

### Step 5a: Set ZSH as Default Shell

**Important**: Setting ZSH as default works for **all access methods**:
- ✅ SSH connections
- ✅ GUI terminal sessions
- ✅ Local console login

**Prerequisites:**

- ✅ ZSH installed (from VM essentials package)
- ✅ Oh My Zsh installed (previous step)
- ✅ Dotfiles stowed (symlinks created)

**Automated method (recommended):**

```bash
# Navigate to shared dotfiles
cd ~/dev/projects/dotfiles

# Run default shell setup script
sudo ./scripts/bootstrap/set-default-shell.sh

# Expected output:
# ✅ Found shell: /usr/bin/zsh
# ✅ Shell is in /etc/shells
# ✅ Default shell changed successfully!
```

**Manual method:**

```bash
# Verify zsh is installed
which zsh
# Expected: /usr/bin/zsh

# Check if zsh is in /etc/shells
grep zsh /etc/shells
# Expected: /usr/bin/zsh

# If not listed, add it
echo "/usr/bin/zsh" | sudo tee -a /etc/shells

# Change default shell
sudo chsh -s $(which zsh) $USER

# Verify the change
getent passwd $USER | cut -d: -f7
# Expected: /usr/bin/zsh
```

**Testing the change:**

```bash
# Test 1: Check shell in /etc/passwd
getent passwd $USER
# Last field should be: /usr/bin/zsh

# Test 2: New SSH session (from Mac Studio)
ssh ubuntu-dev
echo $SHELL
# Expected: /usr/bin/zsh

# Test 3: Start zsh manually (current session)
zsh
# Should load Oh My Zsh with Powerlevel10k theme
```

**Note**: The shell change takes effect:

- **Immediately** for new SSH connections
- **After logout/login** for GUI terminal sessions
- **Current session** remains unchanged until you start a new shell or reboot

**Test the shell:**

```bash
# Test 4: Reconnect via SSH to activate new shell
exit
ssh ubuntu-dev

# Should automatically:
# - Load Oh My Zsh
# - Show Powerlevel10k prompt
# - Run .zshrc configuration

# Verify
echo $SHELL
# Expected: /usr/bin/zsh
```

### Step 5b: Install Oh My Zsh Plugins (Manual)

**If you didn't use the consolidated script, install plugins manually:**

```bash
# Install zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install eza (modern ls replacement)
sudo apt install -y eza

# Verify installations
ls -la ~/.oh-my-zsh/custom/plugins/
eza --version
```

**Note**: The `.zshrc` from dotfiles already enables these plugins. Just install them and reload:

```bash
# Reload ZSH config
source ~/.zshrc
```

---

### Step 6: Configure Git

```bash
# Verify Git config
git config --list

# Set global config if needed
git config --global user.name "Matteo Cervelli"
git config --global user.email "your-email@example.com"

# Test Git
git status
```

### Step 7: Set Up SSH Keys

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
scp ~/.ssh/id_ed25519 matteocervelli@ubuntu-dev4change:~/.ssh/
scp ~/.ssh/id_ed25519.pub matteocervelli@ubuntu-dev4change:~/.ssh/

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
scp ~/.config/rclone/rclone.conf matteocervelli@ubuntu-dev4change:~/.config/rclone/

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
# /Users/matteocervelli/dev/projects/my-app/src/index.ts

# VM: Changes are immediately visible
cd ~/dev/projects/my-app/
cat src/index.ts  # Shows latest changes

# VM: Run Docker build
docker compose build

# VM: Start services
docker compose up -d

# Mac Studio: Access service
curl http://ubuntu-dev4change:3000
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
ssh matteocervelli@ubuntu-dev4change docker ps
```

### Step 2: Create Docker Context (macOS)

**From Mac Studio:**

```bash
# Create remote context
docker context create ubuntu-dev4change \
  --docker "host=ssh://matteocervelli@ubuntu-dev4change"

# Or with custom SSH key
docker context create ubuntu-dev4change \
  --docker "host=ssh://matteocervelli@ubuntu-dev4change" \
  --description "Ubuntu VM on Parallels"

# List contexts
docker context ls

# Switch to VM context
docker context use ubuntu-dev4change

# Test - this now runs on VM!
docker ps
docker images
```

### Step 3: Switch Between Contexts

```bash
# Use VM Docker
docker context use ubuntu-dev4change
docker ps  # Lists containers on VM

# Use macOS Docker Desktop
docker context use default
docker ps  # Lists containers on Mac

# One-off command on specific context
docker --context ubuntu-dev4change ps
```

### Step 4: Test Remote Control

```bash
# From Mac Studio, using VM Docker
docker context use ubuntu-dev4change

# Run container on VM
docker run -d --name test-nginx -p 8080:80 nginx:alpine

# Check on VM (from macOS)
docker ps

# Access from Mac Studio browser
open http://ubuntu-dev4change:8080

# Cleanup
docker stop test-nginx
docker rm test-nginx
```

### Step 5: Docker Compose Remote

```bash
# From Mac Studio, in a project directory
cd ~/dev/projects/my-project/

# Use VM Docker context
docker context use ubuntu-dev4change

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
# Navigate to shared dotfiles
cd ~/dev/projects/dotfiles

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
cat ~/dev/projects/dotfiles/docs/checklists/vm-integration-checklist.md

# Or open in editor
vim ~/dev/projects/dotfiles/docs/checklists/vm-integration-checklist.md
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
ls -la ~/.zshrc && ls ~/dev/projects/dotfiles

# 5. Git
git config --list | grep user

# 6. SSH from macOS (run on Mac Studio)
ssh matteocervelli@ubuntu-dev4change 'echo "SSH works!"'

# 7. Remote Docker from macOS (run on Mac Studio)
docker --context ubuntu-dev4change ps

# 8. Project access
ls ~/dev/projects/
```

✅ **All tests passing - VM fully configured!**

---

## Troubleshooting

### Issue: SSH Connections Always Start Bash (Not ZSH)

**Symptom**:
- `/etc/passwd` shows `/usr/bin/zsh` correctly
- `chsh` was successful
- Manual `zsh` invocation works
- But SSH connections still start bash

**Root Cause**:
This issue was caused by **1Password SSH stub key files** on the macOS client. The files `~/.ssh/id_ed25519` (66 bytes) were 1Password references, not actual keys. When SSH tried to auto-load these during connection, it interfered with the SSH session negotiation, causing the SSH daemon to fall back to bash.

**Solution (macOS side)**:

```bash
# 1. Check if you have tiny key files (likely 1Password stubs)
ls -lh ~/.ssh/id_ed25519*
# If id_ed25519 is ~66 bytes, it's a stub reference

# 2. Backup the stub files
mkdir -p ~/.ssh/.1password-stubs
mv ~/.ssh/id_ed25519* ~/.ssh/.1password-stubs/

# 3. Update SSH config to prevent auto-loading
# Edit: ~/.ssh/config.d/02-1password-macos.conf
# Add: IdentitiesOnly yes

# 4. Restow SSH config
cd ~/dev/projects/dotfiles/stow-packages
stow -R -t ~ ssh

# 5. Test - should now start ZSH
ssh ubuntu-dev
echo $SHELL  # Should show: /usr/bin/zsh
```

**Why this fixed it**: The stub key files were causing SSH errors during connection negotiation. Removing them and adding `IdentitiesOnly yes` prevents SSH from auto-loading default key locations, letting the 1Password agent handle all SSH operations cleanly.

**Additional symptoms this fixes**:
- macOS: Powerlevel10k instant prompt warnings about console output
- macOS: "not a public key file" errors during shell initialization
- VM: SSH sessions starting bash instead of configured shell

---

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

**Symptom**: `docker --context ubuntu-dev4change ps` fails with connection error

**Solution**:

```bash
# 1. Test SSH from macOS
ssh matteocervelli@ubuntu-dev4change docker ps

# 2. If SSH fails, check SSH key
ssh-add -l  # On macOS
ssh-copy-id matteocervelli@ubuntu-dev4change

# 3. Recreate Docker context
docker context rm ubuntu-dev4change
docker context create ubuntu-dev4change --docker "host=ssh://matteocervelli@ubuntu-dev4change"

# 4. Test again
docker context use ubuntu-dev4change
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

# Deploy dotfiles changes (pull happens automatically on Mac Studio)
cd ~/dev/projects/dotfiles
make stow  # Redeploy if config changed

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
