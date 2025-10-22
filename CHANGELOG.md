# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Rclone Setup for R2** (`sync/rclone/`, `stow-packages/bin/`) - FASE 2.3 (Issue #15)
  - `sync/rclone/rclone.conf.template` - Configuration template with 1Password references
  - `sync/rclone/README.md` - Comprehensive documentation with setup, usage, and troubleshooting
  - `stow-packages/bin/.local/bin/setup-rclone` - Automated setup with 1Password secret injection (symlinkable)
  - `stow-packages/bin/.local/bin/test-rclone` - Connection testing and validation script (symlinkable)
  - `stow-packages/bin/.local/bin/rclone-cdn-sync` - Media CDN synchronization to R2 (migrated from ~/dev/scripts/)
  - Shell alias: `cdnsync` → `~/.local/bin/rclone-cdn-sync` (defined in shell package)
  - 1Password integration: Credentials stored in vault (Private/Cloudflare-R2)
  - Security: Config file permissions 600, gitignored, never committed
  - Remote configured: `remote-cdn:` for Cloudflare R2 bucket `media-adlimen`
  - Usage after stow: `setup-rclone` → `test-rclone` → `cdnsync`
  - Tested: ✅ Connection verified, 253 files in bucket
- **Project Setup Script Template** (`templates/project/`) - FASE 2.2 (Issue #14)
  - `dev-setup.sh.template` - Standard project initialization script for all projects
  - `README.md` - Comprehensive usage documentation with examples and troubleshooting
  - `.env.development.template` - Development environment template with 1Password references
  - `.env.production.template` - Production environment template with 1Password references
  - Automated workflow: Git clone/pull → Secret injection → Asset sync (R2) → Project-specific setup
  - Multi-level 1Password tagging system: [PROJECT] + [ENVIRONMENT] + [TYPE] + [CUSTOM]
  - Support for shared secrets across multiple projects via tags
  - Environment-aware configuration (development, staging, production)
  - Vault override support: `export OP_VAULT=Projects` for centralized vault strategy
  - `scripts/secrets/create-project-secret.sh` - CLI tool for creating 1Password secrets with proper categories
  - Supports proper 1Password item types: Database, API Credential, Login, Server (native fields)
  - Tag hierarchy enables flexible querying: by project, environment, type, or combinations
  - Example: `op item list --vault=Projects --tags=APP-Discreto,production,database`
- **Production Secret Management** (`templates/production/`) - FASE 2.2 (Issue #14)
  - `setup-prod-secrets.sh` - VPS setup script for Docker Secrets initialization
  - `.env.prod.template` - Production environment template (for VPS without 1Password)
  - Docker Secrets integration: encrypted at rest, mounted as files in `/run/secrets/`
  - One-time secret injection from 1Password to Docker Secrets on VPS
  - Security: Secrets stored encrypted, accessed via file mounts (not environment variables)
  - Integration with docker-compose for production deployments
- **1Password CLI Integration** (`scripts/secrets/`, `secrets/`) - FASE 2.1 (Issue #13)
  - `inject-env.sh` - Wrapper for `op inject` with authentication checking and validation
  - `validate-secrets.sh` - Verify secret injection completeness (detects remaining op:// references)
  - `template.env` - Standard .env template with 1Password reference examples
  - `docker-compose-op.yml` - Docker Compose example with 1Password integration
  - Automated secret injection from 1Password to .env files
  - Security: No secrets ever committed to git (gitignore configured)
  - Usage: `./scripts/secrets/inject-env.sh .env.template` (auto-generates .env)
  - Validation: `./scripts/secrets/validate-secrets.sh .env` (checks for uninjected refs)
  - Intended workflow: Each project has `dev-setup.sh` script that calls inject-env.sh
  - Cross-platform support (macOS, Linux)
- **Makefile orchestration** (`Makefile`) - FASE 1.9
  - Unified command interface for dotfiles management
  - `make help` - Display all available commands with examples
  - `make install` - Full installation (bootstrap + stow + health)
  - `make bootstrap` - Install dependencies only
  - `make stow` / `make stow-all` - Stow all packages (create symlinks)
  - `make stow-dry-run` / `make stow-all-dry-run` - Preview all packages before stowing (dry-run mode)
  - `make unstow` - Remove all symlinks
  - `make stow-package PKG=<name>` - Stow single package
  - `make stow-package-dry-run PKG=<name>` - Preview single package before stowing (dry-run mode)
  - `make health` - Run comprehensive health checks
  - `make backup` - Backup current configurations (placeholder, full implementation in FASE 2)
  - `make clean` - Clean temporary files (.DS_Store, *.tmp, *.log)
  - Formatted help menu with usage examples and emoji indicators
  - Integration with all existing scripts in `scripts/` directory
  - All stow operations support dry-run mode for safe preview before applying changes
- Health check scripts (`scripts/health/`) - FASE 1.8
  - `check-stow.sh` - Verify GNU Stow symlinks point to correct dotfiles locations
  - `check-all.sh` - Comprehensive health check (OS, dependencies, 1Password auth, symlinks, Git config)
  - Support for verbose mode (`-v`) to show all checks including successful ones
  - Proper exit codes: 0 (success), 1 (failures detected)
  - Smart symlink verification with relative path resolution (GNU Stow compatibility)
  - Actionable error messages with suggested fixes
  - Statistics summary: total checks, passed, warnings, failed
- Stow automation scripts (`scripts/stow/`) - FASE 1.7
  - `stow-all.sh` - Batch installer for all stow packages with statistics
  - `stow-package.sh` - Individual package manager with --no-folding support
  - `unstow-all.sh` - Batch uninstaller with safety confirmation and dry-run
  - Comprehensive error handling and user feedback
  - Dry-run mode support across all scripts
  - Verbose and quiet output modes
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

- **Project Organization**: Reorganized LLM tools package for better sprint alignment
  - Separated 1Password package (Issue #9) from LLM tools configuration
  - Moved llm-tools package from FASE 1.6 to FASE 3.5 (Issue #28)
  - Rationale: FASE 1 focuses on essential foundations, FASE 3 on application configurations
  - 1Password remains in FASE 1 (required for secret management in subsequent phases)
  - LLM tools (Claude Code, MCP servers) now grouped with other dev applications
- Shell package (`stow-packages/shell/`) - Removed Tailscale SSH aliases
  - Removed `alias macbook` and `alias macstudio` from `aliases.sh`
  - Replaced with professional SSH config approach (better cross-tool compatibility)
  - Added comment referencing new SSH config location

## [0.1.0] - 2025-01-17

### Added

- Initial project structure
- Documentation framework
- GNU Stow-based dotfiles management architecture
