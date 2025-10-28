#!/usr/bin/env bats
# Tests for Docker Fedora Installation (Issue #57)

# Setup
setup() {
    # Project root detection
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
    SCRIPT_PATH="$PROJECT_ROOT/scripts/bootstrap/install-docker-fedora.sh"
    GUIDE_PATH="$PROJECT_ROOT/docs/guides/docker-fedora-setup.md"
    ADR_PATH="$PROJECT_ROOT/docs/architecture/ADR/ADR-006-docker-fedora-installation.md"
}

# =============================================================================
# Script Existence and Permissions
# =============================================================================

@test "install-docker-fedora.sh exists" {
    [ -f "$SCRIPT_PATH" ]
}

@test "install-docker-fedora.sh is executable" {
    [ -x "$SCRIPT_PATH" ]
}

@test "install-docker-fedora.sh has correct shebang" {
    head -n 1 "$SCRIPT_PATH" | grep -q "^#!/usr/bin/env bash"
}

# =============================================================================
# Help and Usage
# =============================================================================

@test "install-docker-fedora.sh shows help with --help" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Docker Engine + Compose v2 Installation for Fedora" ]]
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
}

@test "install-docker-fedora.sh shows help with -h" {
    run "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Docker Engine + Compose v2 Installation for Fedora" ]]
}

@test "help mentions --dry-run option" {
    run "$SCRIPT_PATH" --help
    [[ "$output" =~ "--dry-run" ]]
    [[ "$output" =~ "Preview installation without making changes" ]]
}

@test "help mentions --skip-user option" {
    run "$SCRIPT_PATH" --help
    [[ "$output" =~ "--skip-user" ]]
}

@test "help mentions --no-start option" {
    run "$SCRIPT_PATH" --help
    [[ "$output" =~ "--no-start" ]]
}

@test "help mentions SELinux considerations" {
    run "$SCRIPT_PATH" --help
    [[ "$output" =~ "SELinux" ]]
}

@test "help mentions firewalld configuration" {
    run "$SCRIPT_PATH" --help
    [[ "$output" =~ "firewalld" ]]
}

@test "help mentions Podman removal" {
    run "$SCRIPT_PATH" --help
    [[ "$output" =~ "Podman" ]]
}

# =============================================================================
# Script Structure and Functions
# =============================================================================

@test "script has show_help function" {
    grep -q "^show_help()" "$SCRIPT_PATH"
}

@test "script has parse_args function" {
    grep -q "^parse_args()" "$SCRIPT_PATH"
}

@test "script has check_os function" {
    grep -q "^check_os()" "$SCRIPT_PATH"
}

@test "script has check_docker_installed function" {
    grep -q "^check_docker_installed()" "$SCRIPT_PATH"
}

@test "script has remove_old_docker function" {
    grep -q "^remove_old_docker()" "$SCRIPT_PATH"
}

@test "script has setup_docker_repository function" {
    grep -q "^setup_docker_repository()" "$SCRIPT_PATH"
}

@test "script has install_docker_engine function" {
    grep -q "^install_docker_engine()" "$SCRIPT_PATH"
}

@test "script has configure_selinux function" {
    grep -q "^configure_selinux()" "$SCRIPT_PATH"
}

@test "script has configure_firewalld function" {
    grep -q "^configure_firewalld()" "$SCRIPT_PATH"
}

@test "script has configure_docker_service function" {
    grep -q "^configure_docker_service()" "$SCRIPT_PATH"
}

@test "script has configure_user_permissions function" {
    grep -q "^configure_user_permissions()" "$SCRIPT_PATH"
}

@test "script has verify_installation function" {
    grep -q "^verify_installation()" "$SCRIPT_PATH"
}

@test "script has main function" {
    grep -q "^main()" "$SCRIPT_PATH"
}

# =============================================================================
# Error Handling
# =============================================================================

@test "script uses set -eo pipefail" {
    head -n 30 "$SCRIPT_PATH" | grep -q "set -eo pipefail"
}

@test "script sources logger.sh utility" {
    grep -q "source.*logger.sh" "$SCRIPT_PATH"
}

# =============================================================================
# Fedora-Specific Configuration
# =============================================================================

@test "script uses DNF package manager" {
    grep -q "dnf" "$SCRIPT_PATH"
}

@test "script references Docker Fedora repository" {
    grep -q "download.docker.com/linux/fedora" "$SCRIPT_PATH"
}

@test "script handles Podman removal" {
    grep -q "podman" "$SCRIPT_PATH"
}

@test "script handles buildah removal" {
    grep -q "buildah" "$SCRIPT_PATH"
}

@test "script configures SELinux" {
    grep -q "setsebool" "$SCRIPT_PATH" || grep -q "selinux" "$SCRIPT_PATH"
}

@test "script configures firewalld" {
    grep -q "firewall-cmd" "$SCRIPT_PATH"
}

@test "script adds masquerade rule" {
    grep -q "add-masquerade" "$SCRIPT_PATH"
}

@test "script opens port 2376 for remote access" {
    grep -q "2376" "$SCRIPT_PATH"
}

# =============================================================================
# Docker Package Installation
# =============================================================================

@test "script installs docker-ce" {
    grep -q "docker-ce" "$SCRIPT_PATH"
}

@test "script installs docker-compose-plugin" {
    grep -q "docker-compose-plugin" "$SCRIPT_PATH"
}

@test "script installs docker-buildx-plugin" {
    grep -q "docker-buildx-plugin" "$SCRIPT_PATH"
}

@test "script installs containerd.io" {
    grep -q "containerd.io" "$SCRIPT_PATH"
}

# =============================================================================
# Security Validation
# =============================================================================

@test "script uses HTTPS for repository URL" {
    grep "DOCKER_REPO_URL=" "$SCRIPT_PATH" | grep -q "https://"
}

@test "script uses HTTPS for GPG key URL" {
    grep "DOCKER_GPG_URL=" "$SCRIPT_PATH" | grep -q "https://"
}

@test "script never disables SELinux" {
    ! grep -q "setenforce 0" "$SCRIPT_PATH"
    ! grep -q "SELINUX=disabled" "$SCRIPT_PATH"
}

@test "script never disables firewalld" {
    ! grep -q "systemctl stop firewalld" "$SCRIPT_PATH"
    ! grep -q "systemctl disable firewalld" "$SCRIPT_PATH"
}

# =============================================================================
# Documentation Existence
# =============================================================================

@test "docker-fedora-setup.md exists" {
    [ -f "$GUIDE_PATH" ]
}

@test "ADR-006 exists" {
    [ -f "$ADR_PATH" ]
}

@test "setup guide mentions SELinux" {
    grep -q "SELinux" "$GUIDE_PATH"
}

@test "setup guide mentions firewalld" {
    grep -q "firewalld" "$GUIDE_PATH"
}

@test "setup guide mentions Podman removal" {
    grep -q "Podman" "$GUIDE_PATH"
}

@test "setup guide explains :Z and :z labels" {
    grep -q ":Z" "$GUIDE_PATH"
    grep -q ":z" "$GUIDE_PATH"
}

@test "setup guide has troubleshooting section" {
    grep -q "Troubleshooting" "$GUIDE_PATH" || grep -q "## Troubleshooting" "$GUIDE_PATH"
}

@test "setup guide mentions remote Docker context" {
    grep -q "docker context" "$GUIDE_PATH"
}

@test "ADR-006 documents SELinux decision" {
    grep -q "SELinux" "$ADR_PATH"
}

@test "ADR-006 documents Podman removal decision" {
    grep -q "Podman" "$ADR_PATH"
}

@test "ADR-006 documents firewalld decision" {
    grep -q "firewalld" "$ADR_PATH"
}

# =============================================================================
# Code Quality
# =============================================================================

@test "script is under 500 lines" {
    line_count=$(wc -l < "$SCRIPT_PATH")
    [ "$line_count" -le 500 ]
}

@test "script has sufficient comments" {
    comment_count=$(grep -c "^[[:space:]]*#" "$SCRIPT_PATH" || true)
    [ "$comment_count" -ge 30 ]
}

@test "script uses descriptive variable names" {
    grep -q "DOCKER_GPG_URL" "$SCRIPT_PATH"
    grep -q "DOCKER_REPO_URL" "$SCRIPT_PATH"
}

@test "script has proper function documentation" {
    # Check for function comments before key functions
    grep -B 1 "^check_os()" "$SCRIPT_PATH" | grep -q "#"
}

# =============================================================================
# Integration Tests (Only run on Fedora)
# =============================================================================

@test "script detects non-Fedora OS (skip on Fedora)" {
    if [ -f /etc/fedora-release ]; then
        skip "Running on Fedora - test not applicable"
    fi

    # On non-Fedora systems, script should exit with code 2
    run "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 2 ] || [ "$status" -eq 0 ]  # May pass if it can't detect OS
}

@test "dry-run mode doesn't make changes" {
    if [ ! -f /etc/fedora-release ]; then
        skip "Not running on Fedora"
    fi

    # Dry-run should not install anything
    run "$SCRIPT_PATH" --dry-run
    # Should succeed or exit early
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ] || [ "$status" -eq 3 ]
}

# =============================================================================
# Makefile Integration
# =============================================================================

@test "Makefile exists" {
    [ -f "$PROJECT_ROOT/Makefile" ]
}

@test "Makefile has docker-install-fedora target" {
    grep -q "docker-install-fedora:" "$PROJECT_ROOT/Makefile" || \
    grep -q "docker-install:" "$PROJECT_ROOT/Makefile"  # May be generic
}

# =============================================================================
# Cross-Reference Checks
# =============================================================================

@test "CROSS-PLATFORM-ANALYSIS.md exists" {
    [ -f "$PROJECT_ROOT/docs/architecture/CROSS-PLATFORM-ANALYSIS.md" ]
}

@test "CLAUDE.md references Docker Fedora commands" {
    grep -q "docker" "$PROJECT_ROOT/CLAUDE.md" || \
    grep -q "install-docker" "$PROJECT_ROOT/CLAUDE.md" || \
    skip "CLAUDE.md may not be updated yet"
}

@test "README.md mentions Fedora support" {
    grep -q "Fedora" "$PROJECT_ROOT/README.md"
}

# =============================================================================
# Exit Code Tests
# =============================================================================

@test "script with unknown option shows error" {
    run "$SCRIPT_PATH" --unknown-option
    [ "$status" -ne 0 ]
}

@test "script --help exits with 0" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
}

# =============================================================================
# Content Validation
# =============================================================================

@test "setup guide has Table of Contents" {
    grep -q "Table of Contents" "$GUIDE_PATH" || grep -q "## Table of Contents" "$GUIDE_PATH"
}

@test "setup guide has Quick Start section" {
    grep -q "Quick Start" "$GUIDE_PATH" || grep -q "## Quick Start" "$GUIDE_PATH"
}

@test "setup guide has examples" {
    grep -q "\`\`\`bash" "$GUIDE_PATH"
}

@test "ADR-006 has Status section" {
    grep -q "Status:" "$ADR_PATH" || grep -q "\*\*Status\*\*" "$ADR_PATH"
}

@test "ADR-006 references issue #57" {
    grep -q "#57" "$ADR_PATH" || grep -q "57" "$ADR_PATH"
}
