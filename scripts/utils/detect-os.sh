#!/usr/bin/env bash
# OS Detection Utility
# Returns: macos, ubuntu, fedora, arch, alpine, linux, windows, or unknown
#
# Usage:
#   Direct execution:
#     ./detect-os.sh
#     # Output: macos
#
#   Sourcing in scripts:
#     source scripts/utils/detect-os.sh
#     OS=$(detect_os)
#     echo "Running on: $OS"
#
# Supported platforms:
#   - macOS (Darwin)
#   - Ubuntu Linux
#   - Fedora Linux
#   - Arch Linux
#   - Alpine Linux
#   - Generic Linux
#   - Windows (WSL, Git Bash, Cygwin, MSYS2)
#   - Unknown (unsupported platforms)

detect_os() {
    local uname_s
    uname_s="$(uname -s)"

    case "$uname_s" in
        Darwin*)
            # macOS / Darwin
            echo "macos"
            ;;

        Linux*)
            # First check if running under WSL (Windows Subsystem for Linux)
            if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
                echo "windows"
                return 0
            fi

            # Check for specific Linux distributions
            if [ -f /etc/os-release ]; then
                # Source os-release to get distribution ID
                . /etc/os-release
                case "$ID" in
                    ubuntu)
                        echo "ubuntu"
                        ;;
                    fedora)
                        echo "fedora"
                        ;;
                    arch)
                        echo "arch"
                        ;;
                    alpine)
                        echo "alpine"
                        ;;
                    debian)
                        # Debian-based but not Ubuntu
                        echo "linux"
                        ;;
                    rhel|centos|rocky|almalinux)
                        # Red Hat family
                        echo "linux"
                        ;;
                    *)
                        # Other Linux distribution
                        echo "linux"
                        ;;
                esac
            else
                # No /etc/os-release, generic Linux
                echo "linux"
            fi
            ;;

        CYGWIN*|MINGW*|MSYS*|MINGW32*|MINGW64*)
            # Windows environments (Git Bash, Cygwin, MSYS2)
            echo "windows"
            ;;

        *)
            # Unknown/unsupported operating system
            echo "unknown"
            ;;
    esac
}

# Additional helper function to get detailed OS information
get_os_details() {
    local os
    os=$(detect_os)

    case "$os" in
        macos)
            local macos_version
            macos_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
            echo "macOS $macos_version"
            ;;

        ubuntu|fedora|arch|alpine|linux)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                echo "$PRETTY_NAME"
            else
                echo "Linux (unknown distribution)"
            fi
            ;;

        windows)
            if grep -qEi "Microsoft" /proc/version 2>/dev/null; then
                # WSL
                local wsl_version
                if [ -f /etc/os-release ]; then
                    . /etc/os-release
                    wsl_version="$PRETTY_NAME"
                else
                    wsl_version="Linux"
                fi
                echo "Windows (WSL: $wsl_version)"
            else
                # Git Bash / MSYS2 / Cygwin
                echo "Windows ($OSTYPE)"
            fi
            ;;

        unknown)
            echo "Unknown OS ($(uname -s))"
            ;;
    esac
}

# Check if script is being executed directly or sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Script executed directly - output OS type
    detect_os
else
    # Script is being sourced - functions are now available
    # Optionally export functions for use in subshells
    export -f detect_os 2>/dev/null || true
    export -f get_os_details 2>/dev/null || true
fi
