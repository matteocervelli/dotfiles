# Linux Mint System Configuration

**Profile**: `mint-desktop`
**OS**: Linux Mint 21+ (Cinnamon)
**Base**: Ubuntu 22.04 LTS (Jammy)
**Roles**: `development`, `productivity`

---

## Overview

Linux Mint configuration for Parallels VM development environment with full Cinnamon desktop. Optimized for:

- Full-stack development (Python, Node.js, Go)
- GUI application testing
- Desktop Linux experience
- Productivity workflows

---

## Directory Structure

```
system/mint/
├── README.md                      # This file
├── packages-desktop.txt           # Desktop package list
├── cinnamon/
│   └── configure-desktop.sh       # Cinnamon desktop configuration
└── systemd/
    ├── dotfiles-autoupdate.service  # Auto-update service
    └── dotfiles-autoupdate.timer    # Auto-update timer
```

---

## Bootstrap Installation

### Quick Start

```bash
# Clone dotfiles
git clone https://github.com/matteocervelli/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run Mint bootstrap
./scripts/bootstrap/mint-bootstrap.sh
```

### Installation Options

```bash
# Full installation (default)
./scripts/bootstrap/mint-bootstrap.sh

# Dry-run (preview only)
./scripts/bootstrap/mint-bootstrap.sh --dry-run

# Skip GUI applications
./scripts/bootstrap/mint-bootstrap.sh --skip-gui

# Skip Cinnamon configuration
./scripts/bootstrap/mint-bootstrap.sh --skip-cinnamon
```

---

## Package Management

### Install Desktop Packages

```bash
# Install all desktop packages
./scripts/bootstrap/install-dependencies-mint.sh --desktop

# Essential packages only
./scripts/bootstrap/install-dependencies-mint.sh --essential-only

# Preview installation
./scripts/bootstrap/install-dependencies-mint.sh --dry-run
```

### Package Sources

1. **APT Packages**: From `packages-desktop.txt`
2. **Snap Packages**: VS Code, additional apps
3. **Language Managers**:
   - Python: pyenv
   - Node.js: nvm
   - Rust: rustup

---

## Cinnamon Desktop Configuration

### Apply Developer Settings

```bash
# Apply developer-friendly settings
./system/mint/cinnamon/configure-desktop.sh

# Preview changes
./system/mint/cinnamon/configure-desktop.sh --dry-run

# Reset to Mint defaults
./system/mint/cinnamon/configure-desktop.sh --reset
```

### Settings Applied

**Theme & Appearance:**
- Dark theme: Mint-Y-Dark-Aqua
- Icon theme: Mint-Y-Aqua
- Monospace font: JetBrains Mono

**Desktop Behavior:**
- 4 workspaces
- Click-to-focus
- Minimal desktop icons

**Keyboard Shortcuts:**
- Terminal: `Ctrl+Alt+T`
- Browser: `Super+B`
- Workspace switching: `Ctrl+Alt+Arrow`
- Maximize: `Super+Up`

**File Manager (Nemo):**
- Show hidden files
- List view as default
- Show full paths
- Visible columns: name, size, type, date, permissions

---

## Mint vs Ubuntu Differences

### Desktop Environment

| Feature | Ubuntu (GNOME) | Mint (Cinnamon) |
|---------|---------------|-----------------|
| Desktop | GNOME Shell | Cinnamon |
| File Manager | Nautilus | Nemo |
| Terminal | GNOME Terminal | GNOME Terminal |
| Text Editor | gedit | xed |
| Settings | gsettings | gsettings + Cinnamon Settings |

### Package Availability

**Mint-Specific Packages:**
- `timeshift` - System snapshot backup tool (pre-installed)
- `mintbackup` - Mint backup utility
- `mintinstall` - Software Manager
- `mintwelcome` - Welcome screen
- `mint-meta-cinnamon` - Cinnamon meta-package

**Differences:**
- Mint uses Ubuntu repositories but adds own packages
- Some GNOME apps replaced with MATE/Xfce alternatives
- Mint Update Manager (custom update tool)

### Repository Compatibility

Linux Mint is based on Ubuntu LTS and uses:
- Ubuntu repositories (main, universe, restricted, multiverse)
- Mint repositories (overlay with Mint-specific packages)
- Third-party repos work with Ubuntu codename (e.g., `jammy`)

```bash
# Check Ubuntu base
source /etc/os-release
echo "Mint version: $VERSION_ID"
echo "Ubuntu base: $UBUNTU_CODENAME"
```

---

## Recommended Customizations

### Essential Applets

Right-click panel → Add applets to panel:

1. **System Monitor** - CPU, RAM, network monitoring
2. **Workspace Switcher OSD** - Visual workspace switching
3. **Sound 150%** - Enhanced volume control
4. **Weather** - Local weather info
5. **Calendar** - Calendar with events

### Cinnamon Themes

```bash
# Install additional themes
sudo apt install mint-themes mint-y-icons mint-x-icons

# Browse themes
# System Settings > Themes
```

### Nemo Actions

Custom right-click actions in file manager:

```bash
# Location: ~/.local/share/nemo/actions/

# Example: Open terminal here (already built-in)
# Example: Open as root
# Example: Compare files with meld
```

### Desklets

Desktop widgets for productivity:

```bash
# System Settings > Desklets
# Popular: Clock, Notes, System Monitor, Weather
```

---

## Parallels Integration

### Shared Folders

Parallels shared folders are automatically mounted:

```bash
# macOS host folders appear in:
/media/psf/Home          # macOS home directory
/media/psf/Documents     # macOS Documents
/media/psf/dev           # Shared development folder

# Access from terminal:
cd /media/psf/dev
```

### Clipboard Sharing

Bidirectional clipboard sharing enabled by default:
- Copy on macOS → Paste in Mint
- Copy in Mint → Paste on macOS

### Parallels Tools

```bash
# Check Parallels Tools status
prlctl --version

# Reinstall if needed (rarely required)
sudo /media/cdrom/install
```

---

## Stow Packages

Deployed packages for `mint-desktop` profile:

```bash
cd ~/dotfiles

# Deploy shell configuration
stow -t ~ -d stow-packages shell

# Deploy git configuration
stow -t ~ -d stow-packages git

# Deploy SSH configuration
stow -t ~ -d stow-packages ssh

# Deploy 1Password configuration
stow -t ~ -d stow-packages 1password

# Deploy VS Code settings
stow -t ~ -d stow-packages vscode
```

---

## Mint-Specific Tools

### Timeshift (System Backup)

```bash
# Configure Timeshift (recommended)
sudo timeshift-gtk

# Create snapshot
sudo timeshift --create --comments "Before major changes"

# List snapshots
sudo timeshift --list

# Restore (from Live USB if system broken)
sudo timeshift --restore
```

### Update Manager

```bash
# Mint Update Manager (GUI)
mintupdate-launcher

# CLI alternative
sudo apt update && sudo apt upgrade
```

### Software Manager

```bash
# Mint Software Manager (GUI alternative to apt)
mintinstall

# Search for packages
mintinstall search firefox
```

---

## Troubleshooting

### Cinnamon Crashes

```bash
# Restart Cinnamon (preserves session)
cinnamon --replace &

# Reset Cinnamon settings
dconf reset -f /org/cinnamon/

# Check logs
cat ~/.xsession-errors
journalctl -b -u cinnamon
```

### Parallels Issues

```bash
# Reinstall Parallels Tools
sudo mount /dev/cdrom /media/cdrom
sudo /media/cdrom/install

# Check shared folders
df -h | grep psf
```

### Display Resolution

```bash
# Cinnamon display settings
cinnamon-settings display

# Or use xrandr
xrandr
xrandr --output Virtual-1 --mode 1920x1080
```

---

## Resources

### Official Documentation

- [Linux Mint User Guide](https://linuxmint.com/documentation.php)
- [Cinnamon Documentation](https://cinnamon-spices.linuxmint.com/)
- [Mint Forums](https://forums.linuxmint.com/)

### Community Resources

- [Mint Subreddit](https://reddit.com/r/linuxmint)
- [Mint Discord](https://discord.gg/EVVtPpw)
- [Cinnamon Spices](https://cinnamon-spices.linuxmint.com/) - Themes, applets, desklets

### Related Documentation

- [Ubuntu Setup Guide](../../docs/guides/linux-setup-guide.md)
- [DEVICE-MATRIX.md](../../docs/os-configurations/DEVICE-MATRIX.md)
- [PROFILES.md](../../docs/os-configurations/PROFILES.md)

---

**Created**: 2025-10-27
**Target Device**: Parallels Linux Mint Cinnamon (ARM64)
**Status**: FASE 7.3 Implementation
**Issue**: [#41](https://github.com/matteocervelli/dotfiles/issues/41)
