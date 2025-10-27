#!/usr/bin/env bash
# SSH Key Management Script
# Manages device-specific SSH keys stored in 1Password
#
# Usage:
#   ./scripts/setup-ssh-keys.sh                    # Interactive mode
#   ./scripts/setup-ssh-keys.sh --hostname studio  # Specify hostname
#   ./scripts/setup-ssh-keys.sh --generate         # Generate new key
#
# Strategy: One SSH key per device, stored in 1Password
# Naming convention: {hostname}-ssh-key-{year}
# Example: studio4change-ssh-key-2025

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/logger.sh"

# Configuration
SSH_DIR="$HOME/.ssh"
CURRENT_YEAR=$(date +%Y)
DEFAULT_KEY_TYPE="ed25519"

# Get hostname (without domain)
get_hostname() {
    local hostname=$(hostname -s 2>/dev/null || hostname | cut -d. -f1)
    echo "$hostname" | tr '[:upper:]' '[:lower:]'
}

# Get 1Password key name for this device
get_1password_key_name() {
    local hostname="$1"
    echo "${hostname}-ssh-key-${CURRENT_YEAR}"
}

# Check if 1Password CLI is installed and authenticated
check_1password() {
    if ! command -v op &> /dev/null; then
        log_error "1Password CLI not installed. Install with: brew install --cask 1password-cli"
        exit 1
    fi

    # Test authentication
    if ! op account list &> /dev/null; then
        log_error "Not signed in to 1Password. Run: eval \$(op signin)"
        exit 1
    fi

    log_success "1Password CLI ready"
}

# Check if SSH key exists in 1Password
check_key_in_1password() {
    local key_name="$1"

    log_info "Checking for key '$key_name' in 1Password..."

    if op item get "$key_name" &> /dev/null; then
        log_success "Found SSH key in 1Password: $key_name"
        return 0
    else
        log_warning "SSH key not found in 1Password: $key_name"
        return 1
    fi
}

# Retrieve SSH key from 1Password and install locally
install_key_from_1password() {
    local key_name="$1"
    local private_key="$SSH_DIR/id_${DEFAULT_KEY_TYPE}"
    local public_key="$SSH_DIR/id_${DEFAULT_KEY_TYPE}.pub"

    log_step "Installing SSH key from 1Password"

    # Check if keys already exist locally
    if [[ -f "$private_key" ]] && [[ -f "$public_key" ]]; then
        log_warning "SSH keys already exist locally:"
        log_info "  Private: $private_key"
        log_info "  Public:  $public_key"

        read -p "Overwrite existing keys? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log_info "Keeping existing keys"
            return 0
        fi

        # Backup existing keys
        local backup_suffix=$(date +%Y%m%d-%H%M%S)
        log_info "Backing up existing keys..."
        mv "$private_key" "$private_key.backup-$backup_suffix"
        mv "$public_key" "$public_key.backup-$backup_suffix"
    fi

    # Retrieve private key
    log_info "Retrieving private key from 1Password..."
    op item get "$key_name" --fields "private key" > "$private_key"
    chmod 600 "$private_key"

    # Retrieve public key
    log_info "Retrieving public key from 1Password..."
    op item get "$key_name" --fields "public key" > "$public_key"
    chmod 644 "$public_key"

    log_success "SSH keys installed successfully!"
    log_info "  Private: $private_key"
    log_info "  Public:  $public_key"

    # Show key fingerprint
    log_info "Key fingerprint:"
    ssh-keygen -lf "$public_key"
}

# Generate new SSH key and store in 1Password
generate_new_key() {
    local key_name="$1"
    local hostname="$2"
    local email="${3:-$USER@$hostname}"
    local private_key="$SSH_DIR/id_${DEFAULT_KEY_TYPE}"
    local public_key="$SSH_DIR/id_${DEFAULT_KEY_TYPE}.pub"

    log_step "Generating new SSH key"

    # Check if keys already exist locally
    if [[ -f "$private_key" ]] || [[ -f "$public_key" ]]; then
        log_error "SSH keys already exist locally. Delete them first or use --force"
        log_info "  Private: $private_key"
        log_info "  Public:  $public_key"
        exit 1
    fi

    # Generate key
    log_info "Generating $DEFAULT_KEY_TYPE SSH key pair..."
    log_info "Comment: $email"

    ssh-keygen -t "$DEFAULT_KEY_TYPE" -C "$email" -f "$private_key" -N ""

    log_success "SSH key generated successfully!"

    # Show fingerprint
    log_info "Key fingerprint:"
    ssh-keygen -lf "$public_key"

    # Store in 1Password
    log_step "Storing SSH key in 1Password"

    # Read keys
    local private_key_content=$(cat "$private_key")
    local public_key_content=$(cat "$public_key")

    # Create 1Password item
    log_info "Creating 1Password item: $key_name"

    op item create \
        --category="SSH Key" \
        --title="$key_name" \
        --vault="dev" \
        "private key[concealed]=$private_key_content" \
        "public key=$public_key_content" \
        "hostname=$hostname" \
        "email=$email" \
        "generated=$(date +%Y-%m-%d)" \
        || {
            log_error "Failed to create 1Password item"
            log_warning "SSH keys are still available locally, but not backed up"
            exit 1
        }

    log_success "SSH key stored in 1Password: $key_name"
}

# Add SSH key to ssh-agent
add_to_ssh_agent() {
    local private_key="$SSH_DIR/id_${DEFAULT_KEY_TYPE}"

    log_step "Adding SSH key to ssh-agent"

    # Start ssh-agent if not running (macOS should have it running)
    if ! ssh-add -l &> /dev/null; then
        log_info "Starting ssh-agent..."
        eval "$(ssh-agent -s)"
    fi

    # Add key to agent
    ssh-add "$private_key" 2>/dev/null || {
        log_warning "Could not add key to ssh-agent (may require 1Password SSH agent)"
    }

    log_success "SSH key management complete!"
}

# Main setup function
main() {
    local hostname=""
    local generate=false
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --hostname)
                hostname="$2"
                shift 2
                ;;
            --generate)
                generate=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --help)
                cat << EOF
SSH Key Management Script

Usage:
  $0 [OPTIONS]

Options:
  --hostname NAME    Specify hostname (default: auto-detect)
  --generate         Generate new SSH key
  --force            Force overwrite existing keys
  --help             Show this help message

Examples:
  # Install key from 1Password (interactive)
  $0

  # Generate new key for this device
  $0 --generate

  # Install key with specific hostname
  $0 --hostname studio4change

Strategy:
  - One SSH key per device
  - Stored in 1Password vault 'dev'
  - Naming: {hostname}-ssh-key-{year}
  - Type: ed25519 (modern, secure)

EOF
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Auto-detect hostname if not provided
    if [[ -z "$hostname" ]]; then
        hostname=$(get_hostname)
        log_info "Auto-detected hostname: $hostname"
    fi

    local key_name=$(get_1password_key_name "$hostname")

    log_step "SSH Key Setup"
    log_info "Device: $hostname"
    log_info "1Password key name: $key_name"
    echo ""

    # Check 1Password
    check_1password

    # Create SSH directory if needed
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    if $generate; then
        # Generate new key
        generate_new_key "$key_name" "$hostname" "$USER@$hostname"
    else
        # Install from 1Password
        if check_key_in_1password "$key_name"; then
            install_key_from_1password "$key_name"
        else
            log_error "Key not found in 1Password: $key_name"
            echo ""
            log_info "Would you like to generate a new key?"
            read -p "Generate new SSH key? (yes/no): " -r
            if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                generate_new_key "$key_name" "$hostname" "$USER@$hostname"
            else
                log_info "Exiting without changes"
                exit 0
            fi
        fi
    fi

    # Add to ssh-agent
    add_to_ssh_agent

    echo ""
    log_success "✅ SSH key setup complete!"
    echo ""
    log_info "Next steps:"
    echo "  • Test GitHub access: ssh -T git@github.com"
    echo "  • Copy to servers: ssh-copy-id user@server"
    echo "  • View 1Password: op item get '$key_name'"
}

# Run main function
main "$@"
