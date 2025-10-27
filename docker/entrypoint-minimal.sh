#!/bin/bash
# Minimal Container Entrypoint
# Initializes the container environment for minimal profile
#
# Usage:
#   docker run -it --rm dotfiles-ubuntu:minimal
#   docker run -it --rm -v $(pwd):/workspace dotfiles-ubuntu:minimal

set -e

# Display welcome message
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║         Ubuntu Dotfiles Container - Minimal Profile          ║
╚═══════════════════════════════════════════════════════════════╝

Profile: container-minimal
Includes: Shell (ZSH + Oh My Zsh) + Git configuration
User: developer (UID 1000)

EOF

# Show configuration status
echo "Container initialized with:"
echo "  - ZSH: $(zsh --version 2>/dev/null || echo 'Not available')"
echo "  - Git: $(git --version 2>/dev/null || echo 'Not available')"
echo "  - GNU Stow: $(stow --version 2>/dev/null | head -n1 || echo 'Not available')"
echo ""

# Check for mounted workspace
if [ -d "/workspace" ]; then
    echo "Workspace mounted at: /workspace"
    cd /workspace
fi

echo "Starting shell..."
echo ""

# Execute the command passed to the container
# Default is /bin/zsh from Dockerfile CMD
exec "$@"
