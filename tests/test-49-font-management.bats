#!/usr/bin/env bats
#
# Test Suite: Font Management System (Issue #49)
# Tests font installation script, configuration, and integration

setup() {
    # Project root
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    FONTS_SCRIPT="$PROJECT_ROOT/scripts/fonts/install-fonts.sh"
    FONTS_CONFIG="$PROJECT_ROOT/fonts/fonts.yml"
    FONTS_BACKUP="$PROJECT_ROOT/fonts/backup"
}

# ============================================================================
# File Structure Tests
# ============================================================================

@test "fonts.yml configuration exists" {
    [ -f "$FONTS_CONFIG" ]
}

@test "fonts/backup directory exists and contains fonts" {
    [ -d "$FONTS_BACKUP" ]
    font_count=$(find "$FONTS_BACKUP" -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.pcf.gz" \) | wc -l | tr -d ' ')
    [ "$font_count" -gt 100 ]
}

@test "font installation script exists and is executable" {
    [ -f "$FONTS_SCRIPT" ]
    [ -x "$FONTS_SCRIPT" ]
}

# ============================================================================
# Script Usage Tests
# ============================================================================

@test "font install script shows help with --help" {
    run "$FONTS_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Font Installation Script"* ]]
    [[ "$output" == *"--essential-only"* ]]
}

@test "font install script accepts --dry-run flag" {
    skip "Requires macOS and yq"
    run "$FONTS_SCRIPT" --essential-only --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry-run"* ]] || [[ "$output" == *"DRY RUN"* ]]
}

@test "font install script rejects invalid options" {
    run "$FONTS_SCRIPT" --invalid-option
    [ "$status" -ne 0 ]
}

# ============================================================================
# Configuration Tests
# ============================================================================

@test "fonts.yml is valid YAML" {
    if ! command -v yq &> /dev/null; then
        skip "yq not installed"
    fi
    run yq eval '.' "$FONTS_CONFIG"
    [ "$status" -eq 0 ]
}

@test "fonts.yml contains essential fonts category" {
    if ! command -v yq &> /dev/null; then
        skip "yq not installed"
    fi
    run yq eval '.essential' "$FONTS_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" != "null" ]]
}

@test "fonts.yml defines MesloLGS NF fonts as essential" {
    if ! command -v yq &> /dev/null; then
        skip "yq not installed"
    fi
    run yq eval '.essential.terminal[] | select(. == "MesloLGS NF Regular.ttf")' "$FONTS_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"MesloLGS NF Regular.ttf"* ]]
}

@test "fonts.yml defines Lato as essential professional font" {
    if ! command -v yq &> /dev/null; then
        skip "yq not installed"
    fi
    run yq eval '.essential.professional[] | select(. == "Lato-Regular.ttf")' "$FONTS_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Lato-Regular.ttf"* ]]
}

@test "fonts.yml defines Raleway as essential professional font" {
    if ! command -v yq &> /dev/null; then
        skip "yq not installed"
    fi
    run yq eval '.essential.professional[] | select(. == "Raleway-VF.ttf")' "$FONTS_CONFIG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Raleway-VF.ttf"* ]]
}

# ============================================================================
# Font Backup Verification
# ============================================================================

@test "MesloLGS NF fonts exist in backup" {
    [ -f "$FONTS_BACKUP/MesloLGS NF Regular.ttf" ]
    [ -f "$FONTS_BACKUP/MesloLGS NF Bold.ttf" ]
    [ -f "$FONTS_BACKUP/MesloLGS NF Italic.ttf" ]
    [ -f "$FONTS_BACKUP/MesloLGS NF Bold Italic.ttf" ]
}

@test "Lato fonts exist in backup" {
    [ -f "$FONTS_BACKUP/Lato-Regular.ttf" ]
    [ -f "$FONTS_BACKUP/Lato-Bold.ttf" ]
}

@test "Raleway fonts exist in backup" {
    [ -f "$FONTS_BACKUP/Raleway-VF.ttf" ]
}

@test "Hack coding fonts exist in backup" {
    [ -f "$FONTS_BACKUP/Hack-Regular.ttf" ]
    [ -f "$FONTS_BACKUP/Hack-Bold.ttf" ]
}

@test "Powerline fonts exist in backup" {
    [ -f "$FONTS_BACKUP/Source Code Pro for Powerline.otf" ]
    [ -f "$FONTS_BACKUP/DejaVu Sans Mono for Powerline.ttf" ]
}

# ============================================================================
# Health Check Integration Tests
# ============================================================================

@test "health check script includes font check function" {
    health_script="$PROJECT_ROOT/scripts/health/check-all.sh"
    [ -f "$health_script" ]
    grep -q "Font Installation" "$health_script"
}

@test "health check verifies essential fonts" {
    health_script="$PROJECT_ROOT/scripts/health/check-all.sh"
    [ -f "$health_script" ]
    grep -q "MesloLGS NF" "$health_script"
}

# ============================================================================
# Bootstrap Integration Tests
# ============================================================================

@test "bootstrap script includes font installation" {
    bootstrap_script="$PROJECT_ROOT/scripts/bootstrap/macos-bootstrap.sh"
    [ -f "$bootstrap_script" ]
    grep -q "Installing Essential Fonts" "$bootstrap_script"
}

@test "bootstrap calls font install script" {
    bootstrap_script="$PROJECT_ROOT/scripts/bootstrap/macos-bootstrap.sh"
    [ -f "$bootstrap_script" ]
    grep -q "install-fonts.sh" "$bootstrap_script"
}

# ============================================================================
# Makefile Integration Tests
# ============================================================================

@test "Makefile defines fonts-install target" {
    makefile="$PROJECT_ROOT/Makefile"
    [ -f "$makefile" ]
    grep -q "^fonts-install:" "$makefile"
}

@test "Makefile defines fonts-install-essential target" {
    makefile="$PROJECT_ROOT/Makefile"
    [ -f "$makefile" ]
    grep -q "^fonts-install-essential:" "$makefile"
}

@test "Makefile defines fonts-verify target" {
    makefile="$PROJECT_ROOT/Makefile"
    [ -f "$makefile" ]
    grep -q "^fonts-verify:" "$makefile"
}

@test "Makefile help includes font management section" {
    makefile="$PROJECT_ROOT/Makefile"
    [ -f "$makefile" ]
    grep -q "Font Management" "$makefile"
}

# ============================================================================
# Documentation Tests
# ============================================================================

@test "fonts README exists and is comprehensive" {
    readme="$PROJECT_ROOT/fonts/README.md"
    [ -f "$readme" ]
    file_size=$(wc -c < "$readme" | tr -d ' ')
    [ "$file_size" -gt 5000 ]
}

@test "fonts README documents all installation options" {
    readme="$PROJECT_ROOT/fonts/README.md"
    [ -f "$readme" ]
    grep -q "essential-only" "$readme"
    grep -q "with-coding" "$readme"
    grep -q "with-powerline" "$readme"
}

@test "fonts README includes troubleshooting section" {
    readme="$PROJECT_ROOT/fonts/README.md"
    [ -f "$readme" ]
    grep -q "Troubleshooting" "$readme"
}

# ============================================================================
# macOS-Specific Tests (conditional)
# ============================================================================

@test "macOS fonts directory exists" {
    if [ "$(uname -s)" != "Darwin" ]; then
        skip "macOS-specific test"
    fi
    [ -d "$HOME/Library/Fonts" ]
}

@test "atsutil command available on macOS" {
    if [ "$(uname -s)" != "Darwin" ]; then
        skip "macOS-specific test"
    fi
    command -v atsutil
}

# ============================================================================
# Summary Test
# ============================================================================

@test "font management system complete and integrated" {
    # Configuration
    [ -f "$FONTS_CONFIG" ]
    [ -d "$FONTS_BACKUP" ]

    # Scripts
    [ -f "$FONTS_SCRIPT" ]
    [ -x "$FONTS_SCRIPT" ]

    # Integration
    [ -f "$PROJECT_ROOT/scripts/health/check-all.sh" ]
    [ -f "$PROJECT_ROOT/scripts/bootstrap/macos-bootstrap.sh" ]
    [ -f "$PROJECT_ROOT/Makefile" ]

    # Documentation
    [ -f "$PROJECT_ROOT/fonts/README.md" ]

    # Verify integration points
    grep -q "Font Installation" "$PROJECT_ROOT/scripts/health/check-all.sh"
    grep -q "install-fonts.sh" "$PROJECT_ROOT/scripts/bootstrap/macos-bootstrap.sh"
    grep -q "fonts-install:" "$PROJECT_ROOT/Makefile"
}
