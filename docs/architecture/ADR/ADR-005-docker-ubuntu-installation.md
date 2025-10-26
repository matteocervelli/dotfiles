# ADR-005: Docker Engine Installation Strategy for Ubuntu

**Status:** Accepted
**Date:** 2025-10-26
**Decision Makers:** Matteo Cervelli
**Related Issues:** [#22](https://github.com/matteocervelli/dotfiles/issues/22) - FASE 4.2

## Context

The dotfiles project needs to support Docker workflows on Ubuntu 24.04 LTS VMs (Parallels) for development and infrastructure projects. The decision involves choosing between Docker installation methods, version management, and integration with the existing dotfiles bootstrap system.

### Requirements

1. **Docker Engine + Compose v2** on Ubuntu 24.04 LTS (Noble Numbat)
2. **Remote Docker context** accessible from macOS via SSH
3. **Automatic service startup** on boot
4. **User permissions** without requiring sudo for every Docker command
5. **Integration** with existing bootstrap scripts and dotfiles workflow
6. **Parallels VM optimization** for shared folders and performance

### Constraints

- Must work on both Apple Silicon (ARM64) and Intel (x86_64) Parallels VMs
- Must not break existing Ubuntu bootstrap script
- Must be idempotent (safe to run multiple times)
- Must follow dotfiles security and testing standards
- Budget: 6-7 hours for complete implementation

## Decision

We will implement a **dedicated Docker installation script** (`install-docker.sh`) using the **official Docker repository** (not Ubuntu's docker.io package), with **optional integration** into the existing Ubuntu bootstrap workflow.

### Architecture Components

1. **Standalone Script**: `scripts/bootstrap/install-docker.sh`
   - Dedicated Docker Engine + Compose v2 installer
   - Can be run independently or via Ubuntu bootstrap
   - ~300 lines with comprehensive error handling

2. **Bootstrap Integration**: `--with-docker` flag in `install-dependencies-ubuntu.sh`
   - Optional Docker installation during full bootstrap
   - Calls `install-docker.sh` when flag present
   - Maintains backward compatibility

3. **Makefile Targets**:
   - `make docker-install` - Docker only
   - `make ubuntu-full` - Ubuntu packages + Docker

4. **Documentation**: Complete setup guide with Parallels configuration

## Key Design Decisions

### 1. Docker Engine vs Docker Desktop

**Decision:** Use Docker Engine (server-only), not Docker Desktop

**Rationale:**
- **Docker Engine** (Chosen):
  - ✅ Lightweight (no GUI overhead)
  - ✅ Native Linux installation
  - ✅ Better for headless VMs
  - ✅ Official repository with latest versions
  - ✅ Compose v2 as plugin (integrated)
  - ✅ Free for all use cases

- **Docker Desktop** (Rejected):
  - ❌ Heavier (includes GUI)
  - ❌ Subscription required for business use
  - ❌ Not ideal for server/VM environments
  - ❌ More complex installation

**For Ubuntu server/VM environments, Docker Engine is the standard choice.**

### 2. Official Repository vs Ubuntu's docker.io

**Decision:** Use official Docker repository (download.docker.com)

**Rationale:**
- **Official Docker Repo** (Chosen):
  - ✅ Latest stable versions (24.0+)
  - ✅ Faster security updates
  - ✅ Docker Compose v2 plugin included
  - ✅ Better ARM64 support
  - ✅ Consistent across distributions

- **Ubuntu's docker.io** (Rejected):
  - ❌ Often outdated (may be several versions behind)
  - ❌ Slower security patches
  - ❌ Compose v1 or missing entirely
  - ❌ Different package names across Ubuntu versions

**Example**: Ubuntu 24.04's docker.io might ship Docker 23.x when official repo has 24.0.7.

### 3. User Permissions Strategy

**Decision:** Add user to `docker` group (not sudo for every command)

**Rationale:**
- **Docker Group** (Chosen):
  - ✅ Standard Docker practice
  - ✅ No sudo needed for docker commands
  - ✅ Better developer experience
  - ✅ Works with remote Docker contexts
  - ⚠️ Requires logout/login to take effect

- **Sudo Every Time** (Rejected):
  - ❌ Tedious for development
  - ❌ Breaks automation scripts
  - ❌ Incompatible with remote contexts
  - ❌ Not standard practice

- **Rootless Docker** (Deferred):
  - 🔶 More secure (runs without root)
  - ❌ Complex setup
  - ❌ Limited feature support
  - ❌ Performance overhead
  - **Verdict**: Too complex for initial implementation

**Note**: Users are warned that docker group grants root-equivalent access. For production VPS, rootless Docker is recommended (future enhancement).

### 4. Docker Compose v2 vs v1

**Decision:** Docker Compose v2 (plugin), not v1 (standalone binary)

**Rationale:**
- **Compose v2 Plugin** (Chosen):
  - ✅ Integrated with Docker CLI
  - ✅ Faster (written in Go, not Python)
  - ✅ Better error messages
  - ✅ Active development
  - ✅ Command: `docker compose` (no hyphen)
  - ✅ Official Docker recommendation

- **Compose v1 Standalone** (Rejected):
  - ❌ Deprecated (EOL 2023)
  - ❌ Slower (Python-based)
  - ❌ Requires separate binary
  - ❌ Command: `docker-compose` (with hyphen)
  - ❌ No longer maintained

**Migration Note**: Legacy `docker-compose` commands need to be updated to `docker compose`.

### 5. Service Management

**Decision:** systemd service, enabled on boot

**Rationale:**
- **systemd** (Chosen):
  - ✅ Standard for Ubuntu
  - ✅ Automatic restart on failure
  - ✅ Service dependencies managed
  - ✅ Logging via journalctl
  - ✅ Enable on boot: `systemctl enable docker`

- **Manual Start** (Rejected):
  - ❌ Requires manual intervention after reboot
  - ❌ Not suitable for production/VM use

**Implementation:**
```bash
sudo systemctl enable docker  # Start on boot
sudo systemctl start docker   # Start now
```

### 6. Remote Docker Context Strategy

**Decision:** SSH-based remote context from macOS

**Rationale:**
- **SSH Context** (Chosen):
  - ✅ Uses existing SSH infrastructure
  - ✅ Secure (encrypted)
  - ✅ Works with Tailscale
  - ✅ No additional ports/firewall rules
  - ✅ Standard Docker feature
  - ✅ Command: `docker context create ubuntu-vm --docker "host=ssh://ubuntu-vm"`

- **TCP Socket** (Rejected):
  - ❌ Insecure (unless TLS configured)
  - ❌ Requires firewall rules
  - ❌ Exposes Docker daemon
  - ❌ Complex TLS certificate management

- **Docker Desktop VM Integration** (Rejected):
  - ❌ Requires Docker Desktop on macOS
  - ❌ Not applicable to Parallels VMs
  - ❌ Less flexible

**Usage:**
```bash
# From macOS
docker context use ubuntu-vm
docker ps
docker compose up -d
```

### 7. Parallels Integration

**Decision:** Use Parallels shared folders for code, Docker on Ubuntu for execution

**Rationale:**
- **Shared Folders** (Chosen):
  - ✅ Edit code on macOS (fast filesystem)
  - ✅ Run Docker on Ubuntu (native Linux kernel)
  - ✅ Best of both worlds
  - ✅ Requires Parallels Tools
  - ✅ Mount point: `/media/psf/Home/dev` → `~/dev-shared`

- **SSH/rsync** (Rejected):
  - ❌ Manual file synchronization
  - ❌ Slower workflow
  - ❌ Risk of version conflicts

- **Docker on macOS** (Rejected for Linux projects):
  - ❌ Requires Docker Desktop (subscription)
  - ❌ Performance overhead (virtualization layer)
  - ❌ Linux-specific features may not work

**Workflow:**
1. Edit code on macOS (VS Code, Cursor, etc.)
2. Files appear instantly in Ubuntu via shared folder
3. Run Docker commands on Ubuntu (native performance)
4. Or use remote Docker context from macOS

## Implementation Details

### Script Structure

```bash
#!/usr/bin/env bash
# install-docker.sh

# 1. Check OS (Ubuntu only)
# 2. Remove old Docker installations (docker.io, docker-engine)
# 3. Setup official Docker repository with GPG key
# 4. Install: docker-ce, docker-ce-cli, containerd.io, docker-compose-plugin
# 5. Enable and start Docker service
# 6. Add user to docker group
# 7. Verify installation (docker version, hello-world)
```

### Security Measures

1. **GPG Key Verification**: Docker's GPG key downloaded and verified
2. **HTTPS Repository**: All packages from download.docker.com (HTTPS)
3. **OS Validation**: Script only runs on Ubuntu (not Debian, Fedora, etc.)
4. **Idempotency**: Safe to run multiple times (checks existing installation)
5. **Dry-Run Mode**: Preview changes before applying (`--dry-run`)
6. **User Warning**: Clear message about logout/login requirement

### Testing Strategy

**BATS Tests** (unit tests):
- Script existence and permissions
- Help/usage output
- Dry-run functionality
- OS detection logic
- Error handling

**Manual Tests** (integration):
- Fresh Ubuntu 24.04 VM installation
- Run install-docker.sh
- Verify Docker version (24.0+)
- Test `docker run hello-world`
- Test `docker compose version`
- Verify service starts on boot
- Test remote context from macOS

## Consequences

### Positive

✅ **Latest Docker** - Always get newest stable version from official repo
✅ **Compose v2** - Modern, faster Compose plugin
✅ **Remote Access** - Work from macOS, run on Ubuntu
✅ **Parallels Optimized** - Shared folders + native Docker performance
✅ **Idempotent** - Safe to run script multiple times
✅ **Well-Tested** - BATS unit tests + manual validation
✅ **Documented** - Complete setup guide with troubleshooting
✅ **Integrated** - Optional flag in Ubuntu bootstrap workflow

### Negative

⚠️ **Logout Required** - Group change needs logout/login to take effect
⚠️ **Root-Equivalent** - Docker group grants root-equivalent access (security consideration)
⚠️ **Ubuntu-Specific** - Script only supports Ubuntu (not Fedora, Arch yet)
⚠️ **Parallels Tools Dependency** - Shared folders require Parallels Tools installed
⚠️ **Disk Space** - Docker images/containers can consume significant disk (10GB+ typical)

### Neutral

ℹ️ **Not Docker Desktop** - No GUI, no k8s, no Docker Extensions (by design)
ℹ️ **Compose Command Change** - `docker compose` (not `docker-compose`) may require script updates
ℹ️ **Remote Context Requires SSH** - Must have SSH access to VM (usually via Tailscale)

## Alternatives Considered

### 1. Snap Package (docker snap)

**Pros:**
- Simple installation: `snap install docker`
- Auto-updates

**Cons:**
- Strict confinement issues
- Performance overhead
- Limited feature support
- Not recommended by Docker

**Verdict:** Rejected - Official repo is better

### 2. Rootless Docker

**Pros:**
- Enhanced security (no root required)
- User isolation

**Cons:**
- Complex setup
- Limited features (no bridge networking, port < 1024)
- Performance overhead
- Not beginner-friendly

**Verdict:** Deferred to future enhancement (FASE 7 VPS security)

### 3. Podman (Docker alternative)

**Pros:**
- Rootless by default
- OCI-compliant
- No daemon

**Cons:**
- Not Docker (compatibility issues)
- Different CLI
- Less documentation
- Compose support limited

**Verdict:** Rejected - Stick with Docker for compatibility

### 4. Docker in Docker (DinD)

**Pros:**
- Isolated Docker environment
- Good for CI/CD

**Cons:**
- Complex setup
- Performance overhead (nested virtualization)
- Storage driver issues

**Verdict:** Rejected - Not needed for development VMs

## Future Enhancements

1. **Fedora/Arch Support** (FASE 7.2-7.4)
   - Similar scripts for other distributions
   - Adapt GPG key and repo URLs

2. **Rootless Docker Option** (FASE 7.7 - VPS)
   - For security-hardened VPS environments
   - `--rootless` flag in install script

3. **Docker Registry** (Future)
   - Self-hosted registry for private images
   - Integration with MinIO (S3-compatible)

4. **Docker Swarm** (Future)
   - Multi-VM Docker orchestration
   - Alternative to Kubernetes for simpler setups

5. **Health Checks** (FASE 6)
   - Verify Docker service status
   - Check for disk space issues
   - Alert if service fails

## Lessons Learned

1. **Official Repos > Distribution Repos** - Always prefer upstream sources for Docker
2. **Compose v2 is Different** - Command syntax changed (no hyphen)
3. **Group Changes Require Logout** - Can't use `newgrp` workaround reliably
4. **Parallels Shared Folders** - Require Parallels Tools for reliability
5. **Remote Context is Powerful** - Seamless Docker access from macOS
6. **Dry-Run is Essential** - Users want to preview before installation

## References

- [Docker Official Installation Guide](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Compose v2 Documentation](https://docs.docker.com/compose/cli-command/)
- [Docker Contexts](https://docs.docker.com/engine/context/working-with-contexts/)
- [Parallels Shared Folders](https://kb.parallels.com/4096)
- [Ubuntu Server Guide - Docker](https://ubuntu.com/server/docs/containers-docker)
- [Issue #22 - Ubuntu 24.04 LTS Bootstrap & Docker](https://github.com/matteocervelli/dotfiles/issues/22)

## Approval

**Author:** Matteo Cervelli
**Reviewers:** Self-review (solo project)
**Approved:** 2025-10-26
**Implementation:** FASE 4.2 (Issue #22)
