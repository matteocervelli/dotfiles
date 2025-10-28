#!/usr/bin/env bash
# Remove macOS metadata files from dotfiles repository
# These files cause conflicts when stowing on Linux

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Cleaning up macOS metadata files from dotfiles..."

# Find and delete .DS_Store files
echo "Removing .DS_Store files..."
find "$PROJECT_ROOT/stow-packages" -name ".DS_Store" -type f -delete

# Find and delete ._* files (resource forks)
echo "Removing ._* resource fork files..."
find "$PROJECT_ROOT/stow-packages" -name "._*" -type f -delete

# Find and delete .AppleDouble directories
echo "Removing .AppleDouble directories..."
find "$PROJECT_ROOT/stow-packages" -name ".AppleDouble" -type d -exec rm -rf {} + 2>/dev/null || true

echo "✓ Cleanup complete!"
echo ""
echo "Files cleaned:"
echo "  - .DS_Store (macOS folder metadata)"
echo "  - ._* (macOS resource forks)"
echo "  - .AppleDouble (macOS double-encoded files)"
echo ""
echo "These files are now in .gitignore and won't be committed."
