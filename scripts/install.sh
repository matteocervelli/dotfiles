#!/bin/bash

# =============================================================================
# Dotfiles Installation Script - Matteo Cervelli's dotfiles
# =============================================================================
# Complete automation script for setting up macOS development environment
# using GNU Stow for dotfiles management
#
# Usage:
#   ./scripts/install.sh [options]
#
# Options:
#   --help, -h          Show this help message
#   --dry-run, -d       Perform a dry run (show what would be done)
#   --minimal, -m       Install only essential packages
#   --full, -f          Install everything including optional packages
#   --skip-homebrew     Skip Homebrew installation and updates
#   --skip-macos        Skip macOS system configuration
#   --skip-stow         Skip GNU Stow symlink creation
#   --packages <list>   Install only specified packages (comma-separated)
#
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration and Constants
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGES_DIR="$DOTFILES_DIR/packages"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration flags
DRY_RUN=false
MINIMAL_INSTALL=false
FULL_INSTALL=true
SKIP_HOMEBREW=false
SKIP_MACOS=false
SKIP_STOW=false
CUSTOM_PACKAGES=""

# Essential packages (installed in minimal mode)
ESSENTIAL_PACKAGES=(
    "zsh"
    "git" 
    "ssh"
    "homebrew"
)

# Optional packages (installed in full mode)
OPTIONAL_PACKAGES=(
    "cursor"
    "claude" 
    "python"
    "node"
)

# All available packages
ALL_PACKAGES=("${ESSENTIAL_PACKAGES[@]}" "${OPTIONAL_PACKAGES[@]}")

# =============================================================================
# Utility Functions
# =============================================================================

print_banner() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo "  Dotfiles Installation Script - Matteo Cervelli"
    echo "  Setting up macOS development environment with GNU Stow"
    echo "============================================================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_requirements() {
    print_step "Checking system requirements"
    
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Check macOS version
    local macos_version
    macos_version=$(sw_vers -productVersion)
    print_info "macOS version: $macos_version"
    
    # Check if running with sufficient permissions
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this script as root"
        exit 1
    fi
    
    print_success "System requirements check passed"
}

backup_existing_configs() {
    print_step "Backing up existing configurations"
    
    if [[ $DRY_RUN == true ]]; then
        print_info "DRY RUN: Would create backup directory at $BACKUP_DIR"
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    # List of common config files to backup
    local configs_to_backup=(
        ".zshrc"
        ".gitconfig"
        ".ssh/config"
        ".npmrc"
        ".pyenvrc"
        ".pythonrc"
    )
    
    for config in "${configs_to_backup[@]}"; do
        if [[ -f "$HOME/$config" ]] || [[ -L "$HOME/$config" ]]; then
            local backup_path="$BACKUP_DIR/$config"
            mkdir -p "$(dirname "$backup_path")"
            cp -L "$HOME/$config" "$backup_path" 2>/dev/null || true
            print_info "Backed up $config"
        fi
    done
    
    print_success "Configuration backup completed: $BACKUP_DIR"
}

install_homebrew() {
    if [[ $SKIP_HOMEBREW == true ]]; then
        print_info "Skipping Homebrew installation"
        return 0
    fi
    
    print_step "Installing/updating Homebrew"
    
    if ! command -v brew >/dev/null 2>&1; then
        print_info "Installing Homebrew..."
        if [[ $DRY_RUN == true ]]; then
            print_info "DRY RUN: Would install Homebrew"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for Apple Silicon Macs
            if [[ -f "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi
    else
        print_info "Homebrew already installed, updating..."
        if [[ $DRY_RUN == true ]]; then
            print_info "DRY RUN: Would update Homebrew"
        else
            brew update
        fi
    fi
    
    print_success "Homebrew setup completed"
}

install_stow() {
    print_step "Installing GNU Stow"
    
    if ! command -v stow >/dev/null 2>&1; then
        print_info "Installing GNU Stow via Homebrew..."
        if [[ $DRY_RUN == true ]]; then
            print_info "DRY RUN: Would install GNU Stow"
        else
            brew install stow
        fi
    else
        print_info "GNU Stow already installed"
    fi
    
    print_success "GNU Stow setup completed"
}

install_packages_with_homebrew() {
    if [[ $SKIP_HOMEBREW == true ]]; then
        print_info "Skipping Homebrew package installation"
        return 0
    fi
    
    print_step "Installing packages via Homebrew"
    
    local brewfile="$PACKAGES_DIR/homebrew/Brewfile"
    
    if [[ ! -f "$brewfile" ]]; then
        print_warning "Brewfile not found at $brewfile"
        return 1
    fi
    
    if [[ $DRY_RUN == true ]]; then
        print_info "DRY RUN: Would install packages from $brewfile"
        brew bundle --file="$brewfile" --dry-run
    else
        print_info "Installing packages from Brewfile..."
        brew bundle --file="$brewfile"
        print_info "Cleaning up Homebrew..."
        brew cleanup
    fi
    
    print_success "Homebrew package installation completed"
}

stow_package() {
    local package="$1"
    local package_dir="$PACKAGES_DIR/$package"
    
    if [[ ! -d "$package_dir" ]]; then
        print_warning "Package directory not found: $package_dir"
        return 1
    fi
    
    print_info "Stowing package: $package"
    
    if [[ $DRY_RUN == true ]]; then
        print_info "DRY RUN: Would stow $package"
        stow -n -t "$HOME" -d "$PACKAGES_DIR" "$package"
    else
        stow -t "$HOME" -d "$PACKAGES_DIR" "$package"
    fi
    
    return 0
}

install_dotfiles() {
    if [[ $SKIP_STOW == true ]]; then
        print_info "Skipping GNU Stow symlink creation"
        return 0
    fi
    
    print_step "Installing dotfiles with GNU Stow"
    
    local packages_to_install=()
    
    # Determine which packages to install
    if [[ -n "$CUSTOM_PACKAGES" ]]; then
        IFS=',' read -ra packages_to_install <<< "$CUSTOM_PACKAGES"
    elif [[ $MINIMAL_INSTALL == true ]]; then
        packages_to_install=("${ESSENTIAL_PACKAGES[@]}")
    elif [[ $FULL_INSTALL == true ]]; then
        packages_to_install=("${ALL_PACKAGES[@]}")
    fi
    
    print_info "Installing packages: ${packages_to_install[*]}"
    
    # Install each package
    for package in "${packages_to_install[@]}"; do
        if stow_package "$package"; then
            print_success "Successfully stowed: $package"
        else
            print_error "Failed to stow: $package"
        fi
    done
    
    print_success "Dotfiles installation completed"
}

configure_macos() {
    if [[ $SKIP_MACOS == true ]]; then
        print_info "Skipping macOS system configuration"
        return 0
    fi
    
    print_step "Configuring macOS system preferences"
    
    # TODO: Implement macOS configuration scripts
    # This would include scripts for:
    # - Dock preferences
    # - Finder preferences  
    # - Security settings
    # - Trackpad/keyboard settings
    # - Energy preferences
    
    print_info "macOS configuration scripts not yet implemented"
    print_info "This will be added in FASE 4 of the project"
    
    print_success "macOS configuration completed"
}

setup_development_environment() {
    print_step "Setting up development environment"
    
    # Install Oh My Zsh if not present
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_info "Installing Oh My Zsh..."
        if [[ $DRY_RUN == true ]]; then
            print_info "DRY RUN: Would install Oh My Zsh"
        else
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
    fi
    
    # Set ZSH as default shell if not already
    if [[ "$SHELL" != "/bin/zsh" ]] && [[ "$SHELL" != "/usr/local/bin/zsh" ]] && [[ "$SHELL" != "/opt/homebrew/bin/zsh" ]]; then
        print_info "Setting ZSH as default shell..."
        if [[ $DRY_RUN == true ]]; then
            print_info "DRY RUN: Would change default shell to zsh"
        else
            chsh -s "$(which zsh)"
        fi
    fi
    
    # Source the new configurations
    if [[ $DRY_RUN == false ]] && [[ -f "$HOME/.zshrc" ]]; then
        print_info "Sourcing new ZSH configuration..."
        # Note: This won't work in the current shell, but informs the user
        print_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
    fi
    
    print_success "Development environment setup completed"
}

show_completion_summary() {
    print_step "Installation Summary"
    
    echo -e "${GREEN}"
    echo "============================================================================="
    echo "  🎉 Dotfiles Installation Completed Successfully!"
    echo "============================================================================="
    echo -e "${NC}"
    
    echo "📁 Backup directory: $BACKUP_DIR"
    echo "🔧 Packages installed:"
    
    local packages_to_show=()
    if [[ -n "$CUSTOM_PACKAGES" ]]; then
        IFS=',' read -ra packages_to_show <<< "$CUSTOM_PACKAGES"
    elif [[ $MINIMAL_INSTALL == true ]]; then
        packages_to_show=("${ESSENTIAL_PACKAGES[@]}")
    else
        packages_to_show=("${ALL_PACKAGES[@]}")
    fi
    
    for package in "${packages_to_show[@]}"; do
        echo "   ✅ $package"
    done
    
    echo
    echo "🚀 Next Steps:"
    echo "   1. Restart your terminal or run 'source ~/.zshrc'"
    echo "   2. Verify installations with 'brew doctor'"
    echo "   3. Check symlinks with 'ls -la ~/ | grep \"->\"'"
    echo "   4. Review and customize configurations as needed"
    
    if [[ $SKIP_MACOS == true ]]; then
        echo "   5. Run macOS configuration scripts when ready"
    fi
    
    echo
    echo "📚 Documentation: $DOTFILES_DIR/docs/"
    echo "🐛 Issues: Check the troubleshooting guide or create an issue"
    echo
}

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --dry-run, -d       Perform a dry run (show what would be done)"
    echo "  --minimal, -m       Install only essential packages"
    echo "  --full, -f          Install everything including optional packages (default)"
    echo "  --skip-homebrew     Skip Homebrew installation and updates"
    echo "  --skip-macos        Skip macOS system configuration"
    echo "  --skip-stow         Skip GNU Stow symlink creation"
    echo "  --packages <list>   Install only specified packages (comma-separated)"
    echo
    echo "Examples:"
    echo "  $0                                    # Full installation"
    echo "  $0 --minimal                         # Minimal installation"
    echo "  $0 --dry-run                         # See what would be done"
    echo "  $0 --packages zsh,git,homebrew       # Install specific packages"
    echo "  $0 --skip-homebrew --skip-macos      # Only install dotfiles"
    echo
    echo "Available packages:"
    echo "  Essential: ${ESSENTIAL_PACKAGES[*]}"
    echo "  Optional:  ${OPTIONAL_PACKAGES[*]}"
    echo
}

# =============================================================================
# Command Line Argument Parsing
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --dry-run|-d)
                DRY_RUN=true
                shift
                ;;
            --minimal|-m)
                MINIMAL_INSTALL=true
                FULL_INSTALL=false
                shift
                ;;
            --full|-f)
                FULL_INSTALL=true
                MINIMAL_INSTALL=false
                shift
                ;;
            --skip-homebrew)
                SKIP_HOMEBREW=true
                shift
                ;;
            --skip-macos)
                SKIP_MACOS=true
                shift
                ;;
            --skip-stow)
                SKIP_STOW=true
                shift
                ;;
            --packages)
                CUSTOM_PACKAGES="$2"
                MINIMAL_INSTALL=false
                FULL_INSTALL=false
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Main Installation Function
# =============================================================================

main() {
    parse_arguments "$@"
    
    print_banner
    
    if [[ $DRY_RUN == true ]]; then
        print_warning "DRY RUN MODE - No changes will be made"
        echo
    fi
    
    # Pre-installation checks
    check_requirements
    
    # Create backup of existing configurations
    backup_existing_configs
    
    # Install prerequisites
    install_homebrew
    install_stow
    
    # Install packages via Homebrew
    install_packages_with_homebrew
    
    # Install dotfiles
    install_dotfiles
    
    # Configure macOS (FASE 4)
    configure_macos
    
    # Setup development environment
    setup_development_environment
    
    # Show completion summary
    if [[ $DRY_RUN == false ]]; then
        show_completion_summary
    else
        print_info "DRY RUN completed - no changes were made"
    fi
}

# =============================================================================
# Script Execution
# =============================================================================

# Trap errors and cleanup
trap 'print_error "Installation failed at line $LINENO"' ERR

# Run main function with all arguments
main "$@"

# =============================================================================
# End of installation script
# =============================================================================