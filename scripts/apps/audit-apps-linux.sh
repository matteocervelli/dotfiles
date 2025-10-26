#!/usr/bin/env bash
# Linux Application Audit Script
# Discovers and lists all installed packages on Linux distributions
#
# Usage:
#   ./scripts/apps/audit-apps-linux.sh [OPTIONS]
#
# Options:
#   -h, --help       Show this help message
#   -v, --verbose    Show detailed output
#   -o, --output     Output file (default: applications/current_linux_apps_YYYY-MM-DD.txt)
#
# Supported Distributions:
#   - Ubuntu/Debian (APT + Snap + Flatpak)
#   - Fedora/RHEL (DNF + Flatpak)
#   - Arch Linux (Pacman + AUR + Flatpak)
#
# Output:
#   Creates categorized list of packages from all package managers
#
# Example:
#   ./scripts/apps/audit-apps-linux.sh
#   ./scripts/apps/audit-apps-linux.sh --verbose
#   ./scripts/apps/audit-apps-linux.sh --output /tmp/packages.txt

set -eo pipefail

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
OUTPUT_FILE="$PROJECT_ROOT/applications/current_linux_apps_$(date +%Y-%m-%d).txt"

# Distribution and package manager detection
DISTRO=""
DISTRO_VERSION=""
HAS_APT=0
HAS_DNF=0
HAS_PACMAN=0
HAS_SNAP=0
HAS_FLATPAK=0
HAS_AUR_HELPER=""

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Linux Application Audit Script

Discovers and lists all installed packages on Linux distributions.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help       Show this help message
    -v, --verbose    Show detailed output
    -o, --output     Output file (default: applications/current_linux_apps_YYYY-MM-DD.txt)

SUPPORTED DISTRIBUTIONS:
    - Ubuntu/Debian (APT + Snap + Flatpak)
    - Fedora/RHEL (DNF + Flatpak)
    - Arch Linux (Pacman + AUR + Flatpak)

EXAMPLES:
    $0
    $0 --verbose
    $0 --output /tmp/linux-packages.txt

OUTPUT:
    Creates categorized list with sections for each package manager:
    1. Native Packages (APT/DNF/Pacman)
    2. Snap Packages
    3. Flatpak Applications
    4. AUR Packages (Arch only)

EXIT CODES:
    0    Success
    1    General error
    2    OS not supported (Linux only)
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

# Detect Linux distribution
detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "/etc/os-release not found - cannot detect distribution"
        return 1
    fi

    # Source os-release for distribution info
    # shellcheck source=/dev/null
    source /etc/os-release

    DISTRO="${ID:-unknown}"
    DISTRO_VERSION="${VERSION_ID:-unknown}"

    [[ $VERBOSE -eq 1 ]] && log_info "Detected distribution: $DISTRO $DISTRO_VERSION ($NAME)" || true

    # Normalize distribution name
    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop)
            DISTRO="debian-based"
            ;;
        fedora|rhel|centos|rocky|almalinux)
            DISTRO="fedora-based"
            ;;
        arch|manjaro|endeavouros)
            DISTRO="arch-based"
            ;;
        *)
            log_warning "Distribution '$DISTRO' may not be fully supported" || true
            ;;
    esac
}

# Detect available package managers
detect_package_managers() {
    # Native package managers
    if command -v apt-get >/dev/null 2>&1; then
        HAS_APT=1
        [[ $VERBOSE -eq 1 ]] && log_info "Found APT package manager" || true
    fi

    if command -v dnf >/dev/null 2>&1; then
        HAS_DNF=1
        [[ $VERBOSE -eq 1 ]] && log_info "Found DNF package manager" || true
    fi

    if command -v pacman >/dev/null 2>&1; then
        HAS_PACMAN=1
        [[ $VERBOSE -eq 1 ]] && log_info "Found Pacman package manager" || true
    fi

    # Universal package managers
    if command -v snap >/dev/null 2>&1; then
        HAS_SNAP=1
        [[ $VERBOSE -eq 1 ]] && log_info "Found Snap package manager" || true
    fi

    if command -v flatpak >/dev/null 2>&1; then
        HAS_FLATPAK=1
        [[ $VERBOSE -eq 1 ]] && log_info "Found Flatpak package manager" || true
    fi

    # AUR helpers (Arch only)
    if command -v yay >/dev/null 2>&1; then
        HAS_AUR_HELPER="yay"
        [[ $VERBOSE -eq 1 ]] && log_info "Found AUR helper: yay" || true
    elif command -v paru >/dev/null 2>&1; then
        HAS_AUR_HELPER="paru"
        [[ $VERBOSE -eq 1 ]] && log_info "Found AUR helper: paru" || true
    fi
}

# List APT packages
list_apt_packages() {
    if [[ $HAS_APT -eq 0 ]]; then
        return 0
    fi

    log_info "Discovering APT packages..."

    # Get installed packages (skip header line)
    apt list --installed 2>/dev/null | tail -n +2 | cut -d'/' -f1 | sort -u
}

# List DNF packages
list_dnf_packages() {
    if [[ $HAS_DNF -eq 0 ]]; then
        return 0
    fi

    log_info "Discovering DNF packages..."

    # Get installed packages
    dnf list installed 2>/dev/null | tail -n +2 | awk '{print $1}' | cut -d'.' -f1 | sort -u
}

# List Pacman packages
list_pacman_packages() {
    if [[ $HAS_PACMAN -eq 0 ]]; then
        return 0
    fi

    log_info "Discovering Pacman packages..."

    # Get installed packages
    pacman -Q | awk '{print $1}' | sort -u
}

# List Snap packages
list_snap_packages() {
    if [[ $HAS_SNAP -eq 0 ]]; then
        return 0
    fi

    log_info "Discovering Snap packages..."

    # Get installed snaps (skip header)
    snap list 2>/dev/null | tail -n +2 | awk '{print $1}' | sort -u
}

# List Flatpak packages
list_flatpak_packages() {
    if [[ $HAS_FLATPAK -eq 0 ]]; then
        return 0
    fi

    log_info "Discovering Flatpak applications..."

    # Get installed flatpaks (apps only, not runtimes)
    flatpak list --app 2>/dev/null | awk -F'\t' '{print $2}' | sort -u
}

# List AUR packages (explicit only, not dependencies)
list_aur_packages() {
    if [[ -z "$HAS_AUR_HELPER" ]]; then
        return 0
    fi

    log_info "Discovering AUR packages..."

    # Get explicitly installed AUR packages
    pacman -Qm | awk '{print $1}' | sort -u
}

# Count packages in a list
count_packages() {
    local pkg_list="$1"
    if [[ -z "$pkg_list" ]]; then
        echo "0"
    else
        echo "$pkg_list" | wc -l | tr -d ' '
    fi
}

# Generate audit report
generate_report() {
    local apt_packages dnf_packages pacman_packages snap_packages flatpak_packages aur_packages
    local apt_count dnf_count pacman_count snap_count flatpak_count aur_count total_count

    # Gather package lists
    apt_packages=$(list_apt_packages)
    dnf_packages=$(list_dnf_packages)
    pacman_packages=$(list_pacman_packages)
    snap_packages=$(list_snap_packages)
    flatpak_packages=$(list_flatpak_packages)
    aur_packages=$(list_aur_packages)

    # Count packages
    apt_count=$(count_packages "$apt_packages")
    dnf_count=$(count_packages "$dnf_packages")
    pacman_count=$(count_packages "$pacman_packages")
    snap_count=$(count_packages "$snap_packages")
    flatpak_count=$(count_packages "$flatpak_packages")
    aur_count=$(count_packages "$aur_packages")

    # Calculate total
    total_count=$((apt_count + dnf_count + pacman_count + snap_count + flatpak_count + aur_count))

    # Create output directory if needed
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Generate report
    {
        echo "# Linux Application Audit"
        echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Distribution: $DISTRO $DISTRO_VERSION"
        echo "# Total Packages: $total_count"
        echo ""

        # APT packages
        if [[ $HAS_APT -eq 1 ]]; then
            echo "# ============================================================"
            echo "# APT Packages (Debian/Ubuntu) - $apt_count packages"
            echo "# ============================================================"
            echo ""
            if [[ -n "$apt_packages" ]]; then
                echo "$apt_packages"
            fi
            echo ""
        fi

        # DNF packages
        if [[ $HAS_DNF -eq 1 ]]; then
            echo "# ============================================================"
            echo "# DNF Packages (Fedora/RHEL) - $dnf_count packages"
            echo "# ============================================================"
            echo ""
            if [[ -n "$dnf_packages" ]]; then
                echo "$dnf_packages"
            fi
            echo ""
        fi

        # Pacman packages
        if [[ $HAS_PACMAN -eq 1 ]]; then
            echo "# ============================================================"
            echo "# Pacman Packages (Arch Linux) - $pacman_count packages"
            echo "# ============================================================"
            echo ""
            if [[ -n "$pacman_packages" ]]; then
                echo "$pacman_packages"
            fi
            echo ""
        fi

        # Snap packages
        if [[ $HAS_SNAP -eq 1 && $snap_count -gt 0 ]]; then
            echo "# ============================================================"
            echo "# Snap Packages - $snap_count packages"
            echo "# ============================================================"
            echo ""
            echo "$snap_packages"
            echo ""
        fi

        # Flatpak packages
        if [[ $HAS_FLATPAK -eq 1 && $flatpak_count -gt 0 ]]; then
            echo "# ============================================================"
            echo "# Flatpak Applications - $flatpak_count packages"
            echo "# ============================================================"
            echo ""
            echo "$flatpak_packages"
            echo ""
        fi

        # AUR packages
        if [[ -n "$HAS_AUR_HELPER" && $aur_count -gt 0 ]]; then
            echo "# ============================================================"
            echo "# AUR Packages (Arch User Repository) - $aur_count packages"
            echo "# ============================================================"
            echo ""
            echo "$aur_packages"
            echo ""
        fi

    } > "$OUTPUT_FILE"

    log_success "Audit complete: $OUTPUT_FILE"
    log_info "Total packages: $total_count (APT: $apt_count, DNF: $dnf_count, Pacman: $pacman_count, Snap: $snap_count, Flatpak: $flatpak_count, AUR: $aur_count)" || true
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    parse_args "$@"

    # Check OS
    local detected_os
    detected_os=$(detect_os)

    if [[ "$detected_os" != "linux" ]]; then
        log_error "This script only works on Linux (detected: $detected_os)"
        exit 2
    fi

    log_info "Starting Linux application audit..."

    # Detect distribution
    detect_distro

    # Detect package managers
    detect_package_managers

    # Ensure at least one package manager is available
    if [[ $HAS_APT -eq 0 && $HAS_DNF -eq 0 && $HAS_PACMAN -eq 0 ]]; then
        log_error "No supported package manager found (APT, DNF, or Pacman required)"
        exit 3
    fi

    # Generate report
    generate_report

    log_success "Linux application audit completed successfully!"
}

# Run main function
main "$@"
