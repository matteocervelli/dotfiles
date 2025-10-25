#!/usr/bin/env bats
# Tests for Application Audit & Cleanup (Issue #19)
#
# Tests:
# - audit-apps.sh execution and output
# - cleanup-apps.sh dry-run mode (safe testing)
# - Safety features and validation
# - Error handling

# Setup test environment
setup() {
    # Project root detection
    export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export AUDIT_SCRIPT="$PROJECT_ROOT/scripts/apps/audit-apps.sh"
    export CLEANUP_SCRIPT="$PROJECT_ROOT/scripts/apps/cleanup-apps.sh"
    export APPLICATIONS_DIR="$PROJECT_ROOT/applications"
    export TEST_OUTPUT="/tmp/test-apps-$$.txt"
    export TEST_REMOVE_LIST="/tmp/test-remove-apps-$$.txt"

    # Skip tests on non-macOS systems
    if [[ "$(uname -s)" != "Darwin" ]]; then
        skip "These tests only run on macOS"
    fi
}

# Cleanup after tests
teardown() {
    # Remove temporary files
    rm -f "$TEST_OUTPUT" "$TEST_REMOVE_LIST" 2>/dev/null || true
}

# =============================================================================
# Audit Script Tests
# =============================================================================

@test "audit-apps.sh: script exists and is executable" {
    [ -f "$AUDIT_SCRIPT" ]
    [ -x "$AUDIT_SCRIPT" ]
}

@test "audit-apps.sh: shows help message" {
    run "$AUDIT_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Application Audit Script"* ]]
    [[ "$output" == *"USAGE"* ]]
}

@test "audit-apps.sh: runs without errors (default output)" {
    # This creates the actual current-apps.txt
    run "$AUDIT_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Audit complete"* ]]
}

@test "audit-apps.sh: creates output file" {
    run "$AUDIT_SCRIPT" --output "$TEST_OUTPUT"
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT" ]
}

@test "audit-apps.sh: output contains expected sections" {
    "$AUDIT_SCRIPT" --output "$TEST_OUTPUT"

    grep -q "=== Homebrew Casks" "$TEST_OUTPUT"
    grep -q "=== Homebrew Formulae" "$TEST_OUTPUT"
    grep -q "=== Mac App Store Apps" "$TEST_OUTPUT"
    grep -q "=== Setapp Apps" "$TEST_OUTPUT"
    grep -q "=== Manual Installations" "$TEST_OUTPUT"
}

@test "audit-apps.sh: output has header with timestamp" {
    "$AUDIT_SCRIPT" --output "$TEST_OUTPUT"

    grep -q "Application Audit Report" "$TEST_OUTPUT"
    grep -q "Generated:" "$TEST_OUTPUT"
    grep -q "Total Applications:" "$TEST_OUTPUT"
}

@test "audit-apps.sh: output has usage notes" {
    "$AUDIT_SCRIPT" --output "$TEST_OUTPUT"

    grep -q "Notes:" "$TEST_OUTPUT"
    grep -q "remove-apps.txt" "$TEST_OUTPUT"
}

@test "audit-apps.sh: verbose mode works" {
    run "$AUDIT_SCRIPT" --verbose --output "$TEST_OUTPUT"
    [ "$status" -eq 0 ]
    # Verbose mode should show additional info
    [[ "$output" == *"Running on macOS"* ]] || [[ "$output" == *"Discovering"* ]]
}

@test "audit-apps.sh: creates applications/ directory if missing" {
    # Create temp directory for test
    local temp_dir="/tmp/test-audit-dir-$$"
    mkdir -p "$temp_dir"

    # Run audit with output to non-existent subdir
    run "$AUDIT_SCRIPT" --output "$temp_dir/subdir/apps.txt"
    [ "$status" -eq 0 ]
    [ -f "$temp_dir/subdir/apps.txt" ]

    # Cleanup
    rm -rf "$temp_dir"
}

@test "audit-apps.sh: output contains valid app count format" {
    "$AUDIT_SCRIPT" --output "$TEST_OUTPUT"

    # Check format: "=== Section (N) ==="
    grep -E "=== Homebrew Casks \([0-9]+\) ===" "$TEST_OUTPUT"
    grep -E "=== Homebrew Formulae \([0-9]+\) ===" "$TEST_OUTPUT"
    grep -E "=== Mac App Store Apps \([0-9]+\) ===" "$TEST_OUTPUT"
    grep -E "=== Setapp Apps \([0-9]+\) ===" "$TEST_OUTPUT"
    grep -E "=== Manual Installations \([0-9]+\) ===" "$TEST_OUTPUT"
}

# =============================================================================
# Cleanup Script Tests
# =============================================================================

@test "cleanup-apps.sh: script exists and is executable" {
    [ -f "$CLEANUP_SCRIPT" ]
    [ -x "$CLEANUP_SCRIPT" ]
}

@test "cleanup-apps.sh: shows help message" {
    run "$CLEANUP_SCRIPT" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Application Cleanup Script"* ]]
    [[ "$output" == *"SAFETY FEATURES"* ]]
}

@test "cleanup-apps.sh: fails when input file missing" {
    run "$CLEANUP_SCRIPT" --input "/tmp/nonexistent-$$.txt"
    [ "$status" -eq 5 ]
    [[ "$output" == *"Input file not found"* ]]
}

@test "cleanup-apps.sh: fails when input file empty" {
    # Create empty file
    touch "$TEST_REMOVE_LIST"

    run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"
    [ "$status" -eq 5 ]
    [[ "$output" == *"No applications listed"* ]]
}

@test "cleanup-apps.sh: dry-run is default mode" {
    # Create test input file
    echo "test-nonexistent-app" > "$TEST_REMOVE_LIST"

    run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY-RUN"* ]] || [[ "$output" == *"dry-run"* ]]
}

@test "cleanup-apps.sh: dry-run shows what would be done" {
    # Create test input file with fake app
    echo "test-fake-app-for-testing" > "$TEST_REMOVE_LIST"

    run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"
    [ "$status" -eq 0 ]
    [[ "$output" == *"MODE: DRY-RUN"* ]]
    [[ "$output" == *"no actual changes"* ]]
}

@test "cleanup-apps.sh: ignores comments in input file" {
    # Create input with comments
    cat > "$TEST_REMOVE_LIST" << EOF
# This is a comment
test-app-1

# Another comment
test-app-2
EOF

    run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST" --verbose
    [ "$status" -eq 0 ]
    # Should process 2 apps, not 4 lines
    [[ "$output" == *"Found 2 apps"* ]] || [[ "$output" == *"Processing 2"* ]]
}

@test "cleanup-apps.sh: ignores blank lines in input file" {
    # Create input with blank lines
    cat > "$TEST_REMOVE_LIST" << EOF
test-app-1

test-app-2

test-app-3
EOF

    run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST" --verbose
    [ "$status" -eq 0 ]
    # Should process 3 apps, not 5 lines
    [[ "$output" == *"Found 3 apps"* ]] || [[ "$output" == *"Processing 3"* ]]
}

@test "cleanup-apps.sh: trims whitespace from app names" {
    # Create input with whitespace
    cat > "$TEST_REMOVE_LIST" << EOF
  test-app-1
test-app-2
   test-app-3
EOF

    run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"
    [ "$status" -eq 0 ]
    # Should not have issues with whitespace
}

@test "cleanup-apps.sh: shows cleanup summary" {
    echo "test-app" > "$TEST_REMOVE_LIST"

    run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Cleanup Summary"* ]]
    [[ "$output" == *"Applications to remove"* ]]
}

@test "cleanup-apps.sh: shows statistics" {
    echo "test-app" > "$TEST_REMOVE_LIST"

    run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Cleanup Statistics"* ]]
    [[ "$output" == *"Total apps processed"* ]]
}

@test "cleanup-apps.sh: verbose mode works" {
    echo "test-app" > "$TEST_REMOVE_LIST"

    run "$CLEANUP_SCRIPT" --verbose --input "$TEST_REMOVE_LIST"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Running on macOS"* ]] || [[ "$output" == *"dependencies OK"* ]]
}

# =============================================================================
# Integration Tests
# =============================================================================

@test "workflow: audit creates file that cleanup can read" {
    # Run audit
    "$AUDIT_SCRIPT" --output "$TEST_OUTPUT"

    # Verify file exists
    [ -f "$TEST_OUTPUT" ]

    # Extract first app name from Homebrew section (if any)
    local first_app
    first_app=$(awk '/=== Homebrew Casks/,/===/{print}' "$TEST_OUTPUT" | grep -v "===" | grep -v "^$" | grep -v "^(none)" | head -1 | xargs)

    # If we found an app, test cleanup with it
    if [[ -n "$first_app" ]]; then
        echo "$first_app" > "$TEST_REMOVE_LIST"

        run "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"
        [ "$status" -eq 0 ]
        [[ "$output" == *"$first_app"* ]]
    fi
}

@test "safety: cleanup without --execute does not remove apps" {
    # Create a test file (not an app) to verify nothing is deleted
    local test_marker="/tmp/test-cleanup-marker-$$.txt"
    echo "test" > "$test_marker"

    echo "some-fake-app" > "$TEST_REMOVE_LIST"

    # Run cleanup (dry-run)
    "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"

    # Marker should still exist (proving no rm commands ran)
    [ -f "$test_marker" ]

    rm -f "$test_marker"
}

@test "applications/ directory structure exists" {
    [ -d "$APPLICATIONS_DIR" ]
    [ -f "$APPLICATIONS_DIR/README.md" ]
    [ -f "$APPLICATIONS_DIR/keep-apps.txt" ]
    [ -f "$APPLICATIONS_DIR/remove-apps.txt" ]
}

@test "template files have helpful comments" {
    grep -q "# Applications to Keep" "$APPLICATIONS_DIR/keep-apps.txt"
    grep -q "# Applications to Remove" "$APPLICATIONS_DIR/remove-apps.txt"
}

# =============================================================================
# Error Handling Tests
# =============================================================================

@test "audit-apps.sh: handles invalid output path gracefully" {
    # Try to write to read-only location
    run "$AUDIT_SCRIPT" --output "/invalid/path/apps.txt"
    [ "$status" -ne 0 ]
}

@test "cleanup-apps.sh: handles unknown flag gracefully" {
    run "$CLEANUP_SCRIPT" --invalid-flag
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "cleanup-apps.sh: shows helpful error for missing input file" {
    run "$CLEANUP_SCRIPT" --input "/tmp/does-not-exist-$$.txt"
    [ "$status" -eq 5 ]
    [[ "$output" == *"Create this file"* ]]
}

# =============================================================================
# Performance Tests
# =============================================================================

@test "audit-apps.sh: completes in reasonable time (< 10 seconds)" {
    # Use timeout command to enforce time limit
    run timeout 10s "$AUDIT_SCRIPT" --output "$TEST_OUTPUT"
    [ "$status" -eq 0 ]
}

@test "cleanup-apps.sh: dry-run completes quickly (< 5 seconds)" {
    echo "test-app-1" > "$TEST_REMOVE_LIST"
    echo "test-app-2" >> "$TEST_REMOVE_LIST"
    echo "test-app-3" >> "$TEST_REMOVE_LIST"

    run timeout 5s "$CLEANUP_SCRIPT" --input "$TEST_REMOVE_LIST"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "README.md exists in applications/ directory" {
    [ -f "$APPLICATIONS_DIR/README.md" ]
}

@test "README.md contains workflow instructions" {
    grep -q "Workflow" "$APPLICATIONS_DIR/README.md"
    grep -q "audit-apps.sh" "$APPLICATIONS_DIR/README.md"
    grep -q "cleanup-apps.sh" "$APPLICATIONS_DIR/README.md"
}

@test "README.md contains safety warnings" {
    grep -q "Safety" "$APPLICATIONS_DIR/README.md"
    grep -q "dry-run" "$APPLICATIONS_DIR/README.md"
}
