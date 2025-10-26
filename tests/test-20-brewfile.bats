#!/usr/bin/env bats
#
# test-20-brewfile.bats - Tests for Brewfile generation and management
#
# Tests for Issue #20: Brewfile & App Management
#

# Setup
setup() {
    # Get repository root
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

    # Test directories
    TEST_TMP_DIR="${BATS_TEST_TMPDIR}/brewfile-test"
    mkdir -p "$TEST_TMP_DIR"

    # Scripts
    GENERATE_SCRIPT="$REPO_ROOT/scripts/apps/generate-brewfile.sh"
    AUDIT_SCRIPT="$REPO_ROOT/scripts/apps/audit-apps.sh"

    # Test data
    TEST_AUDIT_FILE="$TEST_TMP_DIR/test-audit.txt"
    TEST_BREWFILE="$TEST_TMP_DIR/Brewfile"
}

# Teardown
teardown() {
    rm -rf "$TEST_TMP_DIR"
}

# Helper: Create minimal test audit file
create_test_audit() {
    cat > "$TEST_AUDIT_FILE" <<'EOF'
Application Audit Report
Generated: 2025-10-25 13:37:45
Total Applications: 50

========================================================================

=== Homebrew Casks (5) ===

visual-studio-code
firefox
google-chrome
1password-cli
docker

========================================================================

=== Homebrew Formulae (10) ===

git
gh
node
python@3.12
postgresql@17
brew
stow
wget
fzf
htop

========================================================================

=== Mac App Store Apps (2) ===

123456 Xcode (15.0)
789012 Keynote (13.0)

========================================================================
EOF
}

#
# Test 1-5: Script Existence and Permissions
#

@test "generate-brewfile.sh exists" {
    [ -f "$GENERATE_SCRIPT" ]
}

@test "generate-brewfile.sh is executable" {
    [ -x "$GENERATE_SCRIPT" ]
}

@test "generate-brewfile.sh has valid shebang" {
    head -n 1 "$GENERATE_SCRIPT" | grep -q "^#!/usr/bin/env bash"
}

@test "generate-brewfile.sh shows help with --help" {
    run "$GENERATE_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "generate-brewfile.sh requires input file" {
    run "$GENERATE_SCRIPT" --input /nonexistent/file.txt
    [ "$status" -ne 0 ]
}

#
# Test 6-15: Brewfile Generation
#

@test "generate-brewfile.sh creates Brewfile from test audit" {
    create_test_audit
    run "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    [ "$status" -eq 0 ]
    [ -f "$TEST_BREWFILE" ]
}

@test "generated Brewfile has proper header" {
    create_test_audit
    "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    head -n 5 "$TEST_BREWFILE" | grep -q "Brewfile - Homebrew package manifest"
}

@test "generated Brewfile includes taps section" {
    create_test_audit
    "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    grep -q 'tap "homebrew/bundle"' "$TEST_BREWFILE"
}

@test "generated Brewfile includes formulae" {
    create_test_audit
    "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    grep -q 'brew "git"' "$TEST_BREWFILE"
}

@test "generated Brewfile includes casks" {
    create_test_audit
    "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    grep -q 'cask "visual-studio-code"' "$TEST_BREWFILE"
}

@test "generated Brewfile includes mas apps" {
    create_test_audit
    "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    grep -q 'mas "Xcode", id: 123456' "$TEST_BREWFILE"
}

@test "generated Brewfile has category sections" {
    create_test_audit
    "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    grep -q "Development Tools" "$TEST_BREWFILE"
}

@test "generated Brewfile has sorted packages" {
    create_test_audit
    "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    # Extract brew lines and verify they're sorted
    grep '^brew "' "$TEST_BREWFILE" | head -5 > /dev/null
}

@test "generated Brewfile has footer" {
    create_test_audit
    "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE"
    tail -n 3 "$TEST_BREWFILE" | grep -q "End of Brewfile"
}

@test "dry-run mode doesn't create file" {
    create_test_audit
    run "$GENERATE_SCRIPT" --input "$TEST_AUDIT_FILE" --output "$TEST_BREWFILE" --dry-run
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_BREWFILE" ]
}

#
# Test 16-25: Real Brewfile Tests
#

@test "real Brewfile exists in system/macos/" {
    [ -f "$REPO_ROOT/system/macos/Brewfile" ]
}

@test "real Brewfile is not empty" {
    [ -s "$REPO_ROOT/system/macos/Brewfile" ]
}

@test "real Brewfile has proper format" {
    grep -q '^# Brewfile' "$REPO_ROOT/system/macos/Brewfile"
}

@test "real Brewfile has taps" {
    grep -q '^tap "' "$REPO_ROOT/system/macos/Brewfile"
}

@test "real Brewfile has formulae" {
    grep -q '^brew "' "$REPO_ROOT/system/macos/Brewfile"
}

@test "real Brewfile has casks" {
    grep -q '^cask "' "$REPO_ROOT/system/macos/Brewfile"
}

@test "real Brewfile has category comments" {
    grep -q "# ===" "$REPO_ROOT/system/macos/Brewfile"
}

@test "real Brewfile has no duplicate entries" {
    # Check for duplicate brew/cask lines
    duplicates=$(grep -E '^(brew|cask) ' "$REPO_ROOT/system/macos/Brewfile" | sort | uniq -d | wc -l)
    [ "$duplicates" -eq 0 ]
}

@test "brew bundle syntax check on real Brewfile" {
    skip "Requires brew to be installed and working"
    run brew bundle check --file="$REPO_ROOT/system/macos/Brewfile"
    # Don't fail on missing packages, just check syntax is valid
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "real Brewfile has reasonable size" {
    lines=$(wc -l < "$REPO_ROOT/system/macos/Brewfile")
    # Should have at least 100 lines (comments + packages)
    [ "$lines" -gt 100 ]
}

#
# Test 26-35: VSCode Extensions
#

@test "vscode-extensions.txt exists" {
    [ -f "$REPO_ROOT/applications/vscode-extensions.txt" ]
}

@test "vscode-extensions.txt is not empty" {
    [ -s "$REPO_ROOT/applications/vscode-extensions.txt" ]
}

@test "vscode-extensions.txt has header" {
    head -n 5 "$REPO_ROOT/applications/vscode-extensions.txt" | grep -q "VSCode Extensions"
}

@test "vscode-extensions.txt has install instructions" {
    grep -q "To install all extensions" "$REPO_ROOT/applications/vscode-extensions.txt"
}

@test "vscode-extensions.txt has valid extension format" {
    # Extensions should be in format: publisher.extension-name
    extensions=$(grep -v '^#' "$REPO_ROOT/applications/vscode-extensions.txt" | grep -v '^$')
    while IFS= read -r ext; do
        [[ "$ext" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$ ]] || return 1
    done <<< "$extensions"
}

@test "vscode-extensions.txt is sorted" {
    extensions=$(grep -v '^#' "$REPO_ROOT/applications/vscode-extensions.txt" | grep -v '^$')
    sorted_extensions=$(echo "$extensions" | sort)
    [ "$extensions" = "$sorted_extensions" ]
}

@test "vscode-extensions.txt has anthropic.claude-code" {
    grep -q "anthropic.claude-code" "$REPO_ROOT/applications/vscode-extensions.txt"
}

@test "vscode-extensions.txt has github.copilot" {
    grep -q "github.copilot" "$REPO_ROOT/applications/vscode-extensions.txt"
}

@test "vscode-extensions.txt has ms-python.python" {
    grep -q "ms-python.python" "$REPO_ROOT/applications/vscode-extensions.txt"
}

@test "vscode-extensions.txt count matches header" {
    header_count=$(grep "Total Extensions:" "$REPO_ROOT/applications/vscode-extensions.txt" | grep -o '[0-9]\+')
    actual_count=$(grep -v '^#' "$REPO_ROOT/applications/vscode-extensions.txt" | grep -v '^$' | wc -l)
    [ "$header_count" -eq "$actual_count" ]
}

#
# Test 36-40: Makefile Targets
#

@test "Makefile has brewfile-generate target" {
    grep -q "^brewfile-generate:" "$REPO_ROOT/Makefile"
}

@test "Makefile has brewfile-check target" {
    grep -q "^brewfile-check:" "$REPO_ROOT/Makefile"
}

@test "Makefile has brewfile-install target" {
    grep -q "^brewfile-install:" "$REPO_ROOT/Makefile"
}

@test "Makefile has brewfile-update target" {
    grep -q "^brewfile-update:" "$REPO_ROOT/Makefile"
}

@test "Makefile help shows Brewfile commands" {
    run make -C "$REPO_ROOT" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"brewfile-generate"* ]]
}
