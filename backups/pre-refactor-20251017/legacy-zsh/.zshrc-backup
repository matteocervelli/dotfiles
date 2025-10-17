# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Moduli esterni (alias, exports, tools)
[[ -f "$HOME/.zsh_aliases" ]] && source "$HOME/.zsh_aliases"
[[ -f "$HOME/.zsh_exports" ]] && source "$HOME/.zsh_exports"

# Ensure Node.js is always available (fix for claude and other Node.js apps)
export PATH="/Users/matteocervelli/.nvm/versions/node/v24.1.0/bin:$PATH"
[[ -f "$HOME/.zsh_plugins" ]] && source "$HOME/.zsh_plugins"

# Esecuzione Brew
eval "$(/opt/homebrew/bin/brew shellenv)"

brewup() {
  echo "🔄 Updating Homebrew.."
  brew update
  echo "⬆️ Upgrading all formulae and casks..."
  brew upgrade --greedy
  echo "🧹 Cleaning up.."
  brew cleanup
  echo "✅ Homebrew update complete!"
}

pythonup() {
  echo "🐍 Starting Python update..."
  if command -v brew &>/dev/null; then
    echo "🔧 Updating Python with Homebrew..."
    brew upgrade python
  else
    echo "⚠️ Homebrew not found. Skipping Homebrew update."
  fi

  if command -v pyenv &>/dev/null; then
    echo "🌐 Checking latest Python version available via pyenv..."
    latest=$(pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
    if pyenv versions | grep -q "$latest"; then
      echo "✅ Latest version $latest is already installed."
    else
      echo "⬇️ Installing Python $latest via pyenv..."
      pyenv install "$latest"
    fi
    echo "🔁 Setting Python $latest as global default..."
    pyenv global "$latest"
    echo "📦 Installed Python versions:"
    pyenv versions
  else
    echo "⚠️ pyenv not found. Skipping pyenv update."
  fi
  echo "✅ Python update complete!"
}

check_manual_apps() {
  echo "🔍 Scanning /Applications for manually installed apps..."

  # All installed apps
  installed_apps=($(ls /Applications | grep -E '\.app$' | sed 's/\.app$//' | sort))

  # Apps managed by Homebrew Cask
  brew_cask_apps=($(brew list --cask 2>/dev/null | tr '[:upper:]' '[:lower:]'))

  # Apps from Mac App Store via mas
  if command -v mas &>/dev/null; then
    mas_apps=($(mas list | cut -d' ' -f2- | tr '[:upper:]' '[:lower:]'))
  else
    echo "ℹ️ mas not found. Skipping App Store check. Install with: brew install mas"
    mas_apps=()
  fi

  echo ""
  echo "📋 Checking manually installed apps against Homebrew and App Store..."
  echo ""

  for app in "${installed_apps[@]}"; do
    app_lower=$(echo "$app" | tr '[:upper:]' '[:lower:]')

    if [[ " ${brew_cask_apps[*]} " =~ " $app_lower " ]] || [[ " ${mas_apps[*]} " =~ " $app_lower " ]]; then
      continue  # already managed
    fi

    echo "🔸 $app"

    # Check in Homebrew Cask
    if brew search --casks "$app_lower" | grep -q "$app_lower"; then
      echo "   ✅ Available in Homebrew Cask"
    else
      echo "   ❌ Not found in Homebrew Cask"
    fi

    # Check in Mac App Store (requires mas)
    if command -v mas &>/dev/null; then
      mas_search=$(mas search "$app" | head -1)
      if [[ -n "$mas_search" ]]; then
        echo "   🛍️  Found in Mac App Store: $mas_search"
      else
        echo "   ❌ Not found in Mac App Store"
      fi
    fi

    echo ""
  done

  echo "✅ Scan complete!"
}

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/matteocervelli/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

. "$HOME/.local/bin/env"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/matteocervelli/.lmstudio/bin"
# End of LM Studio CLI section

# Alias per gestire i reindirizzamenti di adli.men
alias newshort=~/dev/scripts/add-new-short-link.sh
# Alias per gestire i reindirizzamenti di adli.men

# bun completions
[ -s "/Users/matteocervelli/.bun/_bun" ] && source "/Users/matteocervelli/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export EDITOR=coteditor
export EDITOR=cot
alias claude="/Users/matteocervelli/.claude/local/claude"

# NVM now loaded via lazy loading in .zsh_exports
