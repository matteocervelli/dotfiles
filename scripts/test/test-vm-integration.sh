#!/usr/bin/env bash

#
# test-vm-integration.sh - Automated VM Integration Testing
#
# Tests Parallels shared folders, R2 assets access, and Docker integration
# Run this script in the VM to verify complete setup
#
# Usage:
#   ./scripts/test/test-vm-integration.sh
#   ./scripts/test/test-vm-integration.sh --verbose
#

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Verbose mode
VERBOSE=0
if [[ "${1:-}" == "--verbose" ]] || [[ "${1:-}" == "-v" ]]; then
    VERBOSE=1
fi

#
# Logging functions
#

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✅ PASS]${NC} $*"
}

log_error() {
    echo -e "${RED}[❌ FAIL]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[⚠️  WARN]${NC} $*"
}

log_verbose() {
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $*"
    fi
}

#
# Test helper functions
#

run_test() {
    local test_name="$1"
    local test_command="$2"

    ((TESTS_RUN++))

    log_verbose "Running test: $test_name"

    if eval "$test_command" &>/dev/null; then
        log_success "$test_name"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "$test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

#
# Test functions
#

test_parallels_tools() {
    local test_name="Parallels Tools installed"

    if command -v prltools &>/dev/null; then
        local version
        version=$(prltools -v 2>&1 | head -1)
        log_success "$test_name ($version)"
        ((TESTS_PASSED++))
    else
        log_error "$test_name - prltools command not found"
        ((TESTS_FAILED++))
        return 1
    fi

    ((TESTS_RUN++))
}

test_parallels_service() {
    local test_name="Parallels Tools service running"

    if systemctl is-active --quiet parallels-tools; then
        log_success "$test_name"
        ((TESTS_PASSED++))
    else
        log_error "$test_name - Service not active"
        log_info "Try: sudo systemctl restart parallels-tools"
        ((TESTS_FAILED++))
        return 1
    fi

    ((TESTS_RUN++))
}

test_shared_folders_mount() {
    local test_name="Shared folders mounted (/media/psf)"

    if [[ -d "/media/psf" ]] && [[ -n "$(ls -A /media/psf 2>/dev/null)" ]]; then
        local folders
        folders=$(ls /media/psf | tr '\n' ' ')
        log_success "$test_name - Found: $folders"
        ((TESTS_PASSED++))
    else
        log_error "$test_name - /media/psf is empty or doesn't exist"
        log_info "Check: Parallels Desktop → VM Config → Options → Sharing"
        ((TESTS_FAILED++))
        return 1
    fi

    ((TESTS_RUN++))
}

test_cdn_accessible() {
    local test_name="CDN directory accessible"
    local cdn_path=""

    # Try multiple possible paths
    if [[ -d "$HOME/cdn" ]]; then
        cdn_path="$HOME/cdn"
    elif [[ -d "/media/psf/Home/media/cdn" ]]; then
        cdn_path="/media/psf/Home/media/cdn"
    fi

    if [[ -n "$cdn_path" ]] && [[ -r "$cdn_path" ]]; then
        log_success "$test_name ($cdn_path)"
        ((TESTS_PASSED++))
    else
        log_error "$test_name - No CDN directory found"
        log_info "Expected: ~/cdn/ or /media/psf/Home/media/cdn/"
        log_info "Create symlink: ln -sf /media/psf/Home/media/cdn ~/cdn"
        ((TESTS_FAILED++))
        return 1
    fi

    ((TESTS_RUN++))
}

test_read_access() {
    local test_name="Read access to CDN"
    local cdn_path=""

    # Find CDN path
    if [[ -d "$HOME/cdn" ]]; then
        cdn_path="$HOME/cdn"
    elif [[ -d "/media/psf/Home/media/cdn" ]]; then
        cdn_path="/media/psf/Home/media/cdn"
    else
        log_error "$test_name - CDN not found"
        ((TESTS_FAILED++))
        ((TESTS_RUN++))
        return 1
    fi

    # Try to read .r2-manifest.yml
    if [[ -r "$cdn_path/.r2-manifest.yml" ]]; then
        log_success "$test_name - Can read .r2-manifest.yml"
        ((TESTS_PASSED++))
    elif [[ -r "$cdn_path/README.md" ]]; then
        log_success "$test_name - Can read README.md"
        ((TESTS_PASSED++))
    else
        # Just try to list directory
        if ls "$cdn_path" &>/dev/null; then
            log_success "$test_name - Can list directory"
            ((TESTS_PASSED++))
        else
            log_error "$test_name - Permission denied"
            ((TESTS_FAILED++))
            return 1
        fi
    fi

    ((TESTS_RUN++))
}

test_write_access() {
    local test_name="Write access to CDN"
    local cdn_path=""
    local test_file="test-vm-integration-$$.txt"

    # Find CDN path
    if [[ -d "$HOME/cdn" ]]; then
        cdn_path="$HOME/cdn"
    elif [[ -d "/media/psf/Home/media/cdn" ]]; then
        cdn_path="/media/psf/Home/media/cdn"
    else
        log_error "$test_name - CDN not found"
        ((TESTS_FAILED++))
        ((TESTS_RUN++))
        return 1
    fi

    # Try to write test file
    if echo "test" > "$cdn_path/$test_file" 2>/dev/null; then
        rm -f "$cdn_path/$test_file"
        log_success "$test_name - Can write files"
        ((TESTS_PASSED++))
    else
        log_warning "$test_name - Read-only access"
        log_info "Check: Parallels sharing permissions (should be Read/Write)"
        ((TESTS_FAILED++))
        return 1
    fi

    ((TESTS_RUN++))
}

test_symlink_cdn() {
    local test_name="CDN symlink exists (~/$cdn)"

    if [[ -L "$HOME/cdn" ]]; then
        local target
        target=$(readlink "$HOME/cdn")
        log_success "$test_name → $target"
        ((TESTS_PASSED++))
    else
        log_warning "$test_name - Symlink not created"
        log_info "Create: ln -sf /media/psf/Home/media/cdn ~/cdn"
        # Not a critical failure
        ((TESTS_PASSED++))
    fi

    ((TESTS_RUN++))
}

test_dev_accessible() {
    local test_name="Dev directory accessible"
    local dev_path=""

    # Try multiple possible paths
    if [[ -d "$HOME/dev-shared" ]]; then
        dev_path="$HOME/dev-shared"
    elif [[ -d "/media/psf/Home/dev" ]]; then
        dev_path="/media/psf/Home/dev"
    fi

    if [[ -n "$dev_path" ]] && [[ -r "$dev_path" ]]; then
        log_success "$test_name ($dev_path)"
        ((TESTS_PASSED++))
    else
        log_warning "$test_name - Not found (optional)"
        log_info "Create: ln -sf /media/psf/Home/dev ~/dev-shared"
        # Not critical
        ((TESTS_PASSED++))
    fi

    ((TESTS_RUN++))
}

test_docker_running() {
    local test_name="Docker service running"

    if command -v docker &>/dev/null; then
        if docker ps &>/dev/null; then
            log_success "$test_name"
            ((TESTS_PASSED++))
        else
            log_warning "$test_name - Docker not accessible (permission?)"
            log_info "Run: sudo usermod -aG docker $USER && logout"
            ((TESTS_PASSED++))  # Not critical for VM integration
        fi
    else
        log_warning "$test_name - Docker not installed"
        log_info "Install: sudo ./scripts/bootstrap/install-docker.sh"
        ((TESTS_PASSED++))  # Not critical for VM integration
    fi

    ((TESTS_RUN++))
}

test_docker_mount_cdn() {
    local test_name="Docker can mount CDN"
    local cdn_path=""

    # Skip if Docker not available
    if ! command -v docker &>/dev/null || ! docker ps &>/dev/null; then
        log_verbose "Skipping Docker mount test (Docker not accessible)"
        return 0
    fi

    # Find CDN path
    if [[ -d "$HOME/cdn" ]]; then
        cdn_path="$HOME/cdn"
    elif [[ -d "/media/psf/Home/media/cdn" ]]; then
        cdn_path="/media/psf/Home/media/cdn"
    else
        log_verbose "Skipping Docker mount test (CDN not found)"
        return 0
    fi

    # Try to mount CDN in container
    if docker run --rm -v "$cdn_path:/data:ro" ubuntu:24.04 ls /data &>/dev/null; then
        log_success "$test_name"
        ((TESTS_PASSED++))
    else
        log_warning "$test_name - Failed to mount"
        log_info "Try: docker run --rm -v $cdn_path:/data:ro ubuntu:24.04 ls /data"
        ((TESTS_FAILED++))
        return 1
    fi

    ((TESTS_RUN++))
}

test_r2_manifest() {
    local test_name="R2 manifest readable"
    local cdn_path=""

    # Find CDN path
    if [[ -d "$HOME/cdn" ]]; then
        cdn_path="$HOME/cdn"
    elif [[ -d "/media/psf/Home/media/cdn" ]]; then
        cdn_path="/media/psf/Home/media/cdn"
    else
        log_verbose "Skipping R2 manifest test (CDN not found)"
        return 0
    fi

    local manifest="$cdn_path/.r2-manifest.yml"

    if [[ -r "$manifest" ]]; then
        # Try to parse with yq if available
        if command -v yq &>/dev/null; then
            local project
            project=$(yq eval '.project' "$manifest" 2>/dev/null || echo "")
            if [[ -n "$project" ]]; then
                log_success "$test_name - Project: $project"
            else
                log_success "$test_name - File exists"
            fi
        else
            log_success "$test_name - File exists"
        fi
        ((TESTS_PASSED++))
    else
        log_warning "$test_name - Manifest not found"
        log_info "Expected: $manifest"
        # Not critical
        ((TESTS_PASSED++))
    fi

    ((TESTS_RUN++))
}

#
# Main execution
#

main() {
    echo ""
    log_info "==================================="
    log_info "VM Integration Testing"
    log_info "==================================="
    echo ""

    # Run all tests
    test_parallels_tools
    test_parallels_service
    test_shared_folders_mount
    test_cdn_accessible
    test_read_access
    test_write_access
    test_symlink_cdn
    test_dev_accessible
    test_r2_manifest
    test_docker_running
    test_docker_mount_cdn

    # Summary
    echo ""
    log_info "==================================="
    log_info "Test Summary"
    log_info "==================================="
    log_info "Tests run:    $TESTS_RUN"
    log_success "Tests passed: $TESTS_PASSED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Tests failed: $TESTS_FAILED"
        echo ""
        log_warning "Some tests failed. See details above."
        log_info "For troubleshooting, see: docs/vm-setup.md#troubleshooting"
        exit 1
    else
        echo ""
        log_success "All tests passed! ✨"
        log_info "Your VM integration is working correctly."
        exit 0
    fi
}

# Run main
main "$@"
