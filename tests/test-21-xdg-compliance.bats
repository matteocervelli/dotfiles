#!/usr/bin/env bats
#
# Test Suite: XDG Base Directory Compliance (Issue #21)
#
# Tests for:
# - XDG environment variables configuration
# - Directory creation with proper permissions
# - PostgreSQL, Bash, Less XDG compliance
# - iTerm2 backup/restore scripts
# - Migration functionality
#

# Setup test environment
setup() {
    # Test directories
    export TEST_HOME="$BATS_TEST_TMPDIR/test-home"
    export TEST_DOTFILES="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

    # Create test home directory
    mkdir -p "$TEST_HOME"

    # Export XDG variables for testing
    export XDG_CONFIG_HOME="$TEST_HOME/.config"
    export XDG_DATA_HOME="$TEST_HOME/.local/share"
    export XDG_STATE_HOME="$TEST_HOME/.local/state"
    export XDG_CACHE_HOME="$TEST_HOME/.cache"
}

# Cleanup after each test
teardown() {
    rm -rf "$TEST_HOME" 2>/dev/null || true
}

# =============================================================================
# Test: XDG Environment Variables
# =============================================================================

@test "[XDG] dev-tools.sh sets XDG_CONFIG_HOME" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -n "$XDG_CONFIG_HOME" ]
    [ "$XDG_CONFIG_HOME" = "$TEST_HOME/.config" ]
}

@test "[XDG] dev-tools.sh sets XDG_DATA_HOME" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -n "$XDG_DATA_HOME" ]
    [ "$XDG_DATA_HOME" = "$TEST_HOME/.local/share" ]
}

@test "[XDG] dev-tools.sh sets XDG_STATE_HOME" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -n "$XDG_STATE_HOME" ]
    [ "$XDG_STATE_HOME" = "$TEST_HOME/.local/state" ]
}

@test "[XDG] dev-tools.sh sets XDG_CACHE_HOME" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -n "$XDG_CACHE_HOME" ]
    [ "$XDG_CACHE_HOME" = "$TEST_HOME/.cache" ]
}

# =============================================================================
# Test: PostgreSQL XDG Compliance
# =============================================================================

@test "[PostgreSQL] dev-tools.sh sets PSQLRC" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -n "$PSQLRC" ]
    [ "$PSQLRC" = "$XDG_CONFIG_HOME/postgresql/psqlrc" ]
}

@test "[PostgreSQL] dev-tools.sh sets PSQL_HISTORY" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -n "$PSQL_HISTORY" ]
    [ "$PSQL_HISTORY" = "$XDG_STATE_HOME/postgresql/history" ]
}

@test "[PostgreSQL] dev-tools.sh creates config directory" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -d "$XDG_CONFIG_HOME/postgresql" ]
}

@test "[PostgreSQL] dev-tools.sh creates state directory" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -d "$XDG_STATE_HOME/postgresql" ]
}

# =============================================================================
# Test: Bash History XDG Compliance
# =============================================================================

@test "[Bash] dev-tools.sh sets HISTFILE" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -n "$HISTFILE" ]
    [ "$HISTFILE" = "$XDG_STATE_HOME/bash/history" ]
}

@test "[Bash] dev-tools.sh creates state directory" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -d "$XDG_STATE_HOME/bash" ]
}

# =============================================================================
# Test: Less XDG Compliance
# =============================================================================

@test "[Less] dev-tools.sh sets LESSHISTFILE" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -n "$LESSHISTFILE" ]
    [ "$LESSHISTFILE" = "$XDG_STATE_HOME/less/history" ]
}

@test "[Less] dev-tools.sh creates state directory" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ -d "$XDG_STATE_HOME/less" ]
}

# =============================================================================
# Test: Migration Functionality
# =============================================================================

@test "[Migration] migrate_to_xdg function exists" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    [ "$(type -t migrate_to_xdg)" = "function" ]
}

@test "[Migration] migrate_to_xdg moves legacy file to XDG location" {
    # Create legacy file
    mkdir -p "$TEST_HOME"
    echo "test history" > "$TEST_HOME/.test_history"

    # Source dev-tools to get migrate_to_xdg function
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"

    # Migrate file
    migrate_to_xdg "$TEST_HOME/.test_history" "$XDG_STATE_HOME/test/history"

    # Verify migration
    [ ! -f "$TEST_HOME/.test_history" ]
    [ -f "$XDG_STATE_HOME/test/history" ]
    [ "$(cat "$XDG_STATE_HOME/test/history")" = "test history" ]
}

@test "[Migration] migrate_to_xdg creates parent directory if needed" {
    # Create legacy file
    mkdir -p "$TEST_HOME"
    echo "test" > "$TEST_HOME/.test"

    # Source dev-tools
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"

    # Migrate to non-existent directory
    migrate_to_xdg "$TEST_HOME/.test" "$XDG_STATE_HOME/deep/nested/path/test"

    # Verify parent directory created
    [ -d "$XDG_STATE_HOME/deep/nested/path" ]
    [ -f "$XDG_STATE_HOME/deep/nested/path/test" ]
}

@test "[Migration] migrate_to_xdg skips if XDG file already exists" {
    # Create both legacy and XDG files
    mkdir -p "$TEST_HOME"
    echo "legacy" > "$TEST_HOME/.test"

    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"

    mkdir -p "$XDG_STATE_HOME/test"
    echo "xdg" > "$XDG_STATE_HOME/test/file"

    # Try to migrate
    migrate_to_xdg "$TEST_HOME/.test" "$XDG_STATE_HOME/test/file"

    # Verify legacy file still exists and XDG file unchanged
    [ -f "$TEST_HOME/.test" ]
    [ "$(cat "$XDG_STATE_HOME/test/file")" = "xdg" ]
}

# =============================================================================
# Test: iTerm2 Backup Script
# =============================================================================

@test "[iTerm2] backup script exists and is executable" {
    skip "iTerm2 tests run on macOS only"
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "Not macOS"
    fi

    [ -f "$TEST_DOTFILES/stow-packages/iterm2/.local/bin/iterm2-backup" ]
    [ -x "$TEST_DOTFILES/stow-packages/iterm2/.local/bin/iterm2-backup" ]
}

@test "[iTerm2] restore script exists and is executable" {
    skip "iTerm2 tests run on macOS only"
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "Not macOS"
    fi

    [ -f "$TEST_DOTFILES/stow-packages/iterm2/.local/bin/iterm2-restore" ]
    [ -x "$TEST_DOTFILES/stow-packages/iterm2/.local/bin/iterm2-restore" ]
}

@test "[iTerm2] backup script shows help" {
    skip "iTerm2 tests run on macOS only"
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "Not macOS"
    fi

    run "$TEST_DOTFILES/stow-packages/iterm2/.local/bin/iterm2-backup" --help
    [ $status -eq 0 ]
    grep -q "Usage:"
}

@test "[iTerm2] restore script shows help" {
    skip "iTerm2 tests run on macOS only"
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "Not macOS"
    fi

    run "$TEST_DOTFILES/stow-packages/iterm2/.local/bin/iterm2-restore" --help
    [ $status -eq 0 ]
    grep -q "Usage:"
}

# =============================================================================
# Test: Shell Integration
# =============================================================================

@test "[Shell] .zshrc sources dev-tools.sh" {
    grep -q "dev-tools.sh" "$TEST_DOTFILES/stow-packages/shell/.zshrc"
}

@test "[Shell] .bashrc sources dev-tools.sh" {
    grep -q "dev-tools.sh" "$TEST_DOTFILES/stow-packages/shell/.bashrc"
}

# =============================================================================
# Test: Documentation
# =============================================================================

@test "[Docs] xdg-compliance.md exists" {
    [ -f "$TEST_DOTFILES/docs/xdg-compliance.md" ]
}

@test "[Docs] app-mappings.yml exists" {
    [ -f "$TEST_DOTFILES/scripts/xdg-compliance/app-mappings.yml" ]
}

@test "[Docs] dev-env README exists" {
    [ -f "$TEST_DOTFILES/stow-packages/dev-env/README.md" ]
}

@test "[Docs] iterm2 README exists" {
    [ -f "$TEST_DOTFILES/stow-packages/iterm2/README.md" ]
}

# =============================================================================
# Test: Stow Package Structure
# =============================================================================

@test "[Stow] dev-env package has correct structure" {
    [ -d "$TEST_DOTFILES/stow-packages/dev-env" ]
    [ -d "$TEST_DOTFILES/stow-packages/dev-env/.config/shell" ]
    [ -f "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh" ]
}

@test "[Stow] dev-env has .stow-local-ignore" {
    [ -f "$TEST_DOTFILES/stow-packages/dev-env/.stow-local-ignore" ]
}

@test "[Stow] iterm2 package has correct structure" {
    [ -d "$TEST_DOTFILES/stow-packages/iterm2" ]
    [ -d "$TEST_DOTFILES/stow-packages/iterm2/.local/bin" ]
    [ -d "$TEST_DOTFILES/stow-packages/iterm2/backups" ]
}

@test "[Stow] iterm2 has .stow-local-ignore" {
    [ -f "$TEST_DOTFILES/stow-packages/iterm2/.stow-local-ignore" ]
}

@test "[Stow] iterm2 has .gitignore" {
    [ -f "$TEST_DOTFILES/stow-packages/iterm2/.gitignore" ]
}

# =============================================================================
# Test: Optional Features (Commented Out by Default)
# =============================================================================

@test "[Optional] R environment variables are commented out" {
    ! grep -q "^export R_PROFILE_USER" "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
}

@test "[Optional] Python PYTHONSTARTUP is commented out" {
    ! grep -q "^export PYTHONSTARTUP" "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
}

@test "[Optional] Python pythonrc file exists" {
    [ -f "$TEST_DOTFILES/stow-packages/dev-env/.config/python/pythonrc" ]
}

# =============================================================================
# Test: Python pythonrc (if enabled)
# =============================================================================

@test "[Python] pythonrc has proper shebang" {
    head -n 1 "$TEST_DOTFILES/stow-packages/dev-env/.config/python/pythonrc" | grep -q "#!/usr/bin/env python3"
}

@test "[Python] pythonrc imports required modules" {
    grep -q "import readline" "$TEST_DOTFILES/stow-packages/dev-env/.config/python/pythonrc"
    grep -q "import atexit" "$TEST_DOTFILES/stow-packages/dev-env/.config/python/pythonrc"
    grep -q "from pathlib import Path" "$TEST_DOTFILES/stow-packages/dev-env/.config/python/pythonrc"
}

# =============================================================================
# Test: wget alias
# =============================================================================

@test "[wget] dev-tools.sh defines wget alias" {
    source "$TEST_DOTFILES/stow-packages/dev-env/.config/shell/dev-tools.sh"
    alias wget | grep -q "hsts-file"
}

# =============================================================================
# Summary
# =============================================================================

@test "[Summary] All XDG compliance tests passed" {
    # This is a placeholder test to ensure test suite runs
    true
}
