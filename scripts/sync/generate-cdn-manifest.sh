#!/usr/bin/env bash
#
# generate-cdn-manifest.sh
# Generate central CDN manifest with automatic dimension extraction
#
# Usage: ./scripts/sync/generate-cdn-manifest.sh [CDN_DIR]
#
# Features:
# - Recursive directory scanning
# - SHA256 checksum calculation
# - File size and modification date extraction
# - Image dimension extraction using ImageMagick
# - Content-based file type detection
# - Dimension caching for performance
# - YAML manifest generation
# - Colored terminal output with change summary
#
# Requirements:
# - imagemagick (brew install imagemagick)
# - yq (brew install yq)
# - shasum (built-in)
# - file (built-in)

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly DEFAULT_CDN_DIR="$HOME/media/cdn"
readonly MANIFEST_NAME=".r2-manifest.yml"
readonly CACHE_NAME=".dimensions-cache.json"

# ANSI Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_GRAY='\033[0;90m'
readonly COLOR_BOLD='\033[1m'

# Counters
declare -i NEW_COUNT=0
declare -i UPDATED_COUNT=0
declare -i UNCHANGED_COUNT=0
declare -i REMOVED_COUNT=0
declare -i TOTAL_SIZE_DELTA=0

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

log_new() {
    echo -e "${COLOR_GREEN}[+]${COLOR_RESET} $*"
}

log_updated() {
    echo -e "${COLOR_YELLOW}[~]${COLOR_RESET} $*"
}

log_removed() {
    echo -e "${COLOR_RED}[-]${COLOR_RESET} $*"
}

log_unchanged() {
    echo -e "${COLOR_GRAY}[=]${COLOR_RESET} $*"
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

    if ! command -v identify &> /dev/null; then
        missing_deps+=("imagemagick")
    fi

    if ! command -v yq &> /dev/null; then
        missing_deps+=("yq")
    fi

    if ! command -v shasum &> /dev/null; then
        missing_deps+=("shasum")
    fi

    if ! command -v file &> /dev/null; then
        missing_deps+=("file")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Install with: brew install ${missing_deps[*]}"
        exit 1
    fi
}

# Sanitize file path (prevent directory traversal)
sanitize_path() {
    local path="$1"
    # Remove any .. or special characters that could be dangerous
    echo "$path" | sed 's/\.\.\///g' | tr -d '\n\r'
}

# Detect file type from content (not extension)
detect_file_type() {
    local filepath="$1"
    local mime_type
    mime_type=$(file --brief --mime-type "$filepath" 2>/dev/null || echo "application/octet-stream")

    case "$mime_type" in
        application/x-*model*|application/octet-stream)
            # Check by extension for model files
            case "${filepath##*.}" in
                bin|gguf|safetensors|weights|pt|h5|onnx) echo "model" ;;
                *) echo "data" ;;
            esac
            ;;
        application/x-tar|application/gzip|application/zip|application/x-parquet)
            echo "dataset"
            ;;
        image/*)
            echo "media"
            ;;
        video/*)
            echo "video"
            ;;
        audio/*)
            echo "audio"
            ;;
        application/pdf|application/msword|application/*document*)
            echo "document"
            ;;
        *)
            echo "data"
            ;;
    esac
}

# Check if file is an image
is_image() {
    local filepath="$1"
    local mime_type
    mime_type=$(file --brief --mime-type "$filepath" 2>/dev/null || echo "")
    [[ "$mime_type" == image/* ]]
}

# Extract image dimensions using ImageMagick
extract_dimensions() {
    local filepath="$1"

    if ! is_image "$filepath"; then
        echo ""
        return
    fi

    local dimensions
    dimensions=$(identify -format "%wx%h" "$filepath" 2>/dev/null || echo "")

    if [ -n "$dimensions" ]; then
        echo "$dimensions"
    else
        echo ""
    fi
}

# Load dimension cache
load_cache() {
    local cache_file="$1"
    if [ -f "$cache_file" ]; then
        cat "$cache_file"
    else
        echo "{}"
    fi
}

# Get cached dimensions
get_cached_dimensions() {
    local cache_json="$1"
    local cache_key="$2"
    echo "$cache_json" | jq -r ".\"$cache_key\" // \"\""
}

# Update cache
update_cache() {
    local cache_file="$1"
    local cache_key="$2"
    local dimensions="$3"

    local cache_json
    cache_json=$(load_cache "$cache_file")

    cache_json=$(echo "$cache_json" | jq --arg key "$cache_key" --arg val "$dimensions" \
        '.[$key] = $val')

    echo "$cache_json" > "$cache_file"
}

# Generate cache key (filepath:mtime:size)
generate_cache_key() {
    local filepath="$1"
    local mtime="$2"
    local size="$3"
    echo "${filepath}:${mtime}:${size}"
}

# Calculate file SHA256
calculate_sha256() {
    local filepath="$1"
    shasum -a 256 "$filepath" | awk '{print $1}'
}

# Load old manifest for comparison
load_old_manifest() {
    local manifest_file="$1"
    if [ -f "$manifest_file" ]; then
        cat "$manifest_file"
    else
        echo ""
    fi
}

# Extract asset from old manifest by path
get_old_asset() {
    local old_manifest="$1"
    local asset_path="$2"

    if [ -z "$old_manifest" ]; then
        echo ""
        return
    fi

    echo "$old_manifest" | yq eval ".assets[] | select(.path == \"$asset_path\")" - 2>/dev/null || echo ""
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

generate_manifest() {
    local cdn_dir="${1:-$DEFAULT_CDN_DIR}"

    # Expand tilde
    cdn_dir="${cdn_dir/#\~/$HOME}"

    if [ ! -d "$cdn_dir" ]; then
        log_error "CDN directory not found: $cdn_dir"
        exit 1
    fi

    log_info "Scanning $cdn_dir..."

    local manifest_file="$cdn_dir/$MANIFEST_NAME"
    local cache_file="$cdn_dir/$CACHE_NAME"
    local temp_manifest="/tmp/r2-manifest-temp-$$.yml"

    # Load old manifest and cache
    local old_manifest
    old_manifest=$(load_old_manifest "$manifest_file")

    local cache_json
    cache_json=$(load_cache "$cache_file")

    # Initialize new manifest
    cat > "$temp_manifest" <<EOF
# Central CDN Asset Manifest
# Auto-generated by generate-cdn-manifest.sh
# DO NOT EDIT MANUALLY

project: media-cdn
version: "1.1"
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

assets:
EOF

    # Track processed paths for removed detection (using grep instead of associative array for bash 3 compatibility)
    local processed_paths_file="/tmp/processed-paths-$$.txt"
    touch "$processed_paths_file"

    # Find all files (exclude hidden files and directories, exclude manifest and cache)
    while IFS= read -r -d '' filepath; do
        # Skip manifest and cache files
        local filename
        filename=$(basename "$filepath")
        if [ "$filename" = "$MANIFEST_NAME" ] || [ "$filename" = "$CACHE_NAME" ]; then
            continue
        fi

        # Calculate relative path from cdn_dir
        local relpath="${filepath#$cdn_dir/}"
        relpath=$(sanitize_path "$relpath")

        # Track processed path
        echo "$relpath" >> "$processed_paths_file"

        # Get file metadata
        local size
        size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null)

        local mtime
        mtime=$(stat -f%m "$filepath" 2>/dev/null || stat -c%Y "$filepath" 2>/dev/null)

        local modified_date
        modified_date=$(date -r "$mtime" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -d "@$mtime" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

        # Calculate SHA256
        local sha256
        sha256=$(calculate_sha256 "$filepath")

        # Detect file type
        local file_type
        file_type=$(detect_file_type "$filepath")

        # Extract or get cached dimensions
        local dimensions=""
        local cache_key
        cache_key=$(generate_cache_key "$relpath" "$mtime" "$size")

        local cached_dims
        cached_dims=$(get_cached_dimensions "$cache_json" "$cache_key")

        if [ -n "$cached_dims" ]; then
            dimensions="$cached_dims"
        elif is_image "$filepath"; then
            dimensions=$(extract_dimensions "$filepath")
            if [ -n "$dimensions" ]; then
                update_cache "$cache_file" "$cache_key" "$dimensions"
                cache_json=$(load_cache "$cache_file")
            fi
        fi

        # Check if file existed in old manifest
        local old_asset
        old_asset=$(get_old_asset "$old_manifest" "$relpath")

        local status="NEW"
        if [ -n "$old_asset" ]; then
            local old_sha256
            old_sha256=$(echo "$old_asset" | yq eval '.sha256' - 2>/dev/null || echo "")

            if [ "$old_sha256" = "$sha256" ]; then
                status="UNCHANGED"
                ((UNCHANGED_COUNT++))
            else
                status="UPDATED"
                ((UPDATED_COUNT++))

                # Calculate size delta
                local old_size
                old_size=$(echo "$old_asset" | yq eval '.size' - 2>/dev/null || echo "0")
                ((TOTAL_SIZE_DELTA += size - old_size))
            fi
        else
            status="NEW"
            ((NEW_COUNT++))
            ((TOTAL_SIZE_DELTA += size))
        fi

        # Write to temp manifest
        cat >> "$temp_manifest" <<EOF
  - path: $relpath
    r2_key: media-cdn/$relpath
    size: $size
    sha256: $sha256
    type: $file_type
    modified: $modified_date
EOF

        # Add dimensions if available
        if [ -n "$dimensions" ]; then
            local width height
            width=$(echo "$dimensions" | cut -d'x' -f1)
            height=$(echo "$dimensions" | cut -d'x' -f2)
            cat >> "$temp_manifest" <<EOF
    dimensions: {width: $width, height: $height}
EOF
        fi

        # Add default sync mode
        cat >> "$temp_manifest" <<EOF
    sync: true
EOF

        # Log change
        local size_human
        size_human=$(format_size "$size")

        case "$status" in
            NEW)
                if [ -n "$dimensions" ]; then
                    log_new "$relpath ($size_human, ${width}×${height})"
                else
                    log_new "$relpath ($size_human)"
                fi
                ;;
            UPDATED)
                log_updated "$relpath"
                local old_size
                old_size=$(echo "$old_asset" | yq eval '.size' - 2>/dev/null || echo "0")
                local old_size_human
                old_size_human=$(format_size "$old_size")
                local delta=$((size - old_size))
                local delta_human
                delta_human=$(format_size "${delta#-}")
                local percent
                if [ "$old_size" -gt 0 ]; then
                    percent=$(echo "scale=1; ($delta * 100) / $old_size" | bc)
                else
                    percent="N/A"
                fi

                if [ "$delta" -gt 0 ]; then
                    echo -e "    ${COLOR_GRAY}Size: $old_size_human → $size_human (+$delta_human, +$percent%)${COLOR_RESET}"
                elif [ "$delta" -lt 0 ]; then
                    echo -e "    ${COLOR_GRAY}Size: $old_size_human → $size_human (-$delta_human, $percent%)${COLOR_RESET}"
                fi

                # Show dimension changes
                if [ -n "$dimensions" ]; then
                    local old_dims
                    old_dims=$(echo "$old_asset" | yq eval '.dimensions | "\(.width)x\(.height)"' - 2>/dev/null || echo "")
                    if [ -n "$old_dims" ] && [ "$old_dims" != "nullxnull" ] && [ "$old_dims" != "$dimensions" ]; then
                        echo -e "    ${COLOR_GRAY}Dimensions: $old_dims → $dimensions${COLOR_RESET}"
                    fi
                fi
                ;;
        esac

    done < <(find "$cdn_dir" -type f -not -path '*/\.*' -print0)

    # Check for removed files
    if [ -n "$old_manifest" ]; then
        local old_paths
        old_paths=$(echo "$old_manifest" | yq eval '.assets[].path' - 2>/dev/null || echo "")

        while IFS= read -r old_path; do
            if [ -z "$old_path" ] || [ "$old_path" = "null" ]; then
                continue
            fi

            if ! grep -Fxq "$old_path" "$processed_paths_file" 2>/dev/null; then
                log_removed "$old_path (deleted)"
                ((REMOVED_COUNT++))

                local old_asset_removed
                old_asset_removed=$(get_old_asset "$old_manifest" "$old_path")
                local old_size_removed
                old_size_removed=$(echo "$old_asset_removed" | yq eval '.size' - 2>/dev/null || echo "0")
                ((TOTAL_SIZE_DELTA -= old_size_removed))
            fi
        done <<< "$old_paths"
    fi

    # Move temp manifest to final location
    mv "$temp_manifest" "$manifest_file"

    # Cleanup
    rm -f "$processed_paths_file"

    # Print summary
    echo ""
    local total_count=$((NEW_COUNT + UPDATED_COUNT + UNCHANGED_COUNT))
    local delta_sign="+"
    local delta_color="$COLOR_GREEN"
    if [ "$TOTAL_SIZE_DELTA" -lt 0 ]; then
        delta_sign=""
        delta_color="$COLOR_RED"
    fi
    local delta_human
    delta_human=$(format_size "${TOTAL_SIZE_DELTA#-}")

    echo -e "${COLOR_BOLD}📊 Summary:${COLOR_RESET} ${COLOR_GREEN}$NEW_COUNT new${COLOR_RESET}, ${COLOR_YELLOW}$UPDATED_COUNT updated${COLOR_RESET}, ${COLOR_RED}$REMOVED_COUNT removed${COLOR_RESET}, ${COLOR_GRAY}$UNCHANGED_COUNT unchanged${COLOR_RESET} (total: $total_count files, ${delta_color}${delta_sign}${delta_human}${COLOR_RESET})"
    echo ""
    log_success "Manifest generated: $manifest_file"
    log_info "Dimension cache: $cache_file"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    verify_dependencies
    generate_manifest "$@"
}

main "$@"
