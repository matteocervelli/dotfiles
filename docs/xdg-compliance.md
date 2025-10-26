# XDG Base Directory Compliance

**Last Updated**: 2025-10-26
**Status**: Implemented (FASE 3.4)
**Implementation**: Hybrid Approach

---

## Table of Contents

1. [Overview](#overview)
2. [XDG Specification](#xdg-specification)
3. [Our Hybrid Approach](#our-hybrid-approach)
4. [Application Analysis](#application-analysis)
5. [Implementation Guide](#implementation-guide)
6. [Rollback Procedures](#rollback-procedures)
7. [Troubleshooting](#troubleshooting)
8. [References](#references)

---

## Overview

The XDG Base Directory Specification defines standard locations for user files on Unix-like systems. This document outlines our **pragmatic hybrid approach** to XDG compliance, balancing:

- ✅ **Cleaner home directory** (fewer dotfiles clutter)
- ✅ **Better version control** (structured ~/.config/ directory)
- ✅ **Platform compatibility** (respecting macOS conventions)
- ✅ **Application stability** (avoiding breaking changes)

### Philosophy

> **Pragmatism over purity**: We implement XDG compliance where it provides clear benefits without breaking application functionality or creating excessive complexity.

### Key Decision

**Not all applications should be forced into XDG compliance**, especially on macOS where platform conventions differ from Linux. We document why certain applications are excluded and provide alternative solutions.

---

## XDG Specification

### Standard Directories

| Variable | Default | Purpose | Example Use Cases |
|----------|---------|---------|-------------------|
| `XDG_CONFIG_HOME` | `~/.config` | User-specific configuration files | Settings, preferences, rc files |
| `XDG_DATA_HOME` | `~/.local/share` | User-specific data files | Databases, plugins, themes |
| `XDG_STATE_HOME` | `~/.local/state` | User-specific state data | History, logs, undo files |
| `XDG_CACHE_HOME` | `~/.cache` | User-specific cached data | Temporary files, downloads |
| `XDG_RUNTIME_DIR` | `/run/user/$UID` | Runtime files (sockets, pipes) | Process-specific files |

### Benefits

- **Organization**: Logical grouping of configs, data, and cache
- **Backup**: Easier to backup just configs (`~/.config/`) vs entire home directory
- **Version Control**: Clear separation of version-controlled configs
- **Portability**: Standard locations across systems

### Limitations

- **Application Support**: Not all apps support XDG (especially on macOS)
- **Platform Differences**: macOS uses `~/Library/`, not `~/.config/`
- **Breaking Changes**: Forcing XDG can break apps or workflows

---

## Our Hybrid Approach

### Decision Matrix

We categorize each application into one of four categories:

#### ✅ **Supported** - Native XDG compliance
Applications with native XDG support via environment variables or configuration options.

**Examples**: Git, PostgreSQL (psql), R, Less, Neovim

**Action**: Implement XDG compliance via environment variables or config settings

#### 🟡 **Partial** - Limited XDG support
Applications that support XDG for some files (e.g., history) but not others (e.g., configs).

**Examples**: Bash (history only), ZSH (history only)

**Action**: Move supported files to XDG, document limitations

#### ❌ **Hardcoded** - No XDG support, best kept in default location
Applications hardcoded to specific paths, or where XDG migration would break core functionality.

**Examples**: VS Code (use Settings Sync instead), iTerm2 (binary plist format)

**Action**: Document as excluded, provide alternative solutions (backup scripts, cloud sync)

#### ⚠️ **Complex** - Technically possible but not recommended
Applications where XDG compliance requires complex workarounds prone to breakage.

**Examples**: Vim (requires VIMINIT hacks), Python history (dual file risk)

**Action**: Document complexity, recommend alternatives (Neovim for Vim, optional for Python)

---

## Application Analysis

### ✅ Supported Applications

#### Git
- **Status**: ✅ Already implemented in `stow-packages/git/`
- **Location**: `~/.config/git/config`
- **Implementation**: Native XDG support since Git 1.7.12
- **Notes**: No downsides on any platform

#### PostgreSQL (psql)
- **Status**: ✅ Implemented via environment variables
- **macOS**: `~/.psqlrc` → `$XDG_CONFIG_HOME/postgresql/psqlrc`
- **Linux**: Same as macOS
- **Implementation**:
  ```bash
  export PSQLRC="$XDG_CONFIG_HOME/postgresql/psqlrc"
  export PSQL_HISTORY="$XDG_STATE_HOME/postgresql/history"
  ```
- **Downsides**: Minimal - must ensure env vars set before psql runs
- **References**: [PostgreSQL Documentation](https://www.postgresql.org/docs/current/app-psql.html)

#### R
- **Status**: ✅ Implemented if R is used
- **macOS/Linux**: `~/.Rprofile` → `$XDG_CONFIG_HOME/R/Rprofile`
- **Implementation**:
  ```bash
  export R_PROFILE_USER="$XDG_CONFIG_HOME/R/Rprofile"
  export R_HISTFILE="$XDG_STATE_HOME/R/history"
  export R_ENVIRON_USER="$XDG_CONFIG_HOME/R/Renviron"
  ```
- **Downsides**: RStudio might not respect custom locations
- **References**: [R Startup Documentation](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Startup.html)

#### Less
- **Status**: ✅ Implemented
- **macOS/Linux**: `~/.lesshst` → `$XDG_STATE_HOME/less/history`
- **Implementation**:
  ```bash
  export LESSHISTFILE="$XDG_STATE_HOME/less/history"
  ```
- **Downsides**: None

#### Neovim
- **Status**: ✅ Native XDG support (already compliant)
- **Location**: `~/.config/nvim/`
- **Implementation**: None needed - native support via `NVIM_APPNAME`
- **Notes**: One of the best examples of native XDG compliance

### 🟡 Partial Applications

#### Bash
- **Status**: 🟡 Partial - history only
- **macOS**: Config files **must** stay in `~/` (no XDG support)
  - `~/.bash_profile` (login shell) - CANNOT MOVE
  - `~/.bashrc` (interactive shell) - CANNOT MOVE
  - `~/.bash_history` → `$XDG_STATE_HOME/bash/history` ✅
- **Linux**: Same limitations
- **Implementation**:
  ```bash
  export HISTFILE="$XDG_STATE_HOME/bash/history"
  ```
- **Downsides**:
  - Config files have NO XDG support
  - Cannot symlink configs without breaking shell initialization order
  - Only history can be moved
- **Rationale**: Partial compliance better than none; history is frequently modified

#### ZSH
- **Status**: 🟡 Partial - history only (already configured)
- **Location**: `~/.zshrc`, `~/.zprofile` must stay in `~/`
- **History**: Already moved to `$XDG_STATE_HOME/zsh/history` in `stow-packages/shell/`
- **Notes**: Similar to Bash - config files cannot be moved without complex ZDOTDIR setup

### ❌ Hardcoded Applications

#### VS Code
- **Status**: ❌ Hardcoded on macOS, do NOT migrate
- **macOS**: `~/Library/Application Support/Code/User/` (hardcoded by Microsoft)
- **Linux**: `~/.config/Code/User/` (already XDG compliant ✅)
- **Downsides of forcing XDG on macOS**:
  - Cannot be changed without breaking symlink hacks
  - **Conflicts with VS Code Settings Sync** (cloud-based config sync feature)
  - macOS updates may overwrite/break custom locations
  - Not designed for XDG on macOS by Microsoft
- **Recommendation**: **Use VS Code Settings Sync instead**
  - Enable: Settings → Settings Sync → Sign in with GitHub/Microsoft
  - Syncs settings, keybindings, extensions, snippets across machines
  - Cloud-based, more reliable than dotfiles for VS Code
- **Alternative**: For local backup, use export/import:
  ```bash
  # Export settings
  code --list-extensions > vscode-extensions.txt
  cp ~/Library/Application\ Support/Code/User/settings.json backups/
  cp ~/Library/Application\ Support/Code/User/keybindings.json backups/
  ```
- **References**: [VS Code Settings Sync](https://code.visualstudio.com/docs/editor/settings-sync)

#### iTerm2
- **Status**: ❌ Hardcoded, use backup/restore workflow
- **macOS**: `~/Library/Preferences/com.googlecode.iterm2.plist` (binary plist)
- **Partial XDG**: Some settings in `~/.config/iterm2/` (split configuration)
- **Downsides**:
  - Binary plist format unsuitable for version control
  - Custom location preference stored in default location (chicken-and-egg problem)
  - Partial XDG support creates confusion
- **Recommendation**: **Use export/import workflow**
  - Implemented in `stow-packages/iterm2/`
  - Scripts: `iterm2-backup`, `iterm2-restore`
  - Exports preferences to JSON/XML for version control
- **Implementation**:
  ```bash
  # Backup iTerm2 preferences
  iterm2-backup

  # Restore on new machine
  iterm2-restore
  ```

### ⚠️ Complex Applications

#### Vim (classic)
- **Status**: ⚠️ Complex - NOT recommended
- **macOS/Linux**: `~/.vimrc`, `~/.vim/` (no native XDG support)
- **Possible workaround**:
  ```bash
  export VIMINIT='source $XDG_CONFIG_HOME/vim/vimrc'
  ```
  But also requires setting:
  - `runtimepath`
  - `backupdir`
  - `directory`
  - `undodir`
  - `viewdir`
- **Downsides**:
  - Breaks plugins expecting `~/.vim/` location
  - Complex setup prone to errors
  - May conflict with system-wide Vim configurations
  - Requires extensive testing
- **Recommendation**: **Migrate to Neovim** (native XDG support) or keep Vim in legacy location
- **References**: [Make Vim XDG Compliant (complex)](https://jorenar.com/blog/vim-xdg)

#### Python History
- **Status**: ⚠️ Complex - optional, implement with caution
- **Default**: `~/.python_history` (no native XDG support)
- **Workaround**: PYTHONSTARTUP script
  ```python
  # $XDG_CONFIG_HOME/python/pythonrc
  import atexit
  import os
  import readline
  from pathlib import Path

  state_home = Path(os.getenv('XDG_STATE_HOME', Path.home() / '.local/state'))
  history_file = state_home / 'python' / 'history'
  history_file.parent.mkdir(parents=True, exist_ok=True)

  readline.read_history_file(str(history_file))
  atexit.register(readline.write_history_file, str(history_file))
  ```
  Then: `export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"`
- **Downsides**:
  - Risk of creating dual history files if not configured correctly
  - PYTHONSTARTUP affects **ALL** Python sessions (could interfere with scripts)
  - Virtual environments might bypass PYTHONSTARTUP
  - Complex readline setup required
- **Recommendation**: Only implement if you actively use Python interactively and understand the risks
- **References**: [Change Python History Location](https://unix.stackexchange.com/questions/630642/change-location-of-python-history)

---

## Implementation Guide

### 1. Environment Variables Setup

All XDG environment variables are configured in `stow-packages/dev-env/.config/shell/dev-tools.sh`:

```bash
# XDG Base Directories (set defaults if not defined)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# PostgreSQL
export PSQLRC="$XDG_CONFIG_HOME/postgresql/psqlrc"
export PSQL_HISTORY="$XDG_STATE_HOME/postgresql/history"

# Bash (history only)
export HISTFILE="$XDG_STATE_HOME/bash/history"

# R (if used)
export R_PROFILE_USER="$XDG_CONFIG_HOME/R/Rprofile"
export R_HISTFILE="$XDG_STATE_HOME/R/history"
export R_ENVIRON_USER="$XDG_CONFIG_HOME/R/Renviron"

# Less
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# Python (optional - commented out by default)
# export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
```

This file is sourced by `~/.zshrc` and `~/.bashrc` in the shell package.

### 2. Directory Creation

Directories are created automatically with proper permissions:

```bash
# Create XDG directories with proper permissions
mkdir -p "$XDG_CONFIG_HOME"/{git,postgresql,R,python,shell}
mkdir -p "$XDG_STATE_HOME"/{bash,postgresql,R,python,less}
mkdir -p "$XDG_CACHE_HOME"
mkdir -p "$XDG_DATA_HOME"

# Set permissions (700 for state dirs, 755 for config)
chmod 700 "$XDG_STATE_HOME"
chmod 755 "$XDG_CONFIG_HOME"
```

### 3. Migration from Legacy Locations

For applications being migrated to XDG:

```bash
# Example: Migrate PostgreSQL history
if [ -f ~/.psql_history ] && [ ! -f "$XDG_STATE_HOME/postgresql/history" ]; then
    mkdir -p "$XDG_STATE_HOME/postgresql"
    mv ~/.psql_history "$XDG_STATE_HOME/postgresql/history"
    echo "Migrated ~/.psql_history to $XDG_STATE_HOME/postgresql/history"
fi

# Example: Migrate bash history
if [ -f ~/.bash_history ] && [ ! -f "$XDG_STATE_HOME/bash/history" ]; then
    mkdir -p "$XDG_STATE_HOME/bash"
    mv ~/.bash_history "$XDG_STATE_HOME/bash/history"
    echo "Migrated ~/.bash_history to $XDG_STATE_HOME/bash/history"
fi
```

### 4. Stow Package Deployment

Deploy the dev-env package:

```bash
cd /path/to/dotfiles
stow -t ~ dev-env
```

Verify symlinks:

```bash
ls -la ~/.config/shell/dev-tools.sh
# Should show: ~/.config/shell/dev-tools.sh -> ../path/to/dotfiles/stow-packages/dev-env/.config/shell/dev-tools.sh
```

### 5. Testing

Verify environment variables:

```bash
# Check XDG variables
echo $XDG_CONFIG_HOME  # Should be: ~/.config
echo $XDG_STATE_HOME   # Should be: ~/.local/state

# Test PostgreSQL
echo $PSQLRC           # Should be: ~/.config/postgresql/psqlrc
psql --version         # Verify psql works

# Test bash history
echo $HISTFILE         # Should be: ~/.local/state/bash/history
history 1              # Verify history works
```

---

## Rollback Procedures

### Reverting to Legacy Locations

If XDG migration causes issues:

1. **Remove environment variables**:
   ```bash
   # Edit ~/.config/shell/dev-tools.sh and comment out problem variables
   # Then reload shell
   source ~/.zshrc
   ```

2. **Move files back to legacy locations**:
   ```bash
   # Example: Revert PostgreSQL
   mv "$XDG_STATE_HOME/postgresql/history" ~/.psql_history
   mv "$XDG_CONFIG_HOME/postgresql/psqlrc" ~/.psqlrc
   ```

3. **Unstow dev-env package**:
   ```bash
   cd /path/to/dotfiles
   stow -D -t ~ dev-env
   ```

### Backup Before Migration

Always backup before migrating:

```bash
# Create backup directory
mkdir -p ~/dotfiles-backup-$(date +%Y%m%d)

# Backup legacy files
cp ~/.psql_history ~/dotfiles-backup-$(date +%Y%m%d)/
cp ~/.bash_history ~/dotfiles-backup-$(date +%Y%m%d)/
cp ~/.lesshst ~/dotfiles-backup-$(date +%Y%m%d)/
```

---

## Troubleshooting

### Issue: Application ignores XDG location

**Symptoms**: Application still writes to `~/` instead of `~/.config/`

**Solutions**:
1. Verify environment variable is set:
   ```bash
   echo $PSQLRC  # Check it's defined
   ```
2. Verify variable is exported before application starts
3. Check application version (older versions may not support XDG)
4. Consult `scripts/xdg-compliance/app-mappings.yml` for known limitations

### Issue: Dual history files created

**Symptoms**: Both `~/.python_history` and `$XDG_STATE_HOME/python/history` exist

**Solutions**:
1. Verify PYTHONSTARTUP script disables default history file
2. Delete legacy file after verifying XDG location works:
   ```bash
   rm ~/.python_history
   ```
3. Check for conflicts with virtual environments

### Issue: Broken shell initialization

**Symptoms**: Shell doesn't start or shows errors about missing files

**Solutions**:
1. Boot into recovery mode or use another shell
2. Unstow dev-env package:
   ```bash
   cd /path/to/dotfiles && stow -D -t ~ dev-env
   ```
3. Check for syntax errors in `dev-tools.sh`
4. Restore from backup

### Issue: VS Code settings not syncing

**Symptoms**: Settings different across machines despite Settings Sync enabled

**Solutions**:
1. Verify Settings Sync is enabled and signed in
2. Check sync status: Settings → Settings Sync → Show Synced Data
3. Force sync: Command Palette → "Settings Sync: Sync Now"
4. Do NOT try to version control settings manually - conflicts with cloud sync

---

## References

### Official Specifications
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [ArchWiki: XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory)

### Application-Specific Documentation
- [VS Code Settings](https://code.visualstudio.com/docs/getstarted/settings)
- [VS Code Settings Sync](https://code.visualstudio.com/docs/editor/settings-sync)
- [iTerm2 Preferences](https://iterm2.com/documentation-preferences.html)
- [PostgreSQL psql](https://www.postgresql.org/docs/current/app-psql.html)
- [Neovim XDG Support](https://github.com/neovim/neovim/issues/78)
- [R Startup](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Startup.html)

### Guides & Tutorials
- [Making Bash XDG Compliant](https://hiphish.github.io/blog/2020/12/27/making-bash-xdg-compliant/)
- [Make Vim follow XDG](https://jorenar.com/blog/vim-xdg)
- [Python History XDG](https://unix.stackexchange.com/questions/630642/change-location-of-python-history)

### Project Documentation
- [Architecture Decisions (ADR)](../docs/ARCHITECTURE-DECISIONS.md)
- [Application Mappings](../scripts/xdg-compliance/app-mappings.yml)
- [TASK.md - Issue #21](../docs/TASK.md)

---

## Summary

| Category | Count | Applications |
|----------|-------|--------------|
| ✅ Supported | 5 | Git, PostgreSQL, R, Less, Neovim |
| 🟡 Partial | 2 | Bash (history only), ZSH (history only) |
| ❌ Hardcoded | 2 | VS Code (use Settings Sync), iTerm2 (backup/restore) |
| ⚠️ Complex | 2 | Vim (use Neovim), Python (optional) |

**Bottom Line**: We achieve **reasonable XDG compliance** (7/11 apps fully or partially compliant) while avoiding breaking changes and respecting platform conventions. For applications that don't fit XDG, we provide robust alternatives (Settings Sync for VS Code, backup scripts for iTerm2).

---

**Version**: 1.0
**Author**: Matteo Cervelli + Claude Code
**Last Review**: 2025-10-26
