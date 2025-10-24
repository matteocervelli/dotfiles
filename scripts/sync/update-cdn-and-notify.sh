#!/usr/bin/env bash
#
# update-cdn-and-notify.sh
# Orchestrate CDN update workflow with notifications and propagation
#
# Usage: ./scripts/sync/update-cdn-and-notify.sh [CDN_DIR] [OPTIONS]
#
# Workflow:
# 1. Backup current manifest
# 2. Regenerate central manifest
# 3. Show update notifications (dimensions, size changes)
# 4. Prompt to propagate updates to projects
# 5. Prompt to sync to R2
# 6. Show final summary
#
# Options:
#   --auto-propagate    Skip propagation prompt (auto-yes)
#   --auto-sync         Skip R2 sync prompt (auto-yes)
#   --no-propagate      Skip propagation step
#   --no-sync           Skip R2 sync step
#
# Requirements:
# - generate-cdn-manifest.sh
# - notify-cdn-updates.sh
# - propagate-cdn-updates.sh (optional)
# - rclone-cdn-sync (optional)

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly DEFAULT_CDN_DIR="$HOME/media/cdn"
readonly MANIFEST_NAME=".r2-manifest.yml"

# Scripts
readonly GENERATE_SCRIPT="$SCRIPT_DIR/generate-cdn-manifest.sh"
readonly NOTIFY_SCRIPT="$SCRIPT_DIR/notify-cdn-updates.sh"
readonly PROPAGATE_SCRIPT="$SCRIPT_DIR/propagate-cdn-updates.sh"

# ANSI Colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_BOLD='\033[1m'

# Flags
AUTO_PROPAGATE=false
AUTO_SYNC=false
NO_PROPAGATE=false
NO_SYNC=false

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

log_section() {
    echo ""
    echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_BOLD}$*${COLOR_RESET}"
    echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""
}

# Sanitize path (prevent directory traversal)
sanitize_path() {
    local path="$1"
    echo "$path" | sed 's/\.\.\///g' | tr -d '\n\r'
}

# Verify dependencies
verify_dependencies() {
    local missing=()

    if [ ! -f "$GENERATE_SCRIPT" ]; then
        missing+=("generate-cdn-manifest.sh")
    fi

    if [ ! -f "$NOTIFY_SCRIPT" ]; then
        missing+=("notify-cdn-updates.sh")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required scripts: ${missing[*]}"
        log_error "Location: $SCRIPT_DIR/"
        exit 1
    fi
}

# Prompt user for confirmation
prompt_yes_no() {
    local message="$1"
    local default="${2:-n}"

    local prompt_str="[y/N]"
    if [ "$default" = "y" ]; then
        prompt_str="[Y/n]"
    fi

    while true; do
        read -r -p "$(echo -e "${COLOR_YELLOW}?${COLOR_RESET} $message $prompt_str ") " response
        response=${response:-$default}
        case "${response,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Extract changed file paths from comparison
extract_changed_files() {
    local cdn_dir="$1"
    local old_manifest="$2"
    local new_manifest="$3"

    local changed_files=()

    # Get new/updated files from new manifest
    if [ -f "$new_manifest" ]; then
        # Compare with old manifest
        if [ -f "$old_manifest" ]; then
            # Extract paths where SHA256 differs or file is new
            while IFS= read -r path; do
                if [ -z "$path" ] || [ "$path" = "null" ]; then
                    continue
                fi

                local old_sha
                old_sha=$(yq eval ".assets[] | select(.path == \"$path\") | .sha256" "$old_manifest" 2>/dev/null || echo "")

                local new_sha
                new_sha=$(yq eval ".assets[] | select(.path == \"$path\") | .sha256" "$new_manifest" 2>/dev/null || echo "")

                if [ -z "$old_sha" ] || [ "$old_sha" = "null" ] || [ "$old_sha" != "$new_sha" ]; then
                    changed_files+=("$path")
                fi
            done < <(yq eval '.assets[].path' "$new_manifest" 2>/dev/null || echo "")
        else
            # No old manifest - all files are new
            while IFS= read -r path; do
                if [ -n "$path" ] && [ "$path" != "null" ]; then
                    changed_files+=("$path")
                fi
            done < <(yq eval '.assets[].path' "$new_manifest" 2>/dev/null || echo "")
        fi
    fi

    printf "%s\n" "${changed_files[@]}"
}

# Find rclone-cdn-sync command
find_rclone_sync() {
    # Try various locations
    local locations=(
        "$DOTFILES_ROOT/stow-packages/bin/.local/bin/rclone-cdn-sync"
        "$HOME/.local/bin/rclone-cdn-sync"
        "$(command -v rclone-cdn-sync 2>/dev/null || echo "")"
    )

    for loc in "${locations[@]}"; do
        if [ -n "$loc" ] && [ -f "$loc" ] && [ -x "$loc" ]; then
            echo "$loc"
            return 0
        fi
    done

    return 1
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

main() {
    local cdn_dir="${1:-$DEFAULT_CDN_DIR}"
    shift || true

    # Parse options
    while [ $# -gt 0 ]; do
        case "$1" in
            --auto-propagate) AUTO_PROPAGATE=true ;;
            --auto-sync) AUTO_SYNC=true ;;
            --no-propagate) NO_PROPAGATE=true ;;
            --no-sync) NO_SYNC=true ;;
            --help)
                echo "Usage: update-cdn-and-notify.sh [CDN_DIR] [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --auto-propagate    Skip propagation prompt (auto-yes)"
                echo "  --auto-sync         Skip R2 sync prompt (auto-yes)"
                echo "  --no-propagate      Skip propagation step"
                echo "  --no-sync           Skip R2 sync step"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done

    # Sanitize and expand path
    cdn_dir=$(sanitize_path "$cdn_dir")
    cdn_dir="${cdn_dir/#\~/$HOME}"

    if [ ! -d "$cdn_dir" ]; then
        log_error "CDN directory not found: $cdn_dir"
        exit 1
    fi

    verify_dependencies

    local manifest_file="$cdn_dir/$MANIFEST_NAME"
    local backup_manifest="${manifest_file}.backup"

    log_section "📦 CDN Update & Notification Workflow"
    log_info "CDN Directory: $cdn_dir"
    echo ""

    # Step 1: Backup current manifest
    log_info "Step 1: Backing up current manifest..."
    if [ -f "$manifest_file" ]; then
        cp "$manifest_file" "$backup_manifest"
        log_success "Backup created: $backup_manifest"
    else
        log_warn "No existing manifest to backup"
        backup_manifest=""
    fi
    echo ""

    # Step 2: Regenerate manifest
    log_info "Step 2: Regenerating central manifest..."
    if ! "$GENERATE_SCRIPT" "$cdn_dir"; then
        log_error "Failed to generate manifest"
        exit 1
    fi
    echo ""

    # Step 3: Show notifications
    log_section "📊 Change Notification"
    if [ -n "$backup_manifest" ]; then
        if ! "$NOTIFY_SCRIPT" "$cdn_dir" "$backup_manifest"; then
            log_warn "Notification script failed, continuing..."
        fi
    else
        log_info "First run - no changes to report"
    fi
    echo ""

    # Step 4: Extract changed files
    local changed_files=()
    if [ -n "$backup_manifest" ] && [ -f "$manifest_file" ]; then
        mapfile -t changed_files < <(extract_changed_files "$cdn_dir" "$backup_manifest" "$manifest_file")
    fi

    if [ ${#changed_files[@]} -eq 0 ]; then
        log_info "No file changes detected"
        log_success "CDN manifest is up to date"
        exit 0
    fi

    log_info "Changed files detected: ${#changed_files[@]}"

    # Step 5: Propagate to projects (if not disabled)
    if [ "$NO_PROPAGATE" = false ]; then
        echo ""
        log_section "🔄 Propagate Updates to Projects"

        local do_propagate=false
        if [ "$AUTO_PROPAGATE" = true ]; then
            log_info "Auto-propagate enabled"
            do_propagate=true
        elif prompt_yes_no "Propagate updates to projects using these files?" "y"; then
            do_propagate=true
        fi

        if [ "$do_propagate" = true ]; then
            if [ -f "$PROPAGATE_SCRIPT" ]; then
                echo ""
                log_info "Running propagation..."
                if "$PROPAGATE_SCRIPT" "${changed_files[@]}"; then
                    log_success "Propagation completed"
                else
                    log_error "Propagation failed (exit code: $?)"
                fi
            else
                log_warn "Propagation script not found: $PROPAGATE_SCRIPT"
                log_warn "Skipping propagation"
            fi
        else
            log_info "Propagation skipped by user"
        fi
    else
        log_info "Propagation disabled (--no-propagate)"
    fi

    # Step 6: Sync to R2 (if not disabled)
    if [ "$NO_SYNC" = false ]; then
        echo ""
        log_section "☁️  Sync to R2"

        local do_sync=false
        if [ "$AUTO_SYNC" = true ]; then
            log_info "Auto-sync enabled"
            do_sync=true
        elif prompt_yes_no "Sync changes to R2?" "y"; then
            do_sync=true
        fi

        if [ "$do_sync" = true ]; then
            local rclone_sync
            if rclone_sync=$(find_rclone_sync); then
                echo ""
                log_info "Running R2 sync..."
                if "$rclone_sync"; then
                    log_success "R2 sync completed"
                else
                    log_error "R2 sync failed (exit code: $?)"
                fi
            else
                log_warn "rclone-cdn-sync not found"
                log_info "Sync manually with: rclone-cdn-sync"
            fi
        else
            log_info "R2 sync skipped by user"
        fi
    else
        log_info "R2 sync disabled (--no-sync)"
    fi

    # Final summary
    echo ""
    log_section "✅ Workflow Complete"
    log_success "CDN manifest updated"
    log_info "Changed files: ${#changed_files[@]}"
    echo ""
}

# ============================================================================
# ENTRY POINT
# ============================================================================

main "$@"
