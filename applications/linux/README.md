# Linux Package Management

Complete Linux package management system for **Ubuntu**, **Fedora**, and **Arch Linux** distributions. Maps macOS Homebrew packages to their Linux equivalents and provides automated installation workflows.

**Part of FASE 4.1** ([Issue #37](https://github.com/matteocervelli/dotfiles/issues/37))

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Package Mappings](#package-mappings)
- [Installation Workflows](#installation-workflows)
- [Package Lists](#package-lists)
- [Audit System](#audit-system)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)

## Overview

This system provides:

1. **Cross-platform package mappings** - 92+ packages mapped from macOS to Linux
2. **Automated installation** - Bootstrap scripts for each distro
3. **Audit capabilities** - Discover installed packages
4. **Package list generation** - Create distro-specific lists from YAML
5. **Open-source alternatives** - Prioritize FOSS where available

### Supported Distributions

| Distribution | Package Manager | Additional | Bootstrap Script |
|--------------|-----------------|------------|------------------|
| Ubuntu 24.04 LTS | APT | Snap, Flatpak | `install-dependencies-ubuntu.sh` |
| Fedora 40+ | DNF | Flatpak, COPR | `install-dependencies-fedora.sh` |
| Arch Linux | Pacman | AUR (yay/paru), Flatpak | `install-dependencies-arch.sh` |

## Quick Start

### 1. Generate Package Lists

```bash
# Generate all distribution package lists
./scripts/apps/generate-linux-packages.sh

# Generate for specific distro
./scripts/apps/generate-linux-packages.sh --distro ubuntu
./scripts/apps/generate-linux-packages.sh --distro fedora
./scripts/apps/generate-linux-packages.sh --distro arch

# Dry run to preview
./scripts/apps/generate-linux-packages.sh --dry-run
```

### 2. Install Packages

#### Ubuntu

```bash
# Full installation
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh

# Essential packages only (git, stow, build tools)
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --essential-only

# Dry run to preview
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --dry-run
```

#### Fedora

```bash
# Full installation
sudo ./scripts/bootstrap/install-dependencies-fedora.sh

# Essential packages only
sudo ./scripts/bootstrap/install-dependencies-fedora.sh --essential-only

# Skip repository setup (use defaults only)
sudo ./scripts/bootstrap/install-dependencies-fedora.sh --skip-repos
```

#### Arch Linux

```bash
# Full installation with AUR
sudo ./scripts/bootstrap/install-dependencies-arch.sh

# Skip AUR packages
sudo ./scripts/bootstrap/install-dependencies-arch.sh --skip-aur

# Specify AUR helper
sudo ./scripts/bootstrap/install-dependencies-arch.sh --aur-helper yay
```

### 3. Audit Installed Packages

```bash
# Audit on any Linux system
./scripts/apps/audit-apps-linux.sh

# Verbose output
./scripts/apps/audit-apps-linux.sh --verbose

# Custom output file
./scripts/apps/audit-apps-linux.sh --output /tmp/packages.txt
```

## Package Mappings

### Structure

Package mappings are defined in [`package-mappings.yml`](package-mappings.yml) following the schema in [`mapping-schema.yml`](mapping-schema.yml).

**Example mapping:**

```yaml
git:
  category: "development"
  apt: "git"
  dnf: "git"
  pacman: "git"
  opensource: true
  notes: "Same package name across all distributions"

1password-cli:
  category: "security"
  apt: "1password-cli"
  dnf: "1password-cli"
  aur: "1password-cli"
  repo_setup:
    ubuntu: "curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && ..."
    fedora: "sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc && ..."
  alternatives:
    - "bitwarden-cli"
  opensource: false
  notes: "Proprietary but has open-source alternative (Bitwarden)"
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `category` | string | Package category (development, languages, databases, etc.) |
| `apt` | string\|null | Ubuntu/Debian package name |
| `dnf` | string\|null | Fedora/RHEL package name |
| `pacman` | string\|null | Arch Linux package name |
| `snap` | string\|null | Snap package name (if preferred) |
| `flatpak` | string\|null | Flatpak application ID |
| `aur` | string\|null | AUR package name (Arch only) |
| `alternatives` | array | Open-source or alternative packages |
| `repo_setup` | object | Repository setup commands per distro |
| `notes` | string | Additional information |
| `opensource` | boolean | Whether package is open-source |

### Categories

- **development** - Git, build tools, IDEs
- **languages** - Python, Node.js, Rust, Go, Ruby
- **databases** - PostgreSQL, SQLite
- **infrastructure** - Docker, Tailscale, Caddy
- **security** - GPG, 1Password, OpenSSL
- **cli-utilities** - bat, eza, fzf, htop, tmux
- **productivity** - VS Code, browsers, LibreOffice
- **media** - ffmpeg, Audacity, OBS
- **system** - Core libraries and dependencies

## Installation Workflows

### Bootstrap Scripts

All bootstrap scripts support:

- `--help` - Show usage information
- `--dry-run` - Preview without making changes
- `--essential-only` - Install only critical packages
- `--verbose` - Detailed output

### Installation Process

1. **OS Detection** - Verify correct Linux distribution
2. **Package Manager Setup** - Update caches, enable optimizations
3. **Essential Packages** - Install build tools, git, stow
4. **Repository Setup** - Add third-party repos (1Password, GitHub CLI, etc.)
5. **Package Installation** - Install from generated package lists
6. **Universal Package Managers** - Setup Snap/Flatpak
7. **Post-Installation** - Install pyenv, nvm, rustup

### Repository Setup

Some packages require external repositories:

**Ubuntu:**
- 1Password CLI
- GitHub CLI
- Tailscale
- Caddy
- Docker CE

**Fedora:**
- RPM Fusion (multimedia)
- 1Password
- GitHub CLI
- Tailscale
- Google Cloud CLI

**Arch:**
- AUR via yay/paru
- Standard repos cover most packages

## Package Lists

Generated package lists are stored in:

- [`system/ubuntu/packages.txt`](../../system/ubuntu/packages.txt) - 92 packages
- [`system/fedora/packages.txt`](../../system/fedora/packages.txt) - 91 packages
- [`system/arch/packages.txt`](../../system/arch/packages.txt) - 77 packages

### Manual Installation

Install from package lists directly:

```bash
# Ubuntu
cat system/ubuntu/packages.txt | grep -v '^#' | xargs sudo apt install -y

# Fedora
cat system/fedora/packages.txt | grep -v '^#' | xargs sudo dnf install -y

# Arch
cat system/arch/packages.txt | grep -v '^#' | xargs sudo pacman -S --needed --noconfirm
```

## Audit System

The audit script discovers all installed packages from multiple sources:

**Detected Package Managers:**
- APT (Ubuntu/Debian)
- DNF (Fedora/RHEL)
- Pacman (Arch Linux)
- Snap (universal)
- Flatpak (universal)
- AUR via yay/paru (Arch)

**Output Format:**

```
# Linux Application Audit
# Generated: 2025-10-26 08:00:00
# Distribution: ubuntu 24.04
# Total Packages: 1234

# ============================================================
# APT Packages (Debian/Ubuntu) - 950 packages
# ============================================================

git
stow
vim
...
```

## Security Considerations

### Input Validation

All scripts validate:
- Package names contain only safe characters `[a-zA-Z0-9._@+-]`
- No shell metacharacters (`;`, `&`, `|`, `` ` ``, `$`, `(`, `)`)
- Proper path sanitization

### Repository Trust

Third-party repositories require GPG key verification:

```bash
# Example: 1Password on Ubuntu
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
```

### Package Manager Preference

When multiple options exist:

1. **Native packages** (APT/DNF/Pacman) - Fastest, best integration
2. **Flatpak** - Sandboxed, good for GUI apps
3. **Snap** - Universal but slower startup
4. **AUR** - Arch only, community packages

## Troubleshooting

### Common Issues

**Problem:** `yq not found`

```bash
# Install yq (required for package list generation)
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

**Problem:** Repository GPG errors

```bash
# Update system keys
sudo apt update --allow-insecure-repositories  # Ubuntu
sudo dnf makecache --refresh                    # Fedora
sudo pacman -Sy archlinux-keyring              # Arch
```

**Problem:** Package conflicts

```bash
# Use --essential-only first, then install incrementally
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --essential-only
# Then install specific packages manually
```

**Problem:** Snap/Flatpak not available

```bash
# Install manually
sudo apt install snapd flatpak              # Ubuntu
sudo dnf install snapd flatpak              # Fedora
sudo pacman -S snapd flatpak               # Arch
```

### Debugging

Enable verbose output for all scripts:

```bash
./scripts/apps/audit-apps-linux.sh --verbose
./scripts/apps/generate-linux-packages.sh --verbose
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --verbose
```

Use dry-run mode to preview changes:

```bash
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --dry-run
```

### Testing

Run the test suite:

```bash
bats tests/test-37-linux-packages.bats
```

## Next Steps

After package installation:

1. **Sign in to 1Password**: `eval $(op signin)`
2. **Configure Tailscale**: `sudo tailscale up`
3. **Setup Rclone**: `./scripts/sync/setup-rclone.sh`
4. **Install Snap apps**: `snap install code --classic`
5. **Install Flatpak apps**: `flatpak install flathub org.libreoffice.LibreOffice`
6. **Setup dotfiles**: `make install`

## Related Documentation

- [FASE 4.1 Issue #37](https://github.com/matteocervelli/dotfiles/issues/37)
- [Architecture Decision Record](../../docs/architecture/ADR/ADR-004-linux-package-management.md)
- [Linux Setup Guide](../../docs/guides/linux-setup-guide.md)
- [Tech Stack Documentation](../../docs/TECH-STACK.md)

## Contributing

### Adding New Packages

1. Add mapping to `package-mappings.yml`:
   ```yaml
   new-package:
     category: "cli-utilities"
     apt: "new-package"
     dnf: "new-package"
     pacman: "new-package"
     opensource: true
   ```

2. Regenerate package lists:
   ```bash
   ./scripts/apps/generate-linux-packages.sh
   ```

3. Test installation:
   ```bash
   sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --dry-run
   ```

### Updating Mappings

Edit `package-mappings.yml` and regenerate lists. Changes are automatically picked up.

---

**License:** MIT
**Maintainer:** Matteo Cervelli
**Last Updated:** 2025-10-26
