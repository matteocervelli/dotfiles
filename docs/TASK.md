# Dotfiles Project - Task List

**Project**: Personal Dotfiles Management System
**Version**: 2.0 (Refactored)
**Date**: 2025-01-17
**Status**: FASE 1-2 Ready for Implementation

---

## 🎯 GitHub Project Management

**Repository**: [matteocervelli/dotfiles](https://github.com/matteocervelli/dotfiles)

### Milestones

| Phase | Milestone | Due Date | Issues |
|-------|-----------|----------|--------|
| ✅ FASE 0 | [Documentation & Refactor](https://github.com/matteocervelli/dotfiles/milestone/1) | 2025-01-17 | 0/0 (Closed) |
| 🟡 FASE 1 | [Foundation](https://github.com/matteocervelli/dotfiles/milestone/2) | 2025-01-24 | [#1-#12](https://github.com/matteocervelli/dotfiles/milestone/2) |
| ⚪ FASE 2 | [Secrets & Sync](https://github.com/matteocervelli/dotfiles/milestone/3) | 2025-01-31 | [#13-#18](https://github.com/matteocervelli/dotfiles/milestone/3) |
| ⚪ FASE 3 | [Applications & XDG](https://github.com/matteocervelli/dotfiles/milestone/4) | 2025-02-07 | [#19-#21](https://github.com/matteocervelli/dotfiles/milestone/4) |
| ⚪ FASE 4 | [VM Ubuntu Setup](https://github.com/matteocervelli/dotfiles/milestone/5) | 2025-02-14 | [#22-#23](https://github.com/matteocervelli/dotfiles/milestone/5) |
| ⚪ FASE 5 | [Templates & Automation](https://github.com/matteocervelli/dotfiles/milestone/6) | 2025-02-21 | [#24-#25](https://github.com/matteocervelli/dotfiles/milestone/6) |
| ⚪ FASE 6 | [Monitoring & Polish](https://github.com/matteocervelli/dotfiles/milestone/7) | 2025-02-28 | [#26-#27](https://github.com/matteocervelli/dotfiles/milestone/7) |

### Quick Links

- 📋 [All Issues](https://github.com/matteocervelli/dotfiles/issues)
- 🎯 [All Milestones](https://github.com/matteocervelli/dotfiles/milestones)
- 📊 [Project Board](https://github.com/matteocervelli/dotfiles/projects)

---

## Status Overview

- 📋 **Completed**: FASE 0 - Documentation & Refactor ([Milestone #1](https://github.com/matteocervelli/dotfiles/milestone/1))
- 🟡 **Ready to Start**: FASE 1 - Foundation ([Issues #1-#12](https://github.com/matteocervelli/dotfiles/milestone/2))
- ⚪ **Pending**: FASE 2 - Secrets & Sync ([Issues #13-#18](https://github.com/matteocervelli/dotfiles/milestone/3))
- ⚪ **Pending**: FASE 3 - Applications & XDG Compliance ([Issues #19-#21](https://github.com/matteocervelli/dotfiles/milestone/4))
- ⚪ **Pending**: FASE 4 - VM Ubuntu Setup ([Issues #22-#23](https://github.com/matteocervelli/dotfiles/milestone/5))
- ⚪ **Pending**: FASE 5 - Templates & Automation ([Issues #24-#25](https://github.com/matteocervelli/dotfiles/milestone/6))
- ⚪ **Pending**: FASE 6 - Monitoring & Polish ([Issues #26-#27](https://github.com/matteocervelli/dotfiles/milestone/7))

---

## FASE 0: Documentation & Repository Refactor ✅

**Obiettivo**: Document all architectural decisions and prepare clean repository

**Duration**: 2 hours
**Priority**: Critical ⚡

### 0.1 Archive Obsolete Content ✅

- [x] **0.1.1** Move old docs to `.archive/` (screenshot docs, old scans)
- [x] **0.1.2** Review existing content for reuse
- [x] **0.1.3** Identify files to keep vs remove

### 0.2 Create Core Documentation ✅

- [x] **0.2.1** Create `ARCHITECTURE-DECISIONS.md` with all design choices
- [x] **0.2.2** Create `IMPLEMENTATION-PLAN.md` with detailed FASE 1-2 plan
- [x] **0.2.3** Update `TASK.md` (this file) with new structure
- [x] **0.2.4** Create `REFACTOR-NOTES.md` documenting cleanup decisions

**Status**: ✅ COMPLETED

---

## FASE 1: Foundation

**Obiettivo**: Establish base infrastructure for dotfiles management
**Duration**: 6-8 hours
**Priority**: Critical ⚡

### 1.1 Backup and Audit ✅

- [x] **1.1.1** Create backup of current repo state in `backups/pre-refactor-20251017/`
- [x] **1.1.2** Audit existing content (packages, scripts, docs)
- [x] **1.1.3** Document decisions in `docs/REFACTOR-NOTES.md`

**Completed**: 2025-10-17
**Status**: ✅ All tasks completed, audit findings documented

### 1.2 Directory Structure ✅

- [x] **1.2.1** Create complete directory structure per IMPLEMENTATION-PLAN.md
- [x] **1.2.2** Verify all required directories exist
- [x] **1.2.3** Test structure with `find` commands

**Completed**: 2025-01-17
**Status**: ✅ All 60+ directories created and verified

### 1.3 Configuration Files

- [ ] **1.3.1** Update `.gitignore` with comprehensive patterns
- [ ] **1.3.2** Create `.stow-local-ignore` with proper exclusions
- [ ] **1.3.3** Test both files with `git status` and `stow -n`

### 1.4 Utility Scripts ✅

- [x] **1.4.1** Create `scripts/utils/detect-os.sh` (OS detection)
- [x] **1.4.2** Create `scripts/utils/logger.sh` (logging functions)
- [x] **1.4.3** Make scripts executable and test

**Completed**: 2025-01-17
**Status**: ✅ All utility scripts implemented with macOS, Linux, and Windows detection support

### 1.5 Bootstrap Scripts

- [ ] **1.5.1** Create `scripts/bootstrap/macos-bootstrap.sh` (Homebrew, Stow, 1Password CLI, Rclone, yq)
- [ ] **1.5.2** Create `scripts/bootstrap/ubuntu-bootstrap.sh` (apt, Stow, 1Password CLI, Rclone, yq)
- [ ] **1.5.3** Create `scripts/bootstrap/install.sh` (master orchestrator)
- [ ] **1.5.4** Test bootstrap on macOS

### 1.6 Stow Packages (Priority 5)

#### Package 1: shell ✅
- [x] **1.6.1** Create `stow-packages/shell/` structure
- [x] **1.6.2** Create `.zshrc` with Oh My Zsh (32 plugins optimized)
- [x] **1.6.3** Create `.bashrc` for Ubuntu
- [x] **1.6.4** Create modular configs in `.config/shell/` (aliases, exports, functions, postgres, ollama, hugo, macos)
- [x] **1.6.5** Test shell package and deploy with stow
- [x] **1.6.6** Add `.p10k.zsh` Powerlevel10k configuration (1837 lines)
- [x] **1.6.7** Clean up duplicate files from `~/.oh-my-zsh/custom/`
- [x] **1.6.8** Extend `macos-bootstrap.sh` with Oh My Zsh and plugin installation
- [x] **1.6.9** Create `.stow-local-ignore` at package level
- [x] **1.6.10** Move `deploy-shell.sh` to `scripts/` directory

**Completed**: 2025-10-18
**Status**: ✅ Shell package fully implemented, cleaned, and production-ready
**Details**:
- 2,593 lines across 11 files (including .p10k.zsh)
- 32 ZSH plugins with OS detection
- Cross-platform support (macOS, Ubuntu)
- Bootstrap script with Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting, Powerlevel10k
- Verified symlinks: .zshrc, .bashrc, .p10k.zsh, .config/shell/

#### Package 2: git
- [ ] **1.6.6** Create `stow-packages/git/` structure
- [ ] **1.6.7** Create `.gitconfig` with user info and aliases
- [ ] **1.6.8** Create `.gitignore_global`
- [ ] **1.6.9** Create `.git-templates/hooks/`
- [ ] **1.6.10** Test git package

#### Package 3: ssh
- [ ] **1.6.11** Create `stow-packages/ssh/` structure
- [ ] **1.6.12** Create `.ssh/config` with Include directive
- [ ] **1.6.13** Create `.ssh/config.d/tailscale.conf` (Tailscale network)
- [ ] **1.6.14** Create `.ssh/config.d/github.conf`
- [ ] **1.6.15** Test ssh package

#### Package 4: 1password
- [ ] **1.6.16** Create `stow-packages/1password/.config/op/` directory
- [ ] **1.6.17** Add .gitkeep (config is auto-generated)
- [ ] **1.6.18** Test 1password package

**Note**: llm-tools package has been moved to FASE 3.5 for better logical separation with other application configurations.

### 1.7 Stow Automation

- [ ] **1.7.1** Create `scripts/stow/stow-all.sh` (stow all packages)
- [ ] **1.7.2** Create `scripts/stow/stow-package.sh` (stow single package)
- [ ] **1.7.3** Create `scripts/stow/unstow-all.sh` (remove symlinks)
- [ ] **1.7.4** Test stow scripts

### 1.8 Health Checks

- [ ] **1.8.1** Create `scripts/health/check-stow.sh` (verify symlinks)
- [ ] **1.8.2** Create `scripts/health/check-all.sh` (verify dependencies + symlinks)
- [ ] **1.8.3** Test health check scripts

### 1.9 Makefile

- [ ] **1.9.1** Create `Makefile` with targets: install, stow, unstow, health, backup, clean
- [ ] **1.9.2** Test all Makefile targets

**Acceptance Criteria**:
- ✅ `make install` completes without errors
- ✅ All 5 packages stowed correctly
- ✅ `make health` passes all checks
- ✅ Symlinks point to correct dotfiles locations

---

## FASE 2: Secrets & Sync

**Obiettivo**: Implement secret management and R2 asset synchronization
**Duration**: 4-6 hours
**Priority**: Critical ⚡

### 2.1 1Password CLI Integration

- [ ] **2.1.1** Create `scripts/secrets/inject-env.sh` (op inject wrapper)
- [ ] **2.1.2** Create `scripts/secrets/validate-secrets.sh` (verify no remaining op:// refs)
- [ ] **2.1.3** Create `secrets/template.env` (standard template)
- [ ] **2.1.4** Create `secrets/docker-compose-op.yml` (example)
- [ ] **2.1.5** Test secret injection with 1Password

### 2.2 Project Setup Script Template

- [ ] **2.2.1** Create `templates/project/dev-setup.sh.template` (standard project setup)
- [ ] **2.2.2** Create `templates/project/README.md` (usage docs)
- [ ] **2.2.3** Test template by copying to test project

### 2.3 Rclone Setup

- [ ] **2.3.1** Create `sync/rclone/rclone.conf.template`
- [ ] **2.3.2** Create `scripts/sync/setup-rclone.sh` (configure R2 from 1Password)
- [ ] **2.3.3** Test rclone configuration (`rclone lsd r2:`)

### 2.4 Manifest System

- [ ] **2.4.1** Create `sync/manifests/schema.yml` (YAML schema)
- [ ] **2.4.2** Create `sync/manifests/README.md` (manifest documentation)
- [ ] **2.4.3** Document manifest workflow

### 2.5 R2 Sync Scripts

- [ ] **2.5.1** Create `scripts/sync/generate-manifest.sh` (scan data/ and generate YAML)
- [ ] **2.5.2** Create `scripts/sync/sync-r2.sh` (pull/push assets)
- [ ] **2.5.3** Create `scripts/sync/update-manifest.sh` (update timestamps)
- [ ] **2.5.4** Test R2 sync with test project

### 2.6 Auto-Update Dotfiles

- [ ] **2.6.1** Create `scripts/sync/auto-update-dotfiles.sh` (commit + push changes)
- [ ] **2.6.2** Create `system/macos/launch-agents/com.dotfiles.autoupdate.plist` (LaunchAgent)
- [ ] **2.6.3** Create `system/ubuntu/systemd/dotfiles-autoupdate.{service,timer}` (systemd)
- [ ] **2.6.4** Create `scripts/sync/install-autoupdate.sh` (install LaunchAgent/timer)
- [ ] **2.6.5** Test auto-update mechanism

**Acceptance Criteria**:
- ✅ `op inject` works with .env.template
- ✅ Rclone configured for R2
- ✅ Manifest generation works
- ✅ R2 pull/push works
- ✅ Auto-update commits and pushes changes every 30min

---

## FASE 3: Applications & XDG Compliance

**Obiettivo**: Application management and config consolidation
**Duration**: 6-8 hours
**Priority**: High 🔥

### 3.1 Application Audit

- [ ] **3.1.1** Create `scripts/apps/audit-apps.sh` (list Homebrew, mas, /Applications)
- [ ] **3.1.2** Run audit and save to `applications/current-apps.txt`
- [ ] **3.1.3** Manually review and create `applications/keep-apps.txt` and `applications/remove-apps.txt`

### 3.2 Brewfile Management

- [ ] **3.2.1** Create `system/macos/Brewfile` from audit
- [ ] **3.2.2** Organize by categories (dev, apps, fonts)
- [ ] **3.2.3** Include mas apps
- [ ] **3.2.4** Test Brewfile installation

### 3.3 Application Cleanup

- [ ] **3.3.1** Create `scripts/apps/cleanup-apps.sh` (remove unwanted apps)
- [ ] **3.3.2** Test cleanup script with dry-run
- [ ] **3.3.3** Run actual cleanup

### 3.4 XDG Compliance

- [ ] **3.4.1** Create `scripts/xdg-compliance/app-mappings.yml` (per-app decisions)
- [ ] **3.4.2** Document XDG compliance strategy in `docs/xdg-compliance.md`
- [ ] **3.4.3** Implement redirects for compatible apps (case-by-case)

### 3.5 Additional Stow Packages

#### Package: cursor
- [ ] **3.5.1** Create `stow-packages/cursor/` with settings.json, keybindings.json
- [ ] **3.5.2** Create `applications/cursor-extensions.txt`
- [ ] **3.5.3** Test cursor package

#### Package: iterm2
- [ ] **3.5.4** Create `stow-packages/iterm2/` with iTerm2 configs
- [ ] **3.5.5** Handle XDG compliance (symlink vs original location)
- [ ] **3.5.6** Test iterm2 package

#### Package: dev-env
- [ ] **3.5.7** Create `stow-packages/dev-env/` for pyenv, nvm, docker configs
- [ ] **3.5.8** Test dev-env package

#### Package: llm-tools
- [ ] **3.5.9** Create `stow-packages/llm-tools/` structure
- [ ] **3.5.10** Migrate Claude Code configs to `.config/claude/`
- [ ] **3.5.11** Migrate MCP server configs to `.config/mcp/`
- [ ] **3.5.12** Document MCP server configurations
- [ ] **3.5.13** Test llm-tools package

**Note**: This package was moved from FASE 1.6 to better align with application configurations in FASE 3.

**Acceptance Criteria**:
- ✅ Brewfile installs all required apps
- ✅ Unwanted apps removed
- ✅ XDG compliance documented and implemented
- ✅ Additional stow packages working

---

## FASE 4: VM Ubuntu Setup

**Obiettivo**: Configure Ubuntu VMs for Docker workloads
**Duration**: 4-6 hours
**Priority**: High 🔥

### 4.1 Ubuntu Bootstrap

- [ ] **4.1.1** Test `scripts/bootstrap/ubuntu-bootstrap.sh` on Ubuntu VM
- [ ] **4.1.2** Verify all dependencies install correctly

### 4.2 Docker Setup

- [ ] **4.2.1** Create script to install Docker + docker-compose on Ubuntu
- [ ] **4.2.2** Test Docker installation
- [ ] **4.2.3** Configure Docker to start on boot

### 4.3 VM-Specific Configs

- [ ] **4.3.1** Create Ubuntu-specific stow packages (if needed)
- [ ] **4.3.2** Test stow packages on Ubuntu VM

### 4.4 Parallels Integration

- [ ] **4.4.1** Document Parallels bind mount setup in `docs/vm-setup.md`
- [ ] **4.4.2** Test bind mount of `~/r2-assets/` from macOS to VM
- [ ] **4.4.3** Verify R2 assets accessible in VM

### 4.5 Cross-Platform Testing

- [ ] **4.5.1** Test dotfiles installation on Ubuntu VM
- [ ] **4.5.2** Test project dev-setup.sh on VM
- [ ] **4.5.3** Verify Docker workflows

**Acceptance Criteria**:
- ✅ Ubuntu VM has all dependencies
- ✅ Docker works natively
- ✅ Parallels mount functional
- ✅ Dotfiles work cross-platform

---

## FASE 5: Templates & Automation

**Obiettivo**: Project boilerplates and advanced automation
**Duration**: 6-8 hours
**Priority**: Medium 🔶

### 5.1 Project Templates

- [ ] **5.1.1** Create `templates/python-project/` boilerplate
- [ ] **5.1.2** Create `templates/nextjs-project/` boilerplate
- [ ] **5.1.3** Create `templates/swift-project/` boilerplate
- [ ] **5.1.4** Create template generation script

### 5.2 Advanced Health Checks

- [ ] **5.2.1** Create health checks for secrets (no op:// refs)
- [ ] **5.2.2** Create health checks for R2 sync (verify checksums)
- [ ] **5.2.3** Create health checks for symlinks (detect conflicts)

### 5.3 Config Update Mechanism

- [ ] **5.3.1** Create script to pull configs from system back into repo
- [ ] **5.3.2** Create diff/compare tool for configs between machines
- [ ] **5.3.3** Implement rollback mechanism

### 5.4 Testing

- [ ] **5.4.1** Create automated tests for install.sh
- [ ] **5.4.2** Test on fresh macOS installation
- [ ] **5.4.3** Test on fresh Ubuntu VM

**Acceptance Criteria**:
- ✅ Templates generate working projects
- ✅ Advanced health checks detect issues
- ✅ Update mechanism works bidirectionally

---

## FASE 6: Monitoring & Polish

**Obiettivo**: Integration with existing infrastructure and finalization
**Duration**: 4-6 hours
**Priority**: Low 🟢

### 6.1 Syncthing Evaluation

- [ ] **6.1.1** Test Syncthing between Mac Studio and MacBook
- [ ] **6.1.2** Decide if needed (vs auto-update)
- [ ] **6.1.3** Implement if beneficial

### 6.2 Backup Automation

- [ ] **6.2.1** Create `scripts/backup/sync-to-nas.sh` (backup to Synology)
- [ ] **6.2.2** Create `scripts/backup/restore-from-nas.sh`
- [ ] **6.2.3** Schedule daily NAS backups

### 6.3 Alertmanager Integration (Future)

- [ ] **6.3.1** Document integration points with monitoring stack
- [ ] **6.3.2** Plan health check alerting (deferred to later)

### 6.4 Documentation Finalization

- [ ] **6.4.1** Create comprehensive README.md
- [ ] **6.4.2** Finalize all docs/ documentation
- [ ] **6.4.3** Create troubleshooting guide
- [ ] **6.4.4** Screenshot documentation (if needed)

### 6.5 Public/Private Split (Optional)

- [ ] **6.5.1** Evaluate if any dotfiles can be open-sourced
- [ ] **6.5.2** Split sensitive configs if desired

**Acceptance Criteria**:
- ✅ Complete documentation
- ✅ Backup strategy implemented
- ✅ System production-ready

---

## Milestone Tracking

### 🎯 Milestone 0: Documentation Complete ✅

**Status**: ✅ COMPLETED
**Date**: 2025-01-17
**Criteria**: All architectural decisions documented, implementation plan ready

### 🎯 Milestone 1: Foundation Complete

**Status**: 🟡 READY TO START
**Target**: FASE 1 completion
**Criteria**:
- Directory structure complete
- Bootstrap scripts working
- 5 priority stow packages functional
- Health checks passing

### 🎯 Milestone 2: Secrets & Sync Complete

**Status**: ⚪ PENDING
**Target**: FASE 2 completion
**Criteria**:
- 1Password integration working
- R2 sync functional
- Auto-update enabled

### 🎯 Milestone 3: Applications & XDG Complete

**Status**: ⚪ PENDING
**Target**: FASE 3 completion
**Criteria**:
- Brewfile manages all apps
- XDG compliance implemented
- Additional stow packages ready

### 🎯 Milestone 4: VM Setup Complete

**Status**: ⚪ PENDING
**Target**: FASE 4 completion
**Criteria**:
- Ubuntu VM fully configured
- Docker working natively
- Cross-platform tested

### 🎯 Milestone 5: Automation Complete

**Status**: ⚪ PENDING
**Target**: FASE 5 completion
**Criteria**:
- Project templates ready
- Advanced automation functional
- Testing complete

### 🎯 Milestone 6: Production Ready

**Status**: ⚪ PENDING
**Target**: FASE 6 completion
**Criteria**:
- Complete documentation
- Backup strategy implemented
- System tested and polished

---

## Decision Log

| Date | Decision | Status | Reference |
|------|----------|--------|-----------|
| 2025-01-17 | XDG Compliance: Hybrid approach | ✅ Approved | ARCHITECTURE-DECISIONS.md |
| 2025-01-17 | Bootstrap: Modular scripts + Makefile | ✅ Approved | ARCHITECTURE-DECISIONS.md |
| 2025-01-17 | Secrets: 1Password CLI only | ✅ Approved | ARCHITECTURE-DECISIONS.md |
| 2025-01-17 | R2: Single bucket | ✅ Approved | ARCHITECTURE-DECISIONS.md |
| 2025-01-17 | VM: Git clone + bind mount | ✅ Approved | ARCHITECTURE-DECISIONS.md |
| 2025-01-17 | Sync: Auto-update to GitHub | ✅ Approved | ARCHITECTURE-DECISIONS.md |
| 2025-01-17 | Backup: Multi-layer (GitHub + NAS + Time Machine) | ✅ Approved | ARCHITECTURE-DECISIONS.md |
| 2025-01-17 | Manifest: YAML format | ✅ Approved | ARCHITECTURE-DECISIONS.md |

---

## Quick Reference

### Current Status
- **Phase**: FASE 0 ✅ Complete, FASE 1 🟡 Ready to Start
- **Next Action**: Begin FASE 1.1 (Backup and Audit)
- **Blockers**: None

### Key Documents
- [ARCHITECTURE-DECISIONS.md](ARCHITECTURE-DECISIONS.md) - All design choices
- [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md) - Detailed execution plan
- [REFACTOR-NOTES.md](REFACTOR-NOTES.md) - Refactor decisions and cleanup
- [new-list.md](new-list.md) - Original requirements list

### Installation Commands
```bash
# Full installation
make install

# Individual operations
make stow           # Stow all packages
make unstow         # Remove symlinks
make health         # Health checks
make backup         # Backup configs
```

### R2 Sync Commands
```bash
# Setup
./scripts/sync/setup-rclone.sh

# Project operations
./scripts/sync/generate-manifest.sh PROJECT
./scripts/sync/sync-r2.sh pull PROJECT
./scripts/sync/sync-r2.sh push PROJECT --path FILE
```

---

**Created**: 2024-12-06 (Original)
**Refactored**: 2025-01-17 (Complete rewrite)
**Last Updated**: 2025-01-17
**Status**: FASE 0 ✅ Complete | FASE 1 🟡 Ready to Start
