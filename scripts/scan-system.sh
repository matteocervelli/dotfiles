#!/bin/bash

# =============================================================================
# SYSTEM SCAN SCRIPT - Mac Studio Complete Configuration Scan
# =============================================================================
# 
# Purpose: Scan current Mac Studio configuration to create comprehensive
#          documentation for dotfiles replication
#
# Usage: ./scripts/scan-system.sh [options]
#
# Options:
#   --complete     Complete scan (default)
#   --software     Software only scan
#   --system       System settings only scan
#   --output FILE  Output file (default: docs/current-system-scan.md)
#   --help         Show this help
#
# Author: Matteo Cervelli
# Date: 2024-12-06
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="${PROJECT_ROOT}/docs/current-system-scan.md"
SCAN_TYPE="complete"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
SYSTEM SCAN SCRIPT - Mac Studio Configuration Scanner

Usage: $0 [options]

Options:
    --complete     Complete system scan (default)
    --software     Software packages only
    --system       System settings only
    --output FILE  Specify output file
    --help         Show this help

Examples:
    $0                                    # Complete scan
    $0 --software                        # Software only
    $0 --output custom-scan.md           # Custom output file
    $0 --system --output system-only.md  # System settings only

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --complete)
                SCAN_TYPE="complete"
                shift
                ;;
            --software)
                SCAN_TYPE="software"
                shift
                ;;
            --system)
                SCAN_TYPE="system"
                shift
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check for required commands
    local required_commands=("brew" "git" "system_profiler" "defaults")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_warning "$cmd not found - some scans will be skipped"
        fi
    done
    
    log_success "Prerequisites check completed"
}

# Initialize output file
init_output_file() {
    log_info "Initializing output file: $OUTPUT_FILE"
    
    # Create output directory if it doesn't exist
    local output_dir=$(dirname "$OUTPUT_FILE")
    mkdir -p "$output_dir"
    
    # Initialize file with header
    cat > "$OUTPUT_FILE" << EOF
# Mac Studio System Scan Report

**Generated**: $TIMESTAMP  
**Scan Type**: $SCAN_TYPE  
**System**: $(sw_vers -productName) $(sw_vers -productVersion)  
**Hardware**: $(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}')

---

EOF
    
    log_success "Output file initialized"
}

# System Hardware Information
scan_hardware() {
    log_info "Scanning hardware information..."
    
    cat >> "$OUTPUT_FILE" << EOF
## 🖥️ HARDWARE INFORMATION

### System Overview
EOF
    
    # Basic system info
    echo '```' >> "$OUTPUT_FILE"
    system_profiler SPHardwareDataType >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    # Display information
    cat >> "$OUTPUT_FILE" << EOF

### Display Configuration
\`\`\`
EOF
    system_profiler SPDisplaysDataType >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    # Storage information
    cat >> "$OUTPUT_FILE" << EOF

### Storage Information
\`\`\`
EOF
    df -h >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    log_success "Hardware scan completed"
}

# Software packages scan
scan_software() {
    log_info "Scanning installed software..."
    
    cat >> "$OUTPUT_FILE" << EOF

## 📦 SOFTWARE PACKAGES

### Homebrew Formulae
EOF
    
    if command -v brew &> /dev/null; then
        echo '```' >> "$OUTPUT_FILE"
        brew list --formula >> "$OUTPUT_FILE" 2>/dev/null || echo "No formulae installed" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        
        cat >> "$OUTPUT_FILE" << EOF

### Homebrew Casks
\`\`\`
EOF
        brew list --cask >> "$OUTPUT_FILE" 2>/dev/null || echo "No casks installed" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
    else
        echo "Homebrew not installed" >> "$OUTPUT_FILE"
    fi
    
    # Mac App Store apps
    cat >> "$OUTPUT_FILE" << EOF

### Mac App Store Applications
\`\`\`
EOF
    if command -v mas &> /dev/null; then
        mas list >> "$OUTPUT_FILE" 2>/dev/null || echo "mas not available" >> "$OUTPUT_FILE"
    else
        echo "mas command not installed" >> "$OUTPUT_FILE"
    fi
    echo '```' >> "$OUTPUT_FILE"
    
    # Node.js packages
    cat >> "$OUTPUT_FILE" << EOF

### Node.js Global Packages
\`\`\`
EOF
    if command -v npm &> /dev/null; then
        npm list -g --depth=0 >> "$OUTPUT_FILE" 2>/dev/null || echo "npm not available" >> "$OUTPUT_FILE"
    else
        echo "npm not installed" >> "$OUTPUT_FILE"
    fi
    echo '```' >> "$OUTPUT_FILE"
    
    # Python packages
    cat >> "$OUTPUT_FILE" << EOF

### Python Packages (pip)
\`\`\`
EOF
    if command -v pip3 &> /dev/null; then
        pip3 list >> "$OUTPUT_FILE" 2>/dev/null || echo "pip3 not available" >> "$OUTPUT_FILE"
    else
        echo "pip3 not installed" >> "$OUTPUT_FILE"
    fi
    echo '```' >> "$OUTPUT_FILE"
    
    # Pyenv versions
    cat >> "$OUTPUT_FILE" << EOF

### Python Versions (pyenv)
\`\`\`
EOF
    if command -v pyenv &> /dev/null; then
        pyenv versions >> "$OUTPUT_FILE" 2>/dev/null || echo "pyenv not available" >> "$OUTPUT_FILE"
    else
        echo "pyenv not installed" >> "$OUTPUT_FILE"
    fi
    echo '```' >> "$OUTPUT_FILE"
    
    # Node versions
    cat >> "$OUTPUT_FILE" << EOF

### Node.js Versions (nvm)
\`\`\`
EOF
    if [[ -f ~/.nvm/nvm.sh ]]; then
        source ~/.nvm/nvm.sh
        nvm list >> "$OUTPUT_FILE" 2>/dev/null || echo "nvm not available" >> "$OUTPUT_FILE"
    else
        echo "nvm not installed" >> "$OUTPUT_FILE"
    fi
    echo '```' >> "$OUTPUT_FILE"
    
    log_success "Software scan completed"
}

# System settings scan
scan_system_settings() {
    log_info "Scanning system settings..."
    
    cat >> "$OUTPUT_FILE" << EOF

## ⚙️ SYSTEM SETTINGS

### Dock Configuration
\`\`\`
EOF
    defaults read com.apple.dock >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot read dock settings" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    cat >> "$OUTPUT_FILE" << EOF

### Finder Configuration
\`\`\`
EOF
    defaults read com.apple.finder >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot read finder settings" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    cat >> "$OUTPUT_FILE" << EOF

### Trackpad Configuration
\`\`\`
EOF
    defaults read com.apple.AppleMultitouchTrackpad >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot read trackpad settings" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    cat >> "$OUTPUT_FILE" << EOF

### Keyboard Configuration
\`\`\`
EOF
    defaults read NSGlobalDomain >> "$OUTPUT_FILE" 2>/dev/null | grep -i keyboard || echo "Cannot read keyboard settings" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    log_success "System settings scan completed"
}

# Network configuration scan
scan_network() {
    log_info "Scanning network configuration..."
    
    cat >> "$OUTPUT_FILE" << EOF

## 🌐 NETWORK CONFIGURATION

### Network Interfaces
\`\`\`
EOF
    ifconfig >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot read network interfaces" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    cat >> "$OUTPUT_FILE" << EOF

### DNS Configuration
\`\`\`
EOF
    scutil --dns >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot read DNS configuration" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    # Tailscale status if available
    if command -v tailscale &> /dev/null; then
        cat >> "$OUTPUT_FILE" << EOF

### Tailscale Status
\`\`\`
EOF
        tailscale status >> "$OUTPUT_FILE" 2>/dev/null || echo "Tailscale not connected" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
    fi
    
    log_success "Network scan completed"
}

# Development environment scan
scan_development() {
    log_info "Scanning development environment..."
    
    cat >> "$OUTPUT_FILE" << EOF

## 💻 DEVELOPMENT ENVIRONMENT

### Git Configuration
\`\`\`
EOF
    git config --list --global >> "$OUTPUT_FILE" 2>/dev/null || echo "No global git configuration" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    # SSH Keys
    cat >> "$OUTPUT_FILE" << EOF

### SSH Keys
\`\`\`
EOF
    ls -la ~/.ssh/ >> "$OUTPUT_FILE" 2>/dev/null || echo "No SSH directory" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    # Development directory structure
    cat >> "$OUTPUT_FILE" << EOF

### Development Directory Structure
\`\`\`
EOF
    if [[ -d ~/dev ]]; then
        find ~/dev -maxdepth 3 -type d >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot scan ~/dev directory" >> "$OUTPUT_FILE"
    else
        echo "~/dev directory not found" >> "$OUTPUT_FILE"
    fi
    echo '```' >> "$OUTPUT_FILE"
    
    # Docker configuration
    if command -v docker &> /dev/null; then
        cat >> "$OUTPUT_FILE" << EOF

### Docker Configuration
\`\`\`
EOF
        docker version >> "$OUTPUT_FILE" 2>/dev/null || echo "Docker not running" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
    fi
    
    log_success "Development environment scan completed"
}

# Shell configuration scan
scan_shell() {
    log_info "Scanning shell configuration..."
    
    cat >> "$OUTPUT_FILE" << EOF

## 🐚 SHELL CONFIGURATION

### Current Shell
\`\`\`
EOF
    echo "Current shell: $SHELL" >> "$OUTPUT_FILE"
    echo "Shell version: $($SHELL --version)" >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot get shell version" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    # ZSH configuration
    if [[ -f ~/.zshrc ]]; then
        cat >> "$OUTPUT_FILE" << EOF

### ZSH Configuration (first 50 lines)
\`\`\`
EOF
        head -50 ~/.zshrc >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot read .zshrc" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
    fi
    
    # Oh My Zsh
    if [[ -d ~/.oh-my-zsh ]]; then
        cat >> "$OUTPUT_FILE" << EOF

### Oh My Zsh Configuration
\`\`\`
EOF
        echo "Oh My Zsh installed at: ~/.oh-my-zsh" >> "$OUTPUT_FILE"
        if [[ -f ~/.oh-my-zsh/custom/plugins.txt ]]; then
            echo "Custom plugins:" >> "$OUTPUT_FILE"
            cat ~/.oh-my-zsh/custom/plugins.txt >> "$OUTPUT_FILE" 2>/dev/null
        fi
        echo '```' >> "$OUTPUT_FILE"
    fi
    
    log_success "Shell configuration scan completed"
}

# Applications scan
scan_applications() {
    log_info "Scanning installed applications..."
    
    cat >> "$OUTPUT_FILE" << EOF

## 📱 INSTALLED APPLICATIONS

### Applications in /Applications
\`\`\`
EOF
    ls -1 /Applications/ >> "$OUTPUT_FILE" 2>/dev/null || echo "Cannot list applications" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    
    cat >> "$OUTPUT_FILE" << EOF

### Applications in ~/Applications
\`\`\`
EOF
    if [[ -d ~/Applications ]]; then
        ls -1 ~/Applications/ >> "$OUTPUT_FILE" 2>/dev/null || echo "No user applications" >> "$OUTPUT_FILE"
    else
        echo "~/Applications directory not found" >> "$OUTPUT_FILE"
    fi
    echo '```' >> "$OUTPUT_FILE"
    
    log_success "Applications scan completed"
}

# Main scan function
run_scan() {
    log_info "Starting system scan (type: $SCAN_TYPE)"
    
    init_output_file
    
    case $SCAN_TYPE in
        "complete")
            scan_hardware
            scan_software
            scan_system_settings
            scan_network
            scan_development
            scan_shell
            scan_applications
            ;;
        "software")
            scan_software
            scan_development
            ;;
        "system")
            scan_hardware
            scan_system_settings
            scan_network
            ;;
        *)
            log_error "Unknown scan type: $SCAN_TYPE"
            exit 1
            ;;
    esac
    
    # Add footer
    cat >> "$OUTPUT_FILE" << EOF

---

**Scan completed**: $(date "+%Y-%m-%d %H:%M:%S")  
**Generated by**: dotfiles/scripts/scan-system.sh  
**Next steps**: Review scan results and update dotfiles configurations accordingly

EOF
    
    log_success "System scan completed successfully!"
    log_info "Report saved to: $OUTPUT_FILE"
    log_info "File size: $(wc -l < "$OUTPUT_FILE") lines"
}

# Backup existing configurations
backup_existing_configs() {
    log_info "Backing up existing configuration files..."
    
    local backup_dir="${PROJECT_ROOT}/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # List of common dotfiles to backup
    local dotfiles=(
        ".zshrc"
        ".zsh_aliases" 
        ".zsh_functions"
        ".gitconfig"
        ".gitignore_global"
        ".ssh/config"
        ".vimrc"
    )
    
    for dotfile in "${dotfiles[@]}"; do
        if [[ -f ~/"$dotfile" ]]; then
            cp ~/"$dotfile" "$backup_dir/" 2>/dev/null && log_info "Backed up: $dotfile"
        fi
    done
    
    # Backup Homebrew Brewfile if exists
    if command -v brew &> /dev/null; then
        brew bundle dump --describe --force --file="$backup_dir/Brewfile" 2>/dev/null && log_info "Backed up: Brewfile"
    fi
    
    # VS Code/Cursor settings
    local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
    if [[ -f "$vscode_settings" ]]; then
        cp "$vscode_settings" "$backup_dir/vscode-settings.json" 2>/dev/null && log_info "Backed up: VS Code settings"
    fi
    
    local cursor_settings="$HOME/Library/Application Support/Cursor/User/settings.json"
    if [[ -f "$cursor_settings" ]]; then
        cp "$cursor_settings" "$backup_dir/cursor-settings.json" 2>/dev/null && log_info "Backed up: Cursor settings"
    fi
    
    log_success "Backup completed in: $backup_dir"
}

# Main execution
main() {
    echo "============================================================================="
    echo "  DOTFILES SYSTEM SCANNER - Mac Studio Configuration"
    echo "============================================================================="
    echo
    
    parse_args "$@"
    check_prerequisites
    
    # Ask for confirmation before running complete scan
    if [[ "$SCAN_TYPE" == "complete" ]]; then
        echo "⚠️  This will perform a complete system scan and may take several minutes."
        echo "   The scan will collect system settings, installed software, and configurations."
        echo
        read -p "Continue with complete scan? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Scan cancelled by user"
            exit 0
        fi
    fi
    
    run_scan
    backup_existing_configs
    
    echo
    echo "============================================================================="
    echo "  SCAN COMPLETED SUCCESSFULLY"
    echo "============================================================================="
    echo
    echo "📄 Scan report: $OUTPUT_FILE"
    echo "💾 Backups: ${PROJECT_ROOT}/backups/"
    echo
    echo "Next steps:"
    echo "1. Review the scan report"
    echo "2. Update dotfiles configurations based on findings"
    echo "3. Test dotfiles installation on clean system"
    echo
}

# Execute main function with all arguments
main "$@"