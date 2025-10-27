# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **personal dotfiles repository** supporting **three platforms**: macOS (primary), Ubuntu Linux, and Fedora Linux (including educational version). Uses **GNU Stow** for symlink management. Based on webpro.nl dotfiles principles and modern 2024 best practices. Designed to completely automate development environment setup across all platforms.

## Core Principles

Following the "You're the king of your castle!" philosophy, this repository provides:

- **Complete automation** of development environment setup (macOS, Ubuntu, Fedora)
- **GNU Stow** for elegant symlink management across all platforms
- **Modular packages** for selective configuration deployment
- **Multi-platform support**: macOS (Homebrew), Ubuntu (APT), Fedora (DNF), + Educational version
- **Infrastructure integration** with existing development stack
- **Educational computing** with dedicated kids' safe learning environment (Fedora)

## Architecture

### Directory Structure (Current)

```
dotfiles/
├── packages/           # GNU Stow packages (main configuration files)
│   ├── zsh/           # ZSH + Oh My Zsh configuration
│   ├── git/           # Git configuration + templates
│   ├── ssh/           # SSH config for Tailscale network
│   ├── vscode/        # VS Code settings
│   ├── claude/        # Claude Code configurations
│   ├── python/        # Python/pyenv setup
│   ├── node/          # Node.js/nvm setup
│   ├── homebrew/      # Brewfile for package management
│   └── bin/           # Custom executable scripts
├── scripts/           # Installation and automation scripts
├── macos/            # macOS system configuration scripts
├── templates/        # Project boilerplate templates
├── fonts/            # Custom fonts
├── screenshots/      # System configuration documentation
├── backups/          # Configuration backups
└── docs/             # Complete documentation
```

### Technology Stack

Full technology stack documented in [docs/TECH-STACK.md](docs/TECH-STACK.md).

**Key Technologies:**
- **Shell**: ZSH with Oh My Zsh framework, Bash 3.2+ scripting
- **Symlink Manager**: GNU Stow 2.3.1+
- **Package Managers**: Homebrew (macOS), APT (Ubuntu), DNF (Fedora), Snap, Flatpak
- **Secret Management**: 1Password CLI with `op inject`
- **Cloud Storage**: Rclone with Cloudflare R2
- **Testing**: BATS (Bash Automated Testing System)
- **Development**: HTML/SCSS, JS/TS, React/Next.js, Python, SwiftUI, PostgreSQL
- **Editor**: VS Code + Xcode
- **Infrastructure**: Tailscale, MCP servers, Docker integration
- **Educational**: Malcontent parental controls (Fedora), OARS content filtering

## Development Commands

### GNU Stow Package Management

```bash
# Install specific package
stow -t ~ zsh              # Symlink ZSH configurations

# Install all packages
stow -t ~ */               # Symlink all package configurations

# Remove package
stow -D -t ~ zsh           # Remove ZSH symlinks

# Dry run (test)
stow -n -t ~ zsh           # Test symlink creation without executing
```

### Installation & Setup

#### macOS Setup

```bash
# Master installation (planned)
./scripts/install.sh                    # Complete Mac setup automation

# Individual setup scripts
./scripts/setup-homebrew.sh             # Install Homebrew + Brewfile
./scripts/setup-stow.sh                 # Install GNU Stow + symlink packages
./scripts/setup-macos.sh                # Configure macOS system preferences

# Pre-format system scan
./scripts/scan-system.sh                # Document current system configuration
```

#### Ubuntu Linux Setup

```bash
# Full development environment with Docker
./scripts/bootstrap/install-dependencies-ubuntu.sh --with-docker

# VM essentials only (lightweight)
./scripts/bootstrap/install-dependencies-ubuntu.sh --vm-essentials

# Essential tools only (minimal)
./scripts/bootstrap/install-dependencies-ubuntu.sh --essential-only

# Or use Makefile targets
make ubuntu-full                        # Full install + Docker
make linux-install-ubuntu               # Packages only, no Docker
make docker-install                     # Docker Engine + Compose v2

# Desktop environment (optional)
./scripts/setup/install-gnome-desktop.sh

# VS Code setup
./scripts/setup/setup-vscode-linux.sh
```

#### Fedora Linux Setup

```bash
# Full development environment
./scripts/bootstrap/install-dependencies-fedora.sh

# VM essentials (lightweight development VM)
./scripts/bootstrap/install-dependencies-fedora.sh --vm-essentials

# Essential tools only (minimal)
./scripts/bootstrap/install-dependencies-fedora.sh --essential-only

# Or use bootstrap with options
./scripts/bootstrap/fedora-bootstrap.sh --with-packages
./scripts/bootstrap/fedora-bootstrap.sh --essential-only

# Educational setup (kids 4-12)
./scripts/bootstrap/kids-fedora-bootstrap.sh --install-all
./scripts/bootstrap/kids-fedora-bootstrap.sh --core-only
```

### Application Management

```bash
# Audit installed applications
./scripts/apps/audit-apps.sh                    # Discover all apps
./scripts/apps/audit-apps.sh --verbose          # Detailed output

# Cleanup unwanted applications
./scripts/apps/cleanup-apps.sh                  # Dry-run (safe preview)
./scripts/apps/cleanup-apps.sh --execute        # Actually remove apps

# Workflow
./scripts/apps/audit-apps.sh                    # 1. Generate current-apps.txt
vim applications/remove-apps.txt                # 2. List apps to remove
./scripts/apps/cleanup-apps.sh                  # 3. Preview changes
./scripts/apps/cleanup-apps.sh --execute        # 4. Execute cleanup
```

### Brewfile Management

```bash
# Generate Brewfile from audit
make brewfile-generate                          # Create from audit data
./scripts/apps/generate-brewfile.sh             # Direct script call

# Validate and Install
make brewfile-check                             # Check what's installed
make brewfile-install                           # Install from Brewfile

# Update from system
make brewfile-update                            # Regenerate from current state
```

### VSCode Extensions

```bash
# Export and Install
make vscode-extensions-export                   # Export current extensions
make vscode-extensions-install                  # Install all extensions from list
```

### Development & Maintenance

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Update Brewfile from current system
brew bundle dump --describe --force --file=system/macos/Brewfile

# Run tests
bats tests/test-19-app-audit.bats              # Application audit tests
bats tests/*.bats                               # All tests

# Health checks
./scripts/health/check-all.sh                   # Comprehensive health check
make health                                     # via Makefile

# Backup current configs
./scripts/backup-current.sh                     # Save existing dotfiles
```

## Implementation Status

### ✅ FASE 1 - Foundation (COMPLETED)
- Bootstrap scripts (macOS, Ubuntu)
- GNU Stow packages: shell, git, ssh, 1password
- Stow automation scripts
- Health check system
- Makefile orchestration
- **Milestone**: [Closed 2025-10-21](https://github.com/matteocervelli/dotfiles/milestone/2)

### ✅ FASE 2 - Secrets & Sync (COMPLETED)
- 1Password CLI integration
- Rclone + Cloudflare R2 setup
- Asset manifest system with dimension extraction
- Project sync with library-first strategy
- Auto-update propagation system
- Environment-aware asset helpers (TypeScript + Python)
- Complete asset management documentation
- **Milestone**: [Closed 2025-01-25](https://github.com/matteocervelli/dotfiles/milestone/3)

### 🔄 FASE 3 - Applications & XDG (IN PROGRESS)
- **✅ Issue #19**: Application audit & cleanup system
- ⏳ Issue #20: Brewfile management
- ⏳ Issue #21: XDG Base Directory compliance
- **Current Status**: Implementing application management

### ⏳ FASE 4-6 - Upcoming
- VM Ubuntu setup
- Project templates
- Monitoring & backup automation

## Key Implementation Notes

### GNU Stow Workflow
1. **Package Structure**: Each `packages/app/` contains files as they should appear in `~/`
2. **Symlink Creation**: `stow app` creates `~/.file -> dotfiles/packages/app/.file`
3. **Modular Deployment**: Install only needed packages per environment
4. **Safe Operations**: Built-in conflict detection and rollback

### Cross-Platform Support

**Current Platforms**:
- **macOS** (primary): Homebrew, mas-cli, native apps, Docker Desktop
- **Ubuntu Linux**: APT, Snap, Flatpak, Docker Engine, GNOME desktop
- **Fedora Linux**: DNF, Flatpak, RPM Fusion, SELinux, educational version
- **Educational** (Fedora-based): Kids' safe learning environment (ages 4-12)

**Platform Detection**:
```bash
# Automatic OS detection
./scripts/utils/detect-os.sh           # Returns: macos, ubuntu, fedora, etc.

# Platform-specific checks
is_ubuntu                               # Boolean check
is_fedora                               # Boolean check
get_os_details                          # Detailed version info
```

**Package Manager Matrix**:
| Platform | Primary | Secondary | GUI Apps |
|----------|---------|-----------|----------|
| macOS | Homebrew | mas-cli | Homebrew Cask |
| Ubuntu | APT | Snap | Flatpak |
| Fedora | DNF | COPR | Flatpak |

**Future Platforms**:
- **Windows Support**: Planned (PowerShell, Windows Package Manager)
- **Arch Linux**: Partially supported (app audit script ready)

### Infrastructure Integration Points
- **Tailscale Network**: SSH configurations for Mac Studio access
- **MCP Servers**: 15+ Model Context Protocol server configurations
- **Docker Stack**: Integration with existing containerized development environment
- **Development Sync**: ~/dev structure replication across machines

### Security Considerations
- **GPG Integration**: 1Password GPG key management
- **SSH Key Management**: Tailscale network security
- **Sensitive Data**: .env templates without actual secrets
- **Permission Management**: Proper file permissions for security files

### Educational Version (Kids' Fedora)

A specialized, safe learning environment for children ages 4-12, built on Fedora Linux.

**Purpose**: Supervised digital learning with age-appropriate content and parental controls

**Key Features**:
- **5-Layer Protection**: User restrictions + Parental controls + DNS filtering + Browser safety + Physical supervision
- **40+ Educational Packages**: GCompris, Tux Suite, KDE Education, Scratch, creative tools
- **Age-Aware**: OARS content filtering based on child's age (4-6, 6-8, 8-10, 10-12)
- **Monitoring Tools**: Usage logging, parent dashboard, activity tracking
- **Non-Admin Account**: Kids have NO sudo access, restricted permissions
- **Malcontent Framework**: System-level app restrictions and time limits

**Quick Start**:
```bash
# Interactive setup (recommended)
./scripts/bootstrap/kids-fedora-bootstrap.sh

# Non-interactive with options
./scripts/bootstrap/kids-fedora-bootstrap.sh \
    --child-name "Sofia" \
    --child-age 8 \
    --install-all

# Core educational apps only (faster)
./scripts/bootstrap/kids-fedora-bootstrap.sh \
    --child-name "Sofia" \
    --child-age 8 \
    --core-only
```

**Parent Management**:
```bash
# View usage dashboard
sudo /usr/local/bin/kids-dashboard

# Check recent activity
sudo tail -n 100 /var/log/kids-usage.log

# Manage parental controls (GUI)
malcontent-control

# Verify safety: kids account should NOT have sudo
groups kids_username  # Should NOT include 'wheel'
```

**Documentation**:
- **Setup Guide**: `docs/guides/parallels-4-fedora-kids-setup.md`
- **Usage Guide**: `docs/guides/kids-fedora-usage.md` (parent routines, troubleshooting)
- **VM Creation**: `docs/guides/parallels-3-fedora-vm-creation.md`

**Philosophy**:
- **Educational First**: Learning and creativity over entertainment
- **Long-term Maintainable**: Designed for years of growth
- **Safe by Design**: Multiple protection layers, not just one control
- **Parent Empowerment**: Tools and knowledge for informed supervision

**Age Progression**:
- **4-6 years**: High supervision, basic activities, 30-45 min sessions
- **6-8 years**: Moderate supervision, creative tools, 45-60 min sessions
- **8-10 years**: Light supervision, programming intro, 60-90 min sessions
- **10-12 years**: Independent with monitoring, advanced projects, 90+ min

## Workflow Integration

This dotfiles system is designed to integrate with:
- **Main Development Hub**: Docker-first development environment
- **Ad Limen S.r.l.**: Business transformation and scalability consulting
- **Multi-Platform Development**: Swift, Python, React/Next.js, PostgreSQL
- **Infrastructure as Code**: Automated environment provisioning