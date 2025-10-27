#!/usr/bin/env bash
################################################################################
# install-gnome-desktop.sh
#
# Install GNOME Desktop Environment optimized for Parallels VM
#
# Features:
# - Ubuntu Desktop (GNOME) installation
# - GDM3 display manager configuration
# - Dark mode by default
# - NO auto-login (security)
# - Disable animations for better VM performance
# - Parallels Tools integration verification
# - Display resolution auto-detect (HiDPI/Retina support)
#
# Usage: sudo ./scripts/setup/install-gnome-desktop.sh
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run with sudo"
   echo "Usage: sudo $0"
   exit 1
fi

# Get the actual user (not root when using sudo)
ACTUAL_USER="${SUDO_USER:-$USER}"
if [[ "$ACTUAL_USER" == "root" ]]; then
    log_error "Cannot determine actual user. Don't run as root directly, use sudo."
    exit 1
fi

log_section "GNOME Desktop Installation"
log_info "Installing for user: $ACTUAL_USER"
log_info "This will install:"
echo "  - Ubuntu Desktop (GNOME)"
echo "  - GDM3 display manager"
echo "  - GNOME Tweaks and extensions"
echo "  - Dark mode theme"
echo "  - Performance optimizations for VM"
echo ""
log_warning "This will download ~2GB of packages and take 10-15 minutes."
echo ""

# Confirmation prompt
read -p "Do you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installation cancelled"
    exit 0
fi

# Update package lists
log_section "Updating Package Lists"
apt-get update

# Install GNOME Desktop
log_section "Installing GNOME Desktop"
log_info "This will take several minutes..."

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ubuntu-desktop \
    gnome-tweaks \
    gnome-shell-extensions \
    dconf-editor \
    gnome-keyring \
    libsecret-1-0 \
    libsecret-tools \
    || {
        log_error "GNOME installation failed"
        exit 1
    }

log_success "GNOME Desktop installed"

# Configure GDM3 (NO auto-login)
log_section "Configuring Display Manager"
log_info "Setting up GDM3 with NO auto-login (security)"

GDM_CONFIG="/etc/gdm3/custom.conf"
if [[ -f "$GDM_CONFIG" ]]; then
    # Ensure auto-login is disabled
    sed -i 's/^AutomaticLoginEnable=true/AutomaticLoginEnable=false/' "$GDM_CONFIG"
    sed -i 's/^#AutomaticLoginEnable=false/AutomaticLoginEnable=false/' "$GDM_CONFIG"

    # If no AutomaticLoginEnable line exists, add it
    if ! grep -q "AutomaticLoginEnable" "$GDM_CONFIG"; then
        sed -i '/\[daemon\]/a AutomaticLoginEnable=false' "$GDM_CONFIG"
    fi

    log_success "GDM3 configured: NO auto-login (password required)"
else
    log_warning "GDM3 config not found at $GDM_CONFIG"
fi

# Configure GNOME settings for the actual user
log_section "Configuring GNOME Settings"
log_info "Applying dark mode and performance optimizations..."

# Run gsettings commands as the actual user
configure_gnome() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $ACTUAL_USER)/bus" "$@"
}

# Dark mode
configure_gnome gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || log_warning "Could not set color scheme"
configure_gnome gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark' || log_warning "Could not set GTK theme"

# Performance: Disable animations
configure_gnome gsettings set org.gnome.desktop.interface enable-animations false || log_warning "Could not disable animations"

# Performance: Reduce visual effects
configure_gnome gsettings set org.gnome.desktop.background picture-options 'zoom' || true
configure_gnome gsettings set org.gnome.shell.extensions.dash-to-dock animation false || true

log_success "GNOME settings configured"

# Verify Parallels Tools
log_section "Verifying Parallels Tools"
if systemctl is-active --quiet prltoolsd 2>/dev/null; then
    log_success "Parallels Tools service is running"
    log_info "Display resolution will auto-detect (HiDPI/Retina supported)"
elif prlctl --version >/dev/null 2>&1; then
    log_success "Parallels Tools installed"
    log_info "Display resolution will auto-detect (HiDPI/Retina supported)"
else
    log_warning "Parallels Tools not detected"
    log_warning "Install from: Parallels menu → Install Parallels Tools"
    log_warning "Without it, display resolution may not auto-adjust"
fi

# Set default session to GNOME
log_section "Setting Default Session"
if command -v update-alternatives >/dev/null 2>&1; then
    update-alternatives --set x-session-manager /usr/bin/gnome-session || log_warning "Could not set default session"
    log_success "Default session set to GNOME"
fi

# Final instructions
log_section "Installation Complete!"
echo ""
log_success "GNOME Desktop installed successfully"
echo ""
echo "Next steps:"
echo "  1. Reboot the system:"
echo "     ${BLUE}sudo reboot${NC}"
echo ""
echo "  2. After reboot:"
echo "     - GDM3 login screen will appear (dark theme)"
echo "     - Login requires password (NO auto-login)"
echo "     - Desktop will load with dark mode"
echo "     - Display will auto-detect resolution"
echo ""
echo "  3. Continue with GUI apps installation:"
echo "     ${BLUE}./scripts/setup/install-gui-apps.sh${NC}"
echo ""
log_warning "Reboot required for GNOME desktop to start"
echo ""
