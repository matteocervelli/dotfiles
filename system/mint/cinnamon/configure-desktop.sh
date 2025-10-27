#!/usr/bin/env bash
# Cinnamon Desktop Configuration Script
# Applies developer-friendly settings to Linux Mint Cinnamon desktop
#
# Usage:
#   ./system/mint/cinnamon/configure-desktop.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   --dry-run          Show what would be configured without applying
#   --reset            Reset to Mint defaults
#
# Example:
#   ./system/mint/cinnamon/configure-desktop.sh
#   ./system/mint/cinnamon/configure-desktop.sh --dry-run

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source utilities if available
if [[ -f "$PROJECT_ROOT/scripts/utils/logger.sh" ]]; then
    source "$PROJECT_ROOT/scripts/utils/logger.sh"
else
    # Fallback logging functions
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warning() { echo "[WARNING] $*"; }
    log_error() { echo "[ERROR] $*"; }
fi

# Configuration
DRY_RUN=0
RESET=0

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Cinnamon Desktop Configuration Script

Applies developer-friendly settings to Linux Mint Cinnamon desktop environment.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    --dry-run           Preview settings without applying
    --reset             Reset to Mint default settings

EXAMPLES:
    $0                  # Apply developer-friendly settings
    $0 --dry-run        # Preview settings
    $0 --reset          # Reset to defaults

SETTINGS APPLIED:
    - Dark theme (Mint-Y-Dark-Aqua)
    - Developer keyboard shortcuts
    - Terminal quick access (Ctrl+Alt+T)
    - Show hidden files in file manager
    - List view as default in Nemo
    - Optimized panel layout

EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --reset)
                RESET=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if running in desktop environment
check_display() {
    if [[ -z "$DISPLAY" ]]; then
        log_error "No display detected - cannot configure desktop"
        log_info "Run this script after logging into the desktop environment"
        exit 1
    fi

    if ! command -v gsettings &> /dev/null; then
        log_error "gsettings command not found"
        log_info "Install: sudo apt install libglib2.0-bin"
        exit 1
    fi
}

# Apply setting with error handling
apply_setting() {
    local schema="$1"
    local key="$2"
    local value="$3"
    local description="$4"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would set: $schema $key = $value"
        return 0
    fi

    log_info "$description"
    if gsettings set "$schema" "$key" "$value" 2>/dev/null; then
        return 0
    else
        log_warning "Failed to set $schema.$key"
        return 1
    fi
}

# Apply theme and appearance settings
configure_theme() {
    log_info "Configuring theme and appearance..."

    if [[ $RESET -eq 1 ]]; then
        apply_setting "org.cinnamon.desktop.interface" "gtk-theme" "'Mint-Y'" "Resetting GTK theme to default"
        apply_setting "org.cinnamon.desktop.interface" "icon-theme" "'Mint-Y'" "Resetting icon theme to default"
        apply_setting "org.cinnamon.theme" "name" "'Mint-Y'" "Resetting Cinnamon theme to default"
    else
        # Developer-friendly dark theme
        apply_setting "org.cinnamon.desktop.interface" "gtk-theme" "'Mint-Y-Dark-Aqua'" "Setting GTK theme to dark"
        apply_setting "org.cinnamon.desktop.interface" "icon-theme" "'Mint-Y-Aqua'" "Setting icon theme"
        apply_setting "org.cinnamon.theme" "name" "'Mint-Y-Dark-Aqua'" "Setting Cinnamon theme to dark"

        # Font settings for better readability
        apply_setting "org.cinnamon.desktop.interface" "font-name" "'Ubuntu 10'" "Setting system font"
        apply_setting "org.cinnamon.desktop.interface" "monospace-font-name" "'JetBrains Mono 11'" "Setting monospace font"
    fi
}

# Configure desktop behavior
configure_desktop() {
    log_info "Configuring desktop behavior..."

    if [[ $RESET -eq 1 ]]; then
        apply_setting "org.cinnamon.desktop.wm.preferences" "button-layout" "':minimize,maximize,close'" "Resetting window buttons"
        apply_setting "org.cinnamon.desktop.wm.preferences" "focus-mode" "'click'" "Resetting focus mode"
    else
        # Window management
        apply_setting "org.cinnamon.desktop.wm.preferences" "button-layout" "':minimize,maximize,close'" "Setting window buttons layout"
        apply_setting "org.cinnamon.desktop.wm.preferences" "focus-mode" "'click'" "Setting click-to-focus"
        apply_setting "org.cinnamon.desktop.wm.preferences" "num-workspaces" "4" "Setting 4 workspaces"

        # Desktop icons (minimal for development)
        apply_setting "org.nemo.desktop" "computer-icon-visible" "false" "Hiding Computer icon"
        apply_setting "org.nemo.desktop" "home-icon-visible" "true" "Showing Home icon"
        apply_setting "org.nemo.desktop" "trash-icon-visible" "true" "Showing Trash icon"
    fi
}

# Configure panel
configure_panel() {
    log_info "Configuring panel..."

    if [[ $RESET -eq 1 ]]; then
        log_info "Resetting panel to defaults (manual reset required)"
        log_info "Go to: System Settings > Panel > Restore all settings to default"
    else
        # Panel position and size
        apply_setting "org.cinnamon" "panels-enabled" "['1:0:bottom']" "Setting panel at bottom"
        apply_setting "org.cinnamon" "panel-zone-icon-sizes" '[{"panelId":1,"left":24,"center":24,"right":16}]' "Setting panel icon sizes"

        log_info "Panel applets configuration:"
        log_info "  - Add system monitor applet for CPU/RAM/Network monitoring"
        log_info "  - Add workspace switcher for multi-desktop workflow"
        log_info "  - Customize in: System Settings > Applets"
    fi
}

# Configure keyboard shortcuts
configure_shortcuts() {
    log_info "Configuring keyboard shortcuts..."

    if [[ $RESET -eq 1 ]]; then
        apply_setting "org.cinnamon.desktop.keybindings.media-keys" "terminal" "['<Super>t']" "Resetting terminal shortcut"
    else
        # Developer-friendly shortcuts
        apply_setting "org.cinnamon.desktop.keybindings.media-keys" "terminal" "['<Primary><Alt>t']" "Setting terminal shortcut (Ctrl+Alt+T)"
        apply_setting "org.cinnamon.desktop.keybindings.media-keys" "www" "['<Super>b']" "Setting browser shortcut (Super+B)"

        # Window management shortcuts
        apply_setting "org.cinnamon.desktop.keybindings.wm" "switch-to-workspace-left" "['<Control><Alt>Left']" "Setting workspace left (Ctrl+Alt+Left)"
        apply_setting "org.cinnamon.desktop.keybindings.wm" "switch-to-workspace-right" "['<Control><Alt>Right']" "Setting workspace right (Ctrl+Alt+Right)"
        apply_setting "org.cinnamon.desktop.keybindings.wm" "maximize" "['<Super>Up']" "Setting maximize window (Super+Up)"
        apply_setting "org.cinnamon.desktop.keybindings.wm" "unmaximize" "['<Super>Down']" "Setting unmaximize window (Super+Down)"
    fi
}

# Configure file manager (Nemo)
configure_nemo() {
    log_info "Configuring Nemo file manager..."

    if [[ $RESET -eq 1 ]]; then
        apply_setting "org.nemo.preferences" "show-hidden-files" "false" "Hiding hidden files"
        apply_setting "org.nemo.preferences" "default-folder-viewer" "'icon-view'" "Resetting to icon view"
    else
        # Developer-friendly settings
        apply_setting "org.nemo.preferences" "show-hidden-files" "true" "Showing hidden files"
        apply_setting "org.nemo.preferences" "default-folder-viewer" "'list-view'" "Setting list view as default"
        apply_setting "org.nemo.preferences" "show-full-path-titles" "true" "Showing full path in title"
        apply_setting "org.nemo.preferences" "show-location-entry" "true" "Showing location entry"

        # Developer column preferences
        apply_setting "org.nemo.list-view" "default-visible-columns" "['name', 'size', 'type', 'date_modified', 'permissions']" "Setting visible columns"
    fi
}

# Configure terminal
configure_terminal() {
    log_info "Configuring Gnome Terminal..."

    if [[ $RESET -eq 1 ]]; then
        log_info "Terminal reset (manual configuration required)"
        log_info "Go to: Terminal > Preferences > Profiles"
    else
        log_info "Terminal configuration tips:"
        log_info "  1. Set default profile with dark color scheme"
        log_info "  2. Increase scrollback to 10000 lines"
        log_info "  3. Set custom font: JetBrains Mono 12"
        log_info "  4. Enable transparency (optional)"
        log_info ""
        log_info "Configure manually in: Terminal > Preferences > Profiles"
    fi
}

# Configure text editor
configure_text_editor() {
    log_info "Configuring xed text editor..."

    if [[ $RESET -eq 1 ]]; then
        apply_setting "org.x.editor.preferences.editor" "scheme" "'classic'" "Resetting color scheme"
    else
        # Developer-friendly text editor settings
        apply_setting "org.x.editor.preferences.editor" "scheme" "'oblivion'" "Setting dark color scheme"
        apply_setting "org.x.editor.preferences.editor" "display-line-numbers" "true" "Showing line numbers"
        apply_setting "org.x.editor.preferences.editor" "bracket-matching" "true" "Enabling bracket matching"
        apply_setting "org.x.editor.preferences.editor" "tabs-size" "4" "Setting tab size to 4"
        apply_setting "org.x.editor.preferences.editor" "insert-spaces" "true" "Using spaces instead of tabs"
        apply_setting "org.x.editor.preferences.editor" "auto-indent" "true" "Enabling auto-indent"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    parse_args "$@"
    check_display

    [[ $DRY_RUN -eq 1 ]] && log_warning "DRY RUN MODE - No changes will be made" || true
    [[ $RESET -eq 1 ]] && log_warning "RESET MODE - Restoring Mint defaults" || true

    log_info "Cinnamon Desktop Configuration"
    echo ""

    # Apply configurations
    configure_theme
    configure_desktop
    configure_panel
    configure_shortcuts
    configure_nemo
    configure_terminal
    configure_text_editor

    echo ""
    log_success "Cinnamon desktop configuration complete!"
    echo ""
    log_info "Additional customizations:"
    echo "  1. System Settings > Themes - Browse and install additional themes"
    echo "  2. System Settings > Applets - Add CPU/RAM monitor, weather, etc."
    echo "  3. System Settings > Desklets - Add desktop widgets"
    echo "  4. System Settings > Extensions - Enable additional features"
    echo ""
    log_info "Recommended applets for developers:"
    echo "  - System Monitor (CPU, RAM, Network)"
    echo "  - Workspace Switcher (OSD)"
    echo "  - Sound 150% (volume control)"
    echo "  - Calendar"
    echo ""
}

# Run main function
main "$@"
