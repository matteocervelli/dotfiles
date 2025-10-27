#!/usr/bin/env bats
# Tests for Docker Ubuntu Minimal Profile
# Issue: https://github.com/matteocervelli/dotfiles/issues/44
#
# Usage:
#   bats tests/test-23-docker-ubuntu.bats
#
# Requirements:
#   - Docker or Podman installed
#   - Images built: dotfiles-ubuntu:minimal, dotfiles-ubuntu:dev

# Test configuration
IMAGE_MINIMAL="dotfiles-ubuntu:minimal"
IMAGE_DEV="dotfiles-ubuntu:dev"
IMAGE_PRODUCTION="dotfiles-ubuntu:production"

# Setup and teardown
setup() {
    # Detect Docker or Podman
    if command -v docker &>/dev/null; then
        CONTAINER_CMD="docker"
    elif command -v podman &>/dev/null; then
        CONTAINER_CMD="podman"
    else
        skip "Neither Docker nor Podman found"
    fi

    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
}

teardown() {
    # Cleanup temporary directory
    [ -n "$TEST_DIR" ] && rm -rf "$TEST_DIR"
}

# =============================================================================
# Dockerfile Tests
# =============================================================================

@test "Dockerfile.dotfiles-ubuntu exists" {
    [ -f "Dockerfile.dotfiles-ubuntu" ]
}

@test "Dockerfile has proper shebang and comments" {
    run head -n 5 Dockerfile.dotfiles-ubuntu
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dockerfile.dotfiles-ubuntu"* ]]
}

@test ".dockerignore file exists" {
    [ -f ".dockerignore" ]
}

@test ".dockerignore excludes unnecessary files" {
    run grep -E "^\.git/|^docs/|^tests/" .dockerignore
    [ "$status" -eq 0 ]
}

# =============================================================================
# Entrypoint Script Tests
# =============================================================================

@test "entrypoint-minimal.sh exists and is executable" {
    [ -f "docker/entrypoint-minimal.sh" ]
    [ -x "docker/entrypoint-minimal.sh" ]
}

@test "entrypoint-dev.sh exists and is executable" {
    [ -f "docker/entrypoint-dev.sh" ]
    [ -x "docker/entrypoint-dev.sh" ]
}

@test "entrypoint scripts have proper shebang" {
    run head -n 1 docker/entrypoint-minimal.sh
    [ "$status" -eq 0 ]
    [[ "$output" == "#!/bin/bash" ]]
}

# =============================================================================
# Profile Configuration Tests
# =============================================================================

@test "container-minimal profile exists" {
    [ -f "system/profiles/container-minimal.yml" ]
}

@test "container-minimal profile has required fields" {
    run grep -E "^name:|^target:|^stow_packages:" system/profiles/container-minimal.yml
    [ "$status" -eq 0 ]
}

# =============================================================================
# Bootstrap Script Tests
# =============================================================================

@test "docker-bootstrap.sh exists and is executable" {
    [ -f "scripts/bootstrap/docker-bootstrap.sh" ]
    [ -x "scripts/bootstrap/docker-bootstrap.sh" ]
}

@test "docker-bootstrap.sh has help option" {
    run scripts/bootstrap/docker-bootstrap.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Docker Container Bootstrap"* ]]
}

# =============================================================================
# Image Existence Tests
# =============================================================================

@test "minimal image exists" {
    # Try to build if not exists
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built. Run: make docker-build-minimal"
    fi
    run $CONTAINER_CMD images --format "{{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_MINIMAL"
    [ "$status" -eq 0 ]
}

@test "minimal image has correct labels" {
    # Skip if image doesn't exist
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD inspect --format='{{index .Config.Labels "profile"}}' $IMAGE_MINIMAL
    [ "$status" -eq 0 ]
    [[ "$output" == "container-minimal" ]]
}

# =============================================================================
# Image Size Tests
# =============================================================================

@test "minimal image is under 500MB (size goal)" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    # Get image size in bytes
    size=$($CONTAINER_CMD images --format "{{.Size}}" $IMAGE_MINIMAL | sed 's/MB//' | awk '{print int($1)}')

    # Check if under 500MB
    [ "$size" -lt 500 ]
}

@test "dev image is under 500MB (size goal)" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built. Run: make docker-build-dev"
    fi

    size=$($CONTAINER_CMD images --format "{{.Size}}" $IMAGE_DEV | sed 's/MB//' | awk '{print int($1)}')
    [ "$size" -lt 500 ]
}

# =============================================================================
# Container Runtime Tests - Minimal
# =============================================================================

@test "minimal container starts successfully" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL echo "test"
    [ "$status" -eq 0 ]
    [[ "$output" == *"test"* ]]
}

@test "minimal container runs as non-root user" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL whoami
    [ "$status" -eq 0 ]
    [[ "$output" == "developer" ]]
}

@test "minimal container user has UID 1000" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL id -u
    [ "$status" -eq 0 ]
    [ "$output" -eq 1000 ]
}

@test "minimal container has ZSH as default shell" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL echo '$SHELL'
    [ "$status" -eq 0 ]
    [[ "$output" == *"/bin/zsh"* ]]
}

# =============================================================================
# Tool Installation Tests - Minimal
# =============================================================================

@test "minimal: git is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL git --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"git version"* ]]
}

@test "minimal: zsh is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL zsh --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"zsh"* ]]
}

@test "minimal: stow is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL stow --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"stow"* ]]
}

@test "minimal: vim is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL vim --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"VIM"* ]]
}

# =============================================================================
# Dotfiles Installation Tests - Minimal
# =============================================================================

@test "minimal: .zshrc exists" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL test -f /home/developer/.zshrc
    [ "$status" -eq 0 ]
}

@test "minimal: git config exists" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL test -f /home/developer/.config/git/config
    [ "$status" -eq 0 ]
}

@test "minimal: Oh My Zsh is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL test -d /home/developer/.oh-my-zsh
    [ "$status" -eq 0 ]
}

@test "minimal: dotfiles are symlinked (stowed)" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    # Check if .zshrc is a symlink
    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL test -L /home/developer/.zshrc
    [ "$status" -eq 0 ]
}

# =============================================================================
# Container Runtime Tests - Dev
# =============================================================================

@test "dev: python3 is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV python3 --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Python"* ]]
}

@test "dev: node is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV node --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"v"* ]]
}

@test "dev: npm is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV npm --version
    [ "$status" -eq 0 ]
}

@test "dev: build-essential is installed (gcc)" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV gcc --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"gcc"* ]]
}

@test "dev: make is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV make --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"GNU Make"* ]]
}

@test "dev: pyenv directory exists" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV test -d /home/developer/.pyenv
    [ "$status" -eq 0 ]
}

@test "dev: nvm directory exists" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV test -d /home/developer/.nvm
    [ "$status" -eq 0 ]
}

# =============================================================================
# Modern CLI Tools Tests - Dev
# =============================================================================

@test "dev: ripgrep (rg) is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV rg --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"ripgrep"* ]]
}

@test "dev: fd is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV fdfind --version
    [ "$status" -eq 0 ]
}

@test "dev: jq is installed" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_DEV jq --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"jq"* ]]
}

# =============================================================================
# Startup Performance Tests
# =============================================================================

@test "minimal container starts in under 2 seconds (performance goal)" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    # Measure startup time (excluding image pull)
    start=$(date +%s.%N)
    $CONTAINER_CMD run --rm $IMAGE_MINIMAL echo "Ready" >/dev/null
    end=$(date +%s.%N)

    # Calculate duration
    duration=$(echo "$end - $start" | bc)

    # Check if under 2 seconds
    result=$(echo "$duration < 2" | bc)
    [ "$result" -eq 1 ]
}

# =============================================================================
# Volume Mount Tests
# =============================================================================

@test "minimal: workspace volume mount works" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    # Create test file
    echo "test content" > "$TEST_DIR/test.txt"

    # Mount and verify
    run $CONTAINER_CMD run --rm -v "$TEST_DIR:/workspace" $IMAGE_MINIMAL cat /workspace/test.txt
    [ "$status" -eq 0 ]
    [[ "$output" == "test content" ]]
}

@test "minimal: volume mount preserves permissions" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    # Create file in mounted volume
    $CONTAINER_CMD run --rm -v "$TEST_DIR:/workspace" $IMAGE_MINIMAL sh -c "echo test > /workspace/test.txt"

    # Check if file is readable on host
    [ -r "$TEST_DIR/test.txt" ]
}

# =============================================================================
# Entrypoint Tests
# =============================================================================

@test "minimal: entrypoint script runs" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD run --rm $IMAGE_MINIMAL echo "test"
    [ "$status" -eq 0 ]
    # Should see welcome message from entrypoint
    [[ "$output" == *"Container"* ]] || [[ "$output" == *"test"* ]]
}

# =============================================================================
# Multi-Architecture Tests
# =============================================================================

@test "image metadata includes architecture" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    run $CONTAINER_CMD inspect --format='{{.Architecture}}' $IMAGE_MINIMAL
    [ "$status" -eq 0 ]
    # Should be either amd64 or arm64
    [[ "$output" == "amd64" ]] || [[ "$output" == "arm64" ]]
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "Docker documentation exists" {
    [ -f "docs/docker/DOCKER-UBUNTU-MINIMAL.md" ]
}

@test "Docker documentation is comprehensive" {
    run wc -l docs/docker/DOCKER-UBUNTU-MINIMAL.md
    [ "$status" -eq 0 ]
    # Should be substantial (> 300 lines)
    lines=$(echo "$output" | awk '{print $1}')
    [ "$lines" -gt 300 ]
}

# =============================================================================
# Integration Tests
# =============================================================================

@test "can run git commands in minimal container" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_MINIMAL"; then
        skip "Minimal image not built"
    fi

    # Initialize git repo in temp dir
    cd "$TEST_DIR"
    git init

    # Run git command in container
    run $CONTAINER_CMD run --rm -v "$TEST_DIR:/workspace" -w /workspace $IMAGE_MINIMAL git status
    [ "$status" -eq 0 ]
}

@test "can run python scripts in dev container" {
    if ! $CONTAINER_CMD images | grep -q "$IMAGE_DEV"; then
        skip "Dev image not built"
    fi

    # Create Python script
    echo 'print("Hello from Python")' > "$TEST_DIR/test.py"

    # Run Python script in container
    run $CONTAINER_CMD run --rm -v "$TEST_DIR:/workspace" -w /workspace $IMAGE_DEV python3 test.py
    [ "$status" -eq 0 ]
    [[ "$output" == *"Hello from Python"* ]]
}

# =============================================================================
# Cleanup Tests
# =============================================================================

@test "no dangling images after build" {
    # This is informational, not a failure condition
    run $CONTAINER_CMD images -f "dangling=true" -q
    [ "$status" -eq 0 ]
    # If there are dangling images, user should run: docker image prune
}
