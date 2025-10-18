# Git Configuration Package

Complete Git configuration with 1Password SSH signing integration and gitignore.io workflow.

## Contents

- **`.gitconfig`** - Main Git configuration with aliases and 1Password signing
- **`.gitignore_global`** - Minimal global gitignore (use gitignore.io for specifics)
- **`.git-templates/hooks/`** - Template directory for Git hooks
- **`.ssh/allowed_signers`** - SSH signing verification for commits
- **`.gitconfig.local.template`** - Template for machine-specific overrides

## Installation

```bash
cd ~/dev/projects/dotfiles/stow-packages
stow -v -t ~ git
```

## Features

### 1Password SSH Signing
Commits are automatically signed using 1Password SSH agent. No need to manage GPG keys manually.

### Comprehensive Aliases
- **Status**: `git st`, `git s` (short)
- **Branch**: `git br`, `git ba` (all), `git bd` (delete)
- **Checkout**: `git co`, `git cob` (new branch)
- **Commit**: `git ci`, `git ca`, `git cm`, `git cam`, `git amend`
- **Add**: `git a`, `git aa` (all), `git unstage`
- **Log**: `git last`, `git l`, `git lg`, `git visual`, `git hist`
- **Diff**: `git d`, `git dc` (cached)
- **Remote**: `git pu`, `git puf` (force with lease), `git pl`
- **Stash**: `git ss`, `git sp`, `git sl`
- **Utilities**: `git aliases`, `git contributors`
- **Undo**: `git undo`, `git discard`

List all aliases: `git aliases`

### Gitignore.io Integration

This package uses a **minimal global gitignore** philosophy. Use the `gi` command (ZSH plugin) to generate project-specific ignores:

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

**ZSH Plugin**: [gitignore plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gitignore)

**Web Interface**: https://www.toptal.com/developers/gitignore

### Machine-Specific Configuration

For machine-specific settings (different email, proxy, etc.):

```bash
# 1. Copy template to home directory
cp ~/.gitconfig.local.template ~/.gitconfig.local

# 2. Edit with your machine-specific settings
# 3. The main .gitconfig includes this automatically
```

Example use cases:
- Work vs personal email
- Different SSH signing key
- Proxy settings
- Directory-specific config (conditional includes)

## Git Hooks

Place custom hooks in `~/.git-templates/hooks/`. They will be automatically copied to new repositories.

Example hooks:
- `pre-commit` - Linting, formatting
- `commit-msg` - Commit message validation
- `pre-push` - Run tests before push

## Verification

```bash
# Check configuration
git config --global --list

# Check aliases
git aliases

# Test signing (will prompt 1Password)
git commit -m "test" --allow-empty

# Verify signature
git log --show-signature -1
```

## Troubleshooting

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
ls -la ~/.gitconfig ~/.gitignore_global

# Re-stow if needed
cd ~/dev/projects/dotfiles/stow-packages
stow -R -v -t ~ git
```

### Gitignore.io Command Not Found
```bash
# Enable the gitignore plugin in ~/.zshrc
# Add 'gitignore' to plugins array
plugins=(git gitignore docker ...)

# Reload shell
exec $SHELL
```

## Cross-Platform Support

This configuration works on:
- **macOS** (primary)
- **Linux** (Ubuntu, Debian, Fedora, etc.)
- **Windows** (via WSL)

The `.gitignore_global` includes patterns for all platforms.

## Security Notes

- SSH signing key is **public** and safe to commit
- Email uses GitHub noreply address for privacy
- No private keys are stored in this repository
- 1Password handles all private key operations securely

## Related Packages

- **shell** - ZSH/Bash configuration (includes gitignore.io plugin)
- **ssh** - SSH configuration for Tailscale network

## References

- [Git Configuration Documentation](https://git-scm.com/docs/git-config)
- [1Password Git Commit Signing](https://developer.1password.com/docs/ssh/git-commit-signing/)
- [Gitignore.io](https://www.toptal.com/developers/gitignore)
- [GNU Stow](https://www.gnu.org/software/stow/)
