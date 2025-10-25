#!/usr/bin/env bats
#
# Test suite for Issue #18: Auto-Update Dotfiles Mechanism
#
# Tests:
# - auto-update-dotfiles.sh workflow
# - install-autoupdate.sh platform-specific installation
# - LaunchAgent and systemd configuration
# - Error handling and edge cases

# Setup and teardown
setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d -t autoupdate-test-XXXXXX)"
    export TEST_DIR

    # Create mock git repository
    GIT_REPO="$TEST_DIR/dotfiles"
    mkdir -p "$GIT_REPO/scripts/sync"
    mkdir -p "$GIT_REPO/scripts/utils"
    mkdir -p "$GIT_REPO/system/macos/launch-agents"
    mkdir -p "$GIT_REPO/system/ubuntu/systemd"
    export GIT_REPO

    # Scripts location
    SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts"
    export SCRIPTS_DIR

    # Copy utility scripts to test repo
    cp "$SCRIPTS_DIR/utils/logger.sh" "$GIT_REPO/scripts/utils/"
    cp "$SCRIPTS_DIR/utils/detect-os.sh" "$GIT_REPO/scripts/utils/"

    # Initialize mock git repo
    cd "$GIT_REPO"
    git init --initial-branch=main > /dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create initial commit (include all setup files)
    echo "# Test Repo" > README.md
    git add -A
    git commit -m "Initial commit" > /dev/null 2>&1
}

teardown() {
    # Clean up temporary test directory
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

create_auto_update_script() {
    cat > "$GIT_REPO/scripts/sync/auto-update-dotfiles.sh" <<'EOF'
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/logger.sh"

cd "$DOTFILES_DIR"

log_info "Checking for dotfiles changes..."

# Check if there are changes
if [ -z "$(git status --porcelain)" ]; then
    log_info "No changes detected"
    exit 0
fi

# Show changes
log_info "Detected changes:"
git status --short

# Check if we're on main branch
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
    log_warning "Not on main branch (current: $BRANCH), skipping auto-update"
    exit 0
fi

# Commit and push
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname -s)

log_info "Committing changes..."
git add -A
git commit -m "chore: auto-update dotfiles from $HOSTNAME - $TIMESTAMP"

log_info "Pushing to GitHub..."
if git push origin main 2>/dev/null; then
    log_success "Dotfiles auto-updated and pushed!"
else
    log_error "Failed to push to GitHub"
    exit 1
fi
EOF
    chmod +x "$GIT_REPO/scripts/sync/auto-update-dotfiles.sh"
}

# ============================================================================
# TESTS: auto-update-dotfiles.sh
# ============================================================================

@test "auto-update-dotfiles.sh: exits early with no changes" {
    create_auto_update_script

    cd "$GIT_REPO"
    # Commit the script so it's not seen as a change
    git add -A
    git commit -m "Add auto-update script" > /dev/null 2>&1

    run "$GIT_REPO/scripts/sync/auto-update-dotfiles.sh"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "No changes detected" ]]
}

@test "auto-update-dotfiles.sh: detects changes and commits on main branch" {
    create_auto_update_script

    cd "$GIT_REPO"
    echo "# New content" >> README.md

    run "$GIT_REPO/scripts/sync/auto-update-dotfiles.sh"

    [ "$status" -eq 1 ]  # Will fail on push (no remote)
    [[ "$output" =~ "Detected changes" ]]
    [[ "$output" =~ "Committing changes" ]]
}

@test "auto-update-dotfiles.sh: skips auto-update on non-main branch" {
    create_auto_update_script

    cd "$GIT_REPO"
    git checkout -b feature-branch > /dev/null 2>&1
    echo "# New content" >> README.md

    run "$GIT_REPO/scripts/sync/auto-update-dotfiles.sh"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Not on main branch" ]]
    [[ "$output" =~ "skipping auto-update" ]]
}

@test "auto-update-dotfiles.sh: script exists and is executable" {
    SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/sync/auto-update-dotfiles.sh"

    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

# ============================================================================
# TESTS: Configuration Files
# ============================================================================

@test "macOS LaunchAgent plist exists and is valid" {
    PLIST="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/system/macos/launch-agents/com.dotfiles.autoupdate.plist"

    [ -f "$PLIST" ]

    # Check for key elements
    grep -q "com.dotfiles.autoupdate" "$PLIST"
    grep -q "StartInterval" "$PLIST"
    grep -q "1800" "$PLIST"
    grep -q "auto-update-dotfiles.sh" "$PLIST"
}

@test "Ubuntu systemd service exists and is valid" {
    SERVICE="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/system/ubuntu/systemd/dotfiles-autoupdate.service"

    [ -f "$SERVICE" ]

    # Check for key elements
    grep -q "Auto-update dotfiles to GitHub" "$SERVICE"
    grep -q "Type=oneshot" "$SERVICE"
    grep -q "auto-update-dotfiles.sh" "$SERVICE"
}

@test "Ubuntu systemd timer exists and is valid" {
    TIMER="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/system/ubuntu/systemd/dotfiles-autoupdate.timer"

    [ -f "$TIMER" ]

    # Check for key elements
    grep -q "OnBootSec=5min" "$TIMER"
    grep -q "OnUnitActiveSec=30min" "$TIMER"
    grep -q "Persistent=true" "$TIMER"
}

# ============================================================================
# TESTS: install-autoupdate.sh
# ============================================================================

@test "install-autoupdate.sh: script exists and is executable" {
    SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/sync/install-autoupdate.sh"

    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "install-autoupdate.sh: sources required utilities" {
    SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/sync/install-autoupdate.sh"

    # Check that it sources detect-os.sh and logger.sh
    grep -q "detect-os.sh" "$SCRIPT"
    grep -q "logger.sh" "$SCRIPT"
}

@test "install-autoupdate.sh: handles macOS platform" {
    SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/sync/install-autoupdate.sh"

    # Check for macOS-specific logic
    grep -q "macos)" "$SCRIPT"
    grep -q "LaunchAgent" "$SCRIPT"
    grep -q "launchctl load" "$SCRIPT"
}

@test "install-autoupdate.sh: handles Ubuntu platform" {
    SCRIPT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/sync/install-autoupdate.sh"

    # Check for Ubuntu-specific logic
    grep -q "ubuntu)" "$SCRIPT"
    grep -q "systemd" "$SCRIPT"
    grep -q "systemctl enable" "$SCRIPT"
}

# ============================================================================
# TESTS: Integration
# ============================================================================

@test "all required files exist in correct locations" {
    BASE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

    # Scripts
    [ -f "$BASE_DIR/scripts/sync/auto-update-dotfiles.sh" ]
    [ -f "$BASE_DIR/scripts/sync/install-autoupdate.sh" ]

    # macOS
    [ -f "$BASE_DIR/system/macos/launch-agents/com.dotfiles.autoupdate.plist" ]

    # Ubuntu
    [ -f "$BASE_DIR/system/ubuntu/systemd/dotfiles-autoupdate.service" ]
    [ -f "$BASE_DIR/system/ubuntu/systemd/dotfiles-autoupdate.timer" ]
}

@test "scripts have correct permissions" {
    BASE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

    [ -x "$BASE_DIR/scripts/sync/auto-update-dotfiles.sh" ]
    [ -x "$BASE_DIR/scripts/sync/install-autoupdate.sh" ]
}
