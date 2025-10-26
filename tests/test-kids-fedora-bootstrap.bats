#!/usr/bin/env bats
# Tests for Kids' Fedora Bootstrap Script
# Tests kids-fedora-bootstrap.sh functionality

setup() {
    # Get project root
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    BOOTSTRAP_SCRIPT="$PROJECT_ROOT/scripts/bootstrap/kids-fedora-bootstrap.sh"
    EDUCATIONAL_PACKAGES="$PROJECT_ROOT/system/fedora/educational-packages.txt"
}

# =============================================================================
# Script Existence Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh exists" {
    [ -f "$BOOTSTRAP_SCRIPT" ]
}

@test "kids-fedora-bootstrap.sh is executable" {
    [ -x "$BOOTSTRAP_SCRIPT" ]
}

@test "educational-packages.txt exists" {
    [ -f "$EDUCATIONAL_PACKAGES" ]
}

# =============================================================================
# Help and Options Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh --help shows usage" {
    run "$BOOTSTRAP_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Kids' Fedora Learning Environment" ]]
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "--child-name" ]]
    [[ "$output" =~ "--child-age" ]]
}

@test "kids-fedora-bootstrap.sh shows help with invalid option" {
    run "$BOOTSTRAP_SCRIPT" --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

# =============================================================================
# Script Structure Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh uses strict error handling" {
    head -20 "$BOOTSTRAP_SCRIPT" | grep -q "set -euo pipefail"
}

@test "kids-fedora-bootstrap.sh sources logger.sh" {
    grep -q "source.*logger.sh" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh sources detect-os.sh" {
    grep -q "source.*detect-os.sh" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Function Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh has validate_environment function" {
    grep -q "validate_environment()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has gather_parent_input function" {
    grep -q "gather_parent_input()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has install_educational_software function" {
    grep -q "install_educational_software()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has create_kids_account function" {
    grep -q "create_kids_account()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has setup_parental_controls function" {
    grep -q "setup_parental_controls()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has configure_desktop_for_kids function" {
    grep -q "configure_desktop_for_kids()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has setup_safe_browsing function" {
    grep -q "setup_safe_browsing()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has create_monitoring_tools function" {
    grep -q "create_monitoring_tools()" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Validation Logic Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh has validate_child_name function" {
    grep -q "validate_child_name()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has validate_child_age function" {
    grep -q "validate_child_age()" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh checks age range 4-12" {
    grep -q "4.*12" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Educational Software Tests
# =============================================================================

@test "educational-packages.txt contains gcompris" {
    grep -q "gcompris" "$EDUCATIONAL_PACKAGES"
}

@test "educational-packages.txt contains tux apps" {
    grep -qE "tux(paint|math|typing)" "$EDUCATIONAL_PACKAGES"
}

@test "educational-packages.txt has comments" {
    grep -q "^#" "$EDUCATIONAL_PACKAGES"
}

@test "kids-fedora-bootstrap.sh references educational-packages.txt" {
    grep -q "educational-packages.txt" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has install-all option" {
    grep -q "INSTALL_ALL" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has core-only option" {
    grep -q "CORE_ONLY" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Safety Feature Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh checks for sudo access" {
    grep -q "sudo access" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh removes kids from wheel group" {
    grep -q "gpasswd.*wheel" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh verifies no sudo for kids" {
    grep -q "sudo -u.*sudo -n" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh creates restricted user" {
    grep -q "useradd.*-m" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has safety check comments" {
    grep -q "CRITICAL" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Parental Control Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh installs malcontent" {
    grep -q "malcontent" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh mentions malcontent-control GUI" {
    grep -q "malcontent-control" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh sets app filter" {
    grep -q "app-filter" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh considers child's age" {
    grep -q "CHILD_AGE" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has OARS content filtering" {
    grep -q "oars" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Desktop Configuration Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh configures GNOME settings" {
    grep -q "gsettings" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh disables hot corners" {
    grep -q "hot-corners" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh increases text size" {
    grep -q "text-scaling-factor" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh creates polkit rules" {
    grep -q "polkit" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh pins educational apps to dock" {
    grep -q "favorite-apps" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Safe Browsing Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh installs Firefox" {
    grep -q "firefox" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh mentions DNS filtering" {
    grep -q "DNS" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh mentions OpenDNS FamilyShield" {
    grep -q "OpenDNS" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has DNS addresses" {
    grep -q "208.67.222.123" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh mentions browser extensions" {
    grep -q "uBlock\|LeechBlock" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Monitoring Tools Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh creates log-kids-usage script" {
    grep -q "log-kids-usage" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh creates kids-dashboard script" {
    grep -q "kids-dashboard" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh sets up cron job" {
    grep -q "cron" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh creates usage log file" {
    grep -q "/var/log/kids-usage.log" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has skip-monitoring option" {
    grep -q "SKIP_MONITORING" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Parent Guide Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh generates parent guide" {
    grep -q "PARENT-README" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh includes credentials in guide" {
    grep -q "CREDENTIALS" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh lists manual steps" {
    grep -q "MANUAL STEP" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh explains next steps" {
    grep -q "NEXT STEPS" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Base System Integration Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh calls fedora-bootstrap.sh" {
    grep -q "fedora-bootstrap.sh" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh uses essential-only flag" {
    grep -q "essential-only" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Educational Philosophy Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh mentions educational philosophy" {
    grep -q -i "educational\|learning" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh mentions safety layers" {
    grep -q "layer\|protection" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has teaching moments" {
    grep -q "teach\|learn" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Dry-run Support Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh supports dry-run" {
    grep -q "DRY_RUN" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh has execute wrapper function" {
    grep -q "execute()" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Interactive Mode Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh prompts for child name" {
    grep -q "read.*CHILD_NAME" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh prompts for child age" {
    grep -q "read.*CHILD_AGE" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh asks for software selection" {
    grep -q "software.*choice" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Error Handling Tests
# =============================================================================

@test "kids-fedora-bootstrap.sh exits if not Fedora" {
    grep -q 'exit 2' "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh checks for Parallels Tools" {
    grep -q "prltools" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh checks internet connectivity" {
    grep -q "ping" "$BOOTSTRAP_SCRIPT"
}

@test "kids-fedora-bootstrap.sh verifies educational packages file" {
    grep -q "EDUCATIONAL_PACKAGES" "$BOOTSTRAP_SCRIPT"
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "kids-fedora-usage.md exists" {
    [ -f "$PROJECT_ROOT/docs/guides/kids-fedora-usage.md" ]
}

@test "kids-fedora-usage.md mentions time limits" {
    grep -q "time limit" "$PROJECT_ROOT/docs/guides/kids-fedora-usage.md"
}

@test "kids-fedora-usage.md has troubleshooting section" {
    grep -q "Troubleshooting" "$PROJECT_ROOT/docs/guides/kids-fedora-usage.md"
}

@test "kids-fedora-usage.md has age-appropriate guidance" {
    grep -qE "Ages [0-9]+-[0-9]+" "$PROJECT_ROOT/docs/guides/kids-fedora-usage.md"
}

# =============================================================================
# Integration Tests (Fedora VM only - skipped on other systems)
# =============================================================================

@test "skip: full bootstrap dry-run" {
    # Only run on Fedora
    if [[ ! -f /etc/fedora-release ]]; then
        skip "Not running on Fedora"
    fi

    run "$BOOTSTRAP_SCRIPT" --dry-run --child-name "TestChild" --child-age 8 --install-all
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY-RUN MODE" ]]
}

@test "skip: validates child name format" {
    # Only run on Fedora
    if [[ ! -f /etc/fedora-release ]]; then
        skip "Not running on Fedora"
    fi

    # This would require interactive testing or mocking
    skip "Requires interactive input testing"
}

@test "skip: verifies no sudo for kids account" {
    # Only run on Fedora with test account
    if [[ ! -f /etc/fedora-release ]]; then
        skip "Not running on Fedora"
    fi

    skip "Requires actual account creation to test"
}
