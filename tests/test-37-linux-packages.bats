#!/usr/bin/env bats
# Tests for Linux Package Management (Issue #37)
#
# Tests cover:
# - File existence
# - Script execution
# - Package list content
# - YAML structure (when yq available)

# Setup
setup() {
    export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export MAPPING_FILE="$PROJECT_ROOT/applications/linux/package-mappings.yml"
    export SCHEMA_FILE="$PROJECT_ROOT/applications/linux/mapping-schema.yml"
}

# ============================================================================
# File Existence Tests
# ============================================================================

@test "package-mappings.yml exists" {
    [ -f "$MAPPING_FILE" ]
}

@test "mapping-schema.yml exists" {
    [ -f "$SCHEMA_FILE" ]
}

@test "audit-apps-linux.sh exists and is executable" {
    [ -x "$PROJECT_ROOT/scripts/apps/audit-apps-linux.sh" ]
}

@test "generate-linux-packages.sh exists and is executable" {
    [ -x "$PROJECT_ROOT/scripts/apps/generate-linux-packages.sh" ]
}

@test "install-dependencies-ubuntu.sh exists and is executable" {
    [ -x "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-ubuntu.sh" ]
}

@test "install-dependencies-fedora.sh exists and is executable" {
    [ -x "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-fedora.sh" ]
}

@test "install-dependencies-arch.sh exists and is executable" {
    [ -x "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-arch.sh" ]
}

# ============================================================================
# Package List Tests
# ============================================================================

@test "Ubuntu package list exists and is not empty" {
    [ -s "$PROJECT_ROOT/system/ubuntu/packages.txt" ]
}

@test "Fedora package list exists and is not empty" {
    [ -s "$PROJECT_ROOT/system/fedora/packages.txt" ]
}

@test "Arch package list exists and is not empty" {
    [ -s "$PROJECT_ROOT/system/arch/packages.txt" ]
}

# ============================================================================
# Script Help Tests
# ============================================================================

@test "audit-apps-linux.sh shows help" {
    run "$PROJECT_ROOT/scripts/apps/audit-apps-linux.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Linux Application Audit Script"* ]]
}

@test "generate-linux-packages.sh shows help" {
    run "$PROJECT_ROOT/scripts/apps/generate-linux-packages.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Generate Linux Package Lists"* ]]
}

@test "install-dependencies-ubuntu.sh shows help" {
    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-ubuntu.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Ubuntu Package Installation"* ]]
}

@test "install-dependencies-fedora.sh shows help" {
    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-fedora.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Fedora Package Installation"* ]]
}

@test "install-dependencies-arch.sh shows help" {
    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-arch.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Arch Linux Package Installation"* ]]
}

# ============================================================================
# Critical Package Tests
# ============================================================================

@test "Ubuntu packages.txt contains git" {
    grep -q "^git$" "$PROJECT_ROOT/system/ubuntu/packages.txt"
}

@test "Ubuntu packages.txt contains stow" {
    grep -q "^stow$" "$PROJECT_ROOT/system/ubuntu/packages.txt"
}

@test "Fedora packages.txt contains git" {
    grep -q "^git$" "$PROJECT_ROOT/system/fedora/packages.txt"
}

@test "Fedora packages.txt contains stow" {
    grep -q "^stow$" "$PROJECT_ROOT/system/fedora/packages.txt"
}

@test "Arch packages.txt contains git" {
    grep -q "^git$" "$PROJECT_ROOT/system/arch/packages.txt"
}

@test "Arch packages.txt contains stow" {
    grep -q "^stow$" "$PROJECT_ROOT/system/arch/packages.txt"
}

# ============================================================================
# Package Count Tests
# ============================================================================

@test "Ubuntu has at least 50 packages" {
    local count
    count=$(grep -v '^#' "$PROJECT_ROOT/system/ubuntu/packages.txt" | grep -v '^$' | wc -l | tr -d ' ')
    [ "$count" -ge 50 ]
}

@test "Fedora has at least 50 packages" {
    local count
    count=$(grep -v '^#' "$PROJECT_ROOT/system/fedora/packages.txt" | grep -v '^$' | wc -l | tr -d ' ')
    [ "$count" -ge 50 ]
}

@test "Arch has at least 50 packages" {
    local count
    count=$(grep -v '^#' "$PROJECT_ROOT/system/arch/packages.txt" | grep -v '^$' | wc -l | tr -d ' ')
    [ "$count" -ge 50 ]
}

# ============================================================================
# YAML Structure Tests (requires yq)
# ============================================================================

@test "package-mappings.yml is valid YAML" {
    if ! command -v yq >/dev/null 2>&1; then
        skip "yq not installed"
    fi
    run yq eval '.' "$MAPPING_FILE"
    [ "$status" -eq 0 ]
}

@test "package-mappings.yml has schema_version" {
    if ! command -v yq >/dev/null 2>&1; then
        skip "yq not installed"
    fi
    run yq eval '.schema_version' "$MAPPING_FILE"
    [ "$status" -eq 0 ]
    [ "$output" = "1.0.0" ]
}

@test "git package mapping has all distros" {
    if ! command -v yq >/dev/null 2>&1; then
        skip "yq not installed"
    fi

    # All three should be "git"
    result_apt=$(yq eval '.packages.git.apt' "$MAPPING_FILE")
    result_dnf=$(yq eval '.packages.git.dnf' "$MAPPING_FILE")
    result_pacman=$(yq eval '.packages.git.pacman' "$MAPPING_FILE")

    [ "$result_apt" = "git" ]
    [ "$result_dnf" = "git" ]
    [ "$result_pacman" = "git" ]
}

# ============================================================================
# Security Tests
# ============================================================================

@test "package names don't contain dangerous characters" {
    # Check all package lists for shell metacharacters
    ! grep -E '[;&|`$()<>]' "$PROJECT_ROOT/system/ubuntu/packages.txt" | grep -v '^#'
    ! grep -E '[;&|`$()<>]' "$PROJECT_ROOT/system/fedora/packages.txt" | grep -v '^#'
    ! grep -E '[;&|`$()<>]' "$PROJECT_ROOT/system/arch/packages.txt" | grep -v '^#'
}

# ============================================================================
# Documentation Tests
# ============================================================================

@test "package lists have proper headers" {
    run head -1 "$PROJECT_ROOT/system/ubuntu/packages.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == "#"* ]]

    run head -1 "$PROJECT_ROOT/system/fedora/packages.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == "#"* ]]

    run head -1 "$PROJECT_ROOT/system/arch/packages.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == "#"* ]]
}

@test "applications/linux/README.md exists" {
    # Will be created in next phase
    [ -f "$PROJECT_ROOT/applications/linux/README.md" ] || skip "README not yet created"
}

# ============================================================================
# Script Functionality Tests
# ============================================================================

@test "generate-linux-packages.sh dry-run works" {
    if ! command -v yq >/dev/null 2>&1; then
        skip "yq not installed"
    fi

    run "$PROJECT_ROOT/scripts/apps/generate-linux-packages.sh" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]
}

@test "generate-linux-packages.sh fails on invalid distro" {
    run "$PROJECT_ROOT/scripts/apps/generate-linux-packages.sh" --distro invalid-distro
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid distribution"* ]]
}

# ============================================================================
# Bootstrap Script Tests
# ============================================================================

@test "Ubuntu bootstrap has essential-only mode" {
    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-ubuntu.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"essential-only"* ]]
}

@test "Fedora bootstrap has essential-only mode" {
    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-fedora.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"essential-only"* ]]
}

@test "Arch bootstrap has essential-only mode" {
    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-arch.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"essential-only"* ]]
}

@test "All bootstrap scripts have dry-run mode" {
    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-ubuntu.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"dry-run"* ]]

    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-fedora.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"dry-run"* ]]

    run "$PROJECT_ROOT/scripts/bootstrap/install-dependencies-arch.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"dry-run"* ]]
}

# ============================================================================
# Directory Structure Tests
# ============================================================================

@test "applications/linux directory exists" {
    [ -d "$PROJECT_ROOT/applications/linux" ]
}

@test "system/ubuntu directory exists" {
    [ -d "$PROJECT_ROOT/system/ubuntu" ]
}

@test "system/fedora directory exists" {
    [ -d "$PROJECT_ROOT/system/fedora" ]
}

@test "system/arch directory exists" {
    [ -d "$PROJECT_ROOT/system/arch" ]
}

# ============================================================================
# Coverage Summary
# ============================================================================

@test "test coverage summary" {
    # This test always passes but provides info
    echo "# ===================================" >&3
    echo "# Linux Package Management Test Suite" >&3
    echo "# ===================================" >&3
    echo "# Total test cases: 40+" >&3
    echo "# Files: 7 scripts, 3 package lists, 2 YAML files" >&3
    echo "# Coverage areas:" >&3
    echo "#   - File existence ✓" >&3
    echo "#   - Script execution ✓" >&3
    echo "#   - Package lists ✓" >&3
    echo "#   - Security validation ✓" >&3
    echo "#   - YAML structure (yq) ✓" >&3
    echo "# ===================================" >&3
    true
}
