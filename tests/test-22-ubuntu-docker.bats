#!/usr/bin/env bats
# Tests for Issue #22 - Ubuntu 24.04 LTS Bootstrap & Docker Setup
#
# Tests the Docker installation script and integration with Ubuntu bootstrap.
#
# Usage:
#   bats tests/test-22-ubuntu-docker.bats
#
# Note: These are unit tests for scripts, not integration tests.
# Full Docker installation requires actual Ubuntu system.

setup() {
    # Project root directory
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

    # Scripts to test
    DOCKER_SCRIPT="$PROJECT_ROOT/scripts/bootstrap/install-docker.sh"
    UBUNTU_SCRIPT="$PROJECT_ROOT/scripts/bootstrap/install-dependencies-ubuntu.sh"
}

# =============================================================================
# File Existence Tests
# =============================================================================

@test "Docker installation script exists" {
    [ -f "$DOCKER_SCRIPT" ]
}

@test "Docker installation script is executable" {
    [ -x "$DOCKER_SCRIPT" ]
}

@test "Ubuntu dependencies script exists" {
    [ -f "$UBUNTU_SCRIPT" ]
}

@test "Ubuntu dependencies script is executable" {
    [ -x "$UBUNTU_SCRIPT" ]
}

# =============================================================================
# Script Help/Usage Tests
# =============================================================================

@test "Docker script shows help with --help" {
    run "$DOCKER_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Docker Engine + Compose v2 Installation" ]]
    [[ "$output" =~ "USAGE:" ]]
}

@test "Docker script shows help with -h" {
    run "$DOCKER_SCRIPT" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Docker Engine + Compose v2 Installation" ]]
}

@test "Ubuntu script help mentions --with-docker flag" {
    run "$UBUNTU_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--with-docker" ]]
    [[ "$output" =~ "Docker Engine + Compose v2" ]]
}

# =============================================================================
# Script Options Tests
# =============================================================================

@test "Docker script supports --dry-run flag" {
    run "$DOCKER_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--dry-run" ]]
}

@test "Docker script supports --skip-user flag" {
    run "$DOCKER_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--skip-user" ]]
}

@test "Docker script supports --no-start flag" {
    run "$DOCKER_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--no-start" ]]
}

@test "Docker script supports --verbose flag" {
    run "$DOCKER_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--verbose" ]]
}

# =============================================================================
# Error Handling Tests
# =============================================================================

@test "Docker script rejects unknown options" {
    run "$DOCKER_SCRIPT" --invalid-option
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "Ubuntu script rejects unknown options" {
    run "$UBUNTU_SCRIPT" --invalid-option
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown option" ]]
}

# =============================================================================
# Script Content Validation
# =============================================================================

@test "Docker script uses official Docker repository" {
    grep -q "download.docker.com" "$DOCKER_SCRIPT"
}

@test "Docker script verifies GPG key" {
    grep -q "gpg" "$DOCKER_SCRIPT"
}

@test "Docker script installs docker-ce" {
    grep -q "docker-ce" "$DOCKER_SCRIPT"
}

@test "Docker script installs docker-compose-plugin" {
    grep -q "docker-compose-plugin" "$DOCKER_SCRIPT"
}

@test "Docker script configures systemd service" {
    grep -q "systemctl" "$DOCKER_SCRIPT"
}

@test "Docker script adds user to docker group" {
    grep -q "usermod -aG docker" "$DOCKER_SCRIPT"
}

@test "Docker script uses logger.sh for output" {
    grep -q "source.*logger.sh" "$DOCKER_SCRIPT"
}

@test "Docker script has strict error handling" {
    grep -q "set -eo pipefail" "$DOCKER_SCRIPT"
}

# =============================================================================
# Ubuntu Bootstrap Integration Tests
# =============================================================================

@test "Ubuntu script defines WITH_DOCKER variable" {
    grep -q "WITH_DOCKER=" "$UBUNTU_SCRIPT"
}

@test "Ubuntu script handles --with-docker flag" {
    grep -q "\\-\\-with-docker" "$UBUNTU_SCRIPT"
}

@test "Ubuntu script calls install-docker.sh when WITH_DOCKER=1" {
    grep -q "install-docker.sh" "$UBUNTU_SCRIPT"
}

@test "Ubuntu script passes dry-run to Docker script" {
    grep -q "install-docker.sh --dry-run" "$UBUNTU_SCRIPT" || \
    grep -q "DRY_RUN.*install-docker" "$UBUNTU_SCRIPT"
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "Docker setup guide exists" {
    [ -f "$PROJECT_ROOT/docs/guides/docker-ubuntu-setup.md" ]
}

@test "Docker ADR exists" {
    [ -f "$PROJECT_ROOT/docs/architecture/ADR/ADR-005-docker-ubuntu-installation.md" ]
}

@test "Docker setup guide is not empty" {
    [ -s "$PROJECT_ROOT/docs/guides/docker-ubuntu-setup.md" ]
}

@test "Docker ADR is not empty" {
    [ -s "$PROJECT_ROOT/docs/architecture/ADR/ADR-005-docker-ubuntu-installation.md" ]
}

@test "Docker setup guide mentions Parallels" {
    grep -q "Parallels" "$PROJECT_ROOT/docs/guides/docker-ubuntu-setup.md"
}

@test "Docker setup guide mentions remote context" {
    grep -q "remote.*context" "$PROJECT_ROOT/docs/guides/docker-ubuntu-setup.md" || \
    grep -q "Remote Docker" "$PROJECT_ROOT/docs/guides/docker-ubuntu-setup.md"
}

@test "Docker setup guide has troubleshooting section" {
    grep -q "Troubleshooting" "$PROJECT_ROOT/docs/guides/docker-ubuntu-setup.md"
}

# =============================================================================
# Makefile Integration Tests
# =============================================================================

@test "Makefile has docker-install target" {
    grep -q "^docker-install:" "$PROJECT_ROOT/Makefile"
}

@test "Makefile has ubuntu-full target" {
    grep -q "^ubuntu-full:" "$PROJECT_ROOT/Makefile"
}

@test "Makefile docker-install calls install-docker.sh" {
    grep -A 10 "^docker-install:" "$PROJECT_ROOT/Makefile" | grep -q "install-docker.sh"
}

@test "Makefile ubuntu-full uses --with-docker flag" {
    grep -A 10 "^ubuntu-full:" "$PROJECT_ROOT/Makefile" | grep -q "with-docker"
}

# =============================================================================
# Security Tests
# =============================================================================

@test "Docker script does not contain hardcoded passwords" {
    ! grep -iE "password|passwd|secret" "$DOCKER_SCRIPT" || \
    grep -iE "password|passwd" "$DOCKER_SCRIPT" | grep -q "#.*password"
}

@test "Docker script uses HTTPS for repository" {
    grep -q "https://download.docker.com" "$DOCKER_SCRIPT"
}

@test "Docker script checks OS before installation" {
    grep -q "check_os" "$DOCKER_SCRIPT" || \
    grep -q "/etc/os-release" "$DOCKER_SCRIPT"
}

# =============================================================================
# Script Structure Tests
# =============================================================================

@test "Docker script has main function" {
    grep -q "^main()" "$DOCKER_SCRIPT" || grep -q "main \$@" "$DOCKER_SCRIPT"
}

@test "Docker script has proper shebang" {
    head -n 1 "$DOCKER_SCRIPT" | grep -q "#!/usr/bin/env bash"
}

@test "Ubuntu script has proper shebang" {
    head -n 1 "$UBUNTU_SCRIPT" | grep -q "#!/usr/bin/env bash"
}

@test "Docker script sources logger utility" {
    grep -q "source.*logger.sh" "$DOCKER_SCRIPT"
}

# =============================================================================
# Installation Verification Tests
# =============================================================================

@test "Docker script verifies installation" {
    grep -q "verify" "$DOCKER_SCRIPT" || grep -q "docker --version" "$DOCKER_SCRIPT"
}

@test "Docker script tests docker compose command" {
    grep -q "docker compose version" "$DOCKER_SCRIPT"
}

@test "Docker script runs hello-world test" {
    grep -q "hello-world" "$DOCKER_SCRIPT"
}

# =============================================================================
# Line Count Tests (Code Quality)
# =============================================================================

@test "Docker script is under 500 lines" {
    line_count=$(wc -l < "$DOCKER_SCRIPT")
    [ "$line_count" -le 500 ]
}

@test "Docker script has comments explaining key sections" {
    comment_count=$(grep -c "^#" "$DOCKER_SCRIPT")
    [ "$comment_count" -ge 20 ]
}
