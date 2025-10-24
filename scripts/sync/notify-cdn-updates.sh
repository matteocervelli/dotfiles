#!/usr/bin/env bash
#
# notify-cdn-updates.sh
# Compare old and new CDN manifests and show update notifications
#
# Usage: ./scripts/sync/notify-cdn-updates.sh [CDN_DIR] [OLD_MANIFEST]
#
# Features:
# - Load and compare old vs new manifests
# - Detect added, removed, and modified files
# - Show dimension and size changes with percentages
# - Colored terminal output (green/red/yellow)
# - Generate Markdown report for commit messages
# - Summary statistics
#
# Requirements:
# - yq (brew install yq)

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_CDN_DIR="$HOME/media/cdn"
readonly MANIFEST_NAME=".r2-manifest.yml"

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
declare -i REMOVED_COUNT=0
declare -i UNCHANGED_COUNT=0
declare -i TOTAL_SIZE_DELTA=0

# Report storage
declare -a MARKDOWN_LINES=()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[✓]${COLOR_RESET} $*"
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
    if ! command -v yq &> /dev/null; then
        log_error "Missing required dependency: yq"
        log_error "Install with: brew install yq"
        exit 1
    fi
}

# Load manifest
load_manifest() {
    local manifest_file="$1"
    if [ ! -f "$manifest_file" ]; then
        echo ""
        return
    fi
    cat "$manifest_file"
}

# Get asset from manifest by path
get_asset() {
    local manifest="$1"
    local asset_path="$2"

    if [ -z "$manifest" ]; then
        echo ""
        return
    fi

    echo "$manifest" | yq eval ".assets[] | select(.path == \"$asset_path\")" - 2>/dev/null || echo ""
}

# Get all asset paths from manifest
get_all_paths() {
    local manifest="$1"

    if [ -z "$manifest" ]; then
        echo ""
        return
    fi

    echo "$manifest" | yq eval '.assets[].path' - 2>/dev/null || echo ""
}

# Add line to markdown report
add_markdown() {
    MARKDOWN_LINES+=("$*")
}

# ============================================================================
# COMPARISON LOGIC
# ============================================================================

compare_manifests() {
    local cdn_dir="${1:-$DEFAULT_CDN_DIR}"
    local old_manifest_file="${2:-}"

    # Expand tilde
    cdn_dir="${cdn_dir/#\~/$HOME}"

    local new_manifest_file="$cdn_dir/$MANIFEST_NAME"

    # Determine old manifest
    if [ -z "$old_manifest_file" ]; then
        # Use backup if exists
        if [ -f "${new_manifest_file}.backup" ]; then
            old_manifest_file="${new_manifest_file}.backup"
        else
            log_error "No old manifest found. Run generate-cdn-manifest.sh first."
            exit 1
        fi
    fi

    if [ ! -f "$new_manifest_file" ]; then
        log_error "New manifest not found: $new_manifest_file"
        log_error "Run generate-cdn-manifest.sh first."
        exit 1
    fi

    log_info "Comparing manifests..."
    log_info "Old: $old_manifest_file"
    log_info "New: $new_manifest_file"
    echo ""

    # Load manifests
    local old_manifest
    old_manifest=$(load_manifest "$old_manifest_file")

    local new_manifest
    new_manifest=$(load_manifest "$new_manifest_file")

    if [ -z "$new_manifest" ]; then
        log_error "Failed to load new manifest"
        exit 1
    fi

    # Initialize markdown report
    add_markdown "# CDN Asset Update Report"
    add_markdown ""
    add_markdown "Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    add_markdown ""
    add_markdown "## Changes"
    add_markdown ""

    # Track processed paths (using grep instead of associative array for bash 3 compatibility)
    local processed_paths_file="/tmp/processed-paths-$$-notify.txt"
    touch "$processed_paths_file"

    # Get all paths from new manifest
    local new_paths
    new_paths=$(get_all_paths "$new_manifest")

    # Check for new and updated files
    while IFS= read -r new_path; do
        if [ -z "$new_path" ] || [ "$new_path" = "null" ]; then
            continue
        fi

        # Track processed path
        echo "$new_path" >> "$processed_paths_file"

        local new_asset
        new_asset=$(get_asset "$new_manifest" "$new_path")

        local old_asset
        old_asset=$(get_asset "$old_manifest" "$new_path")

        if [ -z "$old_asset" ] || [ "$old_asset" = "null" ]; then
            # NEW FILE
            ((NEW_COUNT++))

            local size
            size=$(echo "$new_asset" | yq eval '.size' -)
            ((TOTAL_SIZE_DELTA += size))

            local size_human
            size_human=$(format_size "$size")

            local dimensions
            dimensions=$(echo "$new_asset" | yq eval '.dimensions | "\(.width)x\(.height)"' - 2>/dev/null || echo "")

            if [ -n "$dimensions" ] && [ "$dimensions" != "nullxnull" ]; then
                log_new "$new_path ($size_human, $dimensions)"
                add_markdown "- **[NEW]** \`$new_path\` ($size_human, $dimensions)"
            else
                log_new "$new_path ($size_human)"
                add_markdown "- **[NEW]** \`$new_path\` ($size_human)"
            fi

        else
            # EXISTING FILE - check if modified
            local old_sha256
            old_sha256=$(echo "$old_asset" | yq eval '.sha256' -)

            local new_sha256
            new_sha256=$(echo "$new_asset" | yq eval '.sha256' -)

            if [ "$old_sha256" != "$new_sha256" ]; then
                # UPDATED FILE
                ((UPDATED_COUNT++))

                log_updated "$new_path"
                add_markdown "- **[UPDATED]** \`$new_path\`"

                # Size comparison
                local old_size
                old_size=$(echo "$old_asset" | yq eval '.size' -)

                local new_size
                new_size=$(echo "$new_asset" | yq eval '.size' -)

                local delta=$((new_size - old_size))
                ((TOTAL_SIZE_DELTA += delta))

                local old_size_human
                old_size_human=$(format_size "$old_size")

                local new_size_human
                new_size_human=$(format_size "$new_size")

                local delta_human
                delta_human=$(format_size "${delta#-}")

                local percent
                if [ "$old_size" -gt 0 ]; then
                    percent=$(echo "scale=1; ($delta * 100) / $old_size" | bc 2>/dev/null || echo "0")
                else
                    percent="N/A"
                fi

                if [ "$delta" -gt 0 ]; then
                    echo -e "    ${COLOR_GRAY}Size: $old_size_human → $new_size_human (+$delta_human, +$percent%)${COLOR_RESET}"
                    add_markdown "  - Size: $old_size_human → $new_size_human (+$delta_human, +$percent%)"
                elif [ "$delta" -lt 0 ]; then
                    echo -e "    ${COLOR_GRAY}Size: $old_size_human → $new_size_human (-$delta_human, $percent%)${COLOR_RESET}"
                    add_markdown "  - Size: $old_size_human → $new_size_human (-$delta_human, $percent%)"
                else
                    echo -e "    ${COLOR_GRAY}Size: unchanged ($new_size_human)${COLOR_RESET}"
                    add_markdown "  - Size: unchanged ($new_size_human)"
                fi

                # Dimension comparison
                local old_dims
                old_dims=$(echo "$old_asset" | yq eval '.dimensions | "\(.width)x\(.height)"' - 2>/dev/null || echo "")

                local new_dims
                new_dims=$(echo "$new_asset" | yq eval '.dimensions | "\(.width)x\(.height)"' - 2>/dev/null || echo "")

                if [ -n "$old_dims" ] && [ "$old_dims" != "nullxnull" ]; then
                    if [ -n "$new_dims" ] && [ "$new_dims" != "nullxnull" ] && [ "$old_dims" != "$new_dims" ]; then
                        # Dimensions changed
                        local old_w old_h new_w new_h
                        old_w=$(echo "$old_dims" | cut -d'x' -f1)
                        old_h=$(echo "$old_dims" | cut -d'x' -f2)
                        new_w=$(echo "$new_dims" | cut -d'x' -f1)
                        new_h=$(echo "$new_dims" | cut -d'x' -f2)

                        local w_delta=$((new_w - old_w))
                        local h_delta=$((new_h - old_h))

                        local w_sign=""
                        local h_sign=""
                        [ "$w_delta" -gt 0 ] && w_sign="+"
                        [ "$h_delta" -gt 0 ] && h_sign="+"

                        local w_percent h_percent
                        if [ "$old_w" -gt 0 ]; then
                            w_percent=$(echo "scale=1; ($w_delta * 100) / $old_w" | bc 2>/dev/null || echo "0")
                        else
                            w_percent="N/A"
                        fi

                        if [ "$old_h" -gt 0 ]; then
                            h_percent=$(echo "scale=1; ($h_delta * 100) / $old_h" | bc 2>/dev/null || echo "0")
                        else
                            h_percent="N/A"
                        fi

                        echo -e "    ${COLOR_GRAY}Dimensions: $old_dims → $new_dims (${w_sign}${w_delta}×${h_sign}${h_delta}, ${w_sign}${w_percent}%×${h_sign}${h_percent}%)${COLOR_RESET}"
                        add_markdown "  - Dimensions: $old_dims → $new_dims (${w_sign}${w_delta}×${h_sign}${h_delta}, ${w_sign}${w_percent}%×${h_sign}${h_percent}%)"
                    fi
                fi

                # SHA256 change
                echo -e "    ${COLOR_GRAY}SHA256: ${old_sha256:0:12}... → ${new_sha256:0:12}...${COLOR_RESET}"
                add_markdown "  - SHA256: \`${old_sha256:0:12}...\` → \`${new_sha256:0:12}...\`"

            else
                # UNCHANGED FILE
                ((UNCHANGED_COUNT++))
            fi
        fi

    done <<< "$new_paths"

    # Check for removed files
    if [ -n "$old_manifest" ]; then
        local old_paths
        old_paths=$(get_all_paths "$old_manifest")

        while IFS= read -r old_path; do
            if [ -z "$old_path" ] || [ "$old_path" = "null" ]; then
                continue
            fi

            if ! grep -Fxq "$old_path" "$processed_paths_file" 2>/dev/null; then
                # REMOVED FILE
                ((REMOVED_COUNT++))

                log_removed "$old_path (deleted)"
                add_markdown "- **[REMOVED]** \`$old_path\`"

                local old_asset_removed
                old_asset_removed=$(get_asset "$old_manifest" "$old_path")

                local old_size_removed
                old_size_removed=$(echo "$old_asset_removed" | yq eval '.size' - 2>/dev/null || echo "0")
                ((TOTAL_SIZE_DELTA -= old_size_removed))

                local old_size_human
                old_size_human=$(format_size "$old_size_removed")
                add_markdown "  - Size: $old_size_human (freed)"
            fi
        done <<< "$old_paths"
    fi

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

    # Add summary to markdown
    add_markdown ""
    add_markdown "## Summary"
    add_markdown ""
    add_markdown "- **New files**: $NEW_COUNT"
    add_markdown "- **Updated files**: $UPDATED_COUNT"
    add_markdown "- **Removed files**: $REMOVED_COUNT"
    add_markdown "- **Unchanged files**: $UNCHANGED_COUNT"
    add_markdown "- **Total files**: $total_count"
    add_markdown "- **Size delta**: ${delta_sign}${delta_human}"

    # Generate markdown report file
    local report_file="$cdn_dir/update-report-$(date +%Y%m%d-%H%M%S).md"
    printf "%s\n" "${MARKDOWN_LINES[@]}" > "$report_file"

    # Cleanup
    rm -f "$processed_paths_file"

    echo ""
    log_success "Markdown report generated: $report_file"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    verify_dependencies
    compare_manifests "$@"
}

main "$@"
