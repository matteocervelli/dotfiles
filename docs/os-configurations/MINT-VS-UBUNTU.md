# Linux Mint vs Ubuntu: Key Differences

**Created**: 2025-10-27
**Issue**: [#41](https://github.com/matteocervelli/dotfiles/issues/41)
**Profile**: `mint-desktop` vs `ubuntu-vm`

---

## Executive Summary

Linux Mint is an Ubuntu-based distribution with a focus on user-friendliness and desktop experience. While it shares Ubuntu's package management and base system, Mint provides a traditional desktop environment (Cinnamon) and custom tools that differentiate it from Ubuntu's GNOME experience.

**Key Takeaways:**
- Mint is based on Ubuntu LTS (Long Term Support)
- Full compatibility with Ubuntu packages and repositories
- Different desktop environment (Cinnamon vs GNOME)
- Custom Mint tools and applications
- More traditional, Windows-like desktop experience

---

## Base System Comparison

### Distribution Base

| Aspect | Ubuntu | Linux Mint |
|--------|--------|------------|
| **Base** | Debian | Ubuntu LTS |
| **Release Cycle** | 6 months (LTS: 2 years) | Based on Ubuntu LTS only |
| **Support Period** | 5 years (LTS) | Same as Ubuntu LTS base |
| **Current Version** | 24.04 LTS (Noble) | 21.x (based on 22.04 Jammy) |
| **Codename** | Noble Numbat | Virginia (based on Jammy) |

### Package Management

```bash
# Both use APT package manager
sudo apt update
sudo apt install package-name

# Repository structure
# Ubuntu: main, universe, restricted, multiverse
# Mint: Same + Mint overlay repositories

# Check Ubuntu base in Mint
source /etc/os-release
echo "Mint: $VERSION_ID, Ubuntu base: $UBUNTU_CODENAME"
```

---

## Desktop Environment

### Ubuntu (GNOME Shell)

**Characteristics:**
- Modern, touch-friendly interface
- Activities overview for app launching
- Top bar with system tray
- Dash to Dock (Ubuntu customization)
- Vertical workspace switching
- Minimalist design philosophy

**File Manager:** Nautilus (Files)
**Text Editor:** gedit (Text Editor)
**Settings:** GNOME Settings
**Terminal:** GNOME Terminal

### Linux Mint (Cinnamon)

**Characteristics:**
- Traditional desktop paradigm
- Bottom panel with menu, taskbar, system tray
- Desktop icons enabled by default
- Windows-like familiarity
- Horizontal workspace switching
- Highly customizable (applets, desklets, themes)

**File Manager:** Nemo
**Text Editor:** xed
**Settings:** Cinnamon Settings (+ System Settings)
**Terminal:** GNOME Terminal (inherited from GNOME)

---

## Desktop Environment Feature Matrix

| Feature | Ubuntu (GNOME) | Mint (Cinnamon) |
|---------|----------------|-----------------|
| **Panel** | Top bar | Bottom panel (configurable) |
| **App Launcher** | Activities overview | Menu button |
| **Taskbar** | Dock (left side) | Panel (bottom) |
| **System Tray** | Top right | Bottom right |
| **Workspaces** | Vertical | Horizontal |
| **Desktop Icons** | Disabled by default | Enabled |
| **Window Buttons** | Right side | Right side |
| **Alt+Tab** | Window switcher | Window switcher |
| **Animations** | Smooth, modern | Smooth, customizable |
| **Themes** | Limited | Extensive (Mint themes) |

---

## Default Applications

### System Applications

| Category | Ubuntu | Linux Mint |
|----------|--------|------------|
| **File Manager** | Nautilus (Files) | Nemo |
| **Text Editor** | gedit | xed |
| **Terminal** | GNOME Terminal | GNOME Terminal |
| **Image Viewer** | Eye of GNOME | Eye of GNOME |
| **Document Viewer** | Evince | Evince |
| **Archive Manager** | File Roller | File Roller |
| **Calculator** | GNOME Calculator | GNOME Calculator |
| **System Monitor** | GNOME System Monitor | GNOME System Monitor |

### Mint-Specific Applications

**Pre-installed in Mint (not in Ubuntu):**

1. **Timeshift** - System snapshot backup tool
   ```bash
   sudo timeshift-gtk
   ```

2. **Software Manager** - Mint's custom software center
   ```bash
   mintinstall
   ```

3. **Update Manager** - Mint's update tool
   ```bash
   mintupdate
   ```

4. **Backup Tool** - Mint's backup utility
   ```bash
   mintbackup
   ```

5. **Welcome Screen** - First-run welcome app
   ```bash
   mintwelcome
   ```

6. **System Reports** - System issue reporting
   ```bash
   mint-system-reports
   ```

---

## Package Differences

### Mint-Specific Packages

```bash
# Mint desktop environment
mint-meta-cinnamon          # Cinnamon desktop meta-package
cinnamon-desktop-environment
cinnamon-control-center

# Mint tools
timeshift                   # System backup
mintbackup                  # File backup
mintinstall                 # Software Manager
mintstick                   # USB stick formatter
mint-themes                 # Mint themes
mint-x-icons                # Mint icon themes
mint-y-icons

# Mint artwork
mint-backgrounds
mint-wallpapers-virginia    # Version-specific wallpapers

# Mint utilities
mint-info                   # System information
mint-common                 # Common utilities
```

### Ubuntu Packages Not in Mint

```bash
# GNOME-specific (removed in Mint)
gnome-shell                 # GNOME Shell (replaced by Cinnamon)
gnome-control-center        # GNOME Settings
nautilus                    # File manager (replaced by Nemo)
gedit                       # Text editor (replaced by xed)

# Ubuntu branding
ubuntu-wallpapers
ubuntu-session
```

---

## Configuration Differences

### Settings Location

**Ubuntu (GNOME):**
```bash
# GNOME settings via gsettings
gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"

# Settings stored in:
~/.config/dconf/
~/.local/share/gnome-shell/
```

**Linux Mint (Cinnamon):**
```bash
# Cinnamon settings via gsettings
gsettings set org.cinnamon.desktop.interface gtk-theme "Mint-Y-Dark"

# Settings stored in:
~/.config/dconf/
~/.cinnamon/
~/.local/share/cinnamon/
```

### Theme Customization

**Ubuntu:**
- Limited theme options (Yaru variants)
- GNOME extensions for customization
- Requires GNOME Tweaks for advanced settings

**Mint:**
- Extensive theme options (Mint-X, Mint-Y variants)
- Built-in theme customization in System Settings
- Applets, desklets, extensions available via Cinnamon Spices

---

## File Manager Comparison

### Nautilus (Ubuntu) vs Nemo (Mint)

| Feature | Nautilus | Nemo |
|---------|----------|------|
| **Design** | Minimalist | Feature-rich |
| **Toolbar** | Simplified | Full featured |
| **Location Bar** | Breadcrumb (default) | Path or breadcrumb |
| **Sidebar** | Left sidebar | Left sidebar + optional right |
| **View Options** | Limited | Extensive |
| **Plugins** | Limited | Extensive (Nemo Actions) |
| **Context Menu** | Basic | Customizable (Nemo Actions) |
| **Thumbnail Size** | Fixed options | Zoom slider |

### Nemo Advantages

**Nemo Actions** - Custom context menu entries:
```bash
# Location: ~/.local/share/nemo/actions/

# Example: Open terminal here
# Example: Compare files
# Example: Convert images
# Example: Open as root
```

**Dual Pane Mode:**
- Press F3 for split view
- Compare directories side-by-side

**More View Options:**
- List view with customizable columns
- Compact view
- Icon view with size control

---

## Repository Compatibility

### Third-Party Repositories

Both Ubuntu and Mint are compatible with the same third-party repositories, but use different codenames:

```bash
# Ubuntu 24.04 (Noble)
deb https://example.com/ubuntu noble main

# Mint 21 (based on Ubuntu 22.04 Jammy)
deb https://example.com/ubuntu jammy main
```

**For Mint, use the Ubuntu base codename:**
```bash
# Check Ubuntu base
source /etc/os-release
echo $UBUNTU_CODENAME  # e.g., jammy
```

### Repository Examples

**1Password CLI:**
```bash
# Works for both (using architecture detection)
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    sudo tee /etc/apt/sources.list.d/1password.list
```

**Tailscale:**
```bash
# Ubuntu 24.04
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | \
    sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg

# Mint 21 (use Ubuntu 22.04 Jammy)
source /etc/os-release
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/${UBUNTU_CODENAME}.noarmor.gpg | \
    sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg
```

---

## Desktop Customization

### GNOME Extensions (Ubuntu)

```bash
# Install GNOME Extensions
sudo apt install gnome-shell-extensions
sudo apt install gnome-tweaks

# Popular extensions:
# - Dash to Dock (pre-installed in Ubuntu)
# - AppIndicator Support
# - User Themes
# - Vitals (system monitor)
```

### Cinnamon Customization (Mint)

**Applets** - Panel widgets:
```bash
# System Settings > Applets
# Add to panel: System Monitor, Weather, Calendar, etc.
```

**Desklets** - Desktop widgets:
```bash
# System Settings > Desklets
# Add to desktop: Clock, Notes, System Info, etc.
```

**Themes:**
```bash
# Install additional themes
sudo apt install mint-themes mint-y-icons mint-x-icons

# Download from Cinnamon Spices:
# https://cinnamon-spices.linuxmint.com/themes
```

**Extensions:**
```bash
# System Settings > Extensions
# Similar to GNOME extensions but for Cinnamon
```

---

## Update Management

### Ubuntu Update Strategy

```bash
# Standard APT updates
sudo apt update
sudo apt upgrade

# Unattended upgrades (automatic security updates)
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

### Mint Update Manager

**Philosophy:** Conservative, user-controlled updates

**Update Levels:**
1. **Level 1** - Low risk (always safe)
2. **Level 2** - Recommended (thoroughly tested)
3. **Level 3** - Safe (tested but less critical)
4. **Level 4** - Unsafe (potentially breaking)
5. **Level 5** - Dangerous (kernel, system updates)

**Usage:**
```bash
# GUI Update Manager
mintupdate-launcher

# CLI equivalent
sudo apt update && sudo apt upgrade

# Mint policy files
/etc/linuxmint/mintupdate.conf
```

---

## Backup & Snapshots

### Ubuntu Backup Options

**Timeshift** (can be installed):
```bash
sudo apt install timeshift
```

**Déjà Dup** (GNOME Backups):
```bash
sudo apt install deja-dup
```

### Mint Backup (Built-in)

**Timeshift** - System snapshots (pre-installed):
```bash
sudo timeshift-gtk          # GUI
sudo timeshift --create     # CLI
```

**Mint Backup Tool** - File backup:
```bash
mintbackup
```

**Recommended Strategy:**
- Timeshift for system state (daily automatic)
- Mint Backup for user files (weekly)
- External backup to NAS or cloud

---

## Performance Comparison

### Resource Usage

| Metric | Ubuntu (GNOME) | Mint (Cinnamon) |
|--------|----------------|-----------------|
| **Idle RAM** | ~1.2-1.5 GB | ~800-1000 MB |
| **CPU (idle)** | 2-5% | 1-3% |
| **Boot Time** | 15-20s | 12-18s |
| **Responsiveness** | Good | Excellent |
| **Animations** | Smooth | Smooth |

**Winner:** Mint (Cinnamon is lighter than GNOME)

### Disk Space

| Component | Ubuntu | Mint |
|-----------|--------|------|
| **Base Install** | ~8 GB | ~6 GB |
| **With Apps** | ~12 GB | ~10 GB |
| **Cache** | Similar | Similar |

---

## Use Case Recommendations

### Choose Ubuntu When:
- ✅ You prefer modern, touch-friendly UI
- ✅ You use GNOME extensions extensively
- ✅ You want latest GNOME features
- ✅ You're running headless server (Ubuntu Server)
- ✅ You need bleeding-edge packages (non-LTS)

### Choose Linux Mint When:
- ✅ You prefer traditional desktop paradigm
- ✅ You want Windows-like familiarity
- ✅ You prioritize system stability (LTS-only)
- ✅ You need full desktop customization
- ✅ You want conservative update management
- ✅ You're new to Linux (user-friendly)

---

## Migration Path

### From Ubuntu to Mint

**Not recommended** (reinstall instead):
- Desktop environments conflict
- Package conflicts likely
- Clean install is safer

**Data Backup:**
```bash
# Backup home directory
rsync -av ~/Documents /backup/
rsync -av ~/Pictures /backup/
rsync -av ~/.config /backup/

# Export package list
dpkg --get-selections > ubuntu-packages.txt

# Install Mint fresh, restore data
```

### From Mint to Ubuntu

Same recommendation: Clean install preferred.

---

## Dotfiles Bootstrap Differences

### Ubuntu Bootstrap

```bash
./scripts/bootstrap/ubuntu-bootstrap.sh
# - Headless optimized
# - Docker-focused
# - No GUI by default
# - Profile: ubuntu-vm
```

### Mint Bootstrap

```bash
./scripts/bootstrap/mint-bootstrap.sh
# - Desktop-focused
# - GUI applications included
# - Cinnamon configuration
# - Profile: mint-desktop
```

### Shared Components

Both use:
- APT package management
- Same base repositories
- 1Password CLI
- Tailscale
- Rclone
- GNU Stow for dotfiles

---

## Testing Matrix

### Device Configuration

| Device | OS | Desktop | Use Case |
|--------|----|---------|---------  |
| **Parallels Ubuntu** | Ubuntu 24.04 | None (headless) | Docker, CLI dev |
| **Parallels Mint** | Mint 21.x | Cinnamon | GUI testing, desktop dev |

### Validation Checklist

**Both Platforms:**
- [ ] Bootstrap script executes successfully
- [ ] Essential packages installed
- [ ] Stow packages deployed
- [ ] SSH keys configured
- [ ] Rclone configured
- [ ] ZSH as default shell

**Mint-Specific:**
- [ ] Cinnamon desktop configured
- [ ] GUI applications installed
- [ ] Timeshift configured
- [ ] Nemo actions work
- [ ] Parallels tools installed

---

## Resources

### Official Documentation

**Ubuntu:**
- [Ubuntu Documentation](https://help.ubuntu.com/)
- [Ubuntu Wiki](https://wiki.ubuntu.com/)
- [Ask Ubuntu](https://askubuntu.com/)

**Linux Mint:**
- [Mint User Guide](https://linuxmint.com/documentation.php)
- [Mint Forums](https://forums.linuxmint.com/)
- [Mint Community](https://community.linuxmint.com/)

### Community

- [Mint Subreddit](https://reddit.com/r/linuxmint)
- [Ubuntu Subreddit](https://reddit.com/r/ubuntu)
- [Cinnamon Spices](https://cinnamon-spices.linuxmint.com/)

---

## Conclusion

**Summary:**
- Linux Mint is excellent for desktop usage with traditional UI
- Ubuntu is better for servers and modern desktop experience
- Both share same package ecosystem (fully compatible)
- Mint offers better out-of-box desktop experience
- Ubuntu offers latest features and faster release cycle

**Dotfiles Strategy:**
- Mint: Full desktop profile (`mint-desktop`)
- Ubuntu: Headless VM profile (`ubuntu-vm`)
- Both work seamlessly with dotfiles system

---

**Created**: 2025-10-27
**Author**: Matteo Cervelli
**Issue**: [#41](https://github.com/matteocervelli/dotfiles/issues/41)
**Status**: FASE 7.3 - Linux Mint Implementation
