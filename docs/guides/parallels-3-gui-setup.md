# Guide 3: GUI Desktop Environment Setup

**Purpose**: Transform the CLI Ubuntu VM into a full GUI development environment with GNOME desktop, VS Code (native + remote), and essential GUI applications.

**Prerequisites**:
- ✅ Completed [Guide 2: Development VM Setup](parallels-2-dev-setup.md)
- ✅ CLI environment working (SSH, Docker, dotfiles)
- ✅ Minimum 8GB RAM allocated to VM (12-16GB recommended)
- ✅ At least 20GB free disk space

**Result**: Full GNOME desktop with VS Code, development tools, remote desktop access, and seamless Parallels integration.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites Check](#prerequisites-check)
3. [GNOME Desktop Installation](#gnome-desktop-installation)
4. [VS Code Dual Setup](#vs-code-dual-setup)
5. [Essential GUI Applications](#essential-gui-applications)
6. [Remote Desktop Access](#remote-desktop-access)
7. [Parallels Integration](#parallels-integration)
8. [Performance Optimization](#performance-optimization)
9. [Testing & Verification](#testing--verification)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### What You'll Get

**Desktop Environment**:
- ✅ GNOME 46+ desktop (Ubuntu 24.04 default)
- ✅ GDM3 display manager
- ✅ Full GUI environment with window management
- ✅ GNOME extensions and tweaks

**Development Tools**:
- ✅ VS Code native on Linux (with all extensions from macOS)
- ✅ VS Code Remote SSH from macOS
- ✅ Chromium and LibreWolf browsers
- ✅ pgAdmin 4 for PostgreSQL
- ✅ Ollama for local LLMs

**Productivity Apps**:
- ✅ LibreOffice suite
- ✅ 1Password CLI integration
- ✅ ProtonVPN client

**Remote Access**:
- ✅ RDP (xrdp) - Access from Windows/other devices
- ✅ VNC (TigerVNC) - Universal remote access
- ✅ Parallels Remote Desktop - iOS/macOS access

**Parallels Integration**:
- ✅ Seamless mode (Linux apps in macOS dock)
- ✅ Coherence mode (apps integrated in macOS)
- ✅ Shared clipboard
- ✅ Drag & drop files
- ✅ HiDPI/Retina display support

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Mac Studio (Host)                            │
│                                                                 │
│  ┌─────────────────┐        ┌──────────────────┐              │
│  │ VS Code (macOS) │───────▶│ Remote SSH       │              │
│  │ with Remote-SSH │        │ to ubuntu-dev    │              │
│  └─────────────────┘        └──────────────────┘              │
│                                                                 │
│  ┌─────────────────┐        ┌──────────────────┐              │
│  │ Parallels       │───────▶│ Seamless Mode    │              │
│  │ Desktop         │        │ Linux GUI in macOS│             │
│  └─────────────────┘        └──────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                                  │
                    Parallels Integration Layer
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│              Ubuntu VM (ubuntu-dev4change)                      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ GNOME Desktop Environment                                │  │
│  │                                                          │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │  │
│  │  │ VS Code      │  │ Chromium     │  │ LibreOffice  │ │  │
│  │  │ (Native)     │  │ Browser      │  │              │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │  │
│  │                                                          │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │  │
│  │  │ pgAdmin 4    │  │ Ollama       │  │ ProtonVPN    │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Remote Desktop Services                                  │  │
│  │  • xrdp (RDP) on port 3389                              │  │
│  │  • VNC on port 5900                                     │  │
│  │  • Parallels Remote Desktop                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Disk Space Requirements

- **GNOME Desktop**: ~3GB
- **GUI Applications**: ~2-3GB
- **VS Code + Extensions**: ~500MB
- **Ollama + Models**: ~4-8GB (depending on models)
- **Total additional**: ~10-15GB

**Recommendation**: Ensure at least 20GB free space before starting.

### RAM Allocation

- **Minimum**: 8GB (desktop will work but may be slow)
- **Recommended**: 12-16GB (smooth experience)
- **Optimal**: 16-24GB (for heavy development + Ollama)

---

## Prerequisites Check

### From Guide 2

Verify these are complete before proceeding:

```bash
# SSH to VM
ssh ubuntu-dev

# 1. Check ZSH is default shell
echo $SHELL
# Expected: /usr/bin/zsh

# 2. Check Docker is working
docker ps
# Should show running containers or empty list (not error)

# 3. Check dotfiles are stowed
ls -la ~/.zshrc
# Should be a symlink to dotfiles

# 4. Check shared folders
ls -la ~/dev ~/cdn
# Should show Mac Studio folders

# 5. Check free disk space (need at least 20GB)
df -h /
# Check "Avail" column
```

**If all checks pass, proceed!** ✅

---

## GNOME Desktop Installation

### Quick Installation (Automated)

```bash
# SSH to VM
ssh ubuntu-dev

# Navigate to dotfiles
cd ~/dev/projects/dotfiles

# Run GNOME installation script
sudo ./scripts/setup/install-gnome-desktop.sh

# Expected: ~10-15 minutes to complete
# System will reboot automatically when done
```

### Manual Installation (Step-by-Step)

If you prefer to install manually or the script fails:

```bash
# 1. Update package list
sudo apt update

# 2. Install GNOME Desktop (full version)
sudo apt install -y ubuntu-desktop

# 3. Install GNOME customization tools
sudo apt install -y gnome-tweaks gnome-shell-extensions dconf-editor chrome-gnome-shell

# 4. Set GDM3 as display manager (should be default)
sudo systemctl set-default graphical.target

# 5. Reboot to start GUI
sudo reboot
```

### First Boot - GNOME Setup

After reboot, you'll see the GNOME login screen:

1. **Login**: Use your password (matteocervelli)
2. **Welcome Screen**:
   - Language: English
   - Keyboard: Your layout
   - Privacy: Configure as preferred
   - Online Accounts: Skip (configure later)
3. **Desktop**: You should now see the GNOME desktop!

### GNOME Configuration

**Configure dark mode and basic settings:**

```bash
# Enable dark mode
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Disable animations for performance
gsettings set org.gnome.desktop.interface enable-animations false

# Show battery percentage
gsettings set org.gnome.desktop.interface show-battery-percentage true

# Set favorite apps in dock
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'chromium-browser.desktop', 'code.desktop']"
```

**Install GNOME Extensions (Optional)**:

```bash
# Dash to Dock - macOS-like dock
sudo apt install gnome-shell-extension-dashtodock

# Clipboard Indicator
sudo apt install gnome-shell-extension-clipboard-indicator

# Enable extensions
gnome-extensions enable dash-to-dock@micxgx.gmail.com
gnome-extensions enable clipboard-indicator@tudmotu.com
```

✅ **GNOME Desktop installed and configured!**

---

## VS Code Dual Setup

### Part 1: VS Code Native (Linux GUI)

**Install VS Code on Linux:**

```bash
# Method 1: Official Microsoft repository (Recommended)
# Download Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg

# Add VS Code repository
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Update and install
sudo apt update
sudo apt install -y code

# Verify installation
code --version
```

**Sync Extensions from macOS dotfiles:**

```bash
# Navigate to dotfiles
cd ~/dev/projects/dotfiles

# Run VS Code setup script (installs all extensions from dotfiles)
./scripts/setup/setup-vscode-linux.sh

# This will:
# 1. Install all extensions from macOS VS Code
# 2. Sync settings.json
# 3. Sync keybindings.json
# 4. Setup code command in PATH
```

**Launch VS Code:**

```bash
# From terminal
code

# Or from GNOME application menu
# Search for "Visual Studio Code"
```

### Part 2: VS Code Remote SSH (from macOS)

**On macOS - Install Remote-SSH Extension:**

1. Open VS Code on macOS
2. Go to Extensions (⇧⌘X)
3. Search for "Remote - SSH"
4. Install "Remote - SSH" by Microsoft
5. Reload VS Code

**Connect to VM:**

1. Press ⇧⌘P (Command Palette)
2. Type "Remote-SSH: Connect to Host"
3. Select `ubuntu-dev` (from your SSH config)
4. New VS Code window opens connected to VM
5. Install extensions on remote (automatic from settings sync)

**Benefits of Remote SSH:**
- ✅ Edit files on VM from macOS
- ✅ Use macOS keyboard shortcuts
- ✅ Access VM terminal in VS Code
- ✅ Extensions run on VM (faster for heavy tasks)
- ✅ Shared clipboard works seamlessly

### VS Code Settings Sync

**Settings are synced via dotfiles:**

```bash
# Location in dotfiles
~/dev/projects/dotfiles/stow-packages/vscode/.config/Code/User/
  ├── settings.json       # VS Code settings
  ├── keybindings.json    # Keyboard shortcuts
  ├── extensions.txt      # Extension list
  └── snippets/           # Code snippets
```

**Auto-sync on both systems:**
- macOS: `~/.config/Code/User/` (stowed)
- Linux: `~/.config/Code/User/` (stowed)
- Both point to shared dotfiles via symlinks

✅ **VS Code dual setup complete!**

---

## Essential GUI Applications

### Browsers

#### Chromium (Primary Browser)

```bash
sudo apt install -y chromium-browser

# Launch
chromium-browser

# Set as default
xdg-settings set default-web-browser chromium-browser.desktop
```

#### LibreWolf (Privacy-focused Firefox)

```bash
# Add LibreWolf repository
sudo apt install -y extrepo
sudo extrepo enable librewolf

# Update and install
sudo apt update
sudo apt install -y librewolf

# Launch
librewolf
```

### Development Tools

#### pgAdmin 4 (PostgreSQL GUI)

```bash
# Add pgAdmin repository
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'

# Install desktop mode
sudo apt update
sudo apt install -y pgadmin4-desktop

# Launch
pgadmin4
```

#### Ollama (Local LLMs)

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Verify installation
ollama --version

# Pull recommended models
ollama pull llama3.2:3b      # Small, fast model (2GB)
ollama pull codellama:7b     # Code-focused model (4GB)

# Test
ollama run llama3.2:3b "Hello, how are you?"

# Run as service (starts on boot)
sudo systemctl enable ollama
sudo systemctl start ollama
```

### Productivity Applications

#### LibreOffice

```bash
# Full LibreOffice suite
sudo apt install -y libreoffice

# Or individual components
sudo apt install -y libreoffice-writer libreoffice-calc libreoffice-impress
```

#### 1Password CLI (if not already installed)

```bash
# Check if already installed
which op

# If not installed, add repository
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
  sudo tee /etc/apt/sources.list.d/1password.list

sudo apt update
sudo apt install -y 1password-cli

# Verify
op --version
```

#### ProtonVPN

```bash
# Download ProtonVPN .deb package
wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb

# Install
sudo dpkg -i protonvpn-stable-release_1.0.3-3_all.deb
sudo apt update
sudo apt install -y protonvpn

# Launch GUI
protonvpn-app
```

### Quick Install All GUI Apps

```bash
# Run the consolidated script
cd ~/dev/projects/dotfiles
sudo ./scripts/setup/install-gui-apps.sh

# This installs:
# - Chromium & LibreWolf
# - pgAdmin 4
# - Ollama + models
# - LibreOffice
# - 1Password CLI
# - ProtonVPN
```

✅ **All GUI applications installed!**

---

## Remote Desktop Access

### Overview

Enable three types of remote access:
1. **RDP (xrdp)** - Windows Remote Desktop compatible
2. **VNC (TigerVNC)** - Universal remote desktop
3. **Parallels Remote Desktop** - iOS/macOS native access

### RDP Setup (xrdp)

**Install xrdp:**

```bash
sudo apt install -y xrdp

# Configure for GNOME
sudo sed -i 's/^new_cursors=true/new_cursors=false/g' /etc/xrdp/xrdp.ini

# Allow user to start graphical session
sudo adduser xrdp ssl-cert

# Start and enable service
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Check status
sudo systemctl status xrdp
```

**Configure firewall:**

```bash
# Allow RDP port
sudo ufw allow 3389/tcp

# Verify
sudo ufw status
```

**Connect from Windows/macOS:**

1. **Windows**: Use "Remote Desktop Connection"
   - Computer: `ubuntu-dev4change` or `10.211.55.X`
   - Username: `matteocervelli`
   - Password: Your password

2. **macOS**: Use Microsoft Remote Desktop (from App Store)
   - Add PC: `ubuntu-dev4change`
   - User account: `matteocervelli`

### VNC Setup (TigerVNC)

**Install TigerVNC:**

```bash
sudo apt install -y tigervnc-standalone-server tigervnc-common

# Set VNC password
vncpasswd
# Enter password (different from system password for security)

# Create VNC config
mkdir -p ~/.vnc
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec /usr/bin/gnome-session
EOF

chmod +x ~/.vnc/xstartup
```

**Start VNC server:**

```bash
# Start VNC on display :1 (port 5901)
vncserver :1 -geometry 1920x1080 -depth 24

# Stop VNC
vncserver -kill :1

# Create systemd service for auto-start
sudo tee /etc/systemd/system/vncserver@.service > /dev/null << 'EOF'
[Unit]
Description=Start TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=matteocervelli
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service
sudo systemctl start vncserver@1.service
```

**Connect via VNC:**

Use any VNC client:
- **TigerVNC Viewer** (cross-platform)
- **RealVNC Viewer**
- **macOS Screen Sharing** (vnc://ubuntu-dev4change:5901)

**Security: SSH Tunnel (Recommended)**

```bash
# From macOS, create SSH tunnel
ssh -L 5901:localhost:5901 ubuntu-dev

# Then connect VNC client to localhost:5901
# This encrypts VNC traffic through SSH
```

### Parallels Remote Desktop

**Enable in Parallels Desktop:**

1. Open Parallels Desktop
2. Select Ubuntu VM
3. Go to: Configure → Options → Sharing
4. Enable "Access Windows and Mac from iOS"
5. Note the access code

**Connect from iOS/macOS:**

1. Install "Parallels Access" app
2. Sign in with Parallels account
3. Enter access code
4. Access VM from anywhere!

✅ **Remote desktop access configured!**

---

## Parallels Integration

### Seamless Mode

**What is Seamless Mode?**
- Linux apps appear directly in macOS dock
- No VM window visible
- Apps behave like native macOS apps
- Shared clipboard and file access

**Enable Seamless Mode:**

1. In Parallels Desktop menu bar
2. View → Enter Seamless Mode
3. Or press: ⌘⌥ + Enter

**Configure favorite apps in seamless mode:**

1. View → Customize Dock
2. Add: VS Code, Chromium, Terminal, etc.
3. Apps now accessible from macOS dock

### Coherence Mode (Advanced)

**What is Coherence Mode?**
- Similar to Seamless Mode but more integrated
- Linux desktop completely hidden
- Only app windows visible in macOS

**Enable Coherence Mode:**

1. View → Enter Coherence Mode
2. Linux apps fully integrated
3. Use macOS Mission Control with Linux apps

### Shared Features

**Clipboard:**
- Copy/paste between macOS and Linux
- Already enabled by Parallels Tools

**Drag & Drop:**
- Drag files from macOS to Linux apps
- Drag files from Linux to macOS Finder

**Shared Folders:**
- Already configured in Guide 2
- Access via `/media/psf/` in Linux
- Or via `~/dev`, `~/cdn` symlinks

**HiDPI/Retina Support:**

```bash
# Check current scaling
gsettings get org.gnome.desktop.interface scaling-factor

# Set scaling (1 = 100%, 2 = 200%)
gsettings set org.gnome.desktop.interface scaling-factor 2

# Or use GNOME Settings → Displays
```

✅ **Parallels integration complete!**

---

## Performance Optimization

### Parallels VM Settings

**Recommended configuration for GUI:**

1. **Hardware**:
   - CPU: 6-8 cores (4 minimum)
   - RAM: 12-16GB (8GB minimum)
   - Graphics: 512MB-1GB
   - 3D Acceleration: Enabled

2. **Optimization**:
   - Go to: Configure → Hardware → Boot Order
   - Change: Adaptive Hypervisor → Faster virtual machine

3. **Graphics**:
   - Configure → Hardware → Graphics
   - Enable: 3D acceleration
   - Memory: 1024 MB
   - Enable: Vertical sync

### GNOME Optimizations

```bash
# Disable animations (already done in setup)
gsettings set org.gnome.desktop.interface enable-animations false

# Reduce effects
gsettings set org.gnome.desktop.interface enable-animations false

# Disable search providers (faster search)
gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Contacts.desktop', 'org.gnome.Documents.desktop', 'org.gnome.Nautilus.desktop']"

# Reduce Gnome Shell memory usage
gsettings set org.gnome.shell.overrides workspaces-only-on-primary false
```

### Application Optimizations

**VS Code:**

```json
// In settings.json
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.git/objects/**": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/.git": true
  }
}
```

**Chromium:**

```bash
# Launch with performance flags
chromium-browser --disable-gpu-vsync --disable-frame-rate-limit
```

### Monitor Performance

```bash
# System monitor
gnome-system-monitor

# Or terminal tools
htop
btop
```

✅ **Performance optimized!**

---

## Testing & Verification

### GUI Functionality Tests

```bash
# Test 1: Desktop environment
echo "GNOME Session: $GNOME_DESKTOP_SESSION_ID"
# Should show a session ID

# Test 2: Display server
echo $WAYLAND_DISPLAY
# Should show wayland-0 or similar

# Test 3: Applications installed
which code chromium-browser libreoffice pgadmin4 ollama
# All should return paths

# Test 4: VS Code extensions
code --list-extensions | wc -l
# Should show number of installed extensions (> 20 expected)

# Test 5: Remote desktop services
systemctl status xrdp
systemctl status vncserver@1
# Both should show active (running)
```

### Integration Tests

**Test seamless mode:**
1. Enter seamless mode (⌘⌥ + Enter)
2. Launch VS Code from macOS dock
3. Open a file from `~/dev/`
4. Copy text from VS Code to macOS app
5. Drag file from Finder to VS Code

**Test Remote SSH:**
1. From macOS VS Code
2. Connect to `ubuntu-dev` via Remote-SSH
3. Open folder: `~/dev/projects/`
4. Create test file
5. Verify it appears on VM

**Test remote desktop:**
1. Connect via RDP from Windows/macOS
2. Login should show GNOME desktop
3. Launch applications
4. Test clipboard functionality

✅ **All tests passing - GUI environment complete!**

---

## Troubleshooting

### Issue: Black Screen After GNOME Install

**Symptom**: VM boots but shows black screen

**Solution**:

```bash
# Boot to recovery mode (hold Shift during boot)
# Or switch to TTY (Ctrl+Alt+F3)

# Login and reinstall GDM3
sudo apt install --reinstall gdm3

# Set graphical target
sudo systemctl set-default graphical.target

# Reboot
sudo reboot
```

### Issue: VS Code Extensions Not Syncing

**Symptom**: Extensions from macOS not appearing in Linux VS Code

**Solution**:

```bash
# Check if extensions.txt exists
cat ~/dev/projects/dotfiles/stow-packages/vscode/.config/Code/User/extensions.txt

# Manually install all extensions
cd ~/dev/projects/dotfiles
./scripts/setup/sync-vscode-extensions.sh

# Or install specific extension
code --install-extension <extension-id>
```

### Issue: RDP Connection Refused

**Symptom**: Cannot connect via RDP from Windows

**Solution**:

```bash
# Check xrdp service
sudo systemctl status xrdp

# If not running, start it
sudo systemctl start xrdp

# Check firewall
sudo ufw status
sudo ufw allow 3389/tcp

# Check if port is listening
sudo netstat -tlnp | grep 3389
```

### Issue: Slow GUI Performance

**Symptom**: GNOME feels laggy, apps slow to open

**Solution**:

```bash
# 1. Increase VM RAM (Parallels settings)
# Recommended: 12-16GB

# 2. Disable animations
gsettings set org.gnome.desktop.interface enable-animations false

# 3. Check resource usage
htop

# 4. Restart VM
sudo reboot
```

### Issue: Display Resolution Not Detected

**Symptom**: Screen resolution stuck at low res

**Solution**:

```bash
# Check Parallels Tools running
systemctl status prltoolsd

# Reinstall Parallels Tools
sudo /usr/lib/parallels-tools/install

# Manually set resolution
gsettings set org.gnome.desktop.interface scaling-factor 2
```

### Issue: Ollama Models Taking Too Long

**Symptom**: Model download very slow or hanging

**Solution**:

```bash
# Check Ollama service
systemctl status ollama

# Pull model with explicit timeout
OLLAMA_REQUEST_TIMEOUT=300 ollama pull llama3.2:3b

# Check disk space
df -h

# If low on space, remove unused models
ollama rm <model-name>
```

---

## Next Steps

### ✅ Completed
- GNOME desktop installed and configured
- VS Code dual setup (native + remote SSH)
- Essential GUI applications installed
- Remote desktop access enabled
- Parallels integration configured
- Performance optimized

### 🎯 Recommended Next Actions

1. **Customize Your Environment**:
   - Configure GNOME appearance (themes, icons)
   - Install additional GNOME extensions
   - Customize keyboard shortcuts

2. **Install Project-Specific Tools**:
   - Language-specific IDEs
   - Database clients beyond pgAdmin
   - Design tools (GIMP, Inkscape, etc.)

3. **Setup Backup Strategy**:
   - Configure Time Machine equivalent
   - Setup automated snapshots
   - Export VM configuration

4. **Documentation**:
   - Take screenshots of your setup
   - Document custom configurations
   - Create personal usage guide

---

## Summary

You now have a **complete GUI development environment** on Ubuntu VM with:

✅ **Desktop**: GNOME 46+ with dark mode and optimizations
✅ **Development**: VS Code (native + remote), full toolchain
✅ **Browsers**: Chromium and LibreWolf
✅ **Productivity**: LibreOffice, 1Password, ProtonVPN
✅ **AI**: Ollama with local LLMs
✅ **Remote Access**: RDP, VNC, Parallels Remote Desktop
✅ **Integration**: Seamless mode, shared clipboard, drag & drop
✅ **Performance**: Optimized for smooth operation

**Your VM is now a fully-featured development workstation!** 🚀

For questions or issues, refer to the [Troubleshooting](#troubleshooting) section or open an issue in the dotfiles repository.
