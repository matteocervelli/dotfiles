# Multi-Platform OS Configurations - Overview

**Project**: Dotfiles Multi-Platform Support
**Created**: 2025-10-26
**Status**: FASE 7 (Planning)

---

## Philosophy

This dotfiles repository supports **14+ different environments** across macOS, Linux distributions, Windows, Docker containers, and specialized infrastructure devices. The goal is to maintain a **single source of truth** for configurations while adapting to platform-specific requirements.

### Core Principles

1. **Cross-Platform Compatibility**
   - Maximize code reuse across platforms
   - Abstract platform differences where possible
   - Use OS detection for platform-specific adaptations

2. **Profile-Based Deployment**
   - Device profiles (mac-studio, macbook, vps-minimal)
   - Role-based composition (development, infrastructure, media)
   - Composable architecture for flexibility

3. **Modular Bootstrap Strategy**
   - Platform-specific bootstrap scripts
   - Shared utility functions
   - Consistent installation experience

4. **Security by Default**
   - Minimal packages on servers
   - Security hardening for production
   - 1Password integration for secrets

---

## Supported Environments

### 🖥️ **macOS Workstations** (Primary Platform)

**Devices:**
- **Mac Studio** - Primary development hub
- **MacBook** - Portable development

**Characteristics:**
- Full development stack
- GUI applications
- Infrastructure management tools
- Homebrew package manager
- Apple Silicon (M1/M2/M3) and Intel support

**Bootstrap Script:** `scripts/bootstrap/macos-bootstrap.sh`

---

### 🐧 **Linux Distributions** (Secondary Platform)

#### Ubuntu/Debian Family

**Environments:**
- **Parallels Ubuntu 24.04 LTS** - Docker workloads, development VMs
- **Linux Mint Cinnamon** - Desktop alternative with GUI
- **VPS Ubuntu Headless** - Cloud servers (x86/AMD)
- **Minisforum Ubuntu LTS** - Self-hosting (Nextcloud, Jellyfin, NAS)
- **Docker Ubuntu** - Containerized applications

**Package Manager:** APT (apt-get)
**Bootstrap Scripts:**
- `scripts/bootstrap/ubuntu-bootstrap.sh` (general)
- `scripts/bootstrap/docker-ubuntu.sh` (minimal containers)

#### Fedora/RHEL Family

**Environments:**
- **Parallels Fedora** - RHEL ecosystem testing
- **MacBook Fedora VM** - Kids' educational environment

**Package Manager:** DNF
**Bootstrap Script:** `scripts/bootstrap/fedora-bootstrap.sh`

#### Arch-based Distributions

**Environments:**
- **UTM Arch Linux** - Bleeding edge, rolling release
- **UTM Omarchy** - DHH's opinionated Linux (https://omarchy.org)

**Package Manager:** Pacman + AUR (yay/paru)
**Bootstrap Scripts:**
- `scripts/bootstrap/arch-bootstrap.sh`
- `scripts/bootstrap/omarchy-bootstrap.sh`

---

### 🪟 **Windows** (Future Support)

**Environment:**
- **Parallels Windows 11** - Cross-platform development, testing

**Package Managers:** winget, Scoop, Chocolatey
**Strategy:** Separate PowerShell-based dotfiles or WSL2 integration
**Status:** Deferred to future phase

---

### 📦 **Containerized Environments**

**Docker Ubuntu:**
- Minimal dotfiles profile (shell, git only)
- Base images with baked-in configurations
- Volume-mounted dotfiles for development containers
- Multi-stage builds for dev/production

**Use Cases:**
- Development environments (DevContainers)
- CI/CD build containers
- Production application containers

---

### 🏢 **Infrastructure Devices**

**Synology NAS:**
- Backup target (Time Machine, rsync, rclone)
- Central storage for assets (~/media/cdn/ sync)
- No dotfiles deployment (appliance OS)

**CWWK OpnSense:**
- Router/firewall (FreeBSD-based)
- Network segmentation, VPN
- No dotfiles deployment (appliance configuration)

---

## Architecture Integration

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                     Tailscale Mesh VPN                       │
│  (Secure connectivity across all devices)                   │
└─────────────────────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼─────┐        ┌────▼─────┐        ┌────▼─────┐
   │ Mac      │        │ Mac      │        │ VPS      │
   │ Studio   │        │ Book     │        │ Ubuntu   │
   │ (Hub)    │        │ (Mobile) │        │ (Cloud)  │
   └────┬─────┘        └────┬─────┘        └──────────┘
        │                   │
   ┌────▼──────────────────▼────┐
   │  Parallels/UTM VMs         │
   │  - Ubuntu 24.04            │
   │  - Fedora                  │
   │  - Mint, Arch, Omarchy     │
   │  - Windows 11              │
   └────────────────────────────┘
        │
   ┌────▼─────┐        ┌─────────┐
   │ Synology │        │ CWWK    │
   │ NAS      │        │ OpnSense│
   │ (Backup) │        │ (Firewall)
   └──────────┘        └─────────┘
```

### Backup Strategy

**3-2-1 Backup Rule:**
- **3 Copies**: Original + 2 backups
- **2 Media Types**: Local (SSD) + Network (NAS) + Cloud (R2)
- **1 Offsite**: Cloudflare R2

**Implementation:**
1. **Local**: Time Machine (macOS), rsnapshot (Linux)
2. **Network**: Synology NAS (rsync, rclone)
3. **Cloud**: Cloudflare R2 (assets), GitHub (dotfiles)

**Coverage:**
- Dotfiles → GitHub (version controlled)
- Assets → ~/media/cdn/ → R2 (bidirectional sync)
- System → Time Machine → NAS (incremental)
- Databases → Dump scripts → NAS → R2 (encrypted)

---

## Development Workflow

### Primary Development (Mac Studio)

1. **Full Stack Development**
   - All language runtimes (Python, Node, Go, Swift)
   - Databases (PostgreSQL, Redis)
   - Docker + Docker Compose
   - Ollama (local LLMs)

2. **Infrastructure Management**
   - Manage Docker stacks on VMs
   - Configure remote Docker contexts
   - Monitor via Prometheus/Grafana
   - Deploy to VPS

3. **Asset Management**
   - Central library: `~/media/cdn/`
   - Auto-update propagation to projects
   - R2 sync for distribution

### Portable Development (MacBook)

1. **Battery-Optimized**
   - Core development tools only
   - No heavy background services
   - Lightweight alternatives

2. **Sync Workflow**
   - Git for code
   - Rclone for assets (selective sync)
   - 1Password for secrets

### VM Development

1. **Isolation**
   - Test platform-specific code
   - Docker workload testing
   - OS compatibility validation

2. **Resource Sharing**
   - Parallels shared folders
   - Tailscale network access
   - Remote Docker contexts

---

## Profile System

### Device Profiles

**Pre-defined Profiles:**
- `mac-studio` - Full development + infrastructure
- `macbook` - Portable development, battery-conscious
- `ubuntu-vm` - Headless Docker development
- `vps-minimal` - Security-hardened server
- `selfhosting` - Nextcloud, Jellyfin, NAS tools
- `kids-safe` - Educational, restricted access

### Role Composition

**Composable Roles:**
- `development` - Languages, databases, dev tools
- `infrastructure` - Docker, monitoring, orchestration
- `media` - Plex, Jellyfin, FFmpeg
- `productivity` - Office, browsers, communication
- `security` - Hardening, monitoring, backup

**Usage:**
```bash
# Install with pre-defined profile
./scripts/bootstrap/install.sh --profile mac-studio

# Compose custom profile from roles
./scripts/bootstrap/install.sh --roles development,infrastructure,media
```

---

## Package Management Strategy

### Package Manager Matrix

| OS/Distro | Package Manager | Bootstrap Script |
|-----------|----------------|------------------|
| macOS | Homebrew | `macos-bootstrap.sh` |
| Ubuntu/Debian | APT | `ubuntu-bootstrap.sh` |
| Fedora/RHEL | DNF | `fedora-bootstrap.sh` |
| Arch | Pacman + AUR | `arch-bootstrap.sh` |
| Omarchy | (Research needed) | `omarchy-bootstrap.sh` |
| Windows | winget/Scoop | `windows-bootstrap.ps1` |
| Docker | APT (minimal) | `docker-ubuntu.sh` |

### Cross-Platform Package Mapping

**Example: Development Tools**

| Tool | macOS | Ubuntu | Fedora | Arch |
|------|-------|--------|--------|------|
| Git | `brew install git` | `apt install git` | `dnf install git` | `pacman -S git` |
| Node.js | `brew install node` | `apt install nodejs npm` | `dnf install nodejs npm` | `pacman -S nodejs npm` |
| Python | `brew install python` | `apt install python3` | `dnf install python3` | `pacman -S python` |
| Docker | `brew install --cask docker` | `apt install docker.io` | `dnf install docker` | `pacman -S docker` |

---

## Security Considerations

### macOS Workstations
- 1Password for secrets (SSH, GPG, env vars)
- FileVault encryption
- Firewall enabled
- Gatekeeper active

### Linux Servers (VPS, Self-Hosting)
- SSH key-only authentication
- fail2ban for brute-force protection
- UFW firewall configuration
- Automatic security updates
- Minimal package installation
- Regular backup verification

### VMs (Development)
- Isolated network segments
- Snapshot before major changes
- Limited resource allocation
- Controlled network access

### Containers
- Non-root users
- Minimal base images
- Regular image updates
- Secrets via environment variables (1Password)

---

## Testing Strategy

### Validation Levels

1. **Unit Testing**
   - Individual bootstrap scripts
   - Health check scripts
   - Stow package deployment

2. **Integration Testing**
   - Full installation on fresh VMs
   - Cross-platform compatibility
   - Profile composition

3. **Platform Coverage**
   - Primary: macOS (Mac Studio, MacBook)
   - Secondary: Ubuntu 24.04 LTS (VMs, VPS)
   - Tertiary: Fedora, Arch, Omarchy (VMs)
   - Future: Windows 11

### Testing Environments

- **Local VMs**: Parallels Desktop, UTM
- **Cloud VMs**: DigitalOcean, Hetzner (for VPS testing)
- **Containers**: Docker for ephemeral testing
- **Physical**: Mac Studio, MacBook (daily use validation)

---

## Implementation Phases

### FASE 7.1: Ubuntu 24.04 LTS Bootstrap & Docker Setup [Issue #22]
- Primary Linux VM environment
- Docker workloads and development testing
- Test on Parallels Ubuntu VM

### FASE 7.2: Fedora Bootstrap & DNF Package Management [Issue #40]
- RHEL ecosystem testing
- DNF package mapping
- Test on Parallels Fedora VM

### FASE 7.3: Linux Mint Cinnamon Desktop Configuration [Issue #41] ✅
- ✅ Desktop environment configuration
- ✅ GUI application setup
- ✅ Bootstrap scripts created
- ✅ Documentation completed
- 📋 Ready for testing on Parallels Mint VM

### FASE 7.4: Arch Linux Bootstrap & AUR Integration [Issue #42]
- Pacman + AUR integration
- Rolling release environment
- Test on UTM Arch VM

### FASE 7.5: Omarchy Bootstrap & DHH's Opinionated Setup [Issue #43]
- Research Omarchy base system and package manager
- Respect DHH's opinionated defaults
- Test on UTM/Parallels Omarchy VM

### FASE 7.6: Docker Ubuntu Minimal Base Image [Issue #44]
- Minimal profile design
- Multi-stage builds for optimization
- Multi-arch support (ARM64 + x86_64)

### FASE 7.7: VPS Ubuntu Security Hardening & Headless Setup [Issue #45]
- Headless server profile (no GUI)
- Security hardening (fail2ban, UFW, SSH)
- Test on cloud VPS (Hetzner/DigitalOcean)

### FASE 7.8: Kids Fedora Educational & Parental Controls [Issue #46]
- Educational environment setup
- Parental controls and content filtering
- Safe browsing configuration

### FASE 7.9: Profile System Architecture & Bootstrap Integration [Issue #39]
- Composable profile architecture (YAML-based)
- Role-based package composition
- Bootstrap integration with --profile flag

---

## Future Considerations

### Potential Additions
- **NixOS** - Declarative configuration
- **FreeBSD** - Unix alternative
- **Raspberry Pi OS** - ARM IoT devices
- **Chrome OS (Crostini)** - Chromebook support

### Maintenance Strategy
- Quarterly review of supported platforms
- Deprecation policy for unused environments
- Community feedback on platform priorities
- Cost-benefit analysis for maintenance burden

---

## Resources

### Documentation
- [DEVICE-MATRIX.md](DEVICE-MATRIX.md) - Complete device/OS mapping
- [PROFILES.md](PROFILES.md) - Profile system documentation
- [BOOTSTRAP-STRATEGIES.md](BOOTSTRAP-STRATEGIES.md) - OS-specific approaches

### External References
- [Omarchy Official Site](https://omarchy.org)
- [Homebrew](https://brew.sh)
- [GNU Stow](https://www.gnu.org/software/stow/)
- [Webpro Dotfiles](https://dotfiles.github.io)

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Maintained By**: Matteo Cervelli
**Project**: [dotfiles](https://github.com/matteocervelli/dotfiles)
