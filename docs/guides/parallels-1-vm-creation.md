# Guide 1: Creating Ubuntu VM in Parallels Desktop

**Purpose**: Create a clean Ubuntu 24.04 LTS virtual machine with Parallels Tools integration.

**Result**: Empty Ubuntu VM ready for development environment setup.

**Next Step**: After completing this guide, proceed to [Guide 2: Development VM Setup](parallels-2-dev-setup.md) to configure Docker, dotfiles, and project bindings.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Part 1: VM Creation](#part-1-vm-creation)
3. [Part 2: Ubuntu Installation](#part-2-ubuntu-installation)
4. [Part 3: Parallels Tools Installation](#part-3-parallels-tools-installation)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Next Steps](#next-steps)

---

## Prerequisites

### Required Software

- **Parallels Desktop** 19.0+ (Pro/Business recommended)
- **macOS** Ventura 13.0+ (Sequoia 15.x recommended)
- **Apple Silicon Mac** (M1/M2/M3/M4)

### Host Machine Requirements

| Resource | Minimum | Recommended | Heavy Workloads |
|----------|---------|-------------|-----------------|
| Available RAM | 8 GB | 16 GB | 32 GB+ |
| Free Disk Space | 50 GB | 100 GB | 200 GB+ |
| CPU Cores | 4 cores | 6+ cores | 8+ cores |

### Downloads

**Ubuntu Server 24.04 LTS ARM64 ISO**:
- URL: https://ubuntu.com/download/server/arm
- File: `ubuntu-24.04.3-live-server-arm64.iso` (~2.5 GB)
- Verify SHA256 checksum after download

TO verify the checksum [check this guide](https://ubuntu.com/tutorials/how-to-verify-ubuntu#1-overview).

### Pre-Installation Checklist

- [ ] Parallels Desktop installed and licensed
- [ ] Ubuntu Server ARM64 ISO downloaded
- [ ] At least 50 GB free disk space on Mac
- [ ] SSH key available (for remote access)

---

## Part 1: VM Creation

### Step 1: Launch Parallels and Create New VM

1. Open Parallels Desktop
2. **File** → **New...** (or `⌘N`)
3. Choose **"Install Windows or another OS from a DVD or image file"**
   - DO NOT use "Download Ubuntu" - we want full control

### Step 2: Select Ubuntu ISO

1. Click **"Select a file..."**
2. Navigate to Downloads folder
3. Select `ubuntu-24.04.3-live-server-arm64.iso`
4. Click **"Continue"**

Parallels should auto-detect: **"Ubuntu Linux 24.04"**

### Step 3: Configure VM Settings

**Before first boot, click the gear icon (⚙️) to configure:**

#### Hardware Tab

**CPU & Memory**:
- **Processors**: 4-8 vCPU
  - Development: 4 vCPU
  - Docker workloads: 6-8 vCPU
  - Enable "Adaptive Hypervisor" (improves macOS performance)
  - Enable "Nested Virtualization" (if needed for Docker-in-Docker)

- **Memory**: 8192 MB (8 GB) minimum
  - Heavy workloads: 16384 MB (16 GB)
  - Enable "Balloon memory" (dynamic allocation)

**Graphics**:
- **Memory**: 512 MB (minimal for headless)
- **3D Acceleration**: On

**Network**:
- **Source**: **Shared Network** (recommended)
  - VM gets IP via NAT
  - Internet through macOS
  - Accessible from macOS via hostname
- Alternative: **Bridged Network** (for direct LAN access)

**Hard Disk**:
- **Size**: 50 GB minimum, 100 GB recommended
- **Type**: Expanding Disk (grows as needed)
- **Location**: SSD for best performance

#### Options Tab

**Sharing**:
- **Share Mac folders with Linux**: Enable (configured later in Guide 2)
- Leave specific folders unconfigured for now

**Optimization**:
- **Faster virtual machine**: On
- **Adaptive Hypervisor**: On

### Step 4: Name and Save VM

1. **Name**: `ubuntu-vm` (or your preferred name)
2. **Location**: Default Parallels folder
3. Click **"Create"**

---

## Part 2: Ubuntu Installation

### Step 1: Start VM and Boot Installer

1. Click Play button (▶️)
2. Ubuntu installer boots (GRUB menu)
3. Select **"Try or Install Ubuntu Server"**

### Step 2: Language Selection

1. Select **English** (or your preference)
2. Press Enter

### Step 3: Installer Update

If prompted:
- Choose **"Update to the new installer"** (recommended)

### Step 4: Keyboard Configuration

1. **Layout**: English (US)
2. **Variant**: English (US, intl., with dead keys)
3. **Done** → Enter

### Step 5: Installation Type

**Choose based on your needs:**

#### Option A: Ubuntu Server (base, NOT minimized)

- Headless server (no GUI initially)
- Can add desktop environment later if needed
- Lighter resource usage (~2-4 GB RAM)
- Good for: Docker-only, remote development

#### Option B: Ubuntu Server (minimized)

- Most minimal installation
- Cannot add GUI later without reinstalling
- Only for pure server workloads

#### Recommendation for Development with Mac Studio

- Choose **"Ubuntu Server"** (base, not minimized)
- Add desktop environment in Guide 2 if you want:
  - VS Code GUI on Linux for compatibility testing
  - Browser testing on actual Linux
  - Visual debugging on Linux
  - Full Linux desktop experience

#### Resource Impact of GUI

- RAM: +2 GB (negligible on Mac Studio)
- Disk: +2 GB
- Performance: Minimal impact

Select your choice and press **Done** → Enter
      
### Step 6: Network Configuration

Parallels Shared Network auto-configures:

```
enp0s5: eth
  DHCPv4: 10.211.55.XXX/24
  Gateway: 10.211.55.1
```

**No changes needed** - default is correct.

**Done** → Enter

### Step 7: Proxy Configuration

- Leave blank unless behind corporate proxy
- **Done** → Enter

### Step 8: Mirror Configuration

- Default: `http://ports.ubuntu.com/ubuntu-ports`
- **Done** → Enter

### Step 9: Storage Configuration

**Guided storage** (recommended):

1. **Use entire disk**: Selected
2. **Set up as LVM group**: Unchecked (simpler for VMs)
3. Choose the 50 GB virtual disk
4. **Done** → Enter

Storage summary shows:
- `DISK vda` (50 GB)
  - Partition 1: 1 MB (BIOS boot)
  - Partition 2: 2 GB (ext4, `/boot`)
  - Partition 3: ~48 GB (ext4, `/`)

**Done** → **Continue** (formats disk)

### Step 10: Profile Setup

- **Your name**: Your full name
- **Server's name**: `ubuntu-dev4change` (hostname)
- **Username**: `matteocervelli` (or your username)
- **Password**: Strong password
- **Confirm password**: Re-enter

**Done** → Enter

### Step 11: SSH Setup

**IMPORTANT: Enable SSH**

- **Install OpenSSH server**: ✅ **[X] Selected** (spacebar to toggle)
  - REQUIRED for remote access and Docker context
- **Import SSH identity**: Optional
  - Can import from GitHub/Launchpad
  - Or add keys manually later

**Done** → Enter

### Step 12: Featured Server Snaps

**Skip all** (press **Done** without selecting):
- DO NOT install Docker via snap
- We'll install Docker properly in Guide 2
- Keeps installation minimal

**Done** → Enter

### Step 13: Installation Progress

Wait 5-15 minutes for:
1. Downloading and installing packages
2. Installing kernel
3. Configuring system
4. Installing bootloader

**Wait for**: **"Install complete!"**

### Step 14: Reboot

1. Select **"Reboot Now"**
2. Installer unmounts ISO automatically
3. VM restarts

**If VM hangs**:
- Actions → Stop → Force Stop
- VM Configuration → Hardware → CD/DVD → Disconnect
- Start VM again

### Step 15: First Login

Ubuntu login prompt appears:

```
ubuntu-vm login: matteocervelli
Password: ********
```

Expected prompt:
```
matteocervelli@ubuntu-vm:~$
```

**You're in!** 🎉

---

## Part 3: Parallels Tools Installation

**Parallels Tools provides**:
- ✅ Shared folders (`/media/psf/`)
- ✅ Clipboard synchronization
- ✅ Dynamic display resolution
- ✅ Improved performance (30-50% faster)
- ✅ Better mouse integration
- ✅ Time synchronization

### Step 1: Update System Packages

**CRITICAL: Update before installing Parallels Tools**

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Reboot if kernel updated
sudo reboot
```

Log back in after reboot.

### Step 2: Install Build Dependencies

```bash
# Install required packages
sudo apt install -y \
    dkms \
    build-essential \
    linux-headers-$(uname -r) \
    libelf-dev \
    gcc \
    make

# Verify kernel headers installed
ls /lib/modules/$(uname -r)/build
```

**Expected**: Should list files (not "No such file or directory")

### Step 3: Insert Parallels Tools ISO

**From Parallels Desktop menu**:
1. **Actions** → **Install Parallels Tools...** (or `⌘K`)
2. Confirm if prompted

### Step 4: Mount Parallels Tools ISO

```bash
# Create mount point
sudo mkdir -p /mnt/cdrom

# Mount CD-ROM
sudo mount /dev/cdrom /mnt/cdrom

# Verify mount
ls /mnt/cdrom
```

**Expected output**:
```
install  install-gui  installer  kmods  tools  version
```

### Step 5: Run Parallels Tools Installer

```bash
# Change to CD-ROM directory
cd /mnt/cdrom

# Run installer
sudo ./install
```

Installation takes 2-5 minutes:

```
Parallels Tools installation script
Detecting your operating system...
Ubuntu 24.04 LTS detected

Installing Parallels Tools for Linux...
Building kernel modules...
Installing parallels-tools-X.X.X...
Starting Parallels Tools services...

Installation successful!
```

### Step 6: Verify Installation

```bash
# Check version
prltools -v

# Check service status
systemctl status parallels-tools

# List installed packages
dpkg -l | grep parallels
```

**Expected**:
```
Parallels Tools X.X.X (build XXXXX)
```

### Step 7: Unmount and Reboot

```bash
# Leave CD-ROM directory
cd ~

# Unmount CD-ROM
sudo umount /mnt/cdrom

# Reboot to activate Parallels Tools
sudo reboot
```

### Step 8: Verify Shared Folders

After reboot:

```bash
# Check shared folders
ls -la /media/psf/

# Should be empty or show default shares
# We'll configure specific folders in Guide 2
```

---

## Verification

### Quick Verification Checklist

Run these commands to verify VM is ready:

```bash
# 1. Check Ubuntu version
lsb_release -a

# 2. Check Parallels Tools
prltools -v

# 3. Check network
ping -c 3 google.com

# 4. Check SSH service
systemctl status ssh

# 5. Check available disk space
df -h

# 6. Check memory
free -h

# 7. Check CPU
nproc
```

### From macOS: Test SSH Access

```bash
# Find VM IP (from inside VM)
hostname -I

# From macOS terminal, test SSH
ssh matteocervelli@ubuntu-vm

# Or via IP
ssh matteocervelli@10.211.55.XXX
```

**If SSH works, VM is ready for development setup!**

---

## Troubleshooting

### Issue: Parallels Tools Installation Fails

**Symptom**: `./install` fails with "Unable to build kernel modules"

**Solution**:

```bash
# Ensure kernel headers match running kernel
uname -r
ls /lib/modules/$(uname -r)/build

# If missing, install headers
sudo apt update
sudo apt install -y linux-headers-$(uname -r)

# Try installation again
cd /mnt/cdrom
sudo ./install
```

### Issue: Network Not Working

**Symptom**: `ping google.com` fails

**Solution**:

```bash
# Check network interface
ip addr show

# Restart networking
sudo systemctl restart systemd-networkd

# Or reconfigure manually
sudo netplan apply
```

**If Shared Network not working**:
1. VM Configuration → Hardware → Network
2. Try switching to "Bridged Network"
3. Restart VM

### Issue: SSH Connection Refused

**Symptom**: `ssh: connect to host ubuntu-vm port 22: Connection refused`

**Solution**:

```bash
# In VM - check if SSH running
sudo systemctl status ssh

# Start SSH service
sudo systemctl start ssh

# Enable SSH on boot
sudo systemctl enable ssh

# Check SSH is listening
sudo ss -tlnp | grep :22
```

### Issue: VM Performance is Slow

**Solution**:

1. **Increase VM resources**:
   - VM Configuration → Hardware
   - More vCPU cores (4-8)
   - More RAM (8-16 GB)

2. **Enable performance optimizations**:
   - VM Configuration → Options → Optimization
   - "Faster virtual machine": On
   - "Adaptive Hypervisor": On

3. **Check macOS resources**:
   - Close other applications
   - Ensure sufficient Mac RAM available

---

## Next Steps

### VM is Ready! Now What?

Your Ubuntu VM is created with Parallels Tools installed. The VM is ready for development environment setup.

**Proceed to**: [Guide 2: Development VM Setup](parallels-2-dev-setup.md)

**Guide 2 will configure**:
- ✅ Parallels shared folders (~/dev/, ~/media/cdn/)
- ✅ Docker Engine + Compose
- ✅ Dotfiles integration
- ✅ R2 assets workflow
- ✅ Project bindings from Mac Studio
- ✅ Remote Docker context
- ✅ Performance optimization
- ✅ Complete testing & verification

### Before Proceeding to Guide 2

Ensure:
- [ ] VM boots successfully
- [ ] Parallels Tools working (`prltools -v`)
- [ ] SSH access from macOS works
- [ ] Network connectivity verified
- [ ] Sufficient disk space available

**Ready?** → [Continue to Guide 2](parallels-2-dev-setup.md)

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Status**: ✅ Complete
**Part of**: FASE 4 - VM Ubuntu Setup
