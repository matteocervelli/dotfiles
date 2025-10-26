# Bootstrap Strategies - OS-Specific Installation Approaches

**Project**: Dotfiles Multi-Platform Support
**Created**: 2025-10-26
**Status**: FASE 7 (Planning & Implementation)

---

## Overview

This document outlines the bootstrap strategies for installing dotfiles across 8+ different operating systems and distributions. Each strategy is tailored to the platform's package manager, conventions, and ecosystem.

---

## Core Principles

### 1. OS Detection First

All bootstrap scripts start with OS detection:

```bash
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../utils/detect-os.sh"

case "$OS_TYPE" in
    macos)
        echo "Detected macOS $(sw_vers -productVersion)"
        ;;
    ubuntu|debian)
        echo "Detected Ubuntu/Debian"
        ;;
    fedora|rhel)
        echo "Detected Fedora/RHEL"
        ;;
    arch)
        echo "Detected Arch Linux"
        ;;
    *)
        echo "Unsupported OS: $OS_TYPE"
        exit 1
        ;;
esac
```

### 2. Idempotent Operations

All bootstrap scripts are idempotent (safe to run multiple times):

```bash
# Check if already installed
if command -v brew >/dev/null 2>&1; then
    echo "Homebrew already installed, skipping..."
else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
```

### 3. Minimal Dependencies First

Install only what's needed to run the dotfiles system, then install everything else:

**Phase 1: Bootstrap Dependencies**
- Package manager (Homebrew, APT, DNF, Pacman)
- GNU Stow
- Git
- Curl/wget

**Phase 2: Dotfiles Core**
- 1Password CLI
- Rclone
- yq
- ImageMagick

**Phase 3: Profile Packages**
- Development tools (Python, Node, etc.)
- Applications (browsers, editors, etc.)
- Services (Docker, databases, etc.)

### 4. Error Handling

All scripts use strict error handling:

```bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Logging
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logger.sh"

log_info "Starting bootstrap..."
log_success "Bootstrap complete!"
log_error "Bootstrap failed: $error_message"
```

---

## macOS Bootstrap Strategy

### Script: `scripts/bootstrap/macos-bootstrap.sh`

### Package Manager: Homebrew

**Installation:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Architecture Handling:**
- **Apple Silicon (ARM64)**: `/opt/homebrew/bin/brew`
- **Intel (x86_64)**: `/usr/local/bin/brew`

**Path Setup:**
```bash
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi
```

### Bootstrap Sequence

1. **Install Homebrew** (if not present)
2. **Install Core Tools**:
   ```bash
   brew install stow git curl wget
   ```
3. **Install Dotfiles Dependencies**:
   ```bash
   brew install --cask 1password-cli
   brew install rclone yq imagemagick
   brew install mas  # Mac App Store CLI
   ```
4. **Deploy Stow Packages**:
   ```bash
   stow -t ~ shell git ssh 1password
   ```
5. **Install Profile Packages** (if `--profile` specified):
   ```bash
   brew bundle --file=system/macos/profiles/mac-studio.brewfile
   ```

### macOS-Specific Considerations

- **Xcode Command Line Tools**: Required for Homebrew, auto-installed
- **Rosetta 2**: Auto-installed on first x86_64 binary (Apple Silicon)
- **SIP (System Integrity Protection)**: Cannot modify system directories
- **Gatekeeper**: Downloaded binaries may require approval

---

## Ubuntu/Debian Bootstrap Strategy

### Script: `scripts/bootstrap/ubuntu-bootstrap.sh`

### Package Manager: APT

**Update First:**
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Bootstrap Sequence

1. **Install Core Tools**:
   ```bash
   sudo apt-get install -y stow git curl wget build-essential
   ```

2. **Install 1Password CLI**:
   ```bash
   curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
     sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
     sudo tee /etc/apt/sources.list.d/1password.list
   sudo apt-get update && sudo apt-get install -y 1password-cli
   ```

3. **Install Rclone**:
   ```bash
   sudo apt-get install -y rclone
   # Or latest version:
   curl https://rclone.org/install.sh | sudo bash
   ```

4. **Install yq**:
   ```bash
   sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture)
   sudo chmod +x /usr/local/bin/yq
   ```

5. **Install ImageMagick**:
   ```bash
   sudo apt-get install -y imagemagick
   ```

6. **Deploy Stow Packages**:
   ```bash
   stow -t ~ shell git ssh 1password
   ```

### Ubuntu-Specific Considerations

- **Snap vs APT**: Prefer APT for system packages, Snap for GUI apps
- **PPA Management**: Add PPAs carefully, prefer official repositories
- **Sudo**: Most operations require sudo (unlike Homebrew on macOS)

### Docker Installation (Optional)

If `--profile ubuntu-vm` or `--install-docker`:

```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker
```

---

## Fedora/RHEL Bootstrap Strategy

### Script: `scripts/bootstrap/fedora-bootstrap.sh`

### Package Manager: DNF (Dandified YUM)

**Target**: Fedora Workstation 40+ (ARM64/x86_64)

**Update First:**
```bash
sudo dnf update -y
```

### Bootstrap Sequence

**Phase 1: OS Verification**
- Detect Fedora via `/etc/fedora-release`
- Verify DNF package manager availability
- Check SELinux status (inform, don't disable)
- Check firewalld status

**Phase 2: System Update**
```bash
sudo dnf check-update
sudo dnf upgrade -y
```

**Phase 3: Essential Development Tools**
```bash
# Install Development Tools group (gcc, make, etc.)
sudo dnf group install -y "Development Tools"

# Install essential packages
sudo dnf install -y stow git curl wget ca-certificates gnupg2
```

**Phase 4: Dotfiles Core Dependencies**

1. **1Password CLI**:
   ```bash
   sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
   sudo sh -c 'cat > /etc/yum.repos.d/1password.repo << EOF
   [1password]
   name=1Password Stable Channel
   baseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch
   enabled=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgkey=https://downloads.1password.com/linux/keys/1password.asc
   EOF'
   sudo dnf install -y 1password-cli
   ```

2. **Rclone**:
   ```bash
   sudo dnf install -y rclone
   ```

3. **yq (YAML processor)**:
   ```bash
   # Detect architecture (amd64 or arm64)
   YQ_ARCH=$([ "$(uname -m)" = "aarch64" ] && echo "arm64" || echo "amd64")
   sudo wget -qO /usr/local/bin/yq \
     https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}
   sudo chmod +x /usr/local/bin/yq
   ```

4. **ImageMagick**:
   ```bash
   sudo dnf install -y ImageMagick
   ```

**Phase 5: Stow Package Deployment**
```bash
cd dotfiles/packages
stow -t ~ zsh git ssh
```

**Phase 6: ZSH Setup**
```bash
sudo dnf install -y zsh
sudo chsh -s $(command -v zsh) $(whoami)
```

**Phase 7: Optional Full Package Installation**
```bash
# Install all packages from system/fedora/packages.txt
./scripts/bootstrap/install-dependencies-fedora.sh
```

### Script Usage

```bash
# Minimal setup (essential tools only)
./scripts/bootstrap/fedora-bootstrap.sh

# Full development environment
./scripts/bootstrap/fedora-bootstrap.sh --with-packages

# Preview actions (dry-run)
./scripts/bootstrap/fedora-bootstrap.sh --dry-run

# Quick essential-only setup
./scripts/bootstrap/fedora-bootstrap.sh --essential-only

# Skip repository setup (use default repos)
./scripts/bootstrap/fedora-bootstrap.sh --skip-repos
```

### Fedora-Specific Considerations

**DNF Package Manager:**
- Modern replacement for YUM (Fedora 22+)
- Faster dependency resolution
- Group install: `dnf group install "Development Tools"`
- Case-sensitive package names: `ImageMagick` not `imagemagick`

**SELinux (Security-Enhanced Linux):**
```bash
# Check status
getenforce  # Enforcing, Permissive, or Disabled

# Bootstrap script checks but doesn't disable
# Some operations may require SELinux context changes:
sudo chcon -R -t user_home_t ~/.ssh  # Example
```

**Firewalld (Default Firewall):**
```bash
# Check status
sudo firewall-cmd --state

# List active zones
sudo firewall-cmd --get-active-zones

# Allow service through firewall
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

**RPM Fusion Repositories (Optional):**
```bash
# Free repository (open-source)
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

# Non-free repository (proprietary)
sudo dnf install -y \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Multimedia codecs
sudo dnf install -y ffmpeg gstreamer1-plugins-{bad-*,good-*,base} \
  gstreamer1-plugin-openh264 mozilla-openh264
```

### Package Name Differences

| Tool | Ubuntu (APT) | Fedora (DNF) | Notes |
|------|-------------|--------------|-------|
| Build tools | `build-essential` | `@development-tools` | Group install |
| Python 3 | `python3` | `python3` | Same |
| Python dev | `python3-dev` | `python3-devel` | Different suffix |
| Node.js | `nodejs npm` | `nodejs npm` | Same |
| Docker | `docker.io` | `docker` | No `.io` suffix |
| ImageMagick | `imagemagick` | `ImageMagick` | Case-sensitive! |
| C compiler | `gcc` (in build-essential) | `gcc gcc-c++` | Separate C++ |
| OpenSSL dev | `libssl-dev` | `openssl-devel` | Different naming |

### Architecture Support

**ARM64 (Apple Silicon via Parallels):**
- Full support in Fedora Workstation 40+
- Native ARM64 packages via DNF
- yq binary: `yq_linux_arm64`
- Most development tools available natively

**x86_64 (Intel/AMD):**
- Standard architecture
- Complete package ecosystem
- yq binary: `yq_linux_amd64`

### Profiles

**`fedora-dev` (Issue #40):**
- Full development environment
- All packages from `system/fedora/packages.txt`
- Docker, databases, development tools
- Target: Parallels VM on Mac Studio/MacBook

**`kids-safe` (Issue #46):**
- Educational software focus
- Parental controls (malcontent)
- Restricted user setup
- Safe browsing configuration
- Builds on top of base Fedora bootstrap

---

## Arch Linux Bootstrap Strategy

### Script: `scripts/bootstrap/arch-bootstrap.sh`

### Package Manager: Pacman + AUR (yay/paru)

**Update First:**
```bash
sudo pacman -Syu --noconfirm
```

### Bootstrap Sequence

1. **Install Core Tools**:
   ```bash
   sudo pacman -S --noconfirm stow git curl wget base-devel
   ```

2. **Install AUR Helper (yay)**:
   ```bash
   # Clone yay
   cd /tmp
   git clone https://aur.archlinux.org/yay.git
   cd yay
   makepkg -si --noconfirm
   cd ~
   ```

3. **Install 1Password CLI** (via AUR):
   ```bash
   yay -S --noconfirm 1password-cli
   ```

4. **Install Rclone**:
   ```bash
   sudo pacman -S --noconfirm rclone
   ```

5. **Install yq**:
   ```bash
   yay -S --noconfirm yq
   ```

6. **Install ImageMagick**:
   ```bash
   sudo pacman -S --noconfirm imagemagick
   ```

### Arch-Specific Considerations

- **Rolling Release**: Always up-to-date, but less stable
- **Manual Configuration**: No guided installer
- **AUR**: Community packages, requires compilation
- **Pacman vs Yay**: Use pacman for official, yay for AUR

### AUR Helper Choice

- **yay** (recommended): Go-based, fast, actively maintained
- **paru**: Rust-based alternative, similar features
- **trizen**: Perl-based, older but stable

---

## Omarchy Bootstrap Strategy

### Script: `scripts/bootstrap/omarchy-bootstrap.sh`

### Research Needed

**Questions to Answer:**
1. What is Omarchy based on? (Ubuntu LTS, Fedora, custom?)
2. What package manager does it use? (APT, DNF, custom?)
3. What desktop environment? (GNOME, KDE, custom?)
4. DHH's opinionated defaults - what should we preserve vs override?

**Likely Strategy** (assuming Ubuntu-based):
```bash
# Probably similar to Ubuntu bootstrap
source scripts/bootstrap/ubuntu-bootstrap.sh

# Omarchy-specific overrides
# - Respect DHH's choices (don't override desktop theme, etc.)
# - Add only missing dotfiles pieces
# - Document differences from vanilla Ubuntu
```

**Reference:** https://omarchy.org

---

## Docker Ubuntu Bootstrap Strategy

### Script: `scripts/bootstrap/docker-ubuntu.sh`

### Minimal Container Profile

**Goal**: < 500MB image with dotfiles

**Dockerfile:**
```dockerfile
FROM ubuntu:24.04

# Minimal dependencies
RUN apt-get update && apt-get install -y \
    stow \
    git \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy dotfiles
COPY stow-packages/ /dotfiles/stow-packages/
WORKDIR /dotfiles

# Deploy minimal packages (shell + git only)
RUN stow -t /root shell git

# Set default shell
CMD ["/bin/bash"]
```

**Multi-Stage Build** (Development Variant):
```dockerfile
# Stage 1: Base
FROM ubuntu:24.04 AS base
RUN apt-get update && apt-get install -y stow git curl wget
COPY stow-packages/ /dotfiles/stow-packages/
RUN cd /dotfiles && stow -t /root shell git

# Stage 2: Development
FROM base AS development
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    nodejs npm \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Stage 3: Production (minimal)
FROM base AS production
# No additional packages
```

---

## VPS Security Hardening (Post-Bootstrap)

### Script: `scripts/security/harden-vps.sh`

Applied automatically with `--profile vps-minimal`:

1. **SSH Hardening**:
   ```bash
   # Disable password authentication
   sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

   # Disable root login
   sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
   sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

   sudo systemctl restart sshd
   ```

2. **Firewall (UFW)**:
   ```bash
   sudo apt-get install -y ufw
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow 22/tcp  # SSH
   sudo ufw allow 80/tcp  # HTTP
   sudo ufw allow 443/tcp # HTTPS
   sudo ufw --force enable
   ```

3. **Fail2Ban**:
   ```bash
   sudo apt-get install -y fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

4. **Automatic Updates**:
   ```bash
   sudo apt-get install -y unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```

---

## Windows Bootstrap Strategy (Future)

### Script: `scripts/bootstrap/windows-bootstrap.ps1`

### Package Managers: winget + Scoop

**PowerShell Strategy:**
```powershell
# Install winget (Windows 11: pre-installed)
# Windows 10: Install from Microsoft Store

# Install Scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install core tools
scoop install git
winget install Git.Git
winget install Microsoft.PowerShell

# Install 1Password
winget install AgileBits.1Password

# Symlink configs (requires admin)
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.gitconfig" -Target "$PSScriptRoot\..\..\stow-packages\git\.gitconfig"
```

**WSL2 Integration:**
```powershell
# Install WSL2
wsl --install -d Ubuntu-24.04

# Inside WSL2, use standard Ubuntu bootstrap
wsl bash -c "./scripts/bootstrap/ubuntu-bootstrap.sh"
```

---

## Testing Strategy

### 1. Unit Testing

Test individual bootstrap scripts in isolated VMs:

```bash
# macOS
./scripts/bootstrap/macos-bootstrap.sh --dry-run

# Ubuntu
docker run -it --rm -v $(pwd):/dotfiles ubuntu:24.04 /dotfiles/scripts/bootstrap/ubuntu-bootstrap.sh --dry-run
```

### 2. Integration Testing

Full installation on fresh VMs:

- Parallels: Create Ubuntu 24.04 VM, run bootstrap, verify
- UTM: Create Arch Linux VM, run bootstrap, verify
- Docker: Build image, run container, verify

### 3. Health Checks

Post-installation validation:

```bash
./scripts/health/check-all.sh

# Verify:
# - Stow symlinks correct
# - Dependencies installed
# - Configs applied
# - Services running (if applicable)
```

---

## Rollback Strategy

### Snapshot Before Bootstrap

**Parallels/UTM:**
- Create VM snapshot before running bootstrap
- If bootstrap fails, revert to snapshot

**macOS:**
- Time Machine backup before major changes
- Homebrew cleanup: `brew uninstall <package>`

**Linux (APT):**
- `apt-mark` packages as auto-installed
- `apt autoremove` to clean up

### Uninstall Scripts

```bash
# Uninstall dotfiles
./scripts/stow/unstow-all.sh

# Remove packages (careful!)
./scripts/bootstrap/uninstall.sh --confirm
```

---

## Troubleshooting

### Common Issues

**1. Permission Denied**
```bash
# macOS: Add user to admin group (already admin)
# Linux: Add user to sudo group
sudo usermod -aG sudo $USER
```

**2. Package Not Found**
```bash
# Update package lists first
brew update              # macOS
sudo apt-get update      # Ubuntu
sudo dnf check-update    # Fedora
sudo pacman -Sy          # Arch
```

**3. Network Issues**
```bash
# Test connectivity
curl -I https://github.com

# Use Tailscale if available
ping mac-studio.tailscale-alias
```

**4. Disk Space**
```bash
# Clean caches
brew cleanup             # macOS
sudo apt-get clean       # Ubuntu
sudo dnf clean all       # Fedora
sudo pacman -Scc         # Arch
```

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Maintained By**: Matteo Cervelli
**Project**: [dotfiles](https://github.com/matteocervelli/dotfiles)
