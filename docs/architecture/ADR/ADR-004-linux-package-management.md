# ADR-004: Linux Package Management & Cross-Platform Mapping

**Status:** Accepted
**Date:** 2025-10-26
**Decision Makers:** Matteo Cervelli
**Related Issues:** [#37](https://github.com/matteocervelli/dotfiles/issues/37) - FASE 4.1

## Context

The dotfiles repository was initially designed for macOS using Homebrew as the package manager. To support multi-platform development environments (Ubuntu VMs, Fedora workstations, Arch Linux systems), we need a systematic approach to map macOS packages to their Linux equivalents across different package managers.

### Requirements

1. **Cross-platform package mapping** from macOS (Homebrew) to Linux (APT/DNF/Pacman)
2. **Automated installation workflows** for each distribution
3. **Package discovery/audit** capabilities
4. **Open-source alternatives** for proprietary macOS software
5. **Security-by-design** with input validation and safe repository setup
6. **Maintainability** - easy to add/update packages
7. **Foundation for FASE 7** multi-platform OS configurations

### Constraints

- Must support 3 primary distributions: Ubuntu 24.04 LTS, Fedora 40+, Arch Linux
- Must handle 271+ packages from existing macOS Brewfile
- Must preserve existing macOS workflow (no breaking changes)
- Must be testable without requiring actual Linux VMs
- Repository setup required for some packages (1Password, Tailscale, etc.)

## Decision

We will implement a **YAML-based package mapping system** with distro-specific installation scripts.

### Architecture Components

1. **Package Mappings** (`applications/linux/package-mappings.yml`)
   - Single source of truth for all package mappings
   - Structured data format (YAML) for easy parsing
   - Supports metadata: category, alternatives, repository setup, notes

2. **Schema Definition** (`applications/linux/mapping-schema.yml`)
   - Explicit contract for package mapping structure
   - Documents all fields and their purposes
   - Provides examples and validation rules

3. **Package List Generator** (`scripts/apps/generate-linux-packages.sh`)
   - Generates distro-specific package lists from YAML
   - Uses `yq` for YAML processing
   - Supports single-distro or all-distro generation

4. **Audit Script** (`scripts/apps/audit-apps-linux.sh`)
   - Multi-distro package manager detection
   - Discovers packages from: APT, DNF, Pacman, Snap, Flatpak, AUR
   - Categorized output similar to macOS audit

5. **Bootstrap Scripts** (per distro)
   - `install-dependencies-ubuntu.sh` - APT + Snap + Flatpak
   - `install-dependencies-fedora.sh` - DNF + Flatpak + COPR
   - `install-dependencies-arch.sh` - Pacman + AUR (yay/paru) + Flatpak

### Key Design Decisions

#### 1. YAML over Hardcoded Mappings

**Decision:** Use YAML file for package mappings

**Rationale:**
- **Maintainability**: Easy to add/update packages without code changes
- **Queryability**: `yq` provides powerful querying capabilities
- **Human-readable**: Non-developers can contribute mappings
- **Structured**: Enforces consistent data format via schema
- **Version control**: Changes are clearly visible in Git diffs

**Alternatives Considered:**
- Bash associative arrays - Not cross-file, harder to maintain
- JSON - Less human-friendly than YAML
- SQLite database - Overkill, adds dependency
- Separate files per package - Too fragmented

#### 2. Package Manager Preference Order

**Decision:** Native > Flatpak > Snap > AUR

**Rationale:**
1. **Native packages** (apt/dnf/pacman)
   - Fastest installation and startup
   - Best system integration
   - Distribution-maintained, well-tested

2. **Flatpak**
   - Sandboxed for security
   - Good for GUI applications
   - Cross-distro compatibility
   - Better than Snap for most GUI apps

3. **Snap**
   - Universal package format
   - Slower startup due to squashFS
   - Pre-installed on Ubuntu
   - Good for proprietary apps (VS Code, etc.)

4. **AUR** (Arch only)
   - Community-maintained
   - Extensive package coverage
   - Requires AUR helper (yay/paru)
   - Less vetted than official repos

#### 3. Open-Source Alternatives Priority

**Decision:** Document open-source alternatives for proprietary software

**Rationale:**
- **Philosophical alignment**: Linux ecosystem favors FOSS
- **Cost**: Many proprietary macOS apps are free on Linux alternatives
- **Examples**:
  - 1Password → Bitwarden
  - Chrome/Edge → Chromium/Firefox
  - Alfred → Rofi
  - Rectangle → i3/Sway

**Implementation:**
```yaml
1password-cli:
  apt: "1password-cli"
  alternatives:
    - "bitwarden-cli"  # Open-source
  opensource: false
```

#### 4. Repository Setup Strategy

**Decision:** Automated repository setup in bootstrap scripts, documented in YAML

**Rationale:**
- **User experience**: One command installs everything
- **Reproducibility**: Same repo setup across machines
- **Documentation**: YAML includes setup commands
- **Safety**: GPG key verification required

**Implementation:**
```yaml
repo_setup:
  ubuntu: "curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg ..."
  fedora: "sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc ..."
```

#### 5. Security Measures

**Decision:** Comprehensive input validation and safe defaults

**Security Features:**
- **Input validation**: Package names must match `[a-zA-Z0-9._@+-]+`
- **No shell injection**: Package names checked for metacharacters
- **GPG verification**: All third-party repos require key verification
- **Dry-run mode**: Preview changes before execution
- **Explicit confirmation**: Dangerous operations require flags

**Validation Example:**
```bash
# Reject dangerous characters
! grep -E '[;&|`$()<>]' packages.txt
```

#### 6. Test Strategy

**Decision:** Comprehensive BATS test suite without external dependencies

**Coverage:**
- File existence (scripts, mappings, package lists)
- Script execution (help, dry-run, error handling)
- Package list content (critical packages present)
- YAML structure (when yq available)
- Security validation (no dangerous characters)
- Directory structure

**Result:** 41 test cases, 100% pass rate on macOS (portable to Linux)

## Consequences

### Positive

✅ **Cross-platform support** for Ubuntu, Fedora, Arch without code duplication
✅ **Easy maintenance** - add packages to YAML, regenerate lists
✅ **Automated installation** - one command per distro
✅ **Security built-in** - input validation, GPG verification
✅ **Well-tested** - 41 test cases covering all components
✅ **Documented** - comprehensive README, ADR, guides
✅ **Foundation for FASE 7** - ready for multi-platform expansion
✅ **Open-source friendly** - prioritizes FOSS alternatives

### Negative

⚠️ **yq dependency** - Required for package list generation (easily installable)
⚠️ **Repository maintenance** - Third-party repos may change URLs/keys
⚠️ **AUR reliability** - Community packages less stable than official
⚠️ **Initial setup time** - Full installation can take 30-60 minutes
⚠️ **Storage overhead** - 92+ packages consume significant disk space

### Neutral

ℹ️ **Not every macOS package has Linux equivalent** - Documented as macOS-only
ℹ️ **Distro-specific quirks** - Some packages require manual intervention
ℹ️ **Rolling vs stable** - Arch always latest, Ubuntu stable versions

## Implementation Status

### Completed (FASE 4.1)

- [x] Package mapping system (271 packages → 92 Ubuntu, 91 Fedora, 77 Arch)
- [x] YAML schema definition
- [x] Package list generator
- [x] Linux audit script (multi-PM support)
- [x] Ubuntu bootstrap script (APT + Snap)
- [x] Fedora bootstrap script (DNF + Flatpak)
- [x] Arch bootstrap script (Pacman + AUR)
- [x] Comprehensive test suite (41 tests)
- [x] Documentation (README, ADR, inline)

### Future Work (FASE 7)

- [ ] Fedora Workstation setup (FASE 7.2 - [#41](https://github.com/matteocervelli/dotfiles/issues/41))
- [ ] Linux Mint Cinnamon setup (FASE 7.3 - [#42](https://github.com/matteocervelli/dotfiles/issues/42))
- [ ] Arch Linux full setup (FASE 7.4 - [#43](https://github.com/matteocervelli/dotfiles/issues/43))
- [ ] GUI dotfiles for Linux desktop environments
- [ ] Ansible playbooks for complex setups
- [ ] Container-based testing (Docker)

## Alternatives Considered

### 1. Nix Package Manager

**Pros:**
- Truly cross-platform (macOS + Linux)
- Declarative configuration
- Reproducible builds
- Version pinning

**Cons:**
- Steep learning curve
- Non-standard for most Linux users
- Large disk usage (multiple versions)
- Slower than native package managers

**Verdict:** Rejected - too opinionated, breaks familiar workflows

### 2. Homebrew on Linux

**Pros:**
- Same tool for macOS and Linux
- Already familiar with Homebrew
- Large package repository

**Cons:**
- Compiles from source (slow)
- Parallel installations (conflicts)
- Not idiomatic for Linux
- Larger disk footprint

**Verdict:** Rejected - native package managers preferred on Linux

### 3. Ansible Playbooks

**Pros:**
- Industry-standard automation
- Idempotent operations
- Supports complex logic

**Cons:**
- Requires Python + Ansible
- Overkill for simple package installation
- YAML complexity for conditionals
- Steeper learning curve

**Verdict:** Deferred to FASE 7 for complex multi-VM setups

### 4. Docker Containers

**Pros:**
- Isolated environments
- Reproducible
- Easy to test

**Cons:**
- Not a replacement for host OS packages
- Overhead for desktop applications
- Limited GUI support

**Verdict:** Complementary - use for testing, not primary solution

## Lessons Learned

1. **YAML is powerful but requires discipline** - Schema enforcement critical
2. **Repository setup is the hardest part** - GPG keys, URLs change
3. **Package naming inconsistencies** - nodejs vs node, vim-enhanced vs vim
4. **Snap/Flatpak fragmentation** - Multiple ways to install same app
5. **Testing without Linux VMs is possible** - BATS + conditional tests work well
6. **Documentation is as important as code** - Comprehensive README crucial

## References

- [Homebrew on macOS](https://brew.sh/)
- [APT User Guide](https://wiki.debian.org/Apt)
- [DNF Documentation](https://dnf.readthedocs.io/)
- [Pacman Guide](https://wiki.archlinux.org/title/Pacman)
- [Snap Documentation](https://snapcraft.io/docs)
- [Flatpak Documentation](https://docs.flatpak.org/)
- [AUR User Guidelines](https://wiki.archlinux.org/title/Arch_User_Repository)
- [yq YAML Processor](https://github.com/mikefarah/yq)

## Approval

**Author:** Matteo Cervelli
**Reviewers:** Self-review (solo project)
**Approved:** 2025-10-26
**Implementation:** FASE 4.1 (Issue #37)
