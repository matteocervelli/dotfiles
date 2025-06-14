# =============================================================================
# ZSH Configuration - Matteo Cervelli's dotfiles
# =============================================================================

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion
# Case-sensitive completion must be off. _ and - will be interchangeable
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting
DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days)
export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# History configuration
HIST_STAMPS="yyyy-mm-dd"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_VERIFY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE

# Which plugins to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(
    git
    brew
    docker
    docker-compose
    node
    npm
    python
    pip
    pyenv
    vscode
    macos
    ssh-agent
    gpg-agent
    z
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# =============================================================================
# User Configuration
# =============================================================================

# Language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='nano'
else
    export EDITOR='cursor'
fi

# =============================================================================
# PATH Configuration
# =============================================================================

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# Python/pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Node/nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# Personal bin directory
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# Environment Variables
# =============================================================================

# GPG
export GPG_TTY=$(tty)

# SSH Agent (1Password)
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Development directories
export DEV_DIR="$HOME/dev"
export PROJECTS_DIR="$DEV_DIR/projects"

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# =============================================================================
# Aliases
# =============================================================================

# Load custom aliases
if [ -f ~/.zsh_aliases ]; then
    source ~/.zsh_aliases
fi

# =============================================================================
# Functions
# =============================================================================

# Load custom functions
if [ -f ~/.zsh_functions ]; then
    source ~/.zsh_functions
fi

# =============================================================================
# Additional Configuration
# =============================================================================

# Load any local configuration
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi

# iTerm2 shell integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Auto-completion
autoload -U compinit && compinit

# Direnv hook (if installed)
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# =============================================================================
# Prompt customization (after Oh My Zsh load)
# =============================================================================

# Hide username@hostname in prompt when in local terminal
prompt_context() {
    if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
        prompt_segment black default "%(!.%{%F{yellow}%}.)$USER"
    fi
}

# =============================================================================
# Performance optimizations
# =============================================================================

# Lazy load nvm to speed up shell startup
lazy_load_nvm() {
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # This loads nvm only when needed
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
}

# Only run if we're in an interactive shell
if [[ $- == *i* ]]; then
    lazy_load_nvm
fi

# =============================================================================
# End of configuration
# =============================================================================