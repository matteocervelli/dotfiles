# Device Matrix - Complete Environment Mapping

**Project**: Dotfiles Multi-Platform Support
**Created**: 2025-10-26
**Total Environments**: 14+

---

## Complete Device Matrix

| # | Device Name | OS/Distribution | VM Platform | Architecture | Primary Purpose | Resources | Bootstrap Script | Profile | Status |
|---|------------|----------------|-------------|--------------|----------------|-----------|------------------|---------|--------|
| 1 | Mac Studio | macOS Sequoia 15.x | Native | Apple Silicon (M2) | Primary development hub | 32GB RAM, 1TB SSD | `macos-bootstrap.sh` | `mac-studio` | ✅ Active |
| 2 | MacBook | macOS Sequoia 15.x | Native | Apple Silicon (M1/M2) | Portable development | 16-32GB RAM | `macos-bootstrap.sh` | `macbook` | ✅ Active |
| 3 | Parallels Ubuntu | Ubuntu 24.04 LTS | Parallels | ARM64 | Docker workloads, dev testing | 8GB RAM, 50GB | `ubuntu-bootstrap.sh` | `ubuntu-vm` | 🟡 FASE 7 |
| 4 | Parallels Fedora | Fedora Workstation | Parallels | ARM64 | RHEL ecosystem testing | 8GB RAM, 30GB | `fedora-bootstrap.sh` | `fedora-dev` | 🟡 FASE 7 |
| 5 | Parallels Mint | Linux Mint Cinnamon | Parallels | ARM64 | Desktop GUI alternative | 12GB RAM, 100GB | `ubuntu-bootstrap.sh` | `mint-desktop` | 🟡 FASE 7 |
| 6 | Parallels Windows | Windows 11 | Parallels | ARM64 | Cross-platform dev, testing | 12GB RAM, 80GB | `windows-bootstrap.ps1` | `windows-dev` | ⚪ Future |
| 7 | MacBook Fedora (Kids) | Fedora Workstation | Parallels | ARM64 | Kids' educational environment | 4GB RAM, 30GB | `fedora-bootstrap.sh` | `kids-safe` | 🟡 FASE 7 |
| 8 | UTM Arch | Arch Linux | UTM | ARM64 | Bleeding edge, rolling release | 4GB RAM, 20GB | `arch-bootstrap.sh` | `arch-dev` | 🟡 FASE 7 |
| 9 | UTM Omarchy | Omarchy (DHH Linux) | UTM | ARM64 | Opinionated Linux testing | 4GB RAM, 30GB | `omarchy-bootstrap.sh` | `omarchy-dev` | 🟡 FASE 7 |
| 10 | Docker Ubuntu | Ubuntu 22.04/24.04 | Docker | Multi-arch | Containerized apps | Varies | `docker-ubuntu.sh` | `container-minimal` | 🟡 FASE 7 |
| 11 | VPS Ubuntu (Headless) | Ubuntu 24.04 LTS | Cloud (DigitalOcean/Hetzner) | x86_64 (AMD) | Production web server | 2-4GB RAM | `ubuntu-bootstrap.sh` | `vps-minimal` | 🟡 FASE 7 |
| 12 | VPS Ubuntu (GUI) | Ubuntu 24.04 LTS + XFCE | Cloud | x86_64 (AMD) | Visual app hosting | 4-8GB RAM | `ubuntu-bootstrap.sh` | `vps-gui` | ⚪ Optional |
| 13 | Minisforum | Ubuntu 24.04 LTS Server | Native | x86_64 (Intel/AMD) | Self-hosting: Nextcloud, Jellyfin | 16GB RAM, 1TB SSD | `ubuntu-bootstrap.sh` | `selfhosting` | ⚪ Future |
| 14 | Synology NAS | DSM (Linux-based) | Native | x86_64 | Backup, storage, sync | 8GB RAM, Multi-TB | N/A (Appliance) | N/A | ✅ Active |
| 15 | CWWK OpnSense | FreeBSD (OpnSense) | Native | x86_64 | Router, firewall, VPN | 8GB RAM, 128GB SSD | N/A (Appliance) | N/A | ✅ Active |

---

## Status Legend

- ✅ **Active** - Currently in use, dotfiles deployed
- 🟡 **FASE 7** - Planned for FASE 7 implementation
- ⚪ **Future** - Planned for future phases
- ❌ **Deprecated** - No longer supported

---

## Detailed Device Specifications

### 1. Mac Studio (Primary Development Hub)

**Hardware:**
- Apple M2 Max/Ultra chip
- 32-64GB Unified Memory
- 1TB SSD
- 10GbE network (Thunderbolt bridge to NAS)

**Software Stack:**
- macOS Sequoia 15.x
- Homebrew (500+ packages)
- Docker Desktop
- Parallels Desktop (host for VMs)
- Development: Python, Node.js, Swift, Go
- Infrastructure: PostgreSQL, Redis, Nginx, Ollama
- Monitoring: Prometheus, Grafana, Loki

**Role:**
- Central development environment
- Docker infrastructure management
- VM host (Parallels)
- Infrastructure orchestration
- Asset library maintenance (~/media/cdn/)

**Profile:** `mac-studio`
- Roles: `development`, `infrastructure`, `media`, `productivity`
- Full package installation
- All stow packages deployed
- Background services enabled

---

### 2. MacBook (Portable Development)

**Hardware:**
- Apple M1/M2 chip
- 16-32GB Unified Memory
- 512GB-1TB SSD
- Battery-optimized

**Software Stack:**
- macOS Sequoia 15.x
- Homebrew (subset of Mac Studio)
- Lightweight development tools
- Selective Docker usage
- Battery-friendly alternatives

**Role:**
- Portable development
- Code editing on the go
- Remote work scenarios
- Offline-capable workflows
- Kids' VM host (Fedora educational)

**Profile:** `macbook`
- Roles: `development`, `productivity`
- Reduced package set (no heavy background services)
- Power-optimized configurations
- Selective sync (critical assets only)

---

### 3. Parallels Ubuntu 24.04 LTS

**Configuration:**
- **Hypervisor**: Parallels Desktop (on Mac Studio/MacBook)
- **OS**: Ubuntu 24.04 LTS (Noble Numbat)
- **Architecture**: ARM64 (Apple Silicon host)
- **Resources**: 4-8 vCPU, 8GB RAM, 50GB disk

**Software Stack:**
- Docker Engine + Compose v2
- Development tools (git, build-essential)
- Language runtimes (Python, Node.js, Go)
- No GUI (headless server)

**Use Cases:**
- Docker workload testing
- Linux-specific development
- Container orchestration
- Cross-platform compatibility validation

**Profile:** `ubuntu-vm`
- Roles: `development`, `infrastructure`
- Docker-optimized
- Remote Docker context from macOS
- Tailscale networked

**Bootstrap:**
```bash
./scripts/bootstrap/ubuntu-bootstrap.sh
stow -t ~ shell git ssh 1password
```

**Integration:**
- Shared folders: `/Users/matteo/dev → /mnt/dev`
- Remote Docker: `docker context use ubuntu-vm`
- SSH via Tailscale: `ssh ubuntu-vm.tailscale-alias`

---

### 4. Parallels Fedora

**Configuration:**
- **Hypervisor**: Parallels Desktop
- **OS**: Fedora Workstation (latest)
- **Architecture**: ARM64
- **Resources**: 4 vCPU, 8GB RAM, 30GB disk

**Software Stack:**
- DNF package manager
- Development tools (RPM equivalents)
- Docker (via dnf)
- Optional GUI (GNOME)

**Use Cases:**
- RHEL/CentOS ecosystem testing
- Enterprise Linux compatibility
- RPM package development
- Cross-distro validation

**Profile:** `fedora-dev`
- Roles: `development`
- DNF-based package management
- Enterprise Linux patterns

**Bootstrap:**
```bash
./scripts/bootstrap/fedora-bootstrap.sh
stow -t ~ shell git ssh 1password
```

---

### 5. Parallels Linux Mint Cinnamon

**Configuration:**
- **Hypervisor**: Parallels Desktop
- **OS**: Linux Mint (latest, based on Ubuntu LTS)
- **Architecture**: ARM64
- **Resources**: 6 vCPU, 12GB RAM, 100GB disk

**Software Stack:**
- Cinnamon desktop environment
- APT package manager (Ubuntu-based)
- Full GUI applications
- Development tools

**Use Cases:**
- Desktop Linux testing
- GUI application development
- User-friendly Linux alternative
- Visual debugging

**Profile:** `mint-desktop`
- Roles: `development`, `productivity`
- Full desktop environment
- GUI-heavy applications
- Cinnamon-specific configs

---

### 6. Parallels Windows 11

**Configuration:**
- **Hypervisor**: Parallels Desktop
- **OS**: Windows 11 (ARM64 version)
- **Architecture**: ARM64
- **Resources**: 6 vCPU, 12GB RAM, 80GB disk

**Software Stack:**
- winget, Scoop, Chocolatey
- PowerShell 7
- WSL2 (optional Ubuntu)
- Visual Studio, VS Code
- Git for Windows

**Use Cases:**
- Cross-platform testing
- Windows-specific development
- .NET development
- Office suite (native Windows apps)

**Profile:** `windows-dev`
- Separate PowerShell dotfiles
- Cross-platform configs (Git, VS Code)
- WSL2 integration (optional)

**Status:** Future (deferred)

---

### 7. MacBook Fedora (Kids Educational VM)

**Configuration:**
- **Hypervisor**: Parallels Desktop (on MacBook)
- **OS**: Fedora Workstation
- **Architecture**: ARM64
- **Resources**: 2-4 vCPU, 4GB RAM, 30GB disk

**Software Stack:**
- Restricted user account (non-admin)
- Educational software (GCompris, Scratch, etc.)
- Safe browsing (DNS filtering)
- Simplified desktop (GNOME)

**Use Cases:**
- Kids' coding education
- Safe internet environment
- Parental controls
- Learning Linux basics

**Profile:** `kids-safe`
- Restricted package installation
- Educational software only
- Simplified shell configurations
- No admin access for kids

**Parental Features:**
- Time limits (via systemd timers)
- DNS filtering (OpenDNS Family Shield)
- Browser safe search enforcement
- Activity monitoring (optional)

---

### 8. UTM Arch Linux

**Configuration:**
- **Hypervisor**: UTM (free, open-source)
- **OS**: Arch Linux (rolling release)
- **Architecture**: ARM64
- **Resources**: 2-4 vCPU, 4GB RAM, 20GB disk

**Software Stack:**
- Pacman package manager
- AUR support (yay/paru)
- Minimal base installation
- Manual configuration

**Use Cases:**
- Bleeding edge software testing
- Rolling release experience
- AUR package testing
- Advanced Linux learning

**Profile:** `arch-dev`
- Minimal base system
- AUR helper configured
- Arch-specific patterns

**Bootstrap:**
```bash
./scripts/bootstrap/arch-bootstrap.sh
stow -t ~ shell git ssh
```

**Notes:**
- Requires manual Arch installation first
- No guided installer
- Pacman package name mapping needed

---

### 9. UTM Omarchy (DHH's Linux)

**Configuration:**
- **Hypervisor**: UTM
- **OS**: Omarchy (opinionated Ubuntu-based)
- **Architecture**: ARM64 (if available) or x86_64
- **Resources**: 2-4 vCPU, 4GB RAM, 30GB disk

**Software Stack:**
- DHH's curated package selection
- Custom desktop environment
- Modern, beautiful defaults
- Opinionated configurations

**Use Cases:**
- Testing DHH's Linux vision
- Modern Linux desktop experience
- Opinionated defaults evaluation

**Profile:** `omarchy-dev`
- Respect Omarchy defaults
- Minimal overrides
- Learn from DHH's choices

**Research Needed:**
- Base distribution (Ubuntu LTS?)
- Package manager (APT?)
- Desktop environment
- Default applications

**Reference:** https://omarchy.org

---

### 10. Docker Ubuntu (Container Minimal)

**Configuration:**
- **Platform**: Docker Engine
- **Base Image**: Ubuntu 22.04/24.04 (official)
- **Architecture**: Multi-arch (ARM64, x86_64)
- **Size**: < 500MB with dotfiles

**Software Stack:**
- Minimal Ubuntu base
- Shell configurations only
- Git, curl, wget (essentials)
- No GUI, no desktop apps

**Use Cases:**
- Development containers (DevContainers)
- CI/CD build environments
- Production application containers
- Ephemeral testing environments

**Profile:** `container-minimal`
- Roles: None (minimal)
- Essential stow packages only: `shell`, `git`
- No background services
- Fast startup (<2 seconds)

**Dockerfile Strategy:**
```dockerfile
# Base image with dotfiles
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y git stow
COPY stow-packages/ /dotfiles/stow-packages/
RUN cd /dotfiles && stow -t /root shell git

# Development variant
FROM dotfiles-base
RUN apt-get install -y python3 nodejs npm
```

**Volume Mount Strategy:**
```bash
# Development container with live dotfiles
docker run -v ~/dotfiles/stow-packages:/dotfiles/stow-packages myapp
```

---

### 11. VPS Ubuntu Headless (Production Server)

**Configuration:**
- **Provider**: DigitalOcean, Hetzner, or similar
- **OS**: Ubuntu 24.04 LTS Server
- **Architecture**: x86_64 (AMD preferred for cost)
- **Resources**: 2-4 vCPU, 2-4GB RAM, 50-80GB SSD

**Software Stack:**
- Minimal package installation
- Docker Engine (optional)
- Nginx/Caddy (reverse proxy)
- Fail2ban, UFW (security)
- Prometheus node_exporter

**Use Cases:**
- Production web applications
- API servers
- Database hosting
- Static site hosting
- Remote Docker host

**Profile:** `vps-minimal`
- Roles: `security`
- Security-hardened SSH
- Automatic updates enabled
- Minimal attack surface
- Monitoring agent installed

**Security Hardening:**
- SSH key-only authentication
- fail2ban (5 attempts → 10min ban)
- UFW firewall (allow 22, 80, 443, deny all else)
- Automatic security updates (unattended-upgrades)
- Tailscale for admin access (optional)

**Bootstrap:**
```bash
./scripts/bootstrap/ubuntu-bootstrap.sh --profile vps-minimal
```

---

### 12. VPS Ubuntu with GUI (Optional)

**Configuration:**
- **Provider**: Cloud VPS with higher resources
- **OS**: Ubuntu 24.04 LTS + XFCE
- **Architecture**: x86_64
- **Resources**: 4-8 vCPU, 4-8GB RAM, 100GB SSD

**Software Stack:**
- XFCE desktop environment (lightweight)
- X2Go or VNC for remote access
- GUI browsers (Firefox, Chromium)
- Visual development tools

**Use Cases:**
- Browser-based testing
- GUI applications in cloud
- Remote desktop environment
- Visual debugging on cloud

**Profile:** `vps-gui`
- Roles: `development`, `productivity`
- Lightweight desktop (XFCE)
- Remote desktop optimized

**Status:** Optional (deferred)

---

### 13. Minisforum Ubuntu LTS (Self-Hosting Server)

**Configuration:**
- **Hardware**: Minisforum mini PC (or similar)
- **OS**: Ubuntu 24.04 LTS Server
- **Architecture**: x86_64 (Intel/AMD)
- **Resources**: 16GB RAM, 1TB SSD, 24/7 uptime

**Software Stack:**
- Docker + Docker Compose
- Nextcloud (file sync, calendar, contacts)
- Jellyfin or Plex (media server)
- Nginx Proxy Manager
- Certbot (Let's Encrypt SSL)
- Samba/NFS (network shares)
- Restic (backup to NAS)

**Use Cases:**
- Personal cloud (Nextcloud)
- Media streaming (Jellyfin/Plex)
- File sharing (Samba/NFS)
- Home automation (optional)
- Always-on services

**Profile:** `selfhosting`
- Roles: `infrastructure`, `media`
- Docker Compose stacks pre-configured
- Automated backup scripts
- Health monitoring
- Static IP configuration

**Docker Compose Stacks:**
```
~/docker-stacks/
├── nextcloud/
│   └── docker-compose.yml
├── jellyfin/
│   └── docker-compose.yml
├── nginx-proxy/
│   └── docker-compose.yml
└── monitoring/
    └── docker-compose.yml
```

**Backup Strategy:**
- Daily backup to Synology NAS (rsync)
- Weekly backup to R2 (rclone, encrypted)
- Database dumps before backup

**Status:** Future (hardware TBD)

---

### 14. Synology NAS (Backup & Storage)

**Configuration:**
- **Model**: Synology DS series (4-8 bay)
- **OS**: DSM (Synology's Linux-based OS)
- **Capacity**: Multi-TB (RAID configuration)
- **Network**: 1GbE or 10GbE

**Services:**
- File Server (SMB, NFS, AFP)
- Time Machine target (macOS backup)
- Rsync server (Linux backup)
- Rclone remote (R2 sync)
- Synology Drive (file sync)
- Docker (optional containerized apps)

**Use Cases:**
- Central backup target
- Time Machine backups (Mac Studio, MacBook)
- Rsync backups (Linux VMs, VPS)
- Asset library backup (~/media/cdn/)
- Media storage (original quality files)

**Integration:**
- Mac Studio → NAS: Thunderbolt 10GbE
- MacBook → NAS: WiFi or 1GbE
- VMs → NAS: Network shares
- R2 sync: Bidirectional with NAS

**Backup Schedule:**
- Time Machine: Hourly
- Rsync: Daily (Linux systems)
- R2 sync: Weekly (large assets)

**No Dotfiles:** Appliance OS, managed via web UI

---

### 15. CWWK OpnSense (Network & Security)

**Configuration:**
- **Hardware**: CWWK mini PC (fanless, low power)
- **OS**: OpnSense (FreeBSD-based)
- **Network**: 4x 2.5GbE ports
- **RAM**: 8GB

**Services:**
- Router/firewall (main gateway)
- VPN server (Wireguard, OpenVPN)
- DNS (Unbound, ad-blocking)
- DHCP, static IP assignment
- Traffic shaping (QoS)
- IDS/IPS (Suricata)

**Network Segmentation:**
- LAN: Trusted devices (Mac Studio, MacBook, NAS)
- IoT: Smart home devices (isolated)
- Guest: Visitor WiFi (internet only)
- VPN: Remote access (Tailscale, Wireguard)

**No Dotfiles:** Appliance configuration via web UI

**Integration:**
- Tailscale overlay network
- DNS for local services
- Port forwarding for VPS access
- Firewall rules for VMs

---

## Resource Allocation Summary

### CPU Allocation

| Device Type | vCPUs | Notes |
|-------------|-------|-------|
| Mac Studio | 10-12 cores | M2 Max/Ultra |
| MacBook | 8-10 cores | M1/M2 |
| Development VMs | 4-6 | Parallels shared |
| Testing VMs | 2-4 | UTM, lightweight |
| VPS | 2-4 | Cloud-based |
| Self-hosting | 4-8 | Physical server |

### Memory Allocation

| Device Type | RAM | Notes |
|-------------|-----|-------|
| Mac Studio | 32-64GB | Host + VMs |
| MacBook | 16-32GB | Host + 1 VM |
| Development VMs | 8GB | Ubuntu, Fedora |
| Desktop VMs | 12GB | Mint with GUI |
| Testing VMs | 4GB | Arch, Omarchy |
| Kids VM | 4GB | Restricted |
| VPS Minimal | 2-4GB | Headless server |
| VPS GUI | 4-8GB | With desktop |
| Self-hosting | 16GB | Docker heavy |

### Storage Allocation

| Device Type | Storage | Notes |
|-------------|---------|-------|
| Mac Studio | 1TB SSD | Local projects |
| MacBook | 512GB-1TB | Selective sync |
| Development VMs | 50-100GB | Docker images |
| Testing VMs | 20-30GB | Minimal install |
| VPS | 50-80GB | Cloud SSD |
| Self-hosting | 1TB SSD | Media + apps |
| NAS | Multi-TB | RAID, backup |

---

## Network Topology

```
Internet
   │
   └─→ CWWK OpnSense (Router/Firewall)
          │
          ├─→ [LAN: 192.168.1.0/24] ────────────────┐
          │      │                                   │
          │      ├─→ Mac Studio (192.168.1.10)      │
          │      ├─→ MacBook (192.168.1.11)         │
          │      ├─→ Synology NAS (192.168.1.20)    │
          │      └─→ Minisforum (192.168.1.30)      │
          │                                          │
          ├─→ [Tailscale VPN Mesh] ─────────────────┤
          │      (100.x.x.x/32 overlay)             │
          │                                          │
          └─→ [Cloud VPS] ← Tailscale peer          │
                (Public IP)                          │
                                                     │
    Parallels/UTM VMs (bridged to LAN)              │
    - Ubuntu: 192.168.1.100                         │
    - Fedora: 192.168.1.101                         │
    - Mint: 192.168.1.102                           │
    - Arch: 192.168.1.103                           │
    - Omarchy: 192.168.1.104                        │
                                                     │
    Docker Containers (bridge network)               │
    - 172.17.0.0/16                                 │
```

---

## Comparison Table

### macOS vs Linux VMs vs VPS

| Feature | macOS (Mac Studio) | Linux VM (Parallels) | VPS (Cloud) |
|---------|-------------------|---------------------|-------------|
| **Performance** | Native (fastest) | Near-native (95%) | Variable (cloud) |
| **Cost** | Hardware purchase | Included (VM host) | Monthly subscription |
| **Flexibility** | Limited to macOS | Any Linux distro | Any Linux distro |
| **Isolation** | None | Full VM isolation | Full server isolation |
| **Networking** | LAN + Tailscale | Bridged or NAT | Public IP + VPN |
| **Backup** | Time Machine + NAS | Snapshots + NAS | Cloud backups |
| **Use Case** | Primary development | Testing, Docker | Production, public services |

---

## Implementation Priority

### Phase 1: Core Platforms (FASE 1-2, Completed)
- ✅ macOS (Mac Studio, MacBook)
- ✅ Basic shell, git, ssh configurations

### Phase 2: Applications (FASE 3, In Progress)
- 🟡 Application management
- 🟡 Brewfile system
- 🟡 XDG compliance

### Phase 3: Ubuntu Foundation (FASE 7.1)
- 🟡 Ubuntu 24.04 LTS bootstrap
- 🟡 Docker installation
- 🟡 VM testing

### Phase 4: Additional Linux (FASE 7.2-7.4)
- 🟡 Fedora (DNF-based)
- 🟡 Arch (Pacman + AUR)
- 🟡 Omarchy (Research + bootstrap)
- 🟡 Linux Mint (Desktop GUI)

### Phase 5: Specialized (FASE 7.5-7.7)
- 🟡 Docker minimal profile
- 🟡 VPS security hardening
- 🟡 Kids educational VM

### Phase 6: Windows (Future)
- ⚪ Windows 11 PowerShell dotfiles
- ⚪ WSL2 integration
- ⚪ Cross-platform configs

### Phase 7: Self-Hosting (Future)
- ⚪ Minisforum setup
- ⚪ Docker Compose stacks
- ⚪ Nextcloud + Jellyfin

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Maintained By**: Matteo Cervelli
**Project**: [dotfiles](https://github.com/matteocervelli/dotfiles)
