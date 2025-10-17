# Architecture Decisions Record (ADR)

**Project**: Personal Dotfiles Management System
**Date**: 2025-01-17
**Status**: Active Development
**Last Updated**: 2025-01-17

---

## Executive Summary

This document captures all architectural decisions for the dotfiles project, a comprehensive system for managing development environment configurations across multiple macOS machines and Ubuntu VMs using GNU Stow, 1Password CLI, and Cloudflare R2.

---

## Core Principles

### 1. **Automation First**
- Complete automation of macOS and Ubuntu environment setup
- Minimal manual intervention required
- Idempotent scripts that can be run multiple times safely

### 2. **Security by Default**
- No secrets committed to git (ever)
- 1Password CLI for all secret management
- Per-machine SSH keys (not shared)

### 3. **Cross-Platform Support**
- Primary: macOS (MacBook Pro + Mac Studio)
- Secondary: Ubuntu VMs (development, testing, production simulation)
- Future: Windows support consideration

### 4. **Modularity**
- GNU Stow packages for selective deployment
- Independent script modules
- Clear separation of concerns

---

## Strategic Decisions

### Decision 1: XDG Base Directory Compliance

**Status**: ✅ APPROVED (Hybrid Approach - Option C)

**Context**:
macOS applications don't follow XDG Base Directory specification (`~/.config/`), resulting in configuration files scattered across `~/.`, `~/Library/`, etc. This makes version control and synchronization difficult.

**Options Evaluated**:
- **Option A**: Aggressive symlink redirect (force all apps to use `~/.config/`)
- **Option B**: Conservative Stow multi-target (respect macOS conventions)
- **Option C**: Hybrid approach (case-by-case decisions, documented)

**Decision**: **Option C - Hybrid Approach**

**Rationale**:
- **Textual/versionable configs** → force to `~/.config/` where possible (with symlink redirects)
- **Binary/GUI preferences** → keep in original macOS locations + backup scripts
- **Document exceptions** in `docs/xdg-compliance.md`
- Balance between cleanliness and stability

**Implementation**:
- Create `scripts/xdg-compliance/app-mappings.yml` for tracking decisions
- Create redirect symlinks for compatible apps
- Document each app's config strategy individually
- Priority apps to handle: iTerm2, Cursor, git, ssh, zsh

**Consequences**:
- ✅ Cleaner home directory structure
- ✅ Better version control visibility
- ⚠️ Requires per-app testing and documentation
- ⚠️ May break on app updates (mitigated by health checks)

---

### Decision 2: Bootstrap Strategy

**Status**: ✅ APPROVED (Modular Pipeline)

**Context**:
Need to install dotfiles from scratch on new machines. Trade-off between simplicity (one big script) and flexibility (modular scripts).

**Options Evaluated**:
- **Option A**: Monolithic install script
- **Option B**: Modular pipeline with numbered scripts
- **Option C**: Makefile orchestration with modular scripts

**Decision**: **Option B + C - Modular Scripts + Makefile Interface**

**Rationale**:
- Modular scripts allow granular control and debugging
- Makefile provides unified interface for common operations
- README provides human-readable installation guide
- Best of both worlds: flexibility + usability

**Implementation**:
```bash
# Makefile interface
make install    # Full installation
make stow       # Just symlink packages
make health     # Health checks

# Modular scripts
scripts/bootstrap/
├── install.sh              # Master orchestrator
├── macos-bootstrap.sh      # macOS dependencies
└── ubuntu-bootstrap.sh     # Ubuntu dependencies
```

**Consequences**:
- ✅ Easy to debug individual components
- ✅ Reusable script modules
- ✅ Clear execution order
- ⚠️ Slightly more complex initial setup

---

### Decision 3: Secrets Management

**Status**: ✅ APPROVED (1Password CLI + op inject)

**Context**:
Need secure, reproducible secret injection for development projects without committing secrets to git.

**Options Evaluated**:
- **Option A**: Only `op inject` (no persistent .env files)
- **Option B**: `op inject` → `~/.secrets/` → symlink to projects
- **Option C**: git-crypt for encrypted .env files
- **Option D**: SOPS + age encryption

**Decision**: **Option A - Pure `op inject` with Project Wrapper Scripts**

**Rationale**:
- Maximum security: no secrets on disk longer than necessary
- 1Password already in use across infrastructure
- `op inject` supports Docker Compose with `op run`
- Simple, standardized workflow across all projects

**Implementation**:
```bash
# Template in project (versioned)
project/.env.template

# Injection via wrapper script
project/scripts/dev-setup.sh:
  - git fetch/pull
  - op inject -i .env.template -o .env
  - sync R2 assets
  - update manifest

# Docker Compose
op run --env-file=.env.template -- docker compose up
```

**Consequences**:
- ✅ No secrets persisted on disk
- ✅ Auditable template files in git
- ✅ Works seamlessly with Docker
- ⚠️ Requires `eval $(op signin)` session management
- ✅ Mitigated: wrapper scripts handle auth automatically

---

### Decision 4: R2 Storage Strategy

**Status**: ✅ APPROVED (Single Bucket with Project Namespaces)

**Context**:
Binary assets (ML models, datasets, media) too large for git. Need cloud storage with sync capabilities across macOS and Ubuntu VMs.

**Options Evaluated**:
- **Option A**: Single bucket `dotfiles-assets` with project prefixes
- **Option B**: Separate bucket per project

**Decision**: **Option A - Single Bucket**

**Rationale**:
- Personal use (single user, no permission complexity)
- Simplified rclone configuration (one remote)
- Lower R2 costs (egress pooled)
- Namespace collision easily avoided with project prefixes

**Implementation**:
```
R2 Bucket: dotfiles-assets
Structure:
├── project-1/
│   ├── datasets/
│   ├── media/
│   └── uploads/
├── project-2/
│   └── models/
└── shared/
    └── fonts/
```

**Manifest System** (YAML):
```yaml
# project/.r2-manifest.yml
project: my-app
version: "1.0"
assets:
  - path: data/models/whisper.bin
    r2_key: my-app/models/whisper.bin
    size: 2400000000
    sha256: abc123...
    sync: true
    devices: [macbook, ubuntu-vm-1]
```

**Consequences**:
- ✅ Simple management, one rclone remote
- ✅ Lower costs
- ✅ Easy to reorganize structure
- ⚠️ Must maintain consistent naming conventions
- ✅ Mitigated: documented in `docs/sync-strategy.md`

---

### Decision 5: VM Strategy

**Status**: ✅ APPROVED (Multi-Purpose + Specialized + Ephemeral)

**Context**:
Need Ubuntu VMs for Docker workloads (avoiding Rosetta penalty on macOS ARM), testing, and production simulation.

**VM Types**:
1. **Primary Dev VM**: Ubuntu LTS, multi-purpose, Docker Compose, persistent
2. **Experimental VMs**: Fedora/Arch for testing different distros
3. **Minimal VMs**: Alpine Linux, VPS-like, production testing, ephemeral

**Workflow Decision**: **Git Clone + Bind Mount Assets**

**Rationale**:
- Code: `git clone` on VM (independent, no filesystem sharing issues)
- Assets: Parallels bind mount from macOS `~/r2-assets/` (shared, read-only)
- Work primarily on VM via Tailscale SSH (VSCode Remote)
- Mac Studio as always-on hub

**Implementation**:
```
macOS (Mac Studio):
  ~/dev/projects/my-app/          # Git repo
  ~/r2-assets/my-app/             # R2 assets (bind mount source)

Ubuntu VM:
  ~/dev/projects/my-app/          # Git clone (independent)
  ~/r2-assets/                    # Parallels mount (read-only from macOS)

Workflow:
  1. Work on VM via VSCode Remote SSH (Tailscale)
  2. Git commit/push from VM
  3. Access assets via ~/r2-assets/ mount
  4. Docker runs natively on VM (no Rosetta)
```

**Consequences**:
- ✅ Native Docker performance on VM
- ✅ Independent git histories (no conflicts)
- ✅ Shared R2 assets (no duplication)
- ✅ Can work from anywhere via Tailscale
- ⚠️ Requires Parallels bind mount setup
- ⚠️ Git sync discipline (commit/push regularly)

---

### Decision 6: Sync Strategy (Dotfiles)

**Status**: ✅ APPROVED (Auto-Update to GitHub)

**Context**:
Need to keep dotfiles synchronized between MacBook Pro, Mac Studio, and Ubuntu VMs.

**Options Evaluated**:
- **Option A**: Syncthing (real-time sync between devices)
- **Option B**: Auto-update to GitHub (30min cron/timer)
- **Option C**: Hybrid (Syncthing + GitHub)

**Decision**: **Option B - Auto-Update to GitHub**

**Rationale**:
- GitHub as source of truth (versionable, rollback)
- Works seamlessly with VMs (no Syncthing setup needed)
- Simple: LaunchAgent (macOS) / systemd timer (Ubuntu)
- Syncthing deferred to FASE 6 (can add later if needed)

**Implementation**:
```bash
# Auto-update script (runs every 30min)
scripts/sync/auto-update-dotfiles.sh:
  1. Check for changes in dotfiles repo
  2. If changes: commit + push to GitHub
  3. Other devices pull automatically

# macOS: LaunchAgent
~/Library/LaunchAgents/com.dotfiles.autoupdate.plist

# Ubuntu: systemd timer
/etc/systemd/system/dotfiles-autoupdate.timer
```

**Consequences**:
- ✅ Version controlled sync
- ✅ Works across all platforms
- ✅ Simple setup
- ⚠️ 30min delay (acceptable for dotfiles)
- ✅ Can add Syncthing later for critical files if needed

---

### Decision 7: Backup Strategy

**Status**: ✅ APPROVED (Multi-Layer: GitHub + NAS + Time Machine)

**Context**:
Existing backup infrastructure: Time Machine, iCloud Drive, Synology NAS. Need to integrate dotfiles backups.

**Backup Layers**:

**Layer 1: GitHub (Primary, Text Configs)**
- Private repository
- Versionable configurations
- Scripts, templates, documentation
- **NOT for**: binary assets, secrets

**Layer 2: Synology NAS (Secondary, Full Snapshots)**
- Daily snapshots of dotfiles repo
- R2 assets mirror (rclone sync)
- Pre-migration backups
- Disaster recovery

**Layer 3: Time Machine (Local, Complete System)**
- Full Mac backup (includes dotfiles)
- Hourly snapshots
- Quick local restore

**Layer 4: iCloud Drive (Documents Only)**
- Critical documents (not dotfiles)
- Automatic sync

**Implementation**:
```bash
# Daily NAS backup (via cron/LaunchAgent)
scripts/backup/sync-to-nas.sh

# Restore from NAS (if GitHub unavailable)
scripts/backup/restore-from-nas.sh

# Pre-migration snapshot (manual)
scripts/backup/snapshot.sh
```

**Consequences**:
- ✅ Redundant backups (3-2-1 rule)
- ✅ Version control + disaster recovery
- ✅ Leverages existing infrastructure
- ⚠️ Manual NAS backup setup required
- ✅ Can be automated in FASE 6

---

### Decision 8: Manifest Format

**Status**: ✅ APPROVED (YAML)

**Context**:
Need standardized format for R2 asset manifests.

**Options**: YAML vs JSON vs TOML

**Decision**: **YAML**

**Rationale**:
- More readable than JSON
- Supports comments (useful for documentation)
- Standard for configuration files
- Well supported by tools (yq, Python, etc.)

**Consequences**:
- ✅ Human-readable manifests
- ✅ Easy to edit manually if needed
- ⚠️ Requires `yq` or Python for parsing

---

### Decision 9: Stow Package Structure

**Status**: ✅ APPROVED (Prioritized Packages)

**Initial Priority Packages** (FASE 1):
1. **shell** - ZSH + Bash configs (cross-platform)
2. **git** - Git config, templates, hooks
3. **ssh** - SSH config with Tailscale network
4. **1password** - 1Password CLI configuration
5. **llm-tools** - Claude Code + MCP servers

**Future Packages** (FASE 3+):
- cursor (editor configs)
- iterm2 (terminal configs)
- dev-env (pyenv, nvm, docker)
- bin (custom executables)

**Rationale**:
- Start with essential CLI tools
- Add GUI apps after foundation is solid
- Modular: can stow packages independently

---

## Integration Points with Existing Infrastructure

From [Technology Stack for my infrastructure.md](Technology Stack for my infrastructure.md):

### Tailscale Network
- SSH configs for Mac Studio, MacBook, VMs
- VSCode Remote SSH access
- Secure communication between devices

### 1Password
- CLI already in use
- Vault structure: personal, business (Ad Limen)
- Secret references in .env.template files

### Cloudflare
- R2 for binary assets storage
- CDN for static site assets
- Rclone S3-compatible interface

### Docker Infrastructure
- Compose files in dotfiles for environment replication
- PostgreSQL, Redis, Qdrant, MinIO, N8N, Ollama
- MCP servers (15+)

### Claude Desktop + MCP
- 15+ Model Context Protocol servers
- Configurations in `llm-tools` stow package
- Integration with development workflow

### Synology NAS
- Backup destination for dotfiles snapshots
- R2 assets mirror
- Time Machine alternative

---

## Constraints and Limitations

### Technical Constraints
- macOS Rosetta penalty for Docker → Use Ubuntu VMs for Docker workloads
- GNU Stow doesn't handle conflicts → Pre-backup existing configs
- 1Password CLI requires active session → Wrapper scripts handle auth
- R2 egress costs → Sync selectively, use manifests to track

### Operational Constraints
- Repository must remain private (contains infrastructure details)
- Secrets never committed to git (enforced by .gitignore + pre-commit hooks)
- Cross-platform compatibility (macOS + Ubuntu, future Windows)
- Must work offline (local caching, graceful degradation)

### Resource Constraints
- Storage: R2 costs (mitigated by selective sync)
- Bandwidth: R2 egress (mitigated by local caching)
- Time: Initial setup 10-14 hours (FASE 1-2)

---

## Future Considerations (Post FASE 1-2)

### FASE 3: Applications & XDG Compliance
- Brewfile complete (audit + cleanup)
- Cursor/VSCode extensions management
- iTerm2 configuration
- XDG compliance implementation
- Application cleanup automation

### FASE 4: VM Ubuntu Setup
- Ubuntu bootstrap complete
- Docker + docker-compose setup
- VM-specific stow packages
- Parallels mount automation
- Cross-platform testing

### FASE 5: Templates & Automation
- Project templates (Python, Next.js, Swift)
- Template generation scripts
- Advanced health checks
- Config update mechanism (pull from system)
- Diff/compare tools
- Rollback mechanism

### FASE 6: Monitoring & Polish
- Syncthing evaluation (if needed)
- Alertmanager integration
- Complete backup automation
- Documentation finalization
- Screenshot documentation
- Public/private split (if open-sourcing)

### Windows Support (Future)
- PowerShell scripts
- Windows Package Manager
- Platform detection in bootstrap
- Windows-specific stow packages

---

## Decision Log

| Date | Decision | Status | Notes |
|------|----------|--------|-------|
| 2025-01-17 | XDG Compliance: Hybrid Approach | Approved | Case-by-case, documented |
| 2025-01-17 | Bootstrap: Modular + Makefile | Approved | Best flexibility + usability |
| 2025-01-17 | Secrets: 1Password CLI only | Approved | Maximum security |
| 2025-01-17 | R2: Single bucket | Approved | Personal use, simplified |
| 2025-01-17 | VM: Git clone + bind mount | Approved | Native performance |
| 2025-01-17 | Sync: Auto-update to GitHub | Approved | Syncthing deferred |
| 2025-01-17 | Backup: Multi-layer strategy | Approved | GitHub + NAS + Time Machine |
| 2025-01-17 | Manifest: YAML format | Approved | Readable, standard |
| 2025-01-17 | Stow: 5 priority packages | Approved | Shell, git, ssh, 1password, llm-tools |

---

## References

- [webpro dotfiles guide](https://dotfiles.github.io/)
- [GNU Stow manual](https://www.gnu.org/software/stow/manual/stow.html)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [Rclone Documentation](https://rclone.org/)
- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-17 | Claude + Matteo | Initial architecture decisions captured |

---

**Next Steps**: Proceed with [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md) for detailed execution plan.
