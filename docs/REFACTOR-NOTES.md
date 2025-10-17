# Repository Refactor Notes

**Date**: 2025-01-17
**Version**: 2.0
**Status**: Refactor Complete - Ready for Implementation

---

## Executive Summary

The dotfiles repository has been completely restructured and redesigned based on:
1. **New requirements** from updated [new-list.md](new-list.md)
2. **Cross-platform needs** (macOS + Ubuntu VMs)
3. **Modern best practices** (GNU Stow, 1Password CLI, Cloudflare R2)
4. **Infrastructure integration** (Tailscale, MCP servers, Docker stack)

**Previous State**: Mixed content, unclear structure, incomplete configurations
**Current State**: Clean architecture, comprehensive documentation, ready for implementation

---

## What Was Changed

### Documentation Restructure

**Archived** (moved to `docs/.archive/`):
- `screenshot-checklist.md` - Old screenshot planning
- `screenshot-list-exact.md` - Detailed screenshot list
- `screenshot-priority-revised.md` - Screenshot priorities
- `preferences-analysis.md` - Old preferences analysis
- `mac-studio-scan.md` - System scan from June 2024

**Kept and Updated**:
- `PLANNING.md` - Original planning document (historical reference)
- `TASK.md` - Completely rewritten with new FASE 1-6 structure
- `new-list.md` - Requirements list (source of truth for features)
- `Technology Stack for my infrastructure.md` - Infrastructure overview
- `webpro-dotfiles-guide.md` - Reference guide

**New Documents Created**:
- `ARCHITECTURE-DECISIONS.md` - Complete ADR (Architecture Decision Record)
- `IMPLEMENTATION-PLAN.md` - Detailed execution plan for FASE 1-2
- `REFACTOR-NOTES.md` - This document
- `xdg-compliance.md` - (to be created in FASE 3)
- `secrets-management.md` - (to be created in FASE 2)
- `sync-strategy.md` - (to be created in FASE 2)
- `vm-setup.md` - (to be created in FASE 4)

---

## Repository Structure: Before vs After

### Before (Old Structure)
```
dotfiles/
├── docs/                    # Mixed documentation
├── packages/                # Incomplete stow packages
│   ├── zsh/
│   ├── git/
│   └── ...
├── scripts/                 # Partial automation
├── legacy-zsh/              # Unmigrated configs
├── bash/                    # Unmigrated bash configs
├── macos/                   # Scattered macOS configs
└── screenshots/             # System screenshots
```

**Issues**:
- Inconsistent directory naming (`packages/` vs `stow-packages/`)
- Mixed completed/incomplete content
- No clear separation of concerns
- Missing key components (secrets, sync, VMs)
- No comprehensive documentation

### After (New Structure)
```
dotfiles/
├── stow-packages/           # ✨ GNU Stow packages (clear naming)
│   ├── shell/               # Cross-platform shell configs
│   ├── git/
│   ├── ssh/
│   ├── 1password/
│   ├── llm-tools/
│   ├── cursor/
│   ├── iterm2/
│   ├── dev-env/
│   └── bin/
├── system/                  # ✨ OS-specific system configs
│   ├── macos/
│   │   ├── defaults/
│   │   ├── launch-agents/
│   │   └── Brewfile
│   └── ubuntu/
│       ├── apt-packages.txt
│       └── systemd/
├── applications/            # ✨ Application management
│   ├── brew-packages.txt
│   ├── mas-apps.txt
│   ├── cursor-extensions.txt
│   └── cleanup-list.txt
├── secrets/                 # ✨ Secret management (NEW)
│   ├── template.env
│   ├── op-inject.sh
│   └── docker-compose-op.yml
├── sync/                    # ✨ File synchronization (NEW)
│   ├── rclone/
│   ├── manifests/
│   └── auto-update/
├── scripts/                 # ✨ Complete automation suite
│   ├── bootstrap/
│   ├── stow/
│   ├── apps/
│   ├── xdg-compliance/      # NEW
│   ├── secrets/             # NEW
│   ├── sync/                # NEW
│   ├── health/
│   ├── backup/
│   └── utils/
├── templates/               # ✨ Project boilerplates (NEW)
│   ├── project/
│   ├── python-project/
│   ├── nextjs-project/
│   └── docker-compose/
├── docs/                    # ✨ Comprehensive documentation
├── backups/                 # Gitignored backups
├── .stow-local-ignore
├── .gitignore
├── Makefile
└── README.md
```

**Improvements**:
- ✅ Clear, consistent naming conventions
- ✅ Complete separation of concerns
- ✅ New critical components (secrets, sync, templates)
- ✅ Comprehensive automation scripts
- ✅ Full documentation coverage

---

## Key Architectural Changes

### 1. From Mixed to Modular

**Before**: Configs mixed with scripts, unclear ownership
**After**: Clear separation via GNU Stow packages

**Rationale**: Modularity allows selective deployment (e.g., only `shell` + `git` on a server)

### 2. From Manual to Automated

**Before**: Manual installation steps, incomplete automation
**After**: Complete automation suite with `make install`

**Components**:
- Bootstrap scripts (dependency installation)
- Stow automation (symlink management)
- Health checks (verification)
- Backup scripts (disaster recovery)
- Auto-update (continuous sync)

### 3. From Local to Cloud-Integrated

**Before**: Only local configs
**After**: Integration with Cloudflare R2 for binary assets

**New Capabilities**:
- Binary asset storage (ML models, datasets, media)
- Manifest-based tracking (YAML manifests)
- Cross-device sync (macOS ↔ Ubuntu VMs)

### 4. From Insecure to Secret-First

**Before**: No secret management strategy
**After**: 1Password CLI integration with `op inject`

**Security Improvements**:
- ✅ No secrets in git (ever)
- ✅ Template-based secret injection
- ✅ Docker Compose integration with `op run`
- ✅ Validation scripts to detect leaks

### 5. From macOS-Only to Cross-Platform

**Before**: macOS-centric configs
**After**: macOS + Ubuntu VM support

**Cross-Platform Features**:
- OS detection utilities
- Platform-specific bootstrap scripts
- Conditional configs (`.zshrc` vs `.bashrc`)
- Shared configs via GNU Stow

---

## Migration Path from Old to New

### Phase 1: Content Audit (COMPLETED)

**Actions Taken**:
1. Archived obsolete documentation
2. Identified reusable content:
   - `packages/zsh/.zshrc` → Migrate to `stow-packages/shell/.zshrc`
   - `legacy-zsh/aliases.zsh` → Migrate to `stow-packages/shell/.config/shell/aliases.sh`
   - `legacy-zsh/functions.zsh` → Migrate to `stow-packages/shell/.config/shell/functions.sh`
   - Git configs → Migrate to `stow-packages/git/`
   - SSH configs → Migrate to `stow-packages/ssh/`
3. Documented decisions in this file

### Phase 2: Backup Existing (✅ COMPLETED - 2025-10-17)

**Actions Completed**:
1. ✅ Created backup directory: `backups/pre-refactor-20251017/`
2. ✅ Copied entire current repo state (157 files)
3. ✅ Documented audit findings below

**Files Backed Up**:
- Current `packages/` directory (19 files across 8 packages)
- `legacy-zsh/` directory (13 items including symlinks)
- `bash/` directory (1 file: .zshrc)
- All scripts in `scripts/` (3 files)
- All documentation in `docs/` (14 files + .archive/)
- All screenshots (organized by category)
- Template directories (python-project, react-project, swift-project)

**Backup Statistics**:
- Total size: ~7.2 MB
- Total files: 157
- Backup location: `backups/pre-refactor-20251017/`
- Backup date: October 17, 2025

---

## FASE 1.1 Audit Findings (Completed 2025-10-17)

### Packages Directory Audit

**Current Structure** (`packages/`):
```
packages/
├── bin/                    # Empty directory
├── claude/                 # CLAUDE.md only
├── cursor/                 # VS Code/Cursor settings
├── git/                    # Git configuration files (3 files)
├── homebrew/               # Brewfile
├── node/                   # Node.js configs (3 files)
├── python/                 # Python configs (3 files + pip/)
├── ssh/                    # SSH config (1 file)
└── zsh/                    # ZSH configs (4 files)
```

**Content Analysis**:

1. **zsh/** (4 files):
   - `.zshrc` - Main ZSH configuration with Oh My Zsh
   - `.zsh_aliases` - Shell aliases
   - `.zsh_exports` - Environment exports
   - `.zsh_functions` - Shell functions
   - **Status**: Good foundation, needs migration to modular structure

2. **git/** (3 files):
   - `.gitconfig` - Git user config and aliases
   - `.gitignore_global` - Global gitignore patterns
   - `.gitmessage` - Commit message template
   - **Status**: Ready to migrate, needs GPG signing setup

3. **ssh/** (1 file):
   - `.ssh/config` - SSH configuration
   - **Status**: Needs expansion with Tailscale network and config.d/ structure

4. **cursor/** (2 files):
   - `Library/Application Support/Cursor/User/settings.json` - Editor settings
   - `Library/Application Support/Cursor/User/keybindings.json` - Key bindings
   - **Status**: Ready to migrate, path structure needs XDG consideration

5. **python/** (3 files + directory):
   - `.pyenvrc` - Pyenv configuration
   - `.pythonrc` - Python REPL config
   - `.pip/pip.conf` - Pip configuration
   - **Status**: Good foundation for dev-env package

6. **node/** (3 files):
   - `.npmrc` - NPM configuration
   - `.nvmrc` - NVM version file
   - `.nvmsh` - NVM shell script
   - **Status**: Ready for dev-env package

7. **homebrew/** (1 file):
   - `Brewfile` - Homebrew package list
   - **Status**: Needs update and migration to system/macos/

8. **claude/** (1 file):
   - `CLAUDE.md` - Claude Code configuration
   - **Status**: Migrate to llm-tools package

9. **bin/** (empty):
   - **Status**: Ready to populate with custom scripts

### Legacy-ZSH Directory Audit

**Current Structure** (`legacy-zsh/`):
```
legacy-zsh/
├── .zsh_aliases -> /Users/matteocervelli/.zsh_aliases (symlink)
├── .zsh_aliases-backup (1.9 KB)
├── .zsh_exports -> /Users/matteocervelli/.zsh_exports (symlink)
├── .zsh_exports-backup (398 B)
├── .zsh_plugins -> /Users/matteocervelli/.zsh_plugins (symlink)
├── .zsh_plugins-backup (396 B)
├── .zshrc -> /Users/matteocervelli/.zshrc (symlink)
├── .zshrc-backup (7.9 KB)
├── aliases.zsh -> ~/.oh-my-zsh/custom/aliases.zsh (symlink)
├── exports.zsh -> ~/.oh-my-zsh/custom/exports.zsh (symlink)
└── functions.zsh -> ~/.oh-my-zsh/custom/functions.zsh (symlink)
```

**Content Analysis**:
- Contains OLD configs from before current package structure
- Mix of symlinks to live configs and backup files
- **Important**: The `.zsh_*-backup` files contain useful aliases/exports/functions
- **Decision**: Extract useful content from backup files, then archive directory
- **Action**: Review backup files for unique configs not in current `packages/zsh/`

### Bash Directory Audit

**Current Structure** (`bash/`):
```
bash/
└── .zshrc (8 KB)
```

**Content Analysis**:
- Single ZSH config file (misnamed directory?)
- **Decision**: Review content, likely obsolete or duplicate
- **Action**: Compare with current `packages/zsh/.zshrc`, extract unique configs if any

### Scripts Directory Audit

**Current Structure** (`scripts/`):
```
scripts/
├── analyze-preferences.sh
├── install.sh
└── scan-system.sh
```

**Content Analysis**:
1. **install.sh** - Basic installation script
   - **Status**: Needs complete rewrite per IMPLEMENTATION-PLAN.md

2. **scan-system.sh** - System configuration scanner
   - **Status**: Useful utility, keep and enhance

3. **analyze-preferences.sh** - Preferences analysis tool
   - **Status**: Review for utility, possibly enhance or archive

**Decision**: Keep scripts/ directory, but reorganize per new structure:
```
scripts/
├── bootstrap/
├── stow/
├── apps/
├── secrets/
├── sync/
├── health/
├── backup/
└── utils/
```

### Documentation Audit

**Current Structure** (`docs/`):
```
docs/
├── .archive/                          # Archived old docs
│   ├── analisi-configurazione-zsh.md
│   ├── mac-studio-scan.md
│   ├── preferences-analysis.md
│   ├── screenshot-*.md (3 files)
├── ARCHITECTURE-DECISIONS.md          # ✅ New, comprehensive
├── IMPLEMENTATION-PLAN.md             # ✅ New, detailed
├── PLANNING.md                        # Historical reference
├── REFACTOR-NOTES.md                  # ✅ This file
├── TASK.md                            # ✅ Rewritten
├── Technology Stack...md              # Infrastructure overview
├── mac-setup.md                       # Brief setup notes
├── new-list.md                        # Requirements list
├── system-mapping-complete.md         # System configuration map
└── webpro-dotfiles-guide.md          # Reference guide
```

**Status**: Well-organized after FASE 0 refactor
- ✅ Old docs archived appropriately
- ✅ New comprehensive docs created
- ✅ Clear structure and purpose

### Screenshots Directory Audit

**Current Structure** (`screenshots/`):
- Well-organized by category (applications, menu-bar, overview, system-preferences, third-party)
- Contains useful visual documentation of system configuration
- **Decision**: Keep as reference material for macOS setup

### Templates Directory Audit

**Current Structure** (`templates/`):
```
templates/
├── python-project/
├── react-project/
└── swift-project/
```

**Status**: Directory structure exists but appears empty
- **Decision**: Populate in FASE 5 with actual boilerplates

---

## Migration Recommendations

### Immediate Actions (FASE 1.6)

1. **Migrate ZSH Configs**:
   - Copy `packages/zsh/*` to `stow-packages/shell/`
   - Extract unique configs from `legacy-zsh/*-backup` files
   - Create modular structure in `.config/shell/`

2. **Migrate Git Configs**:
   - Copy `packages/git/*` to `stow-packages/git/`
   - Add GPG signing configuration
   - Enhance git templates

3. **Migrate SSH Configs**:
   - Copy `packages/ssh/.ssh/config` to `stow-packages/ssh/`
   - Create `config.d/` structure
   - Add Tailscale network configurations

4. **Migrate Development Configs**:
   - Create `stow-packages/dev-env/`
   - Migrate `packages/python/` configs
   - Migrate `packages/node/` configs

5. **Migrate Editor Configs**:
   - Migrate `packages/cursor/` to `stow-packages/cursor/`
   - Handle XDG compliance for path structure

6. **Migrate LLM Tools**:
   - Create `stow-packages/llm-tools/.config/claude/`
   - Migrate `packages/claude/CLAUDE.md`

### Content to Archive

After successful migration:
- `legacy-zsh/` → Can be deleted after content extraction
- `bash/` → Archive or delete after review
- Old `packages/` → Keep until new structure is verified working

### Content to Enhance

- `scripts/install.sh` → Rewrite as master orchestrator
- `scripts/scan-system.sh` → Enhance and move to `scripts/utils/`
- `packages/homebrew/Brewfile` → Update and move to `system/macos/`

### Phase 3: Extract and Migrate (TO DO in FASE 1.6)

**Migration Tasks**:

**Shell Configs**:
- [ ] Extract useful aliases from `legacy-zsh/aliases.zsh`
- [ ] Extract useful functions from `legacy-zsh/functions.zsh`
- [ ] Migrate Oh My Zsh settings from `packages/zsh/.zshrc`
- [ ] Create unified `.zshrc` in `stow-packages/shell/`

**Git Configs**:
- [ ] Migrate `.gitconfig` from `packages/git/`
- [ ] Update with 1Password GPG signing
- [ ] Add comprehensive `.gitignore_global`

**SSH Configs**:
- [ ] Migrate SSH config to `stow-packages/ssh/`
- [ ] Add Tailscale network configs
- [ ] Structure with `config.d/` includes

**Development Tools**:
- [ ] Migrate pyenv configs (if any)
- [ ] Migrate nvm configs (if any)
- [ ] Create new `dev-env` stow package

### Phase 4: Testing and Validation (TO DO in FASE 1.8)

**Test Checklist**:
- [ ] Stow packages create correct symlinks
- [ ] Shell configs load without errors
- [ ] Git configs work (signing, aliases)
- [ ] SSH configs connect successfully
- [ ] Health checks pass

---

## Content Disposition Table

| Old Location | Status | New Location | Notes |
|--------------|--------|--------------|-------|
| `docs/screenshot-*.md` | ✅ Archived | `docs/.archive/` | Historical, no longer needed |
| `docs/preferences-analysis.md` | ✅ Archived | `docs/.archive/` | Outdated analysis |
| `docs/mac-studio-scan.md` | ✅ Archived | `docs/.archive/` | June 2024 scan, outdated |
| `docs/PLANNING.md` | ✅ Kept | Same | Historical reference |
| `docs/TASK.md` | ✅ Rewritten | Same | Complete new structure |
| `docs/new-list.md` | ✅ Kept | Same | Requirements source |
| `packages/zsh/` | 🔄 Migrate | `stow-packages/shell/` | Extract useful configs |
| `packages/git/` | 🔄 Migrate | `stow-packages/git/` | Update and enhance |
| `packages/ssh/` | 🔄 Migrate | `stow-packages/ssh/` | Restructure with config.d/ |
| `legacy-zsh/` | 🔄 Migrate | `stow-packages/shell/.config/shell/` | Break into modular files |
| `bash/` | 🔄 Review | `stow-packages/shell/` or delete | Check if needed |
| `scripts/` | 🔄 Review | `scripts/` (new structure) | Keep useful, rewrite rest |
| `macos/` | 🔄 Reorganize | `system/macos/` | Standardize structure |
| `screenshots/` | ⚪ Keep | Same | May be useful reference |

**Legend**:
- ✅ Completed
- 🔄 In Progress / To Do
- ⚪ Pending Decision

---

## Breaking Changes

### 1. Directory Structure

**Impact**: Any scripts or tools referencing old paths will break

**Old Path** → **New Path**:
- `packages/` → `stow-packages/`
- `macos/` → `system/macos/`
- No direct replacement for `legacy-zsh/` (content migrated)

**Migration**: Update all path references, use new structure

### 2. Stow Package Names

**Impact**: Existing symlinks from old stow operations will be orphaned

**Solution**:
1. Run `stow -D` on old packages before migration
2. Install new packages with `make stow`
3. Verify with `make health`

### 3. Configuration File Locations

**Impact**: Configs moved to XDG-compliant locations where possible

**Examples**:
- Shell aliases: `~/.zsh_aliases` → `~/.config/shell/aliases.sh`
- Shell functions: `~/.zsh_functions` → `~/.config/shell/functions.sh`

**Migration**: Symlinks will point to new locations automatically

### 4. Secret Management

**Impact**: No more `.env` files committed to git (was never done, but now enforced)

**New Workflow**:
1. Create `.env.template` with `op://` references
2. Use `op inject` to generate `.env`
3. `.env` is gitignored

**Migration**: Create templates for existing projects

---

## Technical Debt Addressed

### Debt Item 1: Incomplete Automation

**Problem**: Manual steps required for setup
**Solution**: Complete bootstrap + Makefile automation
**Status**: ✅ Planned in FASE 1

### Debt Item 2: No Secret Management

**Problem**: Unclear how to handle secrets
**Solution**: 1Password CLI integration
**Status**: ✅ Planned in FASE 2

### Debt Item 3: Single Platform (macOS)

**Problem**: No Ubuntu support
**Solution**: Cross-platform bootstrap + stow packages
**Status**: ✅ Planned in FASE 1, FASE 4

### Debt Item 4: No Binary Asset Strategy

**Problem**: Large files (models, datasets) not manageable
**Solution**: Cloudflare R2 + manifest system
**Status**: ✅ Planned in FASE 2

### Debt Item 5: Manual Config Sync

**Problem**: No automated sync between machines
**Solution**: Auto-update to GitHub every 30min
**Status**: ✅ Planned in FASE 2

### Debt Item 6: Scattered Documentation

**Problem**: Incomplete, outdated docs
**Solution**: Comprehensive documentation suite
**Status**: ✅ Completed in FASE 0

---

## Lessons Learned

### 1. Start with Architecture

**Lesson**: Clear architectural decisions upfront prevent refactoring later

**Applied**:
- Created comprehensive `ARCHITECTURE-DECISIONS.md` before coding
- Documented all major decisions with rationale
- Resulted in clean, consistent implementation

### 2. Documentation First

**Lesson**: Good documentation enables faster implementation

**Applied**:
- Wrote detailed `IMPLEMENTATION-PLAN.md` with every script, file, and test
- Created `TASK.md` with granular checklist
- Saved hours of "what do I do next?" thinking

### 3. Modular Design

**Lesson**: Modularity enables flexibility

**Applied**:
- GNU Stow packages can be installed selectively
- Bootstrap scripts are OS-specific but share utilities
- Configs are broken into small, focused files

### 4. Security First

**Lesson**: Secrets management is critical, not optional

**Applied**:
- 1Password integration from day 1
- No secrets in git (enforced by gitignore + validation)
- Template-based workflow for all projects

### 5. Cross-Platform from Start

**Lesson**: Adding cross-platform support later is painful

**Applied**:
- OS detection built into utilities
- Platform-specific bootstrap scripts
- Shared configs via GNU Stow

---

## Open Questions / Future Considerations

### Question 1: Syncthing vs Auto-Update?

**Context**: Auto-update has 30min delay, Syncthing is real-time

**Decision**: Start with auto-update (simpler), evaluate Syncthing in FASE 6

**Rationale**: Dotfiles don't change frequently enough to need real-time sync

### Question 2: VM Strategy Details

**Context**: Bind mount vs git clone for code, how to handle R2 assets

**Decision**: Git clone for code, bind mount for R2 assets (read-only)

**Rationale**: Independent git history, shared assets for efficiency

### Question 3: Windows Support?

**Context**: Should we add Windows support?

**Decision**: Not in FASE 1-6, but architecture allows future addition

**Rationale**: Focus on current needs (macOS + Ubuntu), design is extensible

### Question 4: Public vs Private Dotfiles?

**Context**: Some configs could be open-sourced

**Decision**: Keep private for now, evaluate in FASE 6

**Rationale**: Contains infrastructure details, decision can be made later

---

## Next Steps

1. ✅ **FASE 0 Complete**: Documentation and planning done
2. 🟡 **FASE 1 Ready**: Begin implementation of Foundation
   - Create directory structure
   - Write bootstrap scripts
   - Implement 5 priority stow packages
   - Add health checks and Makefile
3. ⚪ **FASE 2 Planned**: Implement Secrets & Sync
4. ⚪ **FASE 3-6 Planned**: Applications, VMs, Templates, Polish

**Immediate Next Action**: Start FASE 1.1 (Backup and Audit existing repo)

---

## Appendix: Command Quick Reference

### Backup Old Repo
```bash
mkdir -p backups/pre-refactor-$(date +%Y%m%d)
cp -R packages/ legacy-zsh/ bash/ scripts/ backups/pre-refactor-$(date +%Y%m%d)/
```

### Remove Old Stow Packages (if any)
```bash
cd packages
stow -D -t ~ */
```

### Install New Dotfiles (after FASE 1 complete)
```bash
cd ~/dev/projects/dotfiles
make install
```

### Health Check
```bash
make health
```

### Sync Changes
```bash
# Manual
git add -A && git commit -m "chore: update dotfiles" && git push

# Automatic (after FASE 2)
# Runs every 30min via LaunchAgent/systemd
```

---

**Document Version**: 1.0
**Created**: 2025-01-17
**Author**: Claude + Matteo Cervelli
**Status**: Complete - Repository refactor documented and ready for implementation
