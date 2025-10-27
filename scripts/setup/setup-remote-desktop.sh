#!/usr/bin/env bash
################################################################################
# setup-remote-desktop.sh
#
# Setup remote desktop access for Ubuntu VM
#
# Methods:
# - VNC (TigerVNC) - Primary, best for macOS clients
# - xrdp - Optional, for Windows/RDP clients
# - Parallels Remote Desktop - Built-in (documentation only)
#
# Usage: ./scripts/setup/setup-remote-desktop.sh
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

# Check for sudo
check_sudo() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        log_warning "Some operations require sudo privileges"
        log_info "You may be prompted for your password"
    fi
}

log_section "Remote Desktop Setup"
log_info "This script will configure remote desktop access methods:"
echo ""
echo "  ${BLUE}1. VNC (TigerVNC)${NC} - Primary (RECOMMENDED)"
echo "     - Best performance for macOS clients"
echo "     - Works with macOS Screen Sharing"
echo "     - Port: 5901"
echo ""
echo "  ${BLUE}2. xrdp${NC} - Optional"
echo "     - For Windows/RDP clients"
echo "     - Port: 3389"
echo ""
echo "  ${BLUE}3. Parallels Remote Desktop${NC} - Built-in"
echo "     - Already available via Parallels Tools"
echo "     - Best performance (native integration)"
echo ""

# Ask which methods to install
echo "Which remote desktop method(s) do you want to install?"
echo ""
echo "  ${GREEN}1${NC} - VNC only (RECOMMENDED for macOS)"
echo "  ${GREEN}2${NC} - VNC + xrdp (for both macOS and Windows clients)"
echo "  ${GREEN}3${NC} - xrdp only"
echo "  ${GREEN}4${NC} - Skip remote desktop setup"
echo ""
read -p "Enter your choice [1-4]: " choice

case "$choice" in
    1)
        INSTALL_VNC=true
        INSTALL_XRDP=false
        ;;
    2)
        INSTALL_VNC=true
        INSTALL_XRDP=true
        ;;
    3)
        INSTALL_VNC=false
        INSTALL_XRDP=true
        ;;
    4)
        log_info "Skipping remote desktop setup"
        exit 0
        ;;
    *)
        log_error "Invalid choice"
        exit 1
        ;;
esac

check_sudo

# Update package lists
log_section "Updating Package Lists"
sudo apt-get update

# Install VNC
if [[ "$INSTALL_VNC" == "true" ]]; then
    log_section "Installing TigerVNC Server"

    sudo apt-get install -y tigervnc-standalone-server tigervnc-common

    log_success "TigerVNC installed"

    log_info "Setting up VNC server..."

    # Create VNC password
    echo ""
    log_warning "You need to set a VNC password for remote connections"
    log_info "This password will be used to connect from macOS Screen Sharing"
    echo ""

    vncpasswd

    # Create VNC startup script
    VNC_XSTARTUP="$HOME/.vnc/xstartup"
    mkdir -p "$HOME/.vnc"

    cat > "$VNC_XSTARTUP" << 'EOF'
#!/bin/sh
# VNC xstartup script for GNOME

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Start GNOME session
exec gnome-session &
EOF

    chmod +x "$VNC_XSTARTUP"

    log_success "VNC startup script created"

    # Create systemd service for VNC
    log_info "Creating systemd service for VNC autostart (optional)..."

    VNC_SERVICE="/etc/systemd/system/vncserver@.service"
    sudo tee "$VNC_SERVICE" > /dev/null << EOF
[Unit]
Description=Start TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=%i
PAMName=login
PIDFile=/home/%i/.vnc/%H:%i.pid
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill :%i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

    log_success "VNC systemd service created"

    # Ask if user wants VNC to start automatically
    echo ""
    read -p "Do you want VNC to start automatically at boot? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl daemon-reload
        sudo systemctl enable "vncserver@1.service"
        sudo systemctl start "vncserver@1.service"
        log_success "VNC server will start automatically at boot (port 5901)"
    else
        log_info "VNC autostart disabled"
        log_info "Start VNC manually: ${BLUE}vncserver -geometry 1920x1080 -depth 24${NC}"
    fi

    # Configure firewall for VNC
    if command -v ufw >/dev/null 2>&1; then
        log_info "Configuring firewall for VNC (port 5901)..."
        sudo ufw allow 5901/tcp comment 'VNC Server'
        log_success "Firewall configured for VNC"
    fi
fi

# Install xrdp
if [[ "$INSTALL_XRDP" == "true" ]]; then
    log_section "Installing xrdp"

    sudo apt-get install -y xrdp

    log_success "xrdp installed"

    # Configure xrdp to use local session
    log_info "Configuring xrdp..."

    sudo sed -i 's/^new_cursors=true/new_cursors=false/' /etc/xrdp/xrdp.ini || true

    # Configure xrdp to use GNOME
    echo "gnome-session" | sudo tee /etc/xrdp/startwm.sh > /dev/null
    sudo chmod +x /etc/xrdp/startwm.sh

    # Start and enable xrdp
    sudo systemctl enable xrdp
    sudo systemctl start xrdp

    log_success "xrdp service started and enabled"

    # Configure firewall for xrdp
    if command -v ufw >/dev/null 2>&1; then
        log_info "Configuring firewall for xrdp (port 3389)..."
        sudo ufw allow 3389/tcp comment 'xrdp Server'
        log_success "Firewall configured for xrdp"
    fi
fi

# Get VM IP addresses
log_section "Connection Information"
echo ""
log_info "Your VM IP addresses:"

# Local network IP
LOCAL_IP=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1)
echo "  Local: ${GREEN}$LOCAL_IP${NC}"

# Tailscale IP (if available)
if command -v tailscale >/dev/null 2>&1; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
    if [[ -n "$TAILSCALE_IP" ]]; then
        echo "  Tailscale: ${GREEN}$TAILSCALE_IP${NC}"
    fi
fi

# Hostname
HOSTNAME=$(hostname)
echo "  Hostname: ${GREEN}$HOSTNAME${NC}"

echo ""

# VNC connection instructions
if [[ "$INSTALL_VNC" == "true" ]]; then
    log_section "VNC Connection Instructions"
    echo ""
    echo "  ${BLUE}From macOS (Screen Sharing):${NC}"
    echo "    1. Open Finder"
    echo "    2. Press: ${YELLOW}Cmd+K${NC}"
    echo "    3. Enter: ${GREEN}vnc://$HOSTNAME:5901${NC}"
    echo "       or:    ${GREEN}vnc://$LOCAL_IP:5901${NC}"
    echo "    4. Click Connect"
    echo "    5. Enter VNC password when prompted"
    echo ""
    echo "  ${BLUE}From command line:${NC}"
    echo "    ${GREEN}open vnc://$HOSTNAME:5901${NC}"
    echo ""
    echo "  ${BLUE}From other VNC clients:${NC}"
    echo "    Host: ${GREEN}$LOCAL_IP${NC}"
    echo "    Port: ${GREEN}5901${NC}"
    echo ""
fi

# xrdp connection instructions
if [[ "$INSTALL_XRDP" == "true" ]]; then
    log_section "RDP Connection Instructions"
    echo ""
    echo "  ${BLUE}From Windows (Remote Desktop):${NC}"
    echo "    1. Open Remote Desktop Connection"
    echo "    2. Computer: ${GREEN}$LOCAL_IP${NC}"
    echo "    3. Connect"
    echo "    4. Login with your Ubuntu username and password"
    echo ""
    echo "  ${BLUE}From macOS (Microsoft Remote Desktop):${NC}"
    echo "    1. Download Microsoft Remote Desktop from App Store"
    echo "    2. Add PC: ${GREEN}$LOCAL_IP${NC}"
    echo "    3. Connect with Ubuntu credentials"
    echo ""
fi

# Parallels Remote Desktop
log_section "Parallels Remote Desktop"
echo ""
log_info "Parallels Remote Desktop is already available via Parallels Tools"
echo ""
echo "  ${BLUE}Access Methods:${NC}"
echo "    - ${GREEN}Coherence Mode${NC}: Linux apps appear as macOS windows"
echo "    - ${GREEN}Full Screen${NC}: Entire Linux desktop in full screen"
echo "    - ${GREEN}Window Mode${NC}: Linux desktop in a window"
echo ""
echo "  ${BLUE}To enable Coherence Mode:${NC}"
echo "    1. In Parallels, go to: View → Enter Coherence"
echo "    2. Or press: ${YELLOW}Cmd+Shift+C${NC}"
echo ""

# Security notes
log_section "Security Notes"
echo ""
log_warning "Remote desktop connections are unencrypted by default"
log_info "For secure remote access:"
echo "  1. Use Tailscale VPN (already configured)"
echo "  2. Connect via Tailscale IP addresses"
echo "  3. Do NOT expose ports 5901 or 3389 to public internet"
echo ""

# Final summary
log_section "Setup Complete!"
echo ""
log_success "Remote desktop access configured successfully"
echo ""

if [[ "$INSTALL_VNC" == "true" ]]; then
    echo "  ${GREEN}✓${NC} VNC server installed (port 5901)"
fi

if [[ "$INSTALL_XRDP" == "true" ]]; then
    echo "  ${GREEN}✓${NC} xrdp server installed (port 3389)"
fi

echo "  ${GREEN}✓${NC} Parallels Remote Desktop available"
echo ""
log_info "Use VNC from macOS Screen Sharing for best performance"
echo ""
