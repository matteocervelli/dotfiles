# VM Integration Testing Checklist

Complete checklist per verificare che l'integrazione tra macOS e VM Ubuntu tramite Parallels funzioni correttamente.

**Usare questa checklist**:
1. Prima di considerare il setup completo
2. Dopo modifiche a configurazione Parallels
3. Dopo aggiornamenti di Parallels Tools
4. Come parte del troubleshooting

**Related Documentation**: [VM Setup Guide](../vm-setup.md)

---

## Pre-Test Setup

### 1. Verify Prerequisites

- [ ] VM Ubuntu 24.04 LTS is running
- [ ] SSH access works from macOS: `ssh ubuntu-vm`
- [ ] Dotfiles are cloned in VM: `ls ~/dotfiles`

**Commands to verify**:
```bash
# From macOS
ssh ubuntu-vm 'uname -a'
# Should show: Linux ubuntu-vm 6.8.0-... aarch64 GNU/Linux
```

---

## Parallels Integration

### 2. Parallels Tools

- [ ] Parallels Tools installed
  ```bash
  # In VM
  prltools -v
  # Expected: Parallels Tools X.X.X (build XXXXX)
  ```

- [ ] Parallels Tools service running
  ```bash
  systemctl status parallels-tools
  # Expected: active (running)
  ```

- [ ] Clipboard synchronization module loaded
  ```bash
  ps aux | grep prlcp
  # Should show prlcp process
  ```

**Troubleshooting**: If not working, see [VM Setup Guide - Troubleshooting](../vm-setup.md#troubleshooting)

---

## Shared Folders

### 3. Basic Shared Folders Access

- [ ] /media/psf/ directory exists
  ```bash
  ls -la /media/psf/
  ```

- [ ] Shared folders are visible
  ```bash
  ls /media/psf/
  # Expected output: Home/ (or your shared folder names)
  ```

- [ ] Home directory is accessible
  ```bash
  ls /media/psf/Home/
  # Should list your macOS home directory contents
  ```

### 4. CDN Directory Access

- [ ] CDN directory accessible via full path
  ```bash
  ls /media/psf/Home/media/cdn/
  # Expected: Should list asset directories
  ```

- [ ] CDN symlink exists (recommended)
  ```bash
  ls -la ~/cdn
  # Expected: ~/cdn -> /media/psf/Home/media/cdn/
  ```

- [ ] Can list CDN contents
  ```bash
  ls ~/cdn/
  # Expected: assets/ branding/ logos/ projects/ etc.
  ```

### 5. Dev Directory Access

- [ ] Dev directory accessible
  ```bash
  ls /media/psf/Home/dev/
  # Expected: Your projects
  ```

- [ ] Dev symlink exists (optional)
  ```bash
  ls -la ~/dev-shared
  # Expected: ~/dev-shared -> /media/psf/Home/dev/
  ```

---

## File Operations

### 6. Read Access

- [ ] Can read files from CDN
  ```bash
  cat ~/cdn/.r2-manifest.yml | head -10
  # Should display manifest content
  ```

- [ ] Can list subdirectories
  ```bash
  ls ~/cdn/assets/
  ls ~/cdn/logos/
  # Should list files
  ```

- [ ] File metadata is correct
  ```bash
  file ~/cdn/logos/*.svg
  # Should show: SVG XML ...
  ```

### 7. Write Access

- [ ] Can create test file
  ```bash
  echo "test from VM" > ~/cdn/test-vm-write.txt
  # Should succeed without errors
  ```

- [ ] File visible on macOS
  ```bash
  # On macOS
  cat ~/media/cdn/test-vm-write.txt
  # Expected: test from VM
  ```

- [ ] Can delete file
  ```bash
  rm ~/cdn/test-vm-write.txt
  # On macOS: file should be gone
  ls ~/media/cdn/test-vm-write.txt
  # Expected: No such file or directory
  ```

- [ ] Can create directory
  ```bash
  mkdir ~/cdn/test-directory
  rmdir ~/cdn/test-directory
  # Should succeed
  ```

---

## R2 Assets Workflow

### 8. Central Manifest

- [ ] R2 manifest file exists
  ```bash
  ls -la ~/cdn/.r2-manifest.yml
  # Should show file with size
  ```

- [ ] Manifest is readable
  ```bash
  cat ~/cdn/.r2-manifest.yml | head -20
  # Should show YAML content
  ```

- [ ] Can parse manifest with yq (if installed)
  ```bash
  yq eval '.project' ~/cdn/.r2-manifest.yml
  # Expected: Project name

  yq eval '.assets | length' ~/cdn/.r2-manifest.yml
  # Expected: Number of assets
  ```

### 9. Asset Access

- [ ] Can access asset directories
  ```bash
  ls ~/cdn/assets/
  ls ~/cdn/logos/
  ls ~/cdn/projects/
  # All should list contents
  ```

- [ ] Can copy assets to project
  ```bash
  cp ~/cdn/logos/logo-main.svg /tmp/test-copy.svg
  ls -lh /tmp/test-copy.svg
  rm /tmp/test-copy.svg
  # Should work without errors
  ```

- [ ] Symlink strategy works
  ```bash
  ln -s ~/cdn/shared /tmp/test-symlink
  ls /tmp/test-symlink
  rm /tmp/test-symlink
  # Should work
  ```

---

## Project Setup

### 10. dev-setup.sh Template

- [ ] Template exists
  ```bash
  ls -la ~/dotfiles/templates/project/dev-setup.sh.template
  # Should exist
  ```

- [ ] Template is executable
  ```bash
  ls -l ~/dotfiles/templates/project/dev-setup.sh.template
  # Should show -rwxr-xr-x
  ```

### 11. Test Project Creation

- [ ] Can create test project
  ```bash
  mkdir -p ~/test-vm-project
  cd ~/test-vm-project
  cp ~/dotfiles/templates/project/dev-setup.sh.template ./dev-setup.sh
  chmod +x dev-setup.sh
  ```

- [ ] Project can access CDN
  ```bash
  ln -s ~/cdn/shared ~/test-vm-project/data
  ls ~/test-vm-project/data
  # Should show CDN shared contents
  ```

- [ ] Clean up test project
  ```bash
  rm -rf ~/test-vm-project
  ```

---

## Docker Integration

### 12. Docker Basic Functionality

- [ ] Docker installed
  ```bash
  docker --version
  # Expected: Docker version 24.0.X
  ```

- [ ] Docker service running
  ```bash
  systemctl status docker
  # Expected: active (running)
  ```

- [ ] Can run docker without sudo
  ```bash
  docker ps
  # Should work without "permission denied"
  ```

### 13. Docker with Shared Folders

- [ ] Can mount CDN in container (read-only)
  ```bash
  docker run --rm -v ~/cdn:/data:ro ubuntu:24.04 ls /data
  # Expected: Lists CDN contents
  ```

- [ ] Can mount CDN in container (read-write)
  ```bash
  docker run --rm -v ~/cdn:/data:rw ubuntu:24.04 touch /data/test-docker.txt
  rm ~/cdn/test-docker.txt
  # Should work
  ```

- [ ] Can mount specific subdirectory
  ```bash
  docker run --rm -v ~/cdn/logos:/data:ro ubuntu:24.04 ls /data
  # Expected: Lists logo files
  ```

### 14. Remote Docker Context (from macOS)

- [ ] Docker CLI installed on macOS
  ```bash
  # On macOS
  docker --version
  # Expected: Docker version X.X.X
  ```

- [ ] Remote context created
  ```bash
  # On macOS
  docker context ls | grep ubuntu-vm
  # Expected: ubuntu-vm context listed
  ```

- [ ] Can switch to remote context
  ```bash
  # On macOS
  docker context use ubuntu-vm
  docker ps
  # Should show VM containers
  ```

- [ ] Can run container remotely
  ```bash
  # On macOS
  docker run --rm ubuntu:24.04 echo "Hello from VM"
  # Expected: Hello from VM
  ```

- [ ] Switch back to local context
  ```bash
  # On macOS
  docker context use default
  ```

---

## Performance

### 15. Read Performance

- [ ] Read small file (< 1 second)
  ```bash
  time cat ~/cdn/README.md > /dev/null
  # Expected: real < 0.1s
  ```

- [ ] Read medium file (< 2 seconds)
  ```bash
  time cat ~/cdn/.r2-manifest.yml > /dev/null
  # Expected: real < 0.5s
  ```

- [ ] List large directory (< 2 seconds)
  ```bash
  time ls -R ~/cdn/ > /dev/null
  # Expected: real < 2s
  ```

### 16. Write Performance

- [ ] Write 1MB file (< 2 seconds)
  ```bash
  time dd if=/dev/zero of=~/cdn/test-1mb.dat bs=1M count=1
  rm ~/cdn/test-1mb.dat
  # Expected: real < 1s
  ```

- [ ] Create many small files (< 5 seconds)
  ```bash
  mkdir ~/cdn/test-many-files
  time for i in {1..100}; do echo "test" > ~/cdn/test-many-files/file-$i.txt; done
  rm -rf ~/cdn/test-many-files
  # Expected: real < 5s
  ```

---

## Automated Testing

### 17. Run Automated Test Script

- [ ] Test script exists
  ```bash
  ls -la ~/dotfiles/scripts/test/test-vm-integration.sh
  ```

- [ ] Run automated tests
  ```bash
  ~/dotfiles/scripts/test/test-vm-integration.sh
  ```

- [ ] All tests pass
  ```
  Expected output:
  ✅ Parallels Tools installed
  ✅ Parallels Tools service running
  ✅ Shared folders mounted
  ✅ CDN directory accessible
  ✅ Read access to CDN
  ✅ Write access to CDN
  ✅ CDN symlink exists
  ✅ Dev directory accessible
  ✅ R2 manifest readable
  ✅ Docker service running
  ✅ Docker can mount CDN

  [✅ PASS] All tests passed! ✨
  ```

- [ ] Verbose output works (if needed)
  ```bash
  ~/dotfiles/scripts/test/test-vm-integration.sh --verbose
  ```

---

## Final Verification

### 18. Complete Workflow Test

- [ ] Clone a real project from GitHub
  ```bash
  cd ~/dev-shared
  git clone https://github.com/your-username/your-project.git
  cd your-project
  ```

- [ ] Access project assets from CDN
  ```bash
  ls ~/cdn/projects/your-project/
  # Should show project-specific assets
  ```

- [ ] Run project dev-setup (if exists)
  ```bash
  ./dev-setup.sh
  # Should complete successfully
  ```

- [ ] Test Docker workflow
  ```bash
  docker compose up -d  # if project has docker-compose.yml
  docker ps
  # Containers should be running
  ```

---

## Troubleshooting Reference

If any test fails, refer to:
- [VM Setup Guide - Troubleshooting](../vm-setup.md#troubleshooting)
- [Parallels VM Creation Guide](../guides/parallels-vm-creation.md#troubleshooting)

**Common Issues**:
1. **Shared folders not visible** → Restart Parallels Tools
2. **Permission denied** → Check Parallels sharing permissions
3. **Symlink broken** → Recreate with correct path
4. **Docker can't mount** → Use absolute paths
5. **Slow performance** → Enable "Faster virtual machine" mode

---

## Checklist Summary

**Total Checks**: ~75 individual verification points

**Critical Items** (must pass):
- ✅ Parallels Tools installed and running
- ✅ Shared folders accessible
- ✅ Can read files from CDN
- ✅ Can write files to CDN
- ✅ Docker can mount shared folders

**Optional Items** (nice to have):
- Symlinks created for convenience
- Remote Docker context configured
- Performance within acceptable range

**Sign-off**:
- [ ] All critical items passing
- [ ] Setup ready for production use
- [ ] Documentation reviewed and understood

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Issue**: [#23](https://github.com/matteocervelli/dotfiles/issues/23)
**Status**: Ready for testing
