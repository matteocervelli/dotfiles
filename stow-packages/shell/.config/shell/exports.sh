#!/usr/bin/env bash
# =============================================================================
# Environment Exports
# Managed by dotfiles: ~/dev/projects/dotfiles
# =============================================================================

# =============================================================================
# System Environment
# =============================================================================

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='nano'
else
    export EDITOR='code'
fi

export VISUAL='code'

# =============================================================================
# PATH Additions
# =============================================================================

# Node.js (ensure Node.js is always available)
export PATH="$HOME/.nvm/versions/node/v24.1.0/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
export NVM_SYMLINK_CURRENT=true
export PATH="/opt/homebrew/opt/nvm/bin:$PATH"

# PyEnv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Docker
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# OpenJDK
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# =============================================================================
# Application-Specific
# =============================================================================

# PostgreSQL
export PGPASSFILE="$HOME/.secrets/.pgpass"

# =============================================================================
# Lazy Loading Functions
# =============================================================================

# PyEnv - Lazy load for performance
if command -v pyenv 1>/dev/null 2>&1; then
  # Path setup
  eval "$(pyenv init --path)"

  # Lazy load function
  pyenv() {
    unset -f pyenv
    eval "$(pyenv init -)"
    pyenv "$@"
  }
fi

# NVM - Lazy load for performance
nvm() {
    unset -f nvm
    [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"
    [ -s "$HOME/.nvm/bash_completion" ] && \. "$HOME/.nvm/bash_completion"
    nvm "$@"
}

# =============================================================================
# End of exports
# =============================================================================
