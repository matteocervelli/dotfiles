#!/usr/bin/env bash
#
# Font Installation Script
# Installs fonts from backup to ~/Library/Fonts/ with selective installation support
#
# Usage:
#   ./install-fonts.sh [OPTIONS]
#
# Options:
#   --essential-only     Install only essential fonts (MesloLGS NF + Lato + Raleway)
#   --with-coding        Install essential + coding fonts (Hack, Space Mono, etc.)
#   --with-powerline     Install essential + all Powerline fonts
#   --all                Install all fonts (default)
#   --dry-run            Show what would be installed without actually installing
#   --force              Overwrite existing fonts
#   --verbose            Show detailed output
#   --skip-cache         Skip font cache rebuild
#   -h, --help           Show this help message

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FONTS_CONFIG="$DOTFILES_DIR/fonts/fonts.yml"
FONTS_BACKUP="$DOTFILES_DIR/fonts/backup"
TARGET_DIR="$HOME/Library/Fonts"

# Source utilities
source "$SCRIPT_DIR/../utils/logger.sh"
source "$SCRIPT_DIR/../utils/detect-os.sh"

# Options
INSTALL_MODE="all"
DRY_RUN=false
FORCE=false
VERBOSE=false
SKIP_CACHE=false

# Statistics
INSTALLED_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

usage() {
    cat << EOF
Font Installation Script

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    --essential-only     Install only essential fonts (terminal + professional)
                        MesloLGS NF (4 variants) + Lato (4 variants) + Raleway (2 variants)

    --with-coding        Install essential + coding fonts
                        Adds: Hack, Space Mono, IBM 3270, CPMono

    --with-powerline     Install essential + all Powerline fonts
                        Adds: 120+ Powerline variants of various typefaces

    --all                Install all fonts (default)
                        Includes: essential + coding + powerline + optional fonts

    --dry-run            Preview what would be installed without making changes

    --force              Overwrite existing fonts (default: skip if already installed)

    --verbose            Show detailed output including font names

    --skip-cache         Skip font cache rebuild (faster but fonts may not appear)

    -h, --help           Show this help message

DESCRIPTION:
    This script installs fonts from the dotfiles backup directory to your
    system fonts folder (~/Library/Fonts on macOS). Fonts are organized by
    category in fonts/fonts.yml for selective installation.

    Font Categories:
    - Essential: Terminal (MesloLGS NF) + Professional (Lato, Raleway)
    - Coding: Hack, Space Mono, IBM 3270, CPMono
    - Powerline: 120+ terminal fonts with special glyphs
    - Optional: Complete Lato family + UI fonts + design fonts

EXAMPLES:
    # Install only essential fonts (fast, recommended for bootstrap)
    $(basename "$0") --essential-only

    # Preview what would be installed
    $(basename "$0") --all --dry-run

    # Install essential + coding fonts
    $(basename "$0") --with-coding

    # Force reinstall all fonts
    $(basename "$0") --all --force

EXIT CODES:
    0 - Success
    1 - Error occurred
    2 - Invalid arguments

For more information, see: $DOTFILES_DIR/fonts/README.md
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --essential-only)
            INSTALL_MODE="essential"
            shift
            ;;
        --with-coding)
            INSTALL_MODE="coding"
            shift
            ;;
        --with-powerline)
            INSTALL_MODE="powerline"
            shift
            ;;
        --all)
            INSTALL_MODE="all"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --skip-cache)
            SKIP_CACHE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 2
            ;;
    esac
done

# Check prerequisites
check_prerequisites() {
    log_header "Checking Prerequisites"

    # Check if running on macOS
    if ! is_macos; then
        log_error "This script currently only supports macOS"
        log_info "Linux support coming soon"
        exit 1
    fi

    # Check if yq is available
    if ! command -v yq &> /dev/null; then
        log_error "yq is required but not installed"
        log_info "Install with: brew install yq"
        exit 1
    fi

    # Check if fonts.yml exists
    if [ ! -f "$FONTS_CONFIG" ]; then
        log_error "Font configuration not found: $FONTS_CONFIG"
        exit 1
    fi

    # Check if backup directory exists
    if [ ! -d "$FONTS_BACKUP" ]; then
        log_error "Font backup directory not found: $FONTS_BACKUP"
        exit 1
    fi

    # Check if target directory exists
    if [ ! -d "$TARGET_DIR" ]; then
        log_warning "Target directory does not exist, creating: $TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    fi

    log_success "Prerequisites check passed"
}

# Get list of fonts to install based on mode
get_fonts_to_install() {
    local mode="$1"
    local fonts=()

    case "$mode" in
        essential)
            # Essential: terminal + professional
            fonts+=($(yq eval '.essential.terminal[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.essential.professional[]' "$FONTS_CONFIG"))
            ;;
        coding)
            # Essential + coding
            fonts+=($(yq eval '.essential.terminal[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.essential.professional[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.coding.hack[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.coding.space-mono[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.coding.ibm-3270[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.coding.cpmono[]' "$FONTS_CONFIG"))
            ;;
        powerline)
            # Essential + all powerline
            fonts+=($(yq eval '.essential.terminal[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.essential.professional[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.meslo-variants[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.source-code-pro[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.dejavu[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.roboto-mono[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.other-powerline[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.terminus[]' "$FONTS_CONFIG"))
            ;;
        all)
            # All fonts
            fonts+=($(yq eval '.essential.terminal[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.essential.professional[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.coding.hack[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.coding.space-mono[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.coding.ibm-3270[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.coding.cpmono[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.meslo-variants[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.source-code-pro[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.dejavu[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.roboto-mono[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.other-powerline[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.powerline.terminus[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.optional-development.lato-complete[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.optional-development.ui-fonts[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.optional-design.serif[]' "$FONTS_CONFIG"))
            fonts+=($(yq eval '.optional-design.display[]' "$FONTS_CONFIG"))
            ;;
    esac

    printf '%s\n' "${fonts[@]}"
}

# Install a single font
install_font() {
    local font_name="$1"
    local source_path="$FONTS_BACKUP/$font_name"
    local target_path="$TARGET_DIR/$font_name"

    # Check if source exists
    if [ ! -f "$source_path" ]; then
        log_error "Font not found in backup: $font_name"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi

    # Check if already installed and not forcing
    if [ -f "$target_path" ] && [ "$FORCE" = false ]; then
        if [ "$VERBOSE" = true ]; then
            log_info "Skipping (already installed): $font_name"
        fi
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        return 0
    fi

    # Dry run
    if [ "$DRY_RUN" = true ]; then
        if [ "$VERBOSE" = true ]; then
            log_info "Would install: $font_name"
        fi
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        return 0
    fi

    # Install font
    if cp "$source_path" "$target_path" 2>/dev/null; then
        if [ "$VERBOSE" = true ]; then
            log_success "Installed: $font_name"
        fi
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        return 0
    else
        log_error "Failed to install: $font_name"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Clear font cache on macOS
clear_font_cache() {
    if [ "$SKIP_CACHE" = true ]; then
        log_info "Skipping font cache rebuild (--skip-cache)"
        return 0
    fi

    log_header "Rebuilding Font Cache"

    if [ "$DRY_RUN" = true ]; then
        log_info "Would rebuild font cache"
        return 0
    fi

    # Clear cache using atsutil (macOS)
    if command -v atsutil &> /dev/null; then
        if atsutil databases -remove 2>/dev/null; then
            log_success "Font cache cleared successfully"
        else
            log_warning "Failed to clear font cache (this is normal on some macOS versions)"
        fi
    else
        log_warning "atsutil not available, skipping cache clear"
    fi

    # Kill font services to force reload
    killall "Font Book" 2>/dev/null || true
}

# Verify font installation
verify_installation() {
    log_header "Verifying Installation"

    local essential_fonts=(
        "MesloLGS NF Regular.ttf"
        "MesloLGS NF Bold.ttf"
        "Lato-Regular.ttf"
        "Raleway-VF.ttf"
    )

    local all_present=true

    for font in "${essential_fonts[@]}"; do
        if [ -f "$TARGET_DIR/$font" ]; then
            if [ "$VERBOSE" = true ]; then
                log_success "✓ $font"
            fi
        else
            log_error "✗ Essential font missing: $font"
            all_present=false
        fi
    done

    if [ "$all_present" = true ]; then
        log_success "All essential fonts verified"
        return 0
    else
        log_error "Some essential fonts are missing"
        return 1
    fi
}

# Print summary
print_summary() {
    local mode_description=""
    case "$INSTALL_MODE" in
        essential) mode_description="Essential Fonts (Terminal + Professional)" ;;
        coding) mode_description="Essential + Coding Fonts" ;;
        powerline) mode_description="Essential + Powerline Fonts" ;;
        all) mode_description="All Fonts" ;;
    esac

    log_header "Installation Summary"
    echo ""
    echo "  Mode:        $mode_description"
    echo "  Installed:   $INSTALLED_COUNT fonts"
    echo "  Skipped:     $SKIPPED_COUNT fonts (already installed)"
    echo "  Failed:      $FAILED_COUNT fonts"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN - No fonts were actually installed"
    fi

    if [ "$FAILED_COUNT" -gt 0 ]; then
        log_error "Installation completed with errors"
        return 1
    elif [ "$INSTALLED_COUNT" -eq 0 ] && [ "$SKIPPED_COUNT" -gt 0 ]; then
        log_success "All fonts already installed"
        return 0
    else
        log_success "Font installation completed successfully"
        return 0
    fi
}

# Main installation process
main() {
    log_header "Font Installation"
    echo ""
    echo "  Dotfiles:    $DOTFILES_DIR"
    echo "  Source:      $FONTS_BACKUP"
    echo "  Target:      $TARGET_DIR"
    echo "  Mode:        $INSTALL_MODE"
    echo "  Dry Run:     $DRY_RUN"
    echo "  Force:       $FORCE"
    echo ""

    # Check prerequisites
    check_prerequisites

    # Get fonts to install
    log_header "Preparing Font List"
    local fonts_to_install
    fonts_to_install=$(get_fonts_to_install "$INSTALL_MODE")
    local total_fonts
    total_fonts=$(echo "$fonts_to_install" | wc -l | tr -d ' ')
    log_info "Found $total_fonts fonts to install"

    # Install fonts
    log_header "Installing Fonts"
    while IFS= read -r font; do
        [ -z "$font" ] && continue
        install_font "$font"
    done <<< "$fonts_to_install"

    # Clear font cache
    if [ "$INSTALLED_COUNT" -gt 0 ] || [ "$FORCE" = true ]; then
        clear_font_cache
    fi

    # Verify installation (only for essential fonts)
    if [ "$INSTALL_MODE" != "all" ] || [ "$DRY_RUN" = false ]; then
        verify_installation || true
    fi

    # Print summary
    print_summary
}

# Run main function
main
