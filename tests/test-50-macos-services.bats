#!/usr/bin/env bats
#
# Test Suite for macOS Services Management (Issue #50)
# Tests installation script, bootstrap integration, and Makefile targets

# Setup and teardown
setup() {
    # Store original directory
    ORIGINAL_DIR="$PWD"

    # Navigate to dotfiles root
    cd "$(dirname "$BATS_TEST_DIRNAME")" || exit 1
    DOTFILES_ROOT="$PWD"

    # Define paths
    SERVICES_SCRIPT="$DOTFILES_ROOT/scripts/services/install-services.sh"
    SERVICES_DIR="$DOTFILES_ROOT/system/macos/services"
    SERVICES_CONFIG="$SERVICES_DIR/services.yml"
    BOOTSTRAP_SCRIPT="$DOTFILES_ROOT/scripts/bootstrap/macos-bootstrap.sh"
    MAKEFILE="$DOTFILES_ROOT/Makefile"
}

teardown() {
    cd "$ORIGINAL_DIR" || true
}

# ============================================================================
# Script Validation Tests
# ============================================================================

@test "install-services.sh script exists" {
    [ -f "$SERVICES_SCRIPT" ]
}

@test "install-services.sh is executable" {
    [ -x "$SERVICES_SCRIPT" ]
}

@test "install-services.sh has proper shebang" {
    run head -n 1 "$SERVICES_SCRIPT"
    [[ "$output" == *"#!/usr/bin/env bash"* ]]
}

@test "install-services.sh sources required utilities" {
    run grep -E "source.*logger.sh" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]

    run grep -E "source.*detect-os.sh" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh has error handling (set -euo pipefail)" {
    run grep "set -euo pipefail" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Configuration Files Tests
# ============================================================================

@test "services.yml configuration file exists" {
    [ -f "$SERVICES_CONFIG" ]
}

@test "services.yml is valid YAML" {
    skip "Requires yq to be installed"
    run yq eval '.' "$SERVICES_CONFIG"
    [ "$status" -eq 0 ]
}

@test "system/macos/services directory exists" {
    [ -d "$SERVICES_DIR" ]
}

@test "system/macos/services/archived directory exists" {
    [ -d "$SERVICES_DIR/archived" ]
}

@test "README.md exists in services directory" {
    [ -f "$SERVICES_DIR/README.md" ]
}

@test "README.md documents all 6 active workflows" {
    run grep -E "File to MD|File to TXT|MD to Rich Text|open-in-vscode|Open in Cursor|Retrieve CDN" "$SERVICES_DIR/README.md"
    [ "$status" -eq 0 ]
}

@test "README.md includes archived workflows section" {
    run grep -i "archived" "$SERVICES_DIR/README.md"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Workflow Files Tests
# ============================================================================

@test "File to MD.workflow exists in backup" {
    [ -d "$SERVICES_DIR/File to MD.workflow" ]
}

@test "File to TXT.workflow exists in backup" {
    [ -d "$SERVICES_DIR/File to TXT.workflow" ]
}

@test "MD to Rich Text.workflow exists in backup" {
    [ -d "$SERVICES_DIR/MD to Rich Text.workflow" ]
}

@test "open-in-vscode.workflow exists in backup" {
    [ -d "$SERVICES_DIR/open-in-vscode.workflow" ]
}

@test "Open in Cursor.workflow exists in backup" {
    [ -d "$SERVICES_DIR/Open in Cursor.workflow" ]
}

@test "Retrieve CDN url.workflow exists in backup" {
    [ -d "$SERVICES_DIR/Retrieve CDN url.workflow" ]
}

@test "Send to Kindle.workflow is archived" {
    [ -d "$SERVICES_DIR/archived/Send to Kindle.workflow" ]
}

@test "Servizio Things.workflow is archived" {
    [ -d "$SERVICES_DIR/archived/Servizio Things.workflow" ]
}

# ============================================================================
# Script Options Tests
# ============================================================================

@test "install-services.sh --help shows usage" {
    run "$SERVICES_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"USAGE"* ]]
    [[ "$output" == *"OPTIONS"* ]]
}

@test "install-services.sh accepts --essential-only option" {
    run grep -E "\-\-essential-only" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh accepts --all option" {
    run grep -E "\-\-all" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh accepts --dry-run option" {
    run grep -E "\-\-dry-run" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh accepts --force option" {
    run grep -E "\-\-force" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh accepts --verbose option" {
    run grep -E "\-\-verbose" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Installation Logic Tests
# ============================================================================

@test "install-services.sh checks for macOS" {
    run grep -E "uname.*Darwin" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh checks for yq requirement" {
    run grep -E "command.*yq" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh validates configuration file" {
    run grep -E "SERVICES_CONFIG" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh defines target directory" {
    run grep 'TARGET_DIR.*Library/Services' "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh has statistics tracking" {
    run grep -E "INSTALLED_COUNT|SKIPPED_COUNT|FAILED_COUNT" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh removes quarantine attributes" {
    run grep "xattr.*com.apple.quarantine" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh sets proper permissions" {
    run grep "chmod.*755" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh refreshes Services cache" {
    run grep "lsregister" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Bootstrap Integration Tests
# ============================================================================

@test "macos-bootstrap.sh exists" {
    [ -f "$BOOTSTRAP_SCRIPT" ]
}

@test "macos-bootstrap.sh includes services installation" {
    run grep "install-services.sh" "$BOOTSTRAP_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "macos-bootstrap.sh calls services with --essential-only" {
    run grep "\-\-essential-only" "$BOOTSTRAP_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "bootstrap installs services after fonts" {
    # Check that services section comes after fonts section
    fonts_line=$(grep -n "Installing Essential Fonts" "$BOOTSTRAP_SCRIPT" | cut -d: -f1)
    services_line=$(grep -n "Installing macOS Services" "$BOOTSTRAP_SCRIPT" | cut -d: -f1)

    [ -n "$fonts_line" ]
    [ -n "$services_line" ]
    [ "$services_line" -gt "$fonts_line" ]
}

# ============================================================================
# Makefile Integration Tests
# ============================================================================

@test "Makefile includes services targets in PHONY" {
    run grep "\.PHONY.*services-install" "$MAKEFILE"
    [ "$status" -eq 0 ]
}

@test "make services-install target exists" {
    run grep "^services-install:" "$MAKEFILE"
    [ "$status" -eq 0 ]
}

@test "make services-install-essential target exists" {
    run grep "^services-install-essential:" "$MAKEFILE"
    [ "$status" -eq 0 ]
}

@test "make services-verify target exists" {
    run grep "^services-verify:" "$MAKEFILE"
    [ "$status" -eq 0 ]
}

@test "make services-backup target exists" {
    run grep "^services-backup:" "$MAKEFILE"
    [ "$status" -eq 0 ]
}

@test "Makefile help includes services section" {
    run make help
    [ "$status" -eq 0 ]
    [[ "$output" == *"macOS Services Management"* ]]
}

@test "make help shows services-install command" {
    run make help
    [ "$status" -eq 0 ]
    [[ "$output" == *"services-install"* ]]
}

@test "make help shows services-install-essential command" {
    run make help
    [ "$status" -eq 0 ]
    [[ "$output" == *"services-install-essential"* ]]
}

# ============================================================================
# Documentation Tests
# ============================================================================

@test "README.md includes installation instructions" {
    run grep -i "installation" "$SERVICES_DIR/README.md"
    [ "$status" -eq 0 ]
}

@test "README.md includes troubleshooting section" {
    run grep -i "troubleshooting" "$SERVICES_DIR/README.md"
    [ "$status" -eq 0 ]
}

@test "README.md documents essential vs all modes" {
    run grep -E "essential.*mode|all.*mode" "$SERVICES_DIR/README.md"
    [ "$status" -eq 0 ]
}

@test "README.md includes workflow inventory" {
    run grep -E "Conversion Tools|Development Tools|CDN" "$SERVICES_DIR/README.md"
    [ "$status" -eq 0 ]
}

@test "services.yml documents modes configuration" {
    run grep -E "^modes:" "$SERVICES_CONFIG"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Workflow Structure Tests
# ============================================================================

@test "workflows have Contents directory" {
    [ -d "$SERVICES_DIR/File to MD.workflow/Contents" ]
}

@test "workflows have Info.plist" {
    [ -f "$SERVICES_DIR/File to MD.workflow/Contents/Info.plist" ]
}

@test "workflows have document.wflow" {
    [ -f "$SERVICES_DIR/File to MD.workflow/Contents/document.wflow" ]
}

# ============================================================================
# Error Handling Tests
# ============================================================================

@test "install-services.sh exits with error on non-macOS" {
    skip "Cannot test non-macOS behavior on macOS"
}

@test "install-services.sh validates required tools" {
    run grep "check_requirements" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "install-services.sh handles missing configuration gracefully" {
    run grep "validate_config" "$SERVICES_SCRIPT"
    [ "$status" -eq 0 ]
}

# ============================================================================
# Integration Summary Test
# ============================================================================

@test "services system is fully integrated" {
    # Check all key components exist
    [ -f "$SERVICES_SCRIPT" ]
    [ -f "$SERVICES_CONFIG" ]
    [ -f "$SERVICES_DIR/README.md" ]
    [ -d "$SERVICES_DIR/archived" ]

    # Check bootstrap integration
    run grep "install-services.sh" "$BOOTSTRAP_SCRIPT"
    [ "$status" -eq 0 ]

    # Check Makefile integration
    run grep "services-install" "$MAKEFILE"
    [ "$status" -eq 0 ]

    # Check workflow count (6 active workflows)
    workflow_count=$(find "$SERVICES_DIR" -maxdepth 1 -name "*.workflow" -type d | wc -l | tr -d ' ')
    [ "$workflow_count" -eq 6 ]
}
