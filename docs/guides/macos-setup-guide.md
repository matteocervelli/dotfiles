# macOS Setup Guide

Complete guide for formatting and setting up a fresh MacBook with this dotfiles repository.

## Table of Contents

1. [Pre-Format Preparation](#pre-format-preparation)
2. [Fresh macOS Installation](#fresh-macos-installation)
3. [Initial System Setup](#initial-system-setup)
4. [Dotfiles Installation](#dotfiles-installation)
5. [Application Restoration](#application-restoration)
6. [System Configuration](#system-configuration)
7. [Development Environment](#development-environment)
8. [Verification & Testing](#verification--testing)
9. [Troubleshooting](#troubleshooting)

---

## Pre-Format Preparation

Before wiping your Mac, ensure you have backed up everything you need.

### 1. Audit Current System

```bash
# Navigate to your dotfiles repository
cd ~/dev/projects/dotfiles

# Audit all installed applications
./scripts/apps/audit-apps.sh

# This generates:
# - applications/current-apps.txt (all installed apps)
# Review this file before formatting
```

### 2. Backup Important Data

**Essential Backups:**
- [ ] Time Machine backup (full system backup)
- [ ] iCloud Drive sync completed
- [ ] 1Password vault synced
- [ ] SSH keys and GPG keys (already in dotfiles/stow-packages/ssh)
- [ ] Browser bookmarks and extensions
- [ ] Application licenses and serial numbers
- [ ] Custom fonts and assets
- [ ] Work documents and projects

**Dotfiles Repository:**
```bash
# Ensure your dotfiles are committed and pushed
cd ~/dev/projects/dotfiles
git status
git add .
git commit -m "Pre-format backup: Save current configurations"
git push origin main
```

**Application Configurations:**
```bash
# Update Brewfile from current system
brew bundle dump --describe --force --file=system/macos/Brewfile
git add system/macos/Brewfile
git commit -m "Update Brewfile before format"
git push
```

**Media Library Backup (if using asset management):**
```bash
# Sync ~/media/cdn/ to Cloudflare R2
cdnsync

# Or manually
rclone sync ~/media/cdn/ r2:your-bucket/cdn/
```

### 3. Compare with Other Machines (Optional)

If you have multiple Macs (e.g., MacBook and Mac Studio), compare their configurations:

**Compare current machine vs another machine:**
```bash
# Run audit on current machine
./scripts/apps/audit-apps.sh
# Generates: applications/current_macos_apps_2025-10-26.txt

# If you have an audit from another machine (Mac Studio, etc.):
./scripts/apps/compare-apps.sh \
  applications/current_macos_apps_2025-10-26.txt \
  applications/mac-studio-apps-2025-10-20.txt
```

**Compare current machine vs Brewfile:**
```bash
# See what's different between your system and the Brewfile
./scripts/apps/compare-apps.sh --brewfile
```

**Output shows three sections:**
- **Only in Machine 1** - Apps to add to Machine 2
- **Only in Machine 2** - Apps to add to Machine 1
- **In Both** - Apps that match

This helps you decide:
- Which apps to install on the new machine
- Which apps to remove (add to `applications/remove-apps.txt`)
- Whether to update your Brewfile

### 4. Document Current Settings

**System Preferences Screenshots:**
- System Settings → Appearance
- System Settings → Desktop & Dock
- System Settings → Displays
- Keyboard → Shortcuts
- Trackpad settings
- Security & Privacy settings

**Application Settings:**
- iTerm2: Backup preferences
  ```bash
  iterm2-backup
  # Creates: stow-packages/iterm2/backups/iterm2-preferences-TIMESTAMP.xml
  git add stow-packages/iterm2/backups/
  git commit -m "Backup iTerm2 preferences"
  git push
  ```
- VS Code: Ensure Settings Sync is enabled
- Cursor: Settings should sync via cloud

### 5. Deauthorize Software

Before formatting:
- [ ] iTunes: Account → Authorizations → Deauthorize This Computer
- [ ] Adobe Creative Cloud (if installed)
- [ ] Any other licensed software with device limits

### 6. Create Checklist

Document any custom configurations not in dotfiles:
- Custom keyboard shortcuts
- Third-party app settings
- Network configurations (VPNs, proxies)
- Printer configurations

---

## Fresh macOS Installation

### 1. Create Bootable Installer (Optional)

If you want a completely clean install:

```bash
# Download macOS installer from App Store
# Insert USB drive (16GB+)
# Replace "MyVolume" with your USB drive name

sudo /Applications/Install\ macOS\ Sonoma.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyVolume
```

### 2. Erase Mac

**Option A: Erase All Content and Settings (macOS Monterey+)**
1. Open System Settings
2. General → Transfer or Reset
3. Erase All Content and Settings
4. Follow on-screen instructions

**Option B: Recovery Mode (Intel Mac)**
1. Restart and hold ⌘+R
2. Disk Utility → Erase Macintosh HD
3. Format: APFS
4. Reinstall macOS

**Option C: Recovery Mode (Apple Silicon)**
1. Shut down Mac
2. Hold power button until "Loading startup options" appears
3. Select Options → Continue
4. Disk Utility → Erase Macintosh HD
5. Format: APFS
6. Reinstall macOS

### 3. macOS Setup Assistant

During first boot:
- **Region**: Select your country
- **Wi-Fi**: Connect to network
- **Data & Privacy**: Review and continue
- **Migration Assistant**: Choose "Not Now" (fresh install)
- **Apple ID**: Sign in
- **Terms and Conditions**: Agree
- **Create Account**: Set up your user account
  - Full Name: Your Name
  - Account Name: `matteo` (or your username)
  - Password: Use strong password
- **Express Setup**: Customize settings
- **Analytics**: Choose your preference
- **Screen Time**: Skip for now
- **Siri**: Enable if desired
- **FileVault**: Enable disk encryption (recommended)
- **Touch ID**: Set up fingerprint (if available)
- **Apple Pay**: Skip for now
- **iCloud**: Enable iCloud Drive, Photos as desired

---

## Initial System Setup

### 1. Essential Settings

Before installing anything:

```bash
# Enable showing hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder

# Install Xcode Command Line Tools (required for Homebrew)
xcode-select --install
# Click "Install" in the popup dialog
# Wait for installation to complete (5-10 minutes)

# Verify installation
xcode-select -p
# Should output: /Library/Developer/CommandLineTools
```

### 2. System Settings Configuration

**Essential Settings to Configure:**

1. **System Settings → Appearance**
   - Appearance: Auto, Light, or Dark
   - Accent color: Your preference
   - Show scroll bars: Always

2. **System Settings → Desktop & Dock**
   - Size: Adjust to preference
   - Magnification: Optional
   - Position: Bottom (or your preference)
   - Minimize windows using: Scale effect
   - Show recent applications: Off
   - Automatically hide and show the Dock: Optional

3. **System Settings → Displays**
   - Resolution: Scaled (More Space for more screen real estate)
   - Night Shift: Schedule if desired

4. **System Settings → Keyboard**
   - Key repeat rate: Fast
   - Delay until repeat: Short
   - Keyboard Shortcuts → Modifier Keys: Remap Caps Lock to Control (optional)

5. **System Settings → Trackpad**
   - Tap to click: Enable
   - Tracking speed: Fast
   - Three finger drag: Enable (Accessibility → Motor → Pointer Control)

6. **System Settings → Security & Privacy**
   - FileVault: Already enabled during setup
   - Firewall: Turn On
   - Privacy: Review app permissions as needed

### 3. Finder Preferences

1. **Finder → Settings**
   - General → Show these items on the desktop: External disks, Hard disks (optional)
   - General → New Finder windows show: Home folder
   - Sidebar: Check items you want visible
   - Advanced → Show all filename extensions: Enable
   - Advanced → Show warning before changing an extension: Disable
   - Advanced → When performing a search: Search the Current Folder

---

## Dotfiles Installation

> **Note:** This section covers both **automated** and **customized** installation options. Choose the approach that fits your needs.

### 1. Clone Repository

```bash
# Create development directory structure
mkdir -p ~/dev/projects

# Clone dotfiles repository
cd ~/dev/projects
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles
```

### 2. Choose Installation Method

#### Option A: Automated Installation (Recommended)

The bootstrap script installs all core dependencies:

```bash
# Run the master installation script
./scripts/bootstrap/install.sh
```

**What it installs:**
- ✅ Homebrew (package manager)
- ✅ GNU Stow (symlink manager)
- ✅ 1Password CLI (secret management)
- ✅ Rclone (cloud storage sync)
- ✅ yq (YAML processor)
- ✅ Oh My Zsh (shell framework)
- ✅ ZSH plugins (autosuggestions, syntax-highlighting)
- ✅ Powerlevel10k (ZSH theme)
- ✅ All stow packages (shell, git, ssh, etc.)
- ✅ Health checks
- ✅ Auto-update service

**Installation time:** ~10-15 minutes (depending on internet speed)

---

#### Option B: Customized Installation

If you want more control over what gets installed:

**Step 1: Install Core Dependencies Only**

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install essential tools
brew install stow git
```

**Step 2: Selectively Install Stow Packages**

Instead of installing everything, choose what you need:

```bash
cd ~/dev/projects/dotfiles

# List available packages
ls -1 stow-packages/

# Install specific packages
./scripts/stow/stow-package.sh install shell     # Shell configuration
./scripts/stow/stow-package.sh install git       # Git configuration
./scripts/stow/stow-package.sh install ssh       # SSH configuration
./scripts/stow/stow-package.sh install cursor    # Cursor settings
./scripts/stow/stow-package.sh install dev-env   # XDG compliance

# Or install all at once
./scripts/stow/stow-all.sh
```

**Step 3: Install Optional Dependencies**

```bash
# 1Password CLI (if you use it)
brew install --cask 1password-cli

# Rclone (if you use asset management)
brew install rclone

# Oh My Zsh (if you want enhanced shell)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ZSH plugins (optional)
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Powerlevel10k theme (optional)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

**Step 4: Customize Brewfile (Optional)**

Before installing all applications:

```bash
# Edit Brewfile to remove unwanted packages
vim system/macos/Brewfile

# Comment out or delete lines for apps you don't need
# Example: Remove if you don't use R programming
# brew "r"           # ← Delete or comment this line
```

---

### 3. Manual Bootstrap (Step-by-Step Reference)

If you prefer step-by-step installation:

```bash
# Step 1: Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Step 2: Install core dependencies
brew install stow
brew install --cask 1password-cli
brew install rclone
brew install yq

# Step 3: Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Step 4: Install ZSH plugins
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Step 5: Deploy dotfiles with Stow
cd ~/dev/projects/dotfiles
./scripts/stow/stow-all.sh

# Step 6: Install auto-update service
./scripts/sync/install-autoupdate.sh
```

### 4. Post-Installation Steps (All Methods)

```bash
# Restart your shell to apply configurations
exec $SHELL

# Sign in to 1Password CLI
eval $(op signin)

# Configure Rclone for R2 (if using asset management)
./scripts/sync/setup-rclone.sh

# Run health check
make health
```

---

## Application Restoration

> **Tip:** Before installing everything, compare your Brewfile against your pre-format audit to see what's different.
> ```bash
> ./scripts/apps/compare-apps.sh --brewfile
> ```

### 1. Install Applications from Brewfile

The repository includes a comprehensive Brewfile with all applications:

```bash
cd ~/dev/projects/dotfiles

# Preview what will be installed
brew bundle check --file=system/macos/Brewfile

# Install all applications
brew bundle install --file=system/macos/Brewfile
```

**Installation time:** 30-60 minutes (300+ packages)

**What gets installed:**

- **Development Tools**: Git, GitHub CLI, VS Code, Neovim, Lazygit
- **Languages & Runtimes**: Python, Node.js, Go, Rust, Ruby, Java, Deno
- **Databases**: PostgreSQL 17, SQLite, pgAdmin, pgcli
- **Infrastructure**: Docker (via Homebrew), Tailscale, Ollama, Caddy
- **Security**: GPG, 1Password CLI, mkcert, OpenSSL
- **CLI Tools**: bat, eza, fzf, htop, btop, tmux, tree, wget, curl
- **Productivity**: Firefox, Chrome, Edge, LibreOffice, Zotero
- **Media Tools**: FFmpeg, VLC, ImageMagick, Audacity, OBS

### 2. Generate Custom Brewfile

If you want to customize based on your pre-format audit:

```bash
# Review your pre-format application list
cat applications/current-apps.txt

# Generate a new Brewfile from audit data
./scripts/apps/generate-brewfile.sh

# Or update from currently installed packages
make brewfile-update
```

### 3. Mac App Store Applications

Some apps require manual installation from Mac App Store:

```bash
# Install mas-cli if not already installed
brew install mas

# Sign in to Mac App Store
mas account

# Search for apps
mas search Xcode
mas search "Final Cut Pro"

# Install by ID
mas install 497799835  # Xcode
```

**Common Mac App Store Apps:**
- Xcode (497799835)
- TestFlight (899247664)
- Keynote (409183694)
- Numbers (409203825)
- Pages (409201541)

### 4. Manual Application Installations

Some applications might not be in Homebrew:

- **Cursor**: Download from https://cursor.sh
- **Claude Code**: Already included via MCP configuration
- **Specialized Software**: Adobe Creative Cloud, Office 365, etc.

---

## System Configuration

### 1. macOS System Defaults

Configure macOS system preferences via command line:

```bash
# These settings enhance productivity and development workflow

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Reveal IP address, hostname, OS version when clicking the clock in login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Restart affected apps
killall SystemUIServer Finder
```

**Note:** More advanced system configurations can be added to a dedicated script in `system/macos/defaults/`.

### 2. Dock Configuration

```bash
# Set Dock icon size
defaults write com.apple.dock tilesize -int 48

# Auto-hide the Dock (optional)
defaults write com.apple.dock autohide -bool true

# Don't show recent applications
defaults write com.apple.dock show-recents -bool false

# Restart Dock
killall Dock
```

### 3. Finder Configuration

```bash
# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Use list view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Restart Finder
killall Finder
```

### 4. Keyboard & Input

```bash
# Enable full keyboard access for all controls
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
```

### 5. Screenshots

```bash
# Save screenshots to ~/Pictures/Screenshots
mkdir -p ~/Pictures/Screenshots
defaults write com.apple.screencapture location -string "~/Pictures/Screenshots"

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Restart SystemUIServer
killall SystemUIServer
```

---

## Development Environment

### 1. Shell Configuration

Your shell should already be configured via stow packages. Verify:

```bash
# Check ZSH is default shell
echo $SHELL
# Should output: /bin/zsh

# Verify dotfiles are loaded
cat ~/.zshrc
# Should source from ~/dev/projects/dotfiles/stow-packages/shell/.zshrc

# Check aliases and functions
alias
# Should show custom aliases like ll, la, etc.
```

### 2. Git Configuration

```bash
# Verify Git configuration
git config --list --show-origin

# Set your identity (if not already set)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify GPG signing (if using 1Password)
git config --global gpg.format openpgp
git config --global user.signingkey "YOUR_GPG_KEY_ID"
git config --global commit.gpgsign true
```

### 3. SSH Configuration

```bash
# Verify SSH config
cat ~/.ssh/config
# Should show Tailscale network configurations

# Generate new SSH key if needed
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Add to GitHub
pbcopy < ~/.ssh/id_ed25519.pub
# Paste at: https://github.com/settings/keys
```

### 4. Python Environment

```bash
# Verify pyenv installation
pyenv --version

# Install latest Python
pyenv install 3.13.0

# Set global Python version
pyenv global 3.13.0

# Verify
python --version
which python
# Should show pyenv shim
```

### 5. Node.js Environment

```bash
# Install nvm if not already installed
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Restart shell
exec $SHELL

# Install latest LTS
nvm install --lts

# Use it
nvm use --lts

# Verify
node --version
npm --version
```

### 6. Docker Setup

```bash
# Install Docker Desktop (if not using homebrew)
# Or install via Homebrew
brew install --cask docker

# Start Docker Desktop
open -a Docker

# Verify installation
docker --version
docker compose version
docker run hello-world
```

### 7. Tailscale Network

```bash
# Start Tailscale
brew services start tailscale

# Or use app
open -a Tailscale

# Connect to your network
tailscale login

# Verify connection
tailscale status
tailscale ip
```

### 8. 1Password Integration

```bash
# Verify 1Password CLI
op --version

# Sign in
eval $(op signin)

# Test secret injection
echo "OP_TOKEN=op://vault/item/field" > test.env
op inject -i test.env
rm test.env
```

### 9. VS Code / Cursor Extensions

```bash
# Export extensions list (if not already in repo)
code --list-extensions > applications/vscode-extensions.txt

# Install extensions
cat applications/vscode-extensions.txt | xargs -L 1 code --install-extension

# Or use Makefile
make vscode-extensions-install
```

---

## Verification & Testing

### 1. Run Health Checks

```bash
cd ~/dev/projects/dotfiles

# Comprehensive health check
./scripts/health/check-all.sh

# Or via Makefile
make health
```

**What it checks:**
- ✅ Stow packages installed correctly
- ✅ Symlinks are valid
- ✅ Shell configuration loads
- ✅ Git configuration
- ✅ SSH configuration
- ✅ Development tools (python, node, etc.)
- ✅ Homebrew packages

### 2. Verify Symlinks

```bash
# Check home directory symlinks
ls -la ~/ | grep " -> "

# Should show symlinks like:
# .zshrc -> dev/projects/dotfiles/stow-packages/shell/.zshrc
# .gitconfig -> dev/projects/dotfiles/stow-packages/git/.gitconfig
# .ssh/config -> dev/projects/dotfiles/stow-packages/ssh/.ssh/config
```

### 3. Test Shell Functions

```bash
# Test custom aliases
ll        # List files with details
la        # List all files including hidden
..        # Go up one directory

# Test custom functions (if defined)
mkcd test_dir     # Create and enter directory
rm -rf test_dir
```

### 4. Test Development Tools

```bash
# Python
python --version
pip --version

# Node.js
node --version
npm --version

# Git
git --version
gh --version

# Docker
docker --version
docker compose version

# Database
psql --version
```

### 5. Test Auto-Update Service

```bash
# Check if service is running
launchctl list | grep dotfiles

# View logs
tail -f /tmp/dotfiles-autoupdate.log

# Manually trigger update
./scripts/sync/auto-update-dotfiles.sh
```

### 6. Test Asset Management (if using)

```bash
# Test Rclone connection
test-rclone

# Sync library
cdnsync

# Test project sync
cd ~/dev/projects/YOUR_PROJECT
sync-project pull
```

---

## Troubleshooting

### Homebrew Issues

**Problem:** `brew` command not found

```bash
# Intel Mac
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"

# Apple Silicon (M1/M2/M3)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Problem:** Permission denied errors

```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) /opt/homebrew
```

**Problem:** Slow Homebrew installations

```bash
# Use bottles (pre-compiled binaries) when possible
export HOMEBREW_NO_AUTO_UPDATE=1
brew update
```

### Stow Issues

**Problem:** Stow conflicts with existing files

```bash
# Backup conflicting files
mkdir -p ~/dotfiles-backup
mv ~/.zshrc ~/dotfiles-backup/

# Re-run stow
./scripts/stow/stow-all.sh
```

**Problem:** Broken symlinks

```bash
# Check for broken symlinks
find ~/ -maxdepth 1 -type l -exec test ! -e {} \; -print

# Remove broken symlinks
find ~/ -maxdepth 1 -type l -exec test ! -e {} \; -delete

# Re-stow all packages
./scripts/stow/stow-all.sh restow
```

### Shell Issues

**Problem:** Shell configuration not loading

```bash
# Check if .zshrc exists and is a symlink
ls -la ~/.zshrc

# Source manually
source ~/.zshrc

# Check for errors
zsh -x ~/.zshrc
```

**Problem:** Powerlevel10k theme not showing

```bash
# Install recommended fonts
brew install --cask font-meslo-lg-nerd-font

# Configure iTerm2/Terminal to use MesloLGS NF font

# Re-run p10k configuration
p10k configure
```

### Git Issues

**Problem:** GPG signing fails

```bash
# Check GPG key
gpg --list-keys

# Export key ID
export GPG_TTY=$(tty)

# Test signing
echo "test" | gpg --clearsign

# If using 1Password, ensure integration is configured
```

**Problem:** SSH authentication fails

```bash
# Check SSH agent
ssh-add -l

# Add key to agent
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Test GitHub connection
ssh -T git@github.com
```

### Python/Node Issues

**Problem:** `pyenv` or `nvm` command not found

```bash
# Restart shell to load PATH
exec $SHELL

# Verify installation
ls -la ~/.pyenv
ls -la ~/.nvm

# Manually add to PATH if needed (should be in shell config)
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
```

**Problem:** Python/Node version not switching

```bash
# Python - verify shims
pyenv rehash
which python

# Node - verify nvm
nvm current
nvm use --lts
```

### Application Issues

**Problem:** Applications crash on first launch

```bash
# Remove quarantine attribute
xattr -r -d com.apple.quarantine /Applications/AppName.app

# Or disable globally (not recommended for security)
sudo spctl --master-disable
```

**Problem:** Can't install from unidentified developer

```bash
# Right-click app → Open (instead of double-clicking)
# Or allow in System Settings → Privacy & Security
```

### Performance Issues

**Problem:** Slow Terminal/Shell startup

```bash
# Time shell startup
time zsh -i -c exit

# Disable plugins one by one to identify culprit
# Edit ~/.zshrc and comment out plugins

# Optimize Oh My Zsh (disable unused plugins)
```

**Problem:** High CPU usage after installation

```bash
# Check what's running
top -o cpu

# Common culprits:
# - Spotlight indexing (mds, mds_stores) - wait for it to finish
# - Time Machine backup - let it complete
# - Software updates - check for updates
```

### Recovery Commands

**Emergency: Revert all dotfiles**

```bash
cd ~/dev/projects/dotfiles

# Unstow all packages
./scripts/stow/unstow-all.sh

# Restore backups (if you created them)
cp -R ~/dotfiles-backup/. ~/

# Or restore Oh My Zsh defaults
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
```

**Emergency: Reset Homebrew**

```bash
# Uninstall Homebrew (⚠️ removes all packages)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

# Re-install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## Post-Setup Checklist

After completing all steps, verify:

- [ ] Shell loads correctly with custom prompt
- [ ] Git commands work and commits are signed
- [ ] SSH connections to GitHub work
- [ ] Python and Node.js environments are set up
- [ ] Docker is running
- [ ] Tailscale is connected
- [ ] 1Password CLI works
- [ ] All essential applications are installed
- [ ] Custom aliases and functions work
- [ ] Auto-update service is running
- [ ] Health checks pass
- [ ] No broken symlinks in home directory

---

## Additional Resources

- **Main README**: [../../README.md](../../README.md)
- **Linux Setup Guide**: [linux-setup-guide.md](linux-setup-guide.md)
- **Parallels VM Setup**: [parallels-1-vm-creation.md](parallels-1-vm-creation.md)
- **Development Environment**: [parallels-2-dev-setup.md](parallels-2-dev-setup.md)
- **Tech Stack**: [../TECH-STACK.md](../TECH-STACK.md)
- **Architecture Decisions**: [../ARCHITECTURE-DECISIONS.md](../ARCHITECTURE-DECISIONS.md)
- **Task Tracking**: [../TASK.md](../TASK.md)

---

## Customization Tips

### Selective Package Installation

**Available Stow Packages:**
```bash
# List all packages
ls -1 ~/dev/projects/dotfiles/stow-packages/

# Common packages:
# - shell      → ZSH configuration, aliases, functions
# - git        → Git config, aliases, templates
# - ssh        → SSH configuration for Tailscale
# - cursor     → Cursor/VS Code settings
# - claude     → Claude Code configurations
# - dev-env    → XDG compliance, development tool configs
# - iterm2     → iTerm2 backup/restore scripts
# - bin        → Custom executable scripts
```

**Install Only What You Need:**
```bash
# Minimal setup (shell + git only)
./scripts/stow/stow-package.sh install shell
./scripts/stow/stow-package.sh install git

# Add more as needed
./scripts/stow/stow-package.sh install ssh
./scripts/stow/stow-package.sh install cursor
```

### Brewfile Customization

**Create Custom Brewfile:**
```bash
# Start with minimal Brewfile
cp system/macos/Brewfile system/macos/Brewfile.full
vim system/macos/Brewfile

# Keep only essentials, remove:
# - Heavy IDEs you don't use
# - Language runtimes you don't need
# - Media tools if you don't do video/audio work
# - Development databases if not developing
```

**Category-Based Installation:**
```bash
# Install only development tools
grep -E "^brew|^cask" system/macos/Brewfile | \
  grep -E "git|node|python|docker" > /tmp/dev-only.brewfile
brew bundle install --file=/tmp/dev-only.brewfile
```

### Machine-Specific Configurations

**Different Setup for Different Machines:**

Create machine-specific branches or audit files:
```bash
# Save MacBook-specific audit
./scripts/apps/audit-apps.sh
mv applications/current_macos_apps_*.txt \
   applications/macbook-pro-apps.txt

# On Mac Studio, save different audit
./scripts/apps/audit-apps.sh
mv applications/current_macos_apps_*.txt \
   applications/mac-studio-apps.txt

# Compare anytime
./scripts/apps/compare-apps.sh \
  applications/macbook-pro-apps.txt \
  applications/mac-studio-apps.txt
```

### Skip Optional Components

**Skip Auto-Update Service:**
```bash
# Don't install auto-update (manual control)
# Just skip the install step in bootstrap or:
launchctl unload ~/Library/LaunchAgents/com.dotfiles.autoupdate.plist
rm ~/Library/LaunchAgents/com.dotfiles.autoupdate.plist
```

**Skip Asset Management:**
```bash
# Don't install Rclone
brew uninstall rclone

# Or just don't configure it
# (skip ./scripts/sync/setup-rclone.sh)
```

**Skip Oh My Zsh:**
```bash
# Use default ZSH or Bash
# Just stow shell package without installing Oh My Zsh
# Edit stow-packages/shell/.zshrc to remove Oh My Zsh references
```

---

## Quick Reference

**Essential Commands:**

```bash
# Dotfiles management
cd ~/dev/projects/dotfiles
git pull                            # Update dotfiles
./scripts/stow/stow-all.sh         # Install all packages
make health                         # Run health checks

# Application management
brew bundle install                 # Install from Brewfile
brew bundle check                   # Check installed apps
brew update && brew upgrade         # Update all packages
./scripts/apps/audit-apps.sh        # Audit installed apps
./scripts/apps/compare-apps.sh --brewfile  # Compare system vs Brewfile

# Asset management (if using)
update-cdn                          # Update central library
sync-project pull                   # Sync project assets
cdnsync                            # Sync to R2

# Service management
launchctl list | grep dotfiles     # Check auto-update service
tail -f /tmp/dotfiles-autoupdate.log  # View auto-update logs
```

---

**Last Updated:** 2025-10-26
**Author:** Matteo Cervelli
**Version:** 1.0
