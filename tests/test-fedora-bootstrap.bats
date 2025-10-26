#!/usr/bin/env bats
# Tests for Fedora Bootstrap Script
# Tests fedora-bootstrap.sh functionality

setup() {
    # Get project root
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    BOOTSTRAP_SCRIPT="$PROJECT_ROOT/scripts/bootstrap/fedora-bootstrap.sh"
}

# =============================================================================
# Script Existence Tests
# =============================================================================

@test "fedora-bootstrap.sh exists" {
    [ -f "$BOOTSTRAP_SCRIPT" ]
}

@test "fedora-bootstrap.sh is executable" {
    [ -x "$BOOTSTRAP_SCRIPT" ]
}

# =============================================================================
# Help and Options Tests
# =============================================================================

@test "fedora-bootstrap.sh --help shows usage" {
    run "$BOOTSTRAP_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Fedora Bootstrap Script" ]]
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "--with-packages" ]]
}

@test "fedora-bootstrap.sh shows help with invalid option" {
    run "$BOOTSTRAP_SCRIPT" --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

# =============================================================================
# Script Structure Tests
# =============================================================================

@test "fedora-bootstrap.sh uses strict error handling" {
    head -5 "$BOOTSTRAP_SCRIPT" | grep -q "set -euo pipefail"
}

@test "fedora-bootstrap.sh sources logger.sh" {
    grep -q "source.*logger.sh" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh sources detect-os.sh" {
    grep -q "source.*detect-os.sh" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Function Tests
# =============================================================================

@test "fedora-bootstrap.sh has check_os function" {
    grep -q "check_os()" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh has install_essential_tools function" {
    grep -q "install_essential_tools()" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh has install_dotfiles_core function" {
    grep -q "install_dotfiles_core()" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh has deploy_stow_packages function" {
    grep -q "deploy_stow_packages()" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh has check_selinux function" {
    grep -q "check_selinux()" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh has check_firewalld function" {
    grep -q "check_firewalld()" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# DNF Package Manager Tests
# =============================================================================

@test "fedora-bootstrap.sh checks for DNF availability" {
    grep -q "command -v dnf" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh uses dnf upgrade for system update" {
    grep -q "dnf upgrade" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh installs Development Tools group" {
    grep -q 'dnf group install.*"Development Tools"' "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Core Dependencies Tests
# =============================================================================

@test "fedora-bootstrap.sh installs GNU Stow" {
    grep -q "stow" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh installs 1Password CLI" {
    grep -q "1password-cli" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh installs rclone" {
    grep -q "rclone" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh installs yq" {
    grep -q "yq" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh installs ImageMagick" {
    grep -q "ImageMagick" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Architecture Detection Tests
# =============================================================================

@test "fedora-bootstrap.sh detects ARM64 architecture for yq" {
    grep -q "aarch64\|arm64" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh detects x86_64 architecture for yq" {
    grep -q "x86_64\|amd64" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Fedora-Specific Tests
# =============================================================================

@test "fedora-bootstrap.sh checks /etc/fedora-release" {
    grep -q "/etc/fedora-release" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh checks SELinux status" {
    grep -q "getenforce\|selinux" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh checks firewalld status" {
    grep -q "firewalld\|firewall-cmd" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh mentions RPM Fusion" {
    grep -q "rpmfusion\|RPM Fusion" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Stow Package Deployment Tests
# =============================================================================

@test "fedora-bootstrap.sh deploys zsh package" {
    grep -q 'stow.*zsh' "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh deploys git package" {
    grep -q 'stow.*git' "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh deploys ssh package" {
    grep -q 'stow.*ssh' "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh sets ZSH as default shell" {
    grep -q "chsh.*zsh" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Optional Features Tests
# =============================================================================

@test "fedora-bootstrap.sh supports --with-packages flag" {
    grep -q "WITH_PACKAGES" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh calls install-dependencies-fedora.sh when --with-packages" {
    grep -q "install-dependencies-fedora.sh" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh supports --dry-run mode" {
    grep -q "DRY_RUN" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh supports --essential-only mode" {
    grep -q "ESSENTIAL_ONLY" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh supports --skip-repos flag" {
    grep -q "SKIP_REPOS" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Idempotency Tests
# =============================================================================

@test "fedora-bootstrap.sh checks if tools already installed" {
    grep -q "command -v.*&> /dev/null" "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh checks if packages already installed with rpm" {
    grep -q "rpm -q" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Error Handling Tests
# =============================================================================

@test "fedora-bootstrap.sh exits if not Fedora" {
    grep -q 'exit 2' "$BOOTSTRAP_SCRIPT"
}

@test "fedora-bootstrap.sh exits if DNF not found" {
    grep -q 'exit 3' "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Integration Tests (require Fedora system)
# =============================================================================

# These tests are skipped on non-Fedora systems
@test "skip: full bootstrap dry-run" {
    # Only run on Fedora
    if [[ ! -f /etc/fedora-release ]]; then
        skip "Not running on Fedora"
    fi

    run "$BOOTSTRAP_SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY-RUN MODE" ]]
}

@test "skip: essential-only dry-run" {
    # Only run on Fedora
    if [[ ! -f /etc/fedora-release ]]; then
        skip "Not running on Fedora"
    fi

    run "$BOOTSTRAP_SCRIPT" --essential-only --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Skipping system update" ]]
}
