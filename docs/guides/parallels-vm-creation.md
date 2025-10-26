# Creating Ubuntu 24.04 LTS VM in Parallels Desktop

Complete guide for creating a production-ready Ubuntu 24.04 LTS virtual machine in Parallels Desktop from a fresh ISO image, with full Parallels Tools integration and optimization.

**Target Environment**: Ubuntu 24.04 LTS (Noble Numbat) Server ARM64 on Parallels Desktop (Apple Silicon Mac)

**Related Documentation**:
- [Docker on Ubuntu Setup](docker-ubuntu-setup.md) - Install Docker after VM creation
- [TASK.md](../TASK.md#73-parallels-integration--testing-issue-23) - Issue #23 tracking

---

## Table of Contents

1. [Why Manual ISO Installation?](#why-manual-iso-installation)
2. [Prerequisites](#prerequisites)
3. [Part 1: VM Creation in Parallels](#part-1-vm-creation-in-parallels)
4. [Part 2: Ubuntu Installation](#part-2-ubuntu-installation)
5. [Part 3: Parallels Tools Installation](#part-3-parallels-tools-installation)
6. [Part 4: Dotfiles Integration](#part-4-dotfiles-integration)
7. [Part 5: Performance Optimization](#part-5-performance-optimization)
8. [Part 6: Testing & Verification](#part-6-testing--verification)
9. [Troubleshooting](#troubleshooting)
10. [Next Steps](#next-steps)

---

## Why Manual ISO Installation?

**Parallels offers two paths:**
1. **"Download Ubuntu"** - Pre-configured, opinionated image with bundled software
2. **Manual ISO** - Fresh installation with full control (RECOMMENDED)

**Benefits of ISO Installation:**
- ✅ Full control over disk partitioning and layout
- ✅ Minimal installation (only packages you need)
- ✅ Better understanding of system configuration
- ✅ Reproducible setup (can automate later)
- ✅ Latest packages directly from Ubuntu repositories
- ✅ No pre-installed bloatware or unwanted configurations
- ✅ Perfect for development and Docker workloads

---

## Prerequisites

### Required Software

- ✅ **Parallels Desktop** 19.0 or later (20.0+ recommended for Ubuntu 24.04)
  - Pro or Business Edition recommended (better VM features)
  - Standard Edition will work but has limitations

- ✅ **macOS** Ventura 13.0 or later (Sequoia 15.x recommended)

- ✅ **Apple Silicon Mac** (M1/M2/M3/M4)
  - Intel Macs: Use x86_64 Ubuntu ISO instead of ARM64

### Host Machine Requirements

| Resource | Minimum | Recommended | Heavy Workloads |
|----------|---------|-------------|-----------------|
| **Available RAM** | 8 GB | 16 GB | 32 GB+ |
| **Free Disk Space** | 50 GB | 100 GB | 200 GB+ |
| **CPU Cores** | 4 cores | 6+ cores | 8+ cores |

### Downloads

1. **Ubuntu Server 24.04 LTS ARM64 ISO**
   - URL: https://ubuntu.com/download/server/arm
   - File: `ubuntu-24.04.3-live-server-arm64.iso` (~2.5 GB)
   - Choose: "Ubuntu Server" (not 64k page size unless you need it)
   - Verify SHA256 checksum after download

2. **Dotfiles Repository** (if not already cloned)
   - Your dotfiles should be ready on macOS
   - We'll clone them into the VM after installation

### Pre-Installation Checklist

- [ ] Parallels Desktop installed and licensed
- [ ] Ubuntu Server ARM64 ISO downloaded
- [ ] At least 50 GB free disk space on Mac
- [ ] SSH key configured (for remote access)
- [ ] Tailscale account ready (optional, for network access)
- [ ] 1Password CLI configured (for secrets management)

---

## Part 1: VM Creation in Parallels

### Step 1: Launch Parallels and Create New VM

1. **Open Parallels Desktop**
2. **File** → **New...** (or press `⌘N`)
3. **Choose "Install Windows or another OS from a DVD or image file"**
   - DO NOT use "Download Ubuntu" - we want full control

### Step 2: Select Ubuntu ISO

1. **Click "Select a file..."**
2. **Navigate to your Downloads folder**
3. **Select `ubuntu-24.04.3-live-server-arm64.iso`**
4. **Click "Open"**
5. **Click "Continue"**

Parallels should auto-detect: **"Ubuntu Linux 24.04"**

### Step 3: Configure VM Settings (Before First Boot)

1. **Click the gear icon (⚙️) or "Configure" before starting**

#### Hardware Tab

**CPU & Memory:**
- **Processors**: 4-8 vCPU (for development: 4 vCPU, for Docker workloads: 8 vCPU)
  - Enable "Adaptive Hypervisor" (improves macOS host performance)
  - Enable "Nested Virtualization" (needed for Docker-in-Docker, if required)

- **Memory**: 8192 MB (8 GB) minimum, 16384 MB (16 GB) for heavy workloads
  - Enable "Balloon memory" (allows dynamic memory allocation)

**Graphics:**
- **Memory**: 512 MB (headless server needs minimal)
- **Enable Retina resolution**: Off (not needed for server)
- **Vertical sync**: Off
- **3D Acceleration**: On (improves terminal performance)

**Network:**
- **Source**: **Shared Network** (recommended for ease of use)
  - VM gets IP address via NAT
  - Internet access through macOS
  - Accessible from macOS via hostname
- **Alternative**: **Bridged Network** (if you need static IP or direct LAN access)
  - VM appears as separate device on your network
  - Requires router configuration for static IP

**Hard Disk:**
- **Size**: 50 GB minimum, 100 GB recommended
  - Expanding Disk (recommended): Grows as needed
  - Plain Disk: Fixed size, better performance
- **Location**: Choose SSD location for best performance

**CD/DVD:**
- **Source**: Ubuntu ISO should be automatically connected
- **Connected**: Ensure checkbox is checked

#### Options Tab

**Sharing:**
- **Share Mac folders with Linux**: Enable (we'll configure specific folders later)
- **Share custom folders**: Add `/Users/matteo/dev` (or your dev directory)
  - Access rights: Read and Write
- **Share Mac user folders**: Optional (Home, Desktop, Documents)
- **Share Windows applications with Mac**: Off (not applicable)

**Advanced:**
- **Shared Profile**: Off
- **Disable Windows logo key**: Off

**Optimization:**
- **Faster virtual machine**: Recommended
  - This optimizes performance at the cost of slightly more battery usage
- **Adaptive Hypervisor**: On (helps macOS performance when VM is idle)

**Security:**
- **Isolate Mac from Linux**: Off (we need integration)
- **Require password to enter Linux**: Optional (up to your security preference)

### Step 4: Name and Save VM

1. **Name**: `ubuntu-vm` (or your preferred name)
2. **Location**: Default Parallels folder or custom location
3. **Customize settings before installation**: Already done above
4. **Click "Create"**

VM is now created but not yet started.

---

## Part 2: Ubuntu Installation

### Step 1: Start VM and Boot Installer

1. **Click the Play button (▶️) to start the VM**
2. **Ubuntu installer should boot automatically** (GRUB menu appears)
3. **Select "Try or Install Ubuntu Server"** (first option, or wait for auto-boot)

**Expected**: Purple/black screen with Ubuntu logo and loading dots

### Step 2: Language Selection

1. **Select language**: English (or your preference)
2. **Press Enter**

### Step 3: Installer Update (Optional)

If prompted:
- **"Installer update available"**: Choose **"Update to the new installer"** (recommended)
- This ensures you have the latest features and bug fixes

### Step 4: Keyboard Configuration

1. **Layout**: English (US) - or your keyboard layout
2. **Variant**: English (US) - or your specific variant
3. **Test your keyboard** by typing in the "Identify keyboard" prompt
4. **Done** → Enter

### Step 5: Installation Type

1. **Choose type of install**: **Ubuntu Server (minimized)**
   - This installs a minimal server without GUI
   - Perfect for Docker workloads and development
2. **Done** → Enter

### Step 6: Network Configuration

**Parallels Shared Network** should auto-configure:

```
enp0s5: eth
  DHCPv4: 10.211.55.XXX/24
  Gateway: 10.211.55.1
```

- **Network device**: Automatically detected (enp0s5 or similar)
- **IPv4 method**: DHCP (automatic)
- **IPv6 method**: Disabled (unless you need it)

**No changes needed** - default is correct for shared network.

**Done** → Enter

### Step 7: Proxy Configuration

- **Proxy address**: Leave blank (unless you're behind a corporate proxy)
- **Done** → Enter

### Step 8: Mirror Configuration

- **Mirror address**: Default Ubuntu mirror (http://ports.ubuntu.com/ubuntu-ports)
  - This is correct for ARM64
  - Leave as-is unless you have a faster local mirror
- **Done** → Enter

### Step 9: Storage Configuration

**Guided storage configuration** (recommended for most users):

1. **Use entire disk**: Selected (default)
2. **Set up this disk as an LVM group**: **Unchecked** (simpler for VMs)
   - LVM adds complexity and is unnecessary for VMs with expanding disks
   - If you want snapshots/resize later, enable LVM
3. **Choose disk**: Should show your 50 GB virtual disk
4. **Done** → Enter

**Storage summary** should show:
- `DISK vda` (50 GB)
  - Partition 1: 1 MB (BIOS boot)
  - Partition 2: 2 GB (ext4, `/boot`)
  - Partition 3: ~48 GB (ext4, `/`)

**Done** → Enter

**Confirm destructive action**: **Continue** (this will format the disk)

### Step 10: Profile Setup

**Your account configuration:**

- **Your name**: Matteo Cervelli (or your name)
- **Your server's name**: `ubuntu-vm` (hostname for SSH access)
- **Pick a username**: `matteo` (your Linux username)
- **Choose a password**: Strong password (you can change this later or use SSH keys)
- **Confirm your password**: Re-enter password

**Done** → Enter

### Step 11: SSH Setup

**IMPORTANT: Enable SSH for remote access**

- **Install OpenSSH server**: ✅ **[X] Selected** (spacebar to toggle)
  - This is REQUIRED for remote Docker context from macOS
  - You can import SSH keys from GitHub/Launchpad here (optional)
- **Import SSH identity**: Optional
  - **From GitHub**: Enter your GitHub username to import public keys
  - **From Launchpad**: Enter your Launchpad ID
  - Or skip and add keys manually later

**Done** → Enter

### Step 12: Featured Server Snaps

**Optional packages** (you can install these later):

- [ ] docker (DO NOT select - we'll install from official Docker repo)
- [ ] microk8s
- [ ] nextcloud
- [ ] Others...

**Recommendation**: Skip all (press **Done** without selecting anything)
- We'll install Docker using our custom script (Issue #22)
- This keeps the installation minimal

**Done** → Enter

### Step 13: Installation Progress

**Installer is now running** - this takes 5-15 minutes:

1. **Downloading and installing system packages**
2. **Installing kernel**
3. **Configuring system**
4. **Installing bootloader**

**Status indicators**:
- ✅ Green checkmark: Completed
- 🟠 Orange spinner: In progress
- ❌ Red X: Failed (see logs)

**Wait until you see**: **"Install complete!"**

### Step 14: Reboot

1. **Reboot Now** → Enter
2. **Installer will unmount the ISO automatically**
3. **Wait for reboot** (VM restarts)

**If VM hangs**:
- Actions → Stop → Force Stop
- VM Configuration → Hardware → CD/DVD → Disconnect
- Start VM again

### Step 15: First Login

**Ubuntu login prompt appears:**

```
ubuntu-vm login: matteo
Password: ********
```

**You're in!** 🎉

Expected prompt:
```
matteo@ubuntu-vm:~$
```

---

## Part 3: Parallels Tools Installation

**Parallels Tools are REQUIRED for:**
- ✅ Shared folders (`/media/psf/`)
- ✅ Clipboard synchronization
- ✅ Dynamic display resolution
- ✅ Improved graphics performance
- ✅ Better mouse integration
- ✅ Drag & drop file sharing
- ✅ Time synchronization

### Step 1: Update System Packages

**IMPORTANT: Do this FIRST before installing Parallels Tools**

```bash
# Update package lists
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Reboot if kernel was updated
sudo reboot
```

**Wait for reboot, then log back in**

### Step 2: Install Build Dependencies

**Parallels Tools requires kernel headers and build tools:**

```bash
# Install required packages
sudo apt install -y \
    dkms \
    build-essential \
    linux-headers-$(uname -r) \
    libelf-dev \
    gcc \
    make

# Verify kernel headers are installed
ls /lib/modules/$(uname -r)/build
```

**Expected output**: Should list files (not "No such file or directory")

### Step 3: Insert Parallels Tools ISO

**From Parallels Desktop menu bar:**

1. **Actions** → **Install Parallels Tools...**
   - Or press `⌘K`
2. **Confirm installation** if prompted

**The Parallels Tools ISO is now inserted into the VM's virtual CD-ROM drive**

### Step 4: Mount Parallels Tools ISO

```bash
# Create mount point
sudo mkdir -p /mnt/cdrom

# Mount the CD-ROM
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

# Or run with verbose output
sudo ./install --verbose
```

**Installation process** (takes 2-5 minutes):

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

**Expected services started**:
- `prltoolsd` - Parallels Tools daemon
- `prlshprof` - Shared Profile service
- `prlcp` - Clipboard synchronization

### Step 6: Verify Installation

```bash
# Check Parallels Tools version
prltools -v

# Check service status
systemctl status parallels-tools

# List installed Parallels Tools packages
dpkg -l | grep parallels
```

**Expected output**:
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

### Step 8: Verify Shared Folders After Reboot

```bash
# Log back in after reboot

# Check Parallels shared folders
ls -la /media/psf/

# Should show your shared folders
# Example: /media/psf/Home/ (if you shared your home directory)
```

**Expected**: Your macOS shared folders appear in `/media/psf/`

---

## Part 4: Dotfiles Integration

Now that Ubuntu is installed with Parallels Tools, integrate with your dotfiles system.

### Step 1: Verify Network and Internet Access

```bash
# Test internet connectivity
ping -c 3 google.com

# Test DNS resolution
nslookup github.com

# Check IP address
ip addr show
```

### Step 2: Configure SSH Access from macOS

**From your Mac (not in VM):**

```bash
# Find VM IP address (from VM)
hostname -I

# Or use Parallels hostname
# Default: ubuntu-vm.local or ubuntu-vm

# Test SSH from macOS
ssh matteo@ubuntu-vm

# Or via IP
ssh matteo@10.211.55.XXX
```

**If SSH works, you can now manage the VM remotely from your Mac terminal**

### Step 3: Set Up SSH Keys (Optional but Recommended)

**From macOS:**

```bash
# Copy your SSH public key to VM
ssh-copy-id matteo@ubuntu-vm

# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh matteo@ubuntu-vm 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'

# Test passwordless SSH
ssh matteo@ubuntu-vm
```

### Step 4: Clone Dotfiles Repository

**In the VM (via SSH or direct terminal):**

```bash
# Install git if not already installed
sudo apt install -y git

# Clone dotfiles (replace with your repo)
cd ~
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles
```

### Step 5: Run Ubuntu Bootstrap Script

**This installs all dependencies (git, curl, wget, build tools, etc.)**

```bash
# Make script executable
chmod +x scripts/bootstrap/install-dependencies-ubuntu.sh

# Run bootstrap (without Docker for now)
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh

# Or with Docker (recommended)
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --with-docker

# Or via Makefile
make ubuntu-full
```

**This installs:**
- Development tools (git, curl, wget, vim, tmux)
- Build essentials (gcc, make, autoconf)
- Python and pip
- Node.js and npm (via nvm)
- Rclone (for R2 asset sync)
- yq (YAML processor)
- Docker Engine + Compose v2 (if `--with-docker` flag used)

**Duration**: 5-10 minutes

### Step 6: Install GNU Stow and Deploy Packages

```bash
# Stow should be installed by bootstrap script
# Verify installation
stow --version

# Deploy all dotfiles packages
cd ~/dotfiles
make stow

# Or deploy specific packages
stow -t ~ shell
stow -t ~ git
stow -t ~ ssh
```

**This creates symlinks:**
- `~/.zshrc` → `~/dotfiles/stow-packages/shell/.zshrc`
- `~/.gitconfig` → `~/dotfiles/stow-packages/git/.gitconfig`
- `~/.ssh/config` → `~/dotfiles/stow-packages/ssh/.ssh/config`

### Step 7: Configure Shared Folders

**Create convenient symlinks to Parallels shared folders:**

```bash
# List available shared folders
ls -la /media/psf/

# Create symlink to shared dev directory
ln -s /media/psf/Home/dev ~/dev-shared

# Or create permanent mount point
sudo mkdir -p /mnt/dev
echo "/media/psf/Home/dev /mnt/dev none bind 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Verify access
ls ~/dev-shared/
# Should show contents of your macOS ~/dev directory
```

### Step 8: Install Docker (If Not Done Yet)

**If you didn't use `--with-docker` flag earlier:**

```bash
cd ~/dotfiles

# Install Docker Engine + Compose v2
sudo ./scripts/bootstrap/install-docker.sh

# Or via Makefile
make docker-install

# Verify Docker installation
docker --version
docker compose version

# Test Docker
docker run hello-world
```

**IMPORTANT**: Log out and log back in for docker group to take effect

```bash
# Log out
exit

# SSH back in
ssh matteo@ubuntu-vm

# Verify you can run Docker without sudo
docker ps
```

**See [docker-ubuntu-setup.md](docker-ubuntu-setup.md) for complete Docker setup guide**

### Step 9: Configure Remote Docker Context (from macOS)

**This allows you to control VM Docker from your Mac without SSH**

**From macOS terminal:**

```bash
# Install Docker CLI on macOS (if not installed)
brew install docker

# Create Docker context for Ubuntu VM
docker context create ubuntu-vm --docker "host=ssh://matteo@ubuntu-vm"

# Switch to Ubuntu VM context
docker context use ubuntu-vm

# Test remote Docker
docker ps

# Switch back to local Docker Desktop (if you have it)
docker context use default
```

**Now you can run Docker commands from macOS and they execute in the VM!**

---

## Part 5: Performance Optimization

### CPU & Memory Optimization

**Adjust VM resources based on workload:**

```bash
# Check VM resource usage (in VM)
htop

# Check CPU cores
nproc

# Check memory
free -h

# Check disk usage
df -h
```

**Recommended configurations:**

| Workload | vCPU | RAM | Disk | Use Case |
|----------|------|-----|------|----------|
| **Light Development** | 2-4 | 4-8 GB | 32 GB | Code editing, small projects |
| **Docker Development** | 4-6 | 8-12 GB | 50 GB | Multiple containers, databases |
| **Heavy Workloads** | 6-8 | 12-16 GB | 100 GB | Large builds, ML workloads |
| **Production Testing** | 8+ | 16-32 GB | 200 GB | Load testing, staging |

**To adjust VM resources:**
1. Shut down VM: `sudo poweroff`
2. Parallels Desktop → VM Configuration → Hardware
3. Adjust CPU and Memory sliders
4. Start VM

### Disk I/O Optimization

**Use SSD location for best performance:**

1. VM Configuration → Hardware → Hard Disk
2. Note the `.pvm` file location
3. Ensure it's on your Mac's internal SSD (not external drive)

**Inside VM - optimize filesystem:**

```bash
# Enable TRIM support for SSD
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# Check TRIM status
sudo systemctl status fstrim.timer
```

### Network Optimization

**Shared Network is faster than Bridged for most use cases**

**Test network performance:**

```bash
# Test download speed
curl -o /dev/null http://speedtest.tele2.net/100MB.zip

# Test latency to macOS host
ping -c 10 10.211.55.1
```

**Expected latency**: < 1ms (Shared Network), 1-5ms (Bridged)

### Memory Balloon Driver

**Allows dynamic memory allocation - should be enabled by default**

**Verify balloon driver:**

```bash
# Check if balloon module is loaded
lsmod | grep vmw_balloon

# Parallels uses different module name
lsmod | grep prl
```

---

## Part 6: Testing & Verification

### Shared Folders Test

```bash
# List shared folders
ls -la /media/psf/

# Create test file from macOS
# (On macOS) echo "Hello from macOS" > ~/dev/test.txt

# Read file from Ubuntu VM
cat /media/psf/Home/dev/test.txt
# Should output: Hello from macOS

# Create file from Ubuntu
echo "Hello from Ubuntu" > /media/psf/Home/dev/test-vm.txt

# Verify on macOS
# (On macOS) cat ~/dev/test-vm.txt
```

✅ **Pass**: Files created in one OS appear in the other immediately

### Clipboard Synchronization Test

**Copy text from macOS → Paste in Ubuntu:**
1. Copy text on macOS (⌘C)
2. In VM terminal: Press `Ctrl+Shift+V` or right-click → Paste
3. Text should paste correctly

**Copy text from Ubuntu → Paste in macOS:**
1. Select text in Ubuntu terminal
2. Copy: `Ctrl+Shift+C`
3. Switch to macOS, paste (⌘V)
4. Text should paste correctly

✅ **Pass**: Clipboard works bidirectionally

### Docker Test

```bash
# Run Docker hello-world
docker run hello-world

# Run nginx container
docker run -d -p 8080:80 --name test-nginx nginx

# Test from VM
curl http://localhost:8080

# Test from macOS (if using Shared Network)
curl http://ubuntu-vm:8080

# Or via IP
curl http://10.211.55.XXX:8080

# Clean up
docker stop test-nginx
docker rm test-nginx
```

✅ **Pass**: Docker containers run and are accessible

### Remote Docker Context Test (from macOS)

```bash
# Switch to Ubuntu VM context
docker context use ubuntu-vm

# List containers (should show containers running in VM)
docker ps

# Run container via remote context
docker run -d -p 9090:80 --name remote-test nginx

# Test access
curl http://ubuntu-vm:9090

# Clean up
docker stop remote-test
docker rm remote-test

# Switch back to local context
docker context use default
```

✅ **Pass**: Remote Docker context works from macOS

### R2 Asset Sync Test

```bash
# Configure rclone (if not done)
cd ~/dotfiles
./scripts/sync/setup-rclone.sh

# Test R2 connection
rclone lsd r2:

# Pull assets from R2
rclone sync r2:your-bucket/assets ~/test-assets --progress

# Verify files
ls ~/test-assets/
```

✅ **Pass**: R2 assets accessible from VM

### SSH Access Test

```bash
# From macOS - test SSH
ssh matteo@ubuntu-vm

# Test SSH key authentication (should not prompt for password)
ssh matteo@ubuntu-vm 'echo "SSH works!"'

# Test via Tailscale (if configured)
ssh ubuntu-vm.tailscale-alias
```

✅ **Pass**: SSH access works from macOS

### Performance Test

```bash
# CPU benchmark
sysbench cpu --threads=4 run

# Memory benchmark
sysbench memory run

# Disk benchmark
dd if=/dev/zero of=~/testfile bs=1M count=1024 oflag=direct

# Clean up
rm ~/testfile
```

✅ **Pass**: Performance is acceptable for workload

---

## Troubleshooting

### Issue: Parallels Tools Installation Fails

**Symptom**: `./install` fails with "Unable to build kernel modules"

**Solution**:

```bash
# Ensure kernel headers match running kernel
uname -r
ls /lib/modules/$(uname -r)/build

# If build directory doesn't exist, install headers
sudo apt update
sudo apt install -y linux-headers-$(uname -r)

# Reinstall Parallels Tools
sudo ./install --verbose
```

### Issue: Shared Folders Not Appearing

**Symptom**: `/media/psf/` is empty or doesn't exist

**Solution**:

```bash
# Check if Parallels Tools is running
systemctl status parallels-tools

# Restart Parallels Tools service
sudo systemctl restart parallels-tools

# Check for mount errors
dmesg | grep -i parallels

# Manually mount shared folders
sudo mount -t prl_fs none /media/psf/
```

**If still not working:**
1. VM Configuration → Options → Sharing
2. Ensure "Share Mac folders with Linux" is enabled
3. Ensure specific folders are added with Read/Write access
4. Reboot VM

### Issue: Clipboard Not Synchronizing

**Symptom**: Cannot copy/paste between macOS and Ubuntu

**Solution**:

```bash
# Check if clipboard service is running
ps aux | grep prlcp

# Restart clipboard service
sudo systemctl restart prlcp

# Or restart all Parallels Tools
sudo systemctl restart parallels-tools
```

**Alternative**: Enable in VM Configuration → Options → Sharing → Share Mac clipboard

### Issue: Network Not Working

**Symptom**: Cannot access internet from VM

**Solution**:

```bash
# Check network interface
ip addr show

# Check for DHCP lease
ip route show

# Restart network service
sudo systemctl restart systemd-networkd

# Or reconfigure network manually
sudo netplan apply
```

**If Shared Network not working:**
1. VM Configuration → Hardware → Network
2. Try switching to "Bridged Network"
3. Restart VM

### Issue: Docker Containers Not Accessible from macOS

**Symptom**: `curl http://ubuntu-vm:8080` fails

**Solution**:

```bash
# Check if container is running in VM
docker ps

# Check container port mapping
docker port container-name

# Test from within VM first
curl http://localhost:8080

# Check firewall rules
sudo ufw status

# If ufw is active, allow port
sudo ufw allow 8080/tcp
```

**Alternative**: Use Bridged Network mode for direct LAN access

### Issue: VM Performance is Slow

**Symptom**: VM feels sluggish, high CPU usage on macOS

**Solution**:

1. **Increase VM resources**:
   - More vCPU cores (4-8)
   - More RAM (8-16 GB)

2. **Enable performance optimizations**:
   - VM Configuration → Options → Optimization → "Faster virtual machine"
   - Enable "Adaptive Hypervisor"

3. **Check disk I/O**:
   ```bash
   # In VM - check disk usage
   iotop

   # Check if disk is on SSD
   # (macOS) diskutil info / | grep "Solid State"
   ```

4. **Disable unnecessary services**:
   ```bash
   # List running services
   systemctl list-units --type=service --state=running

   # Disable unneeded services
   sudo systemctl disable snap.amazon-ssm-agent.amazon-ssm-agent.service
   ```

### Issue: "No Space Left on Device"

**Symptom**: Disk full errors

**Solution**:

```bash
# Check disk usage
df -h

# Find large files
sudo du -sh /* | sort -h

# Clean up Docker
docker system prune -a -f

# Clean up APT cache
sudo apt clean
sudo apt autoclean

# Clean up logs
sudo journalctl --vacuum-time=7d
```

**To expand disk**:
1. Shut down VM
2. VM Configuration → Hardware → Hard Disk → Edit
3. Increase size (e.g., 50 GB → 100 GB)
4. Start VM
5. Resize partition (may require live USB)

### Issue: SSH Connection Refused

**Symptom**: `ssh: connect to host ubuntu-vm port 22: Connection refused`

**Solution**:

```bash
# In VM - check if SSH is running
sudo systemctl status ssh

# Start SSH service
sudo systemctl start ssh

# Enable SSH on boot
sudo systemctl enable ssh

# Check SSH is listening
sudo ss -tlnp | grep :22
```

---

## Next Steps

### After VM is Set Up

1. **Install Additional Software**
   - Docker (if not done): See [docker-ubuntu-setup.md](docker-ubuntu-setup.md)
   - Development tools: Python, Node.js, Go, etc.
   - Database servers: PostgreSQL, Redis, MySQL

2. **Configure Tailscale** (for secure remote access)
   ```bash
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```

3. **Set Up Backup Strategy**
   - Use Parallels snapshots for quick rollback
   - Back up VM to external drive or NAS
   - Sync dotfiles to GitHub regularly

4. **Integrate with Development Workflow**
   - Remote Docker context from macOS
   - VS Code Remote SSH extension
   - Shared folders for code editing

5. **Monitor Resource Usage**
   - Install htop, iotop, nethogs
   - Set up Prometheus node_exporter (optional)
   - Monitor from macOS Activity Monitor

### Related Documentation

- **Issue #22**: [Docker on Ubuntu Setup](docker-ubuntu-setup.md)
- **Issue #23**: Parallels Integration & Testing (this document)
- **TASK.md**: [Complete implementation tracking](../TASK.md)

### Common Next Tasks

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install Redis
sudo apt install -y redis-server

# Install Python development tools
sudo apt install -y python3-pip python3-venv python3-dev

# Install Node.js via nvm (if not installed by bootstrap)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install --lts

# Clone your projects
cd ~/dev-shared
git clone <your-repo>
```

---

## Summary Checklist

Before considering VM setup complete:

- [ ] Ubuntu 24.04 Server ARM64 installed
- [ ] Parallels Tools installed and working
- [ ] Shared folders accessible (`/media/psf/`)
- [ ] Clipboard synchronization working
- [ ] SSH access configured from macOS
- [ ] Dotfiles cloned and deployed
- [ ] Docker installed and running
- [ ] Remote Docker context working from macOS
- [ ] Network connectivity verified
- [ ] Performance acceptable for workload
- [ ] Backup/snapshot created

**Congratulations! Your Ubuntu VM is ready for development. 🎉**

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Issue**: [#23](https://github.com/matteocervelli/dotfiles/issues/23)
**Status**: ✅ Complete
