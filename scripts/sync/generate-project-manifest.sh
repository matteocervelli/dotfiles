#!/usr/bin/env bash
#
# generate-project-manifest.sh
# Generate project-specific R2 manifest with library detection
#
# Usage: ./scripts/sync/generate-project-manifest.sh PROJECT_NAME [PROJECT_DIR]
#
# Features:
# - Scan project directories for assets (public/media/, data/, public/images/)
# - Check if files exist in central library (~/media/cdn/)
# - For library files: Add source path + sync: copy-from-library
# - For project files: Add R2 key + sync: download
# - Smart sync defaults based on file size/type
# - SHA256 checksum calculation
# - Device filtering support
# - YAML manifest generation
#
# Requirements:
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
readonly CDN_MANIFEST_NAME=".r2-manifest.yml"
readonly PROJECT_MANIFEST_NAME=".r2-manifest.yml"

# Directories to scan for assets (relative to project root)
readonly ASSET_DIRS=("public/media" "data" "public/images" "assets")

# ANSI Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_GRAY='\033[0;90m'
readonly COLOR_BOLD='\033[1m'

# Counters
declare -i LIBRARY_COUNT=0
declare -i PROJECT_COUNT=0
declare -i SKIPPED_COUNT=0

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

log_library() {
    echo -e "${COLOR_GREEN}[📚 Library]${COLOR_RESET} $*"
}

log_project() {
    echo -e "${COLOR_BLUE}[📦 Project]${COLOR_RESET} $*"
}

log_skip() {
    echo -e "${COLOR_GRAY}[⊘ Skip]${COLOR_RESET} $*"
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

# Validate project name (alphanumeric + hyphens only)
validate_project_name() {
    local project_name="$1"
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9-]+$ ]]; then
        log_error "Invalid project name: $project_name"
        log_error "Project name must contain only alphanumeric characters and hyphens"
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

# Calculate file SHA256
calculate_sha256() {
    local filepath="$1"
    shasum -a 256 "$filepath" | awk '{print $1}'
}

# Load central CDN manifest
load_cdn_manifest() {
    local cdn_dir="$1"
    local cdn_manifest="$cdn_dir/$CDN_MANIFEST_NAME"

    if [ ! -f "$cdn_manifest" ]; then
        log_warn "Central CDN manifest not found: $cdn_manifest"
        echo ""
        return
    fi

    cat "$cdn_manifest"
}

# Build library lookup table (filename -> asset data)
# Returns a temporary file with format: filename|path|r2_key|size|sha256|cdn_url|dimensions
build_library_lookup() {
    local cdn_manifest="$1"
    local lookup_file="/tmp/library-lookup-$$.txt"

    if [ -z "$cdn_manifest" ]; then
        touch "$lookup_file"
        echo "$lookup_file"
        return
    fi

    # Extract assets and build lookup table
    # Using grep/awk instead of associative arrays for bash 3.2 compatibility
    echo "$cdn_manifest" | yq eval '.assets[] | .path' - 2>/dev/null | while read -r path; do
        if [ -z "$path" ] || [ "$path" = "null" ]; then
            continue
        fi

        local filename
        filename=$(basename "$path")

        # Get asset metadata
        local r2_key size sha256 cdn_url dimensions_w dimensions_h
        r2_key=$(echo "$cdn_manifest" | yq eval ".assets[] | select(.path == \"$path\") | .r2_key" - 2>/dev/null || echo "")
        size=$(echo "$cdn_manifest" | yq eval ".assets[] | select(.path == \"$path\") | .size" - 2>/dev/null || echo "0")
        sha256=$(echo "$cdn_manifest" | yq eval ".assets[] | select(.path == \"$path\") | .sha256" - 2>/dev/null || echo "")
        cdn_url=$(echo "$cdn_manifest" | yq eval ".assets[] | select(.path == \"$path\") | .cdn_url" - 2>/dev/null || echo "")
        dimensions_w=$(echo "$cdn_manifest" | yq eval ".assets[] | select(.path == \"$path\") | .dimensions.width" - 2>/dev/null || echo "")
        dimensions_h=$(echo "$cdn_manifest" | yq eval ".assets[] | select(.path == \"$path\") | .dimensions.height" - 2>/dev/null || echo "")

        # Build dimensions string
        local dimensions=""
        if [ -n "$dimensions_w" ] && [ "$dimensions_w" != "null" ] && [ -n "$dimensions_h" ] && [ "$dimensions_h" != "null" ]; then
            dimensions="${dimensions_w}x${dimensions_h}"
        fi

        # Write to lookup file: filename|path|r2_key|size|sha256|cdn_url|dimensions
        echo "${filename}|${path}|${r2_key}|${size}|${sha256}|${cdn_url}|${dimensions}" >> "$lookup_file"
    done

    echo "$lookup_file"
}

# Search library lookup for filename
# Returns: found|path|r2_key|size|sha256|cdn_url|dimensions
search_library() {
    local lookup_file="$1"
    local filename="$2"

    if [ ! -f "$lookup_file" ]; then
        echo "not_found"
        return
    fi

    # Search for filename in lookup table
    local result
    result=$(grep "^${filename}|" "$lookup_file" 2>/dev/null | head -1 || echo "")

    if [ -n "$result" ]; then
        echo "found|$result"
    else
        echo "not_found"
    fi
}

# Determine sync mode based on file size and type
determine_sync_mode() {
    local size="$1"
    local file_type="$2"

    # Files > 100MB: manual download (sync: false)
    if (( size > 104857600 )); then
        echo "false"
        return
    fi

    # Large models/datasets: manual download
    if [ "$file_type" = "model" ] || [ "$file_type" = "dataset" ]; then
        if (( size > 52428800 )); then  # > 50MB
            echo "false"
            return
        fi
    fi

    # Default: download (will be overridden to copy-from-library if in library)
    echo "download"
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

generate_project_manifest() {
    local project_name="$1"
    local project_dir="${2:-.}"

    # Validate inputs
    validate_project_name "$project_name"

    # Expand tilde and resolve path
    project_dir="${project_dir/#\~/$HOME}"
    project_dir=$(cd "$project_dir" && pwd)

    if [ ! -d "$project_dir" ]; then
        log_error "Project directory not found: $project_dir"
        exit 1
    fi

    log_info "Generating project manifest for: $project_name"
    log_info "Project directory: $project_dir"
    echo ""

    # Load central CDN manifest
    local cdn_dir="${DEFAULT_CDN_DIR}"
    cdn_dir="${cdn_dir/#\~/$HOME}"

    log_info "Loading central library manifest from: $cdn_dir"
    local cdn_manifest
    cdn_manifest=$(load_cdn_manifest "$cdn_dir")

    # Build library lookup table
    local lookup_file
    lookup_file=$(build_library_lookup "$cdn_manifest")

    if [ -s "$lookup_file" ]; then
        local library_file_count
        library_file_count=$(wc -l < "$lookup_file" | tr -d ' ')
        log_success "Library loaded: $library_file_count files indexed"
    else
        log_warn "Library empty or unavailable - all files will use R2 download"
    fi

    echo ""
    log_info "Scanning project directories..."
    echo ""

    # Prepare output manifest
    local manifest_file="$project_dir/$PROJECT_MANIFEST_NAME"
    local temp_manifest="/tmp/project-manifest-$$.yml"

    # Initialize manifest header
    cat > "$temp_manifest" <<EOF
# Project Asset Manifest
# Generated by generate-project-manifest.sh
# Project: $project_name
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

project: $project_name
version: "1.1"
updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

assets:
EOF

    # Scan project directories
    local found_files=0
    for asset_dir in "${ASSET_DIRS[@]}"; do
        local full_asset_dir="$project_dir/$asset_dir"

        if [ ! -d "$full_asset_dir" ]; then
            continue
        fi

        log_info "Scanning: $asset_dir/"

        # Find all files in asset directory
        while IFS= read -r -d '' filepath; do
            ((found_files++))

            # Calculate relative path from project root
            local relpath="${filepath#$project_dir/}"
            relpath=$(sanitize_path "$relpath")

            local filename
            filename=$(basename "$filepath")

            # Get file metadata
            local size
            size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null)

            local size_human
            size_human=$(format_size "$size")

            # Calculate SHA256
            local sha256
            sha256=$(calculate_sha256 "$filepath")

            # Detect file type
            local file_type
            file_type=$(detect_file_type "$filepath")

            # Search in library
            local library_result
            library_result=$(search_library "$lookup_file" "$filename")

            local sync_mode r2_key source_path cdn_url dimensions

            if [[ "$library_result" == found* ]]; then
                # File found in library
                ((LIBRARY_COUNT++))

                # Parse library data: found|filename|path|r2_key|size|sha256|cdn_url|dimensions
                IFS='|' read -r _ _ lib_path lib_r2_key lib_size lib_sha256 lib_cdn_url lib_dimensions <<< "$library_result"

                source_path="$cdn_dir/$lib_path"
                r2_key="$lib_r2_key"
                cdn_url="$lib_cdn_url"
                dimensions="$lib_dimensions"
                sync_mode="copy-from-library"

                log_library "$relpath ($size_human) → from library"

            else
                # File NOT in library - project-specific
                ((PROJECT_COUNT++))

                r2_key="projects/$project_name/$relpath"
                source_path=""
                cdn_url=""
                dimensions=""
                sync_mode=$(determine_sync_mode "$size" "$file_type")

                if [ "$sync_mode" = "false" ]; then
                    log_skip "$relpath ($size_human) → manual download (>100MB)"
                else
                    log_project "$relpath ($size_human) → R2 download"
                fi
            fi

            # Write asset to manifest
            cat >> "$temp_manifest" <<EOF
  - path: $relpath
EOF

            # Add source if from library
            if [ -n "$source_path" ]; then
                cat >> "$temp_manifest" <<EOF
    source: $source_path
EOF
            fi

            cat >> "$temp_manifest" <<EOF
    r2_key: $r2_key
EOF

            # Add CDN URL if available
            if [ -n "$cdn_url" ] && [ "$cdn_url" != "null" ]; then
                cat >> "$temp_manifest" <<EOF
    cdn_url: $cdn_url
EOF
            fi

            cat >> "$temp_manifest" <<EOF
    size: $size
    sha256: $sha256
    type: $file_type
EOF

            # Add dimensions if available
            if [ -n "$dimensions" ] && [ "$dimensions" != "x" ]; then
                local width height
                width=$(echo "$dimensions" | cut -d'x' -f1)
                height=$(echo "$dimensions" | cut -d'x' -f2)
                cat >> "$temp_manifest" <<EOF
    dimensions: {width: $width, height: $height}
EOF
            fi

            # Add sync mode
            cat >> "$temp_manifest" <<EOF
    sync: $sync_mode
EOF

        done < <(find "$full_asset_dir" -type f -print0 2>/dev/null)

    done

    # Check if any files were found
    if [ "$found_files" -eq 0 ]; then
        log_warn "No asset files found in project directories"
        log_info "Searched in: ${ASSET_DIRS[*]}"

        # Create empty manifest
        cat >> "$temp_manifest" <<EOF
[]
EOF
    fi

    # Move temp manifest to final location
    mv "$temp_manifest" "$manifest_file"

    # Cleanup
    rm -f "$lookup_file"

    # Print summary
    echo ""
    echo -e "${COLOR_BOLD}📊 Summary:${COLOR_RESET}"
    echo -e "  ${COLOR_GREEN}📚 From library:${COLOR_RESET} $LIBRARY_COUNT files (copy-from-library)"
    echo -e "  ${COLOR_BLUE}📦 Project-specific:${COLOR_RESET} $PROJECT_COUNT files (R2 download)"
    echo -e "  ${COLOR_GRAY}Total:${COLOR_RESET} $((LIBRARY_COUNT + PROJECT_COUNT)) files"
    echo ""
    log_success "Manifest generated: $manifest_file"

    if [ "$LIBRARY_COUNT" -gt 0 ]; then
        local percentage=$((LIBRARY_COUNT * 100 / (LIBRARY_COUNT + PROJECT_COUNT)))
        log_info "Library efficiency: ${percentage}% of files can be copied locally (fast!)"
    fi
}

# Show usage
usage() {
    cat <<EOF
Usage: $0 PROJECT_NAME [PROJECT_DIR]

Generate project-specific R2 manifest with library detection.

Arguments:
  PROJECT_NAME    Project name (alphanumeric + hyphens only)
  PROJECT_DIR     Project directory (default: current directory)

Examples:
  $0 app-portfolio
  $0 app-portfolio ~/dev/projects/APP-Portfolio
  $0 website-blog ~/dev/projects/WEB-Blog

The script will:
  1. Scan project directories: ${ASSET_DIRS[*]}
  2. Check if files exist in central library (~media/cdn/)
  3. For library files: Set sync: copy-from-library (fast)
  4. For project files: Set sync: download (from R2)
  5. Generate .r2-manifest.yml in project root

Requirements:
  - yq (brew install yq)
  - Central library at ~/media/cdn/ with .r2-manifest.yml
EOF
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    if [ $# -lt 1 ]; then
        usage
        exit 1
    fi

    verify_dependencies
    generate_project_manifest "$@"
}

main "$@"
