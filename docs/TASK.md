# Dotfiles Project - Task List

**Project**: Personal Dotfiles Management System
**Version**: 2.0 (Refactored)
**Date**: 2025-01-17
**Status**: FASE 1-2 Ready for Implementation

---

## 🎯 GitHub Project Management

**Repository**: [matteocervelli/dotfiles](https://github.com/matteocervelli/dotfiles)

### Milestones

| Phase | Milestone | Due Date | Issues | Status |
|-------|-----------|----------|--------|--------|
| ✅ FASE 0 | [Documentation & Refactor](https://github.com/matteocervelli/dotfiles/milestone/1) | 2025-01-17 | 0/0 | **CLOSED** |
| ✅ FASE 1 | [Foundation](https://github.com/matteocervelli/dotfiles/milestone/2) | 2025-01-24 | 12/12 | **CLOSED** 2025-10-21 |
| ✅ FASE 2 | [Secrets & Sync](https://github.com/matteocervelli/dotfiles/milestone/3) | 2025-01-31 | [#13-#34](https://github.com/matteocervelli/dotfiles/milestone/3) | **CLOSED** 2025-01-25 |
| ⚪ FASE 3 | [Applications & XDG](https://github.com/matteocervelli/dotfiles/milestone/4) | 2025-02-07 | [#19-#21](https://github.com/matteocervelli/dotfiles/milestone/4) | Pending |
| ⚪ FASE 4 | [VM Ubuntu Setup](https://github.com/matteocervelli/dotfiles/milestone/5) | 2025-02-14 | [#22-#23](https://github.com/matteocervelli/dotfiles/milestone/5) | Pending |
| ⚪ FASE 5 | [Templates & Automation](https://github.com/matteocervelli/dotfiles/milestone/6) | 2025-02-21 | [#24-#25](https://github.com/matteocervelli/dotfiles/milestone/6) | Pending |
| ⚪ FASE 6 | [Monitoring & Polish](https://github.com/matteocervelli/dotfiles/milestone/7) | 2025-02-28 | [#26-#27](https://github.com/matteocervelli/dotfiles/milestone/7) | Pending |

### Quick Links

- 📋 [All Issues](https://github.com/matteocervelli/dotfiles/issues)
- 🎯 [All Milestones](https://github.com/matteocervelli/dotfiles/milestones)
- 📊 [Project Board](https://github.com/matteocervelli/dotfiles/projects)

---

## Status Overview

- ✅ **Completed**: FASE 0 - Documentation & Refactor ([Milestone #1](https://github.com/matteocervelli/dotfiles/milestone/1))
- ✅ **Completed**: FASE 1 - Foundation ([Milestone #2](https://github.com/matteocervelli/dotfiles/milestone/2)) - **CLOSED 2025-10-21**
- ✅ **Completed**: FASE 2 - Secrets & Sync ([Milestone #3](https://github.com/matteocervelli/dotfiles/milestone/3)) - **CLOSED 2025-01-25**
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

## FASE 1: Foundation ✅

**Obiettivo**: Establish base infrastructure for dotfiles management
**Duration**: 6-8 hours
**Priority**: Critical ⚡
**Status**: ✅ **COMPLETED** 2025-10-21 | [Milestone #2](https://github.com/matteocervelli/dotfiles/milestone/2) CLOSED | All 12 issues resolved

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

### 1.3 Configuration Files ✅

- [x] **1.3.1** Update `.gitignore` with comprehensive patterns
- [x] **1.3.2** Create `.stow-local-ignore` with proper exclusions
- [x] **1.3.3** Test both files with `git status` and `stow -n`

**Completed**: 2025-10-17
**Status**: ✅ All configuration files created and tested

### 1.4 Utility Scripts ✅

- [x] **1.4.1** Create `scripts/utils/detect-os.sh` (OS detection)
- [x] **1.4.2** Create `scripts/utils/logger.sh` (logging functions)
- [x] **1.4.3** Make scripts executable and test

**Completed**: 2025-01-17
**Status**: ✅ All utility scripts implemented with macOS, Linux, and Windows detection support

### 1.5 Bootstrap Scripts ✅

- [x] **1.5.1** Create `scripts/bootstrap/macos-bootstrap.sh` (Homebrew, Stow, 1Password CLI, Rclone, yq)
- [x] **1.5.2** Create `scripts/bootstrap/ubuntu-bootstrap.sh` (apt, Stow, 1Password CLI, Rclone, yq)
- [x] **1.5.3** Create `scripts/bootstrap/install.sh` (master orchestrator)
- [x] **1.5.4** Test bootstrap on macOS

**Completed**: 2025-10-17
**Status**: ✅ All bootstrap scripts implemented and tested

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

#### Package 2: git ✅
- [x] **1.6.6** Create `stow-packages/git/` structure
- [x] **1.6.7** Create `.gitconfig` with user info and aliases
- [x] **1.6.8** Create `.gitignore_global`
- [x] **1.6.9** Create `.git-templates/hooks/`
- [x] **1.6.10** Test git package

**Completed**: 2025-10-20
**Status**: ✅ Git package fully implemented with 1Password SSH signing, 30+ aliases, cross-platform support

#### Package 3: ssh ✅
- [x] **1.6.11** Create `stow-packages/ssh/` structure
- [x] **1.6.12** Create `.ssh/config` with Include directive
- [x] **1.6.13** Create `.ssh/config.d/tailscale.conf` (Tailscale network)
- [x] **1.6.14** Create `.ssh/config.d/github.conf`
- [x] **1.6.15** Test ssh package

**Completed**: 2025-10-20
**Status**: ✅ SSH package fully implemented with Tailscale network, GitHub config, 1Password agent integration

#### Package 4: 1password ✅
- [x] **1.6.16** Create `stow-packages/1password/.config/op/` directory
- [x] **1.6.17** Add .gitkeep (config is auto-generated)
- [x] **1.6.18** Test 1password package

**Completed**: 2025-10-19
**Status**: ✅ 1Password package created (configuration auto-generated by CLI)

**Note**: llm-tools package has been moved to FASE 3.5 for better logical separation with other application configurations.

### 1.7 Stow Automation ✅

- [x] **1.7.1** Create `scripts/stow/stow-all.sh` (stow all packages)
- [x] **1.7.2** Create `scripts/stow/stow-package.sh` (stow single package)
- [x] **1.7.3** Create `scripts/stow/unstow-all.sh` (remove symlinks)
- [x] **1.7.4** Test stow scripts

**Completed**: 2025-10-20
**Status**: ✅ All stow automation scripts implemented with dry-run support, verbose/quiet modes, comprehensive error handling

### 1.8 Health Checks ✅

- [x] **1.8.1** Create `scripts/health/check-stow.sh` (verify symlinks)
- [x] **1.8.2** Create `scripts/health/check-all.sh` (verify dependencies + symlinks)
- [x] **1.8.3** Test health check scripts

**Completed**: 2025-10-21
**Status**: ✅ Comprehensive health checks implemented with OS detection, dependency verification, symlink validation, Git config checks

### 1.9 Makefile ✅

- [x] **1.9.1** Create `Makefile` with targets: install, stow, unstow, health, backup, clean
- [x] **1.9.2** Test all Makefile targets

**Completed**: 2025-10-21
**Status**: ✅ Makefile orchestration complete with dry-run support, formatted help menu, integration with all scripts

**Acceptance Criteria**:
- ✅ `make install` completes without errors
- ✅ All packages stowed correctly
- ✅ `make health` passes all checks (13/13 passed)
- ✅ Symlinks point to correct dotfiles locations
- ✅ Dry-run mode available for safe preview (`make stow-dry-run`, `make stow-package-dry-run`)

---

## FASE 2: Secrets & Sync ✅

**Obiettivo**: Implement secret management and R2 asset synchronization
**Duration**: 4-6 hours (base) + 18 hours (enhanced asset management)
**Priority**: Critical ⚡
**Status**: ✅ **COMPLETED** 2025-01-25 | All 11 sections complete (2.1-2.11)

### 2.1 1Password CLI Integration ✅

- [x] **2.1.1** Create `scripts/secrets/inject-env.sh` (op inject wrapper)
- [x] **2.1.2** Create `scripts/secrets/validate-secrets.sh` (verify no remaining op:// refs)
- [x] **2.1.3** Create `secrets/template.env` (standard template)
- [x] **2.1.4** Create `secrets/docker-compose-op.yml` (example)
- [x] **2.1.5** Test secret injection with 1Password

**Completed**: 2025-10-21
**Status**: ✅ All tasks completed, scripts tested and working
**GitHub Issue**: [#13](https://github.com/matteocervelli/dotfiles/issues/13)

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

### 2.7 Enhanced Manifest System with Auto-Update ✅

- [x] **2.7.1** Add `dimensions` and `env_mode` fields to schema
- [x] **2.7.2** Create `scripts/sync/generate-cdn-manifest.sh` (with ImageMagick dimensions)
- [x] **2.7.3** Create `scripts/sync/notify-cdn-updates.sh` (show size/dimension changes)
- [x] **2.7.4** Test manifest generation with images

**Completed**: 2025-01-24
**Status**: ✅ Enhanced manifest system fully implemented with dimension extraction, notification system, and performance caching
**GitHub Issue**: [#29](https://github.com/matteocervelli/dotfiles/issues/29) ✅ CLOSED
**Tests**: `tests/test-29-manifest-system.bats` (30 tests passing)

### 2.8 Project Asset Sync with Library-First Strategy ✅

- [x] **2.8.1** Create `scripts/sync/generate-project-manifest.sh` (interactive)
- [x] **2.8.2** Create `scripts/sync/sync-project-assets.sh` (copy from ~/media/cdn, fallback to R2)
- [x] **2.8.3** Add `stow-packages/bin/.local/bin/sync-project` symlink
- [x] **2.8.4** Test with sample project

**Completed**: 2025-01-24
**Status**: ✅ Library-first sync strategy implemented with smart fallback, device filtering, and checksum verification
**GitHub Issue**: [#30](https://github.com/matteocervelli/dotfiles/issues/30) ✅ CLOSED
**Tests**: `tests/test-30-project-sync.bats` (42 tests, 41 passing - 97.6%)

### 2.9 Auto-Update Propagation Across Projects ✅

- [x] **2.9.1** Create `scripts/sync/update-cdn-and-notify.sh` (update + notify workflow)
- [x] **2.9.2** Create `scripts/sync/propagate-cdn-updates.sh` (update all projects using changed files)
- [x] **2.9.3** Add `stow-packages/bin/.local/bin/update-cdn` symlink
- [x] **2.9.4** Test propagation workflow

**Completed**: 2025-01-24
**Status**: ✅ Auto-update propagation system with interactive workflow, before/after comparison, and project detection
**GitHub Issue**: [#31](https://github.com/matteocervelli/dotfiles/issues/31) ✅ CLOSED
**Tests**: `tests/test-31-auto-update.bats` (24 tests passing)
**Performance**: <5 minutes for 10+ projects (vs ~30 min manual)

### 2.10 Environment-Aware Asset Helpers ✅

- [x] **2.10.1** Create `templates/project/lib/assets.ts` (TypeScript helper with React hook)
- [x] **2.10.2** Create `templates/project/lib/assets.py` (Python helper)
- [x] **2.10.3** Create example tests for both helpers
- [x] **2.10.4** Test helpers in sample projects

**Completed**: 2025-01-24
**Status**: ✅ Environment-aware asset helpers for TypeScript and Python with zero dependencies
**GitHub Issue**: [#32](https://github.com/matteocervelli/dotfiles/issues/32) ✅ CLOSED
**Tests**: `tests/test-32-environment-helpers.bats` (57 tests passing)
**Features**:
- TypeScript: 370 lines, singleton pattern, React hook, batch operations
- Python: 380 lines, @lru_cache, type hints, batch operations
- Security: Path traversal prevention, HTTPS validation
- Example tests: 36 test cases (TypeScript), 27 test cases (Python)

### 2.11 Documentation: Asset Management System ✅

- [x] **2.11.1** Create `sync/library/README.md` (central library guide)
- [x] **2.11.2** Update `sync/manifests/README.md` (add library workflow, env switching)
- [x] **2.11.3** Update `sync/manifests/schema.yml` (document new fields)
- [x] **2.11.4** Create `templates/README.md` (asset helpers documentation)
- [x] **2.11.5** Update main `README.md` (add asset management overview)

**Completed**: 2025-01-25
**Status**: ✅ Comprehensive documentation for entire asset management system
**GitHub Issue**: [#34](https://github.com/matteocervelli/dotfiles/issues/34) ✅ CLOSED
**Documentation**:
- Central Library Guide: Complete workflow, best practices, troubleshooting
- Manifest Documentation: Library workflow, environment switching, auto-update sections
- Schema Documentation: Detailed field explanations with use cases
- Templates Documentation: Asset helpers, integration examples, testing
- Main README: Quick start, command reference, example workflow

**Acceptance Criteria**:
- ✅ `op inject` works with .env.template
- ✅ Rclone configured for R2
- ✅ Manifest generation works
- ✅ R2 pull/push works
- ⏸️  Auto-update commits and pushes changes every 30min (deferred to FASE 2.6)
- ✅ Enhanced manifest with dimensions and env_mode (Issue #29)
- ✅ Project sync with library-first strategy (Issue #30)
- ✅ Auto-update notifications with size/dimension comparison (Issue #31)
- ✅ Environment helpers working in TypeScript and Python (Issue #32)
- ✅ Complete asset management documentation (Issue #34)

**FASE 2.X Summary** (Issues #29-#34):
- Total time: ~16 hours implementation + 2 hours documentation = **18 hours**
- Scripts created: 6 (generate-cdn-manifest, notify-cdn-updates, generate-project-manifest, sync-project-assets, update-cdn-and-notify, propagate-cdn-updates)
- Helpers created: 2 (assets.ts - 370 lines, assets.py - 380 lines)
- Documentation files: 2 new (sync/library/README.md, templates/README.md), 3 updated
- Tests: 153 BATS tests across 4 test suites (97%+ passing)
- Performance: 90% library efficiency, <5 min propagation for 10+ projects

**Master Plan**: See [ASSET-MANAGEMENT-PLAN.md](ASSET-MANAGEMENT-PLAN.md) for detailed implementation plan

---

## FASE 3: Applications & XDG Compliance

**Obiettivo**: Application management and config consolidation
**Duration**: 6-8 hours
**Priority**: High 🔥

### 3.1 Application Audit ✅

- [x] **3.1.1** Create `scripts/apps/audit-apps.sh` (list Homebrew, mas, /Applications)
- [x] **3.1.2** Run audit and save to `applications/current-apps.txt`
- [x] **3.1.3** Manually review and create `applications/keep-apps.txt` and `applications/remove-apps.txt`
- [x] **3.1.4** Create `scripts/apps/cleanup-apps.sh` (safe removal with dry-run)
- [x] **3.1.5** Create `applications/README.md` with complete workflow guide
- [x] **3.1.6** Create `tests/test-19-app-audit.bats` (38 tests)
- [x] **3.1.7** Create `docs/TECH-STACK.md` documentation
- [x] **3.1.8** Update documentation (README.md, CHANGELOG.md, CLAUDE.md)

**Completed**: 2025-01-25
**Status**: ✅ All tasks completed, comprehensive application management system implemented
**GitHub Issue**: [#19](https://github.com/matteocervelli/dotfiles/issues/19) ✅ CLOSED
**Scripts**: audit-apps.sh (~200 lines), cleanup-apps.sh (~250 lines)
**Tests**: 38 BATS tests covering audit, cleanup, safety features, and error handling
**Documentation**: README.md, CLAUDE.md, TECH-STACK.md, applications/README.md updated

### 3.2 Brewfile Management ✅

- [x] **3.2.1** Create `system/macos/Brewfile` from audit
- [x] **3.2.2** Organize by categories (dev, apps, fonts)
- [x] **3.2.3** Include mas apps
- [x] **3.2.4** Test Brewfile installation
- [x] **3.2.5** Create `applications/vscode-extensions.txt`

**Completed**: 2025-10-25
**Status**: ✅ All tasks completed, Brewfile management system fully functional
**GitHub Issue**: [#20](https://github.com/matteocervelli/dotfiles/issues/20) ✅ CLOSED
**Scripts**: generate-brewfile.sh (~450 lines)
**Output**: system/macos/Brewfile (271 packages), applications/vscode-extensions.txt (92 extensions)
**Makefile**: 4 new targets (brewfile-generate, brewfile-check, brewfile-install, brewfile-update)
**Tests**: 40 BATS tests (all passing)
**Documentation**: system/macos/README.md (new), applications/README.md (updated)

### 3.3 Application Cleanup

**Note**: Merged into 3.1 - cleanup functionality integrated into audit system
- [x] **3.3.1** Create `scripts/apps/cleanup-apps.sh` (remove unwanted apps)
- [x] **3.3.2** Test cleanup script with dry-run
- [x] **3.3.3** Run actual cleanup

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

**Status**: ✅ **COMPLETED** 2025-10-26 | Docker implementation complete

**Note**: **FASE 4 has been expanded into FASE 7** to accommodate 14+ different OS environments.

### 4.2 Ubuntu 24.04 LTS Bootstrap & Docker Setup ✅

- [x] **4.2.1** Create `scripts/bootstrap/install-docker.sh` (~370 lines)
- [x] **4.2.2** Implement official Docker repository setup with GPG verification
- [x] **4.2.3** Install Docker Engine + Docker Compose v2 plugin
- [x] **4.2.4** Configure systemd service (enable on boot)
- [x] **4.2.5** Add user to docker group with proper warnings
- [x] **4.2.6** Implement comprehensive error handling and dry-run mode
- [x] **4.2.7** Update `install-dependencies-ubuntu.sh` with `--with-docker` flag
- [x] **4.2.8** Create Makefile targets (`docker-install`, `ubuntu-full`)
- [x] **4.2.9** Create `docs/guides/docker-ubuntu-setup.md` (~500 lines)
- [x] **4.2.10** Document Parallels VM configuration (CPU, RAM, shared folders)
- [x] **4.2.11** Document remote Docker context setup from macOS
- [x] **4.2.12** Create `docs/architecture/ADR/ADR-005-docker-ubuntu-installation.md`
- [x] **4.2.13** Create `tests/test-22-ubuntu-docker.bats` (48 tests, 100% passing)
- [x] **4.2.14** Update CHANGELOG.md with complete implementation details
- [x] **4.2.15** Update docs/TECH-STACK.md with Docker information
- [x] **4.2.16** Update README.md with Docker section
- [x] **4.2.17** Close Issue #22

**Completed**: 2025-10-26
**Status**: ✅ All acceptance criteria met
**GitHub Issue**: [#22](https://github.com/matteocervelli/dotfiles/issues/22) READY TO CLOSE
**Tests**: 48 BATS tests passing
**Documentation**: 1000+ lines (guide + ADR + tests)
**Performance**: Docker installation in 3-5 minutes

**Acceptance Criteria** (All Met):
- ✅ Ubuntu 24.04 LTS bootstrap installs all dependencies
- ✅ Docker Engine + Compose v2 working natively
- ✅ Docker starts automatically on boot
- ✅ Dotfiles work cross-platform (macOS configs adapted for Linux)
- ✅ Remote Docker context accessible from macOS
- ✅ Parallels shared folders functional

See [FASE 7: Multi-Platform OS Configurations](#fase-7-multi-platform-os-configurations) below for complete implementation plan.

---

## FASE 5: Templates & Automation

**Obiettivo**: Project boilerplates and advanced automation
**Duration**: 6-8 hours
**Priority**: Medium 🔶

### 5.1 Interactive Project Template Generator ⏳

- [ ] **5.1.1** Create `scripts/templates/new-project.sh` (interactive CLI)
- [ ] **5.1.2** Create `templates/nextjs-app/` (Next.js 14 App Router)
- [ ] **5.1.3** Create `templates/nextjs-pages/` (Next.js 14 Pages Router)
- [ ] **5.1.4** Create `templates/vite-react/` (Vite + React + TypeScript)
- [ ] **5.1.5** Create `templates/python-fastapi/` (FastAPI + SQLAlchemy)
- [ ] **5.1.6** Create `templates/python-ml/` (Python + Jupyter + MLX)
- [ ] **5.1.7** Create `templates/swift-app/` (SwiftUI + SwiftPM)
- [ ] **5.1.8** Create `templates/monorepo/` (Turborepo structure)
- [ ] **5.1.9** Create `templates/README.md` (template usage docs)
- [ ] **5.1.10** Test template generation workflow (target: <3 minutes per project)

**GitHub Issue**: [#33](https://github.com/matteocervelli/dotfiles/issues/33)

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

## FASE 7: Multi-Platform OS Configurations

**Obiettivo**: Bootstrap and configure 14+ different OS environments with profile-based deployment
**Duration**: 12-16 hours
**Priority**: Medium 🔶
**Status**: ⚪ PENDING (Documentation complete, implementation planned)

**Documentation**: See [docs/os-configurations/](../docs/os-configurations/) for complete multi-platform architecture.

### 7.1 Ubuntu 24.04 LTS Bootstrap & Docker [Issue #22] ✅

- [x] **7.1.1** Test `scripts/bootstrap/ubuntu-bootstrap.sh` on Ubuntu 24.04 VM
- [x] **7.1.2** Create Docker installation script (`install-docker.sh`)
- [x] **7.1.3** Test Docker Engine + Compose v2 installation
- [x] **7.1.4** Configure Docker to start on boot (systemctl)
- [x] **7.1.5** Test dotfiles installation on Parallels Ubuntu VM
- [x] **7.1.6** Verify Docker workflows and remote Docker context

**Completed**: 2025-10-26 (FASE 4.2)
**Status**: ✅ All tasks completed
**Target**: Parallels Ubuntu 24.04 LTS (ARM64)
**Profile**: `ubuntu-vm`
**Roles**: `development`, `infrastructure`
**GitHub Issue**: [#22](https://github.com/matteocervelli/dotfiles/issues/22)

### 7.2 Fedora Bootstrap & DNF Package Management [Issue #40]

- [ ] **7.2.1** Create `scripts/bootstrap/fedora-bootstrap.sh`
- [ ] **7.2.2** Map Homebrew/APT packages to DNF equivalents
- [ ] **7.2.3** Create `system/fedora/packages.txt`
- [ ] **7.2.4** Test on Parallels Fedora VM
- [ ] **7.2.5** Document Fedora-specific configurations

**Target**: Parallels Fedora Workstation (ARM64)
**Profile**: `fedora-dev`
**Roles**: `development`

### 7.3 Linux Mint Cinnamon Desktop Configuration [Issue #41] ✅

- [x] **7.3.1** Create Mint-specific bootstrap (based on Ubuntu)
- [x] **7.3.2** Configure Cinnamon desktop settings
- [x] **7.3.3** Test GUI application configurations
- [x] **7.3.4** Document Mint vs Ubuntu differences

**Target**: Parallels Linux Mint Cinnamon (ARM64)
**Profile**: `mint-desktop`
**Roles**: `development`, `productivity`
**Status**: ✅ Completed - Ready for testing

### 7.4 Arch Linux Bootstrap & AUR Integration [Issue #42]

- [ ] **7.4.1** Create `scripts/bootstrap/arch-bootstrap.sh`
- [ ] **7.4.2** Implement Pacman package management
- [ ] **7.4.3** Configure AUR helper (yay or paru)
- [ ] **7.4.4** Map package names (APT → Pacman)
- [ ] **7.4.5** Test on UTM Arch Linux VM

**Target**: UTM Arch Linux (ARM64)
**Profile**: `arch-dev`
**Roles**: `development`

### 7.5 Omarchy (DHH Linux) Bootstrap [Issue #43]

- [ ] **7.5.1** Research Omarchy base system and package manager
- [ ] **7.5.2** Create `scripts/bootstrap/omarchy-bootstrap.sh`
- [ ] **7.5.3** Respect DHH's opinionated defaults
- [ ] **7.5.4** Test on UTM Omarchy VM
- [ ] **7.5.5** Document Omarchy-specific quirks

**Target**: UTM Omarchy (ARM64/x86_64)
**Profile**: `omarchy-dev`
**Reference**: https://omarchy.org

### 7.6 Docker Ubuntu Base Image & Minimal Profile [Issue #44]

- [ ] **7.6.1** Create `Dockerfile.dotfiles-ubuntu` base image
- [ ] **7.6.2** Implement minimal stow packages (shell, git only)
- [ ] **7.6.3** Create multi-stage builds (dev/production variants)
- [ ] **7.6.4** Document volume mount strategy
- [ ] **7.6.5** Test container startup time (< 2 seconds target)

**Target**: Docker containers (multi-arch)
**Profile**: `container-minimal`
**Size Goal**: < 500MB with dotfiles

### 7.7 VPS Ubuntu Headless & Security Hardening [Issue #45]

- [ ] **7.7.1** Create VPS-specific bootstrap (minimal, headless)
- [ ] **7.7.2** Implement security hardening (fail2ban, UFW, SSH)
- [ ] **7.7.3** Configure monitoring integration (Prometheus node_exporter)
- [ ] **7.7.4** Setup remote Docker context
- [ ] **7.7.5** Test on cloud VPS (DigitalOcean/Hetzner)

**Target**: Cloud VPS Ubuntu 24.04 LTS (x86_64/AMD)
**Profile**: `vps-minimal`
**Roles**: `security`

### 7.8 Kids' Fedora VM - Educational Profile [Issue #46]

- [ ] **7.8.1** Create restricted user profile configuration
- [ ] **7.8.2** Create educational software package list
- [ ] **7.8.3** Implement parental controls and safe browsing
- [ ] **7.8.4** Create simplified shell environment
- [ ] **7.8.5** Test on MacBook Fedora VM

**Target**: MacBook Parallels Fedora (ARM64)
**Profile**: `kids-safe`
**Roles**: `education` (custom)

### 7.9 Profile System Architecture & Bootstrap Integration [Issue #39]

- [ ] **7.9.1** Design composable profile system (YAML-based)
- [ ] **7.9.2** Create profile directory structure (`system/profiles/`)
- [ ] **7.9.3** Create role definitions (`system/roles/`)
- [ ] **7.9.4** Add `--profile` flag to bootstrap scripts
- [ ] **7.9.5** Implement role-based package composition
- [ ] **7.9.6** Create profile selection documentation
- [ ] **7.9.7** Test profile inheritance model

**Profiles to Create:**
- `mac-studio`, `macbook`, `ubuntu-vm`, `vps-minimal`, `selfhosting`, `kids-safe`, `container-minimal`, `fedora-dev`, `mint-desktop`, `arch-dev`, `omarchy-dev`

**Acceptance Criteria**:
- ✅ All 8+ OS environments have bootstrap scripts
- ✅ Profile system supports composable roles
- ✅ Tested on respective platforms (VMs, containers, VPS)
- ✅ Cross-platform compatibility verified
- ✅ Documentation complete (OVERVIEW, DEVICE-MATRIX, PROFILES, BOOTSTRAP-STRATEGIES)
- ✅ Placeholder scripts created for all platforms

**Milestone**: [FASE 7: Multi-Platform OS Configurations](https://github.com/matteocervelli/dotfiles/milestone/8)

---

## Milestone Tracking

### 🎯 Milestone 0: Documentation Complete ✅

**Status**: ✅ COMPLETED
**Date**: 2025-01-17
**Criteria**: All architectural decisions documented, implementation plan ready

### 🎯 Milestone 1: Foundation Complete ✅

**Status**: ✅ **COMPLETED** 2025-10-21
**Target**: FASE 1 completion
**Criteria**:
- ✅ Directory structure complete (60+ directories)
- ✅ Bootstrap scripts working (macOS, Ubuntu, master orchestrator)
- ✅ 4 stow packages functional (shell, git, ssh, 1password) + 5 placeholder packages
- ✅ Health checks passing (13/13 checks passed)
- ✅ Makefile orchestration complete with dry-run support
- ✅ All 12 GitHub issues closed ([Milestone #2](https://github.com/matteocervelli/dotfiles/milestone/2))

### 🎯 Milestone 2: Secrets & Sync Complete

**Status**: 🟡 READY TO START
**Target**: FASE 2 completion ([Milestone #3](https://github.com/matteocervelli/dotfiles/milestone/3))
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

### 🎯 Milestone 7: Multi-Platform Complete

**Status**: ⚪ PENDING (Documentation ✅ Complete)
**Target**: FASE 7 completion ([Milestone #8](https://github.com/matteocervelli/dotfiles/milestone/8))
**Criteria**:
- Bootstrap scripts for 8+ environments (Ubuntu, Fedora, Mint, Arch, Omarchy, Docker, VPS, Kids)
- Profile system implemented (composable roles)
- Cross-platform testing complete
- Documentation: OVERVIEW.md, DEVICE-MATRIX.md, PROFILES.md, BOOTSTRAP-STRATEGIES.md
- Placeholder scripts created for all platforms

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
| 2025-10-26 | Multi-Platform: 14+ device support | ✅ Approved | Issue #22 analysis, DEVICE-MATRIX.md |
| 2025-10-26 | FASE 7: OS-specific configurations | ✅ Approved | New milestone, expanded from FASE 4 |
| 2025-10-26 | Omarchy: DHH's opinionated Linux | ✅ Research | https://omarchy.org |
| 2025-10-26 | Ubuntu 24.04 LTS: Primary VM OS | ✅ Approved | vs 22.04 LTS (longer support) |
| 2025-10-26 | Profile System: Composable roles | ✅ Approved | FASE 7.9, PROFILES.md |
| 2025-10-26 | Docker: Base image + volume mount | ✅ Approved | FASE 7.6, container-minimal profile |
| 2025-10-26 | VPS: Headless + security hardening | ✅ Approved | FASE 7.7, vps-minimal profile |

---

## Quick Reference

### Current Status
- **Phase**: FASE 0 ✅ Complete, FASE 1 ✅ Complete (2025-10-21)
- **Next Phase**: FASE 2 🟡 Ready to Start ([Secrets & Sync](https://github.com/matteocervelli/dotfiles/milestone/3))
- **Next Action**: Begin FASE 2.1 (1Password CLI Integration)
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
**Last Updated**: 2025-10-21
**Status**: FASE 0 ✅ Complete | FASE 1 ✅ Complete (2025-10-21) | FASE 2 🟡 Ready to Start
