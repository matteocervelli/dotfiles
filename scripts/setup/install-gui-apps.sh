#!/usr/bin/env bash
################################################################################
# install-gui-apps.sh
#
# Install essential GUI applications for Ubuntu VM development environment
#
# Applications:
# - Browsers: Chromium (default), LibreWolf
# - Development: VS Code, pgAdmin 4
# - Productivity: LibreOffice
# - Security: 1Password CLI, ProtonVPN
# - AI/ML: Ollama (manual start only)
#
# Usage: ./scripts/setup/install-gui-apps.sh
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

# Check for sudo when needed
check_sudo() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        log_warning "Some operations require sudo privileges"
        log_info "You may be prompted for your password"
    fi
}

log_section "GUI Applications Installation"
log_info "This script will install:"
echo ""
echo "  ${BLUE}Browsers:${NC}"
echo "    - Chromium (default browser)"
echo "    - LibreWolf (privacy-focused)"
echo ""
echo "  ${BLUE}Development:${NC}"
echo "    - VS Code (via official Microsoft repository)"
echo "    - pgAdmin 4 (PostgreSQL GUI)"
echo ""
echo "  ${BLUE}Productivity:${NC}"
echo "    - LibreOffice (full suite)"
echo ""
echo "  ${BLUE}Security:${NC}"
echo "    - 1Password CLI (if not already installed)"
echo "    - ProtonVPN"
echo ""
echo "  ${BLUE}AI/ML:${NC}"
echo "    - Ollama (manual start only)"
echo ""
log_warning "Total download: ~1GB, Installation time: ~10 minutes"
echo ""

read -p "Do you want to continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installation cancelled"
    exit 0
fi

check_sudo

# Update package lists
log_section "Updating Package Lists"
sudo apt-get update

# Install Browsers
log_section "Installing Browsers"

log_info "Installing Chromium..."
sudo apt-get install -y chromium-browser
log_success "Chromium installed"

log_info "Installing LibreWolf..."
# LibreWolf requires adding their repository
if ! command -v librewolf >/dev/null 2>&1; then
    sudo apt-get install -y software-properties-common apt-transport-https wget

    # Add LibreWolf repository
    wget -qO- https://deb.librewolf.net/keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/librewolf.gpg

    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/librewolf.gpg] https://deb.librewolf.net $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/librewolf.list

    sudo apt-get update
    sudo apt-get install -y librewolf

    log_success "LibreWolf installed"
else
    log_success "LibreWolf already installed"
fi

# Set Chromium as default browser
log_info "Setting Chromium as default browser..."
sudo update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/chromium-browser 100
sudo update-alternatives --set x-www-browser /usr/bin/chromium-browser
log_success "Chromium set as default browser"

# Install Development Tools
log_section "Installing Development Tools"

# VS Code will be installed by setup-vscode-linux.sh
log_info "VS Code will be installed by setup-vscode-linux.sh"
log_info "Run: ./scripts/setup/setup-vscode-linux.sh"

log_info "Installing pgAdmin 4..."
# pgAdmin 4 requires adding their repository
if ! command -v pgadmin4 >/dev/null 2>&1; then
    # Add PostgreSQL repository for pgAdmin
    sudo sh -c 'echo "deb https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'

    wget --quiet -O - https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/pgadmin4.gpg

    sudo sed -i 's|deb https|deb [signed-by=/usr/share/keyrings/pgadmin4.gpg] https|' /etc/apt/sources.list.d/pgadmin4.list

    sudo apt-get update
    sudo apt-get install -y pgadmin4-desktop

    log_success "pgAdmin 4 installed"
else
    log_success "pgAdmin 4 already installed"
fi

# Install Productivity Software
log_section "Installing Productivity Software"

log_info "Installing LibreOffice..."
sudo apt-get install -y libreoffice
log_success "LibreOffice installed"

# Install Security Tools
log_section "Installing Security Tools"

# 1Password CLI
log_info "Checking 1Password CLI..."
if command -v op >/dev/null 2>&1; then
    log_success "1Password CLI already installed"
else
    log_info "Installing 1Password CLI..."
    # Add 1Password repository
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list

    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    sudo apt-get update
    sudo apt-get install -y 1password-cli

    log_success "1Password CLI installed"
fi

# ProtonVPN
log_info "Installing ProtonVPN..."
if ! command -v protonvpn >/dev/null 2>&1; then
    # Download and install ProtonVPN repository
    wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb
    sudo dpkg -i protonvpn-stable-release_1.0.3-3_all.deb
    rm protonvpn-stable-release_1.0.3-3_all.deb

    sudo apt-get update
    sudo apt-get install -y proton-vpn-gnome-desktop

    log_success "ProtonVPN installed"
else
    log_success "ProtonVPN already installed"
fi

# Install AI/ML Tools
log_section "Installing AI/ML Tools"

log_info "Installing Ollama..."
if ! command -v ollama >/dev/null 2>&1; then
    curl -fsSL https://ollama.com/install.sh | sh
    log_success "Ollama installed"
else
    log_success "Ollama already installed"
fi

log_info "Configuring Ollama (NO autostart)..."
# Ensure Ollama service is disabled (manual start only)
if systemctl is-enabled ollama.service 2>/dev/null; then
    sudo systemctl disable ollama.service
    log_success "Ollama autostart disabled (manual start only)"
fi

# Verify installations
log_section "Verifying Installations"

verify_installation() {
    local app_name="$1"
    local command_name="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        log_success "$app_name: $(command -v $command_name)"
    else
        log_warning "$app_name: Not found in PATH"
    fi
}

verify_installation "Chromium" "chromium-browser"
verify_installation "LibreWolf" "librewolf"
verify_installation "pgAdmin 4" "pgadmin4"
verify_installation "LibreOffice" "libreoffice"
verify_installation "1Password CLI" "op"
verify_installation "ProtonVPN" "protonvpn"
verify_installation "Ollama" "ollama"

# Final summary
log_section "Installation Complete!"
echo ""
log_success "All GUI applications installed successfully"
echo ""
echo "Installed applications:"
echo "  ${GREEN}✓${NC} Chromium (default browser)"
echo "  ${GREEN}✓${NC} LibreWolf"
echo "  ${GREEN}✓${NC} pgAdmin 4"
echo "  ${GREEN}✓${NC} LibreOffice"
echo "  ${GREEN}✓${NC} 1Password CLI"
echo "  ${GREEN}✓${NC} ProtonVPN"
echo "  ${GREEN}✓${NC} Ollama (manual start: ${BLUE}ollama serve${NC})"
echo ""
echo "Next steps:"
echo "  1. Install VS Code with extensions:"
echo "     ${BLUE}./scripts/setup/setup-vscode-linux.sh${NC}"
echo ""
echo "  2. Setup remote desktop access:"
echo "     ${BLUE}./scripts/setup/setup-remote-desktop.sh${NC}"
echo ""
echo "  3. Sync Ollama models from macOS (optional):"
echo "     ${BLUE}./scripts/setup/sync-ollama-models.sh${NC}"
echo ""
