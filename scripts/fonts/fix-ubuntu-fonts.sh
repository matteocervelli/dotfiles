#!/usr/bin/env bash
#
# Ubuntu Meslo Font Fix Script
# Fixes Powerlevel10k Meslo font rendering issues on Ubuntu
#
# This script:
# 1. Installs MesloLGS NF fonts to ~/.local/share/fonts
# 2. Rebuilds font cache with fc-cache
# 3. Configures GNOME Terminal to use the correct font
# 4. Verifies font installation and rendering
#
# Usage:
#   ./fix-ubuntu-fonts.sh [OPTIONS]
#
# Options:
#   --configure-terminal    Also configure GNOME Terminal font settings
#   --dry-run               Show what would be done without making changes
#   --verbose               Show detailed output
#   -h, --help              Show this help message

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
FONTS_BACKUP="$DOTFILES_DIR/fonts/backup"
TARGET_DIR="$HOME/.local/share/fonts"

# Source utilities
source "$SCRIPT_DIR/../utils/logger.sh"

# Options
CONFIGURE_TERMINAL=false
DRY_RUN=false
VERBOSE=false

# MesloLGS NF fonts (required for Powerlevel10k)
MESLO_FONTS=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
)

usage() {
    cat << 'EOF'
Ubuntu Meslo Font Fix Script

Fixes Powerlevel10k font rendering issues on Ubuntu by:
- Installing MesloLGS NF fonts to ~/.local/share/fonts
- Rebuilding font cache with fc-cache
- Optionally configuring GNOME Terminal

USAGE:
    ./fix-ubuntu-fonts.sh [OPTIONS]

OPTIONS:
    --configure-terminal    Configure GNOME Terminal to use MesloLGS NF
    --dry-run               Preview changes without making them
    --verbose               Show detailed output
    -h, --help              Show this help message

EXAMPLES:
    # Install fonts only
    ./fix-ubuntu-fonts.sh

    # Install fonts and configure terminal
    ./fix-ubuntu-fonts.sh --configure-terminal

    # Preview what would be done
    ./fix-ubuntu-fonts.sh --dry-run --verbose

TROUBLESHOOTING:
    If fonts still don't work after running this script:

    1. Close and reopen your terminal
    2. Log out and log back in
    3. Manually set font in terminal:
       - Open terminal preferences
       - Uncheck "Use system font"
       - Select "MesloLGS NF Regular" from font list
    4. Run p10k configure to reconfigure Powerlevel10k

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --configure-terminal)
            CONFIGURE_TERMINAL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
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

# Check if running on Ubuntu
check_ubuntu() {
    log_step "Checking System"

    if [ ! -f /etc/os-release ]; then
        log_error "Not running on a Linux system with /etc/os-release"
        exit 1
    fi

    source /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        log_warning "Not running on Ubuntu (detected: $ID)"
        log_info "This script is designed for Ubuntu but may work on other Debian-based systems"
    else
        log_success "Running on Ubuntu $VERSION_ID"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking Prerequisites"

    # Check if fc-cache is available
    if ! command -v fc-cache &> /dev/null; then
        log_error "fc-cache not found - fontconfig not installed"
        log_info "Install with: sudo apt install fontconfig"
        exit 1
    fi

    # Check if font backup exists
    if [ ! -d "$FONTS_BACKUP" ]; then
        log_error "Font backup directory not found: $FONTS_BACKUP"
        log_info "Make sure you're running this from the dotfiles repository"
        exit 1
    fi

    # Check if MesloLGS NF fonts exist in backup
    local missing_fonts=0
    for font in "${MESLO_FONTS[@]}"; do
        if [ ! -f "$FONTS_BACKUP/$font" ]; then
            log_error "Font not found in backup: $font"
            missing_fonts=$((missing_fonts + 1))
        fi
    done

    if [ $missing_fonts -gt 0 ]; then
        log_error "$missing_fonts fonts missing from backup directory"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Create target directory
create_target_dir() {
    log_step "Creating Font Directory"

    if [ -d "$TARGET_DIR" ]; then
        log_info "Directory already exists: $TARGET_DIR"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "Would create: $TARGET_DIR"
        return 0
    fi

    if mkdir -p "$TARGET_DIR"; then
        log_success "Created: $TARGET_DIR"
    else
        log_error "Failed to create directory: $TARGET_DIR"
        exit 1
    fi
}

# Install MesloLGS NF fonts
install_fonts() {
    log_step "Installing MesloLGS NF Fonts"

    local installed=0
    local skipped=0

    for font in "${MESLO_FONTS[@]}"; do
        local source="$FONTS_BACKUP/$font"
        local target="$TARGET_DIR/$font"

        # Check if already installed
        if [ -f "$target" ]; then
            if [ "$VERBOSE" = true ]; then
                log_info "Already installed: $font"
            fi
            skipped=$((skipped + 1))
            continue
        fi

        # Dry run
        if [ "$DRY_RUN" = true ]; then
            log_info "Would install: $font"
            installed=$((installed + 1))
            continue
        fi

        # Install font
        if cp "$source" "$target"; then
            if [ "$VERBOSE" = true ]; then
                log_success "Installed: $font"
            fi
            installed=$((installed + 1))
        else
            log_error "Failed to install: $font"
        fi
    done

    log_info "Installed: $installed fonts, Skipped: $skipped fonts"
}

# Rebuild font cache
rebuild_font_cache() {
    log_step "Rebuilding Font Cache"

    if [ "$DRY_RUN" = true ]; then
        log_info "Would run: fc-cache -f -v $TARGET_DIR"
        return 0
    fi

    if [ "$VERBOSE" = true ]; then
        fc-cache -f -v "$TARGET_DIR"
    else
        fc-cache -f "$TARGET_DIR" &> /dev/null
    fi

    log_success "Font cache rebuilt successfully"
}

# Verify font installation
verify_fonts() {
    log_step "Verifying Font Installation"

    local all_found=true
    local fonts_in_cache=false

    # Check if files exist
    for font in "${MESLO_FONTS[@]}"; do
        if [ -f "$TARGET_DIR/$font" ]; then
            if [ "$VERBOSE" = true ]; then
                log_success "✓ File exists: $font"
            fi
        else
            log_error "✗ Missing file: $font"
            all_found=false
        fi
    done

    # Check if fonts are in cache
    if fc-list | grep -q "MesloLGS NF"; then
        fonts_in_cache=true
        if [ "$VERBOSE" = true ]; then
            log_success "✓ MesloLGS NF fonts found in font cache"
        fi
    else
        log_warning "MesloLGS NF fonts NOT yet in font cache"
        log_info "This is normal - fonts will be available after you logout/login"
        log_info "Or run in a new terminal session"
    fi

    if [ "$all_found" = true ]; then
        log_success "Font files installed successfully"
        if [ "$fonts_in_cache" = false ]; then
            log_warning "Fonts will be available after restarting your session"
        fi
        return 0
    else
        log_error "Font installation failed - some files missing"
        return 1
    fi
}

# Configure GNOME Terminal
configure_gnome_terminal() {
    if [ "$CONFIGURE_TERMINAL" = false ]; then
        return 0
    fi

    log_step "Configuring GNOME Terminal"

    # Check if gsettings is available (for GNOME)
    if ! command -v gsettings &> /dev/null; then
        log_warning "gsettings not available - not running GNOME"
        log_info "You'll need to manually set the font in your Terminal Preferences"
        return 0
    fi

    # Check if dconf is available
    if ! command -v dconf &> /dev/null; then
        log_warning "dconf not available - cannot configure GNOME Terminal"
        log_info "Install with: sudo dnf install dconf  # Fedora"
        log_info "          or: sudo apt install dconf-cli  # Ubuntu"
        return 0
    fi

    # Get default profile
    local profile
    profile=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")

    # Fallback to legacy path if new path doesn't work
    if [ -z "$profile" ]; then
        profile=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d "'")
    fi

    if [ -z "$profile" ]; then
        log_warning "No default GNOME Terminal profile found"
        log_info "Manually set font: Preferences → Profiles → Text → Custom font → MesloLGS NF Regular"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "Would configure GNOME Terminal profile: $profile"
        log_info "  - Disable system font"
        log_info "  - Set font to: MesloLGS NF Regular 11"
        return 0
    fi

    # Try new GNOME Terminal schema first (GNOME 42+)
    local profile_path="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"

    # Configure font
    if gsettings set "$profile_path" use-system-font false 2>/dev/null; then
        gsettings set "$profile_path" font 'MesloLGS NF Regular 11'
        log_success "GNOME Terminal configured (gsettings method)"
    else
        # Fallback to dconf for older systems
        local dconf_path="/org/gnome/terminal/legacy/profiles:/:$profile/"
        dconf write "${dconf_path}use-system-font" false
        dconf write "${dconf_path}font" "'MesloLGS NF Regular 11'"
        log_success "GNOME Terminal configured (dconf method)"
    fi

    log_info "Close and reopen terminal for changes to take effect"
}

# Print next steps
print_next_steps() {
    log_step "Next Steps"

    echo ""
    echo "  1. Close and reopen your terminal (or logout/login)"
    echo "  2. Verify font rendering with: echo '\ue0b0 \u00b1 \ue0a0 \u27a6 \u2718 \u26a1 \u2699'"
    echo "  3. If icons don't render, run: p10k configure"
    echo ""

    if [ "$CONFIGURE_TERMINAL" = false ]; then
        echo "  To auto-configure GNOME Terminal, run:"
        echo "    $0 --configure-terminal"
        echo ""
        echo "  Or manually set font in Terminal Preferences:"
        echo "    - Uncheck 'Use system font'"
        echo "    - Select 'MesloLGS NF Regular' (size 11)"
        echo ""
    fi

    log_info "For more help, see: https://github.com/romkatv/powerlevel10k#fonts"
}

# Print summary
print_summary() {
    log_step "Summary"

    echo ""
    echo "  Target Directory:  $TARGET_DIR"
    echo "  Fonts Installed:   ${#MESLO_FONTS[@]} MesloLGS NF variants"
    echo "  Font Cache:        Rebuilt with fc-cache"

    if [ "$CONFIGURE_TERMINAL" = true ]; then
        echo "  Terminal Config:   GNOME Terminal configured"
    else
        echo "  Terminal Config:   Not configured (use --configure-terminal)"
    fi

    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN - No changes were made"
    else
        log_success "Font installation completed successfully!"
    fi
}

# Main function
main() {
    log_step "Ubuntu Meslo Font Fix"
    echo ""
    echo "  This script will install MesloLGS NF fonts for Powerlevel10k"
    echo ""

    check_ubuntu
    check_prerequisites
    create_target_dir
    install_fonts
    rebuild_font_cache
    verify_fonts
    configure_gnome_terminal
    print_summary
    print_next_steps
}

# Run main function
main
