# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

## [0.1.0] - 2025-01-17

### Added

- Initial project structure
- Documentation framework
- GNU Stow-based dotfiles management architecture
