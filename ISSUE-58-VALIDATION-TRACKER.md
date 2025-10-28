# Issue #58 Validation Tracker

**Date**: 2025-10-28
**Validator**: Matteo Cervelli
**Hardware**: Mac Studio M2 Max
**VM**: fedora-dev4change

---

## Validation Checklist

### Pre-Flight (5 min)
- [ ] Mac Studio resources checked (100GB+ free, Parallels installed)
- [ ] Fedora 41 ARM64 ISO downloaded (~2.3 GB)
- [ ] Documentation opened (Guide 4, Guide 5, Issue #58)
- [ ] Note-taking setup ready

**Start Time**: ________________

---

### Phase 1: VM Creation (20-30 min)
- [ ] VM created in Parallels with correct specs
  - Name: `fedora-dev4change`
  - CPU: 6 vCPU, Adaptive Hypervisor ON, Nested Virtualization ON
  - RAM: 12 GB, Balloon memory ON
  - Disk: 100 GB, Expanding
  - Network: Shared Network
- [ ] Fedora installed successfully
  - Username: `matteocervelli`
  - Hostname: `fedora-dev4change`
  - Administrator account created
- [ ] First boot successful

**Phase 1 Start**: ________________
**Phase 1 End**: ________________
**Duration**: _______ minutes

**Issues/Notes**:
_________________________________________________
_________________________________________________

---

### Phase 2: Initial Configuration (20 min)
- [ ] GNOME initial setup completed
- [ ] System updated (`sudo dnf upgrade -y`)
- [ ] Build tools installed for Parallels Tools
- [ ] Parallels Tools installed successfully
- [ ] Clipboard sync works (Mac ↔ VM)
- [ ] Display resize works
- [ ] Full screen works

**Phase 2 Start**: ________________
**Phase 2 End**: ________________
**Duration**: _______ minutes

**Parallels Tools Version**: ________________

**Issues/Notes**:
_________________________________________________
_________________________________________________

---

### Phase 3: Bootstrap Installation (15 min)
- [ ] Dotfiles cloned from GitHub
- [ ] Bootstrap script ran: `./scripts/bootstrap/fedora-bootstrap.sh --vm-essentials`
- [ ] ZSH is default shell
- [ ] Stow packages deployed (.zshrc, .gitconfig)
- [ ] 1Password CLI installed and working
- [ ] rclone installed and working

**Phase 3 Start**: ________________
**Phase 3 End**: ________________
**Duration**: _______ minutes

**Issues/Notes**:
_________________________________________________
_________________________________________________

---

### Phase 4: Docker Installation (10 min)
- [ ] Docker script ran: `./scripts/bootstrap/install-docker-fedora.sh`
- [ ] Podman removed successfully
- [ ] Docker Engine installed
- [ ] Docker Compose v2 installed
- [ ] SELinux configured for containers
- [ ] firewalld configured for Docker
- [ ] User added to docker group
- [ ] Logged out and back in for group activation
- [ ] `docker ps` works WITHOUT sudo
- [ ] `docker run hello-world` successful

**Phase 4 Start**: ________________
**Phase 4 End**: ________________
**Duration**: _______ minutes

**Docker Version**: ________________
**Compose Version**: ________________

**Issues/Notes**:
_________________________________________________
_________________________________________________

---

### Phase 5: Shared Folders (15 min)
- [ ] Shared folders configured in Parallels (~/dev, ~/media/cdn)
- [ ] `/media/psf/Home/dev/` accessible from VM
- [ ] `/media/psf/Home/media/cdn/` accessible from VM
- [ ] Symlinks created (~/ dev-shared, ~/cdn-shared)
- [ ] Docker can mount shared folders
- [ ] Test container accessed shared folder successfully

**Phase 5 Start**: ________________
**Phase 5 End**: ________________
**Duration**: _______ minutes

**Issues/Notes**:
_________________________________________________
_________________________________________________

---

### Phase 6: Remote Docker Context (10 min)
- [ ] VM IP address noted: ________________
- [ ] SSH connection from Mac successful
- [ ] SSH key copied (passwordless login)
- [ ] Docker context created on Mac: `fedora-dev4change`
- [ ] Remote Docker commands work from Mac
- [ ] `docker info` shows "Fedora Linux 41"
- [ ] Can switch between local and remote contexts

**Phase 6 Start**: ________________
**Phase 6 End**: ________________
**Duration**: _______ minutes

**Issues/Notes**:
_________________________________________________
_________________________________________________

---

### Phase 7: Complete Verification (10 min)
- [ ] All system checks passed (Fedora version, hostname, etc.)
- [ ] Parallels Tools working
- [ ] Shared folders accessible
- [ ] ZSH default shell
- [ ] Dotfiles deployed
- [ ] Docker working
- [ ] Docker with shared folders working
- [ ] Network connectivity good
- [ ] Resources adequate (disk, RAM, CPU)

**Phase 7 Start**: ________________
**Phase 7 End**: ________________
**Duration**: _______ minutes

**Issues/Notes**:
_________________________________________________
_________________________________________________

---

## Summary

**Total Time**: _______ minutes (Goal: < 120 minutes)

**Success Criteria Met?**
- [ ] Complete setup < 2 hours: **YES / NO** (Actual: _____ min)
- [ ] All services operational: **YES / NO**

---

## Issues Found

### Critical Issues (Blockers)
1. _________________________________________________
2. _________________________________________________

### Minor Issues (Annoyances)
1. _________________________________________________
2. _________________________________________________

### Documentation Issues
**Guide 4 Corrections Needed:**
- _________________________________________________

**Guide 5 Corrections Needed:**
- _________________________________________________

---

## Guide Feedback

### What Worked Well
- _________________________________________________
- _________________________________________________

### What Could Be Improved
- _________________________________________________
- _________________________________________________

### Missing Information
- _________________________________________________
- _________________________________________________

---

## Recommendations

### For Future Users
- _________________________________________________
- _________________________________________________

### For Guide Updates
- _________________________________________________
- _________________________________________________

---

## Next Steps

- [ ] Update Issue #58 with validation results
- [ ] Create new issues for any bugs found
- [ ] Update guides with corrections (if needed)
- [ ] Take VM snapshot: "Fedora Dev - Validated"
- [ ] Close Issue #58 if validation successful

---

## Notes

_________________________________________________
_________________________________________________
_________________________________________________
_________________________________________________

---

**Validation Status**: [ ] In Progress  [ ] Complete  [ ] Failed

**Final Decision**: [ ] Guides Approved  [ ] Needs Revisions
