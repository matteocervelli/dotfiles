#!/bin/bash
# Development Container Entrypoint
# Initializes the container environment for dev profile
#
# Usage:
#   docker run -it --rm dotfiles-ubuntu:dev
#   docker run -it --rm -v $(pwd):/workspace dotfiles-ubuntu:dev

set -e

# Display welcome message
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║        Ubuntu Dotfiles Container - Development Profile       ║
╚═══════════════════════════════════════════════════════════════╝

Profile: container-dev
Includes: Shell + Git + Python + Node.js + Dev Tools
User: developer (UID 1000)

EOF

# Show configuration status
echo "Container initialized with:"
echo "  - ZSH: $(zsh --version 2>/dev/null || echo 'Not available')"
echo "  - Git: $(git --version 2>/dev/null || echo 'Not available')"
echo "  - Python: $(python3 --version 2>/dev/null || echo 'Not available')"
echo "  - Node.js: $(node --version 2>/dev/null || echo 'Not available')"
echo "  - npm: $(npm --version 2>/dev/null || echo 'Not available')"
echo "  - GNU Stow: $(stow --version 2>/dev/null | head -n1 || echo 'Not available')"
echo ""

# Initialize pyenv if not already done
if [ -d "$HOME/.pyenv" ] && [ ! -f "$HOME/.pyenv/.initialized" ]; then
    echo "Initializing pyenv..."
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
    touch "$HOME/.pyenv/.initialized"
fi

# Initialize nvm if not already done
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
fi

# Check for mounted workspace
if [ -d "/workspace" ]; then
    echo "Workspace mounted at: /workspace"
    cd /workspace
fi

echo "Starting development environment..."
echo ""

# Execute the command passed to the container
# Default is /bin/zsh from Dockerfile CMD
exec "$@"
