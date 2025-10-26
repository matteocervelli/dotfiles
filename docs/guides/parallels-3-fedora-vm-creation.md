# Guide 3: Creating Fedora VM in Parallels Desktop for Kids Learning

**Purpose**: Create a clean Fedora Workstation virtual machine with Parallels Tools integration, optimized for a safe kids' learning environment.

**Result**: Empty Fedora VM ready for educational software and safe browsing setup.

**Next Step**: After completing this guide, proceed to [Guide 4: Fedora Kids Learning Setup](parallels-4-fedora-kids-setup.md) to configure educational software, parental controls, and simplified environment.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: VM Creation](#part-1-vm-creation)
3. [Part 2: Fedora Installation](#part-2-fedora-installation)
4. [Part 3: Initial Configuration](#part-3-initial-configuration)
5. [Part 4: Parallels Tools Installation](#part-4-parallels-tools-installation)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)
8. [Next Steps](#next-steps)

---

## Prerequisites

### Required Software

- **Parallels Desktop** 19.0+ (Pro/Business recommended)
- **macOS** Ventura 13.0+ (Sequoia 15.x recommended)
- **Apple Silicon Mac** (M1/M2/M3/M4) - MacBook for kids' usage

### Host Machine Requirements

| Resource | Minimum | Recommended | Notes |
|----------|---------|-------------|-------|
| Available RAM | 8 GB | 12 GB | MacBook should have 16GB+ total |
| Free Disk Space | 40 GB | 60 GB | For system + educational software |
| CPU Cores | 4 cores | 4-6 cores | Balance with macOS performance |

### Downloads

**Fedora Workstation ARM64 ISO**:
- URL: https://fedoraproject.org/workstation/download
- Select: **ARM® aarch64** architecture
- File: `Fedora-Workstation-Live-aarch64-40-*.iso` (~2.3 GB)
- Verify checksum after download: https://fedoraproject.org/security

### Pre-Installation Checklist

- [ ] Parallels Desktop installed and licensed
- [ ] Fedora Workstation ARM64 ISO downloaded
- [ ] At least 40 GB free disk space on Mac
- [ ] Considered data plan for kids' environment (supervised access)

---

## Part 1: VM Creation

### Step 1: Launch Parallels and Create New VM

1. Open Parallels Desktop
2. **File** → **New...** (or `⌘N`)
3. Choose **"Install Windows or another OS from a DVD or image file"**

### Step 2: Select Fedora ISO

1. Click **"Select a file..."**
2. Navigate to Downloads folder
3. Select `Fedora-Workstation-Live-aarch64-40-*.iso`
4. Click **"Continue"**

Parallels should auto-detect: **"Fedora Linux"**

### Step 3: Configure VM Settings

**Before first boot, click the gear icon (⚙️) to configure:**

#### Hardware Tab

**CPU & Memory**:
- **Processors**: 4 vCPU (kids' VM - balanced)
  - Enable "Adaptive Hypervisor" (improves macOS performance)
  - Do NOT enable "Nested Virtualization" (unnecessary for kids)

- **Memory**: 4096 MB (4 GB) for learning
  - 6144 MB (6 GB) if running heavy educational apps
  - Enable "Balloon memory" (dynamic allocation)

**Graphics**:
- **Memory**: 1024 MB (1 GB for smooth desktop)
- **3D Acceleration**: On (better GUI performance)

**Network**:
- **Source**: **Shared Network** (recommended)
  - VM gets IP via NAT
  - Internet through macOS (easier parental control)
  - Accessible from macOS via hostname
- **Note**: Easier to monitor and filter at Mac level

**Hard Disk**:
- **Size**: 40 GB minimum, 50 GB recommended
- **Type**: Expanding Disk (grows as needed)
- **Location**: SSD for best performance

#### Options Tab

**Sharing**:
- **Share Mac folders with Linux**: Enable (for parent-approved content)
- Leave specific folders unconfigured for now (setup in Guide 4)

**Optimization**:
- **Faster virtual machine**: On
- **Adaptive Hypervisor**: On

**Security** (Parallels Pro feature):
- **Isolate Linux from Mac**: Optional (extra safety layer)
- **Restrict Network Access**: Configure in Guide 4

### Step 4: Name and Save VM

1. **Name**: `fedora-kids` (or child's name: `fedora-sofia`)
2. **Location**: Default Parallels folder
3. Click **"Create"**

---

## Part 2: Fedora Installation

### Step 1: Start VM and Boot Installer

1. Click Play button (▶️)
2. Fedora Live Desktop boots
3. Wait for GNOME desktop to load (~1-2 minutes)

**Expected**: You'll see Fedora Workstation desktop with "Try Fedora" or "Install to Hard Drive" option

### Step 2: Start Installation

1. Double-click **"Install to Hard Drive"** icon on desktop
2. Fedora installer (Anaconda) launches

### Step 3: Language Selection

1. Select **English (United States)** (or your preferred language)
2. Click **"Continue"**

### Step 4: Installation Summary

You'll see the main installation hub with several options:

#### Keyboard Layout
1. Click **"Keyboard"**
2. Select **English (US)** (or your preference)
3. Click **"Done"**

#### Time & Date
1. Click **"Time & Date"**
2. Select your **Region** and **City**
3. Enable **"Network Time"** (automatic sync)
4. Click **"Done"**

#### Installation Destination (Disk Partitioning)

**IMPORTANT: Simple automatic partitioning for kids' VM**

1. Click **"Installation Destination"**
2. Select the **40-50 GB virtual disk** (should be pre-selected)
3. **Storage Configuration**: Select **"Automatic"**
   - ✅ Recommended for kids' VM (simple, works well)
   - Creates `/boot`, `/`, and `/home` partitions automatically
4. **Encryption**: Optional
   - ❌ Not recommended for kids' VM (adds complexity)
   - Password recovery can be difficult
5. Click **"Done"**
6. If prompted, click **"Accept Changes"**

**Storage Layout (Automatic)**:
- `/boot/efi`: ~600 MB (boot partition)
- `/`: ~15-20 GB (system files)
- `/home`: Remaining space (user files, educational content)

#### Network & Hostname

1. Click **"Network & Hostname"**
2. **Hostname**: Enter `fedora-kids` (or `fedora-sofia`)
3. **Ethernet**: Should be **ON** (Parallels shared network)
4. Verify IP address shows (e.g., `10.211.55.XXX`)
5. Click **"Done"**

#### User Creation (IMPORTANT for kids' environment)

**Create Parent Account First:**

1. Click **"User Creation"**
2. **Full Name**: Your name (parent/guardian)
3. **Username**: `parent` or your username
4. **Password**: Strong password (parents only)
5. ✅ **"Make this user administrator"** - CHECK THIS
6. ❌ **"Require a password to use this account"** - REQUIRED
7. Click **"Done"**

**Note**: We'll create the kids' restricted account in Guide 4

### Step 5: Root Password (Optional but Recommended)

1. Click **"Root Password"**
2. Set a **strong password** (parents only)
3. ❌ **"Allow root SSH login"** - Keep unchecked (security)
4. Click **"Done"** (may need to click twice if password is simple)

**Why set root password?**
- System recovery
- Package management
- Parental controls configuration

### Step 6: Begin Installation

1. Verify all settings:
   - ✅ Keyboard configured
   - ✅ Time & date set
   - ✅ Installation destination selected
   - ✅ Network connected
   - ✅ Parent user created
   - ✅ Root password set (optional)
2. Click **"Begin Installation"**

**Installation takes 10-20 minutes**:
- Installing packages
- Configuring system
- Setting up GNOME desktop

### Step 7: Installation Complete

1. Wait for **"Installation Complete"** message
2. Click **"Finish Installation"**
3. Click **"Quit"** to exit installer
4. Shutdown the VM from the GNOME menu

**Important**: Remove the ISO:
1. VM Configuration → Hardware → CD/DVD
2. Set Source to **"None"** or **"Disconnect"**
3. Click **"OK"**

### Step 8: First Boot

1. Start the VM
2. Fedora boots to login screen (~30 seconds)
3. See parent account listed

---

## Part 3: Initial Configuration

### Step 1: First Login (Parent Account)

1. Click on **parent** username
2. Enter password
3. Press **Enter**

**GNOME Initial Setup may appear:**

#### Welcome Screen
1. Click **"Start Setup"** or **"Next"**

#### Privacy Settings
1. **Location Services**: OFF (privacy for kids)
2. **Automatic Problem Reporting**: Optional (helps Fedora improve)
3. Click **"Next"**

#### Online Accounts
1. **Skip** for now (configure later if needed)
2. Click **"Skip"**

#### Ready to Go
1. Click **"Start Using Fedora"**

### Step 2: System Update (CRITICAL)

**ALWAYS update before installing Parallels Tools!**

Open Terminal:
- Press **Super** (Windows key) → type "terminal" → Enter
- Or: Activities → Terminal

```bash
# Update package repositories
sudo dnf check-update

# Upgrade all packages
sudo dnf upgrade -y

# Reboot if kernel was updated
sudo reboot
```

**Wait 5-15 minutes for updates to complete**

Log back in after reboot.

### Step 3: Install Development Tools

**Required for Parallels Tools compilation:**

```bash
# Install required build tools
sudo dnf install -y \
    kernel-devel \
    kernel-headers \
    dkms \
    gcc \
    make \
    perl \
    bzip2 \
    tar \
    elfutils-libelf-devel

# Verify kernel headers match running kernel
uname -r
ls /usr/src/kernels/$(uname -r)
```

**Expected**: Directory should exist with kernel headers

---

## Part 4: Parallels Tools Installation

**Parallels Tools provides**:
- ✅ Shared folders (`/media/psf/`)
- ✅ Clipboard synchronization (copy/paste between Mac and VM)
- ✅ Dynamic display resolution (window resizing)
- ✅ Improved performance (30-50% faster graphics)
- ✅ Better mouse integration
- ✅ Time synchronization

### Step 1: Insert Parallels Tools ISO

**From Parallels Desktop menu**:
1. **Actions** → **Install Parallels Tools...** (or `⌘K`)
2. Confirm if prompted

Fedora should **auto-mount** the CD-ROM to `/run/media/parent/Parallels Tools/`

### Step 2: Run Parallels Tools Installer

**From Terminal:**

```bash
# Navigate to CD-ROM mount point
cd /run/media/parent/Parallels\ Tools/

# Run installer (requires sudo)
sudo ./install

# Or if the above path doesn't exist, try:
cd /media/parent/Parallels\ Tools/
sudo ./install
```

Installation takes 3-5 minutes:

```
Parallels Tools for Linux installation script
Detecting operating system...
Fedora Linux 40 detected

Installing Parallels Tools...
Building kernel modules...
Installing guest tools...
Starting services...

Installation successful!
```

### Step 3: Verify Installation

#### For ARM64 (Apple Silicon) - FUSE-based Integration

**IMPORTANT**: On ARM64 Macs, Parallels Tools uses **FUSE userspace filesystem** instead of traditional kernel modules.

```bash
# 1. Check Parallels Tools version
cat /usr/lib/parallels-tools/version
# Expected: 19.x.x.xxxxx (or newer)

# 2. Check service status
systemctl status prltools.service
# Expected: active (running)

# 3. Verify binaries installed
ls -la /usr/bin/prl*
# Expected: prltools, prlsrvctl, etc.

# 4. Test shared folders mount point
ls -la /media/psf/
# Expected: Directory exists (may be empty until configured)
```

**Expected service status**:
```
● prltools.service - Parallels Tools Agent
     Loaded: loaded
     Active: active (running)
```

#### Important: ARM64 vs x86_64 Differences

**ARM64 (Apple Silicon)**:
- ✅ Uses FUSE userspace filesystem for shared folders
- ❌ NO kernel modules (this is NORMAL and CORRECT!)
- ✅ Full functionality maintained

**Don't expect**:
- Kernel modules (`lsmod | grep prl` will be empty - this is OK!)
- .deb or .rpm packages (`rpm -qa | grep parallels` shows nothing - expected)

### Step 4: Reboot to Activate

```bash
# Reboot to fully activate Parallels Tools
sudo reboot
```

Log back in after reboot (parent account).

### Step 5: Verify Clipboard Synchronization

**Test copy/paste between Mac and VM:**

1. **On Mac**: Copy some text (e.g., `Hello from Mac`)
2. **In Fedora VM**: Open Text Editor → Paste (`Ctrl+V`)
3. **Expected**: Text should paste successfully

**If not working**: Check Parallels Desktop → VM Configuration → Options → Sharing → Share clipboard

### Step 6: Test Dynamic Display Resolution

1. **Resize VM window** on Mac
2. **Expected**: Fedora desktop should resize automatically
3. Try **View → Enter Full Screen** (⌘↩)
4. **Expected**: Desktop adjusts to full screen

---

## Verification

### Quick Verification Checklist

Run these commands in Terminal to verify VM is ready:

```bash
# 1. Check Fedora version
cat /etc/fedora-release

# 2. Check Parallels Tools
prltools -v

# 3. Check Parallels Tools service
systemctl status prltools.service

# 4. Check network connectivity
ping -c 3 google.com

# 5. Check disk space
df -h

# 6. Check memory
free -h

# 7. Check CPU
nproc

# 8. Verify clipboard (copy text from Mac, then):
# Ctrl+V in Text Editor should paste Mac clipboard
```

### From macOS: Test Accessibility

```bash
# Find VM IP (from inside VM)
hostname -I

# From macOS terminal, test ping
ping -c 3 fedora-kids

# Or via IP
ping -c 3 10.211.55.XXX
```

**If all checks pass, VM is ready for kids' learning setup!**

---

## Troubleshooting

### Issue: Parallels Tools Installation Fails

**Symptom**: `./install` fails with "Unable to build kernel modules"

**Solution**:

```bash
# Ensure kernel headers match running kernel
uname -r
sudo dnf install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r)

# Reinstall build tools
sudo dnf install -y gcc make perl dkms

# Try installation again
cd /run/media/parent/Parallels\ Tools/
sudo ./install
```

### Issue: Parallels Tools ISO Not Mounting

**Symptom**: Can't find `/run/media/parent/Parallels Tools/`

**Solution**:

```bash
# Check if CD-ROM is detected
lsblk

# Create mount point manually
sudo mkdir -p /mnt/cdrom

# Find CD-ROM device (usually /dev/sr0 or /dev/cdrom)
ls -la /dev/cdrom

# Mount manually
sudo mount /dev/cdrom /mnt/cdrom

# Navigate and install
cd /mnt/cdrom
sudo ./install
```

### Issue: Network Not Working

**Symptom**: `ping google.com` fails

**Solution**:

```bash
# Check network interface status
ip addr show

# Check NetworkManager service
systemctl status NetworkManager

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Try switching to Bridged Network in Parallels:
# VM Configuration → Hardware → Network → Source: Bridged Network
```

### Issue: Slow Performance

**Solution**:

1. **Enable Parallels optimizations**:
   - VM Configuration → Options → Optimization
   - "Faster virtual machine": On
   - "Adaptive Hypervisor": On

2. **Allocate more resources**:
   - VM Configuration → Hardware → CPU: 4-6 vCPU
   - VM Configuration → Hardware → Memory: 6 GB

3. **Disable unnecessary GNOME extensions**:
   - Extensions app → Disable unused extensions

4. **Reduce GNOME animations**:
   ```bash
   # Disable animations for better performance
   gsettings set org.gnome.desktop.interface enable-animations false
   ```

### Issue: Display Resolution Not Adjusting

**Symptom**: Desktop doesn't resize with VM window

**Solution**:

```bash
# Restart Parallels Tools service
sudo systemctl restart prltools.service

# Check if service is running
systemctl status prltools.service

# If still not working, reinstall Parallels Tools
```

---

## Next Steps

### Automation Option: Bootstrap Script

For **automated development environment setup** (not kids' learning), you can use the Fedora bootstrap script:

```bash
# Clone dotfiles (if not already present)
git clone https://github.com/matteocervelli/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run bootstrap script (automated setup)
./scripts/bootstrap/fedora-bootstrap.sh

# Or with full package installation
./scripts/bootstrap/fedora-bootstrap.sh --with-packages

# Preview without changes
./scripts/bootstrap/fedora-bootstrap.sh --dry-run
```

**The bootstrap script automates:**
- ✅ System updates (dnf upgrade)
- ✅ Development tools installation (@development-tools group)
- ✅ Dotfiles core dependencies (1Password CLI, rclone, yq, ImageMagick)
- ✅ GNU Stow package deployment (zsh, git, ssh)
- ✅ ZSH setup as default shell
- ✅ Optional: Full package installation (115+ packages)
- ✅ SELinux and firewalld checks

**Use Cases:**
- **`fedora-dev` profile**: Full development environment (Python, Node, Docker, PostgreSQL, etc.)
- **`kids-safe` profile**: See Guide 4 for manual educational setup

**Bootstrap Options:**
```bash
--with-packages      # Install all packages from system/fedora/packages.txt
--essential-only     # Quick setup (stow, git, 1password, rclone only)
--dry-run            # Preview what would be installed
--skip-repos         # Use default repos only (no 3rd-party)
```

**See also:**
- [BOOTSTRAP-STRATEGIES.md](../os-configurations/BOOTSTRAP-STRATEGIES.md#fedorarhel-bootstrap-strategy) - Detailed Fedora bootstrap documentation
- [Issue #40](https://github.com/matteocervelli/dotfiles/issues/40) - Fedora Bootstrap implementation

---

### VM is Ready! Now What?

Your Fedora VM is created with Parallels Tools installed. The VM is ready for educational software and kids' learning environment setup.

**Proceed to**: [Guide 4: Fedora Kids Learning Setup](parallels-4-fedora-kids-setup.md)

**Guide 4 will configure**:
- ✅ Kids' restricted user account with parental controls
- ✅ Educational software packages (educational games, learning apps)
- ✅ Safe browsing with parental controls
- ✅ Simplified GNOME desktop environment
- ✅ Shared folders for parent-approved content
- ✅ Time limits and usage restrictions
- ✅ Content filtering and monitoring

### Before Proceeding to Guide 4

Ensure:
- [ ] VM boots successfully to Fedora desktop
- [ ] Parallels Tools working (`prltools -v`)
- [ ] Clipboard synchronization works (copy/paste Mac ↔ VM)
- [ ] Display resolution adjusts when resizing window
- [ ] Network connectivity verified (`ping google.com`)
- [ ] System fully updated (`sudo dnf upgrade`)
- [ ] Sufficient disk space available (`df -h`)
- [ ] Parent account configured and accessible

### Safety Reminders

Before setting up for kids:
- ✅ Parent account is administrator (sudo access)
- ✅ Root password is set and secure
- ✅ Network access works (for parental control configuration)
- ✅ VM can be easily paused/suspended from Mac
- ✅ Consider taking a VM snapshot before kids start using it

**Ready?** → [Continue to Guide 4](parallels-4-fedora-kids-setup.md)

---

## Fedora vs Ubuntu: Key Differences

For parents familiar with Ubuntu:

| Aspect | Ubuntu | Fedora |
|--------|--------|--------|
| Package Manager | `apt` | `dnf` |
| Release Cycle | LTS: 5 years | 13 months per version |
| Desktop | GNOME (customized) | GNOME (vanilla) |
| Updates | Stable/conservative | Cutting-edge |
| Command | `sudo apt install` | `sudo dnf install` |
| Search packages | `apt search` | `dnf search` |
| Remove packages | `apt remove` | `dnf remove` |

**For kids' learning**: Both are excellent choices. Fedora provides latest GNOME desktop with modern features.

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Status**: ✅ Complete
**Part of**: FASE 7 - Multi-Platform OS Configurations
**Related**: [Issue #46](https://github.com/matteocervelli/dotfiles/issues/46) - Kids' Fedora VM Educational Profile
