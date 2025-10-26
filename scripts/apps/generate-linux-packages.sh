#!/usr/bin/env bash
# Generate Linux Package Lists
# Generates distro-specific package lists from package-mappings.yml
#
# Usage:
#   ./scripts/apps/generate-linux-packages.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   -v, --verbose      Show detailed output
#   -d, --distro       Target distribution (ubuntu|fedora|arch|all)
#   --dry-run          Show what would be generated without writing files
#
# Generates:
#   - system/ubuntu/packages.txt
#   - system/fedora/packages.txt
#   - system/arch/packages.txt
#
# Example:
#   ./scripts/apps/generate-linux-packages.sh
#   ./scripts/apps/generate-linux-packages.sh --distro ubuntu
#   ./scripts/apps/generate-linux-packages.sh --dry-run

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Configuration
VERBOSE=0
DRY_RUN=0
TARGET_DISTRO="all"
MAPPING_FILE="$PROJECT_ROOT/applications/linux/package-mappings.yml"
UBUNTU_OUTPUT="$PROJECT_ROOT/system/ubuntu/packages.txt"
FEDORA_OUTPUT="$PROJECT_ROOT/system/fedora/packages.txt"
ARCH_OUTPUT="$PROJECT_ROOT/system/arch/packages.txt"

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Generate Linux Package Lists

Generates distribution-specific package lists from package-mappings.yml
for Ubuntu (APT), Fedora (DNF), and Arch Linux (Pacman).

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help         Show this help message
    -v, --verbose      Show detailed output
    -d, --distro       Target distribution (ubuntu|fedora|arch|all) [default: all]
    --dry-run          Preview output without writing files

EXAMPLES:
    $0                              # Generate all package lists
    $0 --distro ubuntu              # Generate Ubuntu packages only
    $0 --dry-run                    # Preview without writing

OUTPUTS:
    - system/ubuntu/packages.txt    # APT package names
    - system/fedora/packages.txt    # DNF package names
    - system/arch/packages.txt      # Pacman package names

DEPENDENCIES:
    - yq (YAML processor) - Install: brew install yq (macOS) or snap install yq (Linux)

EXIT CODES:
    0    Success
    1    General error
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
            -d|--distro)
                if [[ -n "${2:-}" ]]; then
                    TARGET_DISTRO="$2"
                    shift 2
                else
                    log_error "Error: --distro requires an argument"
                    exit 1
                fi
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate distro argument
    case "$TARGET_DISTRO" in
        ubuntu|fedora|arch|all)
            ;;
        *)
            log_error "Invalid distribution: $TARGET_DISTRO (must be: ubuntu, fedora, arch, or all)"
            exit 1
            ;;
    esac
}

# Check dependencies
check_dependencies() {
    if ! command -v yq >/dev/null 2>&1; then
        log_error "yq not found. Install with: brew install yq (macOS) or snap install yq (Linux)"
        exit 3
    fi

    if [[ ! -f "$MAPPING_FILE" ]]; then
        log_error "Package mapping file not found: $MAPPING_FILE"
        exit 1
    fi

    [[ $VERBOSE -eq 1 ]] && log_info "Dependencies check passed" || true
}

# Generate Ubuntu package list
generate_ubuntu_packages() {
    log_info "Generating Ubuntu (APT) package list..."

    local packages header

    # Header
    header=$(cat << 'EOF'
#
# Ubuntu/Debian Package List
#
# Generated from: applications/linux/package-mappings.yml
# Package Manager: APT (Advanced Package Tool)
# Target Distribution: Ubuntu 24.04 LTS (Noble Numbat)
#
# Usage:
#   xargs -a system/ubuntu/packages.txt sudo apt install
#   cat system/ubuntu/packages.txt | xargs sudo apt install
#
# Notes:
#   - Some packages require repository setup before installation
#   - See applications/linux/package-mappings.yml for repo_setup instructions
#   - Packages marked with (snap) should be installed via Snap
#   - Packages marked with (flatpak) should be installed via Flatpak
#
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
#

# ============================================================================
# Native APT Packages
# ============================================================================

EOF
)

    # Extract APT packages (where apt field is not null)
    packages=$(yq eval '.packages | to_entries | .[] | select(.value.apt != null) | .value.apt' "$MAPPING_FILE" | sort -u)

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "=== Ubuntu Packages (Dry Run) ==="
        echo "$header"
        echo "$packages"
        echo ""
        log_info "Would write to: $UBUNTU_OUTPUT"
    else
        {
            echo "$header"
            echo "$packages"
        } > "$UBUNTU_OUTPUT"
        local count
        count=$(echo "$packages" | wc -l | tr -d ' ')
        log_success "Generated Ubuntu package list: $count packages → $UBUNTU_OUTPUT"
    fi
}

# Generate Fedora package list
generate_fedora_packages() {
    log_info "Generating Fedora (DNF) package list..."

    local packages header

    # Header
    header=$(cat << 'EOF'
#
# Fedora/RHEL Package List
#
# Generated from: applications/linux/package-mappings.yml
# Package Manager: DNF (Dandified YUM)
# Target Distribution: Fedora Workstation 40+
#
# Usage:
#   cat system/fedora/packages.txt | xargs sudo dnf install
#   xargs -a system/fedora/packages.txt sudo dnf install
#
# Notes:
#   - Some packages require repository setup before installation
#   - See applications/linux/package-mappings.yml for repo_setup instructions
#   - RPM Fusion repositories recommended for multimedia packages
#   - Enable COPR repositories for additional software
#
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
#

# ============================================================================
# Native DNF Packages
# ============================================================================

EOF
)

    # Extract DNF packages (where dnf field is not null)
    packages=$(yq eval '.packages | to_entries | .[] | select(.value.dnf != null) | .value.dnf' "$MAPPING_FILE" | sort -u)

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "=== Fedora Packages (Dry Run) ==="
        echo "$header"
        echo "$packages"
        echo ""
        log_info "Would write to: $FEDORA_OUTPUT"
    else
        {
            echo "$header"
            echo "$packages"
        } > "$FEDORA_OUTPUT"
        local count
        count=$(echo "$packages" | wc -l | tr -d ' ')
        log_success "Generated Fedora package list: $count packages → $FEDORA_OUTPUT"
    fi
}

# Generate Arch package list
generate_arch_packages() {
    log_info "Generating Arch Linux (Pacman) package list..."

    local packages header

    # Header
    header=$(cat << 'EOF'
#
# Arch Linux Package List
#
# Generated from: applications/linux/package-mappings.yml
# Package Manager: Pacman
# Target Distribution: Arch Linux (rolling release)
#
# Usage:
#   cat system/arch/packages.txt | xargs sudo pacman -S
#   xargs -a system/arch/packages.txt sudo pacman -S --needed
#
# Notes:
#   - AUR packages require an AUR helper (yay or paru)
#   - See applications/linux/package-mappings.yml for AUR packages
#   - Use --needed flag to skip already installed packages
#   - Pacman supports parallel downloads with ParallelDownloads option
#
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
#

# ============================================================================
# Native Pacman Packages
# ============================================================================

EOF
)

    # Extract Pacman packages (where pacman field is not null)
    packages=$(yq eval '.packages | to_entries | .[] | select(.value.pacman != null) | .value.pacman' "$MAPPING_FILE" | sort -u)

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "=== Arch Linux Packages (Dry Run) ==="
        echo "$header"
        echo "$packages"
        echo ""
        log_info "Would write to: $ARCH_OUTPUT"
    else
        {
            echo "$header"
            echo "$packages"
        } > "$ARCH_OUTPUT"
        local count
        count=$(echo "$packages" | wc -l | tr -d ' ')
        log_success "Generated Arch package list: $count packages → $ARCH_OUTPUT"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    parse_args "$@"

    # Check dependencies
    check_dependencies

    log_info "Generating Linux package lists from: $MAPPING_FILE"
    [[ $DRY_RUN -eq 1 ]] && log_warning "DRY RUN MODE - No files will be written" || true

    # Generate based on target distro
    case "$TARGET_DISTRO" in
        ubuntu)
            generate_ubuntu_packages
            ;;
        fedora)
            generate_fedora_packages
            ;;
        arch)
            generate_arch_packages
            ;;
        all)
            generate_ubuntu_packages
            generate_fedora_packages
            generate_arch_packages
            ;;
    esac

    if [[ $DRY_RUN -eq 0 ]]; then
        log_success "Package list generation completed successfully!"
        log_info "Next steps:"
        log_info "  1. Review generated files in system/{ubuntu,fedora,arch}/packages.txt"
        log_info "  2. Install packages: cat system/ubuntu/packages.txt | xargs sudo apt install"
        log_info "  3. Or use bootstrap scripts: ./scripts/bootstrap/install-dependencies-ubuntu.sh"
    fi
}

# Run main function
main "$@"
