#!/usr/bin/env bash
# =============================================================================
# Shell Package Deployment Script
# Safely deploys shell package with backup and rollback support
# =============================================================================

set -e

DOTFILES_DIR="$HOME/dev/projects/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup/shell-$(date +%Y%m%d-%H%M%S)"
STOW_DIR="$DOTFILES_DIR/stow-packages"

echo "🚀 Shell Package Deployment"
echo "==========================="
echo ""

# Create backup directory
echo "📦 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup existing files
echo "💾 Backing up existing shell configuration files..."
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
    echo "  ✓ Backed up .zshrc"
fi

if [ -f "$HOME/.bashrc" ]; then
    cp "$HOME/.bashrc" "$BACKUP_DIR/.bashrc"
    echo "  ✓ Backed up .bashrc"
fi

if [ -d "$HOME/.config/shell" ]; then
    cp -r "$HOME/.config/shell" "$BACKUP_DIR/.config-shell"
    echo "  ✓ Backed up .config/shell/"
fi

# Remove existing files to avoid conflicts
echo ""
echo "🗑️  Removing existing files (backed up)..."
rm -f "$HOME/.zshrc"
rm -f "$HOME/.bashrc"
# Don't remove .config/shell as it might be a symlink already

# Stow the shell package
echo ""
echo "🔗 Stowing shell package..."
cd "$DOTFILES_DIR"
stow -t ~ -d stow-packages -v shell

echo ""
echo "✅ Shell package deployed successfully!"
echo ""
echo "📍 Backup location: $BACKUP_DIR"
echo ""
echo "🔄 To apply changes, run: exec zsh"
echo ""
echo "⚠️  To rollback if needed:"
echo "   stow -D -t ~ -d $STOW_DIR shell"
echo "   cp $BACKUP_DIR/.zshrc ~/.zshrc"
echo "   cp $BACKUP_DIR/.bashrc ~/.bashrc"
echo ""
