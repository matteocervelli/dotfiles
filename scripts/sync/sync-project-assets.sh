#!/usr/bin/env bash
#
# sync-project-assets.sh
# Sync project assets with library-first copy strategy
#
# Usage: ./scripts/sync/sync-project-assets.sh [pull|push] [PROJECT_DIR]
#
# Features:
# - Pull mode: Download/copy assets to project
#   - Try copy from ~/media/cdn/ first (FAST)
#   - Fallback to R2 download if library unavailable (SLOWER)
#   - Device filtering (skip assets not for this device)
#   - Checksum verification on all operations
#   - Statistics: copies vs downloads
# - Push mode: Upload project-specific assets to R2
# - Support for sync modes: copy-from-library, download, cdn-only, false
#
# Requirements:
# - rclone (for R2 operations)
# - yq (brew install yq)
# - shasum (built-in)
# - curl (built-in)

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly MANIFEST_NAME=".r2-manifest.yml"
readonly RCLONE_REMOTE="r2"

# ANSI Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_GRAY='\033[0;90m'
readonly COLOR_BOLD='\033[1m'

# Statistics counters
declare -i STAT_COPIED=0
declare -i STAT_DOWNLOADED=0
declare -i STAT_SKIPPED=0
declare -i STAT_ALREADY_SYNCED=0
declare -i STAT_FAILED=0
declare -i STAT_CDN_ONLY=0
declare -i STAT_MANUAL=0

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[✓]${COLOR_RESET} $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

log_copy() {
    echo -e "${COLOR_GREEN}[📚 Copy]${COLOR_RESET} $*"
}

log_download() {
    echo -e "${COLOR_BLUE}[⬇️  Download]${COLOR_RESET} $*"
}

log_skip() {
    echo -e "${COLOR_GRAY}[⊘ Skip]${COLOR_RESET} $*"
}

log_already() {
    echo -e "${COLOR_GRAY}[✓ Synced]${COLOR_RESET} $*"
}

log_cdn() {
    echo -e "${COLOR_YELLOW}[🌐 CDN]${COLOR_RESET} $*"
}

log_manual() {
    echo -e "${COLOR_YELLOW}[📝 Manual]${COLOR_RESET} $*"
}

# Format bytes to human-readable size
format_size() {
    local bytes=$1
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        echo "$(( bytes / 1024 ))KB"
    elif (( bytes < 1073741824 )); then
        printf "%.1fMB" "$(echo "scale=1; $bytes / 1048576" | bc)"
    else
        printf "%.2fGB" "$(echo "scale=2; $bytes / 1073741824" | bc)"
    fi
}

# Verify dependencies
verify_dependencies() {
    local missing_deps=()

    if ! command -v rclone &> /dev/null; then
        missing_deps+=("rclone")
    fi

    if ! command -v yq &> /dev/null; then
        missing_deps+=("yq")
    fi

    if ! command -v shasum &> /dev/null; then
        missing_deps+=("shasum")
    fi

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        if [[ " ${missing_deps[*]} " == *" rclone "* ]]; then
            log_error "Install rclone: brew install rclone"
            log_error "Configure R2: rclone config"
        fi
        log_error "Install others: brew install ${missing_deps[*]}"
        exit 1
    fi
}

# Verify rclone R2 configuration
verify_rclone_config() {
    if ! rclone listremotes | grep -q "^${RCLONE_REMOTE}:"; then
        log_error "Rclone remote '$RCLONE_REMOTE' not configured"
        log_error "Run: rclone config"
        log_error "Or use setup-rclone script"
        exit 1
    fi
}

# Calculate file SHA256
calculate_sha256() {
    local filepath="$1"
    if [ ! -f "$filepath" ]; then
        echo ""
        return
    fi
    shasum -a 256 "$filepath" 2>/dev/null | awk '{print $1}'
}

# Verify checksum matches
verify_checksum() {
    local filepath="$1"
    local expected_sha256="$2"

    local actual_sha256
    actual_sha256=$(calculate_sha256 "$filepath")

    if [ -z "$actual_sha256" ]; then
        log_error "Failed to calculate checksum for: $filepath"
        return 1
    fi

    if [ "$actual_sha256" != "$expected_sha256" ]; then
        log_error "Checksum mismatch for: $filepath"
        log_error "Expected: $expected_sha256"
        log_error "Actual:   $actual_sha256"
        return 1
    fi

    return 0
}

# Get current device hostname
get_device_name() {
    hostname | tr '[:upper:]' '[:lower:]' | sed 's/\.local$//'
}

# Check if asset should be synced on this device
should_sync_on_device() {
    local manifest="$1"
    local asset_path="$2"
    local device_name="$3"

    # Get devices list for this asset
    local devices
    devices=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .devices[]" - 2>/dev/null || echo "")

    # If no devices specified, sync on all devices
    if [ -z "$devices" ] || [ "$devices" = "null" ]; then
        return 0
    fi

    # Check if current device is in the list
    if echo "$devices" | grep -Fxq "$device_name"; then
        return 0
    else
        return 1
    fi
}

# Load project manifest
load_manifest() {
    local project_dir="$1"
    local manifest_file="$project_dir/$MANIFEST_NAME"

    if [ ! -f "$manifest_file" ]; then
        log_error "Manifest not found: $manifest_file"
        log_error "Run: generate-project-manifest.sh PROJECT_NAME"
        exit 1
    fi

    cat "$manifest_file"
}

# Copy file from library
copy_from_library() {
    local source_path="$1"
    local dest_path="$2"
    local expected_sha256="$3"

    # Expand tilde in source path
    source_path="${source_path/#\~/$HOME}"

    # Check if source exists
    if [ ! -f "$source_path" ]; then
        return 1
    fi

    # Create destination directory
    mkdir -p "$(dirname "$dest_path")"

    # Copy file
    if ! cp "$source_path" "$dest_path" 2>/dev/null; then
        return 1
    fi

    # Verify checksum
    if ! verify_checksum "$dest_path" "$expected_sha256"; then
        rm -f "$dest_path"
        return 1
    fi

    return 0
}

# Download file from R2
download_from_r2() {
    local r2_key="$1"
    local dest_path="$2"
    local expected_sha256="$3"

    # Create destination directory
    mkdir -p "$(dirname "$dest_path")"

    # Download with rclone
    if ! rclone copy "${RCLONE_REMOTE}:${r2_key}" "$(dirname "$dest_path")" --progress 2>&1 | grep -v "^Transferred:" || true; then
        log_error "Failed to download from R2: $r2_key"
        return 1
    fi

    # Verify file exists
    if [ ! -f "$dest_path" ]; then
        log_error "File not found after download: $dest_path"
        return 1
    fi

    # Verify checksum
    if ! verify_checksum "$dest_path" "$expected_sha256"; then
        rm -f "$dest_path"
        return 1
    fi

    return 0
}

# Verify CDN URL is accessible
verify_cdn_url() {
    local cdn_url="$1"

    if [ -z "$cdn_url" ] || [ "$cdn_url" = "null" ]; then
        return 1
    fi

    # Check with HEAD request
    if curl -sSf -I "$cdn_url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# PULL MODE
# ============================================================================

pull_assets() {
    local project_dir="${1:-.}"

    # Resolve project directory
    project_dir="${project_dir/#\~/$HOME}"
    project_dir=$(cd "$project_dir" && pwd)

    log_info "Syncing assets for project: $(basename "$project_dir")"
    log_info "Project directory: $project_dir"
    echo ""

    # Load manifest
    local manifest
    manifest=$(load_manifest "$project_dir")

    # Get device name
    local device_name
    device_name=$(get_device_name)
    log_info "Device: $device_name"
    echo ""

    # Get all asset paths
    local asset_paths
    asset_paths=$(echo "$manifest" | yq eval '.assets[].path' - 2>/dev/null || echo "")

    if [ -z "$asset_paths" ]; then
        log_warn "No assets defined in manifest"
        exit 0
    fi

    # Process each asset
    while IFS= read -r asset_path; do
        if [ -z "$asset_path" ] || [ "$asset_path" = "null" ]; then
            continue
        fi

        # Get asset metadata
        local source_path sync_mode r2_key size sha256 cdn_url
        source_path=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .source" - 2>/dev/null || echo "")
        sync_mode=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .sync" - 2>/dev/null || echo "download")
        r2_key=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .r2_key" - 2>/dev/null || echo "")
        size=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .size" - 2>/dev/null || echo "0")
        sha256=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .sha256" - 2>/dev/null || echo "")
        cdn_url=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .cdn_url" - 2>/dev/null || echo "")

        local size_human
        size_human=$(format_size "$size")

        # Device filtering
        if ! should_sync_on_device "$manifest" "$asset_path" "$device_name"; then
            log_skip "$asset_path (not for device: $device_name)"
            ((STAT_SKIPPED++))
            continue
        fi

        # Full destination path
        local dest_path="$project_dir/$asset_path"

        # Check if already synced with correct checksum
        if [ -f "$dest_path" ]; then
            local current_sha256
            current_sha256=$(calculate_sha256 "$dest_path")
            if [ "$current_sha256" = "$sha256" ]; then
                log_already "$asset_path ($size_human)"
                ((STAT_ALREADY_SYNCED++))
                continue
            fi
        fi

        # Handle different sync modes
        case "$sync_mode" in
            copy-from-library)
                # Try to copy from library
                if [ -n "$source_path" ] && [ "$source_path" != "null" ]; then
                    if copy_from_library "$source_path" "$dest_path" "$sha256"; then
                        log_copy "$asset_path ($size_human) ← $(basename "$(dirname "$source_path")")"
                        ((STAT_COPIED++))
                    else
                        # Fallback to R2 download
                        log_warn "Library unavailable for $asset_path, falling back to R2..."
                        if download_from_r2 "$r2_key" "$dest_path" "$sha256"; then
                            log_download "$asset_path ($size_human) ← R2 (fallback)"
                            ((STAT_DOWNLOADED++))
                        else
                            log_error "Failed to sync: $asset_path"
                            ((STAT_FAILED++))
                        fi
                    fi
                else
                    log_error "No source path for copy-from-library: $asset_path"
                    ((STAT_FAILED++))
                fi
                ;;

            download)
                # Download from R2
                if download_from_r2 "$r2_key" "$dest_path" "$sha256"; then
                    log_download "$asset_path ($size_human) ← R2"
                    ((STAT_DOWNLOADED++))
                else
                    log_error "Failed to download: $asset_path"
                    ((STAT_FAILED++))
                fi
                ;;

            cdn-only)
                # Verify CDN URL is accessible, don't sync locally
                if verify_cdn_url "$cdn_url"; then
                    log_cdn "$asset_path ($size_human) → $cdn_url"
                    ((STAT_CDN_ONLY++))
                else
                    log_warn "CDN URL not accessible: $cdn_url"
                    log_warn "Asset: $asset_path"
                    ((STAT_FAILED++))
                fi
                ;;

            false)
                # Manual download required
                log_manual "$asset_path ($size_human) - Manual download required"
                if [ -n "$cdn_url" ] && [ "$cdn_url" != "null" ]; then
                    echo -e "       ${COLOR_GRAY}URL: $cdn_url${COLOR_RESET}"
                elif [ -n "$r2_key" ]; then
                    echo -e "       ${COLOR_GRAY}R2: $r2_key${COLOR_RESET}"
                fi
                ((STAT_MANUAL++))
                ;;

            true)
                # Legacy boolean support - treat as download
                if download_from_r2 "$r2_key" "$dest_path" "$sha256"; then
                    log_download "$asset_path ($size_human) ← R2"
                    ((STAT_DOWNLOADED++))
                else
                    log_error "Failed to download: $asset_path"
                    ((STAT_FAILED++))
                fi
                ;;

            *)
                log_warn "Unknown sync mode '$sync_mode' for: $asset_path"
                ((STAT_SKIPPED++))
                ;;
        esac

    done <<< "$asset_paths"

    # Print summary
    echo ""
    echo -e "${COLOR_BOLD}📊 Sync Summary:${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}📚 Copied from library:${COLOR_RESET} $STAT_COPIED files (fast)"
    echo -e "  ${COLOR_BLUE}⬇️  Downloaded from R2:${COLOR_RESET} $STAT_DOWNLOADED files"
    echo -e "  ${COLOR_GRAY}✓ Already synced:${COLOR_RESET} $STAT_ALREADY_SYNCED files"
    echo -e "  ${COLOR_YELLOW}🌐 CDN only:${COLOR_RESET} $STAT_CDN_ONLY files"
    echo -e "  ${COLOR_YELLOW}📝 Manual download:${COLOR_RESET} $STAT_MANUAL files"
    echo -e "  ${COLOR_GRAY}⊘ Skipped (device):${COLOR_RESET} $STAT_SKIPPED files"

    if [ "$STAT_FAILED" -gt 0 ]; then
        echo -e "  ${COLOR_RED}❌ Failed:${COLOR_RESET} $STAT_FAILED files"
    fi

    local total_synced=$((STAT_COPIED + STAT_DOWNLOADED))
    echo -e "  ${COLOR_BOLD}Total synced:${COLOR_RESET} $total_synced files"

    # Calculate library efficiency
    if [ "$total_synced" -gt 0 ]; then
        local efficiency=$((STAT_COPIED * 100 / total_synced))
        echo ""
        log_info "Library efficiency: ${efficiency}% of synced files copied locally (fast!)"
    fi

    echo ""
    if [ "$STAT_FAILED" -gt 0 ]; then
        log_error "Some files failed to sync. Check errors above."
        exit 1
    else
        log_success "All assets synced successfully!"
    fi
}

# ============================================================================
# PUSH MODE
# ============================================================================

push_assets() {
    local project_dir="${1:-.}"

    # Resolve project directory
    project_dir="${project_dir/#\~/$HOME}"
    project_dir=$(cd "$project_dir" && pwd)

    log_info "Pushing project-specific assets to R2"
    log_info "Project directory: $project_dir"
    echo ""

    # Load manifest
    local manifest
    manifest=$(load_manifest "$project_dir")

    # Get project name
    local project_name
    project_name=$(echo "$manifest" | yq eval '.project' - 2>/dev/null || echo "unknown")

    log_info "Project: $project_name"
    echo ""

    # Get all asset paths
    local asset_paths
    asset_paths=$(echo "$manifest" | yq eval '.assets[].path' - 2>/dev/null || echo "")

    if [ -z "$asset_paths" ]; then
        log_warn "No assets defined in manifest"
        exit 0
    fi

    local uploaded_count=0
    local skipped_count=0

    # Process each asset
    while IFS= read -r asset_path; do
        if [ -z "$asset_path" ] || [ "$asset_path" = "null" ]; then
            continue
        fi

        # Get asset metadata
        local sync_mode r2_key source_path
        sync_mode=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .sync" - 2>/dev/null || echo "download")
        r2_key=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .r2_key" - 2>/dev/null || echo "")
        source_path=$(echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\") | .source" - 2>/dev/null || echo "")

        # Only push project-specific files (not library files)
        if [ "$sync_mode" = "copy-from-library" ] || [ -n "$source_path" ]; then
            log_skip "$asset_path (from library, not uploading)"
            ((skipped_count++))
            continue
        fi

        # Full source path
        local source_file="$project_dir/$asset_path"

        if [ ! -f "$source_file" ]; then
            log_warn "File not found: $asset_path (skipping)"
            ((skipped_count++))
            continue
        fi

        # Upload to R2
        log_info "Uploading: $asset_path → $r2_key"
        if rclone copy "$source_file" "${RCLONE_REMOTE}:$(dirname "$r2_key")" --progress 2>&1 | grep -v "^Transferred:" || true; then
            log_success "Uploaded: $asset_path"
            ((uploaded_count++))

            # TODO: Update manifest with new checksum (future enhancement)
        else
            log_error "Failed to upload: $asset_path"
        fi

    done <<< "$asset_paths"

    # Print summary
    echo ""
    echo -e "${COLOR_BOLD}📊 Push Summary:${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}⬆️  Uploaded to R2:${COLOR_RESET} $uploaded_count files"
    echo -e "  ${COLOR_GRAY}⊘ Skipped (library):${COLOR_RESET} $skipped_count files"
    echo ""
    log_success "Push completed!"
}

# ============================================================================
# MAIN
# ============================================================================

usage() {
    cat <<EOF
Usage: $0 [pull|push] [PROJECT_DIR]

Sync project assets with library-first copy strategy.

Commands:
  pull    Download/copy assets to project (default)
          - Try copy from ~/media/cdn/ first (FAST)
          - Fallback to R2 download if unavailable (SLOWER)
  push    Upload project-specific assets to R2

Arguments:
  PROJECT_DIR    Project directory (default: current directory)

Examples:
  $0 pull                           # Sync assets in current directory
  $0 pull ~/dev/projects/APP-Portfolio
  $0 push                           # Push project assets to R2

Sync Modes:
  copy-from-library  Copy from ~/media/cdn/ (fallback to R2)
  download           Download from R2 directly
  cdn-only           Skip local sync, verify CDN URL
  false              Manual download required (show instructions)

Requirements:
  - rclone configured with R2 remote
  - .r2-manifest.yml in project root
  - yq, shasum, curl
EOF
}

main() {
    local mode="${1:-pull}"
    local project_dir="${2:-.}"

    if [ "$mode" = "-h" ] || [ "$mode" = "--help" ]; then
        usage
        exit 0
    fi

    verify_dependencies

    case "$mode" in
        pull)
            verify_rclone_config
            pull_assets "$project_dir"
            ;;
        push)
            verify_rclone_config
            push_assets "$project_dir"
            ;;
        *)
            log_error "Unknown mode: $mode"
            usage
            exit 1
            ;;
    esac
}

main "$@"
