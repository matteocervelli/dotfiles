# Git Configuration Package

Complete Git configuration with 1Password SSH signing integration, gitignore.io workflow, and XDG Base Directory compliance.

## 🎯 XDG Compliance

This package follows the **XDG Base Directory Specification**. All Git configuration files are stored in `~/.config/git/` instead of cluttering your home directory.

**Why XDG?**
- ✅ Cleaner home directory
- ✅ Standard location for all config files
- ✅ Better organization and backups
- ✅ Future-proof (modern apps use XDG)

## 📁 Contents

- **`.config/git/config`** - Main Git configuration (was `~/.gitconfig`)
- **`.config/git/ignore`** - Global gitignore patterns (was `~/.gitignore_global`)
- **`.config/git/templates/`** - Template directory for Git hooks (was `~/.git-templates/`)
- **`.config/git/config.local.template`** - Template for machine-specific overrides
- **`.ssh/allowed_signers`** - SSH signing verification for commits

## 🚀 Installation

### Using Stow Helper Scripts (Recommended)

```bash
cd ~/dev/projects/dotfiles
./scripts/stow/stow-package.sh install git
```

### Manual Stow

```bash
cd ~/dev/projects/dotfiles/stow-packages
stow --no-folding -v -t ~ git
```

## ✨ Features

### XDG Base Directory Support

All configuration follows XDG standards:

| File | XDG Location | Legacy Location |
|------|--------------|-----------------|
| Main config | `~/.config/git/config` | `~/.gitconfig` |
| Global ignore | `~/.config/git/ignore` | `~/.gitignore_global` |
| Templates | `~/.config/git/templates/` | `~/.git-templates/` |
| Local config | `~/.config/git/config.local` | `~/.gitconfig.local` |

**Note**: Git automatically uses `~/.config/git/` when `core.excludesFile` is not explicitly set.

### 1Password SSH Signing

Commits are automatically signed using 1Password SSH agent. No GPG key management needed.

**Setup**:
1. Install 1Password and enable SSH agent
2. Configuration is already set in `~/.config/git/config`
3. Commits will prompt for 1Password authentication

### Comprehensive Aliases

Quick reference for common Git operations:

**Status & Info**
```bash
git st        # status
git s         # status --short
```

**Branch Operations**
```bash
git br        # branch
git ba        # branch -a (all)
git bd        # branch -d (delete)
git bD        # branch -D (force delete)
```

**Checkout**
```bash
git co        # checkout
git cob       # checkout -b (new branch)
```

**Commit**
```bash
git ci        # commit
git ca        # commit -a
git cm        # commit -m
git cam       # commit -am
git amend     # commit --amend
```

**Add & Unstage**
```bash
git a         # add
git aa        # add --all
git unstage   # reset HEAD --
```

**Log & History**
```bash
git last      # log -1 HEAD
git l         # log --oneline --graph --decorate
git lg        # pretty log with graph
git visual    # log --graph --oneline --decorate --all
git hist      # log with dates
```

**Diff**
```bash
git d         # diff
git dc        # diff --cached
```

**Remote**
```bash
git pu        # push
git puf       # push --force-with-lease
git pl        # pull
```

**Stash**
```bash
git ss        # stash save
git sp        # stash pop
git sl        # stash list
```

**Utilities**
```bash
git aliases       # List all aliases
git contributors  # Show contributors with counts
```

**Undo**
```bash
git undo      # reset --soft HEAD^
git discard   # checkout --
```

List all aliases: `git aliases`

### Gitignore.io Integration

This package uses a **minimal global gitignore** philosophy. Generate project-specific patterns using the `gi` command (ZSH plugin):

```bash
# List available templates
gi list

# Generate ignores for specific technologies
gi macos,node,python

# Append to project .gitignore
gi macos,node,react >> .gitignore

# Common combinations
gi macos,linux,windows,vscode,node >> .gitignore         # Frontend
gi macos,python,django,vscode >> .gitignore              # Python
gi macos,go,vscode >> .gitignore                          # Go
gi macos,docker,terraform >> .gitignore                   # DevOps
```

**Resources**:
- **ZSH Plugin**: [gitignore plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gitignore)
- **Web Interface**: https://www.toptal.com/developers/gitignore

### Machine-Specific Configuration

For machine-specific settings (different email, proxy, etc.):

```bash
# 1. Copy template to config directory
cp ~/.config/git/config.local.template ~/.config/git/config.local

# 2. Edit with your machine-specific settings
cursor ~/.config/git/config.local

# 3. The main config includes this automatically
```

**Example use cases**:
- Work vs personal email
- Different SSH signing key per machine
- Proxy settings for corporate networks
- Directory-specific config (conditional includes)

Example `~/.config/git/config.local`:

```ini
# Work email override
[user]
    email = matteo.cervelli@company.com

# Different signing key
[user]
    signingkey = ssh-ed25519 AAAA...work-key

# Proxy for corporate network
[http]
    proxy = http://proxy.company.com:8080

# Conditional includes by directory
[includeIf "gitdir:~/work/"]
    path = ~/.config/git/config-work
[includeIf "gitdir:~/personal/"]
    path = ~/.config/git/config-personal
```

## 🪝 Git Hooks

Place custom hooks in `~/.config/git/templates/hooks/`. They will be automatically copied to new repositories via `init.templatedir` setting.

**Example hooks**:
- `pre-commit` - Linting, formatting
- `commit-msg` - Commit message validation
- `pre-push` - Run tests before push

**Setup**:
```bash
# Create a hook
cat > ~/.config/git/templates/hooks/pre-commit << 'EOF'
#!/bin/bash
npm run lint
EOF

# Make executable
chmod +x ~/.config/git/templates/hooks/pre-commit

# New repos will have this hook automatically
git init my-new-project
```

## ✅ Verification

### Check Configuration

```bash
# List all config with sources
git config --list --show-origin

# Check XDG config is being used
git config --list --show-origin | grep config/git

# Check aliases
git aliases

# Verify ignore file location (should be empty - using XDG default)
git config core.excludesfile
```

### Test Signing

```bash
# Create test commit (will prompt 1Password)
git commit -m "test" --allow-empty

# Verify signature
git log --show-signature -1
```

### Test Global Ignore

```bash
# Create test directory
cd /tmp && mkdir test-git && cd test-git
git init

# Create files that should be ignored
touch .DS_Store .env node_modules/

# Check status (should show nothing)
git status
# Should output: "nothing to commit"
```

## 🔧 Troubleshooting

### 1Password Signing Not Working

```bash
# Check 1Password CLI is installed
op --version

# Check SSH signing is enabled
git config --global commit.gpgsign
# Should return: true

# Check 1Password program path
git config --global gpg.ssh.program
# Should return: /Applications/1Password.app/Contents/MacOS/op-ssh-sign
```

### Symlinks Not Working

```bash
# Verify symlinks
ls -la ~/.config/git/

# Re-stow if needed
cd ~/dev/projects/dotfiles
./scripts/stow/stow-package.sh restow git
```

### Global Ignore Not Working

```bash
# Check if core.excludesFile is set (should be empty)
git config --global --show-origin core.excludesFile

# If set to old path, remove it
git config --global --unset core.excludesFile

# Git will use ~/.config/git/ignore automatically
```

### Gitignore.io Command Not Found

```bash
# Enable the gitignore plugin in ~/.zshrc
# Add 'gitignore' to plugins array
plugins=(git gitignore docker ...)

# Reload shell
exec $SHELL
```

## 🌍 Cross-Platform Support

This configuration works on:
- **macOS** (primary)
- **Linux** (Ubuntu, Debian, Fedora, etc.)
- **Windows** (via WSL)

The `.config/git/ignore` includes patterns for all platforms.

## 🔒 Security Notes

- SSH signing key is **public** and safe to commit
- Email uses GitHub noreply address for privacy
- No private keys are stored in this repository
- 1Password handles all private key operations securely
- `~/.config/git/config.local` is **NOT** tracked by Stow (machine-specific)

## 📚 Related Packages

- **shell** - ZSH/Bash configuration (includes gitignore.io plugin)
- **ssh** - SSH configuration for Tailscale network

## 🔗 References

- [Git Configuration Documentation](https://git-scm.com/docs/git-config)
- [Git Ignore Documentation](https://git-scm.com/docs/gitignore)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [1Password Git Commit Signing](https://developer.1password.com/docs/ssh/git-commit-signing/)
- [Gitignore.io](https://www.toptal.com/developers/gitignore)
- [GNU Stow](https://www.gnu.org/software/stow/)

## 📝 Migration Notes

This package was migrated from legacy locations to XDG Base Directory in version 2.0:

| Old Location | New Location |
|-------------|--------------|
| `~/.gitconfig` | `~/.config/git/config` |
| `~/.gitignore_global` | `~/.config/git/ignore` |
| `~/.git-templates/` | `~/.config/git/templates/` |
| `~/.gitconfig.local` | `~/.config/git/config.local` |

Benefits of XDG migration:
- Cleaner home directory
- Standard config location
- Better organization
- Easier backups
- Future-proof

---

**Version**: 2.0 (XDG)
**Last Updated**: 2025-01-19
