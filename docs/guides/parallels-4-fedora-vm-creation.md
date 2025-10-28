# Guide 4: Creating Fedora Development VM in Parallels Desktop

**Purpose**: Create a Fedora Workstation virtual machine optimized for development with Docker, dotfiles, and project workflows.

**Result**: Empty Fedora development VM ready for environment setup with Docker and development tools.

**Next Step**: After completing this guide, proceed to [Guide 5: Fedora Dev Setup](parallels-5-fedora-dev-setup.md) to configure Docker, dotfiles, shared folders, and development environment.

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
- **Apple Silicon Mac** (M1/M2/M3/M4) - Mac Studio recommended

### Host Machine Requirements

| Resource | Minimum | Recommended | Heavy Workloads |
|----------|---------|-------------|-----------------|
| Available RAM | 12 GB | 16 GB | 24 GB+ |
| Free Disk Space | 50 GB | 100 GB | 200 GB+ |
| CPU Cores | 6 cores | 8+ cores | 12+ cores |

**Recommended for Issue #58 validation:**
- CPU: 6 vCPU
- RAM: 12 GB
- Disk: 100 GB

### Downloads

**Fedora Workstation ARM64 ISO**:
- URL: https://fedoraproject.org/workstation/download
- Select: **ARM® aarch64** architecture
- File: `Fedora-Workstation-Live-aarch64-41-*.iso` (~2.3 GB)
- Verify checksum after download: https://fedoraproject.org/security

### Pre-Installation Checklist

- [ ] Parallels Desktop installed and licensed
- [ ] Fedora Workstation ARM64 ISO downloaded and verified
- [ ] At least 100 GB free disk space on Mac
- [ ] SSH key available for remote access (from dotfiles)

---

## Part 1: VM Creation

### Step 1: Launch Parallels and Create New VM

1. Open Parallels Desktop
2. **File** → **New...** (or `⌘N`)
3. Choose **"Install Windows or another OS from a DVD or image file"**
   - DO NOT use "Download" option - we want full control

### Step 2: Select Fedora ISO

1. Click **"Select a file..."**
2. Navigate to Downloads folder
3. Select `Fedora-Workstation-Live-aarch64-41-*.iso`
4. Click **"Continue"**

Parallels should auto-detect: **"Fedora Linux"**

### Step 3: Configure VM Settings

**Before first boot, click the gear icon (⚙️) to configure:**

#### Hardware Tab

**CPU & Memory**:
- **Processors**: 6 vCPU (recommended for development)
  - Mac Studio: 6-8 vCPU (plenty of cores available)
  - MacBook: 4-6 vCPU (balance with macOS)
  - Enable "Adaptive Hypervisor" (improves macOS performance)
  - ✅ **Enable "Nested Virtualization"** (REQUIRED for Docker)

- **Memory**: 12288 MB (12 GB) recommended
  - Minimum: 8192 MB (8 GB)
  - Heavy workloads: 16384 MB (16 GB)
  - Enable "Balloon memory" (dynamic allocation)

**Graphics**:
- **Memory**: 1024 MB (1 GB for smooth desktop)
- **3D Acceleration**: On (better GUI performance)

**Network**:
- **Source**: **Shared Network** (recommended)
  - VM gets IP via NAT (10.211.55.x)
  - Internet through macOS
  - Accessible from macOS via hostname
  - Supports Docker port forwarding
- Alternative: **Bridged Network** (for direct LAN access)

**Hard Disk**:
- **Size**: 100 GB recommended (Issue #58 spec)
  - Minimum: 50 GB
  - Heavy projects: 150-200 GB
- **Type**: Expanding Disk (grows as needed)
- **Location**: SSD for best performance

#### Options Tab

**Sharing**:
- **Share Mac folders with Linux**: Enable (configured in Guide 5)
- Leave specific folders unconfigured for now

**Optimization**:
- **Faster virtual machine**: On
- **Adaptive Hypervisor**: On
- **Tune for**: "Developer / Fast response"

**Security** (Parallels Pro feature):
- **Isolate Linux from Mac**: OFF (we need shared folders)
- **Require password to access**: Optional

### Step 4: Name and Save VM

1. **Name**: `fedora-dev4change` (standard development VM name)
2. **Location**: Default Parallels folder or custom location
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

**IMPORTANT: Simple automatic partitioning recommended for development VM**

1. Click **"Installation Destination"**
2. Select the **100 GB virtual disk** (should be pre-selected)
3. **Storage Configuration**: Select **"Automatic"**
   - ✅ Recommended for development (simple, works well)
   - Creates `/boot`, `/`, and `/home` partitions automatically
   - LVM optional (not required for VMs)
4. **Encryption**: Optional
   - ❌ Not recommended for development VM (adds complexity)
   - Consider for production or sensitive data
5. Click **"Done"**
6. If prompted, click **"Accept Changes"**

**Storage Layout (Automatic)**:
- `/boot/efi`: ~600 MB (boot partition)
- `/`: ~20-30 GB (system files)
- `/home`: Remaining space (projects, Docker volumes, development files)

#### Network & Hostname

1. Click **"Network & Hostname"**
2. **Hostname**: Enter `fedora-dev4change`
3. **Ethernet**: Should be **ON** (Parallels shared network)
4. Verify IP address shows (e.g., `10.211.55.XXX`)
5. Click **"Done"**

#### User Creation

**Create your development account:**

1. Click **"User Creation"**
2. **Full Name**: Matteo Cervelli (or your name)
3. **Username**: `matteocervelli` (your standard username)
4. **Password**: Strong password
5. ✅ **"Make this user administrator"** - CHECK THIS (required for sudo)
6. ✅ **"Require a password to use this account"** - CHECK THIS (security)
7. Click **"Done"**

### Step 5: Root Password (Recommended)

1. Click **"Root Password"**
2. Set a **strong password**
3. ❌ **"Allow root SSH login"** - Keep unchecked (security best practice)
4. Click **"Done"** (may need to click twice if password is simple)

**Why set root password?**
- System recovery
- Package management troubleshooting
- Advanced system configuration

### Step 6: Begin Installation

1. Verify all settings:
   - ✅ Keyboard configured
   - ✅ Time & date set
   - ✅ Installation destination selected (100 GB)
   - ✅ Network connected (10.211.55.x)
   - ✅ User `matteocervelli` created as administrator
   - ✅ Root password set
2. Click **"Begin Installation"**

**Installation takes 10-20 minutes**:
- Installing packages (~1500+ packages)
- Configuring system
- Setting up GNOME desktop
- Installing language packs

### Step 7: Installation Complete

1. Wait for **"Installation Complete"** message
2. Click **"Finish Installation"**
3. Click **"Quit"** to exit installer
4. Shutdown the VM from the GNOME menu (top right → Power Off)

**Important**: Remove the ISO:
1. VM Configuration → Hardware → CD/DVD
2. Set Source to **"None"** or **"Disconnect"**
3. Click **"OK"**

### Step 8: First Boot

1. Start the VM
2. Fedora boots to login screen (~30 seconds)
3. See your account listed: `matteocervelli`

---

## Part 3: Initial Configuration

### Step 1: First Login

1. Click on **matteocervelli** username
2. Enter password
3. Press **Enter**

**GNOME Initial Setup may appear:**

#### Welcome Screen

1. Click **"Start Setup"** or **"Next"**

#### Privacy Settings

1. **Location Services**: OFF (privacy, not needed for dev)
2. **Automatic Problem Reporting**: Optional (helps Fedora improve)
3. Click **"Next"**

#### Online Accounts

1. **Skip** for now (not needed for development VM)
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

# Upgrade all packages (this may take 10-15 minutes)
sudo dnf upgrade -y

# Reboot if kernel was updated (check output)
sudo reboot
```

**Wait 5-15 minutes for updates to complete**

Log back in after reboot.

### Step 3: Install Development Tools (Required for Parallels Tools)

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

**Expected**: Directory should exist with kernel headers matching your running kernel version.

---

## Part 4: Parallels Tools Installation

**Parallels Tools provides**:
- ✅ Shared folders (`/media/psf/`) - CRITICAL for project access
- ✅ Clipboard synchronization (copy/paste between Mac and VM)
- ✅ Dynamic display resolution (window resizing)
- ✅ Improved performance (30-50% faster graphics)
- ✅ Better mouse integration
- ✅ Time synchronization

### Step 1: Insert Parallels Tools ISO

**From Parallels Desktop menu**:
1. **Actions** → **Install Parallels Tools...** (or `⌘K`)
2. Confirm if prompted

Fedora should **auto-mount** the CD-ROM to `/run/media/matteocervelli/Parallels Tools/`

### Step 2: Run Parallels Tools Installer

**From Terminal:**

```bash
# Navigate to CD-ROM mount point
cd /run/media/matteocervelli/Parallels\ Tools/

# Run installer (requires sudo)
sudo ./install

# Or if the above path doesn't exist, try:
cd /media/matteocervelli/Parallels\ Tools/
sudo ./install
```

Installation takes 3-5 minutes:

```
Parallels Tools for Linux installation script
Detecting operating system...
Fedora Linux 41 detected

Installing Parallels Tools...
Building kernel modules...
Installing guest tools...
Starting services...

Installation successful!
```

### Step 3: Verify Installation

#### For ARM64 (Apple Silicon) - FUSE-based Integration

**IMPORTANT**: On ARM64 Macs (M1/M2/M3/M4), Parallels Tools uses **FUSE userspace filesystem** instead of traditional kernel modules. This is normal and correct!

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
# Expected: Directory exists (may be empty until configured in Guide 5)
```

**Expected service status**:
```
● prltools.service - Parallels Tools Agent
     Loaded: loaded
     Active: active (running)
```

#### Important: ARM64 vs x86_64 Differences

**ARM64 (Apple Silicon) - This is your setup:**
- ✅ Uses FUSE userspace filesystem for shared folders (`fuse.prl_fsd`)
- ❌ NO kernel modules (`lsmod | grep prl` will be EMPTY - this is NORMAL!)
- ✅ Full functionality maintained
- ✅ Better performance and stability

**Don't expect**:
- Kernel modules (`lsmod | grep prl` shows nothing - expected behavior)
- .rpm packages (`rpm -qa | grep parallels` shows nothing - expected)
- The installer compiles and installs directly to `/usr/lib/parallels-tools/`

### Step 4: Reboot to Activate

```bash
# Reboot to fully activate Parallels Tools
sudo reboot
```

Log back in after reboot (matteocervelli account).

### Step 5: Verify Clipboard Synchronization

**Test copy/paste between Mac and VM:**

1. **On Mac**: Copy some text (e.g., `Hello from Mac Studio`)
2. **In Fedora VM**: Open Text Editor → Paste (`Ctrl+V`)
3. **Expected**: Text should paste successfully

**If not working**:
- Check Parallels Desktop → VM Configuration → Options → Sharing → "Share clipboard" enabled

### Step 6: Test Dynamic Display Resolution

1. **Resize VM window** on Mac
2. **Expected**: Fedora desktop should resize automatically
3. Try **View → Enter Full Screen** (⌘↩)
4. **Expected**: Desktop adjusts to full screen resolution
5. Exit full screen: **⌘↩** again

---

## Verification

### Quick Verification Checklist

Run these commands in Terminal to verify VM is ready for development setup:

```bash
# 1. Check Fedora version
cat /etc/fedora-release
# Expected: Fedora Linux 41 (Workstation Edition)

# 2. Check Parallels Tools
prltools -v
# Expected: version number (e.g., 19.4.1.xxxx)

# 3. Check Parallels Tools service
systemctl status prltools.service
# Expected: active (running)

# 4. Check network connectivity
ping -c 3 google.com
# Expected: 3 packets transmitted, 3 received

# 5. Check disk space
df -h
# Expected: ~95 GB available in /home

# 6. Check memory
free -h
# Expected: 12 GB total RAM

# 7. Check CPU
nproc
# Expected: 6

# 8. Verify nested virtualization (for Docker)
cat /sys/module/kvm_intel/parameters/nested || cat /sys/module/kvm_amd/parameters/nested
# Expected: Y (enabled) - Note: May not show on ARM64, that's OK

# 9. Verify hostname
hostname
# Expected: fedora-dev4change
```

### From macOS: Test Network Accessibility

```bash
# Find VM IP (from inside VM)
hostname -I
# Note the IP (e.g., 10.211.55.10)

# From macOS terminal, test ping
ping -c 3 fedora-dev4change

# Or via IP
ping -c 3 10.211.55.XXX

# Test SSH (should work after Guide 5 SSH setup)
ssh matteocervelli@fedora-dev4change
```

**If all checks pass, VM is ready for development environment setup!**

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
cd /run/media/matteocervelli/Parallels\ Tools/
sudo ./install
```

### Issue: Parallels Tools ISO Not Mounting

**Symptom**: Can't find `/run/media/matteocervelli/Parallels Tools/`

**Solution**:

```bash
# Check if CD-ROM is detected
lsblk
# Look for sr0 or cdrom device

# Create mount point manually
sudo mkdir -p /mnt/cdrom

# Find CD-ROM device
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

# Check firewalld (Fedora's firewall)
sudo systemctl status firewalld

# If still not working, try Bridged Network:
# VM Configuration → Hardware → Network → Source: Bridged Network
```

### Issue: Slow Performance

**Solution**:

1. **Enable Parallels optimizations**:
   - VM Configuration → Options → Optimization
   - "Faster virtual machine": On
   - "Adaptive Hypervisor": On
   - "Tune for": Developer / Fast response

2. **Allocate more resources**:
   - VM Configuration → Hardware → CPU: 8 vCPU (if Mac Studio)
   - VM Configuration → Hardware → Memory: 16 GB

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

# Check if prl_fs module loaded (x86 only, not needed on ARM64)
lsmod | grep prl

# If still not working, reinstall Parallels Tools
```

---

## Next Steps

### VM is Ready! Now What?

Your Fedora development VM is created with Parallels Tools installed. The VM is ready for complete development environment setup.

**Proceed to**: [Guide 5: Fedora Dev Setup](parallels-5-fedora-dev-setup.md)

**Guide 5 will configure**:
- ✅ SSH configuration for remote access from Mac Studio
- ✅ Parallels shared folders (~/dev/, ~/media/cdn/)
- ✅ Bootstrap installation with dotfiles
- ✅ Docker Engine + Compose v2
- ✅ SELinux and firewalld configuration for Docker
- ✅ systemd auto-update service
- ✅ Remote Docker context (control VM Docker from macOS)
- ✅ Complete testing & verification

### Before Proceeding to Guide 5

Ensure:
- [ ] VM boots successfully to Fedora desktop
- [ ] Parallels Tools working (`prltools -v`)
- [ ] Clipboard synchronization works (copy/paste Mac ↔ VM)
- [ ] Display resolution adjusts when resizing window
- [ ] Network connectivity verified (`ping google.com`)
- [ ] System fully updated (`sudo dnf upgrade`)
- [ ] Sufficient disk space available (`df -h` shows ~95 GB)
- [ ] Account `matteocervelli` has sudo access

### Development VM Best Practices

Before setting up development environment:
- ✅ Take a VM snapshot (Parallels: Actions → Take Snapshot)
  - Name: "Fresh Fedora Install + Parallels Tools"
  - Allows rollback if needed
- ✅ Verify nested virtualization for Docker
- ✅ Ensure Mac has enough resources available
- ✅ Consider VM backup strategy

**Ready?** → [Continue to Guide 5](parallels-5-fedora-dev-setup.md)

---

## Fedora vs Ubuntu: Key Differences for Developers

For developers familiar with Ubuntu:

| Aspect | Ubuntu | Fedora |
|--------|--------|--------|
| Package Manager | `apt` | `dnf` |
| Release Cycle | LTS: 5 years | ~13 months per version |
| Desktop | GNOME (customized) | GNOME (vanilla) |
| Updates | Stable/conservative | Cutting-edge |
| SELinux | Optional (AppArmor default) | Enabled by default |
| Firewall | ufw | firewalld |
| Install command | `sudo apt install` | `sudo dnf install` |
| Search packages | `apt search` | `dnf search` |
| Remove packages | `apt remove` | `dnf remove` |
| Update system | `sudo apt update && sudo apt upgrade` | `sudo dnf upgrade` |

**For development**:
- Fedora provides latest technologies faster (newer kernels, compilers, tools)
- Excellent for testing against newer environments
- Strong Red Hat / RHEL compatibility
- SELinux provides robust security (requires configuration for Docker)

---

**Created**: 2025-10-28
**Last Updated**: 2025-10-28
**Status**: ✅ Complete
**Part of**: FASE 7 - Multi-Platform OS Configurations
**Related**: [Issue #58](https://github.com/matteocervelli/dotfiles/issues/58) - Validate Fedora VM Setup
**Related**: [Issue #57](https://github.com/matteocervelli/dotfiles/issues/57) - Docker Engine Installation for Fedora
