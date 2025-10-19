# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- SSH configuration package (`stow-packages/ssh/`) - FASE 1.6
  - Modular SSH configuration with `config.d/` directory structure
  - Cross-platform support (macOS and Linux) with platform-specific 1Password agent paths
  - Complete Tailscale network configuration for all devices (studio, macbook, nas, sara's devices)
  - GitHub SSH configuration with 1Password authentication
  - VPS servers configuration (`30-vps.conf`) - tracked in git
  - Work/client servers template (`40-work.conf.template`) - gitignored
  - Connection multiplexing with ControlMaster for faster SSH
  - Include directive for modular config file loading
  - Comprehensive README with usage examples and troubleshooting
- Git configuration package (`stow-packages/git/`) - FASE 1.6
  - Complete `.gitconfig` with 1Password SSH signing integration
  - Comprehensive Git aliases (30+ shortcuts for common operations)
  - Minimal `.gitignore_global` with gitignore.io-first philosophy
  - Git hooks template directory (`.git-templates/hooks/`)
  - SSH allowed signers file for commit verification
  - Machine-specific override template (`.gitconfig.local.template`)
  - Cross-platform support (macOS, Linux, Windows via WSL)
  - Comprehensive documentation and troubleshooting guide
- Bootstrap scripts for automated dependency installation (FASE 1.5)
  - macOS bootstrap with Homebrew-based installation
  - Ubuntu bootstrap with apt/wget-based installation
  - Master install orchestrator with automatic OS detection
  - Idempotent operations: safe to run multiple times
  - Dependencies installed: GNU Stow, 1Password CLI, Rclone, yq
- OS detection utility (`scripts/utils/detect-os.sh`)
- Logging utilities with colored output (`scripts/utils/logger.sh`)

### Changed

- Shell package (`stow-packages/shell/`) - Removed Tailscale SSH aliases
  - Removed `alias macbook` and `alias macstudio` from `aliases.sh`
  - Replaced with professional SSH config approach (better cross-tool compatibility)
  - Added comment referencing new SSH config location

## [0.1.0] - 2025-01-17

### Added

- Initial project structure
- Documentation framework
- GNU Stow-based dotfiles management architecture
