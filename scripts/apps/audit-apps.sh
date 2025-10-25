#!/usr/bin/env bash
# Application Audit Script
# Discovers and lists all installed applications on macOS
#
# Usage:
#   ./scripts/apps/audit-apps.sh [OPTIONS]
#
# Options:
#   -h, --help       Show this help message
#   -v, --verbose    Show detailed output
#   -o, --output     Output file (default: applications/current-apps.txt)
#
# Output:
#   Creates categorized list of applications:
#   - Homebrew Casks
#   - Mac App Store Apps
#   - Manual Installations
#
# Example:
#   ./scripts/apps/audit-apps.sh
#   ./scripts/apps/audit-apps.sh --verbose
#   ./scripts/apps/audit-apps.sh --output /tmp/apps.txt

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
OUTPUT_FILE="$PROJECT_ROOT/applications/current-apps.txt"

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Application Audit Script

Discovers and lists all installed applications on macOS.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help       Show this help message
    -v, --verbose    Show detailed output
    -o, --output     Output file (default: applications/current-apps.txt)

EXAMPLES:
    $0
    $0 --verbose
    $0 --output /tmp/apps.txt

OUTPUT:
    Creates categorized list with three sections:
    1. Homebrew Casks - Apps installed via brew
    2. Mac App Store Apps - Apps from MAS
    3. Manual Installations - Apps in /Applications

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported (macOS only)
    3    Missing dependencies

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
            -o|--output)
                if [[ -n "${2:-}" ]]; then
                    OUTPUT_FILE="$2"
                    shift 2
                else
                    log_error "Error: --output requires an argument"
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

    [[ $VERBOSE -eq 1 ]] && log_info "Running on macOS"
}

# Check required dependencies
check_dependencies() {
    local missing_deps=()

    # Check for brew (optional but recommended)
    if ! command -v brew &> /dev/null; then
        log_warning "Homebrew not found - Homebrew apps won't be listed"
    fi

    # Check for mas (optional but recommended)
    if ! command -v mas &> /dev/null; then
        log_warning "mas-cli not found - Mac App Store apps won't be listed"
        log_info "Install with: brew install mas"
    fi

    # Find command should always be available on macOS
    if ! command -v find &> /dev/null; then
        missing_deps+=("find")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        exit 3
    fi

    [[ $VERBOSE -eq 1 ]] && log_success "All dependencies OK"
}

# =============================================================================
# Application Discovery Functions
# =============================================================================

# List Homebrew cask applications
list_homebrew_casks() {
    if ! command -v brew &> /dev/null; then
        [[ $VERBOSE -eq 1 ]] && log_warning "Skipping Homebrew casks (brew not installed)" >&2
        return 0
    fi

    [[ $VERBOSE -eq 1 ]] && log_info "Discovering Homebrew casks..." >&2

    local casks
    casks=$(brew list --cask 2>/dev/null | sort)

    if [[ -z "$casks" ]]; then
        [[ $VERBOSE -eq 1 ]] && log_info "No Homebrew casks found" >&2
        return 0
    fi

    echo "$casks"
}

# List Mac App Store applications
list_mas_apps() {
    if ! command -v mas &> /dev/null; then
        [[ $VERBOSE -eq 1 ]] && log_warning "Skipping MAS apps (mas not installed)" >&2
        return 0
    fi

    [[ $VERBOSE -eq 1 ]] && log_info "Discovering Mac App Store apps..." >&2

    local mas_apps
    mas_apps=$(mas list 2>/dev/null | sort)

    if [[ -z "$mas_apps" ]]; then
        [[ $VERBOSE -eq 1 ]] && log_info "No Mac App Store apps found" >&2
        return 0
    fi

    echo "$mas_apps"
}

# List manually installed applications
list_manual_apps() {
    [[ $VERBOSE -eq 1 ]] && log_info "Discovering manual installations..." >&2

    # Find all .app bundles in /Applications
    local manual_apps
    manual_apps=$(find /Applications -maxdepth 1 -type d -name "*.app" 2>/dev/null | \
        sed 's|/Applications/||' | \
        sed 's|\.app$||' | \
        sort)

    if [[ -z "$manual_apps" ]]; then
        [[ $VERBOSE -eq 1 ]] && log_info "No manual installations found" >&2
        return 0
    fi

    echo "$manual_apps"
}

# Filter manual apps to exclude Homebrew-managed apps
filter_manual_apps() {
    local manual_apps="$1"
    local homebrew_casks="$2"

    if [[ -z "$homebrew_casks" ]]; then
        echo "$manual_apps"
        return 0
    fi

    # Convert cask names to app names (rough heuristic)
    # Example: google-chrome -> Google Chrome
    local filtered_apps=""

    while IFS= read -r app; do
        local is_homebrew=0

        # Check if app name (case-insensitive) matches any cask
        while IFS= read -r cask; do
            # Simple heuristic: convert cask name to app-like format
            local cask_normalized
            cask_normalized=$(echo "$cask" | tr '[:upper:]' '[:lower:]' | tr '-' ' ')
            local app_normalized
            app_normalized=$(echo "$app" | tr '[:upper:]' '[:lower:]')

            if [[ "$app_normalized" == *"$cask_normalized"* ]] || [[ "$cask_normalized" == *"$app_normalized"* ]]; then
                is_homebrew=1
                break
            fi
        done <<< "$homebrew_casks"

        # If not matched as Homebrew app, include in manual list
        if [[ $is_homebrew -eq 0 ]]; then
            filtered_apps+="$app"$'\n'
        fi
    done <<< "$manual_apps"

    echo "$filtered_apps"
}

# =============================================================================
# Report Generation
# =============================================================================

# Generate complete audit report
generate_audit_report() {
    local output_file="$1"
    local output_dir
    output_dir=$(dirname "$output_file")

    # Create output directory if it doesn't exist
    if [[ ! -d "$output_dir" ]]; then
        [[ $VERBOSE -eq 1 ]] && log_info "Creating directory: $output_dir"
        mkdir -p "$output_dir"
    fi

    log_step "Starting Application Audit"

    # Discover applications
    local homebrew_casks
    local mas_apps
    local manual_apps
    local manual_only_apps

    homebrew_casks=$(list_homebrew_casks)
    mas_apps=$(list_mas_apps)
    manual_apps=$(list_manual_apps)
    manual_only_apps=$(filter_manual_apps "$manual_apps" "$homebrew_casks")

    # Count applications
    local homebrew_count=0
    local mas_count=0
    local manual_count=0

    [[ -n "$homebrew_casks" ]] && homebrew_count=$(echo "$homebrew_casks" | grep -c '^' || echo 0)
    [[ -n "$mas_apps" ]] && mas_count=$(echo "$mas_apps" | grep -c '^' || echo 0)
    [[ -n "$manual_only_apps" ]] && manual_count=$(echo "$manual_only_apps" | grep -c '^' || echo 0)

    local total_count=$((homebrew_count + mas_count + manual_count))

    # Generate report
    {
        echo "Application Audit Report"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Total Applications: $total_count"
        echo ""
        echo "========================================================================"
        echo ""

        # Homebrew Casks Section
        echo "=== Homebrew Casks ($homebrew_count) ==="
        echo ""
        if [[ -n "$homebrew_casks" ]]; then
            echo "$homebrew_casks"
        else
            echo "(none)"
        fi
        echo ""
        echo "========================================================================"
        echo ""

        # Mac App Store Section
        echo "=== Mac App Store Apps ($mas_count) ==="
        echo ""
        if [[ -n "$mas_apps" ]]; then
            echo "$mas_apps"
        else
            echo "(none)"
        fi
        echo ""
        echo "========================================================================"
        echo ""

        # Manual Installations Section
        echo "=== Manual Installations ($manual_count) ==="
        echo ""
        if [[ -n "$manual_only_apps" ]]; then
            echo "$manual_only_apps"
        else
            echo "(none)"
        fi
        echo ""
        echo "========================================================================"
        echo ""
        echo "Notes:"
        echo "- Manual installations exclude apps already managed by Homebrew"
        echo "- To remove apps, add names to applications/remove-apps.txt"
        echo "- Then run: ./scripts/apps/cleanup-apps.sh --execute"

    } > "$output_file"

    log_success "Audit complete! Found $total_count applications"
    log_info "  Homebrew Casks: $homebrew_count"
    log_info "  Mac App Store: $mas_count"
    log_info "  Manual Installs: $manual_count"
    log_info ""
    log_success "Report saved to: $output_file"

    # Show next steps
    echo ""
    log_step "Next Steps"
    echo "1. Review the audit report: cat $output_file"
    echo "2. Add apps to remove: vim applications/remove-apps.txt"
    echo "3. Test cleanup (dry-run): ./scripts/apps/cleanup-apps.sh"
    echo "4. Execute cleanup: ./scripts/apps/cleanup-apps.sh --execute"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    parse_args "$@"
    check_os
    check_dependencies
    generate_audit_report "$OUTPUT_FILE"
}

# Run main function
main "$@"
