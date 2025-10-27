# Stow Packages

This directory contains all dotfiles organized as **GNU Stow packages**. Each subdirectory represents a package that can be independently installed, uninstalled, or re-installed.

## 📋 Table of Contents

- [What is GNU Stow?](#what-is-gnu-stow)
- [Package Structure](#package-structure)
- [Using Packages](#using-packages)
- [Creating New Packages](#creating-new-packages)
- [Why --no-folding?](#why---no-folding)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## What is GNU Stow?

**GNU Stow** is a symlink farm manager that makes it easy to manage dotfiles. Instead of copying files around, Stow creates symbolic links from your home directory to files in this repository.

### Benefits

- ✅ **Version Control**: All configs in git
- ✅ **Single Source of Truth**: GitHub repo is the master copy
- ✅ **Modular**: Install only what you need
- ✅ **Safe**: Easy to rollback (just unstow)
- ✅ **Cross-Machine**: Same setup everywhere

---

## Package Structure

Each package mirrors the structure it should have in your home directory (`~/`):

```
stow-packages/
├── shell/                  # Shell configuration package
│   ├── .config/
│   │   └── shell/
│   │       ├── aliases.sh
│   │       ├── exports.sh
│   │       └── functions.sh
│   ├── .bashrc
│   ├── .zshrc
│   └── .stow-local-ignore  # Files to ignore when stowing
├── git/                    # Git configuration package
│   ├── .gitconfig
│   ├── .gitignore_global
│   └── .stow-local-ignore
└── vscode/                 # VS Code settings
    └── .config/
        └── Code/
            └── User/
                └── settings.json
```

### How Stow Works

When you run `stow shell`, it creates symlinks like:

```
~/.bashrc        → dotfiles/stow-packages/shell/.bashrc
~/.zshrc         → dotfiles/stow-packages/shell/.zshrc
~/.config/shell/ ← real directory
  ├── aliases.sh   → dotfiles/stow-packages/shell/.config/shell/aliases.sh
  ├── exports.sh   → dotfiles/stow-packages/shell/.config/shell/exports.sh
  └── functions.sh → dotfiles/stow-packages/shell/.config/shell/functions.sh
```

**Note**: With `--no-folding` (our default), directories are created as real directories with individual file symlinks, NOT as directory symlinks.

---

## Using Packages

### Installation

We provide helper scripts that wrap GNU Stow with sensible defaults:

#### Install Single Package

```bash
# Install shell configuration
./scripts/stow/stow-package.sh install shell

# Dry-run to see what would happen (recommended first!)
./scripts/stow/stow-package.sh -n install shell

# Install git configuration
./scripts/stow/stow-package.sh install git
```

#### Install All Packages

```bash
# Install all packages
./scripts/stow/stow-all.sh

# Dry-run to preview all changes
./scripts/stow/stow-all.sh -n
```

### Uninstallation

```bash
# Uninstall single package
./scripts/stow/stow-package.sh uninstall shell

# Uninstall all packages
./scripts/stow/stow-all.sh uninstall
```

### Re-installation (Update)

```bash
# Re-install package (useful after updates)
./scripts/stow/stow-package.sh restow shell

# Re-install all packages
./scripts/stow/stow-all.sh restow
```

### Direct Stow Commands (Advanced)

If you prefer using `stow` directly:

```bash
# IMPORTANT: Always use --no-folding flag
cd ~/dev/projects/dotfiles/stow-packages

# Install package
stow --no-folding -v -t ~ shell

# Uninstall package
stow -D -v -t ~ shell

# Re-install package
stow -R --no-folding -v -t ~ shell

# Dry-run (simulate, don't execute)
stow -n --no-folding -v -t ~ shell
```

---

## Creating New Packages

### Step 1: Create Package Directory

```bash
cd ~/dev/projects/dotfiles/stow-packages
mkdir my-package
```

### Step 2: Mirror Home Directory Structure

Create the structure as it should appear in `~/`:

```bash
# Example: VSCode settings
my-package/
└── .config/
    └── Code/
        └── User/
            ├── settings.json
            └── keybindings.json

# Example: Python configuration
python/
├── .config/
│   └── pip/
│       └── pip.conf
└── .pypirc
```

### Step 3: Add `.stow-local-ignore` (Optional)

Create a `.stow-local-ignore` file to exclude files from stowing:

```bash
# .stow-local-ignore example
^/README\.md$       # Don't stow README
^/deploy.*\.sh$     # Don't stow deployment scripts
\.backup$           # Don't stow backup files
~$                  # Don't stow editor temp files
```

**Regex rules:**
- `^/` = root of package
- `$` = end of filename
- Use Perl regex syntax

### Step 4: Test Installation

```bash
# Dry-run first!
./scripts/stow/stow-package.sh -n install my-package

# If looks good, install for real
./scripts/stow/stow-package.sh install my-package
```

### Step 5: Verify Symlinks

```bash
# Check what was created
ls -la ~/.config/

# Verify specific symlink
readlink ~/.config/Code/User/settings.json
```

---

## Why --no-folding?

Our scripts use `--no-folding` flag by default. Here's why:

### Without --no-folding (Default Stow Behavior)

```
~/.config/shell → dotfiles/stow-packages/shell/.config/shell
```

Entire directory is a symlink (**tree folding**)

**Problems:**
- Less visible what's symlinked
- Can't mix stowed and non-stowed files in same directory
- If directory symlink breaks, entire config is lost

### With --no-folding (Our Approach)

```
~/.config/shell/          ← REAL directory
├── aliases.sh   → dotfiles/.../aliases.sh
├── exports.sh   → dotfiles/.../exports.sh
└── functions.sh → dotfiles/.../functions.sh
```

Individual files are symlinks

**Benefits:**
- ✅ Clear visibility of each symlinked file
- ✅ Can mix stowed and non-stowed files
- ✅ More granular control
- ✅ Safer (one broken link != whole config broken)
- ✅ Better for debugging

### Example: Mixing Stowed and Non-Stowed

With `--no-folding`, you can have:

```
~/.config/shell/
├── aliases.sh   → [stowed]
├── exports.sh   → [stowed]
├── local.sh     ← [machine-specific, NOT stowed]
└── work.sh      ← [work-only, NOT stowed]
```

This is **impossible** with tree folding!

---

## Best Practices

### 1. **Always Dry-Run First**

```bash
# See what WOULD happen before doing it
./scripts/stow/stow-package.sh -n install my-package
```

### 2. **One Concern Per Package**

- ✅ Good: `shell/`, `git/`, `vim/`, `vscode/`
- ❌ Bad: `dev-tools/` containing shell + git + vim

### 3. **Use Descriptive Package Names**

- Use lowercase
- Use hyphens for multi-word names
- Examples: `shell`, `git`, `node-tools`, `python-dev`

### 4. **Document Special Configurations**

Create a `README.md` in complex packages:

```
stow-packages/vscode/
├── .config/...
└── README.md  ← Document VS Code-specific setup
```

### 5. **Keep Secrets Out**

Never commit:
- API keys
- Passwords
- SSH private keys
- `.env` files with real secrets

Use templates instead:

```
stow-packages/secrets-template/
└── .env.template  # Template only, not real secrets
```

### 6. **Test on Fresh System**

Before relying on your dotfiles:

```bash
# On a fresh macOS/Ubuntu install
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
./scripts/bootstrap/install.sh
```

---

## Troubleshooting

### Problem: "Conflicts" Error

```
WARNING! stowing shell would cause conflicts:
  * existing target is not a link: .zshrc
```

**Solution**: Backup and remove existing file:

```bash
# Backup
mv ~/.zshrc ~/.zshrc.backup

# Try stow again
./scripts/stow/stow-package.sh install shell
```

### Problem: Symlink Points to Wrong Location

```bash
# Check current symlink
readlink ~/.zshrc

# If wrong, unstow and restow
./scripts/stow/stow-package.sh restow shell
```

### Problem: Package Appears Empty

```
⚠ Package 'git' appears to be empty (no files to stow)
```

**Cause**: Package only has `.stow-local-ignore` or is completely empty

**Solution**: Add actual dotfiles to the package

### Problem: Can't Find Stow Command

```
✗ GNU Stow is not installed
```

**Solution**: Install GNU Stow

```bash
# macOS
brew install stow

# Ubuntu/Debian
sudo apt install stow
```

### Problem: Permission Denied

```bash
# Make scripts executable
chmod +x scripts/stow/stow-package.sh
chmod +x scripts/stow/stow-all.sh
```

---

## Available Packages

| Package | Description | Status |
|---------|-------------|--------|
| `shell` | ZSH/Bash configuration, aliases, functions | ✅ Implemented |
| `git` | Git configuration and global gitignore | 🚧 Planned |
| `vscode` | VS Code settings and keybindings | ✅ Implemented |
| `ssh` | SSH configuration for Tailscale network | 🚧 Planned |
| `1password` | 1Password CLI configuration | 🚧 Planned |
| `bin` | Custom executable scripts | 🚧 Planned |
| `dev-env` | Development environment variables | 🚧 Planned |
| `iterm2` | iTerm2 configuration | 🚧 Planned |
| `llm-tools` | LLM and AI tools configuration | 🚧 Planned |

---

## Further Reading

- [GNU Stow Official Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Using GNU Stow for Dotfiles](https://alexpearce.me/2016/02/managing-dotfiles-with-stow/)
- [Dotfiles Best Practices](https://dotfiles.github.io/)

---

## Getting Help

- **Scripts Help**: Run with `-h` flag
  ```bash
  ./scripts/stow/stow-package.sh -h
  ./scripts/stow/stow-all.sh -h
  ```

- **Stow Manual**: `man stow`

- **Project Docs**: See `docs/` directory for architecture and implementation details
