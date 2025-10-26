# Dotfiles

Personal dotfiles and development environment configuration for **macOS** and **Linux** (Ubuntu, Fedora, Arch).

## 🚀 Features

- ✅ ZSH configuration with custom aliases and functions
- ✅ Git configuration and aliases
- ✅ Development tools setup
- ✅ **Cross-Platform Package Management** - Linux package mappings for Ubuntu, Fedora, Arch
- ✅ **Application Management** - Audit and cleanup macOS applications
- ✅ **Asset Management System** - Central library with auto-update propagation
- ✅ **Environment-Aware Helpers** - TypeScript & Python asset URL resolution
- ✅ R2 sync with Cloudflare integration
- 🚧 IDE configurations (in progress)

## 🛠️ Tech Stack

- [ZSH](https://www.zsh.org/) - Shell
- [Git](https://git-scm.com/) - Version control
- **macOS**: [Homebrew](https://brew.sh/) - Package manager
- **Linux**: APT (Ubuntu), DNF (Fedora), Pacman (Arch) + Snap/Flatpak

## 📦 Installation

### macOS

```bash
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles
./install.sh
```

### Linux (Ubuntu, Fedora, Arch)

#### Option A: Automated Bootstrap (Recommended)

```bash
# Clone repository
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles

# Ubuntu (automated setup)
./scripts/bootstrap/ubuntu-bootstrap.sh              # Minimal setup
./scripts/bootstrap/ubuntu-bootstrap.sh --with-docker  # With Docker

# Fedora (automated setup)
./scripts/bootstrap/fedora-bootstrap.sh              # Minimal setup
./scripts/bootstrap/fedora-bootstrap.sh --with-packages  # Full dev environment
./scripts/bootstrap/fedora-bootstrap.sh --dry-run    # Preview changes

# Arch (manual - see docs)
./scripts/bootstrap/install-dependencies-arch.sh
```

#### Option B: Manual Package Installation

```bash
# Clone repository
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles

# Generate package lists
./scripts/apps/generate-linux-packages.sh

# Install packages (choose your distro)
sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh  # Ubuntu 24.04 LTS
sudo ./scripts/bootstrap/install-dependencies-fedora.sh  # Fedora 40+
sudo ./scripts/bootstrap/install-dependencies-arch.sh    # Arch Linux

# Setup dotfiles
make install
```

**See also:**
- [Linux Setup Guide](docs/guides/linux-setup-guide.md)
- [Linux Package Management](applications/linux/README.md)
- [Bootstrap Strategies](docs/os-configurations/BOOTSTRAP-STRATEGIES.md) - Detailed bootstrap documentation
- **Parallels VM Guides:**
  - [Guide 1: Ubuntu VM Creation](docs/guides/parallels-1-vm-creation.md) - Create Ubuntu VM
  - [Guide 2: Development Environment](docs/guides/parallels-2-dev-setup.md) - Full dev setup with Docker
  - [Guide 3: Fedora VM Creation](docs/guides/parallels-3-fedora-vm-creation.md) - Create Fedora VM (dev or kids)
  - [Guide 4: Kids Learning Environment](docs/guides/parallels-4-fedora-kids-setup.md) - Safe learning with parental controls

## 🧪 Usage

```bash
# Source the configurations
source ~/.zshrc
```

## 📦 Asset Management System

Comprehensive asset management with central library, auto-update propagation, and environment-aware URL resolution.

### Quick Start

**Update central library and propagate to projects**:
```bash
update-cdn
# Regenerates manifest → Shows changes → Propagates to projects → Syncs to R2
```

**Sync project assets**:
```bash
cd ~/dev/projects/MY_PROJECT
sync-project pull
# Copies from ~/media/cdn/ (fast) or downloads from R2 (fallback)
```

**Sync library to R2**:
```bash
cdnsync
# Uploads ~/media/cdn/ to Cloudflare R2
```

### Key Features

1. **Central Library** (`~/media/cdn/`)
   - Single source of truth for shared assets
   - Automatic dimension extraction for images
   - Bidirectional R2 sync

2. **Auto-Update Propagation**
   - Detects library changes (size, dimensions, checksum)
   - Updates all affected projects automatically
   - Shows before/after comparison

3. **Library-First Sync**
   - Projects copy from library first (<0.1s per file)
   - Falls back to R2 download if needed (1-5s per file)
   - 90% library efficiency typical

4. **Environment-Aware Assets**
   - Development: Uses local paths (`/media/logo.svg`)
   - Production: Uses CDN URLs (`https://cdn.example.com/logo.svg`)
   - Zero dependencies TypeScript & Python helpers

### Command Reference

| Command | Purpose | Documentation |
|---------|---------|---------------|
| `update-cdn` | Update library + propagate + sync | [Central Library Guide](sync/library/README.md) |
| `sync-project pull` | Sync project assets | [Project Sync Guide](sync/manifests/README.md#3-sync-project-assets-new---issue-30) |
| `cdnsync` | Sync library to R2 | [Rclone Setup](sync/rclone/README.md) |
| `setup-rclone` | Configure R2 connection | [Rclone Setup](sync/rclone/README.md) |
| `test-rclone` | Test R2 connection | [Rclone Setup](sync/rclone/README.md) |

## 🔄 Auto-Update Dotfiles

Automatic bidirectional synchronization of dotfiles changes across machines every 30 minutes using a **pull-before-push strategy**.

### Features

- **Pull-Before-Push**: Automatically fetches remote changes before committing local changes
- **Smart conflict handling**: Auto-resolves non-overlapping changes, stops on real conflicts
- **Safe stashing**: Preserves local work when pulling remote updates
- **Branch safety**: Only operates on `main` branch (skips feature branches)
- **Platform support**: macOS (LaunchAgent) and Ubuntu (systemd)
- **Performance**: Early exit when no changes detected (~1s check)
- **Offline-safe**: Gracefully handles network failures
- **Logging**: Full logs for debugging on both platforms

### How It Works

Every 30 minutes, the script:
1. **Fetch** remote changes from GitHub
2. **Stash** local uncommitted changes (if any)
3. **Pull** remote changes with rebase
4. **Pop** stashed changes back
5. **Commit** local changes (if any)
6. **Push** to GitHub

**Result**: Your dotfiles stay in sync across all machines automatically, with minimal conflicts.

### Installation

```bash
# Install auto-update service
./scripts/sync/install-autoupdate.sh
```

**macOS**: Creates LaunchAgent, runs every 30 minutes
**Ubuntu**: Creates systemd timer, runs every 30 minutes

### Manual Usage

```bash
# Run auto-update manually
./scripts/sync/auto-update-dotfiles.sh
```

### Monitoring

**macOS**:
```bash
# View logs
tail -f /tmp/dotfiles-autoupdate.log
tail -f /tmp/dotfiles-autoupdate.err

# Check if running
launchctl list | grep dotfiles
```

**Ubuntu**:
```bash
# View logs
journalctl -u dotfiles-autoupdate -f

# Check timer status
systemctl status dotfiles-autoupdate.timer
```

## 🐳 Docker on Ubuntu

Complete Docker Engine + Compose v2 setup for Ubuntu 24.04 LTS with Parallels VM optimization and remote Docker context from macOS.

### Quick Start

```bash
# Ubuntu only - Install Docker Engine + Compose v2
sudo ./scripts/bootstrap/install-docker.sh

# Or install Ubuntu packages + Docker together
make ubuntu-full

# Verify installation
docker --version
docker compose version
docker run hello-world
```

### Remote Docker Context (macOS → Ubuntu VM)

Access Ubuntu Docker from macOS without SSH every time:

```bash
# Create Docker context (from macOS)
docker context create ubuntu-vm --docker "host=ssh://ubuntu-vm"

# Use Ubuntu Docker from macOS
docker context use ubuntu-vm
docker ps
docker compose up -d

# Switch back to macOS Docker
docker context use default
```

### Features

- ✅ Official Docker repository (24.0+, not Ubuntu's docker.io)
- ✅ Docker Compose v2 plugin (integrated, faster)
- ✅ systemd service (enabled on boot)
- ✅ User permissions (docker group, no sudo required)
- ✅ Parallels shared folders (`/Users/matteo/dev` → `/mnt/dev`)
- ✅ Remote context via SSH (work from macOS, run on Ubuntu)
- ✅ Comprehensive troubleshooting guide

**Complete Guides**:
- [Guide 1: VM Creation](docs/guides/parallels-1-vm-creation.md) - Create Ubuntu VM from ISO
- [Guide 2: Development Setup](docs/guides/parallels-2-dev-setup.md) - Docker, dotfiles, and full dev environment

### Disable/Enable

**macOS**:
```bash
# Disable
launchctl unload ~/Library/LaunchAgents/com.dotfiles.autoupdate.plist

# Re-enable
launchctl load ~/Library/LaunchAgents/com.dotfiles.autoupdate.plist
```

**Ubuntu**:
```bash
# Disable
sudo systemctl stop dotfiles-autoupdate.timer

# Re-enable
sudo systemctl start dotfiles-autoupdate.timer
```

### Asset Helpers

Copy environment-aware asset helpers to your projects:

**TypeScript/React** (`templates/project/lib/assets.ts`):
```typescript
import { useAsset } from '@/lib/assets';

const logoUrl = useAsset('/media/logo.png', 'https://cdn.example.com/logo.png');
// Dev: '/media/logo.png' | Prod: 'https://cdn.example.com/logo.png'
```

**Python/FastAPI** (`templates/project/lib/assets.py`):
```python
from lib.assets import get_asset_url

logo_url = get_asset_url('/static/logo.png', 'https://cdn.example.com/logo.png')
# Dev: '/static/logo.png' | Prod: 'https://cdn.example.com/logo.png'
```

### Documentation

- **Central Library**: [sync/library/README.md](sync/library/README.md) - Managing ~/media/cdn/
- **Project Manifests**: [sync/manifests/README.md](sync/manifests/README.md) - Asset sync workflows
- **Asset Helpers**: [templates/README.md](templates/README.md) - TypeScript & Python helpers
- **Schema Reference**: [sync/manifests/schema.yml](sync/manifests/schema.yml) - Manifest format
- **Architecture**: [docs/ASSET-MANAGEMENT-PLAN.md](docs/ASSET-MANAGEMENT-PLAN.md) - Design decisions

### Example Workflow

```bash
# 1. Add new logo to central library
cp ~/Downloads/new-logo.svg ~/media/cdn/logos/company/

# 2. Update and propagate
update-cdn
# Shows: [+] logos/company/new-logo.svg (22.1KB, 1024×1024) - NEW
# Prompts: Propagate to projects? [Y/n]
# Updates: APP-Portfolio, WEB-Landing (2 projects)

# 3. On another machine, sync project
cd ~/dev/projects/APP-Portfolio
git pull  # Get updated .r2-manifest.yml
sync-project pull
# Copies new-logo.svg from ~/media/cdn/ (or downloads from R2)

# 4. Use in code with environment awareness
# Development: /media/new-logo.svg
# Production: https://cdn.example.com/logos/company/new-logo.svg
```

## 🗂️ Application Management

Comprehensive system for auditing and cleaning up macOS applications across Homebrew, Mac App Store, and manual installations.

### Quick Start

**Audit all installed applications**:
```bash
./scripts/apps/audit-apps.sh
# Generates: applications/current-apps.txt
```

**Cleanup unwanted applications**:
```bash
# 1. Review and edit removal list
vim applications/remove-apps.txt

# 2. Preview changes (dry-run, safe)
./scripts/apps/cleanup-apps.sh

# 3. Execute cleanup
./scripts/apps/cleanup-apps.sh --execute
```

### Features

1. **Comprehensive Discovery**
   - Homebrew casks (`brew list --cask`)
   - Mac App Store apps (`mas list`)
   - Manual installations (`/Applications/*.app`)
   - Automatic categorization

2. **Safe Cleanup**
   - **Dry-run by default** - No deletions without explicit --execute flag
   - User confirmation before removal
   - Smart detection: Homebrew vs manual apps
   - Proper uninstall methods (`brew uninstall --cask` or `rm -rf`)

3. **Workflow**
   - Audit → Review → Categorize → Test → Execute
   - Template files with instructions
   - Statistics and logging

### Command Reference

| Command | Purpose | Safety |
|---------|---------|--------|
| `./scripts/apps/audit-apps.sh` | Discover all applications | ✅ Read-only |
| `./scripts/apps/audit-apps.sh --verbose` | Detailed audit output | ✅ Read-only |
| `./scripts/apps/cleanup-apps.sh` | Preview removals (dry-run) | ✅ Safe |
| `./scripts/apps/cleanup-apps.sh --execute` | Actually remove apps | ⚠️  Destructive |
| `./scripts/apps/cleanup-apps.sh -e -y` | Skip confirmation | ⚠️  Dangerous |

### Example Workflow

```bash
# 1. Audit current applications
./scripts/apps/audit-apps.sh
# Output: applications/current-apps.txt
#   === Homebrew Casks (45) ===
#   === Mac App Store Apps (12) ===
#   === Manual Installations (8) ===

# 2. Review and decide what to remove
cat applications/current-apps.txt
vim applications/remove-apps.txt

# Add unwanted apps:
# google-chrome
# firefox
# microsoft-edge

# 3. Test with dry-run (safe preview)
./scripts/apps/cleanup-apps.sh
# Shows what would be removed, no actual changes

# 4. Execute cleanup
./scripts/apps/cleanup-apps.sh --execute
# Prompts for confirmation
# Removes listed apps
# Shows statistics

# 5. Update Brewfile to reflect current state
brew bundle dump --describe --force --file=system/macos/Brewfile
```

### Documentation

- **Detailed Guide**: [applications/README.md](applications/README.md)
- **Script Source**: [scripts/apps/](scripts/apps/)
- **Tests**: [tests/test-19-app-audit.bats](tests/test-19-app-audit.bats)

## 🏠 XDG Base Directory Compliance

Pragmatic hybrid approach to XDG compliance - cleaner home directory without breaking applications.

### Philosophy

**Pragmatism over purity**: We implement XDG compliance where it provides clear benefits without breaking application functionality or creating excessive complexity.

### Compliance Status

| Status | Count | Applications |
|--------|-------|--------------|
| ✅ Supported | 5 | Git, PostgreSQL, R, Less, Neovim |
| 🟡 Partial | 2 | Bash (history only), ZSH (history only) |
| ❌ Hardcoded | 2 | VS Code (use Settings Sync), iTerm2 (backup/restore) |
| ⚠️ Complex | 2 | Vim (use Neovim), Python (optional) |

### Quick Start

**Deploy XDG environment**:
```bash
# Install dev-env package
stow -t ~ dev-env

# Reload shell
source ~/.zshrc  # or source ~/.bashrc
```

**Verify**:
```bash
# Check XDG variables
echo $XDG_CONFIG_HOME  # ~/.config
echo $XDG_STATE_HOME   # ~/.local/state

# Check application configs
echo $PSQLRC           # ~/.config/postgresql/psqlrc
echo $HISTFILE         # ~/.local/state/bash/history
```

### What's XDG Compliant

**Fully Migrated** (native support):
- PostgreSQL: Config + history → `~/.config/postgresql/`, `~/.local/state/postgresql/`
- Less: History → `~/.local/state/less/`
- Git: Already at `~/.config/git/` ✅
- Neovim: Already at `~/.config/nvim/` ✅

**Partially Migrated**:
- Bash: History → `~/.local/state/bash/` (config files stay in `~/`)
- ZSH: History already managed by shell package

**NOT Migrated** (by design):
- **VS Code**: Use [Settings Sync](https://code.visualstudio.com/docs/editor/settings-sync) instead (cloud-based, more reliable)
- **iTerm2**: Use backup/restore scripts (`iterm2-backup`, `iterm2-restore`)

### iTerm2 Backup/Restore

```bash
# Backup preferences (version control)
iterm2-backup
# Creates: stow-packages/iterm2/backups/iterm2-preferences-TIMESTAMP.xml

# Restore on new machine
iterm2-restore
# Uses latest backup from stow-packages/iterm2/backups/
```

### Optional Features

**R Language** (if you use R):
```bash
# Edit: stow-packages/dev-env/.config/shell/dev-tools.sh
# Uncomment R environment variables
source ~/.zshrc
```

**Python History** (⚠️ complex, requires testing):
```bash
# Edit: stow-packages/dev-env/.config/shell/dev-tools.sh
# Uncomment PYTHONSTARTUP export
source ~/.zshrc

# Test thoroughly (see docs/xdg-compliance.md#python-history)
```

### Documentation

- **Strategy & Trade-offs**: [docs/xdg-compliance.md](docs/xdg-compliance.md) - Comprehensive guide with per-app analysis
- **Application Inventory**: [scripts/xdg-compliance/app-mappings.yml](scripts/xdg-compliance/app-mappings.yml) - Full compliance status
- **dev-env Package**: [stow-packages/dev-env/README.md](stow-packages/dev-env/README.md) - Installation and usage
- **iTerm2 Package**: [stow-packages/iterm2/README.md](stow-packages/iterm2/README.md) - Backup/restore workflow

### Why Some Apps Aren't XDG Compliant

We **intentionally exclude** some applications from XDG migration because:

- **VS Code (macOS)**: Hardcoded location, conflicts with cloud Settings Sync
- **iTerm2**: Binary plist format, export/import workflow more reliable than symlinks
- **Vim**: Complex workarounds prone to breakage (use Neovim instead)
- **Python history**: Risk of dual history files, affects all Python sessions

See [docs/xdg-compliance.md](docs/xdg-compliance.md) for detailed analysis and platform-specific downsides.

## 📁 Project Structure

```text
config/     # Configuration files
scripts/    # Installation and utility scripts
docs/       # Documentation
dotfiles/   # Actual dotfiles (.zshrc, .gitconfig, etc.)
```

## 🤝 Contributing

Contributions are welcome! Please open an issue or pull request.

## 📄 License

Distributed under the MIT License. See LICENSE for more information.
