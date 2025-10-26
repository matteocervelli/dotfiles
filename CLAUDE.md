# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **personal dotfiles repository** for macOS development environment configuration using **GNU Stow** for symlink management. Based on webpro.nl dotfiles principles and modern 2024 best practices. Designed to completely automate Mac setup for development work.

## Core Principles

Following the "You're the king of your castle!" philosophy, this repository provides:

- **Complete automation** of macOS development environment setup
- **GNU Stow** for elegant symlink management
- **Modular packages** for selective configuration deployment
- **Cross-platform consideration** (future Windows compatibility planned)
- **Infrastructure integration** with existing development stack

## Architecture

### Directory Structure (Current)

```
dotfiles/
├── packages/           # GNU Stow packages (main configuration files)
│   ├── zsh/           # ZSH + Oh My Zsh configuration
│   ├── git/           # Git configuration + templates
│   ├── ssh/           # SSH config for Tailscale network
│   ├── cursor/        # Cursor/VS Code settings
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
- **Package Managers**: Homebrew (macOS), mas-cli, apt (Ubuntu)
- **Secret Management**: 1Password CLI with `op inject`
- **Cloud Storage**: Rclone with Cloudflare R2
- **Testing**: BATS (Bash Automated Testing System)
- **Development**: HTML/SCSS, JS/TS, React/Next.js, Python, SwiftUI, PostgreSQL
- **Editor**: Cursor (VS Code based) + Xcode
- **Infrastructure**: Tailscale, MCP servers, Docker integration

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

### VM Setup (Parallels)

```bash
# Ubuntu Development VM (Guides 1-2)
# See: docs/guides/parallels-1-vm-creation.md
# See: docs/guides/parallels-2-dev-setup.md
# Complete Docker development environment with shared folders

# Ubuntu Bootstrap (inside VM)
./scripts/bootstrap/ubuntu-bootstrap.sh              # Minimal setup
./scripts/bootstrap/ubuntu-bootstrap.sh --with-docker  # With Docker

# Fedora Development VM (automated setup)
# See: docs/guides/parallels-3-fedora-vm-creation.md
# Fedora Bootstrap (inside VM)
./scripts/bootstrap/fedora-bootstrap.sh              # Minimal setup
./scripts/bootstrap/fedora-bootstrap.sh --with-packages  # Full dev environment
./scripts/bootstrap/fedora-bootstrap.sh --dry-run    # Preview changes
./scripts/bootstrap/fedora-bootstrap.sh --essential-only  # Quick essentials

# Fedora Kids Learning VM (Guides 3-4) - Manual Setup
# See: docs/guides/parallels-4-fedora-kids-setup.md
# Install educational software (Fedora)
sudo dnf install $(cat system/fedora/educational-packages.txt | grep -v '^#' | grep -v '^$' | tr '\n' ' ')

# Test VM integration
./scripts/test/test-vm-integration.sh          # Automated tests
cat docs/checklists/vm-integration-checklist.md  # Manual checklist
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
- VM Ubuntu setup (Guides 1-2 COMPLETED)
- **NEW: Fedora Kids VM (Guides 3-4) - COMPLETED** ✅
  - Complete safe learning environment for kids
  - Parental controls, educational software, time limits
  - Safe browsing with multi-layer protection
  - 40+ educational packages across all subjects
- Project templates
- Monitoring & backup automation

## Key Implementation Notes

### GNU Stow Workflow
1. **Package Structure**: Each `packages/app/` contains files as they should appear in `~/`
2. **Symlink Creation**: `stow app` creates `~/.file -> dotfiles/packages/app/.file`
3. **Modular Deployment**: Install only needed packages per environment
4. **Safe Operations**: Built-in conflict detection and rollback

### Cross-Platform Planning
- **Windows Support**: Planned future extension (PowerShell, Windows Package Manager)
- **Unix Compatibility**: Bash fallback for non-macOS Unix systems
- **Conditional Logic**: Platform detection in installation scripts

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

## Workflow Integration

This dotfiles system is designed to integrate with:
- **Main Development Hub**: Docker-first development environment
- **Ad Limen S.r.l.**: Business transformation and scalability consulting
- **Multi-Platform Development**: Swift, Python, React/Next.js, PostgreSQL
- **Infrastructure as Code**: Automated environment provisioning