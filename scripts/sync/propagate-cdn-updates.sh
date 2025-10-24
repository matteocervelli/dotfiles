#!/usr/bin/env bash
#
# propagate-cdn-updates.sh
# Propagate CDN library updates to all affected projects
#
# Usage: ./scripts/sync/propagate-cdn-updates.sh [OPTIONS] CHANGED_FILES...
#
# Features:
# - Scan all projects in ~/dev/projects/*/
# - Detect projects using changed files (by source field or filename)
# - Update project manifests with new checksums, sizes, dimensions
# - Re-copy files from library to projects
# - Verify checksums after copy
# - Optional git commits
# - Comprehensive statistics and reporting
#
# Options:
#   --git-commit        Commit changes to git (off by default)
#   --projects-dir DIR  Custom projects directory (default: ~/dev/projects)
#   --library-dir DIR   Custom library directory (default: ~/media/cdn)
#
# Requirements:
# - yq (brew install yq)
# - shasum (built-in)

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly DEFAULT_PROJECTS_DIR="$HOME/dev/projects"
readonly DEFAULT_LIBRARY_DIR="$HOME/media/cdn"
readonly MANIFEST_NAME=".r2-manifest.yml"

# ANSI Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_GRAY='\033[0;90m'
readonly COLOR_BOLD='\033[1m'

# Flags
GIT_COMMIT=false
PROJECTS_DIR="$DEFAULT_PROJECTS_DIR"
LIBRARY_DIR="$DEFAULT_LIBRARY_DIR"

# Statistics
declare -i STAT_PROJECTS_SCANNED=0
declare -i STAT_PROJECTS_UPDATED=0
declare -i STAT_FILES_COPIED=0
declare -i STAT_MANIFESTS_UPDATED=0
declare -i STAT_ERRORS=0
declare -i STAT_SKIPPED=0

# Track affected projects
declare -a AFFECTED_PROJECTS=()

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

log_update() {
    echo -e "${COLOR_GREEN}[↻ Update]${COLOR_RESET} $*"
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

# Sanitize path (prevent directory traversal)
sanitize_path() {
    local path="$1"
    echo "$path" | sed 's/\.\.\///g' | tr -d '\n\r'
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

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Install with: brew install ${missing_deps[*]}"
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

# Check if project uses a changed file
project_uses_file() {
    local project_manifest="$1"
    local changed_file="$2"
    local library_dir="$3"

    if [ ! -f "$project_manifest" ]; then
        return 1
    fi

    # Method 1: Check source field (exact match)
    if yq eval ".assets[] | select(.source | test(\"$changed_file\"))" "$project_manifest" 2>/dev/null | grep -q .; then
        return 0
    fi

    # Method 2: Check by filename (for library files copied to projects)
    local filename
    filename=$(basename "$changed_file")

    # Get all assets with matching filename
    local matching_assets
    matching_assets=$(yq eval ".assets[] | select(.path | test(\"$filename\"))" "$project_manifest" 2>/dev/null || echo "")

    if [ -n "$matching_assets" ]; then
        # Check if any have source pointing to library
        if echo "$matching_assets" | yq eval '.source' - 2>/dev/null | grep -q "$library_dir"; then
            return 0
        fi
    fi

    return 1
}

# Get asset metadata from library manifest
get_library_asset() {
    local library_manifest="$1"
    local asset_path="$2"

    if [ ! -f "$library_manifest" ]; then
        echo ""
        return
    fi

    yq eval ".assets[] | select(.path == \"$asset_path\")" "$library_manifest" 2>/dev/null || echo ""
}

# Update project asset in manifest
update_project_asset() {
    local project_manifest="$1"
    local asset_path="$2"
    local library_asset="$3"

    # Extract new metadata
    local new_sha256
    new_sha256=$(echo "$library_asset" | yq eval '.sha256' -)

    local new_size
    new_size=$(echo "$library_asset" | yq eval '.size' -)

    local new_modified
    new_modified=$(echo "$library_asset" | yq eval '.modified' -)

    # Check if asset has dimensions
    local has_dims
    has_dims=$(echo "$library_asset" | yq eval '.dimensions' - 2>/dev/null)

    # Create temp file for update
    local temp_manifest
    temp_manifest=$(mktemp)

    # Update the asset
    if [ "$has_dims" != "null" ] && [ -n "$has_dims" ]; then
        local width height
        width=$(echo "$library_asset" | yq eval '.dimensions.width' -)
        height=$(echo "$library_asset" | yq eval '.dimensions.height' -)

        # Update with dimensions
        yq eval "(.assets[] | select(.path == \"$asset_path\") | .sha256) = \"$new_sha256\" |
                 (.assets[] | select(.path == \"$asset_path\") | .size) = $new_size |
                 (.assets[] | select(.path == \"$asset_path\") | .modified) = \"$new_modified\" |
                 (.assets[] | select(.path == \"$asset_path\") | .dimensions.width) = $width |
                 (.assets[] | select(.path == \"$asset_path\") | .dimensions.height) = $height" \
                 "$project_manifest" > "$temp_manifest"
    else
        # Update without dimensions
        yq eval "(.assets[] | select(.path == \"$asset_path\") | .sha256) = \"$new_sha256\" |
                 (.assets[] | select(.path == \"$asset_path\") | .size) = $new_size |
                 (.assets[] | select(.path == \"$asset_path\") | .modified) = \"$new_modified\"" \
                 "$project_manifest" > "$temp_manifest"
    fi

    # Replace original manifest
    mv "$temp_manifest" "$project_manifest"
}

# Copy file from library to project
copy_from_library() {
    local library_path="$1"
    local project_path="$2"

    # Create parent directory if needed
    local parent_dir
    parent_dir=$(dirname "$project_path")
    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir"
    fi

    # Copy file
    if cp "$library_path" "$project_path"; then
        return 0
    else
        return 1
    fi
}

# Verify file checksum
verify_checksum() {
    local filepath="$1"
    local expected_sha256="$2"

    local actual_sha256
    actual_sha256=$(calculate_sha256 "$filepath")

    if [ -z "$actual_sha256" ]; then
        return 1
    fi

    if [ "$actual_sha256" = "$expected_sha256" ]; then
        return 0
    else
        return 1
    fi
}

# Git commit changes
git_commit_changes() {
    local project_dir="$1"
    local files_updated="$2"

    cd "$project_dir" || return 1

    # Check if git repo
    if [ ! -d ".git" ]; then
        return 0
    fi

    # Stage manifest and updated files
    git add "$MANIFEST_NAME" 2>/dev/null || true

    # Check if there are changes to commit
    if ! git diff --cached --quiet 2>/dev/null; then
        git commit -m "chore: update assets from CDN library

Updated $files_updated file(s) from central library.

🤖 Generated by propagate-cdn-updates.sh" 2>/dev/null || true
    fi
}

# ============================================================================
# REGISTRY-BASED FUNCTIONS
# ============================================================================

# Get projects using a file from registry (O(1) lookup)
get_projects_from_registry() {
    local library_dir="$1"
    local changed_file="$2"

    local registry_dir="$library_dir/.project-registry"
    local filename
    filename=$(basename "$changed_file")
    local registry_file="$registry_dir/${filename}.json"

    if [ ! -f "$registry_file" ]; then
        # No registry entry - file not used by any project
        return 1
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        log_warn "jq not installed - falling back to project scanning"
        return 1
    fi

    # Extract project info from registry: name|path|asset_path
    jq -r '.projects[] | "\(.name)|\(.path)|\(.asset_path)"' "$registry_file" 2>/dev/null
    return 0
}

# Process a single project
process_project() {
    local project_dir="$1"
    local changed_files=("${@:2}")
    local library_dir="$LIBRARY_DIR"
    local library_manifest="$library_dir/$MANIFEST_NAME"

    local project_name
    project_name=$(basename "$project_dir")

    local project_manifest="$project_dir/$MANIFEST_NAME"

    if [ ! -f "$project_manifest" ]; then
        log_skip "$project_name (no manifest)"
        ((STAT_SKIPPED++))
        return
    fi

    ((STAT_PROJECTS_SCANNED++))

    # Check if project uses any changed files
    local uses_changed=false
    local matched_files=()

    for changed_file in "${changed_files[@]}"; do
        if project_uses_file "$project_manifest" "$changed_file" "$library_dir"; then
            uses_changed=true
            matched_files+=("$changed_file")
        fi
    done

    if [ "$uses_changed" = false ]; then
        log_skip "$project_name (not affected)"
        ((STAT_SKIPPED++))
        return
    fi

    log_update "$project_name"
    ((STAT_PROJECTS_UPDATED++))
    AFFECTED_PROJECTS+=("$project_name")

    local files_updated=0
    local files_failed=0

    # Process each matched file
    for changed_file in "${matched_files[@]}"; do
        # Get library asset metadata
        local library_asset
        library_asset=$(get_library_asset "$library_manifest" "$changed_file")

        if [ -z "$library_asset" ] || [ "$library_asset" = "null" ]; then
            log_error "  ✗ $changed_file (not found in library manifest)"
            ((files_failed++))
            ((STAT_ERRORS++))
            continue
        fi

        # Find project asset path (may differ from library path)
        local project_asset_path
        project_asset_path=$(yq eval ".assets[] | select(.source | test(\"$changed_file\")) | .path" "$project_manifest" 2>/dev/null | head -1 || echo "")

        if [ -z "$project_asset_path" ] || [ "$project_asset_path" = "null" ]; then
            # Try filename match
            local filename
            filename=$(basename "$changed_file")
            project_asset_path=$(yq eval ".assets[] | select(.path | test(\"$filename\")) | select(.source | test(\"$library_dir\")) | .path" "$project_manifest" 2>/dev/null | head -1 || echo "")
        fi

        if [ -z "$project_asset_path" ] || [ "$project_asset_path" = "null" ]; then
            log_error "  ✗ $changed_file (not found in project manifest)"
            ((files_failed++))
            ((STAT_ERRORS++))
            continue
        fi

        local library_file="$library_dir/$changed_file"
        local project_file="$project_dir/$project_asset_path"

        # Copy file from library
        if ! copy_from_library "$library_file" "$project_file"; then
            log_error "  ✗ $changed_file (copy failed)"
            ((files_failed++))
            ((STAT_ERRORS++))
            continue
        fi

        # Verify checksum
        local expected_sha256
        expected_sha256=$(echo "$library_asset" | yq eval '.sha256' -)

        if ! verify_checksum "$project_file" "$expected_sha256"; then
            log_error "  ✗ $changed_file (checksum mismatch after copy)"
            ((files_failed++))
            ((STAT_ERRORS++))
            continue
        fi

        # Update project manifest
        update_project_asset "$project_manifest" "$project_asset_path" "$library_asset"
        ((STAT_MANIFESTS_UPDATED++))

        local file_size
        file_size=$(echo "$library_asset" | yq eval '.size' -)
        local size_human
        size_human=$(format_size "$file_size")

        log_success "  ✓ $changed_file → $project_asset_path ($size_human)"
        ((files_updated++))
        ((STAT_FILES_COPIED++))
    done

    # Git commit if enabled
    if [ "$GIT_COMMIT" = true ] && [ "$files_updated" -gt 0 ]; then
        if git_commit_changes "$project_dir" "$files_updated"; then
            log_success "  ✓ Git commit created"
        fi
    fi

    if [ "$files_failed" -gt 0 ]; then
        log_warn "  ⚠ $files_failed file(s) failed"
    fi
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

main() {
    # Parse options
    local changed_files=()

    while [ $# -gt 0 ]; do
        case "$1" in
            --git-commit)
                GIT_COMMIT=true
                ;;
            --projects-dir)
                PROJECTS_DIR="$2"
                shift
                ;;
            --library-dir)
                LIBRARY_DIR="$2"
                shift
                ;;
            --help)
                echo "Usage: propagate-cdn-updates.sh [OPTIONS] CHANGED_FILES..."
                echo ""
                echo "Options:"
                echo "  --git-commit        Commit changes to git (off by default)"
                echo "  --projects-dir DIR  Custom projects directory (default: ~/dev/projects)"
                echo "  --library-dir DIR   Custom library directory (default: ~/media/cdn)"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                changed_files+=("$1")
                ;;
        esac
        shift
    done

    # Validate inputs
    if [ ${#changed_files[@]} -eq 0 ]; then
        log_error "No changed files specified"
        echo "Usage: propagate-cdn-updates.sh [OPTIONS] CHANGED_FILES..."
        exit 1
    fi

    # Expand paths
    PROJECTS_DIR="${PROJECTS_DIR/#\~/$HOME}"
    LIBRARY_DIR="${LIBRARY_DIR/#\~/$HOME}"

    # Verify dependencies
    verify_dependencies

    # Verify library directory and manifest exist
    if [ ! -d "$LIBRARY_DIR" ]; then
        log_error "Library directory not found: $LIBRARY_DIR"
        exit 1
    fi

    local library_manifest="$LIBRARY_DIR/$MANIFEST_NAME"
    if [ ! -f "$library_manifest" ]; then
        log_error "Library manifest not found: $library_manifest"
        exit 1
    fi

    # Verify projects directory exists
    if [ ! -d "$PROJECTS_DIR" ]; then
        log_error "Projects directory not found: $PROJECTS_DIR"
        exit 1
    fi

    echo ""
    echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_BOLD}🔄 Propagate CDN Updates to Projects${COLOR_RESET}"
    echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
    log_info "Library: $LIBRARY_DIR"
    log_info "Projects: $PROJECTS_DIR"
    log_info "Changed files: ${#changed_files[@]}"
    if [ "$GIT_COMMIT" = true ]; then
        log_info "Git commits: enabled"
    fi
    echo ""

    # Process projects using registry (O(1) lookup) or fallback to scanning
    local use_registry=true
    local registry_dir="$LIBRARY_DIR/.project-registry"

    # Check if registry exists and jq is available
    if [ ! -d "$registry_dir" ] || ! command -v jq &> /dev/null; then
        use_registry=false
        if [ ! -d "$registry_dir" ]; then
            log_warn "Registry not found at $registry_dir - falling back to project scanning"
        else
            log_warn "jq not installed - falling back to project scanning"
        fi
    fi

    if [ "$use_registry" = true ]; then
        log_info "Using registry for O(1) project lookup..."
        echo ""

        # Track which projects we've already processed (avoid duplicates)
        local -a processed_projects=()

        # For each changed file, lookup affected projects from registry
        for changed_file in "${changed_files[@]}"; do
            local filename=$(basename "$changed_file")
            log_info "Checking registry for: $filename"

            if get_projects_from_registry "$LIBRARY_DIR" "$changed_file"; then
                # Parse registry output: name|path|asset_path
                while IFS='|' read -r proj_name proj_path proj_asset_path; do
                    # Skip if we've already processed this project
                    if [[ " ${processed_projects[@]} " =~ " ${proj_name} " ]]; then
                        continue
                    fi

                    log_info "  → Found in project: $proj_name"
                    process_project "$proj_path" "$changed_file"
                    processed_projects+=("$proj_name")
                done < <(get_projects_from_registry "$LIBRARY_DIR" "$changed_file")
            else
                log_info "  → No projects registered for this file"
            fi
        done

        if [ ${#processed_projects[@]} -eq 0 ]; then
            log_info "No projects found in registry for changed files"
        fi
    else
        # Fallback: scan all projects (original O(n) approach)
        log_info "Scanning all projects in $PROJECTS_DIR..."
        echo ""

        for project_dir in "$PROJECTS_DIR"/*/; do
            if [ ! -d "$project_dir" ]; then
                continue
            fi
            process_project "$project_dir" "${changed_files[@]}"
        done
    fi

    # Print summary
    echo ""
    echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_BOLD}📊 Propagation Summary${COLOR_RESET}"
    echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
    echo -e "  ${COLOR_BOLD}Projects scanned:${COLOR_RESET} $STAT_PROJECTS_SCANNED"
    echo -e "  ${COLOR_GREEN}${COLOR_BOLD}Projects updated:${COLOR_RESET} $STAT_PROJECTS_UPDATED"
    echo -e "  ${COLOR_GREEN}${COLOR_BOLD}Files copied:${COLOR_RESET} $STAT_FILES_COPIED"
    echo -e "  ${COLOR_GREEN}${COLOR_BOLD}Manifests updated:${COLOR_RESET} $STAT_MANIFESTS_UPDATED"
    echo -e "  ${COLOR_GRAY}Projects skipped:${COLOR_RESET} $STAT_SKIPPED"

    if [ "$STAT_ERRORS" -gt 0 ]; then
        echo -e "  ${COLOR_RED}${COLOR_BOLD}Errors:${COLOR_RESET} $STAT_ERRORS"
    fi

    echo ""

    if [ ${#AFFECTED_PROJECTS[@]} -gt 0 ]; then
        echo -e "${COLOR_BOLD}Affected projects:${COLOR_RESET}"
        for project in "${AFFECTED_PROJECTS[@]}"; do
            echo -e "  ${COLOR_GREEN}✓${COLOR_RESET} $project"
        done
        echo ""
    fi

    if [ "$STAT_ERRORS" -gt 0 ]; then
        log_warn "Completed with errors"
        exit 1
    else
        log_success "Propagation completed successfully"
        exit 0
    fi
}

# ============================================================================
# ENTRY POINT
# ============================================================================

main "$@"
