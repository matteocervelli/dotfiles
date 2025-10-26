# Dev-Env Stow Package

XDG-compliant environment configuration for development tools.

## Overview

This package configures XDG Base Directory compliance for various development tools by exporting environment variables that redirect config and history files to `~/.config/` and `~/.local/state/` respectively.

## What's Included

### ✅ Fully Configured

- **PostgreSQL (psql)**: Config and history → XDG locations
- **Bash**: History only → `$XDG_STATE_HOME/bash/history`
- **Less**: History → `$XDG_STATE_HOME/less/history`

### 🔧 Optional (Commented Out)

- **R**: Config and history → XDG locations (uncomment if you use R)
- **Python**: History → XDG location via PYTHONSTARTUP ⚠️ (complex, see warnings)
- **Node.js/npm**: Partial XDG support (uncomment if you use Node)
- **Docker**: Config → XDG location (uncomment if needed)

## Files

```
dev-env/
├── .config/
│   ├── shell/
│   │   └── dev-tools.sh          # Main XDG configuration script
│   └── python/
│       └── pythonrc              # Optional Python history redirect
├── .stow-local-ignore
└── README.md (this file)
```

## Installation

### 1. Deploy Package

```bash
cd /path/to/dotfiles
stow -t ~ dev-env
```

This creates:
- `~/.config/shell/dev-tools.sh` → symlink to this package

### 2. Source in Shell

The `dev-tools.sh` file is automatically sourced by the `shell` package in:
- `~/.zshrc` (if using ZSH)
- `~/.bashrc` (if using Bash)

If you haven't deployed the shell package yet:

```bash
# For ZSH users, add to ~/.zshrc:
[[ -f "$HOME/.config/shell/dev-tools.sh" ]] && source "$HOME/.config/shell/dev-tools.sh"

# For Bash users, add to ~/.bashrc:
[ -f "$HOME/.config/shell/dev-tools.sh" ] && source "$HOME/.config/shell/dev-tools.sh"
```

### 3. Reload Shell

```bash
# ZSH
source ~/.zshrc

# Bash
source ~/.bashrc
```

## Verification

Check that environment variables are set:

```bash
# XDG base directories
echo $XDG_CONFIG_HOME  # Should be: ~/.config
echo $XDG_STATE_HOME   # Should be: ~/.local/state

# PostgreSQL
echo $PSQLRC           # Should be: ~/.config/postgresql/psqlrc
echo $PSQL_HISTORY     # Should be: ~/.local/state/postgresql/history

# Bash
echo $HISTFILE         # Should be: ~/.local/state/bash/history

# Less
echo $LESSHISTFILE     # Should be: ~/.local/state/less/history
```

Test that applications respect the new locations:

```bash
# PostgreSQL (if installed)
psql --version
# Create a test history entry, then check:
cat "$PSQL_HISTORY"

# Bash
history 1
ls -la "$HISTFILE"

# Less
less /etc/hosts
# Press 'q', then check:
ls -la "$LESSHISTFILE"
```

## Migration

The `dev-tools.sh` script includes auto-migration functionality that runs once on first shell startup after installation.

It automatically moves:
- `~/.psql_history` → `$XDG_STATE_HOME/postgresql/history`
- `~/.bash_history` → `$XDG_STATE_HOME/bash/history`
- `~/.lesshst` → `$XDG_STATE_HOME/less/history`

A marker file `~/.xdg_migration_done` is created to prevent re-migration.

### Manual Migration

If you need to migrate manually or re-migrate:

```bash
# Remove marker file
rm ~/.xdg_migration_done

# Reload shell (migration will run automatically)
source ~/.zshrc
```

## Optional: Python History

⚠️ **WARNING**: Python history redirection is complex and comes with risks.

### Risks

- May create dual history files (`~/.python_history` AND XDG location)
- PYTHONSTARTUP affects ALL Python sessions (including scripts)
- Virtual environments might bypass PYTHONSTARTUP
- Requires testing with your specific Python setup

### To Enable

1. Edit `.config/shell/dev-tools.sh`
2. Uncomment the Python section:
   ```bash
   export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"
   ```
3. Reload shell: `source ~/.zshrc`
4. Test thoroughly:
   ```bash
   python3
   >>> import os
   >>> print(os.getenv('PYTHONSTARTUP'))
   >>> # Type some commands, then exit
   >>> exit()

   # Check history was written to XDG location
   cat "$XDG_STATE_HOME/python/history"

   # Verify no dual history file
   ls -la ~/.python_history  # Should not exist
   ```

### To Disable

1. Comment out Python section in `dev-tools.sh`
2. Unset variable: `unset PYTHONSTARTUP`
3. Reload shell

## Optional: R Configuration

To enable R XDG compliance:

1. Edit `.config/shell/dev-tools.sh`
2. Uncomment the R section
3. Create `~/.config/R/Rprofile` with your R configuration
4. Reload shell

Note: RStudio might not respect these custom locations.

## Uninstallation

```bash
cd /path/to/dotfiles
stow -D -t ~ dev-env
```

This removes the symlinks. Your XDG-located files remain intact.

To revert to legacy locations:

```bash
# Move files back
mv "$XDG_STATE_HOME/postgresql/history" ~/.psql_history
mv "$XDG_STATE_HOME/bash/history" ~/.bash_history
mv "$XDG_STATE_HOME/less/history" ~/.lesshst

# Remove XDG directories (optional)
rm -rf "$XDG_STATE_HOME/postgresql"
rm -rf "$XDG_STATE_HOME/bash"
rm -rf "$XDG_STATE_HOME/less"

# Remove migration marker
rm ~/.xdg_migration_done
```

## Documentation

For comprehensive XDG compliance information:
- [docs/xdg-compliance.md](../../docs/xdg-compliance.md) - Full XDG strategy
- [scripts/xdg-compliance/app-mappings.yml](../../scripts/xdg-compliance/app-mappings.yml) - Application inventory

## Troubleshooting

### Environment variables not set

**Check**: Is the shell package deployed and sourcing dev-tools.sh?

```bash
grep "dev-tools.sh" ~/.zshrc
```

### Application still writes to legacy location

**Solutions**:
1. Verify env var is exported: `echo $PSQLRC`
2. Check application version (old versions may not support custom paths)
3. Consult `app-mappings.yml` for known limitations

### Dual history files created

**For Python**: The PYTHONSTARTUP script might not be disabling the default history correctly. Check the script or disable PYTHONSTARTUP.

## Platform Support

- ✅ macOS (tested on Sequoia 15.x)
- ✅ Linux (tested on Ubuntu 22.04)
- ⚠️ Windows/WSL (not tested)

## Version

- **Created**: 2025-10-26
- **Status**: Active
- **Part of**: FASE 3.4 - XDG Compliance Implementation
