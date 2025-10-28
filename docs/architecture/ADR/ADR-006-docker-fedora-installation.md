# ADR-006: Docker Engine Installation for Fedora

**Status**: Accepted
**Date**: 2025-10-28
**Decision Makers**: Matteo Cervelli
**Related Issues**: #57
**Related ADRs**: [ADR-005: Docker Ubuntu Installation](ADR-005-docker-ubuntu-installation.md)

---

## Context

We need to implement Docker Engine + Compose v2 installation for Fedora Linux to achieve development environment parity with Ubuntu. Fedora uses different package management (DNF), security (SELinux), and firewall (firewalld) systems compared to Ubuntu, requiring Fedora-specific implementation.

### Background

- **Ubuntu Implementation Exists**: Proven 422-line installation script for Ubuntu 24.04 LTS
- **Critical Gap**: Fedora lacks Docker support, identified in cross-platform analysis
- **Target Platform**: Fedora 40+ Workstation (ARM64 on Parallels, x86_64)
- **Use Cases**: Development VMs, educational environment base
- **Estimated Effort**: 8-10 hours

### Fedora-Specific Challenges

1. **Package Manager**: DNF vs APT (different commands, repository structure)
2. **Security**: SELinux vs AppArmor (mandatory access control, labels)
3. **Firewall**: firewalld vs ufw (zones, services, rich rules)
4. **Default Container Runtime**: Podman (conflicts with Docker, must be removed)
5. **Repository Structure**: Different GPG key locations, repo file format

---

## Decision

### 1. Docker CE vs Podman

**Decision**: Install Docker CE, remove Podman

**Rationale**:
- **Consistency**: Ubuntu implementation uses Docker CE for development environment parity
- **Industry Standard**: Docker is more widely adopted in professional development
- **Compose v2**: Docker Compose plugin architecture is more mature
- **Remote Context**: Seamless macOS → Fedora VM workflow requires Docker
- **Educational Value**: Teaching Docker aligns with industry practices

**Alternatives Considered**:
- **Keep Podman**: Fedora-native, rootless by default, OCI-compliant
  - ❌ Different CLI commands break cross-platform workflows
  - ❌ Compose compatibility issues with podman-compose
  - ❌ Remote context not as mature
- **Dual Installation**: Run both Docker and Podman
  - ❌ Port conflicts (both bind to same sockets)
  - ❌ Confusion for users
  - ❌ Increased complexity

### 2. SELinux Enforcement

**Decision**: Keep SELinux enforcing, configure properly

**Rationale**:
- **Security-First**: SELinux is a critical security layer
- **Production-Ready**: Mimics production Fedora/RHEL environments
- **Docker Support**: Docker works correctly with SELinux enforcing
- **Troubleshooting**: Teaches developers security-aware practices

**Implementation**:
```bash
# Set container management boolean
sudo setsebool -P container_manage_cgroup on

# Volume mounts require :Z or :z labels
docker run -v /host:/container:Z nginx
```

**Alternatives Considered**:
- **Disable SELinux**: (`setenforce 0`)
  - ❌ Security vulnerability
  - ❌ Doesn't match production
  - ❌ Bad practice, misleads developers
- **Permissive Mode**: (`setenforce 0`)
  - ❌ Still logs denials but doesn't enforce
  - ❌ Hides real issues

### 3. firewalld Configuration

**Decision**: Configure firewalld, never disable

**Rationale**:
- **Network Security**: firewalld protects against unauthorized access
- **Docker Bridge Support**: Masquerade allows container networking
- **Remote Access**: Port 2376 for secure Docker context from macOS
- **Zone-Based**: Flexible rules management

**Implementation**:
```bash
# Enable masquerade for Docker bridge network
sudo firewall-cmd --permanent --zone=public --add-masquerade

# Open remote Docker port (optional)
sudo firewall-cmd --permanent --zone=public --add-port=2376/tcp

# Reload rules
sudo firewall-cmd --reload
```

**Alternatives Considered**:
- **Disable firewalld**: (`systemctl stop firewalld`)
  - ❌ Security risk
  - ❌ Exposes services unnecessarily
- **Trusted Zone**: Move Docker to trusted zone
  - ❌ Bypasses all rules (too permissive)

### 4. Podman Removal Strategy

**Decision**: Automatic removal with user warning

**Rationale**:
- **Conflict Prevention**: Docker and Podman compete for same resources
- **User Awareness**: Warn about data preservation
- **Data Preservation**: Podman containers/images remain in `~/.local/share/containers/`
- **Reversible**: Users can reinstall Podman if needed

**Implementation**:
```bash
# Remove podman and related packages
sudo dnf remove -y podman buildah

# Preserve user data (NOT removed)
# ~/.local/share/containers/ remains intact
```

**Alternatives Considered**:
- **Keep Podman**: Run side-by-side
  - ❌ Socket conflicts
  - ❌ User confusion
- **Force Data Deletion**: Remove `~/.local/share/containers/`
  - ❌ Data loss
  - ❌ User frustration

### 5. GPG Key Verification

**Decision**: Always verify Docker repository GPG key

**Rationale**:
- **Security**: Prevents man-in-the-middle attacks
- **Integrity**: Ensures packages are from Docker, Inc.
- **Best Practice**: Aligns with security standards

**Implementation**:
```bash
# Docker's GPG key location (Fedora)
/etc/pki/rpm-gpg/docker-ce.gpg

# Key automatically verified during dnf install
# User sees fingerprint: 060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35
```

**Alternatives Considered**:
- **Skip Verification**: (`--nogpgcheck`)
  - ❌ Security vulnerability
  - ❌ Supply chain attack risk

### 6. User Group Permissions

**Decision**: Add user to docker group, require logout/login

**Rationale**:
- **Convenience**: Run Docker commands without sudo
- **Development Workflow**: Matches developer expectations
- **Security Trade-off**: Docker group = root-equivalent (acceptable for dev VMs)

**Implementation**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Warn user to logout/login
# Group changes only take effect after re-authentication
```

**Alternatives Considered**:
- **Rootless Docker**: Run Docker as non-root
  - ❌ Complexity increases significantly
  - ❌ Some features don't work (privileged containers)
  - ❌ Not mature on Fedora
- **Always Use sudo**: Never add to docker group
  - ❌ Poor developer experience
  - ❌ Breaks many Docker Compose files

### 7. Remote Docker Context Approach

**Decision**: SSH-based Docker context from macOS

**Rationale**:
- **Security**: Uses existing SSH authentication (1Password)
- **Zero Configuration**: Leverages Tailscale network
- **Native Docker CLI**: No additional tools needed
- **Bidirectional**: Can develop on macOS, build on Fedora

**Implementation**:
```bash
# On macOS
docker context create fedora-vm --docker 'host=ssh://fedora-vm'
docker context use fedora-vm

# All docker commands now execute on Fedora VM
docker ps
docker build -t myapp .
```

**Alternatives Considered**:
- **Docker Machine**: Legacy tool
  - ❌ Deprecated by Docker
  - ❌ Not maintained
- **HTTP API**: Direct TCP connection
  - ❌ No authentication by default
  - ❌ Security risk
- **Docker Desktop**: macOS-native
  - ❌ Doesn't help with Fedora VM development

### 8. Compose v2 Plugin vs Standalone

**Decision**: Use Compose v2 as Docker plugin

**Rationale**:
- **Integration**: Native part of Docker CLI
- **Performance**: Faster than standalone Python version
- **Syntax**: `docker compose` (space) vs `docker-compose` (hyphen)
- **Future-Proof**: Docker officially deprecated standalone version

**Implementation**:
```bash
# Installed as plugin
docker-compose-plugin

# Used via Docker CLI
docker compose up
docker compose down
```

**Alternatives Considered**:
- **Standalone Compose v1**: Python-based
  - ❌ Deprecated
  - ❌ Slower performance
  - ❌ Not maintained

---

## Consequences

### Positive

1. ✅ **Development Parity**: Fedora VMs match Ubuntu capabilities
2. ✅ **Security-First**: SELinux + firewalld remain enforcing
3. ✅ **Remote Development**: macOS → Fedora VM workflow enabled
4. ✅ **Production-Ready**: Configuration mimics production Fedora/RHEL
5. ✅ **Comprehensive Documentation**: Clear guides and troubleshooting
6. ✅ **Automated Installation**: 3-5 minute setup time
7. ✅ **Reversible**: Can uninstall and restore Podman if needed

### Negative

1. ⚠️ **Podman Removal**: Users lose Fedora-native container runtime
   - Mitigation: Preserve user data, document migration
2. ⚠️ **SELinux Complexity**: `:Z`/`:z` labels required for volumes
   - Mitigation: Comprehensive documentation, clear error messages
3. ⚠️ **Security Trade-off**: docker group = root-equivalent access
   - Mitigation: Acceptable for development VMs, document risk
4. ⚠️ **Logout Required**: Group changes need re-authentication
   - Mitigation: Clear warning messages

### Risks

1. **SELinux Policy Changes**: Future Fedora updates may change SELinux policies
   - Mitigation: Regular testing, update documentation
2. **firewalld Conflicts**: Some Docker networks may require additional rules
   - Mitigation: Document common scenarios, provide troubleshooting
3. **Podman Evolution**: Podman may become more Docker-compatible
   - Mitigation: Revisit decision if Podman gains full Docker compatibility

---

## Implementation

### Files Created

1. **Installation Script**: `scripts/bootstrap/install-docker-fedora.sh` (~450 lines)
2. **Setup Guide**: `docs/guides/docker-fedora-setup.md` (~600 lines)
3. **This ADR**: `docs/architecture/ADR/ADR-006-docker-fedora-installation.md`
4. **Test Suite**: `tests/test-57-fedora-docker.bats` (~200 lines)

### Integration Points

1. **Makefile**: Add `docker-install-fedora`, `fedora-full` targets
2. **Bootstrap**: Add `--with-docker` flag to `fedora-bootstrap.sh`
3. **Documentation**: Update CLAUDE.md, README.md, CROSS-PLATFORM-ANALYSIS.md
4. **Health Checks**: Integration with existing health check system

### Testing Strategy

1. **Fedora 40 ARM64**: Primary test platform (Parallels on Mac Studio)
2. **Fedora 41 x86_64**: Secondary platform (if available)
3. **Scenarios**:
   - Fresh install (no Docker/Podman)
   - Podman pre-installed (migration)
   - Old Docker installed (upgrade)
   - SELinux enforcing + firewalld active
   - Remote Docker context from macOS

---

## References

### Official Documentation

- [Docker on Fedora](https://docs.docker.com/engine/install/fedora/)
- [SELinux and Docker](https://docs.docker.com/storage/volumes/#configure-the-selinux-label)
- [firewalld Documentation](https://firewalld.org/documentation/)
- [Fedora Docs: SELinux](https://docs.fedoraproject.org/en-US/quick-docs/getting-started-with-selinux/)

### Related Project Files

- [ADR-005: Docker Ubuntu Installation](ADR-005-docker-ubuntu-installation.md)
- [Ubuntu Docker Script](../../scripts/bootstrap/install-docker.sh)
- [Cross-Platform Analysis](../CROSS-PLATFORM-ANALYSIS.md)
- [Issue #57](https://github.com/matteocervelli/dotfiles/issues/57)

### External Resources

- [Podman vs Docker](https://www.redhat.com/en/topics/containers/what-is-podman)
- [Docker Compose v2](https://docs.docker.com/compose/cli-command/)
- [SELinux for Mere Mortals](https://www.youtube.com/watch?v=MxjenQ31b70)

---

## Approval

**Status**: Accepted
**Approved By**: Matteo Cervelli
**Date**: 2025-10-28

**Implementation**: Issue #57
**Review**: Self-review (solo project)
**Testing**: Fedora 40 ARM64 (Parallels VM)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-28
**Next Review**: After first production use
