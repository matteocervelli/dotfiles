# GitHub CLI (gh) Configuration Package

Standardized GitHub CLI (`gh`) configuration managed through GNU Stow, following XDG Base Directory Specification.

## 📋 Table of Contents

- [Overview](#overview)
- [What's Included](#whats-included)
- [What's NOT Included](#whats-not-included)
- [Installation](#installation)
- [Configuration Files](#configuration-files)
- [XDG Compliance](#xdg-compliance)
- [Security Notes](#security-notes)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

---

## Overview

This package provides **preferences-only** configuration for GitHub CLI. Authentication credentials (`hosts.yml`) are **intentionally excluded** and remain machine-local for security.

### Why Separate Preferences from Credentials?

- ✅ **Safe to version control**: `config.yml` contains no secrets
- ✅ **Sync preferences across machines**: Same aliases, settings everywhere
- ✅ **Keep credentials local**: `hosts.yml` with tokens stays on each machine
- ✅ **Security best practice**: Never commit authentication tokens

---

## What's Included

Files that **ARE** symlinked from this package:

```
~/.config/gh/
└── config.yml → dotfiles/stow-packages/gh/.config/gh/config.yml
```

### config.yml Contents

- Git protocol preference (https/ssh)
- Editor preferences
- Interactive prompt settings
- Custom aliases
- Browser preferences
- Color and accessibility settings
- Spinner/progress indicator preferences

---

## What's NOT Included

Files that remain **machine-local** (excluded via `.stow-local-ignore`):

```
~/.config/gh/
├── hosts.yml      ← AUTHENTICATION TOKENS (machine-specific)
├── state.yml      ← Session state (machine-specific)
└── cache/         ← Temporary cache files
```

### Why hosts.yml is Excluded

`hosts.yml` contains:
- Personal access tokens
- OAuth tokens
- GitHub Enterprise authentication
- User-specific credentials

**NEVER commit this file to version control!**

---

## Installation

### Prerequisites

```bash
# Install GitHub CLI
brew install gh

# Authenticate (creates hosts.yml locally)
gh auth login
```

### Install Package

```bash
# From dotfiles root directory
./scripts/stow/stow-package.sh install gh

# Or with dry-run first (recommended)
./scripts/stow/stow-package.sh -n install gh
```

### Verify Installation

```bash
# Check symlink
ls -la ~/.config/gh/config.yml
# Should show: ~/.config/gh/config.yml -> .../dotfiles/stow-packages/gh/.config/gh/config.yml

# Verify both files exist
ls -la ~/.config/gh/
# Should show:
#   config.yml → [symlink to dotfiles]
#   hosts.yml  ← [local file, NOT symlinked]

# Test gh functionality
gh --version
gh auth status
```

---

## Configuration Files

### config.yml (Version Controlled)

**Location**: `~/.config/gh/config.yml` → `dotfiles/stow-packages/gh/.config/gh/config.yml`

**Contents**:
```yaml
version: 1
git_protocol: https          # Use https for git operations
prompt: enabled              # Interactive prompts enabled
aliases:
    co: pr checkout          # Custom alias: gh co
color_labels: disabled       # RGB color codes disabled
spinner: enabled            # Animated progress indicator
```

**Safe to modify**: Yes, changes will sync via git

### hosts.yml (Machine-Local)

**Location**: `~/.config/gh/hosts.yml` (local only, NOT in dotfiles)

**Contents**: Authentication tokens (example structure):
```yaml
github.com:
    user: yourusername
    oauth_token: gho_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    git_protocol: https
```

**Never commit this file!** It's automatically excluded via `.stow-local-ignore`.

---

## XDG Compliance

This package follows [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html):

| Purpose | XDG Location | Legacy Location |
|---------|-------------|-----------------|
| Config | `~/.config/gh/` | N/A (gh always used XDG) |
| Cache | `~/.cache/gh/` | N/A |
| State | `~/.local/state/gh/` | N/A |

**Note**: GitHub CLI (`gh`) has always used XDG locations by default. No migration needed!

---

## Security Notes

### Authentication Flow

1. **First-time setup on new machine**:
   ```bash
   # Clone dotfiles and stow gh package (gets config.yml)
   ./scripts/stow/stow-package.sh install gh

   # Authenticate (creates hosts.yml locally)
   gh auth login
   ```

2. **What happens**:
   - `config.yml`: Symlinked from dotfiles ✅
   - `hosts.yml`: Created locally by `gh auth login` ✅
   - Both files coexist in `~/.config/gh/` ✅

3. **Security guarantee**:
   - Dotfiles repo contains: Preferences only
   - Local machine has: Preferences + Credentials
   - Git never sees: `hosts.yml` (excluded via `.stow-local-ignore`)

### Token Storage

GitHub CLI stores tokens in `hosts.yml`:
- **Format**: Plain text (file permissions protect it)
- **Permissions**: `600` (read/write for user only)
- **Location**: `~/.config/gh/hosts.yml`
- **Never commit**: Excluded from stow, excluded from git

---

## Customization

### Adding Custom Aliases

Edit the config.yml **in the dotfiles repo**:

```bash
# Edit in dotfiles (source of truth)
vim ~/dev/projects/dotfiles/stow-packages/gh/.config/gh/config.yml

# Add your alias
aliases:
    co: pr checkout
    pv: pr view
    pc: pr create
    il: issue list

# Re-stow to apply (optional, symlink auto-updates)
./scripts/stow/stow-package.sh restow gh

# Test
gh pv  # Should run 'gh pr view'
```

**Changes are immediate** (symlink reflects dotfiles file).

### Changing Git Protocol

```yaml
# Use SSH instead of HTTPS
git_protocol: ssh
```

**Note**: Requires SSH keys configured in GitHub settings.

### Machine-Specific Overrides

For machine-specific settings, create a local config:

```bash
# Create override file (NOT in dotfiles)
cat > ~/.config/gh/config.local.yml << 'EOF'
# Machine-specific overrides
editor: vim
browser: firefox
EOF

# Note: gh doesn't natively support includes
# This is just for documentation/reference
```

---

## Troubleshooting

### Problem: "gh auth status" shows "not logged in"

**Cause**: `hosts.yml` doesn't exist on this machine

**Solution**: Authenticate
```bash
gh auth login
# Follow interactive prompts
```

### Problem: Changes to config.yml not taking effect

**Check symlink**:
```bash
ls -la ~/.config/gh/config.yml
# Should point to dotfiles directory

# If broken, re-stow
./scripts/stow/stow-package.sh restow gh
```

### Problem: "permission denied" when running gh

**Check file permissions**:
```bash
ls -la ~/.config/gh/
# hosts.yml should be 600 (rw-------)

# Fix if needed
chmod 600 ~/.config/gh/hosts.yml
```

### Problem: Accidentally committed hosts.yml

**Immediate action**:
```bash
# Remove from git history (CAREFUL!)
git rm --cached stow-packages/gh/.config/gh/hosts.yml

# Verify .stow-local-ignore has the rule
grep hosts.yml stow-packages/gh/.stow-local-ignore

# Rotate your tokens on GitHub
# Settings → Developer settings → Personal access tokens → Revoke
```

**Prevention**: The `.stow-local-ignore` should prevent this, but always verify.

### Problem: Config changes not syncing to other machines

**Workflow**:
```bash
# Machine A: Make changes
vim ~/dev/projects/dotfiles/stow-packages/gh/.config/gh/config.yml
git add stow-packages/gh/.config/gh/config.yml
git commit -m "feat(gh): add new aliases"
git push

# Machine B: Pull changes
cd ~/dev/projects/dotfiles
git pull
# Symlink automatically reflects new config (no restow needed!)
```

---

## Further Reading

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [gh config documentation](https://cli.github.com/manual/gh_config)
- [XDG Base Directory Spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)

---

## Quick Reference

```bash
# Install package
./scripts/stow/stow-package.sh install gh

# Uninstall package (keeps hosts.yml)
./scripts/stow/stow-package.sh uninstall gh

# Check authentication
gh auth status

# View current config
gh config list

# Edit preferences (in dotfiles)
vim ~/dev/projects/dotfiles/stow-packages/gh/.config/gh/config.yml

# Test aliases
gh co <pr-number>  # Checkout PR
```
