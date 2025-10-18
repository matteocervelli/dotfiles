#!/usr/bin/env bash
# =============================================================================
# macOS-Specific Configuration
# Managed by dotfiles: ~/dev/projects/dotfiles
# =============================================================================

# Only load on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    return
fi

# =============================================================================
# macOS-Specific Aliases
# =============================================================================

# Tailscale (if installed)
if [ -d "/Applications/Tailscale.app" ]; then
    alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
fi

# =============================================================================
# End of macOS configuration
# =============================================================================
