#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Installing Ubuntu Dependencies"

# Check if running on Ubuntu
if [ ! -f /etc/os-release ] || ! grep -q "ubuntu" /etc/os-release; then
    log_error "This script must be run on Ubuntu"
    exit 1
fi

# Update package lists
log_info "Updating package lists..."
sudo apt update

# Install GNU Stow
if ! command -v stow &> /dev/null; then
    log_info "Installing GNU Stow..."
    sudo apt install -y stow
else
    log_success "GNU Stow already installed"
fi

# Install 1Password CLI
if ! command -v op &> /dev/null; then
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

    sudo apt update && sudo apt install -y 1password-cli
else
    log_success "1Password CLI already installed"
fi

# Install Rclone
if ! command -v rclone &> /dev/null; then
    log_info "Installing Rclone..."
    sudo apt install -y rclone
else
    log_success "Rclone already installed"
fi

# Install yq (YAML processor)
# Note: We need to install the correct architecture version (ARM64 or AMD64)
if ! command -v yq &> /dev/null; then
    log_info "Installing yq..."

    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            YQ_BINARY="yq_linux_amd64"
            ;;
        aarch64|arm64)
            YQ_BINARY="yq_linux_arm64"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    # Remove any existing snap yq (has permission issues with shared folders)
    if snap list 2>/dev/null | grep -q "^yq "; then
        log_info "Removing snap yq (conflicts with direct installation)..."
        sudo snap remove yq 2>/dev/null || true
    fi

    # Download and install correct architecture binary
    YQ_VERSION="v4.40.5"
    log_info "Installing yq $YQ_VERSION for $ARCH..."
    cd /tmp
    wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz" -O yq.tar.gz
    tar xzf yq.tar.gz
    sudo mv "${YQ_BINARY}" /usr/local/bin/yq
    sudo chmod +x /usr/local/bin/yq
    rm -f yq.tar.gz yq.1 install_yq.sh

    log_success "yq installed successfully"
else
    # Verify existing yq is correct architecture
    YQ_PATH=$(which yq)
    YQ_FILE_INFO=$(file "$YQ_PATH")
    CURRENT_ARCH=$(uname -m)

    # Check if architecture matches
    case "$CURRENT_ARCH" in
        aarch64|arm64)
            if echo "$YQ_FILE_INFO" | grep -q "ARM aarch64"; then
                log_success "yq already installed (ARM64)"
            else
                log_warning "yq installed but wrong architecture (found: $(echo $YQ_FILE_INFO | cut -d: -f2))"
                log_info "Reinstalling correct ARM64 version..."
                sudo rm -f "$YQ_PATH"

                # Remove snap version if exists
                sudo snap remove yq 2>/dev/null || true

                YQ_VERSION="v4.40.5"
                cd /tmp
                wget "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_arm64.tar.gz" -O yq.tar.gz
                tar xzf yq.tar.gz
                sudo mv yq_linux_arm64 /usr/local/bin/yq
                sudo chmod +x /usr/local/bin/yq
                rm -f yq.tar.gz yq.1 install_yq.sh
                log_success "yq ARM64 installed successfully"
            fi
            ;;
        x86_64)
            if echo "$YQ_FILE_INFO" | grep -q "x86-64"; then
                log_success "yq already installed (AMD64)"
            else
                log_warning "yq installed but wrong architecture"
                log_info "Reinstalling correct AMD64 version..."
                sudo rm -f "$YQ_PATH"
                sudo snap remove yq 2>/dev/null || true
                sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_amd64
                sudo chmod +x /usr/local/bin/yq
                log_success "yq AMD64 installed successfully"
            fi
            ;;
    esac
fi

# Install essential build tools
log_info "Installing build essentials..."
sudo apt install -y build-essential curl git

log_success "Ubuntu dependencies installed successfully!"

# Setup SSH keys
log_step "SSH Key Setup"
log_info "Setting up device-specific SSH key from 1Password..."
echo ""

if eval $(op signin) 2>/dev/null; then
    "$SCRIPT_DIR/../setup-ssh-keys.sh" || {
        log_warning "SSH key setup skipped or failed"
        log_info "Run manually later: ./scripts/setup-ssh-keys.sh"
    }
else
    log_warning "Not signed in to 1Password - skipping SSH key setup"
    log_info "Sign in and run: ./scripts/setup-ssh-keys.sh"
fi

echo ""
log_info "Next steps:"
echo "  1. If SSH keys not set up: ./scripts/setup-ssh-keys.sh"
echo "  2. Configure Rclone for R2: ./scripts/sync/setup-rclone.sh"
echo "  3. Run full installation: make install"
