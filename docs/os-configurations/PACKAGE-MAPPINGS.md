# Package Mappings - Cross-Distribution Package Names

**Project**: Dotfiles Multi-Platform Support
**Created**: 2025-10-27
**Status**: FASE 7.4 - Arch Linux Bootstrap

---

## Overview

This document provides package name mappings across different Linux distributions to facilitate cross-platform dotfiles deployment. Package managers use different naming conventions, and this guide helps translate package names between Ubuntu (APT), Fedora (DNF), and Arch Linux (Pacman).

---

## Quick Reference

| Tool/Library | Ubuntu (APT) | Fedora (DNF) | Arch (Pacman) | Notes |
|--------------|--------------|--------------|---------------|-------|
| **Build Tools** | `build-essential` | `@development-tools` | `base-devel` | C/C++ compiler, make, etc. |
| **1Password CLI** | `1password-cli` | `1password-cli` | `1password-cli` (AUR) | Requires repo setup on Ubuntu/Fedora |
| **GNU Stow** | `stow` | `stow` | `stow` | ✅ Same name |
| **Git** | `git` | `git` | `git` | ✅ Same name |
| **Rclone** | `rclone` | `rclone` | `rclone` | ✅ Same name |
| **yq** | Manual install | Manual install | `yq` (AUR) | Binary download recommended for Ubuntu/Fedora |
| **ImageMagick** | `imagemagick` | `ImageMagick` | `imagemagick` | Note: Capital 'I' on Fedora |
| **Node.js** | `nodejs npm` | `nodejs npm` | `nodejs npm` | ✅ Same name |
| **Python** | `python3` | `python3` | `python` | Arch: python = Python 3 |
| **Docker** | `docker.io` | `docker` | `docker` | Ubuntu uses `.io` suffix |
| **Docker Compose** | `docker-compose-plugin` | `docker-compose-plugin` | `docker-compose` | Arch has standalone package |
| **ZSH** | `zsh` | `zsh` | `zsh` | ✅ Same name |
| **Neovim** | `neovim` | `neovim` | `neovim` | ✅ Same name |
| **Tmux** | `tmux` | `tmux` | `tmux` | ✅ Same name |
| **htop** | `htop` | `htop` | `htop` | ✅ Same name |
| **btop** | `btop` | `btop` | `btop` | ✅ Same name |
| **bat** | `bat` | `bat` | `bat` | ✅ Same name |
| **eza** | `eza` | `eza` | `eza` | Modern `ls` replacement |
| **fzf** | `fzf` | `fzf` | `fzf` | ✅ Same name |
| **ripgrep** | `ripgrep` | `ripgrep` | `ripgrep` | ✅ Same name |
| **GitHub CLI** | `gh` | `gh` | `github-cli` | Different name on Arch |
| **Rust** | `rustc cargo` | `rust cargo` | `rust` | Arch bundles rustc+cargo |
| **Go** | `golang-go` | `golang` | `go` | Different names |
| **Ruby** | `ruby-full` | `ruby` | `ruby` | Ubuntu needs `-full` |
| **PostgreSQL** | `postgresql postgresql-contrib` | `postgresql postgresql-server` | `postgresql` | Server setup varies |
| **Redis** | `redis-server` | `redis` | `redis` | Ubuntu uses `-server` |
| **Java (OpenJDK)** | `openjdk-21-jdk` | `java-21-openjdk` | `jdk-openjdk` | Version numbers differ |
| **LaTeX** | `texlive-full` | `texlive-scheme-full` | `texlive-most` | Huge download |
| **Pandoc** | `pandoc` | `pandoc` | `pandoc` | ✅ Same name |
| **FFmpeg** | `ffmpeg` | `ffmpeg` | `ffmpeg` | May need RPM Fusion on Fedora |
| **Inkscape** | `inkscape` | `inkscape` | `inkscape` | ✅ Same name |
| **GIMP** | `gimp` | `gimp` | `gimp` | ✅ Same name |
| **VLC** | `vlc` | `vlc` | `vlc` | May need RPM Fusion on Fedora |
| **Firefox** | `firefox` | `firefox` | `firefox` | ✅ Same name |
| **Chromium** | `chromium-browser` | `chromium` | `chromium` | Ubuntu uses `-browser` |
| **Tailscale** | `tailscale` | `tailscale` | `tailscale` | ✅ Same name |
| **Ollama** | Manual install | Manual install | `ollama` (AUR) | Arch via AUR |
| **Terraform** | Manual install | Manual install | `terraform` (AUR) | Arch via AUR |
| **Ansible** | `ansible` | `ansible` | `ansible` | ✅ Same name |

---

## Distribution-Specific Package Management

### Ubuntu/Debian (APT)

**Package Manager:** APT (Advanced Package Tool)

#### Basic Commands

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Install package
sudo apt install -y package-name

# Search for package
apt search keyword

# Show package info
apt show package-name

# Remove package
sudo apt remove package-name

# Remove package + config files
sudo apt purge package-name

# Clean up unused dependencies
sudo apt autoremove
```

#### Repository Management

```bash
# Add PPA (Personal Package Archive)
sudo add-apt-repository ppa:repository-name/ppa
sudo apt update

# Add external repository with GPG key
curl -fsSL https://example.com/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/example.gpg
echo "deb [signed-by=/usr/share/keyrings/example.gpg] https://example.com/repo stable main" | \
  sudo tee /etc/apt/sources.list.d/example.list
sudo apt update
```

#### Special Considerations

- **Snap:** Ubuntu includes Snap for containerized applications
- **Build Dependencies:** Use `build-essential` meta-package
- **Architecture:** Use `dpkg --print-architecture` to detect (amd64, arm64)

---

### Fedora/RHEL (DNF)

**Package Manager:** DNF (Dandified YUM)

#### Basic Commands

```bash
# Update package metadata
sudo dnf check-update

# Upgrade all packages
sudo dnf upgrade -y

# Install package
sudo dnf install -y package-name

# Search for package
dnf search keyword

# Show package info
dnf info package-name

# Remove package
sudo dnf remove package-name

# Clean up unused dependencies
sudo dnf autoremove

# Install package group
sudo dnf group install "Group Name"
```

#### Repository Management

```bash
# Add repository
sudo dnf config-manager --add-repo https://example.com/repo.repo

# Enable repository
sudo dnf config-manager --set-enabled repository-id

# Add GPG key
sudo rpm --import https://example.com/key.asc

# Manual repo file
sudo tee /etc/yum.repos.d/example.repo << EOF
[example]
name=Example Repository
baseurl=https://example.com/repo/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://example.com/key.asc
EOF
```

#### Special Considerations

- **RPM Fusion:** Needed for multimedia codecs and proprietary software
- **SELinux:** May require context changes for some operations
- **Firewalld:** Default firewall (vs UFW on Ubuntu)
- **Build Dependencies:** Use `@development-tools` group

---

### Arch Linux (Pacman + AUR)

**Package Manager:** Pacman (official repos) + AUR helpers (community packages)

#### Basic Commands - Pacman

```bash
# Synchronize package databases and upgrade
sudo pacman -Syu

# Install package
sudo pacman -S package-name

# Install without confirmations
sudo pacman -S --noconfirm package-name

# Search for package
pacman -Ss keyword

# Show package info
pacman -Si package-name

# Remove package
sudo pacman -R package-name

# Remove package + dependencies
sudo pacman -Rns package-name

# Clean package cache
sudo pacman -Sc
```

#### AUR (Arch User Repository)

**AUR Helpers:** `yay`, `paru`, `trizen`

```bash
# Install yay (AUR helper)
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

# Install package from AUR (using yay)
yay -S package-name

# Search AUR
yay -Ss keyword

# Upgrade all packages (including AUR)
yay -Syu
```

#### Special Considerations

- **Rolling Release:** Always latest packages, update frequently
- **Manual Configuration:** No guided installer, more hands-on
- **AUR Compilation:** AUR packages are built from source (requires `base-devel`)
- **Build Dependencies:** Use `base-devel` group
- **No Official Binary for Some Tools:** Must use AUR or manual installation

---

## Common Package Patterns

### Development Tools

| Category | Ubuntu | Fedora | Arch |
|----------|--------|--------|------|
| C/C++ Compiler | `build-essential` | `@development-tools` | `base-devel` |
| GCC | `gcc g++` | `gcc gcc-c++` | `gcc` |
| Make | Included in build-essential | Included in dev-tools | `make` |
| CMake | `cmake` | `cmake` | `cmake` |
| Autoconf/Automake | `autoconf automake` | `autoconf automake` | `autoconf automake` |

### Programming Languages

| Language | Ubuntu | Fedora | Arch |
|----------|--------|--------|------|
| Python 3 | `python3 python3-pip` | `python3 python3-pip` | `python python-pip` |
| Node.js | `nodejs npm` | `nodejs npm` | `nodejs npm` |
| Ruby | `ruby-full` | `ruby` | `ruby` |
| Go | `golang-go` | `golang` | `go` |
| Rust | `rustc cargo` | `rust cargo` | `rust` |
| Java | `openjdk-21-jdk` | `java-21-openjdk` | `jdk-openjdk` |
| PHP | `php php-cli` | `php php-cli` | `php` |
| Perl | `perl` | `perl` | `perl` |
| Lua | `lua5.4` | `lua` | `lua` |

### Databases

| Database | Ubuntu | Fedora | Arch |
|----------|--------|--------|------|
| PostgreSQL | `postgresql postgresql-contrib` | `postgresql postgresql-server` | `postgresql` |
| MySQL | `mysql-server` | `mysql-server` | `mariadb` |
| Redis | `redis-server` | `redis` | `redis` |
| SQLite | `sqlite3` | `sqlite` | `sqlite` |
| MongoDB | Manual install | Manual install | `mongodb-bin` (AUR) |

### Version Control

| Tool | Ubuntu | Fedora | Arch |
|------|--------|--------|------|
| Git | `git` | `git` | `git` |
| Git LFS | `git-lfs` | `git-lfs` | `git-lfs` |
| GitHub CLI | `gh` | `gh` | `github-cli` |
| Mercurial | `mercurial` | `mercurial` | `mercurial` |
| Subversion | `subversion` | `subversion` | `subversion` |

### Shell Tools

| Tool | Ubuntu | Fedora | Arch |
|------|--------|--------|------|
| ZSH | `zsh` | `zsh` | `zsh` |
| Fish | `fish` | `fish` | `fish` |
| Bash Completion | `bash-completion` | `bash-completion` | `bash-completion` |
| Tmux | `tmux` | `tmux` | `tmux` |
| Screen | `screen` | `screen` | `screen` |

---

## Bootstrap Script Mapping

Each bootstrap script uses the appropriate package manager:

### Ubuntu Bootstrap

```bash
# Update
sudo apt update && sudo apt upgrade -y

# Install essentials
sudo apt install -y stow git curl wget build-essential

# Install dotfiles core
sudo apt install -y 1password-cli rclone imagemagick
```

### Fedora Bootstrap

```bash
# Update
sudo dnf upgrade -y

# Install essentials
sudo dnf install -y stow git curl wget
sudo dnf group install -y "Development Tools"

# Install dotfiles core
sudo dnf install -y 1password-cli rclone ImageMagick
```

### Arch Bootstrap

```bash
# Update
sudo pacman -Syu --noconfirm

# Install essentials
sudo pacman -S --noconfirm stow git curl wget base-devel

# Install AUR helper (yay)
cd /tmp && git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si --noconfirm

# Install dotfiles core
yay -S --noconfirm 1password-cli
sudo pacman -S --noconfirm rclone imagemagick yq
```

---

## Package Discovery

### Finding Package Names

#### Ubuntu/Debian

```bash
# Search by name
apt search firefox

# Search by description
apt search "web browser"

# Find which package provides a file
dpkg -S /usr/bin/firefox
```

#### Fedora/RHEL

```bash
# Search by name
dnf search firefox

# Search by description
dnf search all "web browser"

# Find which package provides a file
dnf provides /usr/bin/firefox
```

#### Arch Linux

```bash
# Search by name
pacman -Ss firefox

# Search in AUR (using yay)
yay -Ss firefox

# Find which package owns a file
pacman -Qo /usr/bin/firefox
```

---

## Architecture Considerations

### Detecting Architecture

```bash
# Generic Linux
uname -m
# Output: x86_64, aarch64, armv7l, etc.

# Ubuntu (dpkg)
dpkg --print-architecture
# Output: amd64, arm64, armhf

# Fedora/Arch (rpm/pacman)
uname -m
# Output: x86_64, aarch64
```

### Binary Downloads

When manually installing binaries (like `yq`), architecture matters:

| `uname -m` | Binary Suffix |
|------------|---------------|
| x86_64 | `amd64` or `x86_64` |
| aarch64 | `arm64` or `aarch64` |
| armv7l | `armv7` |

Example for yq:
```bash
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        YQ_BINARY="yq_linux_amd64"
        ;;
    aarch64|arm64)
        YQ_BINARY="yq_linux_arm64"
        ;;
esac
sudo wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}"
sudo chmod +x /usr/local/bin/yq
```

---

## Resources

### Official Documentation

- **Ubuntu Packages:** https://packages.ubuntu.com/
- **Fedora Packages:** https://packages.fedoraproject.org/
- **Arch Packages:** https://archlinux.org/packages/
- **AUR:** https://aur.archlinux.org/

### Package Search Tools

- **Debian/Ubuntu:** https://packages.debian.org/
- **Fedora:** https://src.fedoraproject.org/
- **Arch:** https://archlinux.org/packages/
- **Repology (Cross-distro):** https://repology.org/

### Related Documentation

- [BOOTSTRAP-STRATEGIES.md](BOOTSTRAP-STRATEGIES.md) - Installation approaches
- [DEVICE-MATRIX.md](DEVICE-MATRIX.md) - Device/OS mapping
- [OVERVIEW.md](OVERVIEW.md) - Multi-platform support overview

---

**Created**: 2025-10-27
**Last Updated**: 2025-10-27
**Maintained By**: Matteo Cervelli
**Project**: [dotfiles](https://github.com/matteocervelli/dotfiles)
