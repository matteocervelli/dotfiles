# macOS System Configuration

This directory contains macOS-specific system configurations and package management files.

## Contents

- **[Brewfile](Brewfile)** - Homebrew package manifest for reproducible macOS setup

## Brewfile Management

The Brewfile is the central package manifest that defines all Homebrew formulae, casks, and Mac App Store apps for your macOS setup.

### What is a Brewfile?

A Brewfile is to Homebrew what a `package.json` is to npm or `requirements.txt` is to pip. It's a declarative way to manage all your macOS packages in one place, making it easy to:

- **Reproduce** your setup on a new Mac
- **Share** your configuration with others
- **Version control** your installed packages
- **Automate** installation and updates

### Quick Start

```bash
# Generate Brewfile from current system
make brewfile-generate

# Validate Brewfile (check what's installed)
make brewfile-check

# Install all packages from Brewfile
make brewfile-install

# Update Brewfile from current system state
make brewfile-update
```

### Brewfile Structure

The Brewfile is organized into logical categories:

```ruby
# Taps - Third-party repositories
tap "homebrew/bundle"
tap "homebrew/services"

# Development Tools
brew "git"
brew "gh"
cask "visual-studio-code"

# Languages & Runtimes
brew "python@3.12"
brew "node"
brew "go"

# Databases & Data Tools
brew "postgresql@17"
brew "pgcli"

# Infrastructure & DevOps
brew "docker"
brew "ollama"
cask "tailscale"

# Security Tools
cask "1password-cli"
brew "gnupg"

# CLI Utilities & Tools
brew "bat"
brew "fzf"
brew "htop"

# Productivity Applications
cask "firefox"
cask "google-chrome"

# Media & Creative Tools
brew "ffmpeg"
brew "imagemagick"

# System Libraries & Dependencies
brew "openssl@3"
brew "readline"

# Mac App Store Applications
mas "Xcode", id: 497799835
mas "Keynote", id: 409183694
```

### Common Workflows

#### 1. Fresh macOS Setup

```bash
# Clone dotfiles
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles

# Bootstrap (install Homebrew, Stow, etc.)
make bootstrap

# Install all packages
make brewfile-install

# Verify installation
make brewfile-check
```

#### 2. Keep Brewfile Updated

```bash
# After manually installing new packages
brew install newtool
brew install --cask newapp

# Update Brewfile to include them
make brewfile-update

# Commit changes
git add system/macos/Brewfile
git commit -m "chore: add newtool and newapp to Brewfile"
```

#### 3. Sync Between Machines

```bash
# On Machine A: Update Brewfile
make brewfile-update
git push

# On Machine B: Pull and install
git pull
make brewfile-install
```

#### 4. Check What's Missing

```bash
# See what's in Brewfile but not installed
make brewfile-check

# Example output:
# The following formulae are missing:
#   bat
#   fzf
# The following casks are missing:
#   visual-studio-code
```

### Manual Brewfile Management

If you prefer manual control:

```bash
# Generate from audit data
./scripts/apps/generate-brewfile.sh

# Generate from current brew list
brew bundle dump --describe --force --file=system/macos/Brewfile

# Check status
brew bundle check --file=system/macos/Brewfile

# Install missing packages
brew bundle install --file=system/macos/Brewfile

# Install without upgrading existing
brew bundle install --no-upgrade --file=system/macos/Brewfile

# Cleanup (remove packages not in Brewfile)
brew bundle cleanup --file=system/macos/Brewfile

# Actually remove them (dry-run by default)
brew bundle cleanup --force --file=system/macos/Brewfile
```

### Tips & Best Practices

#### Keep Categories Organized

- Group related packages together
- Add comments to explain non-obvious packages
- Keep the file alphabetically sorted within categories

#### Version Pinning

```ruby
# Pin to specific version if needed
brew "postgresql@17"  # Not just "postgresql"
brew "python@3.12"    # Specific Python version
```

#### Conditional Packages

For machine-specific setups, consider using multiple Brewfiles (see [Issue #39](https://github.com/matteocervelli/dotfiles/issues/39) - Device-Specific Configurations).

#### Don't Commit Heavy Apps

Some apps are better installed manually:
- **Setapp** apps (managed by Setapp subscription)
- **Manual installations** (Parallels, specific licenses)
- **Company-specific** tools

List them in `applications/current_macos_apps_*.txt` for documentation but exclude from Brewfile.

### Troubleshooting

#### Brewfile Check Fails

```bash
# See detailed error
brew bundle check --file=system/macos/Brewfile --verbose

# Common issues:
# - Package renamed: Update Brewfile
# - Tap removed: Add correct tap or remove package
# - Cask vs formula confusion: Check with `brew search <package>`
```

#### Installation Hangs

```bash
# Some casks require interaction
# Run with verbose mode:
brew bundle install --file=system/macos/Brewfile --verbose

# Or install problematic packages manually:
brew install --cask <package-name>
```

#### Mac App Store Apps Won't Install

```bash
# Requires mas-cli
brew install mas

# Sign in to App Store first
mas account

# Then install
make brewfile-install
```

### Related Files

- [applications/vscode-extensions.txt](../../applications/vscode-extensions.txt) - VSCode extensions list
- [applications/current_macos_apps_*.txt](../../applications/) - Complete app audit
- [applications/remove-apps.txt](../../applications/remove-apps.txt) - Apps to uninstall

### Generation Script

The Brewfile is generated by [`scripts/apps/generate-brewfile.sh`](../../scripts/apps/generate-brewfile.sh):

```bash
# Generate from most recent audit
./scripts/apps/generate-brewfile.sh

# Generate from specific audit
./scripts/apps/generate-brewfile.sh --input applications/current_macos_apps_2025-10-25.txt

# Dry-run (preview output)
./scripts/apps/generate-brewfile.sh --dry-run

# Custom output location
./scripts/apps/generate-brewfile.sh --output /tmp/test-brewfile

# Show help
./scripts/apps/generate-brewfile.sh --help
```

### Integration with Other Systems

#### Device Profiles

The Brewfile serves as the **macOS baseline** for:
- [Issue #39](https://github.com/matteocervelli/dotfiles/issues/39) - Device-Specific Configurations
  - Mac Studio (full development stack)
  - MacBook (portable, battery-optimized)
  - VM/VPS (minimal server setup)

#### Cross-Platform Equivalents

The package categorization informs:
- [Issue #37](https://github.com/matteocervelli/dotfiles/issues/37) - Linux package management
- [Issue #38](https://github.com/matteocervelli/dotfiles/issues/38) - Windows package management

### Resources

- [Homebrew Bundle Documentation](https://github.com/Homebrew/homebrew-bundle)
- [Homebrew Formula Search](https://formulae.brew.sh/)
- [Mac App Store CLI (mas)](https://github.com/mas-cli/mas)

---

**Last Updated**: 2025-10-25
**Issue**: [#20 - Brewfile & App Management](https://github.com/matteocervelli/dotfiles/issues/20)
