#!/usr/bin/env bash
# Application Cleanup Script
# Safely removes unwanted applications based on remove-apps.txt
#
# Usage:
#   ./scripts/apps/cleanup-apps.sh [OPTIONS]
#
# Options:
#   -h, --help        Show this help message
#   -v, --verbose     Show detailed output
#   -e, --execute     Actually remove apps (default is dry-run)
#   -y, --yes         Skip confirmation prompt (use with caution!)
#   -i, --input       Input file with apps to remove (default: applications/remove-apps.txt)
#
# Safety Features:
#   - Defaults to DRY-RUN mode (preview only)
#   - Requires --execute flag for actual deletions
#   - Asks for confirmation before proceeding
#   - Validates all app names before removal
#   - Logs all operations
#
# Examples:
#   ./scripts/apps/cleanup-apps.sh                  # Dry-run (safe preview)
#   ./scripts/apps/cleanup-apps.sh --execute        # Actually remove apps
#   ./scripts/apps/cleanup-apps.sh --execute --yes  # Skip confirmation

set -euo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"
# shellcheck source=../utils/detect-os.sh
source "$PROJECT_ROOT/scripts/utils/detect-os.sh"

# Default configuration
VERBOSE=0
DRY_RUN=1  # Safe default: dry-run mode
SKIP_CONFIRMATION=0
INPUT_FILE="$PROJECT_ROOT/applications/remove-apps.txt"

# Statistics
TOTAL_APPS=0
REMOVED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Application Cleanup Script

Safely removes unwanted applications based on remove-apps.txt.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help        Show this help message
    -v, --verbose     Show detailed output
    -e, --execute     Actually remove apps (default is DRY-RUN)
    -y, --yes         Skip confirmation prompt (use with caution!)
    -i, --input       Input file (default: applications/remove-apps.txt)

SAFETY FEATURES:
    - DRY-RUN by default (preview changes without executing)
    - Requires explicit --execute flag for actual deletions
    - Confirmation prompt before proceeding
    - Validates app names and existence
    - Logs all operations

EXAMPLES:
    $0                          # Safe preview (dry-run)
    $0 --execute                # Remove apps (with confirmation)
    $0 --execute --yes          # Remove apps (skip confirmation)
    $0 -v -e                    # Verbose output with execution

WORKFLOW:
    1. Run audit: ./scripts/apps/audit-apps.sh
    2. Edit remove list: vim applications/remove-apps.txt
    3. Test (dry-run): ./scripts/apps/cleanup-apps.sh
    4. Execute: ./scripts/apps/cleanup-apps.sh --execute

EXIT CODES:
    0    Success (all apps removed or dry-run completed)
    1    General error
    2    OS not supported (macOS only)
    3    Missing dependencies
    4    User cancelled operation
    5    Input file not found or empty

EOF
}

# Parse command-line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -e|--execute)
                DRY_RUN=0
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=1
                shift
                ;;
            -i|--input)
                if [[ -n "${2:-}" ]]; then
                    INPUT_FILE="$2"
                    shift 2
                else
                    log_error "Error: --input requires an argument"
                    exit 1
                fi
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if running on macOS
check_os() {
    local os
    os=$(detect_os)

    if [[ "$os" != "macos" ]]; then
        log_error "This script only works on macOS"
        log_info "Detected OS: $os"
        exit 2
    fi

    [[ $VERBOSE -eq 1 ]] && log_info "Running on macOS" || true
}

# Check required dependencies
check_dependencies() {
    local missing_deps=()

    # Check for brew (optional but recommended)
    if ! command -v brew &> /dev/null; then
        log_warning "Homebrew not found - will use manual removal only"
    fi

    # Basic Unix tools (should always be available)
    if ! command -v rm &> /dev/null; then
        missing_deps+=("rm")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 3
    fi

    [[ $VERBOSE -eq 1 ]] && log_success "All dependencies OK" || true
}

# =============================================================================
# Validation Functions
# =============================================================================

# Validate input file exists and is readable
validate_input_file() {
    if [[ ! -f "$INPUT_FILE" ]]; then
        log_error "Input file not found: $INPUT_FILE"
        log_info "Create this file with app names to remove (one per line)"
        log_info "Example:"
        echo "  echo 'google-chrome' >> $INPUT_FILE"
        echo "  echo 'firefox' >> $INPUT_FILE"
        exit 5
    fi

    if [[ ! -r "$INPUT_FILE" ]]; then
        log_error "Input file not readable: $INPUT_FILE"
        exit 5
    fi

    [[ $VERBOSE -eq 1 ]] && log_success "Input file found: $INPUT_FILE" || true
}

# Read and parse input file
read_app_list() {
    local apps=()

    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Skip comments (lines starting with #)
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip if empty after trimming
        [[ -z "$line" ]] && continue

        # Add to list
        apps+=("$line")
    done < "$INPUT_FILE"

    if [[ ${#apps[@]} -eq 0 ]]; then
        log_error "No applications listed in $INPUT_FILE"
        log_info "Add app names to remove (one per line)"
        exit 5
    fi

    echo "${apps[@]}"
}

# =============================================================================
# Application Detection Functions
# =============================================================================

# Check if app is managed by Homebrew
is_homebrew_app() {
    local app_name="$1"

    if ! command -v brew &> /dev/null; then
        return 1
    fi

    # Check if app is in brew list
    if brew list --cask 2>/dev/null | grep -q "^${app_name}$"; then
        return 0
    fi

    return 1
}

# Check if app exists in /Applications
app_exists() {
    local app_name="$1"

    # Check if .app bundle exists
    if [[ -d "/Applications/${app_name}.app" ]]; then
        return 0
    fi

    # Check if app name already includes .app extension
    if [[ -d "/Applications/${app_name}" ]]; then
        return 0
    fi

    return 1
}

# Get full app path
get_app_path() {
    local app_name="$1"

    if [[ -d "/Applications/${app_name}.app" ]]; then
        echo "/Applications/${app_name}.app"
    elif [[ -d "/Applications/${app_name}" ]]; then
        echo "/Applications/${app_name}"
    else
        echo ""
    fi
}

# =============================================================================
# Removal Functions
# =============================================================================

# Remove Homebrew-managed app
remove_homebrew_app() {
    local app_name="$1"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would run: brew uninstall --cask '$app_name'"
        return 0
    fi

    [[ $VERBOSE -eq 1 ]] && log_info "Uninstalling Homebrew cask: $app_name" || true

    if brew uninstall --cask "$app_name" 2>&1 | tee -a "$PROJECT_ROOT/applications/cleanup.log"; then
        log_success "Removed Homebrew app: $app_name"
        return 0
    else
        log_error "Failed to remove Homebrew app: $app_name"
        return 1
    fi
}

# Remove manually installed app
remove_manual_app() {
    local app_name="$1"
    local app_path
    app_path=$(get_app_path "$app_name")

    if [[ -z "$app_path" ]]; then
        log_error "App not found: $app_name"
        return 1
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would run: rm -rf '$app_path'"
        return 0
    fi

    [[ $VERBOSE -eq 1 ]] && log_info "Removing manual installation: $app_path" || true

    if rm -rf "$app_path" 2>&1 | tee -a "$PROJECT_ROOT/applications/cleanup.log"; then
        log_success "Removed manual app: $app_name"
        return 0
    else
        log_error "Failed to remove manual app: $app_name"
        log_error "You may need to manually remove it via Finder"
        return 1
    fi
}

# Remove single application
remove_app() {
    local app_name="$1"

    # Check if app exists
    if ! app_exists "$app_name" && ! is_homebrew_app "$app_name"; then
        log_warning "App not found (may already be removed): $app_name"
        ((SKIPPED_COUNT++))
        return 0
    fi

    # Determine removal method
    if is_homebrew_app "$app_name"; then
        [[ $VERBOSE -eq 1 ]] && log_info "Detected as Homebrew app: $app_name" || true
        if remove_homebrew_app "$app_name"; then
            ((REMOVED_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
    elif app_exists "$app_name"; then
        [[ $VERBOSE -eq 1 ]] && log_info "Detected as manual installation: $app_name" || true
        if remove_manual_app "$app_name"; then
            ((REMOVED_COUNT++))
        else
            ((FAILED_COUNT++))
        fi
    else
        log_warning "App not found: $app_name"
        ((SKIPPED_COUNT++))
    fi
}

# =============================================================================
# Main Cleanup Logic
# =============================================================================

# Show cleanup summary
show_summary() {
    local apps=("$@")

    echo ""
    log_step "Cleanup Summary"

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "${YELLOW}MODE: DRY-RUN (no actual changes)${NC}"
    else
        echo "${RED}MODE: EXECUTE (will remove apps)${NC}"
    fi

    echo ""
    echo "Applications to remove (${#apps[@]}):"
    echo ""

    local idx=1
    for app in "${apps[@]}"; do
        local status="❓"
        local method="Unknown"

        if is_homebrew_app "$app"; then
            status="📦"
            method="Homebrew"
        elif app_exists "$app"; then
            status="📱"
            method="Manual"
        else
            status="⚠️ "
            method="Not Found"
        fi

        printf "  %2d. %s %-40s (%s)\n" "$idx" "$status" "$app" "$method"
        ((idx++))
    done

    echo ""
}

# Ask for user confirmation
confirm_cleanup() {
    if [[ $SKIP_CONFIRMATION -eq 1 ]]; then
        log_warning "Skipping confirmation (--yes flag)"
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "This is a dry-run. No apps will be removed."
        return 0
    fi

    echo ""
    echo "${RED}⚠️  WARNING: This will permanently remove the listed applications${NC}"
    echo ""
    read -r -p "Do you want to proceed? (yes/no): " response

    case "$response" in
        yes|YES|y|Y)
            log_info "Proceeding with cleanup..."
            return 0
            ;;
        *)
            log_warning "Cleanup cancelled by user"
            exit 4
            ;;
    esac
}

# Execute cleanup for all apps
cleanup_apps() {
    local apps=("$@")

    TOTAL_APPS=${#apps[@]}

    log_step "Processing $TOTAL_APPS Applications"

    local idx=1
    for app in "${apps[@]}"; do
        echo ""
        log_info "[$idx/$TOTAL_APPS] Processing: $app"
        remove_app "$app"
        ((idx++))
    done
}

# Show final statistics
show_statistics() {
    echo ""
    log_step "Cleanup Statistics"

    echo "Total apps processed: $TOTAL_APPS"

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "Dry-run mode: No actual changes made"
        echo "Run with --execute to actually remove apps"
    else
        echo "Successfully removed: $REMOVED_COUNT"
        echo "Failed to remove: $FAILED_COUNT"
        echo "Skipped (not found): $SKIPPED_COUNT"

        if [[ $REMOVED_COUNT -gt 0 ]]; then
            log_success "Cleanup completed!"
            log_info "Log file: $PROJECT_ROOT/applications/cleanup.log"
        fi

        if [[ $FAILED_COUNT -gt 0 ]]; then
            log_warning "Some apps failed to remove - check log for details"
        fi
    fi

    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    parse_args "$@"
    check_os
    check_dependencies
    validate_input_file

    log_step "Application Cleanup"

    # Read app list
    local apps
    read -ra apps <<< "$(read_app_list)"

    [[ $VERBOSE -eq 1 ]] && log_info "Found ${#apps[@]} apps to process" || true

    # Show summary
    show_summary "${apps[@]}"

    # Confirm (if not dry-run and not skipped)
    confirm_cleanup

    # Execute cleanup
    cleanup_apps "${apps[@]}"

    # Show statistics
    show_statistics

    # Exit with appropriate code
    if [[ $DRY_RUN -eq 1 ]]; then
        exit 0
    elif [[ $FAILED_COUNT -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
