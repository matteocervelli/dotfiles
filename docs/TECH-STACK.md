# Technology Stack

This document outlines the complete technology stack used in the dotfiles project.

## Core Technologies

### Shell Environment

- **Primary Shell**: Bash 3.2+ (macOS default)
  - All scripts compatible with Bash 3.2 (no associative arrays)
  - Portable across macOS and Linux
- **User Shell**: ZSH with Oh My Zsh
  - Powerlevel10k theme
  - 32 curated plugins (see [stow-packages/shell](../stow-packages/shell/))
  - Cross-platform configuration

### Package Managers

- **macOS**: Homebrew
  - Formulae (CLI tools)
  - Casks (GUI applications)
  - Mac App Store integration via `mas-cli`
- **Ubuntu**: APT (Advanced Package Tool)
  - System packages via `apt-get`
  - Debian repository management

### Configuration Management

- **GNU Stow** - Symlink farm manager
  - Version: 2.3.1+
  - Manages dotfile deployment via symlinks
  - Modular package-based approach
  - Cross-platform (macOS, Linux)

## Development Tools

### Version Control

- **Git** 2.40+
  - 1Password SSH signing integration
  - GPG commit signing support
  - Comprehensive alias configuration (30+ aliases)
  - Git hooks via templates

### Secret Management

- **1Password CLI** (`op`)
  - Version: 2.20+
  - Secret injection for environment files
  - SSH agent integration
  - GPG key management

### Cloud Storage & Sync

- **Rclone** 1.60+
  - Cloudflare R2 integration
  - S3-compatible API support
  - Asset synchronization to remote storage
  - Backup and restore capabilities

### Data Processing

- **yq** 4.30+
  - YAML/JSON/XML processor
  - Manifest parsing and generation
  - Schema validation

- **ImageMagick** 7.1+
  - Image dimension extraction
  - Content-based file type detection
  - Used in manifest generation (FASE 2.7)

### Testing

- **BATS** (Bash Automated Testing System)
  - Version: 1.8.0+
  - Framework for Bash script testing
  - Test suites for all major scripts
  - Coverage: 153+ tests across project

## Languages & Scripting

### Shell Scripting

- **Bash** - Primary scripting language
  - Strict mode: `set -euo pipefail`
  - Modular functions
  - Comprehensive error handling
  - Logging utilities ([scripts/utils/logger.sh](../scripts/utils/logger.sh))

### Configuration Formats

- **YAML** - Configuration files
  - Manifests (R2 asset tracking)
  - Schema definitions
  - Docker Compose files

- **Shell Script** - Executable configurations
  - `.zshrc`, `.bashrc`
  - Environment setup scripts
  - Modular config loading

## System Configuration

### Fonts

- **Font Management** - Automated installation and synchronization
  - **Total Fonts**: 179 custom fonts
  - **Categories**:
    - Essential (10): MesloLGS NF (Powerlevel10k), Lato, Raleway
    - Coding (16): Hack, Space Mono, IBM 3270, CPMono
    - Powerline (120+): Terminal fonts with special glyphs
    - Optional (33): Complete font families for design
  - **Location**: `~/Library/Fonts/` (macOS user-level)
  - **Cache Management**: `atsutil databases -remove` (macOS)
  - **Verification**: Integrated into health checks
  - **Configuration**: `fonts/fonts.yml` (parsed with yq)
  - **Installation**: `scripts/fonts/install-fonts.sh`
    - Selective modes: essential, coding, powerline, all
    - Performance: <5s essential, <15s all fonts
    - Bootstrap integration (auto-installs essential)

## Platform Support

### Primary Platform: macOS

- **macOS Sequoia** (15.x)
- **Architecture**: Apple Silicon (M1/M2) and Intel
- **Shell**: ZSH (default), Bash (scripting)
- **Services**:
  - LaunchAgents for background tasks
  - Keychain integration
  - Spotlight integration
  - Font management (`atsutil` for font cache)

### Secondary Platform: Ubuntu Linux

- **Ubuntu 24.04 LTS** (Noble Numbat)
- **Architecture**: x86_64, ARM64 (Parallels VMs on Apple Silicon)
- **Shell**: Bash (default)
- **Services**:
  - systemd units (services and timers)
  - cron jobs
  - Docker Engine + Compose v2 (native containerization)

### Future Platform: Windows (Planned)

- **WSL2** (Windows Subsystem for Linux)
- **PowerShell** for native Windows scripts
- **Git Bash** compatibility

## Infrastructure Integration

### Network

- **Tailscale** - Mesh VPN
  - SSH configuration for device network
  - Secure remote access
  - Cross-device syncing

### Virtualization & Containerization

- **Parallels Desktop** (macOS)
  - Ubuntu 24.04 LTS VMs (Apple Silicon/Intel)
  - Shared folders: `/Users/matteo/dev` → `/mnt/dev`
  - Parallels Tools for optimal performance
  - 4-8 vCPU, 8GB RAM, 50GB disk (typical configuration)

- **Docker Engine** (Ubuntu)
  - Version: 24.0+ from official Docker repository
  - Docker Compose v2 (plugin, not standalone)
  - Docker BuildKit for advanced builds
  - Storage driver: overlay2 (default)
  - systemd service management
  - Remote Docker context accessible from macOS via SSH
  - User-level access via docker group

### Monitoring & Logging

- **System Logging**
  - macOS: unified logging (`log show`)
  - Ubuntu: journalctl (systemd)
  - Custom logger utility with colored output

## Asset Management System

### Central Library

- **Location**: `~/media/cdn/`
- **Structure**: Organized asset repository
- **Format**: File-based with YAML manifests

### Manifest System

- **Format**: YAML (`.r2-manifest.yml`)
- **Fields**: path, r2_key, size, checksum (SHA256), dimensions, type, sync mode
- **Schema**: [sync/manifests/schema.yml](../sync/manifests/schema.yml)

### Sync Strategies

- **Library-First**: Copy from local (`~/media/cdn/`) → Fallback to R2
- **CDN-Only**: Verify URL, skip local sync
- **Download**: Direct R2 download
- **Manual**: User-initiated download

### Environment Modes

- `cdn-production-local-dev` (default)
- `cdn-always`
- `local-always`

## Automation & CI/CD

### Auto-Update System

- **macOS**: LaunchAgent (`com.dotfiles.autoupdate.plist`)
- **Ubuntu**: systemd timer (`dotfiles-autoupdate.timer`)
- **Frequency**: Every 30 minutes
- **Strategy**: Pull-before-push with conflict detection

### Scripts Organization

```
scripts/
├── apps/           # Application management
├── backup/         # Backup and restore
├── bootstrap/      # Dependency installation
├── health/         # System health checks
├── secrets/        # 1Password integration
├── stow/           # GNU Stow automation
├── sync/           # Asset and dotfile synchronization
├── utils/          # Shared utilities
└── xdg-compliance/ # XDG Base Directory compliance
```

## Dependencies

### Required (Bootstrap Phase)

```bash
# macOS
brew install stow          # GNU Stow 2.3.1+
brew install --cask 1password-cli
brew install rclone
brew install yq
brew install imagemagick
brew install mas           # Mac App Store CLI

# Ubuntu
apt-get install stow
wget -O 1password.deb https://downloads.1password.com/...
apt-get install rclone
wget -qO /usr/local/bin/yq https://github.com/...
apt-get install imagemagick
```

### Optional (Extended Features)

- **Docker** - Containerized development
- **Node.js** (via nvm) - JavaScript development
- **Python** (via pyenv) - Python development
- **Swift** - macOS/iOS development

## Testing & Quality

### Test Coverage

- **BATS Tests**: 153+ tests
  - Manifest system: 30 tests
  - Project sync: 42 tests
  - Auto-update: 24 tests
  - Environment helpers: 57 tests
- **Pass Rate**: 97%+ across all suites

### Code Quality Standards

- **Line Limit**: 500 lines per file
- **Modular Design**: Single responsibility principle
- **Error Handling**: Comprehensive with logging
- **Documentation**: Inline comments and READMEs

## Performance Benchmarks

- **Manifest Generation**: < 10 seconds for 100 files
- **Project Sync**: 90% library efficiency (45 copied, 5 downloaded)
- **Auto-Update Propagation**: < 5 minutes for 10+ projects
- **Health Checks**: < 3 seconds for complete suite

## Security

### Secret Storage

- **1Password Vaults**: Private, Projects
- **SSH Keys**: 1Password agent integration
- **GPG Keys**: 1Password integration
- **Environment Secrets**: `op://` references, never committed

### File Permissions

- **SSH Config**: 600 (user read/write only)
- **Private Keys**: 600
- **Scripts**: 755 (executable, world-readable)
- **Configs**: 644 (user read/write, others read)

### Security Features

- **Path Traversal Prevention**: Input sanitization
- **HTTPS Validation**: Production asset URLs
- **Checksum Verification**: SHA256 for all assets
- **Safe Stashing**: No data loss during auto-updates

## Version Control

### Git Workflow

- **Main Branch**: `main` (default)
- **Feature Branches**: `feature/<issue-number>-<description>`
- **Commit Format**: Conventional Commits (feat, fix, chore, docs, test)
- **Signed Commits**: 1Password SSH signing

### Repository Structure

- **Stow Packages**: `stow-packages/`
- **Scripts**: `scripts/`
- **Documentation**: `docs/`, `README.md`, `CHANGELOG.md`
- **Templates**: `templates/`
- **Tests**: `tests/`
- **System Configs**: `system/macos/`, `system/ubuntu/`

## Documentation

- **README.md**: Quick start and overview
- **CHANGELOG.md**: Version history (Keep a Changelog format)
- **ARCHITECTURE-DECISIONS.md**: Design choices and rationale
- **TASK.md**: Implementation tracking
- **TECH-STACK.md**: This document
- **Per-package READMEs**: Package-specific documentation

## References

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli)
- [Rclone Documentation](https://rclone.org/docs/)
- [BATS Documentation](https://bats-core.readthedocs.io/)
- [Webpro Dotfiles Guide](https://dotfiles.github.io/)

---

**Created**: 2025-01-25
**Last Updated**: 2025-01-25
**Maintained By**: Matteo Cervelli
**Project**: [dotfiles](https://github.com/matteocervelli/dotfiles)
