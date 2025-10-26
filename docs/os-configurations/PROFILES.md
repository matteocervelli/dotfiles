# Profile-Based Deployment System

**Project**: Dotfiles Multi-Platform Support
**Created**: 2025-10-26
**Status**: FASE 7.9 (Design Phase)
**Implementation**: [Issue #39](https://github.com/matteocervelli/dotfiles/issues/39)

---

## Overview

The profile system provides a **composable, role-based** approach to deploying dotfiles across 14+ different environments. Instead of maintaining separate configuration sets for each device, profiles combine modular **roles** to create device-specific configurations.

## Architecture

### Core Concept

```
Profile = Device Configuration + Roles[] + Package Set + Bootstrap Script
```

**Example:**
```bash
mac-studio = macOS + [development, infrastructure, media] + Full Packages + macos-bootstrap.sh
vps-minimal = Ubuntu + [security] + Minimal Packages + ubuntu-bootstrap.sh --profile vps-minimal
```

---

## Pre-Defined Profiles

### 1. `mac-studio` - Full Development Hub

**Target Device:** Mac Studio
**OS:** macOS Sequoia
**Roles:** `development`, `infrastructure`, `media`, `productivity`

**Package Set:**
- **Development**: Python, Node.js, Go, Swift, Rust, Docker
- **Infrastructure**: PostgreSQL, Redis, Nginx, Ollama, Prometheus, Grafana
- **Media**: FFmpeg, ImageMagick, Handbrake
- **Productivity**: All GUI apps from Brewfile

**Stow Packages:** All (shell, git, ssh, 1password, cursor, iterm2, dev-env, llm-tools)

**Bootstrap:**
```bash
./scripts/bootstrap/install.sh --profile mac-studio
```

---

### 2. `macbook` - Portable Development

**Target Device:** MacBook
**OS:** macOS Sequoia
**Roles:** `development`, `productivity`

**Package Set:**
- **Development**: Core languages only (Python, Node.js, Swift)
- **Productivity**: Essential GUI apps (browsers, editors)
- **Excluded**: Heavy services (PostgreSQL, Redis), Ollama, media tools

**Optimizations:**
- Battery-friendly (no background daemons)
- Reduced package count (~50% of mac-studio)
- Lightweight alternatives where possible

**Bootstrap:**
```bash
./scripts/bootstrap/install.sh --profile macbook
```

---

### 3. `ubuntu-vm` - Headless Docker Development

**Target Device:** Parallels/UTM Ubuntu VM
**OS:** Ubuntu 24.04 LTS
**Roles:** `development`, `infrastructure`

**Package Set:**
- Docker Engine + Compose v2
- Development tools (git, build-essential, curl)
- Language runtimes (Python, Node.js, Go)
- **No GUI apps**

**Stow Packages:** shell, git, ssh, 1password

**Bootstrap:**
```bash
./scripts/bootstrap/ubuntu-bootstrap.sh --profile ubuntu-vm
```

---

### 4. `vps-minimal` - Security-Hardened Server

**Target Device:** Cloud VPS
**OS:** Ubuntu 24.04 LTS Server
**Roles:** `security`

**Package Set:**
- **Security**: fail2ban, ufw, unattended-upgrades
- **Monitoring**: Prometheus node_exporter
- **Essentials**: git, curl, wget
- **Excluded**: Development tools, compilers, Docker (unless needed)

**Hardening:**
- SSH key-only authentication
- UFW firewall (ports 22, 80, 443)
- Automatic security updates
- Minimal attack surface

**Stow Packages:** shell, git, ssh

**Bootstrap:**
```bash
./scripts/bootstrap/ubuntu-bootstrap.sh --profile vps-minimal
```

---

### 5. `selfhosting` - Home Server Stack

**Target Device:** Minisforum mini PC
**OS:** Ubuntu 24.04 LTS Server
**Roles:** `infrastructure`, `media`

**Package Set:**
- Docker + Docker Compose (for all services)
- Nginx Proxy Manager
- Certbot (Let's Encrypt)
- Samba/NFS
- Restic (backup)

**Docker Compose Stacks:**
- Nextcloud (file sync, calendar, contacts)
- Jellyfin (media server)
- Monitoring (Prometheus, Grafana)

**Stow Packages:** shell, git, ssh, 1password

**Bootstrap:**
```bash
./scripts/bootstrap/ubuntu-bootstrap.sh --profile selfhosting
```

---

### 6. `kids-safe` - Educational Environment

**Target Device:** MacBook Fedora VM
**OS:** Fedora Workstation
**Roles:** `education` (custom role)

**Package Set:**
- Educational software (GCompris, Scratch, Tux Paint)
- Safe browsers (Firefox with parental controls)
- Basic dev tools (for learning: Python, Scratch)

**Restrictions:**
- Non-admin user account
- DNS filtering (OpenDNS Family Shield)
- No package installation rights
- Simplified shell (basic aliases only)

**Stow Packages:** shell (simplified)

**Bootstrap:**
```bash
./scripts/bootstrap/fedora-bootstrap.sh --profile kids-safe
```

---

### 7. `container-minimal` - Docker Base Image

**Target Device:** Docker containers
**OS:** Ubuntu 22.04/24.04
**Roles:** None (absolute minimum)

**Package Set:**
- Shell essentials only
- Git (for cloning repos)
- Curl, wget (for downloads)

**Stow Packages:** shell, git (minimal configs)

**Dockerfile:**
```dockerfile
FROM ubuntu:24.04
COPY scripts/bootstrap/docker-ubuntu.sh /tmp/
RUN /tmp/docker-ubuntu.sh && rm /tmp/docker-ubuntu.sh
```

---

### 8. Additional Profiles

| Profile | Device | OS | Roles | Purpose |
|---------|--------|----|----|---------|
| `fedora-dev` | Parallels VM | Fedora | development | RHEL testing |
| `mint-desktop` | Parallels VM | Linux Mint | development, productivity | Desktop Linux |
| `arch-dev` | UTM VM | Arch Linux | development | Bleeding edge |
| `omarchy-dev` | UTM VM | Omarchy | development | DHH's Linux |
| `vps-gui` | Cloud VPS | Ubuntu + XFCE | development, productivity | GUI cloud |

---

## Role Definitions

### `development` Role

**Purpose:** Core development tools and language runtimes

**Packages:**
- **Languages**: Python (pyenv), Node.js (nvm), Go, Rust, Swift (macOS only)
- **Tools**: Git, build-essential, Docker, make, cmake
- **Databases**: PostgreSQL client, Redis client
- **Editors**: vim, nano (CLI), VS Code/Cursor (GUI)

**Configs:**
- `.zshrc` / `.bashrc` with dev aliases
- `.gitconfig` with signing, aliases
- Language-specific configs (.pythonrc, .npmrc)

---

### `infrastructure` Role

**Purpose:** Container orchestration, monitoring, infrastructure tools

**Packages:**
- **Containers**: Docker, docker-compose, kubectl (if k8s)
- **Monitoring**: Prometheus, Grafana, Loki
- **Databases**: PostgreSQL, Redis (server, not just client)
- **Web Servers**: Nginx, Caddy
- **AI**: Ollama (local LLMs)

**Configs:**
- Docker daemon configuration
- Prometheus scrape configs
- Nginx site configs

---

### `media` Role

**Purpose:** Media processing, streaming, transcoding

**Packages:**
- **Processing**: FFmpeg, ImageMagick, Handbrake
- **Streaming**: Jellyfin, Plex (optional)
- **Tools**: yt-dlp, exiftool

**Configs:**
- FFmpeg presets
- Jellyfin Docker Compose stack

---

### `productivity` Role

**Purpose:** GUI applications, office suite, communication

**Packages (macOS):**
- **Browsers**: Chrome, Firefox, Arc
- **Communication**: Slack, Discord, Zoom
- **Office**: Microsoft Office, LibreOffice
- **Utilities**: 1Password, Rectangle, Alfred

**Packages (Linux):**
- **Browsers**: Firefox, Chromium
- **Communication**: Slack (snap), Discord
- **Office**: LibreOffice
- **Utilities**: GNOME extensions

---

### `security` Role

**Purpose:** Security hardening, monitoring, backup

**Packages:**
- **Firewall**: ufw (Linux), macOS firewall (macOS)
- **IDS**: fail2ban, Suricata (optional)
- **Monitoring**: Prometheus node_exporter, auditd
- **Updates**: unattended-upgrades (Linux)
- **Backup**: Restic, Borgbackup

**Hardening:**
- SSH configuration (key-only, no root)
- Firewall rules (whitelist approach)
- Automatic security updates
- Log monitoring

---

### `education` Role (Custom for Kids)

**Purpose:** Educational software, safe browsing, restricted access

**Packages:**
- **Learning**: GCompris, Scratch, Tux Paint, KTurtle
- **Browsers**: Firefox with safe search
- **Basic Dev**: Python IDLE, Scratch Desktop

**Restrictions:**
- DNS filtering (family-safe)
- No sudo access
- Time limits (systemd timers)
- Simplified shell (no advanced features)

---

## Usage Examples

### Install with Pre-Defined Profile

```bash
# Mac Studio (full stack)
./scripts/bootstrap/install.sh --profile mac-studio

# MacBook (portable)
./scripts/bootstrap/install.sh --profile macbook

# Ubuntu VM (Docker dev)
./scripts/bootstrap/ubuntu-bootstrap.sh --profile ubuntu-vm

# VPS (minimal server)
./scripts/bootstrap/ubuntu-bootstrap.sh --profile vps-minimal
```

### Compose Custom Profile from Roles

```bash
# Custom: Development + Media (no infrastructure)
./scripts/bootstrap/install.sh --roles development,media

# Custom: Infrastructure + Security (server focus)
./scripts/bootstrap/install.sh --roles infrastructure,security

# Custom: Development + Productivity (desktop workstation)
./scripts/bootstrap/install.sh --roles development,productivity
```

### Override with Additional Packages

```bash
# Profile + extra packages
./scripts/bootstrap/install.sh --profile macbook --extra postgresql,ollama

# Profile + exclude packages
./scripts/bootstrap/install.sh --profile mac-studio --exclude ollama,docker-desktop
```

---

## Profile Inheritance

Profiles can inherit from base profiles to reduce duplication:

```yaml
# system/profiles/mac-studio.yml
base: macos-base
roles:
  - development
  - infrastructure
  - media
  - productivity
packages:
  extra:
    - ollama
    - docker-desktop
    - parallels

# system/profiles/macbook.yml
base: macos-base
roles:
  - development
  - productivity
packages:
  exclude:
    - postgresql  # Too heavy for laptop
    - ollama
    - docker-desktop
```

---

## Creating Custom Profiles

### Step 1: Define Profile YAML

Create `system/profiles/my-profile.yml`:

```yaml
name: my-profile
description: "Custom profile for XYZ use case"
os: ubuntu
roles:
  - development
  - security
packages:
  extra:
    - custom-tool-1
    - custom-tool-2
  exclude:
    - unnecessary-package
stow_packages:
  - shell
  - git
  - ssh
bootstrap_options:
  - --no-gui
  - --minimal
```

### Step 2: Use Custom Profile

```bash
./scripts/bootstrap/install.sh --profile my-profile
```

---

## Implementation (FASE 7.8)

### Directory Structure

```
system/
├── profiles/
│   ├── mac-studio.yml
│   ├── macbook.yml
│   ├── ubuntu-vm.yml
│   ├── vps-minimal.yml
│   ├── selfhosting.yml
│   ├── kids-safe.yml
│   └── container-minimal.yml
├── roles/
│   ├── development.yml
│   ├── infrastructure.yml
│   ├── media.yml
│   ├── productivity.yml
│   ├── security.yml
│   └── education.yml
└── packages/
    ├── macos/
    │   └── role-*.brewfile
    ├── ubuntu/
    │   └── role-*.txt
    └── fedora/
        └── role-*.txt
```

### Profile Processing

1. **Load Profile** → Parse YAML (yq)
2. **Resolve Roles** → Collect package lists
3. **Merge Packages** → Combine role packages + extras - excludes
4. **Execute Bootstrap** → Call OS-specific bootstrap with package list
5. **Deploy Stow** → Install specified stow packages

---

## Benefits

1. **Maintainability**: Single package definition per role
2. **Flexibility**: Mix and match roles for custom configs
3. **Testability**: Each profile is a known-good configuration
4. **Documentation**: Self-documenting via YAML
5. **Consistency**: Same roles work across platforms
6. **Efficiency**: Only install what's needed

---

**Created**: 2025-10-26
**Last Updated**: 2025-10-26
**Maintained By**: Matteo Cervelli
**Project**: [dotfiles](https://github.com/matteocervelli/dotfiles)
