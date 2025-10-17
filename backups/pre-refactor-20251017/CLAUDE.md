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

- **Shell**: ZSH with Oh My Zsh framework
- **Symlink Manager**: GNU Stow
- **Package Manager**: Homebrew + Mac App Store integration
- **Development**: HTML/SCSS, JS/TS, React/Next.js, Python, SwiftUI, PostgreSQL
- **Editor**: Cursor (VS Code based) + Xcode
- **Infrastructure**: Tailscale, MCP servers, Docker integration
- **Security**: 1Password, GPG signing, Bitdefender

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

### Development & Maintenance

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Update Brewfile from current system
brew bundle dump --describe --force --file=packages/homebrew/Brewfile

# Test configurations
./scripts/test-config.sh               # Validate all configurations

# Backup current configs
./scripts/backup-current.sh            # Save existing dotfiles
```

## Implementation Status

### ✅ Completed (FASE 1)
- Documentation structure (PLANNING.md, TASK.md)
- Directory structure with GNU Stow packages
- Project architecture definition
- .stow-local-ignore configuration

### 🚧 In Progress (FASE 2)
- System configuration scanning
- Existing dotfiles backup
- Screenshot documentation

### ⏳ Planned (FASE 3-6)
- Core package implementations (zsh, git, cursor, etc.)
- Automation scripts development
- macOS system configuration
- Infrastructure integration
- Testing and documentation

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