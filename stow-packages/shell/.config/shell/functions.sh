#!/usr/bin/env bash
# =============================================================================
# Shell Functions
# Managed by dotfiles: ~/dev/projects/dotfiles
# =============================================================================

# =============================================================================
# Homebrew Management
# =============================================================================

brewup() {
  echo "🔄 Updating Homebrew.."
  brew update
  echo "⬆️ Upgrading all formulae and casks..."
  brew upgrade --greedy
  echo "🧹 Cleaning up.."
  brew cleanup
  echo "👨🏻‍⚕️ Running doctor..."
  brew doctor
  echo "✅ Homebrew update complete!"
}

# =============================================================================
# Python Management
# =============================================================================

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

# =============================================================================
# Application Audit
# =============================================================================

appsup() {
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

# =============================================================================
# End of functions
# =============================================================================
