# Linux Setup Guide

Step-by-step guide for setting up dotfiles on Ubuntu, Fedora, and Arch Linux.

## Prerequisites

- Fresh Linux installation or VM
- Internet connection
- sudo privileges
- Basic command-line knowledge

## Quick Setup (Any Distribution)

```bash
# 1. Clone dotfiles
cd ~
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles

# 2. Generate package lists
./scripts/apps/generate-linux-packages.sh

# 3. Install packages (choose your distro)
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh  # Ubuntu
sudo ./scripts/bootstrap/install-dependencies-fedora.sh  # Fedora
sudo ./scripts/bootstrap/install-dependencies-arch.sh    # Arch

# 4. Setup dotfiles
make install
```

## Ubuntu 24.04 LTS Setup

### Step 1: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Essential Tools

```bash
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --essential-only
```

This installs:
- build-essential
- git, curl, wget
- stow (dotfiles manager)
- ca-certificates, gnupg

### Step 3: Full Package Installation

```bash
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh
```

Installs:
- 92 packages via APT
- Snap packages (VS Code, Flutter)
- Flatpak with Flathub
- Repository setup (1Password, GitHub CLI, Tailscale)

### Step 4: Post-Installation

```bash
# Sign in to 1Password
eval $(op signin)

# Configure Tailscale
sudo tailscale up

# Install pyenv + nvm (already done by script)
# Setup dotfiles
make install
```

## Fedora Workstation Setup

### Step 1: Update System

```bash
sudo dnf upgrade --refresh -y
```

### Step 2: Essential Packages

```bash
sudo ./scripts/bootstrap/install-dependencies-fedora.sh --essential-only
```

### Step 3: Full Installation

```bash
sudo ./scripts/bootstrap/install-dependencies-fedora.sh
```

Features:
- 91 packages via DNF
- RPM Fusion repositories
- Flatpak with Flathub
- DNF optimizations (parallel downloads)

### Step 4: Optional COPR Repositories

```bash
# Additional software from COPR
sudo dnf copr enable varlad/helix
sudo dnf install helix
```

## Arch Linux Setup

### Step 1: Update System

```bash
sudo pacman -Syu
```

### Step 2: Essential + AUR Helper

```bash
sudo ./scripts/bootstrap/install-dependencies-arch.sh --essential-only
```

Installs base-devel, git, and yay (AUR helper).

### Step 3: Full Installation

```bash
sudo ./scripts/bootstrap/install-dependencies-arch.sh
```

Features:
- 77 packages via Pacman
- AUR packages via yay
- Flatpak with Flathub
- Pacman optimizations

### Step 4: AUR Packages

The script auto-installs common AUR packages. For additional:

```bash
yay -S package-name
```

## Common Post-Installation Tasks

### 1. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 2. Setup SSH Keys

```bash
# Generate key
ssh-keygen -t ed25519 -C "your@email.com"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Paste to https://github.com/settings/keys
```

### 3. Install Additional Snap Packages

```bash
snap install code --classic          # VS Code
snap install slack --classic
snap install spotify
```

### 4. Install Flatpak Applications

```bash
flatpak install flathub org.libreoffice.LibreOffice
flatpak install flathub org.gimp.GIMP
flatpak install flathub com.obsproject.Studio
```

### 5. Setup Development Tools

```bash
# Python via pyenv
pyenv install 3.13.0
pyenv global 3.13.0

# Node via nvm
nvm install --lts
nvm use --lts

# Rust (already installed via rustup)
rustup update stable
```

## Troubleshooting

### yq not found

```bash
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

### Snap permission denied

```bash
sudo snap restart
# Or reboot system
```

### Flatpak not working

```bash
# Add Flathub manually
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Fix permissions
flatpak repair
```

### AUR build failures (Arch)

```bash
# Update keyring
sudo pacman -S archlinux-keyring
sudo pacman -Syu

# Clear build cache
yay -Sc
```

## VM-Specific Notes

### Parallels (macOS)

- Enable "Share Mac user folders" for easy file transfer
- Install Parallels Tools for better performance
- Use "Coherence Mode" for seamless integration

### UTM (macOS)

- Enable shared directories
- Use SPICE guest tools for copy/paste
- Configure bridged networking for Tailscale

### VirtualBox

- Install Guest Additions
- Enable shared folders
- Use Host-Only or Bridged network

## Performance Tips

### Ubuntu

```bash
# Disable animations
gsettings set org.gnome.desktop.interface enable-animations false

# Reduce swappiness
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
```

### Fedora

```bash
# Enable DNF parallel downloads (already done by script)
# Disable PackageKit
sudo systemctl mask packagekit
```

### Arch

```bash
# Enable parallel downloads (already done by script)
# Use reflector for fastest mirrors
sudo pacman -S reflector
sudo reflector --country 'Italy' --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
```

## Next Steps

- [Package Management README](../../applications/linux/README.md)
- [Architecture Decision Record](../architecture/ADR/ADR-004-linux-package-management.md)
- [Tech Stack Documentation](../TECH-STACK.md)

---

**Last Updated:** 2025-10-26
**Author:** Matteo Cervelli
