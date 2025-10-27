# Docker Ubuntu Minimal Profile

**Profile**: `container-minimal`
**Issue**: [#44](https://github.com/matteocervelli/dotfiles/issues/44)
**Status**: FASE 7.6
**Created**: 2025-10-27

---

## Overview

The **Docker Ubuntu Minimal Profile** provides a lightweight, containerized Ubuntu 24.04 environment with essential dotfiles (shell + git) configured via GNU Stow. Designed for development containers, CI/CD pipelines, and minimal runtime environments.

### Key Features

- **Minimal Size**: < 500MB with full dotfiles
- **Fast Startup**: < 2 seconds container initialization
- **Multi-Architecture**: ARM64 (Apple Silicon) + AMD64 (Intel/AMD)
- **Multi-Stage Builds**: Minimal, Dev, and Production variants
- **GNU Stow**: Modular dotfiles management
- **ZSH + Oh My Zsh**: Modern shell environment
- **Non-Root User**: Runs as `developer` (UID 1000)

---

## Quick Start

### Build Minimal Image

```bash
# Basic build (minimal profile)
docker build -f Dockerfile.dotfiles-ubuntu -t dotfiles-ubuntu:minimal .

# Multi-architecture build
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 \
  -f Dockerfile.dotfiles-ubuntu -t dotfiles-ubuntu:minimal .
```

### Run Container

```bash
# Interactive shell
docker run -it --rm dotfiles-ubuntu:minimal

# With workspace mount
docker run -it --rm -v $(pwd):/workspace dotfiles-ubuntu:minimal

# Run single command
docker run --rm dotfiles-ubuntu:minimal git --version
```

---

## Image Variants

### 1. Minimal (Default)

**Target**: `minimal` (default)
**Size**: ~200-300 MB
**Profile**: `container-minimal`

**Includes**:
- Ubuntu 24.04 base
- ZSH + Oh My Zsh
- Git
- GNU Stow
- Vim, Nano
- Dotfiles: shell + git configurations

**Build**:
```bash
docker build -f Dockerfile.dotfiles-ubuntu -t dotfiles-ubuntu:minimal .
# or explicitly:
docker build -f Dockerfile.dotfiles-ubuntu --target minimal -t dotfiles-ubuntu:minimal .
```

**Use Cases**:
- Lightweight development containers
- CI/CD runner base image
- Script execution environments
- Git operations in containers

---

### 2. Development

**Target**: `dev`
**Size**: ~400-500 MB
**Profile**: `container-dev`

**Includes** (Minimal +):
- Python 3 + pip + pipx + pyenv
- Node.js + npm + nvm
- Build tools (gcc, g++, make, cmake)
- Database clients (postgresql-client, sqlite3)
- Modern CLI tools (ripgrep, fd, bat, fzf, jq, htop)
- tmux

**Build**:
```bash
docker build -f Dockerfile.dotfiles-ubuntu --target dev -t dotfiles-ubuntu:dev .
```

**Use Cases**:
- Full development environment
- Multi-language projects
- Docker-in-Docker development
- Backend service development

---

### 3. Production

**Target**: `production`
**Size**: ~200-300 MB (same as minimal)
**Profile**: `container-production`

**Optimizations**:
- Identical to minimal (for now)
- Future: Read-only root filesystem
- Future: Capability dropping
- Future: Package manager removal

**Build**:
```bash
docker build -f Dockerfile.dotfiles-ubuntu --target production -t dotfiles-ubuntu:production .
```

**Use Cases**:
- Production application base image
- Security-hardened containers
- Immutable infrastructure

---

## Volume Mount Strategy

### Recommended Mount Points

#### 1. Workspace Mount (Recommended)

Mount your current project directory to `/workspace`:

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  dotfiles-ubuntu:minimal
```

**Benefits**:
- Edit code on host (fast filesystem)
- Run commands in container (consistent environment)
- Automatic sync (no rsync needed)
- Works with IDE file watchers

**Permissions**: Container user `developer` (UID 1000) matches most host users

---

#### 2. Persistent Home (Optional)

Persist shell history, configs across container restarts:

```bash
docker run -it --rm \
  -v ~/.docker-home:/home/developer \
  -v $(pwd):/workspace \
  dotfiles-ubuntu:minimal
```

**Benefits**:
- Preserve ZSH history
- Keep installed plugins
- Maintain pyenv/nvm installations
- Cache package managers

**Warning**: May cause conflicts if dotfiles change. Use for stable environments only.

---

#### 3. SSH Keys (For Git Operations)

Mount SSH keys for git push/pull:

```bash
docker run -it --rm \
  -v ~/.ssh:/home/developer/.ssh:ro \
  -v $(pwd):/workspace \
  dotfiles-ubuntu:minimal
```

**Security Notes**:
- Use `:ro` (read-only) mount
- Only mount when needed
- Consider SSH agent forwarding instead:

```bash
docker run -it --rm \
  -v $SSH_AUTH_SOCK:/ssh-agent \
  -e SSH_AUTH_SOCK=/ssh-agent \
  -v $(pwd):/workspace \
  dotfiles-ubuntu:minimal
```

---

#### 4. Git Configuration (Optional)

Override default git config:

```bash
docker run -it --rm \
  -v ~/.gitconfig:/home/developer/.gitconfig:ro \
  -v $(pwd):/workspace \
  dotfiles-ubuntu:minimal
```

**Use Case**: When container's git config doesn't match your identity

---

### Volume Mount Examples

#### Example 1: Simple Development

```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  dotfiles-ubuntu:dev \
  bash -c "npm install && npm test"
```

#### Example 2: Persistent Development Environment

```bash
docker run -it --rm \
  --name dev-container \
  -v ~/projects:/workspace \
  -v ~/.docker-home:/home/developer \
  -v ~/.gitconfig:/home/developer/.gitconfig:ro \
  -v ~/.ssh:/home/developer/.ssh:ro \
  dotfiles-ubuntu:dev
```

#### Example 3: CI/CD Runner

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  dotfiles-ubuntu:minimal \
  sh -c "git clone https://github.com/user/repo && cd repo && make test"
```

---

## Environment Variables

### Pre-configured

- `SHELL=/bin/zsh` - Default shell
- `TZ=UTC` - Timezone
- `DEBIAN_FRONTEND=noninteractive` - No prompts

### Custom Variables

```bash
docker run -it --rm \
  -e GIT_AUTHOR_NAME="Your Name" \
  -e GIT_AUTHOR_EMAIL="you@example.com" \
  -v $(pwd):/workspace \
  dotfiles-ubuntu:minimal
```

---

## Advanced Usage

### Multi-Stage Build Customization

Create a custom Dockerfile extending the minimal image:

```dockerfile
# Custom Dockerfile
FROM dotfiles-ubuntu:minimal AS custom

USER root

# Add custom packages
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER developer

# Add custom configuration
COPY --chown=developer:developer custom-config/ /home/developer/.config/
```

---

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  dev:
    image: dotfiles-ubuntu:dev
    volumes:
      - .:/workspace
      - ~/.docker-home:/home/developer
      - ~/.gitconfig:/home/developer/.gitconfig:ro
    working_dir: /workspace
    tty: true
    stdin_open: true
    environment:
      - TZ=America/New_York
    command: /bin/zsh
```

Run with:
```bash
docker-compose run --rm dev
```

---

### GitHub Actions Integration

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: dotfiles-ubuntu:minimal

    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          git --version
          zsh --version
```

---

## Performance Benchmarks

### Image Size

| Variant | Size | Comparison |
|---------|------|------------|
| Minimal | ~250 MB | Ubuntu 24.04 base: ~77 MB |
| Dev | ~450 MB | Includes Python + Node.js |
| Production | ~250 MB | Same as minimal |

**Target**: < 500 MB ✅

---

### Startup Time

```bash
# Test startup time
time docker run --rm dotfiles-ubuntu:minimal echo "Ready"

# Expected: < 2 seconds
# Typical: 0.3-0.8 seconds (excluding image pull)
```

**Target**: < 2 seconds ✅

---

### Build Time

| Stage | Time (Cached) | Time (Clean) |
|-------|---------------|--------------|
| Base | ~30 seconds | ~2 minutes |
| Minimal | ~30 seconds | ~2 minutes |
| Dev | ~1 minute | ~5 minutes |

*Times vary based on network speed and hardware*

---

## Verification

### Check Image

```bash
# List images
docker images dotfiles-ubuntu

# Inspect image
docker inspect dotfiles-ubuntu:minimal

# Check history
docker history dotfiles-ubuntu:minimal
```

---

### Test Installation

```bash
# 1. ZSH is default
docker run --rm dotfiles-ubuntu:minimal echo $SHELL
# Expected: /bin/zsh

# 2. Git config exists
docker run --rm dotfiles-ubuntu:minimal test -f /home/developer/.config/git/config && echo "OK"

# 3. Dotfiles are stowed
docker run --rm dotfiles-ubuntu:minimal test -L /home/developer/.zshrc && echo "OK"

# 4. Oh My Zsh installed
docker run --rm dotfiles-ubuntu:minimal test -d /home/developer/.oh-my-zsh && echo "OK"
```

---

## Troubleshooting

### Image Too Large

```bash
# Check layer sizes
docker history dotfiles-ubuntu:minimal --human --no-trunc

# Remove build cache
docker builder prune -a

# Rebuild with --no-cache
docker build --no-cache -f Dockerfile.dotfiles-ubuntu -t dotfiles-ubuntu:minimal .
```

---

### Slow Startup

```bash
# Check container overhead
docker run --rm dotfiles-ubuntu:minimal time zsh -c "exit"

# Profile entrypoint script
docker run --rm dotfiles-ubuntu:minimal bash -x /usr/local/bin/entrypoint.sh zsh -c "exit"
```

---

### Permission Issues with Mounts

If files created in container have wrong permissions:

```bash
# Check user ID
docker run --rm dotfiles-ubuntu:minimal id
# Expected: uid=1000(developer)

# Match host user ID if needed (rebuild with custom UID):
docker build --build-arg USER_UID=$(id -u) -f Dockerfile.dotfiles-ubuntu -t dotfiles-ubuntu:minimal .
```

---

## Maintenance

### Update Base Image

```bash
# Pull latest Ubuntu 24.04
docker pull ubuntu:24.04

# Rebuild
docker build -f Dockerfile.dotfiles-ubuntu -t dotfiles-ubuntu:minimal .
```

---

### Update Dotfiles

Changes to stow-packages automatically picked up on rebuild:

```bash
# Edit dotfiles
vim stow-packages/shell/.zshrc

# Rebuild
docker build -f Dockerfile.dotfiles-ubuntu -t dotfiles-ubuntu:minimal .
```

---

## Integration with Dotfiles Project

### Makefile Targets

```bash
# Build Docker images
make docker-build-minimal
make docker-build-dev

# Test Docker images
make docker-test

# Clean Docker resources
make docker-clean
```

---

### Testing

```bash
# Run BATS tests
bats tests/test-23-docker-ubuntu.bats

# Manual verification
./scripts/docker/verify-docker-image.sh
```

---

## Security Considerations

### Non-Root User

Container runs as `developer` (UID 1000) by default:

```bash
docker run --rm dotfiles-ubuntu:minimal whoami
# Output: developer
```

To run as root (not recommended):
```bash
docker run --rm --user root dotfiles-ubuntu:minimal whoami
```

---

### Read-Only Root Filesystem

For production, enable read-only root:

```bash
docker run --rm --read-only \
  --tmpfs /tmp \
  --tmpfs /home/developer/.cache \
  dotfiles-ubuntu:production
```

---

### Capability Dropping

Drop unnecessary capabilities:

```bash
docker run --rm \
  --cap-drop=ALL \
  --cap-add=CHOWN \
  --cap-add=DAC_OVERRIDE \
  dotfiles-ubuntu:minimal
```

---

## Frequently Asked Questions

### Why not Docker Desktop?

This is Docker **Engine** in containers, not Docker Desktop. See [ADR-005](../architecture/ADR/ADR-005-docker-ubuntu-installation.md) for rationale.

---

### Why UID 1000?

UID 1000 is the default for most Linux desktop users, ensuring file permissions match when mounting volumes.

---

### Can I use Podman?

Yes! Replace `docker` with `podman`:

```bash
podman build -f Dockerfile.dotfiles-ubuntu -t dotfiles-ubuntu:minimal .
podman run -it --rm dotfiles-ubuntu:minimal
```

---

### Why Oh My Zsh in containers?

Provides consistent shell experience across development environments. Adds ~5 MB. Can be removed if size-critical.

---

## Related Documentation

- [Profile System](../os-configurations/PROFILES.md)
- [ADR-005: Docker Installation Strategy](../architecture/ADR/ADR-005-docker-ubuntu-installation.md)
- [Ubuntu Setup Guide](../guides/linux-setup-guide.md)
- [Device Matrix](../os-configurations/DEVICE-MATRIX.md)

---

## Support

**Issue Tracker**: [GitHub Issues](https://github.com/matteocervelli/dotfiles/issues)
**Primary Issue**: [#44 - Docker Ubuntu Minimal Profile](https://github.com/matteocervelli/dotfiles/issues/44)

---

## Changelog

### 2025-10-27 - v1.0

- Initial implementation
- Multi-stage Dockerfile (minimal/dev/production)
- Profile configuration (container-minimal)
- Volume mount strategy documented
- Size: ~250 MB (minimal), ~450 MB (dev)
- Startup time: < 1 second
- Multi-arch support (ARM64 + AMD64)

---

**Status**: ✅ Complete
**Size Goal**: < 500 MB ✅
**Startup Goal**: < 2 seconds ✅
**Multi-Arch**: ARM64 + AMD64 ✅
