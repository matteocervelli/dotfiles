# VM Ubuntu - Setup e Testing Integrazione Parallels

Guida pratica per configurare e testare l'integrazione tra macOS e VM Ubuntu tramite Parallels Desktop, con focus su shared folders, R2 assets workflow, e verifica completa del setup.

**Prerequisiti**: VM Ubuntu già creata con Parallels Tools installato. Se devi creare la VM, vedi [Parallels VM Creation Guide](guides/parallels-vm-creation.md).

**Related Documentation**:
- [Parallels VM Creation Guide](guides/parallels-vm-creation.md) - Come creare la VM da zero
- [Docker on Ubuntu Setup](guides/docker-ubuntu-setup.md) - Setup Docker (Issue #22)
- [TASK.md](TASK.md#43-parallels-integration--testing-issue-23) - Issue #23 tracking

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Shared Folders Configuration](#shared-folders-configuration)
3. [R2 Assets Workflow](#r2-assets-workflow)
4. [Project Setup Testing](#project-setup-testing)
5. [Docker Integration](#docker-integration)
6. [Automated Testing](#automated-testing)
7. [Manual Testing Checklist](#manual-testing-checklist)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required

- ✅ **VM Ubuntu 24.04 LTS** già creata e funzionante
  - Se non hai ancora la VM: [Parallels VM Creation Guide](guides/parallels-vm-creation.md)
- ✅ **Parallels Tools** installato nella VM
  - Verifica: `prltools -v` nella VM deve mostrare la versione
- ✅ **Docker** installato e funzionante (Issue #22)
  - Verifica: `docker --version` e `docker ps`
- ✅ **Dotfiles** clonati e deployed nella VM
  - Verifica: `ls ~/dotfiles` e `ls -la ~/.zshrc`
- ✅ **SSH access** configurato da macOS
  - Verifica: `ssh ubuntu-vm` da macOS

### Recommended

- ✅ **Rclone** configurato per R2 (FASE 2)
- ✅ **1Password CLI** configurato (FASE 2)
- ✅ **Central asset library** su macOS: `~/media/cdn/`

### Directory Structure Expected

**macOS:**
```
~/media/cdn/
├── .r2-manifest.yml      # Central manifest
├── .dimensions-cache.json
├── assets/               # General assets
├── logos/                # Logo files
├── projects/             # Project-specific assets
├── profile/              # Personal/profile assets
└── shared/               # Shared across projects
```

**VM Ubuntu (dopo setup):**
```
/media/psf/Home/media/cdn/    # Parallels mount (automatico)
~/cdn -> /media/psf/Home/media/cdn/    # Symlink (da creare)
~/dev -> /media/psf/Home/dev/          # Symlink (da creare)
```

---

## Shared Folders Configuration

### Step 1: Configure in Parallels Desktop (macOS)

**Enable Shared Folders:**

1. **Open Parallels Desktop**
2. **Select Ubuntu VM** → Right-click → **Configure**
3. **Options Tab** → **Sharing**
4. **Share Mac folders with Linux**: ✅ Enable

**Add Custom Folders:**

1. **Share custom folders**: Click **+** button
2. **Add two folders:**
   - **Folder 1**: `/Users/matteo/dev`
     - Name: `dev` (o lascia default)
     - Access rights: **Read and Write**
   - **Folder 2**: `/Users/matteo/media/cdn`
     - Name: `cdn` (o lascia default)
     - Access rights: **Read and Write**

**Important Settings:**
- ✅ **Share Mac folders with Linux**: Enabled
- ✅ **Share Mac user folders**: Optional (Home, Desktop, Documents)
- ❌ **Shared Profile**: Disabled (can cause permission issues)

**Apply Changes**: Click **OK**

### Step 2: Verify Mount Points in VM

**From VM terminal:**

```bash
# List all Parallels shared folders
ls -la /media/psf/

# Expected output should include:
# drwxr-xr-x  Home/     (your macOS home directory)
# or specific folders you shared
```

**Expected paths:**
- `/media/psf/Home/dev/` → your macOS `~/dev`
- `/media/psf/Home/media/cdn/` → your macOS `~/media/cdn`

### Step 3: Create Convenient Symlinks

**In VM, create symlinks for easy access:**

```bash
# Symlink for CDN assets
ln -sf /media/psf/Home/media/cdn ~/cdn

# Symlink for development directory
ln -sf /media/psf/Home/dev ~/dev-shared

# Verify symlinks
ls -la ~/ | grep -E 'cdn|dev-shared'

# Test access
ls ~/cdn/
ls ~/dev-shared/
```

**Why symlinks?**
- Shorter paths: `~/cdn/` instead of `/media/psf/Home/media/cdn/`
- Easier to remember
- Can be used in scripts without long paths

### Step 4: Test Read/Write Access

```bash
# Test read access
cat ~/cdn/.r2-manifest.yml | head -10

# Test write access (create temp file)
echo "Test from VM" > ~/cdn/test-vm.txt

# Verify from macOS
# (macOS) cat ~/media/cdn/test-vm.txt
# Should show: Test from VM

# Clean up
rm ~/cdn/test-vm.txt
```

✅ **Success indicator**: You can read and write files bidirectionally

### Step 5: Set Up Permanent Mounts (Optional)

**For production setups, create permanent mount points:**

```bash
# Create mount points
sudo mkdir -p /mnt/cdn
sudo mkdir -p /mnt/dev

# Add to /etc/fstab for automatic mounting
echo "/media/psf/Home/media/cdn /mnt/cdn none bind 0 0" | sudo tee -a /etc/fstab
echo "/media/psf/Home/dev /mnt/dev none bind 0 0" | sudo tee -a /etc/fstab

# Mount now
sudo mount -a

# Verify
ls /mnt/cdn/
ls /mnt/dev/
```

**Note**: This is optional. Symlinks are usually sufficient for development.

---

## R2 Assets Workflow

### Central Library Strategy

**Architecture:**
```
Cloudflare R2 (cloud storage)
    ↓ sync (rclone)
macOS ~/media/cdn/ (central library)
    ↓ shared folders (Parallels)
VM /media/psf/Home/media/cdn/ (read-only access)
```

**Key Benefits:**
- ✅ **Single source of truth**: macOS central library
- ✅ **No duplication**: VM reads directly from macOS
- ✅ **Automatic sync**: Changes on macOS instantly visible in VM
- ✅ **Efficient**: No need to sync R2 → VM separately

### Verify R2 Manifest Access in VM

**The central manifest contains all asset metadata:**

```bash
# In VM - read central manifest
cat ~/cdn/.r2-manifest.yml | head -20

# Check manifest structure
yq eval '.project' ~/cdn/.r2-manifest.yml
yq eval '.assets | length' ~/cdn/.r2-manifest.yml

# List all assets
yq eval '.assets[].path' ~/cdn/.r2-manifest.yml
```

**Expected output**: YAML structure with project name, version, and asset list

### Access Specific Assets in VM

**Example: Access logos:**

```bash
# List available logos
ls ~/cdn/logos/

# View logo file
file ~/cdn/logos/logo-main.svg

# Use in project (example)
cp ~/cdn/logos/logo-main.svg ~/my-project/public/logo.svg
```

### R2 Sync Workflow (macOS)

**Sync from R2 to macOS (central library):**

```bash
# On macOS (not in VM!)
cd ~/media/cdn

# Pull latest assets from R2
rclone sync r2:your-bucket . --progress

# Changes are immediately visible in VM via shared folders
```

**In VM, verify changes:**

```bash
# VM automatically sees new files
ls ~/cdn/

# No additional sync needed!
```

### Project-Specific Asset Usage

**Use assets in your projects via symlinks or copies:**

```bash
# In your project directory (VM)
cd ~/dev-shared/my-project

# Option 1: Symlink (read-only, always up-to-date)
ln -s ~/cdn/projects/my-project/images ./data/images

# Option 2: Copy (independent, can modify)
cp -r ~/cdn/projects/my-project/images ./data/images

# Verify
ls data/images/
```

---

## Project Setup Testing

### Using dev-setup.sh Template

**The `dev-setup.sh.template` helps initialize projects with R2 assets.**

**Location**: `~/dotfiles/templates/project/dev-setup.sh.template`

### Test Workflow: Create Sample Project

**Step 1: Create test project in VM**

```bash
# In VM
cd ~/dev-shared
mkdir test-project
cd test-project

# Initialize git
git init

# Copy dev-setup template
cp ~/dotfiles/templates/project/dev-setup.sh.template ./dev-setup.sh
chmod +x dev-setup.sh
```

**Step 2: Create project manifest**

```bash
# Create simple manifest
cat > .r2-manifest.yml << 'EOF'
project: test-project
version: "1.0"
updated: 2025-10-26T10:00:00Z

assets:
  - path: data/test-image.png
    r2_key: shared/test-image.png
    size: 1048576
    sha256: abc123...
    type: image
    sync: true
    devices: [mac-studio, ubuntu-vm]
    description: "Test image for VM integration"
EOF
```

**Step 3: Test dev-setup.sh**

```bash
# Run setup script
./dev-setup.sh

# Expected behavior:
# 1. Check if manifest exists ✓
# 2. Check if assets are accessible ✓
# 3. Create data/ directory if needed
# 4. Symlink or copy assets from ~/cdn/
```

### Verify Project Assets Access

```bash
# Check if data directory was created
ls -la data/

# Verify assets are accessible
file data/test-image.png

# Check symlink (if using symlink strategy)
ls -la data/ | grep -E '->.*cdn'
```

✅ **Success indicator**: Project can access assets via central library

---

## Docker Integration

### Test Docker with Shared Folders

**Docker containers can mount volumes from Parallels shared folders:**

```bash
# Test 1: Mount ~/cdn in container
docker run -it --rm \
  -v ~/cdn:/data:ro \
  ubuntu:24.04 \
  ls -la /data

# Expected: Should list your CDN assets

# Test 2: Mount project directory
docker run -it --rm \
  -v ~/dev-shared/test-project:/project \
  ubuntu:24.04 \
  ls -la /project

# Expected: Should list project files
```

### Test Docker with Asset Workflow

**Create a test container that uses CDN assets:**

```bash
# Create Dockerfile
cat > ~/dev-shared/test-project/Dockerfile << 'EOF'
FROM ubuntu:24.04

# Install imagemagick for testing
RUN apt-get update && apt-get install -y imagemagick

# Copy test image from CDN
COPY data/test-image.png /app/test.png

# Verify
RUN ls -lh /app/test.png
RUN file /app/test.png

CMD ["echo", "Container built successfully with CDN assets"]
EOF

# Build image
cd ~/dev-shared/test-project
docker build -t test-cdn-integration .

# Run container
docker run --rm test-cdn-integration
```

✅ **Success indicator**: Docker build succeeds and can access CDN assets

### Remote Docker Context Test

**From macOS, control VM Docker:**

```bash
# On macOS
docker context use ubuntu-vm

# Run container in VM from macOS
docker run -d --name test-nginx \
  -v /home/matteo/cdn:/usr/share/nginx/html:ro \
  -p 8080:80 \
  nginx

# Test access from macOS
curl http://ubuntu-vm:8080/

# Check container in VM
# (VM) docker ps

# Clean up
docker stop test-nginx
docker rm test-nginx

# Switch back to local context
docker context use default
```

✅ **Success indicator**: Can control VM Docker from macOS and mount shared folders

---

## Automated Testing

### Run Integration Test Script

**Use the automated test script:**

```bash
# In VM
cd ~/dotfiles

# Run automated tests
./scripts/test/test-vm-integration.sh

# Expected output:
# ✅ Parallels Tools installed
# ✅ Shared folders mounted
# ✅ CDN accessible
# ✅ Read access working
# ✅ Write access working
# ✅ Symlinks created
# ✅ R2 manifest accessible
# ✅ Docker integration working
```

**The script checks:**
- Parallels Tools installation
- Shared folder mounts
- CDN accessibility
- Read/write permissions
- Symlink creation
- R2 manifest parsing
- Docker shared folder integration

### Interpret Test Results

**All tests passing:**
```
✅ All tests passed! (8/8)
Your VM integration is working correctly.
```

**Some tests failing:**
```
❌ Some tests failed (5/8)
See details above for troubleshooting steps.
```

---

## Manual Testing Checklist

Use this checklist to manually verify VM integration.

### Basic Integration

- [ ] **Parallels Tools Installed**
  ```bash
  prltools -v
  # Should show version number
  ```

- [ ] **Shared Folders Visible**
  ```bash
  ls /media/psf/
  # Should show Home/ or your shared folders
  ```

- [ ] **CDN Directory Accessible**
  ```bash
  ls ~/cdn/ || ls /media/psf/Home/media/cdn/
  # Should list asset directories
  ```

- [ ] **Dev Directory Accessible**
  ```bash
  ls ~/dev-shared/ || ls /media/psf/Home/dev/
  # Should list your projects
  ```

### Read/Write Access

- [ ] **Can Read Files**
  ```bash
  cat ~/cdn/.r2-manifest.yml | head -5
  # Should show manifest content
  ```

- [ ] **Can Write Files**
  ```bash
  echo "test" > ~/cdn/test-write.txt
  # Should succeed without errors
  rm ~/cdn/test-write.txt
  ```

- [ ] **Can Create Directories**
  ```bash
  mkdir ~/cdn/test-dir
  rmdir ~/cdn/test-dir
  ```

### R2 Assets

- [ ] **Manifest Readable**
  ```bash
  yq eval '.project' ~/cdn/.r2-manifest.yml
  # Should show project name
  ```

- [ ] **Assets Accessible**
  ```bash
  ls ~/cdn/assets/
  ls ~/cdn/logos/
  # Should list files
  ```

- [ ] **Can Copy Assets**
  ```bash
  cp ~/cdn/logos/logo-main.svg /tmp/test-logo.svg
  file /tmp/test-logo.svg
  rm /tmp/test-logo.svg
  ```

### Project Setup

- [ ] **dev-setup.sh Template Exists**
  ```bash
  ls ~/dotfiles/templates/project/dev-setup.sh.template
  ```

- [ ] **Can Create Test Project**
  ```bash
  mkdir -p ~/dev-shared/test-vm-project
  cd ~/dev-shared/test-vm-project
  cp ~/dotfiles/templates/project/dev-setup.sh.template ./dev-setup.sh
  chmod +x dev-setup.sh
  ```

- [ ] **Project Can Access Assets**
  ```bash
  ln -s ~/cdn/shared ~/dev-shared/test-vm-project/data
  ls ~/dev-shared/test-vm-project/data
  ```

### Docker Integration

- [ ] **Docker Running**
  ```bash
  docker ps
  # Should show running containers (if any)
  ```

- [ ] **Can Mount Shared Folders**
  ```bash
  docker run --rm -v ~/cdn:/data:ro ubuntu:24.04 ls /data
  # Should list CDN contents
  ```

- [ ] **Remote Context Works (from macOS)**
  ```bash
  # On macOS
  docker context use ubuntu-vm
  docker ps
  # Should show VM containers
  ```

### Performance

- [ ] **Read Performance Acceptable**
  ```bash
  time cat ~/cdn/logos/logo-main.svg > /dev/null
  # Should complete quickly (< 0.1s)
  ```

- [ ] **Write Performance Acceptable**
  ```bash
  time dd if=/dev/zero of=~/cdn/test-1mb.dat bs=1M count=1
  rm ~/cdn/test-1mb.dat
  # Should complete quickly (< 1s)
  ```

---

## Troubleshooting

### Issue: Shared Folders Not Visible

**Symptom**: `/media/psf/` is empty or doesn't exist

**Solutions**:

```bash
# 1. Check Parallels Tools status
systemctl status parallels-tools

# 2. Restart Parallels Tools
sudo systemctl restart parallels-tools

# 3. Check for prl_fs module
lsmod | grep prl

# 4. Manually mount
sudo mount -t prl_fs none /media/psf/

# 5. Check dmesg for errors
dmesg | grep -i parallels | tail -20
```

**If still not working**:
1. Verify Parallels Tools installed: `prltools -v`
2. Check Parallels Desktop → VM Configuration → Options → Sharing
3. Ensure "Share Mac folders with Linux" is enabled
4. Reboot VM

### Issue: Permission Denied on Shared Folders

**Symptom**: Cannot read or write files in `/media/psf/`

**Solutions**:

```bash
# Check ownership
ls -la /media/psf/Home/media/cdn/

# User should have access
# If not, check Parallels sharing settings

# Ensure Access rights are "Read and Write"
# Parallels Desktop → Configure → Options → Sharing
```

### Issue: CDN Symlink Broken

**Symptom**: `ls ~/cdn/` shows "No such file or directory"

**Solutions**:

```bash
# Remove broken symlink
rm ~/cdn

# Recreate symlink
ln -sf /media/psf/Home/media/cdn ~/cdn

# Verify
ls -la ~/cdn
```

### Issue: R2 Manifest Not Accessible

**Symptom**: Cannot read `.r2-manifest.yml`

**Solutions**:

```bash
# Check if file exists on macOS
# (macOS) ls -la ~/media/cdn/.r2-manifest.yml

# Check in VM
ls -la /media/psf/Home/media/cdn/.r2-manifest.yml

# If file doesn't exist, sync from R2 (on macOS)
# (macOS) cd ~/media/cdn && rclone sync r2:your-bucket . --progress
```

### Issue: Docker Can't Access Shared Folders

**Symptom**: Docker mount fails or shows empty directory

**Solutions**:

```bash
# 1. Verify path is accessible
ls ~/cdn/

# 2. Use absolute path instead of relative
docker run --rm -v /home/matteo/cdn:/data:ro ubuntu:24.04 ls /data

# 3. Check permissions
ls -la ~/cdn/

# 4. Try mounting specific subdirectory
docker run --rm -v ~/cdn/logos:/data:ro ubuntu:24.04 ls /data
```

### Issue: Slow Performance

**Symptom**: Reading/writing to shared folders is very slow

**Solutions**:

1. **Enable Performance Mode** in Parallels:
   - VM Configuration → Options → Optimization → "Faster virtual machine"

2. **Check Adaptive Hypervisor**:
   - Should be enabled for better performance

3. **Reduce I/O operations**:
   - Copy frequently-accessed files to VM local disk
   - Use shared folders for large, infrequently-accessed assets

4. **Check macOS disk performance**:
   - Ensure ~/media/cdn/ is on internal SSD, not external drive

---

## Summary

**After completing this setup, you should have:**

✅ Shared folders working: `~/cdn/` and `~/dev-shared/`
✅ R2 assets accessible from VM via central library
✅ Project setup workflow tested with `dev-setup.sh`
✅ Docker integration verified with shared folder mounts
✅ Remote Docker context working from macOS
✅ All automated tests passing

**Next Steps:**

1. **Test on real projects**: Clone your actual projects and verify asset access
2. **Optimize workflow**: Adjust paths and scripts based on your needs
3. **Document project-specific setup**: Add project-specific instructions to each repo
4. **Set up CI/CD**: Consider using VM for testing pipelines

**Related Documentation:**
- [Parallels VM Creation Guide](guides/parallels-vm-creation.md) - Create VM from scratch
- [Docker Ubuntu Setup](guides/docker-ubuntu-setup.md) - Docker installation
- [Asset Management](../sync/library/README.md) - Central library strategy

---

**Created**: 2025-10-26
**Issue**: [#23](https://github.com/matteocervelli/dotfiles/issues/23)
**Status**: Ready for testing
