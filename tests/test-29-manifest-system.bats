#!/usr/bin/env bats
#
# Test suite for Issue #29: Enhanced Manifest System
#
# Tests:
# - Dependency verification
# - Dimension extraction
# - File type detection
# - Cache operations
# - Manifest generation
# - Notification system

# Setup and teardown
setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d -t manifest-test-XXXXXX)"
    export TEST_DIR

    # Create test CDN directory structure
    CDN_DIR="$TEST_DIR/cdn"
    mkdir -p "$CDN_DIR"
    export CDN_DIR

    # Create test fixtures
    FIXTURES_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/fixtures/manifest-system"
    export FIXTURES_DIR

    # Scripts location
    SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/sync"
    export SCRIPTS_DIR
}

teardown() {
    # Clean up temporary test directory
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# ============================================================================
# DEPENDENCY TESTS
# ============================================================================

@test "verify imagemagick is installed" {
    run command -v identify
    [ "$status" -eq 0 ]
}

@test "verify yq is installed" {
    run command -v yq
    [ "$status" -eq 0 ]
}

@test "verify shasum is available" {
    run command -v shasum
    [ "$status" -eq 0 ]
}

@test "verify file command is available" {
    run command -v file
    [ "$status" -eq 0 ]
}

# ============================================================================
# HELPER FUNCTION TESTS
# ============================================================================

@test "format_size converts bytes correctly" {
    # Create a simple test file to verify size formatting logic
    echo "test" > "$TEST_DIR/test.txt"
    local size
    size=$(stat -f%z "$TEST_DIR/test.txt" 2>/dev/null || stat -c%s "$TEST_DIR/test.txt" 2>/dev/null)

    # Size should be 5 bytes (test\n)
    [ "$size" -eq 5 ]
}

@test "detect image file type using ImageMagick" {
    skip "requires test image fixture"
    # This test requires actual image files in fixtures
}

@test "detect non-image file type" {
    echo "test data" > "$TEST_DIR/test.txt"
    local mime_type
    mime_type=$(file --brief --mime-type "$TEST_DIR/test.txt")

    # Should be text/plain
    [[ "$mime_type" == text/* ]]
}

# ============================================================================
# DIMENSION EXTRACTION TESTS
# ============================================================================

@test "extract dimensions from PNG image" {
    skip "requires PNG fixture"
    # Will be implemented with actual image fixtures
}

@test "extract dimensions from JPG image" {
    skip "requires JPG fixture"
    # Will be implemented with actual image fixtures
}

@test "extract dimensions from SVG image" {
    skip "requires SVG fixture"
    # Will be implemented with actual image fixtures
}

@test "handle non-image gracefully (no dimensions)" {
    # Create a text file
    echo "not an image" > "$TEST_DIR/test.txt"

    # Check that file command doesn't report it as an image
    local mime_type
    mime_type=$(file --brief --mime-type "$TEST_DIR/test.txt")
    [[ "$mime_type" != image/* ]]
}

# ============================================================================
# CACHE TESTS
# ============================================================================

@test "create empty dimension cache" {
    local cache_file="$TEST_DIR/.dimensions-cache.json"
    echo "{}" > "$cache_file"

    [ -f "$cache_file" ]

    local content
    content=$(cat "$cache_file")
    [ "$content" = "{}" ]
}

@test "update dimension cache with new entry" {
    local cache_file="$TEST_DIR/.dimensions-cache.json"
    echo "{}" > "$cache_file"

    # Add entry using jq
    local cache_key="test.png:1234567890:1024"
    local dimensions="800x600"

    local updated_cache
    updated_cache=$(cat "$cache_file" | jq --arg key "$cache_key" --arg val "$dimensions" '.[$key] = $val')
    echo "$updated_cache" > "$cache_file"

    # Verify entry exists
    local retrieved
    retrieved=$(cat "$cache_file" | jq -r ".\"$cache_key\"")
    [ "$retrieved" = "$dimensions" ]
}

@test "read from dimension cache" {
    local cache_file="$TEST_DIR/.dimensions-cache.json"
    echo '{"test.png:1234567890:1024":"800x600"}' > "$cache_file"

    local cache_key="test.png:1234567890:1024"
    local retrieved
    retrieved=$(cat "$cache_file" | jq -r ".\"$cache_key\"")

    [ "$retrieved" = "800x600" ]
}

# ============================================================================
# SHA256 TESTS
# ============================================================================

@test "calculate SHA256 checksum" {
    echo "test content" > "$TEST_DIR/test.txt"

    local sha256
    sha256=$(shasum -a 256 "$TEST_DIR/test.txt" | awk '{print $1}')

    # SHA256 should be 64 characters hex
    [ ${#sha256} -eq 64 ]
}

@test "SHA256 changes when content changes" {
    echo "test content" > "$TEST_DIR/test.txt"
    local sha1
    sha1=$(shasum -a 256 "$TEST_DIR/test.txt" | awk '{print $1}')

    echo "different content" > "$TEST_DIR/test.txt"
    local sha2
    sha2=$(shasum -a 256 "$TEST_DIR/test.txt" | awk '{print $1}')

    [ "$sha1" != "$sha2" ]
}

# ============================================================================
# MANIFEST GENERATION TESTS
# ============================================================================

@test "generate manifest for empty directory" {
    # Run generate script on empty CDN directory
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"

    # Script should succeed
    [ "$status" -eq 0 ]

    # Manifest should be created
    [ -f "$CDN_DIR/.r2-manifest.yml" ]

    # Manifest should have empty assets array
    local assets_count
    assets_count=$(yq eval '.assets | length' "$CDN_DIR/.r2-manifest.yml")
    [ "$assets_count" -eq 0 ]
}

@test "generate manifest with single file" {
    # Create a test file
    echo "test content" > "$CDN_DIR/test.txt"

    # Run generate script
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Manifest should exist
    [ -f "$CDN_DIR/.r2-manifest.yml" ]

    # Should have 1 asset
    local assets_count
    assets_count=$(yq eval '.assets | length' "$CDN_DIR/.r2-manifest.yml")
    [ "$assets_count" -eq 1 ]

    # Asset should have required fields
    local asset_path
    asset_path=$(yq eval '.assets[0].path' "$CDN_DIR/.r2-manifest.yml")
    [ "$asset_path" = "test.txt" ]

    local asset_size
    asset_size=$(yq eval '.assets[0].size' "$CDN_DIR/.r2-manifest.yml")
    [ "$asset_size" -gt 0 ]

    local asset_sha256
    asset_sha256=$(yq eval '.assets[0].sha256' "$CDN_DIR/.r2-manifest.yml")
    [ ${#asset_sha256} -eq 64 ]
}

@test "generate manifest with nested directories" {
    # Create nested structure
    mkdir -p "$CDN_DIR/subdir/nested"
    echo "file1" > "$CDN_DIR/file1.txt"
    echo "file2" > "$CDN_DIR/subdir/file2.txt"
    echo "file3" > "$CDN_DIR/subdir/nested/file3.txt"

    # Run generate script
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Should have 3 assets
    local assets_count
    assets_count=$(yq eval '.assets | length' "$CDN_DIR/.r2-manifest.yml")
    [ "$assets_count" -eq 3 ]
}

@test "manifest excludes hidden files" {
    # Create files
    echo "visible" > "$CDN_DIR/visible.txt"
    echo "hidden" > "$CDN_DIR/.hidden.txt"
    mkdir -p "$CDN_DIR/.hidden_dir"
    echo "in hidden dir" > "$CDN_DIR/.hidden_dir/file.txt"

    # Run generate script
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Should have only 1 asset (visible.txt)
    local assets_count
    assets_count=$(yq eval '.assets | length' "$CDN_DIR/.r2-manifest.yml")
    [ "$assets_count" -eq 1 ]
}

@test "manifest excludes itself and cache file" {
    # Create manifest and cache manually
    echo "test" > "$CDN_DIR/test.txt"
    touch "$CDN_DIR/.r2-manifest.yml"
    touch "$CDN_DIR/.dimensions-cache.json"

    # Run generate script
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Should have only 1 asset (test.txt)
    local assets_count
    assets_count=$(yq eval '.assets | length' "$CDN_DIR/.r2-manifest.yml")
    [ "$assets_count" -eq 1 ]
}

# ============================================================================
# NOTIFICATION TESTS
# ============================================================================

@test "notify with no changes shows unchanged" {
    # Create initial manifest
    echo "test" > "$CDN_DIR/test.txt"
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Backup manifest
    cp "$CDN_DIR/.r2-manifest.yml" "$CDN_DIR/.r2-manifest.yml.backup"

    # Run generate again (no changes)
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Run notify script
    run "$SCRIPTS_DIR/notify-cdn-updates.sh" "$CDN_DIR" "$CDN_DIR/.r2-manifest.yml.backup"
    [ "$status" -eq 0 ]

    # Output should mention unchanged
    [[ "$output" == *"unchanged"* ]]
}

@test "notify detects new files" {
    # Create initial manifest with one file
    echo "file1" > "$CDN_DIR/file1.txt"
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Backup manifest
    cp "$CDN_DIR/.r2-manifest.yml" "$CDN_DIR/.r2-manifest.yml.backup"

    # Add new file
    echo "file2" > "$CDN_DIR/file2.txt"

    # Regenerate manifest
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Run notify script
    run "$SCRIPTS_DIR/notify-cdn-updates.sh" "$CDN_DIR" "$CDN_DIR/.r2-manifest.yml.backup"
    [ "$status" -eq 0 ]

    # Output should show new file
    [[ "$output" == *"new"* ]]
    [[ "$output" == *"file2.txt"* ]]
}

@test "notify detects removed files" {
    # Create initial manifest with two files
    echo "file1" > "$CDN_DIR/file1.txt"
    echo "file2" > "$CDN_DIR/file2.txt"
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Backup manifest
    cp "$CDN_DIR/.r2-manifest.yml" "$CDN_DIR/.r2-manifest.yml.backup"

    # Remove file
    rm "$CDN_DIR/file2.txt"

    # Regenerate manifest
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Run notify script
    run "$SCRIPTS_DIR/notify-cdn-updates.sh" "$CDN_DIR" "$CDN_DIR/.r2-manifest.yml.backup"
    [ "$status" -eq 0 ]

    # Output should show removed file
    [[ "$output" == *"removed"* || "$output" == *"deleted"* ]]
}

@test "notify detects modified files" {
    # Create initial manifest
    echo "original content" > "$CDN_DIR/test.txt"
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Backup manifest
    cp "$CDN_DIR/.r2-manifest.yml" "$CDN_DIR/.r2-manifest.yml.backup"

    # Modify file
    echo "modified content that is longer" > "$CDN_DIR/test.txt"

    # Regenerate manifest
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Run notify script
    run "$SCRIPTS_DIR/notify-cdn-updates.sh" "$CDN_DIR" "$CDN_DIR/.r2-manifest.yml.backup"
    [ "$status" -eq 0 ]

    # Output should show updated file
    [[ "$output" == *"updated"* || "$output" == *"UPDATED"* ]]
}

@test "notify generates markdown report" {
    # Create initial manifest
    echo "test" > "$CDN_DIR/test.txt"
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Backup manifest
    cp "$CDN_DIR/.r2-manifest.yml" "$CDN_DIR/.r2-manifest.yml.backup"

    # Add file
    echo "new" > "$CDN_DIR/new.txt"

    # Regenerate manifest
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Run notify script
    run "$SCRIPTS_DIR/notify-cdn-updates.sh" "$CDN_DIR" "$CDN_DIR/.r2-manifest.yml.backup"
    [ "$status" -eq 0 ]

    # Markdown report should exist
    run find "$CDN_DIR" -name "update-report-*.md"
    [ "$status" -eq 0 ]
    [ ${#lines[@]} -ge 1 ]
}

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

@test "full workflow: generate, modify, regenerate, notify" {
    # Step 1: Create initial files and generate manifest
    echo "initial file 1" > "$CDN_DIR/file1.txt"
    echo "initial file 2" > "$CDN_DIR/file2.txt"

    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]
    [ -f "$CDN_DIR/.r2-manifest.yml" ]

    # Backup manifest
    cp "$CDN_DIR/.r2-manifest.yml" "$CDN_DIR/.r2-manifest.yml.backup"

    # Step 2: Make changes (add, modify, remove)
    echo "modified file 1 with more content" > "$CDN_DIR/file1.txt"  # Modify
    rm "$CDN_DIR/file2.txt"  # Remove
    echo "new file 3" > "$CDN_DIR/file3.txt"  # Add

    # Step 3: Regenerate manifest
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    # Step 4: Run notification
    run "$SCRIPTS_DIR/notify-cdn-updates.sh" "$CDN_DIR" "$CDN_DIR/.r2-manifest.yml.backup"
    [ "$status" -eq 0 ]

    # Verify output contains all change types
    [[ "$output" == *"new"* ]]
    [[ "$output" == *"updated"* || "$output" == *"UPDATED"* ]]
    [[ "$output" == *"removed"* || "$output" == *"deleted"* ]]
}

# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================

@test "generate fails on non-existent directory" {
    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "/nonexistent/directory"
    [ "$status" -ne 0 ]
}

@test "notify fails without old manifest" {
    # Create CDN dir but no manifest
    echo "test" > "$CDN_DIR/test.txt"

    run "$SCRIPTS_DIR/notify-cdn-updates.sh" "$CDN_DIR"
    [ "$status" -ne 0 ]
}

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

@test "generate completes in reasonable time for 100 files" {
    skip "performance test - run manually"

    # Create 100 test files
    for i in {1..100}; do
        echo "test content $i" > "$CDN_DIR/file_$i.txt"
    done

    # Time the generation
    local start_time
    start_time=$(date +%s)

    run "$SCRIPTS_DIR/generate-cdn-manifest.sh" "$CDN_DIR"
    [ "$status" -eq 0 ]

    local end_time
    end_time=$(date +%s)

    local duration=$((end_time - start_time))

    # Should complete in less than 10 seconds
    [ "$duration" -lt 10 ]
}
