#!/usr/bin/env bash
# Application Comparison Script
# Compare application audits between machines or against Brewfile
#
# Usage:
#   ./scripts/apps/compare-apps.sh [OPTIONS] FILE1 FILE2
#   ./scripts/apps/compare-apps.sh --brewfile
#
# Options:
#   -h, --help         Show this help message
#   -b, --brewfile     Compare current audit against Brewfile
#   -v, --verbose      Show detailed output
#
# Examples:
#   # Compare MacBook vs Mac Studio
#   ./scripts/apps/compare-apps.sh \
#     applications/current_macos_apps_2025-10-25.txt \
#     applications/mac-studio-apps-2025-10-20.txt
#
#   # Compare current system against Brewfile
#   ./scripts/apps/compare-apps.sh --brewfile

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Default configuration
VERBOSE=0
COMPARE_BREWFILE=0
FILE1=""
FILE2=""

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Application Comparison Script

Compare application audits between machines or against Brewfile.

USAGE:
    $0 [OPTIONS] FILE1 FILE2
    $0 --brewfile

OPTIONS:
    -h, --help         Show this help message
    -b, --brewfile     Compare current audit against Brewfile
    -v, --verbose      Show detailed output

EXAMPLES:
    # Compare two machine audits
    $0 applications/macbook-apps.txt applications/mac-studio-apps.txt

    # Compare current machine vs Brewfile
    $0 --brewfile

    # Save comparison to file
    $0 applications/file1.txt applications/file2.txt > comparison.txt

OUTPUT:
    Shows three sections:
    1. Only in FILE1 (or Current Machine) - apps to add to FILE2
    2. Only in FILE2 (or Brewfile) - apps to add to FILE1
    3. In Both - apps that match

EXIT CODES:
    0    Success
    1    General error
    2    Missing files or dependencies

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
            -b|--brewfile)
                COMPARE_BREWFILE=1
                shift
                ;;
            *)
                if [[ -z "$FILE1" ]]; then
                    FILE1="$1"
                elif [[ -z "$FILE2" ]]; then
                    FILE2="$1"
                else
                    log_error "Too many arguments"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Extract application names from audit file
extract_apps_from_audit() {
    local audit_file="$1"
    local category="$2"  # "casks", "formulae", "mas", "manual", or "all"

    if [[ ! -f "$audit_file" ]]; then
        log_error "Audit file not found: $audit_file"
        return 1
    fi

    case "$category" in
        casks)
            sed -n '/=== Homebrew Casks/,/===/p' "$audit_file" | \
                grep -v "^===" | grep -v "^$" | grep -v "^(" | sed 's/^[[:space:]]*//'
            ;;
        formulae)
            sed -n '/=== Homebrew Formulae/,/===/p' "$audit_file" | \
                grep -v "^===" | grep -v "^$" | grep -v "^(" | sed 's/^[[:space:]]*//'
            ;;
        mas)
            sed -n '/=== Mac App Store/,/===/p' "$audit_file" | \
                grep -v "^===" | grep -v "^$" | grep -v "^(" | \
                sed 's/^[[:space:]]*//' | awk '{print $1}'
            ;;
        manual)
            sed -n '/=== Manual Installations/,/===/p' "$audit_file" | \
                grep -v "^===" | grep -v "^$" | grep -v "^(" | grep -v "^Notes:" | \
                grep -v "^-" | sed 's/^[[:space:]]*//'
            ;;
        all)
            {
                extract_apps_from_audit "$audit_file" "casks"
                extract_apps_from_audit "$audit_file" "formulae"
                extract_apps_from_audit "$audit_file" "mas"
                extract_apps_from_audit "$audit_file" "manual"
            } | sort -u
            ;;
        *)
            log_error "Unknown category: $category"
            return 1
            ;;
    esac
}

# Extract packages from Brewfile
extract_from_brewfile() {
    local brewfile="$PROJECT_ROOT/system/macos/Brewfile"
    local type="$1"  # "cask", "brew", or "all"

    if [[ ! -f "$brewfile" ]]; then
        log_error "Brewfile not found: $brewfile"
        return 1
    fi

    case "$type" in
        cask)
            grep '^cask ' "$brewfile" | awk '{print $2}' | tr -d '"' | sort
            ;;
        brew)
            grep '^brew ' "$brewfile" | awk '{print $2}' | tr -d '"' | sort
            ;;
        all)
            {
                extract_from_brewfile "cask"
                extract_from_brewfile "brew"
            } | sort -u
            ;;
        *)
            log_error "Unknown type: $type"
            return 1
            ;;
    esac
}

# Compare two lists and show differences
compare_lists() {
    local list1="$1"
    local list2="$2"
    local label1="$3"
    local label2="$4"

    # Create temp files
    local tmp1=$(mktemp)
    local tmp2=$(mktemp)
    local only_in_1=$(mktemp)
    local only_in_2=$(mktemp)
    local in_both=$(mktemp)

    # Write lists to temp files
    echo "$list1" | sort -u > "$tmp1"
    echo "$list2" | sort -u > "$tmp2"

    # Find differences
    comm -23 "$tmp1" "$tmp2" > "$only_in_1"
    comm -13 "$tmp1" "$tmp2" > "$only_in_2"
    comm -12 "$tmp1" "$tmp2" > "$in_both"

    # Count items
    local count_only_1=$(wc -l < "$only_in_1" | tr -d ' ')
    local count_only_2=$(wc -l < "$only_in_2" | tr -d ' ')
    local count_both=$(wc -l < "$in_both" | tr -d ' ')

    # Display results
    echo "========================================================================"
    echo "Application Comparison Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "Source 1: $label1"
    echo "Source 2: $label2"
    echo ""
    echo "Summary:"
    echo "  Only in $label1: $count_only_1"
    echo "  Only in $label2: $count_only_2"
    echo "  In Both: $count_both"
    echo "========================================================================"
    echo ""

    # Only in first file
    echo "=== Only in $label1 ($count_only_1) ==="
    echo ""
    if [[ $count_only_1 -gt 0 ]]; then
        cat "$only_in_1"
    else
        echo "(none)"
    fi
    echo ""
    echo "========================================================================"
    echo ""

    # Only in second file
    echo "=== Only in $label2 ($count_only_2) ==="
    echo ""
    if [[ $count_only_2 -gt 0 ]]; then
        cat "$only_in_2"
    else
        echo "(none)"
    fi
    echo ""
    echo "========================================================================"
    echo ""

    # In both
    echo "=== In Both ($count_both) ==="
    echo ""
    if [[ $count_both -gt 0 ]]; then
        cat "$in_both"
    else
        echo "(none)"
    fi
    echo ""
    echo "========================================================================"

    # Cleanup
    rm -f "$tmp1" "$tmp2" "$only_in_1" "$only_in_2" "$in_both"
}

# Compare current audit against Brewfile
compare_with_brewfile() {
    log_step "Comparing Current System vs Brewfile"

    # Find latest audit file
    local latest_audit=$(find "$PROJECT_ROOT/applications" -name "current_macos_apps_*.txt" -type f | sort -r | head -n 1)

    if [[ -z "$latest_audit" ]]; then
        log_error "No audit file found. Run: ./scripts/apps/audit-apps.sh"
        exit 2
    fi

    [[ $VERBOSE -eq 1 ]] && log_info "Using audit: $(basename "$latest_audit")"

    # Extract applications
    log_info "Extracting applications from audit..."
    local current_apps=$(extract_apps_from_audit "$latest_audit" "all")

    log_info "Extracting packages from Brewfile..."
    local brewfile_apps=$(extract_from_brewfile "all")

    # Compare
    compare_lists "$current_apps" "$brewfile_apps" "Current System" "Brewfile"

    echo ""
    log_step "Recommendations"
    echo ""
    echo "Apps only on current system:"
    echo "  → Add to Brewfile: ./scripts/apps/generate-brewfile.sh"
    echo "  → Or remove: Add to applications/remove-apps.txt"
    echo ""
    echo "Apps only in Brewfile:"
    echo "  → Install: brew bundle install --file=system/macos/Brewfile"
    echo "  → Or remove from Brewfile if no longer needed"
}

# Compare two audit files
compare_two_audits() {
    local file1="$1"
    local file2="$2"

    if [[ ! -f "$file1" ]]; then
        log_error "File not found: $file1"
        exit 2
    fi

    if [[ ! -f "$file2" ]]; then
        log_error "File not found: $file2"
        exit 2
    fi

    log_step "Comparing Application Audits"
    [[ $VERBOSE -eq 1 ]] && log_info "File 1: $file1"
    [[ $VERBOSE -eq 1 ]] && log_info "File 2: $file2"

    # Extract applications
    log_info "Extracting applications from File 1..."
    local apps1=$(extract_apps_from_audit "$file1" "all")

    log_info "Extracting applications from File 2..."
    local apps2=$(extract_apps_from_audit "$file2" "all")

    # Compare
    compare_lists "$apps1" "$apps2" "$(basename "$file1")" "$(basename "$file2")"

    echo ""
    log_step "Sync Recommendations"
    echo ""
    echo "To sync File 1 → File 2:"
    echo "  → Review 'Only in File 1' section"
    echo "  → Install those apps on machine 2"
    echo ""
    echo "To sync File 2 → File 1:"
    echo "  → Review 'Only in File 2' section"
    echo "  → Install those apps on machine 1"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    parse_args "$@"

    if [[ $COMPARE_BREWFILE -eq 1 ]]; then
        # Compare current system against Brewfile
        compare_with_brewfile
    elif [[ -n "$FILE1" && -n "$FILE2" ]]; then
        # Compare two audit files
        compare_two_audits "$FILE1" "$FILE2"
    else
        log_error "Missing arguments"
        echo ""
        show_help
        exit 1
    fi
}

# Run main function
main "$@"
