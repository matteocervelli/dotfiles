#!/bin/bash
# =============================================================================
# Bash Configuration - Matteo Cervelli's dotfiles
# Managed by dotfiles: ~/dev/projects/dotfiles
# =============================================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# =============================================================================
# History Configuration
# =============================================================================

# Don't put duplicate lines or lines starting with space in history
HISTCONTROL=ignoreboth

# Append to history file, don't overwrite it
shopt -s histappend

# History length
HISTSIZE=10000
HISTFILESIZE=20000

# Check window size after each command
shopt -s checkwinsize

# =============================================================================
# Shell Options
# =============================================================================

# Enable extended pattern matching
shopt -s extglob

# Enable recursive globbing with **
shopt -s globstar 2>/dev/null

# =============================================================================
# Prompt
# =============================================================================

# Simple but informative prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# =============================================================================
# Load Modular Configurations
# =============================================================================

# Source XDG environment configuration first (sets XDG_* variables and HISTFILE)
[[ -f "$HOME/.config/shell/dev-tools.sh" ]] && source "$HOME/.config/shell/dev-tools.sh"

# Source modular shell configs (shared with ZSH)
[[ -f "$HOME/.config/shell/exports.sh" ]] && source "$HOME/.config/shell/exports.sh"
[[ -f "$HOME/.config/shell/aliases.sh" ]] && source "$HOME/.config/shell/aliases.sh"
[[ -f "$HOME/.config/shell/functions.sh" ]] && source "$HOME/.config/shell/functions.sh"
[[ -f "$HOME/.config/shell/postgres.sh" ]] && source "$HOME/.config/shell/postgres.sh"
[[ -f "$HOME/.config/shell/ollama.sh" ]] && source "$HOME/.config/shell/ollama.sh"
[[ -f "$HOME/.config/shell/hugo.sh" ]] && source "$HOME/.config/shell/hugo.sh"

# =============================================================================
# Completion
# =============================================================================

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# =============================================================================
# End of Bash Configuration
# =============================================================================
