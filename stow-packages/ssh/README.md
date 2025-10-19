# SSH Configuration Package

Complete SSH configuration with modular structure, 1Password integration, Tailscale network support, and cross-platform compatibility.

## 🎯 Features

- **Modular Configuration** - Organized config files in `~/.ssh/config.d/`
- **Cross-Platform** - Works on macOS and Linux
- **1Password Integration** - Secure SSH authentication via 1Password agent
- **Tailscale Network** - Pre-configured access to all your Tailscale devices
- **GitHub Ready** - Optimized GitHub SSH configuration
- **Connection Multiplexing** - Faster SSH with ControlMaster
- **Easy Customization** - Add custom hosts via template

## 📁 Contents

- **`.ssh/config`** - Main SSH configuration with Include directives
- **`.ssh/config.d/01-defaults.conf`** - Global defaults (all platforms)
- **`.ssh/config.d/02-1password-macos.conf`** - 1Password agent for macOS
- **`.ssh/config.d/02-1password-linux.conf`** - 1Password agent for Linux
- **`.ssh/config.d/10-github.conf`** - GitHub SSH configuration
- **`.ssh/config.d/20-tailscale.conf`** - Tailscale network hosts
- **`.ssh/config.d/30-vps.conf`** - VPS servers (production/staging)
- **`.ssh/config.d/40-work.conf.template`** - Template for work/client servers
- **`.ssh/config.d/90-custom.conf.template`** - Template for custom hosts
- **`.ssh/sockets/`** - Directory for ControlMaster sockets

## 🚀 Installation

### Using Stow Helper Scripts (Recommended)

```bash
cd ~/dev/projects/dotfiles
./scripts/stow/stow-package.sh install ssh
```

### Manual Stow

```bash
cd ~/dev/projects/dotfiles/stow-packages
stow --no-folding -v -t ~ ssh
```

### Post-Installation

```bash
# Create sockets directory
mkdir -p ~/.ssh/sockets

# Verify configuration
ssh -G github.com

# Test GitHub connection
ssh -T git@github.com
```

## ✨ Tailscale Network Access

Your complete Tailscale network (siamese-dominant) is pre-configured:

### Your Devices

```bash
# Mac Studio (full name or short alias)
ssh studio4change
ssh studio

# MacBook Pro
ssh macbook4change
ssh macbook

# NAS (Linux)
ssh nas4fortezza
ssh nas
```

### Sara's Devices

```bash
# Sara's MacBook Air
ssh sara-macbook
ssh macbook-air-di-sara
```

### Network-Wide Features

All Tailscale hosts (`*.ts.net`) automatically get:
- ChaCha20 cipher (optimized for Tailscale encryption)
- Increased keepalive intervals
- Auto-accept new host keys

### Replacing Shell Aliases

This SSH configuration **replaces** the old shell aliases:
```bash
# OLD (removed from aliases.sh):
alias macbook="ssh matteocervelli@macbook4change"
alias macstudio="ssh matteocervelli@studio4change"

# NEW (SSH config - works everywhere):
ssh macbook     # Works in shell, scripts, scp, rsync, git, etc.
ssh studio      # More professional and feature-rich
```

**Advantages over aliases**:
- ✅ Works with `scp`, `rsync`, `git`, and all SSH-based tools
- ✅ Supports advanced SSH features (ProxyJump, ForwardAgent, etc.)
- ✅ Works in scripts and non-interactive sessions
- ✅ Standard SSH approach (portable across systems)

### Usage Examples

```bash
# SSH connections
ssh studio
ssh macbook
ssh nas

# File transfers
scp file.txt studio:/path/to/dest/
rsync -av folder/ macbook:~/backup/

# Git operations (if you host git repos on Tailscale devices)
git clone studio:/repos/project.git

# Port forwarding
ssh -L 8080:localhost:80 nas

# Remote commands
ssh studio "docker ps"
ssh macbook "brew update && brew upgrade"
```

## 🔒 1Password SSH Agent

All SSH authentication is handled by 1Password - no need to manage SSH keys manually.

### Setup

1. **Install 1Password** (already done)
2. **Enable SSH agent** in 1Password settings
3. **Configuration** is already set in this package

### Platform-Specific Paths

- **macOS**: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- **Linux**: `~/.1password/agent.sock`

The package automatically uses the correct path based on your OS.

### Verify 1Password Integration

```bash
# Check if 1Password agent is configured
ssh-add -l

# Test with GitHub
ssh -T git@github.com
# Should prompt for 1Password authentication
```

## 🖥️ VPS Servers

Your VPS servers are pre-configured in `30-vps.conf`:

```bash
# Connect to Levero VPS
ssh levero-vps
```

### Adding More VPS Servers

Edit `~/.ssh/config.d/30-vps.conf`:

```ssh
# Add your VPS servers here
Host my-new-vps
    HostName 123.456.789.0
    User myuser
    Port 22
```

**Note**: VPS configuration is tracked in git (safe - only hostnames, no keys).

## 📝 Adding Work/Client Servers

For temporary work or client servers:

### Step 1: Copy Template

```bash
cd ~/.ssh/config.d
cp 40-work.conf.template 40-work.conf
```

### Step 2: Add Your Hosts

Edit `40-work.conf`:

```ssh
# Work server
Host work-server
    HostName internal.company.com
    User mcervelli
    ProxyJump bastion.company.com
```

### Step 3: Test

```bash
ssh work-server
```

## 📝 Adding Custom Hosts

For other custom configurations, use `90-custom.conf.template` as reference.

## 🌍 Cross-Platform Support

This configuration works on:
- **macOS** (primary) - Uses macOS-specific 1Password path
- **Linux** (Ubuntu, Debian, etc.) - Uses Linux 1Password path
- **Both** - Common settings shared across platforms

The SSH `Include` directive automatically loads only existing files, so platform-specific configs work seamlessly.

## 🔧 Configuration Details

### Connection Multiplexing (ControlMaster)

Speeds up multiple connections to the same host:

```bash
# First connection - establishes master
ssh studio

# Subsequent connections - instant (reuse existing connection)
ssh studio  # Much faster!
scp file.txt studio:/tmp/
```

**Benefits**:
- ⚡ Faster reconnections
- 🔒 Single authentication for multiple sessions
- 📊 Reduced overhead

### Security Settings

```ssh
StrictHostKeyChecking ask        # Ask before accepting new keys
VerifyHostKeyDNS yes             # Verify via DNS (SSHFP records)
IdentitiesOnly yes               # Use only configured identities
ServerAliveInterval 60           # Keep connections alive
```

### Performance Optimizations

```ssh
Compression yes                  # Compress data
ControlMaster auto               # Connection multiplexing
ControlPersist 10m               # Keep master connection for 10 min
```

## ✅ Verification

### Check Configuration Loading

```bash
# Test configuration for specific host
ssh -G studio | head -20
ssh -G github.com | head -20

# List all configured hosts
grep "^Host " ~/.ssh/config.d/*.conf

# Test Include directive
ssh -T -v github.com 2>&1 | grep "config.d"
```

### Test Connections

```bash
# Test GitHub
ssh -T git@github.com
# Expected: "Hi [username]! You've successfully authenticated..."

# Test Tailscale host
ssh studio whoami
# Expected: matteocervelli

# Test custom host (after adding to 90-custom.conf)
ssh levero-vps whoami
```

### Verify ControlMaster

```bash
# Connect to a host
ssh studio

# In another terminal, check sockets
ls -la ~/.ssh/sockets/
# Should see active control socket for studio
```

## 🐛 Troubleshooting

### 1Password Not Working

```bash
# Check 1Password CLI
op --version

# Check SSH agent socket exists (macOS)
ls -la ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Check SSH agent socket exists (Linux)
ls -la ~/.1password/agent.sock

# Verify SSH config
ssh -G github.com | grep IdentityAgent
```

### Tailscale Hosts Not Accessible

```bash
# Check Tailscale status
tailscale status

# Verify host is online
ping studio4change.siamese-dominant.ts.net

# Test SSH with verbose mode
ssh -v studio
```

### Include Directive Not Working

```bash
# Check SSH version (needs OpenSSH 7.3+)
ssh -V

# Test config syntax
ssh -G studio | head

# Verify config.d files exist
ls -la ~/.ssh/config.d/
```

### Permission Issues

```bash
# SSH requires strict permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/config.d/*
chmod 700 ~/.ssh/sockets
```

### Symlinks Not Working

```bash
# Verify symlinks
ls -la ~/.ssh/config
ls -la ~/.ssh/config.d/

# Re-stow if needed
cd ~/dev/projects/dotfiles
./scripts/stow/stow-package.sh restow ssh
```

## 🔗 Integration with Other Packages

### Shell Package

- **Removed aliases**: `macbook`, `macstudio` (now in SSH config)
- **Tailscale command**: Still available as alias (macOS)

### Git Package

- Works seamlessly with Git operations
- SSH signing via 1Password (configured in git package)

## 📚 References

- [OpenSSH Configuration](https://www.openssh.com/manual.html)
- [SSH Include Directive](https://man.openbsd.org/ssh_config#Include)
- [1Password SSH Agent](https://developer.1password.com/docs/ssh/)
- [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh/)
- [ControlMaster](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing)

## 📋 File Structure

```text
stow-packages/ssh/
├── README.md                              # This file
├── .gitignore                             # Ignore machine-specific files
└── .ssh/
    ├── config                             # Main config (Include directives)
    ├── config.d/
    │   ├── 01-defaults.conf               # Global defaults (all platforms)
    │   ├── 02-1password-macos.conf        # 1Password agent (macOS)
    │   ├── 02-1password-linux.conf        # 1Password agent (Linux)
    │   ├── 10-github.conf                 # GitHub SSH
    │   ├── 20-tailscale.conf              # Tailscale network hosts
    │   ├── 30-vps.conf                    # VPS servers (production/staging)
    │   ├── 40-work.conf.template          # Work/client servers template
    │   └── 90-custom.conf.template        # Custom hosts template
    └── sockets/                           # ControlMaster sockets (gitignored)
```

## 🔒 Security Notes

- **No private keys** in this repository
- **1Password** handles all authentication securely
- **Host configurations only** (safe to commit - hostnames, not credentials)
- **VPS config tracked** in git (30-vps.conf - safe to share)
- **Work config gitignored** (40-work.conf - temporary/client access)
- **Proper permissions** enforced (600 for configs, 700 for directories)

---

**Version**: 1.0
**Last Updated**: 2025-01-19
**Tailnet**: siamese-dominant
