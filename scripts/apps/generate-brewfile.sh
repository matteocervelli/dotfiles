#!/usr/bin/env bash
#
# generate-brewfile.sh - Generate organized Brewfile from application audit
#
# Usage:
#   ./scripts/apps/generate-brewfile.sh [OPTIONS]
#
# Options:
#   --input FILE     Input audit file (default: applications/current_macos_apps_*.txt)
#   --output FILE    Output Brewfile (default: system/macos/Brewfile)
#   --dry-run        Show output without writing file
#   --help           Show this help message
#
# Description:
#   Parses application audit data and generates a well-organized Brewfile
#   with categorized formulae and casks for reproducible macOS setup.
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$SCRIPT_DIR/../utils/logger.sh"

# Default values
INPUT_FILE=""
OUTPUT_FILE="$DOTFILES_ROOT/system/macos/Brewfile"
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --input)
            INPUT_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            grep "^#" "$0" | grep -v "^#!/" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Find most recent audit file if not specified
if [[ -z "$INPUT_FILE" ]]; then
    INPUT_FILE=$(find "$DOTFILES_ROOT/applications" -name "current_macos_apps_*.txt" -type f | sort -r | head -n 1)
    if [[ -z "$INPUT_FILE" ]]; then
        log_error "No audit file found. Run ./scripts/apps/audit-apps.sh first"
        exit 1
    fi
    log_info "Using audit file: $(basename "$INPUT_FILE")"
fi

# Verify input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    log_error "Input file not found: $INPUT_FILE"
    exit 1
fi

# Arrays for package categorization
declare -a taps=()
declare -a dev_tools=()
declare -a languages=()
declare -a databases=()
declare -a infrastructure=()
declare -a cli_utils=()
declare -a productivity=()
declare -a media=()
declare -a security=()
declare -a system_libs=()
declare -a fonts=()
declare -a mas_apps=()

#
# Categorization logic
#
categorize_formula() {
    local pkg="$1"

    # Development Tools
    case "$pkg" in
        git|gh|lazygit|vim|neovim|cmake|autoconf|make|gcc|llvm|clang*)
            dev_tools+=("$pkg")
            ;;
        # Languages & Runtimes
        python*|node|go|rust|ruby|perl|lua*|php|java|openjdk*|groovy|deno)
            languages+=("$pkg")
            ;;
        # Databases & Data Tools
        postgresql*|pgcli|pgvector|redis|sqlite|mysql*|mongodb*)
            databases+=("$pkg")
            ;;
        # Infrastructure & DevOps
        docker*|kubernetes*|terraform|ansible|ollama|qemu|caddy|nginx|socat)
            infrastructure+=("$pkg")
            ;;
        # Security Tools
        1password-cli|gnupg|gpg*|mkcert|openssl*|pinentry|certifi)
            security+=("$pkg")
            ;;
        # CLI Utilities
        bat|eza|fzf|htop|btop|glances|tree|wget|curl|jq|yq|rclone|stow|tmux|moreutils|pv|pwgen|arp-scan)
            cli_utils+=("$pkg")
            ;;
        # Media & Creative
        ffmpeg|imagemagick|giflib|jpeg*|libpng|libtiff|webp|vlc|obs|audacity|inkscape|potrace|graphite2)
            media+=("$pkg")
            ;;
        # Fonts
        font-*)
            fonts+=("$pkg")
            ;;
        # System Libraries (dependencies)
        *lib*|*ssl*|icu4c*|gettext|pkg-config|pkgconf|readline|ncurses|ca-certificates|gmp|mpfr|isl|pcre*)
            system_libs+=("$pkg")
            ;;
        # Default to CLI utilities if unknown
        *)
            cli_utils+=("$pkg")
            ;;
    esac
}

categorize_cask() {
    local pkg="$1"

    case "$pkg" in
        # Development
        visual-studio-code|cursor|iterm*|docker*|pgadmin*|git-credential-manager|flutter|dotnet-sdk)
            dev_tools+=("$pkg")
            ;;
        # Browsers & Productivity
        firefox|google-chrome|microsoft-edge|ungoogled-chromium|brave-browser|arc)
            productivity+=("$pkg")
            ;;
        # Infrastructure
        tailscale*|gcloud-cli|container)
            infrastructure+=("$pkg")
            ;;
        # Media & Creative
        vlc|obs|audacity|inkscape|gimp*)
            media+=("$pkg")
            ;;
        # Security
        1password|bitwarden|protonvpn*)
            security+=("$pkg")
            ;;
        # Productivity Apps
        libreoffice|zotero|nook|rstudio)
            productivity+=("$pkg")
            ;;
        # Fonts
        font-*)
            fonts+=("$pkg")
            ;;
        # Default
        *)
            productivity+=("$pkg")
            ;;
    esac
}

#
# Parse audit file
#
log_info "Parsing audit file..."

in_formulae=false
in_casks=false
in_mas=false

while IFS= read -r line; do
    # Detect sections
    if [[ "$line" =~ ^===\ Homebrew\ Formulae ]]; then
        in_formulae=true
        in_casks=false
        in_mas=false
        continue
    elif [[ "$line" =~ ^===\ Homebrew\ Casks ]]; then
        in_formulae=false
        in_casks=true
        in_mas=false
        continue
    elif [[ "$line" =~ ^===\ Mac\ App\ Store ]]; then
        in_formulae=false
        in_casks=false
        in_mas=true
        continue
    elif [[ "$line" =~ ^=== ]]; then
        in_formulae=false
        in_casks=false
        in_mas=false
        continue
    fi

    # Skip empty lines and headers
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[0-9]+\. ]] && continue

    # Parse packages
    if [[ "$in_formulae" == true ]]; then
        categorize_formula "$line"
    elif [[ "$in_casks" == true ]]; then
        categorize_cask "$line"
    elif [[ "$in_mas" == true ]]; then
        # Extract mas app (format: "123456 AppName (1.0)")
        if [[ "$line" =~ ^[0-9]+ ]]; then
            mas_apps+=("$line")
        fi
    fi
done < "$INPUT_FILE"

#
# Generate Brewfile
#
log_info "Generating Brewfile..."

generate_brewfile() {
    cat <<'EOF'
#
# Brewfile - Homebrew package manifest for macOS
#
# Generated by: scripts/apps/generate-brewfile.sh
# Last updated: $(date +"%Y-%m-%d %H:%M:%S")
#
# Usage:
#   brew bundle install           # Install all packages
#   brew bundle check             # Check what's installed
#   brew bundle cleanup           # Remove packages not in Brewfile
#   brew bundle cleanup --force   # Actually remove them
#
# To update this file:
#   ./scripts/apps/generate-brewfile.sh
#   make brewfile-generate
#

EOF

    # Taps
    echo "# ============================================================================"
    echo "# Taps - Third-party repositories"
    echo "# ============================================================================"
    echo ""
    echo "tap \"homebrew/bundle\""
    echo "tap \"homebrew/services\""
    echo ""

    # Development Tools
    if [[ ${#dev_tools[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Development Tools"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${dev_tools[@]}" | sort -u | while read -r pkg; do
            if [[ "$pkg" == *"-"* ]] && [[ ! "$pkg" =~ ^font- ]]; then
                echo "cask \"$pkg\""
            else
                echo "brew \"$pkg\""
            fi
        done
        echo ""
    fi

    # Languages & Runtimes
    if [[ ${#languages[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Languages & Runtimes"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${languages[@]}" | sort -u | while read -r pkg; do
            echo "brew \"$pkg\""
        done
        echo ""
    fi

    # Databases & Data Tools
    if [[ ${#databases[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Databases & Data Tools"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${databases[@]}" | sort -u | while read -r pkg; do
            echo "brew \"$pkg\""
        done
        echo ""
    fi

    # Infrastructure & DevOps
    if [[ ${#infrastructure[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Infrastructure & DevOps"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${infrastructure[@]}" | sort -u | while read -r pkg; do
            if [[ "$pkg" == *"-"* ]]; then
                echo "cask \"$pkg\""
            else
                echo "brew \"$pkg\""
            fi
        done
        echo ""
    fi

    # Security Tools
    if [[ ${#security[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Security Tools"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${security[@]}" | sort -u | while read -r pkg; do
            if [[ "$pkg" == *"-"* ]]; then
                echo "cask \"$pkg\""
            else
                echo "brew \"$pkg\""
            fi
        done
        echo ""
    fi

    # CLI Utilities
    if [[ ${#cli_utils[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# CLI Utilities & Tools"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${cli_utils[@]}" | sort -u | while read -r pkg; do
            echo "brew \"$pkg\""
        done
        echo ""
    fi

    # Productivity Apps
    if [[ ${#productivity[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Productivity Applications"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${productivity[@]}" | sort -u | while read -r pkg; do
            echo "cask \"$pkg\""
        done
        echo ""
    fi

    # Media & Creative
    if [[ ${#media[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Media & Creative Tools"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${media[@]}" | sort -u | while read -r pkg; do
            if [[ "$pkg" == *"-"* ]] && [[ ! "$pkg" =~ ^lib ]]; then
                echo "cask \"$pkg\""
            else
                echo "brew \"$pkg\""
            fi
        done
        echo ""
    fi

    # System Libraries
    if [[ ${#system_libs[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# System Libraries & Dependencies"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${system_libs[@]}" | sort -u | while read -r pkg; do
            echo "brew \"$pkg\""
        done
        echo ""
    fi

    # Fonts
    if [[ ${#fonts[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Fonts"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${fonts[@]}" | sort -u | while read -r pkg; do
            echo "cask \"$pkg\""
        done
        echo ""
    fi

    # Mac App Store
    if [[ ${#mas_apps[@]} -gt 0 ]]; then
        echo "# ============================================================================"
        echo "# Mac App Store Applications"
        echo "# Requires: brew install mas"
        echo "# ============================================================================"
        echo ""
        printf '%s\n' "${mas_apps[@]}" | while read -r app; do
            # Format: mas "AppName", id: 123456
            if [[ "$app" =~ ^([0-9]+)\ (.+)\ \(([0-9.]+)\) ]]; then
                app_id="${BASH_REMATCH[1]}"
                app_name="${BASH_REMATCH[2]}"
                echo "mas \"$app_name\", id: $app_id"
            fi
        done
        echo ""
    fi

    # Footer
    echo "# ============================================================================"
    echo "# End of Brewfile"
    echo "# ============================================================================"
}

# Output
if [[ "$DRY_RUN" == true ]]; then
    log_info "Dry-run mode: showing output"
    generate_brewfile
else
    # Create output directory if needed
    mkdir -p "$(dirname "$OUTPUT_FILE")"

    # Generate and write
    generate_brewfile > "$OUTPUT_FILE"

    log_success "Brewfile generated: $OUTPUT_FILE"
    log_info "Validate with: brew bundle check --file=$OUTPUT_FILE"
fi

# Summary
log_info "Summary:"
log_info "  Development Tools: ${#dev_tools[@]}"
log_info "  Languages: ${#languages[@]}"
log_info "  Databases: ${#databases[@]}"
log_info "  Infrastructure: ${#infrastructure[@]}"
log_info "  Security: ${#security[@]}"
log_info "  CLI Utilities: ${#cli_utils[@]}"
log_info "  Productivity: ${#productivity[@]}"
log_info "  Media & Creative: ${#media[@]}"
log_info "  System Libraries: ${#system_libs[@]}"
log_info "  Fonts: ${#fonts[@]}"
log_info "  Mac App Store: ${#mas_apps[@]}"
log_info "  Total: $((${#dev_tools[@]} + ${#languages[@]} + ${#databases[@]} + ${#infrastructure[@]} + ${#security[@]} + ${#cli_utils[@]} + ${#productivity[@]} + ${#media[@]} + ${#system_libs[@]} + ${#fonts[@]} + ${#mas_apps[@]}))"
