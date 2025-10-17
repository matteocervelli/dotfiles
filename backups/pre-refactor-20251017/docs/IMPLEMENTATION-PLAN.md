# Implementation Plan: FASE 1-2

**Project**: Personal Dotfiles Management System
**Version**: 1.0
**Date**: 2025-01-17
**Status**: Ready for Execution
**Estimated Duration**: 10-14 hours

---

## Overview

This document details the implementation plan for FASE 1 (Foundation) and FASE 2 (Secrets & Sync), establishing the core infrastructure for the dotfiles management system.

**Prerequisites**:
- macOS Sonoma+ or Ubuntu 22.04+ LTS
- Git installed
- Internet connection
- 1Password account with CLI access
- Cloudflare R2 account (for asset storage)

**Architecture Decisions**: See [ARCHITECTURE-DECISIONS.md](ARCHITECTURE-DECISIONS.md)

---

## FASE 1: Foundation

**Goal**: Establish base infrastructure for dotfiles management
**Duration**: 6-8 hours
**Priority**: Critical ⚡

### 1.1 Backup and Audit Existing Repository

**Objective**: Save current state and identify what to keep

**Actions**:
1. Create dated backup directory
2. Copy entire repo to backup
3. Audit existing files
4. Document decisions

**Commands**:
```bash
cd ~/dev/projects/dotfiles
mkdir -p backups/pre-refactor-$(date +%Y%m%d)
cp -R . backups/pre-refactor-$(date +%Y%m%d)/
```

**Files to Review**:
- `docs/*.md` → Keep: PLANNING.md, TASK.md, new-list.md, Technology Stack.md
- `packages/` → Review and migrate useful configs
- `scripts/` → Audit for reusable scripts
- `legacy-zsh/` → Extract useful aliases/functions

**Output**:
- ✅ Backup in `backups/pre-refactor-YYYYMMDD/`
- ✅ Decisions documented in `docs/REFACTOR-NOTES.md`

**Duration**: 30 minutes

---

### 1.2 Create Directory Structure

**Objective**: Establish complete repository architecture

**Structure to Create**:
```
dotfiles/
├── stow-packages/           # GNU Stow packages for symlinking
│   ├── shell/               # ZSH + Bash (cross-platform)
│   ├── git/                 # Git configurations
│   ├── ssh/                 # SSH configurations
│   ├── 1password/           # 1Password CLI config
│   ├── llm-tools/           # Claude Code, MCP servers
│   ├── cursor/              # Editor configs (FASE 3)
│   ├── iterm2/              # Terminal emulator (FASE 3)
│   ├── dev-env/             # pyenv, nvm, docker (FASE 3)
│   └── bin/                 # Custom executables
│
├── system/                  # OS-specific system configurations
│   ├── macos/
│   │   ├── defaults/        # macOS defaults scripts
│   │   ├── launch-agents/   # LaunchAgents for automation
│   │   └── Brewfile         # Homebrew package list
│   └── ubuntu/
│       ├── apt-packages.txt # APT packages
│       ├── snap-packages.txt
│       └── systemd/         # Systemd units
│
├── applications/            # Application management
│   ├── brew-packages.txt    # Core Homebrew formulas
│   ├── mas-apps.txt         # Mac App Store apps
│   ├── cursor-extensions.txt
│   └── cleanup-list.txt     # Apps to remove
│
├── secrets/                 # Secret management templates
│   ├── .gitignore           # Block actual secrets
│   ├── template.env         # Standard .env template
│   ├── op-inject.sh         # 1Password injection wrapper
│   └── docker-compose-op.yml # Docker Compose example
│
├── sync/                    # File synchronization configs
│   ├── rclone/
│   │   ├── rclone.conf.template
│   │   └── sync-profiles/   # Per-project sync configs
│   ├── manifests/
│   │   ├── schema.yml       # Manifest YAML schema
│   │   └── README.md        # Manifest documentation
│   └── auto-update/         # Auto-update configs
│
├── scripts/                 # Automation scripts
│   ├── bootstrap/
│   │   ├── install.sh       # Master installation orchestrator
│   │   ├── macos-bootstrap.sh
│   │   └── ubuntu-bootstrap.sh
│   ├── stow/
│   │   ├── stow-all.sh      # Stow all packages
│   │   ├── stow-package.sh  # Stow single package
│   │   └── unstow-all.sh    # Remove all symlinks
│   ├── apps/
│   │   ├── audit-apps.sh    # List installed apps
│   │   ├── install-apps.sh  # Install from lists
│   │   └── cleanup-apps.sh  # Remove unwanted apps
│   ├── xdg-compliance/
│   │   ├── redirect-configs.sh
│   │   └── app-mappings.yml # Per-app config decisions
│   ├── secrets/
│   │   ├── inject-env.sh    # 1Password injection
│   │   └── validate-secrets.sh
│   ├── sync/
│   │   ├── setup-rclone.sh
│   │   ├── sync-r2.sh       # R2 pull/push
│   │   ├── generate-manifest.sh
│   │   └── auto-update-dotfiles.sh
│   ├── health/
│   │   ├── check-all.sh     # Run all health checks
│   │   └── check-stow.sh    # Verify symlinks
│   ├── backup/
│   │   ├── snapshot.sh      # Manual backup
│   │   ├── sync-to-nas.sh   # Backup to Synology
│   │   └── restore-from-nas.sh
│   └── utils/
│       ├── detect-os.sh     # OS detection
│       └── logger.sh        # Logging utilities
│
├── templates/               # Project boilerplates
│   ├── project/
│   │   └── dev-setup.sh.template  # Standard project setup script
│   ├── python-project/      # (FASE 5)
│   ├── nextjs-project/      # (FASE 5)
│   └── docker-compose/      # (FASE 5)
│
├── docs/                    # Documentation
│   ├── PLANNING.md          # Original planning doc
│   ├── TASK.md              # Task tracking
│   ├── ARCHITECTURE-DECISIONS.md  # This document
│   ├── IMPLEMENTATION-PLAN.md     # Execution plan
│   ├── REFACTOR-NOTES.md    # Refactor decisions
│   ├── xdg-compliance.md    # XDG compliance decisions
│   ├── secrets-management.md # Secret management guide
│   ├── sync-strategy.md     # Sync strategy documentation
│   └── vm-setup.md          # VM setup guide
│
├── backups/                 # Pre-migration backups (gitignored)
│
├── .stow-local-ignore       # Stow ignore patterns
├── .gitignore               # Git ignore patterns
├── Makefile                 # Command orchestration
└── README.md                # Project documentation
```

**Commands**:
```bash
cd ~/dev/projects/dotfiles

# Create all directories
mkdir -p stow-packages/{shell,git,ssh,1password,llm-tools,cursor,iterm2,dev-env,bin}
mkdir -p system/{macos/{defaults,launch-agents},ubuntu/systemd}
mkdir -p applications
mkdir -p secrets
mkdir -p sync/{rclone/sync-profiles,manifests,auto-update}
mkdir -p scripts/{bootstrap,stow,apps,xdg-compliance,secrets,sync,health,backup,utils}
mkdir -p templates/{project,python-project,nextjs-project,docker-compose}
mkdir -p docs backups
```

**Output**:
- ✅ Complete directory structure created
- ✅ All directories exist and are empty (ready for content)

**Duration**: 15 minutes

---

### 1.3 Configuration Files (Base)

**Objective**: Configure Git ignore and Stow ignore patterns

#### 1.3.1 Update `.gitignore`

**File**: `.gitignore`

**Content**:
```gitignore
# Secrets - NEVER commit
.env
.env.*
!.env.template
secrets/*.env
!secrets/template.env
!secrets/op-inject.sh
!secrets/docker-compose-op.yml

# 1Password config (has account IDs)
.config/op/config

# Backups
backups/
*.backup
*.bak

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Rclone config (has credentials)
sync/rclone/rclone.conf
.config/rclone/rclone.conf

# Temporary files
*.tmp
*.log
*.swp
*.swo
*~

# Editor files
.vscode/
.idea/
*.sublime-*

# Package manager
node_modules/
venv/
__pycache__/

# R2 assets (too large for git)
r2-assets/
*.bin
*.model
*.weights
```

#### 1.3.2 Create `.stow-local-ignore`

**File**: `.stow-local-ignore`

**Content**:
```
# Project metadata (don't symlink)
^/README\.md
^/LICENSE
^/\.git
^/\.gitignore
^/\.stow-local-ignore
^/Makefile

# Documentation
^/docs

# Scripts
^/scripts

# Templates
^/templates

# System configs
^/system

# Applications lists
^/applications

# Secrets templates (not actual secrets)
^/secrets

# Sync configs
^/sync

# Backups
^/backups

# OS files
\.DS_Store
\.DS_Store\?
\._.*
```

**Output**:
- ✅ `.gitignore` updated with comprehensive patterns
- ✅ `.stow-local-ignore` created and tested
- ✅ `git status` shows only intended files
- ✅ `stow -n` dry run doesn't attempt to symlink metadata

**Duration**: 15 minutes

---

### 1.4 Utility Scripts

**Objective**: Create reusable helper functions

#### 1.4.1 OS Detection Utility

**File**: `scripts/utils/detect-os.sh`

**Content**:
```bash
#!/usr/bin/env bash
# OS Detection Utility
# Returns: macos, ubuntu, fedora, linux, or unknown

detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu) echo "ubuntu" ;;
                    fedora) echo "fedora" ;;
                    arch) echo "arch" ;;
                    alpine) echo "alpine" ;;
                    *) echo "linux" ;;
                esac
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Export for sourcing
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script executed directly
    detect_os
fi
```

#### 1.4.2 Logging Utility

**File**: `scripts/utils/logger.sh`

**Content**:
```bash
#!/usr/bin/env bash
# Logging Utilities
# Provides consistent logging across scripts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $*"
}

log_step() {
    echo ""
    echo -e "${BLUE}==>${NC} $*"
    echo ""
}

# Export for sourcing
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "This script should be sourced, not executed directly"
    exit 1
fi
```

**Commands**:
```bash
chmod +x scripts/utils/detect-os.sh scripts/utils/logger.sh
```

**Test**:
```bash
# Test OS detection
./scripts/utils/detect-os.sh

# Test logging (in another script)
source scripts/utils/logger.sh
log_info "Testing info log"
log_success "Testing success log"
log_error "Testing error log"
log_warning "Testing warning log"
```

**Output**:
- ✅ `detect-os.sh` executable and returns correct OS
- ✅ `logger.sh` provides colored output functions
- ✅ Both scripts tested and working

**Duration**: 20 minutes

---

### 1.5 Bootstrap Scripts

**Objective**: Automate dependency installation

#### 1.5.1 macOS Bootstrap

**File**: `scripts/bootstrap/macos-bootstrap.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Installing macOS Dependencies"

# Check if running on macOS
if [ "$(uname -s)" != "Darwin" ]; then
    log_error "This script must be run on macOS"
    exit 1
fi

# Install Homebrew
if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    log_success "Homebrew already installed"
fi

# Update Homebrew
log_info "Updating Homebrew..."
brew update

# Install GNU Stow
if ! command -v stow &> /dev/null; then
    log_info "Installing GNU Stow..."
    brew install stow
else
    log_success "GNU Stow already installed"
fi

# Install 1Password CLI
if ! command -v op &> /dev/null; then
    log_info "Installing 1Password CLI..."
    brew install --cask 1password-cli
else
    log_success "1Password CLI already installed"
fi

# Install Rclone
if ! command -v rclone &> /dev/null; then
    log_info "Installing Rclone..."
    brew install rclone
else
    log_success "Rclone already installed"
fi

# Install yq (YAML processor)
if ! command -v yq &> /dev/null; then
    log_info "Installing yq..."
    brew install yq
else
    log_success "yq already installed"
fi

log_success "macOS dependencies installed successfully!"
echo ""
log_info "Next steps:"
echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
echo "  2. Configure Rclone for R2: ./scripts/sync/setup-rclone.sh"
echo "  3. Run full installation: make install"
```

#### 1.5.2 Ubuntu Bootstrap

**File**: `scripts/bootstrap/ubuntu-bootstrap.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Installing Ubuntu Dependencies"

# Check if running on Ubuntu
if [ ! -f /etc/os-release ] || ! grep -q "ubuntu" /etc/os-release; then
    log_error "This script must be run on Ubuntu"
    exit 1
fi

# Update package lists
log_info "Updating package lists..."
sudo apt update

# Install GNU Stow
if ! command -v stow &> /dev/null; then
    log_info "Installing GNU Stow..."
    sudo apt install -y stow
else
    log_success "GNU Stow already installed"
fi

# Install 1Password CLI
if ! command -v op &> /dev/null; then
    log_info "Installing 1Password CLI..."

    # Add 1Password repository
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list

    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    sudo apt update && sudo apt install -y 1password-cli
else
    log_success "1Password CLI already installed"
fi

# Install Rclone
if ! command -v rclone &> /dev/null; then
    log_info "Installing Rclone..."
    sudo apt install -y rclone
else
    log_success "Rclone already installed"
fi

# Install yq (YAML processor)
if ! command -v yq &> /dev/null; then
    log_info "Installing yq..."
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq
else
    log_success "yq already installed"
fi

# Install essential build tools
log_info "Installing build essentials..."
sudo apt install -y build-essential curl git

log_success "Ubuntu dependencies installed successfully!"
echo ""
log_info "Next steps:"
echo "  1. Sign in to 1Password CLI: eval \$(op signin)"
echo "  2. Configure Rclone for R2: ./scripts/sync/setup-rclone.sh"
echo "  3. Run full installation: make install"
```

#### 1.5.3 Master Install Script

**File**: `scripts/bootstrap/install.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/detect-os.sh"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Dotfiles Installation"
log_info "Repository: $DOTFILES_DIR"

# Detect OS
OS=$(detect_os)
log_info "Detected OS: $OS"

# Run OS-specific bootstrap
case "$OS" in
    macos)
        log_info "Running macOS bootstrap..."
        "$SCRIPT_DIR/macos-bootstrap.sh"
        ;;
    ubuntu)
        log_info "Running Ubuntu bootstrap..."
        "$SCRIPT_DIR/ubuntu-bootstrap.sh"
        ;;
    *)
        log_error "Unsupported OS: $OS"
        log_info "Supported: macos, ubuntu"
        exit 1
        ;;
esac

# Backup existing configs
log_step "Backing up existing configurations"
if [ -f "$DOTFILES_DIR/scripts/backup/snapshot.sh" ]; then
    "$DOTFILES_DIR/scripts/backup/snapshot.sh"
else
    log_warning "Backup script not found, skipping..."
fi

# Stow packages
log_step "Installing dotfiles (stow packages)"
if [ -f "$DOTFILES_DIR/scripts/stow/stow-all.sh" ]; then
    "$DOTFILES_DIR/scripts/stow/stow-all.sh"
else
    log_error "Stow script not found: $DOTFILES_DIR/scripts/stow/stow-all.sh"
    exit 1
fi

# Health check
log_step "Running health checks"
if [ -f "$DOTFILES_DIR/scripts/health/check-all.sh" ]; then
    "$DOTFILES_DIR/scripts/health/check-all.sh"
else
    log_warning "Health check script not found, skipping..."
fi

log_success "Dotfiles installation complete!"
echo ""
log_info "Next steps:"
echo "  1. Restart your shell: exec \$SHELL"
echo "  2. Sign in to 1Password: eval \$(op signin)"
echo "  3. Configure Rclone: ./scripts/sync/setup-rclone.sh"
echo "  4. Run health check: make health"
```

**Commands**:
```bash
chmod +x scripts/bootstrap/*.sh
```

**Output**:
- ✅ Bootstrap scripts executable
- ✅ OS-specific dependency installation works
- ✅ Master script orchestrates installation flow

**Duration**: 45 minutes

---

### 1.6 Stow Packages (Priority 5)

**Objective**: Create initial configuration packages

#### 1.6.1 Shell Package

**Directory**: `stow-packages/shell/`

**Structure**:
```
stow-packages/shell/
├── .zshrc
├── .bashrc
└── .config/
    └── shell/
        ├── aliases.sh
        ├── exports.sh
        └── functions.sh
```

**File**: `stow-packages/shell/.zshrc`

**Content** (minimal starter):
```bash
# ~/.zshrc - ZSH Configuration
# Managed by dotfiles: ~/dev/projects/dotfiles

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker docker-compose)
source $ZSH/oh-my-zsh.sh

# Source modular configs
if [ -d "$HOME/.config/shell" ]; then
    for config in "$HOME/.config/shell"/*.sh; do
        [ -r "$config" ] && source "$config"
    done
fi

# 1Password
if command -v op &> /dev/null; then
    # Add 1Password plugins path
    export OP_PLUGIN_PATH="$HOME/.config/op/plugins"
fi

# Pyenv
if command -v pyenv &> /dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Tailscale (if installed)
if [ -d "/Applications/Tailscale.app" ]; then
    alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
fi
```

**File**: `stow-packages/shell/.config/shell/aliases.sh`

**Content**:
```bash
# Common aliases

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ~="cd ~"

# List
alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"

# Git
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"

# Docker
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"

# Dotfiles
alias dotfiles="cd ~/dev/projects/dotfiles"
alias dot="cd ~/dev/projects/dotfiles"

# Dev
alias dev="cd ~/dev/projects"
```

**File**: `stow-packages/shell/.config/shell/exports.sh`

**Content**:
```bash
# Environment exports

# Editor
export EDITOR="cursor"
export VISUAL="cursor"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Homebrew (macOS ARM)
if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# XDG Base Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
```

**File**: `stow-packages/shell/.config/shell/functions.sh`

**Content**:
```bash
# Useful functions

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find process by name
psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e "$@"
}
```

**File**: `stow-packages/shell/.bashrc`

**Content** (minimal, for Ubuntu VMs):
```bash
# ~/.bashrc - Bash Configuration
# Managed by dotfiles: ~/dev/projects/dotfiles

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Source modular configs
if [ -d "$HOME/.config/shell" ]; then
    for config in "$HOME/.config/shell"/*.sh; do
        [ -r "$config" ] && source "$config"
    done
fi

# History
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
```

#### 1.6.2 Git Package

**Directory**: `stow-packages/git/`

**Structure**:
```
stow-packages/git/
├── .gitconfig
├── .gitignore_global
└── .git-templates/
    └── hooks/
        └── .gitkeep
```

**File**: `stow-packages/git/.gitconfig`

**Content**:
```ini
[user]
    name = Matteo Cervelli
    email = YOUR_EMAIL@example.com
    # 1Password Git signing (configure separately)
    # signingkey = YOUR_GPG_KEY

[core]
    editor = cursor --wait
    excludesfile = ~/.gitignore_global
    autocrlf = input

[init]
    defaultBranch = main
    templatedir = ~/.git-templates

[pull]
    rebase = false

[push]
    default = current
    autoSetupRemote = true

[fetch]
    prune = true

[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = log --graph --oneline --decorate --all

[color]
    ui = auto

[diff]
    tool = default-difftool

[merge]
    tool = default-mergetool

# 1Password Git integration
# [gpg]
#     format = openpgp
# [gpg "ssh"]
#     program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
# [commit]
#     gpgsign = true
```

**File**: `stow-packages/git/.gitignore_global`

**Content**:
```gitignore
# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editors
.vscode/
.idea/
*.swp
*.swo
*~
.cursor/

# Node
node_modules/
npm-debug.log

# Python
__pycache__/
*.py[cod]
.venv/
venv/
.pytest_cache/

# Secrets
.env
.env.*
!.env.example
!.env.template
```

#### 1.6.3 SSH Package

**Directory**: `stow-packages/ssh/`

**Structure**:
```
stow-packages/ssh/
└── .ssh/
    ├── config
    └── config.d/
        ├── tailscale.conf
        └── github.conf
```

**File**: `stow-packages/ssh/.ssh/config`

**Content**:
```
# SSH Config
# Managed by dotfiles: ~/dev/projects/dotfiles

# Include all configs from config.d/
Include ~/.ssh/config.d/*

# Default settings
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
```

**File**: `stow-packages/ssh/.ssh/config.d/tailscale.conf`

**Content**:
```
# Tailscale Network
# Format: hostname.tailnet-name.ts.net

# Mac Studio
Host mac-studio
    HostName mac-studio.YOUR-TAILNET.ts.net
    User matteocervelli
    ForwardAgent yes

# Ubuntu Dev VM
Host ubuntu-dev
    HostName ubuntu-dev.YOUR-TAILNET.ts.net
    User matteocervelli
    ForwardAgent yes
```

**File**: `stow-packages/ssh/.ssh/config.d/github.conf`

**Content**:
```
# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
```

#### 1.6.4 1Password Package

**Directory**: `stow-packages/1password/`

**Structure**:
```
stow-packages/1password/
└── .config/
    └── op/
        └── .gitkeep
```

**Note**: 1Password CLI config is auto-generated and contains account IDs, so it's gitignored. This package just ensures the directory exists.

#### 1.6.5 LLM Tools Package

**Directory**: `stow-packages/llm-tools/`

**Structure**:
```
stow-packages/llm-tools/
└── .config/
    ├── claude/
    │   └── config.json
    └── mcp/
        └── servers.json
```

**File**: `stow-packages/llm-tools/.config/claude/config.json`

**Content** (migrate from existing):
```json
{
  "version": "1.0",
  "codeEditor": "cursor",
  "settings": {}
}
```

**File**: `stow-packages/llm-tools/.config/mcp/servers.json`

**Content** (migrate from existing, example):
```json
{
  "mcpServers": {
    "obsidian-mcp": {
      "command": "npx",
      "args": ["-y", "obsidian-mcp"]
    },
    "github-mcp": {
      "command": "npx",
      "args": ["-y", "github-mcp"]
    }
  }
}
```

**Commands**:
```bash
# Make scripts executable
chmod +x stow-packages/shell/.config/shell/*.sh

# Create gitkeep files
touch stow-packages/git/.git-templates/hooks/.gitkeep
touch stow-packages/1password/.config/op/.gitkeep
```

**Output**:
- ✅ 5 stow packages created and populated
- ✅ Shell configs modular and cross-platform
- ✅ Git config standardized
- ✅ SSH config with Tailscale
- ✅ LLM tools configs ready to migrate

**Duration**: 1.5 hours

---

### 1.7 Stow Automation Scripts

**Objective**: Automate stow operations

#### 1.7.1 Stow All Packages

**File**: `scripts/stow/stow-all.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Stowing All Packages"

cd "$DOTFILES_DIR/stow-packages"

# Priority packages for FASE 1
PACKAGES=(
    "shell"
    "git"
    "ssh"
    "1password"
    "llm-tools"
)

for package in "${PACKAGES[@]}"; do
    if [ -d "$package" ]; then
        log_info "Stowing $package..."
        stow -t ~ -v "$package"
        log_success "$package stowed"
    else
        log_warning "$package directory not found, skipping..."
    fi
done

log_success "All packages stowed successfully!"
```

#### 1.7.2 Stow Single Package

**File**: `scripts/stow/stow-package.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <package-name>"
    echo ""
    echo "Available packages:"
    ls -1 "$(dirname "$0")/../../stow-packages"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PACKAGE="$1"

source "$SCRIPT_DIR/../utils/logger.sh"

cd "$DOTFILES_DIR/stow-packages"

if [ ! -d "$PACKAGE" ]; then
    log_error "Package not found: $PACKAGE"
    exit 1
fi

log_info "Stowing $PACKAGE..."
stow -t ~ -v "$PACKAGE"
log_success "$PACKAGE stowed successfully!"
```

#### 1.7.3 Unstow All Packages

**File**: `scripts/stow/unstow-all.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Unstowing All Packages"
log_warning "This will remove all dotfiles symlinks!"

read -p "Are you sure? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    exit 0
fi

cd "$DOTFILES_DIR/stow-packages"

for package in */; do
    package="${package%/}"
    log_info "Unstowing $package..."
    stow -D -t ~ -v "$package" || log_warning "$package not stowed, skipping..."
done

log_success "All packages unstowed!"
```

**Commands**:
```bash
chmod +x scripts/stow/*.sh
```

**Output**:
- ✅ Stow automation scripts executable
- ✅ Can stow all packages with one command
- ✅ Can stow individual packages
- ✅ Can unstow (remove symlinks) safely

**Duration**: 30 minutes

---

### 1.8 Health Check Scripts

**Objective**: Verify installation correctness

#### 1.8.1 Check Stow Symlinks

**File**: `scripts/health/check-stow.sh`

**Content**:
```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Checking Stow Symlinks"

# Expected symlinks
declare -A EXPECTED_LINKS=(
    ["$HOME/.zshrc"]="$DOTFILES_DIR/stow-packages/shell/.zshrc"
    ["$HOME/.bashrc"]="$DOTFILES_DIR/stow-packages/shell/.bashrc"
    ["$HOME/.gitconfig"]="$DOTFILES_DIR/stow-packages/git/.gitconfig"
    ["$HOME/.ssh/config"]="$DOTFILES_DIR/stow-packages/ssh/.ssh/config"
)

ERRORS=0

for link in "${!EXPECTED_LINKS[@]}"; do
    expected_target="${EXPECTED_LINKS[$link]}"

    if [ -L "$link" ]; then
        actual_target=$(readlink "$link")
        if [ "$actual_target" = "$expected_target" ]; then
            log_success "$link → $expected_target"
        else
            log_warning "$link → $actual_target (expected: $expected_target)"
            ((ERRORS++))
        fi
    elif [ -e "$link" ]; then
        log_error "$link exists but is not a symlink"
        ((ERRORS++))
    else
        log_warning "$link does not exist (package not stowed?)"
    fi
done

if [ $ERRORS -eq 0 ]; then
    log_success "All symlinks correct!"
    exit 0
else
    log_error "Found $ERRORS symlink issues"
    exit 1
fi
```

#### 1.8.2 Check All Dependencies

**File**: `scripts/health/check-all.sh`

**Content**:
```bash
#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/detect-os.sh"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Running Health Checks"

OS=$(detect_os)
log_info "OS: $OS"

# Check required commands
log_info "Checking required commands..."
COMMANDS=(git stow op rclone yq)
MISSING=0

for cmd in "${COMMANDS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        log_success "$cmd installed"
    else
        log_error "$cmd not found"
        ((MISSING++))
    fi
done

# Check 1Password authentication
log_info "Checking 1Password authentication..."
if op whoami &> /dev/null; then
    log_success "1Password CLI authenticated"
else
    log_warning "1Password CLI not authenticated (run: eval \$(op signin))"
fi

# Check stow symlinks
log_info "Checking stow symlinks..."
if [ -f "$SCRIPT_DIR/check-stow.sh" ]; then
    "$SCRIPT_DIR/check-stow.sh"
else
    log_warning "check-stow.sh not found, skipping..."
fi

# Summary
echo ""
if [ $MISSING -eq 0 ]; then
    log_success "All health checks passed!"
    exit 0
else
    log_error "Health checks failed ($MISSING missing commands)"
    log_info "Run the bootstrap script to install dependencies"
    exit 1
fi
```

**Commands**:
```bash
chmod +x scripts/health/*.sh
```

**Test**:
```bash
./scripts/health/check-all.sh
```

**Output**:
- ✅ Health check scripts executable
- ✅ Verify required commands installed
- ✅ Verify symlinks point to correct targets
- ✅ Provide actionable error messages

**Duration**: 30 minutes

---

### 1.9 Makefile

**Objective**: Unified command interface

**File**: `Makefile`

**Content**:
```makefile
.PHONY: help install bootstrap stow unstow health backup clean

# Default target
help:
	@echo "Dotfiles Management"
	@echo "==================="
	@echo ""
	@echo "Installation:"
	@echo "  make install      Full installation (bootstrap + stow + health)"
	@echo "  make bootstrap    Install dependencies only"
	@echo ""
	@echo "Stow Operations:"
	@echo "  make stow         Stow all packages (create symlinks)"
	@echo "  make unstow       Remove all symlinks"
	@echo ""
	@echo "Maintenance:"
	@echo "  make health       Run health checks"
	@echo "  make backup       Backup current configs"
	@echo "  make clean        Clean temporary files"
	@echo ""
	@echo "R2 Sync:"
	@echo "  make sync-help    Show R2 sync commands"

# Full installation
install: bootstrap stow health

# Install dependencies
bootstrap:
	@./scripts/bootstrap/install.sh

# Stow all packages
stow:
	@./scripts/stow/stow-all.sh

# Remove all symlinks
unstow:
	@./scripts/stow/unstow-all.sh

# Run health checks
health:
	@./scripts/health/check-all.sh

# Backup existing configs
backup:
	@./scripts/backup/snapshot.sh

# Clean temporary files
clean:
	@find . -name ".DS_Store" -delete
	@find . -name "*.tmp" -delete
	@find . -name "*.log" -delete
	@echo "✓ Cleaned temporary files"

# R2 sync help
sync-help:
	@echo "R2 Sync Commands:"
	@echo "  ./scripts/sync/setup-rclone.sh              Setup Rclone for R2"
	@echo "  ./scripts/sync/sync-r2.sh pull PROJECT      Pull assets from R2"
	@echo "  ./scripts/sync/sync-r2.sh push PROJECT PATH Push assets to R2"
	@echo "  ./scripts/sync/generate-manifest.sh PROJECT Generate asset manifest"
```

**Commands**:
```bash
chmod +x Makefile
```

**Test**:
```bash
make help
```

**Output**:
- ✅ Makefile provides unified interface
- ✅ `make help` shows all available commands
- ✅ `make install` runs full installation
- ✅ Individual targets work correctly

**Duration**: 15 minutes

---

## FASE 1 Verification

**Test Full Installation**:
```bash
# On a fresh clone
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run full installation
make install

# Should complete without errors and:
# ✅ Install dependencies (Homebrew, Stow, 1Password CLI, Rclone, yq)
# ✅ Create symlinks for 5 packages
# ✅ Pass all health checks

# Verify
make health
ls -la ~ | grep "^l"  # List symlinks
```

**Expected Output**:
```
[INFO] Detected OS: macos
[✓] Homebrew already installed
[✓] GNU Stow installed
[✓] 1Password CLI installed
[✓] Rclone installed
[✓] yq installed
[✓] shell stowed
[✓] git stowed
[✓] ssh stowed
[✓] 1password stowed
[✓] llm-tools stowed
[✓] All health checks passed!
```

---

## FASE 2: Secrets & Sync

**Goal**: Implement secret management and R2 asset synchronization
**Duration**: 4-6 hours
**Priority**: Critical ⚡

### 2.1 1Password CLI Integration

**Objective**: Automate secret injection from 1Password

#### 2.1.1 Secret Injection Script

**File**: `scripts/secrets/inject-env.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-.env.template> [output-path]"
    echo ""
    echo "Example:"
    echo "  $0 ~/dev/projects/my-app/.env.template"
    echo "  $0 ~/dev/projects/my-app/.env.template ~/dev/projects/my-app/.env"
    exit 1
fi

TEMPLATE="$1"
OUTPUT="${2:-${TEMPLATE%.template}}"

if [ ! -f "$TEMPLATE" ]; then
    log_error "Template not found: $TEMPLATE"
    exit 1
fi

log_info "Injecting secrets from 1Password..."
log_info "Template: $TEMPLATE"
log_info "Output: $OUTPUT"

# Check 1Password authentication
if ! op whoami &> /dev/null; then
    log_info "Signing in to 1Password..."
    eval $(op signin)
fi

# Inject secrets
if op inject -i "$TEMPLATE" -o "$OUTPUT"; then
    log_success "Secrets injected to $OUTPUT"

    # Verify output has no remaining op:// references
    if grep -q "op://" "$OUTPUT"; then
        log_warning "Some secrets may not have been injected (check 1Password references)"
    fi
else
    log_error "Failed to inject secrets"
    exit 1
fi
```

#### 2.1.2 Secret Validation Script

**File**: `scripts/secrets/validate-secrets.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-.env>"
    exit 1
fi

ENV_FILE="$1"

if [ ! -f "$ENV_FILE" ]; then
    log_error "File not found: $ENV_FILE"
    exit 1
fi

log_info "Validating secrets in: $ENV_FILE"

# Check for remaining op:// references
if grep -q "op://" "$ENV_FILE"; then
    log_error "Found uninjected 1Password references:"
    grep "op://" "$ENV_FILE"
    exit 1
fi

# Check for empty values
EMPTY_VARS=$(grep -E "^[A-Z_]+=$" "$ENV_FILE" || true)
if [ -n "$EMPTY_VARS" ]; then
    log_warning "Found empty variables:"
    echo "$EMPTY_VARS"
fi

log_success "Secrets validation passed"
```

#### 2.1.3 Standard .env Template

**File**: `secrets/template.env`

**Content**:
```bash
# Standard .env Template
# Copy this to your project and customize 1Password references

# Database
DATABASE_URL=op://vault/project-name/database_url
DB_USER=op://vault/project-name/db_user
DB_PASSWORD=op://vault/project-name/db_password

# APIs
API_KEY=op://vault/project-name/api_key
API_SECRET=op://vault/project-name/api_secret

# AWS / R2
AWS_ACCESS_KEY_ID=op://vault/r2-cloudflare/access_key
AWS_SECRET_ACCESS_KEY=op://vault/r2-cloudflare/secret_key
AWS_ENDPOINT_URL=https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com

# Application
APP_ENV=development
APP_DEBUG=true
APP_URL=http://localhost:3000
```

#### 2.1.4 Docker Compose Example

**File**: `secrets/docker-compose-op.yml`

**Content**:
```yaml
# Docker Compose with 1Password Integration
# Usage: op run --env-file=.env.template -- docker compose -f docker-compose-op.yml up

services:
  app:
    image: myapp:latest
    environment:
      - DATABASE_URL=op://vault/project/database_url
      - API_KEY=op://vault/project/api_key
      - AWS_ACCESS_KEY_ID=op://vault/r2/access_key
      - AWS_SECRET_ACCESS_KEY=op://vault/r2/secret_key
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
```

**Commands**:
```bash
chmod +x scripts/secrets/*.sh
```

**Test**:
```bash
# Create test template
cat > /tmp/test.env.template <<EOF
TEST_SECRET=op://vault/item/field
EOF

# Inject (requires 1Password configured)
eval $(op signin)
./scripts/secrets/inject-env.sh /tmp/test.env.template

# Validate
./scripts/secrets/validate-secrets.sh /tmp/test.env
```

**Output**:
- ✅ Secret injection script works with 1Password CLI
- ✅ Validation script detects issues
- ✅ Template and Docker Compose example provided
- ✅ Documentation in `docs/secrets-management.md`

**Duration**: 1 hour

---

### 2.2 Project Setup Script Template

**Objective**: Standard dev-setup.sh for all projects

**File**: `templates/project/dev-setup.sh.template`

**Content**:
```bash
#!/usr/bin/env bash
set -e

# Project Development Setup Script
# Generated from: ~/dev/projects/dotfiles/templates/project/dev-setup.sh.template

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() {
    echo -e "${BLUE}==>${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

cd "$PROJECT_ROOT"

log_step "Setting up $PROJECT_NAME"

# 1. Git fetch/pull
if [ -d ".git" ]; then
    log_step "Git fetch/pull..."
    git fetch origin
    git pull origin main
    log_success "Git updated"
fi

# 2. Inject secrets from 1Password
if [ -f ".env.template" ]; then
    log_step "Injecting secrets from 1Password..."

    # Ensure authenticated
    if ! op whoami &> /dev/null 2>&1; then
        eval $(op signin)
    fi

    op inject -i .env.template -o .env
    log_success "Secrets injected"
fi

# 3. Sync R2 assets (if manifest exists)
if [ -f ".r2-manifest.yml" ]; then
    log_step "Syncing R2 assets..."
    ~/dotfiles/scripts/sync/sync-r2.sh pull "$PROJECT_NAME"
    log_success "R2 assets synced"
fi

# 4. Update manifest links (if manifest exists)
if [ -f ".r2-manifest.yml" ]; then
    log_step "Updating manifest..."
    ~/dotfiles/scripts/sync/update-manifest.sh "$PROJECT_NAME"
    log_success "Manifest updated"
fi

# 5. Project-specific setup (customize below)
log_step "Running project-specific setup..."

# Uncomment and customize as needed:
# npm install
# pip install -r requirements.txt
# docker compose pull

log_success "$PROJECT_NAME ready!"
echo ""
echo "Next steps:"
echo "  - Start development server"
echo "  - Run tests"
echo "  - Check .env file"
```

**Usage Documentation**:

**File**: `templates/project/README.md`

**Content**:
```markdown
# Project Setup Script Template

## Purpose
This template provides a standard `dev-setup.sh` script for all projects, automating:
1. Git fetch/pull
2. Secret injection from 1Password
3. R2 asset synchronization
4. Manifest updates
5. Project-specific setup

## Usage

### 1. Copy Template to New Project
```bash
cp ~/dotfiles/templates/project/dev-setup.sh.template \
   ~/dev/projects/MY_PROJECT/scripts/dev-setup.sh

chmod +x ~/dev/projects/MY_PROJECT/scripts/dev-setup.sh
```

### 2. Customize Project-Specific Steps
Edit section 5 in `dev-setup.sh`:
```bash
# 5. Project-specific setup
npm install
pip install -r requirements.txt
docker compose pull
```

### 3. Run Setup
```bash
cd ~/dev/projects/MY_PROJECT
./scripts/dev-setup.sh
```

### 4. Create Alias (Optional)
Add to project's `.zshrc` or `.bashrc`:
```bash
alias dev-setup='./scripts/dev-setup.sh'
```

## Requirements
- 1Password CLI installed and authenticated
- Rclone configured for R2 (if using asset sync)
- `.env.template` file in project root (if using secrets)
- `.r2-manifest.yml` in project root (if using R2 assets)

## Integration with dotfiles
This script depends on:
- `~/dotfiles/scripts/sync/sync-r2.sh`
- `~/dotfiles/scripts/sync/update-manifest.sh`

Ensure dotfiles are installed and up to date.
```

**Output**:
- ✅ Template script ready for copying to projects
- ✅ Documentation explains usage
- ✅ Customizable for project-specific needs

**Duration**: 30 minutes

---

### 2.3 Rclone Setup for R2

**Objective**: Configure Rclone for Cloudflare R2 access

#### 2.3.1 Rclone Config Template

**File**: `sync/rclone/rclone.conf.template`

**Content**:
```ini
[r2]
type = s3
provider = Cloudflare
access_key_id = YOUR_ACCESS_KEY_FROM_1PASSWORD
secret_access_key = YOUR_SECRET_KEY_FROM_1PASSWORD
endpoint = https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com
acl = private
region = auto
```

#### 2.3.2 Rclone Setup Script

**File**: `scripts/sync/setup-rclone.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

RCLONE_CONF="$HOME/.config/rclone/rclone.conf"

log_step "Setting up Rclone for Cloudflare R2"

# Create config directory
mkdir -p "$(dirname "$RCLONE_CONF")"

# Check if already configured
if [ -f "$RCLONE_CONF" ] && rclone listremotes | grep -q "^r2:$"; then
    log_success "Rclone already configured for R2"
    log_info "Test with: rclone lsd r2:"
    exit 0
fi

# Get credentials from 1Password
log_info "Getting R2 credentials from 1Password..."

if ! op whoami &> /dev/null; then
    log_info "Signing in to 1Password..."
    eval $(op signin)
fi

# Read credentials (adjust vault/item/field names)
ACCESS_KEY=$(op read "op://vault/r2-cloudflare/access_key" 2>/dev/null || echo "")
SECRET_KEY=$(op read "op://vault/r2-cloudflare/secret_key" 2>/dev/null || echo "")
ACCOUNT_ID=$(op read "op://vault/r2-cloudflare/account_id" 2>/dev/null || echo "")

if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ] || [ -z "$ACCOUNT_ID" ]; then
    log_error "Failed to retrieve R2 credentials from 1Password"
    log_info "Please ensure the following exist in 1Password:"
    log_info "  - Vault: vault"
    log_info "  - Item: r2-cloudflare"
    log_info "  - Fields: access_key, secret_key, account_id"
    exit 1
fi

# Generate rclone config
log_info "Generating rclone config..."

cat > "$RCLONE_CONF" <<EOF
[r2]
type = s3
provider = Cloudflare
access_key_id = $ACCESS_KEY
secret_access_key = $SECRET_KEY
endpoint = https://${ACCOUNT_ID}.r2.cloudflarestorage.com
acl = private
region = auto
EOF

chmod 600 "$RCLONE_CONF"

log_success "Rclone configured for R2!"
log_info "Test with: rclone lsd r2:"

# Test connection
log_info "Testing R2 connection..."
if rclone lsd r2: &> /dev/null; then
    log_success "R2 connection successful!"
else
    log_warning "R2 connection test failed - check credentials"
fi
```

**Commands**:
```bash
chmod +x scripts/sync/setup-rclone.sh
```

**Test**:
```bash
./scripts/sync/setup-rclone.sh
rclone lsd r2:
```

**Output**:
- ✅ Rclone configured with R2 credentials from 1Password
- ✅ Config file created in `~/.config/rclone/rclone.conf`
- ✅ Connection test successful

**Duration**: 30 minutes

---

### 2.4 R2 Manifest System

**Objective**: Track binary assets with YAML manifests

#### 2.4.1 Manifest Schema

**File**: `sync/manifests/schema.yml`

**Content**:
```yaml
# R2 Asset Manifest Schema
# Version: 1.0
# Purpose: Track binary assets stored in Cloudflare R2

project: string                # Project name (required)
version: string                # Manifest version (default: "1.0")
updated: datetime              # Last update timestamp (ISO 8601)

assets:                        # List of assets (required)
  - path: string               # Local path relative to project root
    r2_key: string             # R2 object key (bucket path)
    size: integer              # File size in bytes
    sha256: string             # SHA256 checksum for verification
    type: string               # Asset type: model, dataset, media, document, etc.
    sync: boolean              # Whether to sync automatically (default: true)
    devices: array             # Target devices (optional)
      - string                 # Device names: macbook, mac-studio, ubuntu-vm-1, etc.
    description: string        # Human-readable description (optional)

# Example Manifest:
#
# project: my-ai-app
# version: "1.0"
# updated: 2025-01-17T10:30:00Z
# assets:
#   - path: data/models/whisper-large-v3.bin
#     r2_key: my-ai-app/models/whisper-large-v3.bin
#     size: 2847213568
#     sha256: a1b2c3d4e5f6...
#     type: model
#     sync: true
#     devices: [macbook, ubuntu-vm-1]
#     description: "OpenAI Whisper Large V3 model"
#
#   - path: data/datasets/training-data.tar.gz
#     r2_key: my-ai-app/datasets/training-data.tar.gz
#     size: 1073741824
#     sha256: 9f8e7d6c5b4a...
#     type: dataset
#     sync: false
#     devices: [mac-studio]
#     description: "Training dataset (10K samples)"
```

#### 2.4.2 Manifest README

**File**: `sync/manifests/README.md`

**Content**:
```markdown
# R2 Asset Manifests

## Purpose
Track binary assets stored in Cloudflare R2 and manage their synchronization across multiple devices.

## Manifest Location
Each project should have a `.r2-manifest.yml` file in its root directory.

## Workflow

### 1. Generate Manifest
When you add new binary assets to a project:
```bash
~/dotfiles/scripts/sync/generate-manifest.sh PROJECT_NAME
```

This will:
- Scan `data/` directory for all files
- Calculate file sizes and SHA256 checksums
- Generate `.r2-manifest.yml` with all metadata

### 2. Push Assets to R2
Upload assets to Cloudflare R2:
```bash
~/dotfiles/scripts/sync/sync-r2.sh push PROJECT_NAME --path data/models/new-model.bin
```

Or push all assets:
```bash
cd ~/dev/projects/PROJECT_NAME
rclone sync data/ r2:dotfiles-assets/PROJECT_NAME/
```

### 3. Pull Assets from R2
On a new machine or after clean install:
```bash
~/dotfiles/scripts/sync/sync-r2.sh pull PROJECT_NAME
```

This will:
- Read `.r2-manifest.yml`
- Download all assets marked with `sync: true`
- Verify checksums after download

### 4. Update Manifest
After modifying assets:
```bash
~/dotfiles/scripts/sync/update-manifest.sh PROJECT_NAME
```

## Best Practices

### 1. Commit Manifest to Git
The `.r2-manifest.yml` file should be committed to your project's git repository. It contains only metadata, not the actual binary files.

### 2. Gitignore Actual Assets
Add binary assets to `.gitignore`:
```gitignore
# In project/.gitignore
data/
*.bin
*.model
*.weights
*.tar.gz
```

### 3. Selective Sync
Use `sync: false` for assets that should not be automatically synchronized:
```yaml
assets:
  - path: data/huge-dataset.tar.gz
    sync: false  # Manual download only
```

### 4. Device Targeting
Specify which devices need which assets:
```yaml
assets:
  - path: data/models/small-model.bin
    devices: [macbook]  # Only for laptop

  - path: data/models/large-model.bin
    devices: [mac-studio, ubuntu-vm-1]  # Only for powerful machines
```

### 5. Verify Checksums
After sync, verify integrity:
```bash
~/dotfiles/scripts/sync/verify-manifest.sh PROJECT_NAME
```

## Troubleshooting

### Checksum Mismatch
If checksums don't match after download:
1. Re-download: `rclone copy --checksum r2:dotfiles-assets/PROJECT/file data/`
2. Regenerate manifest: `generate-manifest.sh PROJECT`

### Missing Assets
If assets are missing from R2:
1. Check manifest: `cat .r2-manifest.yml`
2. List R2 bucket: `rclone ls r2:dotfiles-assets/PROJECT/`
3. Upload missing: `rclone copy data/missing-file r2:dotfiles-assets/PROJECT/`

### Large File Transfers
For very large files (>5GB), use rclone directly with progress:
```bash
rclone copy --progress data/huge-file.bin r2:dotfiles-assets/PROJECT/
```
```

**Output**:
- ✅ Manifest schema documented with examples
- ✅ README explains complete workflow
- ✅ Best practices and troubleshooting included

**Duration**: 30 minutes

---

### 2.5 R2 Sync Scripts

**Objective**: Automate R2 asset synchronization

#### 2.5.1 Generate Manifest Script

**File**: `scripts/sync/generate-manifest.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <project-name>"
    echo ""
    echo "Example:"
    echo "  $0 my-app"
    echo ""
    echo "This will generate .r2-manifest.yml in ~/dev/projects/my-app/"
    exit 1
fi

PROJECT="$1"
PROJECT_DIR="$HOME/dev/projects/$PROJECT"
MANIFEST="$PROJECT_DIR/.r2-manifest.yml"

if [ ! -d "$PROJECT_DIR" ]; then
    log_error "Project directory not found: $PROJECT_DIR"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/data" ]; then
    log_warning "data/ directory not found in project"
    log_info "Creating data/ directory..."
    mkdir -p "$PROJECT_DIR/data"
fi

log_step "Generating manifest for $PROJECT"

cd "$PROJECT_DIR"

# Generate manifest header
cat > "$MANIFEST" <<EOF
project: $PROJECT
version: "1.0"
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

assets:
EOF

# Find all files in data/ directory
ASSET_COUNT=0

if [ -d "data" ]; then
    while IFS= read -r -d '' file; do
        # Get file info
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file")
        sha256=$(shasum -a 256 "$file" | cut -d' ' -f1)
        r2_key="$PROJECT/${file#data/}"

        # Detect asset type from extension
        case "${file##*.}" in
            bin|model|gguf|safetensors|weights) type="model" ;;
            tar|tar.gz|tgz|zip) type="dataset" ;;
            jpg|jpeg|png|gif|webp|svg) type="media" ;;
            mp4|mov|avi|mkv) type="video" ;;
            mp3|wav|flac) type="audio" ;;
            pdf|doc|docx) type="document" ;;
            *) type="data" ;;
        esac

        # Append to manifest
        cat >> "$MANIFEST" <<EOF
  - path: $file
    r2_key: $r2_key
    size: $size
    sha256: $sha256
    type: $type
    sync: true
    devices: [macbook, mac-studio, ubuntu-vm-1]
EOF

        ((ASSET_COUNT++))
        log_info "Added: $file ($type, $(numfmt --to=iec-i --suffix=B $size))"
    done < <(find data -type f -print0)
fi

if [ $ASSET_COUNT -eq 0 ]; then
    log_warning "No assets found in data/ directory"
else
    log_success "Generated manifest with $ASSET_COUNT assets"
fi

log_info "Manifest: $MANIFEST"
log_info "Next steps:"
echo "  1. Review and commit manifest: git add .r2-manifest.yml"
echo "  2. Push assets to R2: ~/dotfiles/scripts/sync/sync-r2.sh push $PROJECT"
```

#### 2.5.2 Sync R2 Script

**File**: `scripts/sync/sync-r2.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

COMMAND="$1"
PROJECT="$2"

if [ -z "$COMMAND" ] || [ -z "$PROJECT" ]; then
    echo "Usage: $0 {pull|push} <project-name> [options]"
    echo ""
    echo "Commands:"
    echo "  pull PROJECT              Pull all assets from R2"
    echo "  push PROJECT --path FILE  Push specific file to R2"
    echo ""
    echo "Examples:"
    echo "  $0 pull my-app"
    echo "  $0 push my-app --path data/models/new-model.bin"
    exit 1
fi

PROJECT_DIR="$HOME/dev/projects/$PROJECT"
MANIFEST="$PROJECT_DIR/.r2-manifest.yml"

if [ ! -f "$MANIFEST" ]; then
    log_error "Manifest not found: $MANIFEST"
    log_info "Generate manifest first: ~/dotfiles/scripts/sync/generate-manifest.sh $PROJECT"
    exit 1
fi

case "$COMMAND" in
    pull)
        log_step "Pulling assets for $PROJECT from R2"

        # Read manifest and sync each asset
        # Note: This is a simplified version. For production, use yq or Python to parse YAML
        while IFS= read -r line; do
            if [[ "$line" =~ path:\ (.+) ]]; then
                local_path="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ r2_key:\ (.+) ]]; then
                r2_key="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ sync:\ (.+) ]]; then
                should_sync="${BASH_REMATCH[1]}"

                # If we have both path and r2_key, and sync is true, download
                if [ -n "$local_path" ] && [ -n "$r2_key" ] && [ "$should_sync" = "true" ]; then
                    log_info "Syncing: $r2_key → $local_path"

                    # Create parent directory
                    mkdir -p "$PROJECT_DIR/$(dirname "$local_path")"

                    # Download with rclone
                    if rclone copy "r2:dotfiles-assets/$r2_key" "$PROJECT_DIR/$(dirname "$local_path")" --progress; then
                        log_success "Downloaded: $local_path"
                    else
                        log_error "Failed to download: $r2_key"
                    fi

                    # Reset variables
                    local_path=""
                    r2_key=""
                    should_sync=""
                fi
            fi
        done < "$MANIFEST"

        log_success "R2 pull complete!"
        ;;

    push)
        shift 2  # Remove 'push' and project name

        if [ "$1" != "--path" ] || [ -z "$2" ]; then
            log_error "Usage: $0 push PROJECT --path FILE"
            exit 1
        fi

        FILE_PATH="$2"
        FULL_PATH="$PROJECT_DIR/$FILE_PATH"

        if [ ! -f "$FULL_PATH" ]; then
            log_error "File not found: $FULL_PATH"
            exit 1
        fi

        log_step "Pushing $FILE_PATH to R2"

        # Extract r2_key from manifest for this file
        r2_key=""
        while IFS= read -r line; do
            if [[ "$line" =~ path:\ $FILE_PATH ]]; then
                # Next r2_key line is for this file
                read -r next_line
                if [[ "$next_line" =~ r2_key:\ (.+) ]]; then
                    r2_key="${BASH_REMATCH[1]}"
                    break
                fi
            fi
        done < "$MANIFEST"

        if [ -z "$r2_key" ]; then
            log_error "File not found in manifest: $FILE_PATH"
            log_info "Run: ~/dotfiles/scripts/sync/generate-manifest.sh $PROJECT"
            exit 1
        fi

        log_info "Uploading: $FULL_PATH → r2:dotfiles-assets/$r2_key"

        if rclone copy "$FULL_PATH" "r2:dotfiles-assets/$(dirname "$r2_key")" --progress; then
            log_success "Upload complete!"
        else
            log_error "Upload failed"
            exit 1
        fi
        ;;

    *)
        log_error "Unknown command: $COMMAND"
        exit 1
        ;;
esac
```

#### 2.5.3 Update Manifest Script

**File**: `scripts/sync/update-manifest.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <project-name>"
    exit 1
fi

PROJECT="$1"
PROJECT_DIR="$HOME/dev/projects/$PROJECT"
MANIFEST="$PROJECT_DIR/.r2-manifest.yml"

if [ ! -f "$MANIFEST" ]; then
    log_error "Manifest not found: $MANIFEST"
    exit 1
fi

log_step "Updating manifest for $PROJECT"

# Backup existing manifest
cp "$MANIFEST" "$MANIFEST.backup"

# Update timestamp
sed -i.tmp "s/^updated:.*/updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$MANIFEST"
rm -f "$MANIFEST.tmp"

log_success "Manifest updated!"
log_info "Backup saved: $MANIFEST.backup"
```

**Commands**:
```bash
chmod +x scripts/sync/*.sh
```

**Test** (with a test project):
```bash
# Create test project
mkdir -p ~/dev/projects/test-project/data/models
echo "test model" > ~/dev/projects/test-project/data/models/test.bin

# Generate manifest
./scripts/sync/generate-manifest.sh test-project

# View manifest
cat ~/dev/projects/test-project/.r2-manifest.yml

# Push to R2 (requires rclone configured)
./scripts/sync/sync-r2.sh push test-project --path data/models/test.bin

# Pull from R2 (after deleting local file)
rm ~/dev/projects/test-project/data/models/test.bin
./scripts/sync/sync-r2.sh pull test-project
```

**Output**:
- ✅ `generate-manifest.sh` creates valid YAML manifests
- ✅ `sync-r2.sh pull` downloads assets from R2
- ✅ `sync-r2.sh push` uploads assets to R2
- ✅ `update-manifest.sh` updates timestamps

**Duration**: 1.5 hours

---

### 2.6 Auto-Update Dotfiles

**Objective**: Automatic sync of dotfiles changes to GitHub

#### 2.6.1 Auto-Update Script

**File**: `scripts/sync/auto-update-dotfiles.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/logger.sh"

cd "$DOTFILES_DIR"

log_info "Checking for dotfiles changes..."

# Check if there are changes
if [ -z "$(git status --porcelain)" ]; then
    log_info "No changes detected"
    exit 0
fi

# Show changes
log_info "Detected changes:"
git status --short

# Check if we're on main branch
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
    log_warning "Not on main branch (current: $BRANCH), skipping auto-update"
    exit 0
fi

# Commit and push
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname -s)

log_info "Committing changes..."
git add -A
git commit -m "chore: auto-update dotfiles from $HOSTNAME - $TIMESTAMP"

log_info "Pushing to GitHub..."
if git push origin main; then
    log_success "Dotfiles auto-updated and pushed!"
else
    log_error "Failed to push to GitHub"
    exit 1
fi
```

#### 2.6.2 macOS LaunchAgent

**File**: `system/macos/launch-agents/com.dotfiles.autoupdate.plist`

**Content**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.dotfiles.autoupdate</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/YOUR_USERNAME/dev/projects/dotfiles/scripts/sync/auto-update-dotfiles.sh</string>
    </array>

    <key>StartInterval</key>
    <integer>1800</integer> <!-- 30 minutes -->

    <key>StandardOutPath</key>
    <string>/tmp/dotfiles-autoupdate.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/dotfiles-autoupdate.err</string>

    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
```

#### 2.6.3 Ubuntu systemd Service

**File**: `system/ubuntu/systemd/dotfiles-autoupdate.service`

**Content**:
```ini
[Unit]
Description=Auto-update dotfiles to GitHub
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=YOUR_USERNAME
ExecStart=/home/YOUR_USERNAME/dev/projects/dotfiles/scripts/sync/auto-update-dotfiles.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**File**: `system/ubuntu/systemd/dotfiles-autoupdate.timer`

**Content**:
```ini
[Unit]
Description=Auto-update dotfiles timer
Requires=dotfiles-autoupdate.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=30min
Persistent=true

[Install]
WantedBy=timers.target
```

#### 2.6.4 Installation Script

**File**: `scripts/sync/install-autoupdate.sh`

**Content**:
```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/detect-os.sh"
source "$SCRIPT_DIR/../utils/logger.sh"

OS=$(detect_os)

log_step "Installing Auto-Update for Dotfiles"

case "$OS" in
    macos)
        PLIST="$HOME/Library/LaunchAgents/com.dotfiles.autoupdate.plist"

        log_info "Installing LaunchAgent..."

        # Copy and customize plist
        cp "$DOTFILES_DIR/system/macos/launch-agents/com.dotfiles.autoupdate.plist" "$PLIST"
        sed -i '' "s|YOUR_USERNAME|$USER|g" "$PLIST"
        sed -i '' "s|/Users/.*/dev/projects/dotfiles|$DOTFILES_DIR|g" "$PLIST"

        # Load LaunchAgent
        launchctl unload "$PLIST" 2>/dev/null || true
        launchctl load "$PLIST"

        log_success "Auto-update enabled (every 30 minutes)"
        log_info "View logs: tail -f /tmp/dotfiles-autoupdate.log"
        log_info "Disable: launchctl unload $PLIST"
        ;;

    ubuntu)
        log_info "Installing systemd timer..."

        # Copy and customize systemd files
        sudo cp "$DOTFILES_DIR/system/ubuntu/systemd/dotfiles-autoupdate.service" /etc/systemd/system/
        sudo cp "$DOTFILES_DIR/system/ubuntu/systemd/dotfiles-autoupdate.timer" /etc/systemd/system/

        sudo sed -i "s|YOUR_USERNAME|$USER|g" /etc/systemd/system/dotfiles-autoupdate.service
        sudo sed -i "s|/home/.*/dev/projects/dotfiles|$DOTFILES_DIR|g" /etc/systemd/system/dotfiles-autoupdate.service

        # Reload and enable
        sudo systemctl daemon-reload
        sudo systemctl enable dotfiles-autoupdate.timer
        sudo systemctl start dotfiles-autoupdate.timer

        log_success "Auto-update enabled (every 30 minutes)"
        log_info "View logs: journalctl -u dotfiles-autoupdate -f"
        log_info "Disable: sudo systemctl stop dotfiles-autoupdate.timer"
        ;;

    *)
        log_error "Unsupported OS: $OS"
        exit 1
        ;;
esac
```

**Commands**:
```bash
chmod +x scripts/sync/auto-update-dotfiles.sh
chmod +x scripts/sync/install-autoupdate.sh
```

**Test**:
```bash
# Test script manually
./scripts/sync/auto-update-dotfiles.sh

# Install auto-update
./scripts/sync/install-autoupdate.sh

# Check status (macOS)
launchctl list | grep dotfiles

# Check status (Ubuntu)
systemctl status dotfiles-autoupdate.timer
```

**Output**:
- ✅ Auto-update script commits and pushes changes
- ✅ LaunchAgent (macOS) runs every 30 minutes
- ✅ systemd timer (Ubuntu) runs every 30 minutes
- ✅ Logs available for troubleshooting

**Duration**: 1 hour

---

## FASE 2 Verification

**Test Secret Injection**:
```bash
# Create test .env.template
cat > ~/test.env.template <<EOF
TEST_SECRET=op://vault/item/field
EOF

# Sign in to 1Password
eval $(op signin)

# Inject secrets
./scripts/secrets/inject-env.sh ~/test.env.template

# Verify
cat ~/test.env
./scripts/secrets/validate-secrets.sh ~/test.env
```

**Test R2 Sync**:
```bash
# Setup rclone
./scripts/sync/setup-rclone.sh

# Test connection
rclone lsd r2:

# Create test project
mkdir -p ~/dev/projects/test-sync/data
echo "test data" > ~/dev/projects/test-sync/data/test.txt

# Generate manifest
./scripts/sync/generate-manifest.sh test-sync

# Push to R2
./scripts/sync/sync-r2.sh push test-sync --path data/test.txt

# Pull from R2
rm ~/dev/projects/test-sync/data/test.txt
./scripts/sync/sync-r2.sh pull test-sync
```

**Test Auto-Update**:
```bash
# Install auto-update
./scripts/sync/install-autoupdate.sh

# Make a change
echo "# Test" >> README.md

# Wait 30 minutes or trigger manually
./scripts/sync/auto-update-dotfiles.sh

# Verify commit on GitHub
git log -1
```

---

## Complete FASE 1-2 Acceptance Test

**On Fresh Machine** (or VM):

```bash
# 1. Clone dotfiles
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dev/projects/dotfiles
cd ~/dev/projects/dotfiles

# 2. Run full installation
make install

# Expected output:
# [✓] Dependencies installed (Homebrew, Stow, 1Password CLI, Rclone, yq)
# [✓] Backed up existing configs
# [✓] All 5 packages stowed (shell, git, ssh, 1password, llm-tools)
# [✓] Health checks passed

# 3. Restart shell
exec $SHELL

# 4. Verify symlinks
ls -la ~ | grep "^l"
# Should show: .zshrc, .bashrc, .gitconfig, .ssh/config

# 5. Configure 1Password
eval $(op signin)

# 6. Setup Rclone for R2
./scripts/sync/setup-rclone.sh
rclone lsd r2:

# 7. Test project setup script
mkdir -p ~/dev/projects/test-app/data
cp templates/project/dev-setup.sh.template ~/dev/projects/test-app/scripts/dev-setup.sh
chmod +x ~/dev/projects/test-app/scripts/dev-setup.sh
cd ~/dev/projects/test-app
./scripts/dev-setup.sh

# 8. Install auto-update
cd ~/dev/projects/dotfiles
./scripts/sync/install-autoupdate.sh

# 9. Final health check
make health

# Expected output:
# [✓] All required commands installed
# [✓] 1Password CLI authenticated
# [✓] All symlinks correct
# [✓] Rclone configured for R2
# [✓] Auto-update enabled
```

---

## Summary

### FASE 1 Deliverables
✅ Complete directory structure
✅ Configuration files (.gitignore, .stow-local-ignore)
✅ Utility scripts (detect-os, logger)
✅ Bootstrap scripts (macOS, Ubuntu, master installer)
✅ 5 stow packages (shell, git, ssh, 1password, llm-tools)
✅ Stow automation scripts
✅ Health check scripts
✅ Makefile orchestration

### FASE 2 Deliverables
✅ 1Password CLI integration scripts
✅ Secret injection and validation
✅ Standard .env template and Docker Compose example
✅ Project dev-setup.sh template
✅ Rclone configuration for R2
✅ Manifest system (schema, README, scripts)
✅ R2 sync scripts (generate, pull, push, update)
✅ Auto-update dotfiles mechanism (LaunchAgent + systemd)

### Total Duration
- FASE 1: 6-8 hours
- FASE 2: 4-6 hours
- **Total: 10-14 hours**

### Next Steps (Post FASE 1-2)
- **FASE 3**: Applications & XDG Compliance (Brewfile, Cursor, iTerm2, app cleanup)
- **FASE 4**: VM Ubuntu Setup (complete Ubuntu bootstrap, Docker setup, testing)
- **FASE 5**: Templates & Automation (project templates, advanced health checks)
- **FASE 6**: Monitoring & Polish (Syncthing evaluation, complete documentation)

---

**Ready to Execute**: This plan is ready for implementation. Proceed with FASE 1.1!
