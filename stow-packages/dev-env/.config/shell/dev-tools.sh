#!/usr/bin/env bash
# XDG Base Directory Configuration for Development Tools
#
# This file configures XDG-compliant locations for various development tools
# that support custom config/history paths via environment variables.
#
# Sourced by: ~/.zshrc, ~/.bashrc
# Part of: stow-packages/dev-env/
# Documentation: docs/xdg-compliance.md

# =============================================================================
# XDG Base Directories
# =============================================================================

# Set XDG base directories if not already defined
# These follow the XDG Base Directory Specification:
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# =============================================================================
# PostgreSQL (psql client)
# =============================================================================
# Status: ✅ Supported
# Documentation: https://www.postgresql.org/docs/current/app-psql.html

export PSQLRC="$XDG_CONFIG_HOME/postgresql/psqlrc"
export PSQL_HISTORY="$XDG_STATE_HOME/postgresql/history"

# Create directories if they don't exist
[[ ! -d "$XDG_CONFIG_HOME/postgresql" ]] && mkdir -p "$XDG_CONFIG_HOME/postgresql"
[[ ! -d "$XDG_STATE_HOME/postgresql" ]] && mkdir -p "$XDG_STATE_HOME/postgresql"

# =============================================================================
# Bash
# =============================================================================
# Status: 🟡 Partial - history only (config files must stay in ~/)
# Note: ~/.bashrc and ~/.bash_profile cannot be moved to XDG locations

export HISTFILE="$XDG_STATE_HOME/bash/history"

# Create directory if it doesn't exist
[[ ! -d "$XDG_STATE_HOME/bash" ]] && mkdir -p "$XDG_STATE_HOME/bash"

# =============================================================================
# Less
# =============================================================================
# Status: ✅ Supported

export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# Create directory if it doesn't exist
[[ ! -d "$XDG_STATE_HOME/less" ]] && mkdir -p "$XDG_STATE_HOME/less"

# =============================================================================
# R (optional - uncomment if you use R)
# =============================================================================
# Status: ✅ Supported
# Documentation: https://stat.ethz.ch/R-manual/R-devel/library/base/html/Startup.html
# Note: RStudio might not respect these custom locations

# export R_PROFILE_USER="$XDG_CONFIG_HOME/R/Rprofile"
# export R_HISTFILE="$XDG_STATE_HOME/R/history"
# export R_ENVIRON_USER="$XDG_CONFIG_HOME/R/Renviron"

# Create directories if they don't exist
# [[ ! -d "$XDG_CONFIG_HOME/R" ]] && mkdir -p "$XDG_CONFIG_HOME/R"
# [[ ! -d "$XDG_STATE_HOME/R" ]] && mkdir -p "$XDG_STATE_HOME/R"

# =============================================================================
# Python (optional - CAUTION: complex setup, see docs)
# =============================================================================
# Status: ⚠️ Complex - implement with caution
# Documentation: docs/xdg-compliance.md#python-history
#
# WARNING: This requires a PYTHONSTARTUP script to properly redirect history.
#          Risk of creating dual history files if not configured correctly.
#          Only enable if you understand the implications.

# export PYTHONSTARTUP="$XDG_CONFIG_HOME/python/pythonrc"

# Create directory if it doesn't exist
# [[ ! -d "$XDG_CONFIG_HOME/python" ]] && mkdir -p "$XDG_CONFIG_HOME/python"
# [[ ! -d "$XDG_STATE_HOME/python" ]] && mkdir -p "$XDG_STATE_HOME/python"

# =============================================================================
# Node.js / npm (optional - uncomment if you use Node)
# =============================================================================
# Status: 🟡 Partial
# Note: npm has partial XDG support via npm config

# export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
# export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
# export NPM_CONFIG_PREFIX="$XDG_DATA_HOME/npm"

# export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"

# Create directories if they don't exist
# [[ ! -d "$XDG_CONFIG_HOME/npm" ]] && mkdir -p "$XDG_CONFIG_HOME/npm"
# [[ ! -d "$XDG_CACHE_HOME/npm" ]] && mkdir -p "$XDG_CACHE_HOME/npm"
# [[ ! -d "$XDG_DATA_HOME/npm" ]] && mkdir -p "$XDG_DATA_HOME/npm"
# [[ ! -d "$XDG_STATE_HOME/node" ]] && mkdir -p "$XDG_STATE_HOME/node"

# =============================================================================
# Docker
# =============================================================================
# Status: 🟡 Partial
# Note: Docker config can be moved, but socket location is fixed

# export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# Create directory if it doesn't exist
# [[ ! -d "$XDG_CONFIG_HOME/docker" ]] && mkdir -p "$XDG_CONFIG_HOME/docker"

# =============================================================================
# Wget
# =============================================================================
# Status: ✅ Supported (via alias, not env var)

alias wget='wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'

# =============================================================================
# Migration Helper Functions
# =============================================================================

# Function to migrate a file from legacy location to XDG location
# Usage: migrate_to_xdg "~/.psql_history" "$XDG_STATE_HOME/postgresql/history"
migrate_to_xdg() {
    local legacy_path="$1"
    local xdg_path="$2"

    # Expand ~ to actual home directory
    legacy_path="${legacy_path/#\~/$HOME}"

    if [[ -f "$legacy_path" ]] && [[ ! -f "$xdg_path" ]]; then
        # Create parent directory if it doesn't exist
        local xdg_dir
        xdg_dir="$(dirname "$xdg_path")"
        [[ ! -d "$xdg_dir" ]] && mkdir -p "$xdg_dir"

        # Move file
        mv "$legacy_path" "$xdg_path"
        echo "✓ Migrated $(basename "$legacy_path") to $xdg_path"
    fi
}

# Auto-migrate common files on first run
if [[ ! -f "$HOME/.xdg_migration_done" ]]; then
    echo "🔄 Performing one-time XDG migration..."

    # Migrate PostgreSQL history
    migrate_to_xdg "~/.psql_history" "$XDG_STATE_HOME/postgresql/history"

    # Migrate bash history (only if not already migrated by Bash itself)
    if [[ -f "$HOME/.bash_history" ]] && [[ ! -f "$XDG_STATE_HOME/bash/history" ]]; then
        migrate_to_xdg "~/.bash_history" "$XDG_STATE_HOME/bash/history"
    fi

    # Migrate less history
    migrate_to_xdg "~/.lesshst" "$XDG_STATE_HOME/less/history"

    # Mark migration as complete
    touch "$HOME/.xdg_migration_done"
    echo "✓ XDG migration complete!"
fi

# =============================================================================
# Verification (for debugging)
# =============================================================================

# Uncomment to verify XDG paths on shell startup
# echo "XDG paths configured:"
# echo "  CONFIG: $XDG_CONFIG_HOME"
# echo "  DATA:   $XDG_DATA_HOME"
# echo "  STATE:  $XDG_STATE_HOME"
# echo "  CACHE:  $XDG_CACHE_HOME"
