# =============================================================================
# ZSH Configuration - Matteo Cervelli's dotfiles
# Managed by dotfiles: ~/dev/projects/dotfiles
# =============================================================================

# =============================================================================
# Early initialization - Things that might produce output
# =============================================================================

# Fix for Cursor IDE terminal issues - MUST be at the very top
if [[ "$TERM_PROGRAM" == "vscode" ]] || [[ -n "$VSCODE_INJECTION" ]]; then
  # Unset problematic variables that cause issues with VS Code/Cursor zsh integration
  unset argv 2>/dev/null || true
  # Force zsh to ignore errors from VS Code's integration script
  setopt no_nomatch 2>/dev/null || true
  # Clear the switching flag from bash
  unset SWITCHING_TO_ZSH 2>/dev/null || true
fi

# Brew initialization (might produce output)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Load environment variables early
. "$HOME/.local/bin/env"

# Disable autocorrection
unsetopt correct_all
unsetopt correct

# =============================================================================
# Powerlevel10k Instant Prompt - MUST come after anything that produces output
# =============================================================================

# Configure Powerlevel10k instant prompt based on environment
if [[ "$TERM_PROGRAM" == "vscode" ]] || [[ -n "$VSCODE_INJECTION" ]]; then
  # Disable instant prompt completely in VS Code/Cursor to avoid issues
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
else
  # Use quiet mode for other terminals
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# Oh My Zsh Configuration
# =============================================================================

# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme (disabled because using Powerlevel10k separately)
ZSH_THEME=""

# Auto-update behavior
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Disable autocorrection (annoying suggestions)
DISABLE_CORRECTION="true"

# Disable dotenv prompts (we use 1Password for secrets)
ZSH_DOTENV_PROMPT=false

# Completion waiting dots
COMPLETION_WAITING_DOTS="true"

# Disable marking untracked files under VCS as dirty (faster)
DISABLE_UNTRACKED_FILES_DIRTY="true"

# =============================================================================
# Oh My Zsh Plugins
# =============================================================================

# Detect OS for conditional plugins
OS_TYPE="unknown"
if [[ "$(uname -s)" == "Darwin" ]]; then
    OS_TYPE="macos"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
        ubuntu) OS_TYPE="ubuntu" ;;
        debian) OS_TYPE="debian" ;;
        arch) OS_TYPE="archlinux" ;;
        fedora) OS_TYPE="fedora" ;;
        alpine) OS_TYPE="alpine" ;;
    esac
fi

# Core plugins (always loaded)
core_plugins=(
    git
    docker
    docker-compose
    brew
    gh
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
    aliases
    alias-finder
    1password
)

# Development tools plugins
dev_plugins=(
    vscode
    node
    npm
    python
    pip
    pyenv
    bun
)

# Utility plugins
utility_plugins=(
    command-not-found
    copypath
    eza
    gcloud
    gitignore
    history
    rsync
    sudo
    web-search
)

# Security plugins
security_plugins=(
    ssh-agent
)

# OS-specific plugins (conditional)
os_plugins=()
case "$OS_TYPE" in
    macos)
        os_plugins+=(macos)
        ;;
    ubuntu)
        os_plugins+=(ubuntu)
        ;;
    debian)
        os_plugins+=(debian)
        ;;
    archlinux)
        os_plugins+=(archlinux)
        ;;
    fedora)
        os_plugins+=(dnf)
        ;;
    alpine)
        os_plugins+=(alpine)
        ;;
esac

# Combine all plugins
plugins=(
    ${core_plugins[@]}
    ${dev_plugins[@]}
    ${utility_plugins[@]}
    ${security_plugins[@]}
    ${os_plugins[@]}
)

# Plugin-specific settings
# alias-finder
zstyle ':omz:plugins:alias-finder' autoload yes
zstyle ':omz:plugins:alias-finder' longer yes
zstyle ':omz:plugins:alias-finder' exact yes
zstyle ':omz:plugins:alias-finder' cheaper yes

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# =============================================================================
# Powerlevel10k Theme
# =============================================================================

# Load Powerlevel10k theme
source ~/.vim/plugins/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# =============================================================================
# User Configuration
# =============================================================================

# Load modular shell configurations
# Source XDG environment configuration first (sets XDG_* variables)
[[ -f "$HOME/.config/shell/dev-tools.sh" ]] && source "$HOME/.config/shell/dev-tools.sh"

# Source other shell configurations
[[ -f "$HOME/.config/shell/exports.sh" ]] && source "$HOME/.config/shell/exports.sh"
[[ -f "$HOME/.config/shell/aliases.sh" ]] && source "$HOME/.config/shell/aliases.sh"
[[ -f "$HOME/.config/shell/functions.sh" ]] && source "$HOME/.config/shell/functions.sh"
[[ -f "$HOME/.config/shell/postgres.sh" ]] && source "$HOME/.config/shell/postgres.sh"
[[ -f "$HOME/.config/shell/ollama.sh" ]] && source "$HOME/.config/shell/ollama.sh"
[[ -f "$HOME/.config/shell/hugo.sh" ]] && source "$HOME/.config/shell/hugo.sh"
[[ -f "$HOME/.config/shell/macos.sh" ]] && source "$HOME/.config/shell/macos.sh"

# =============================================================================
# Application Integrations
# =============================================================================

# Docker CLI completions
fpath=(/Users/matteocervelli/.docker/completions $fpath)
autoload -Uz compinit
compinit

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# OpenJDK (if not already in exports.sh)
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# =============================================================================
# End of ZSH Configuration
# =============================================================================
