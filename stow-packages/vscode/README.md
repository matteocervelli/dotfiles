# VS Code Stow Package

VS Code settings synchronized across macOS and Linux.

## Contains

- `settings.json` - Editor configuration
- `keybindings.json` - Keyboard shortcuts
- `extensions.txt` - Extension list (92 extensions)

## Installation

### macOS

```bash
cd ~/dev/projects/dotfiles
stow -t ~ vscode
```

### Linux (Ubuntu VM)

```bash
cd ~/dev/projects/dotfiles
stow -t ~ vscode

# Install all extensions
while read -r ext; do
    [[ "$ext" =~ ^#.*$ || -z "$ext" ]] && continue
    code --install-extension "$ext"
done < ~/.config/Code/User/extensions.txt
```

## Verification

```bash
# Check symlinks are created
ls -la ~/.config/Code/User/
# Should show: settings.json -> ~/dev/projects/dotfiles/stow-packages/vscode/.config/Code/User/settings.json

# Verify extensions installed
code --list-extensions | wc -l
# Should show: 92
```

## Notes

- Settings copied from Cursor (VS Code compatible)
- No snippets included (not needed)
- Extensions list also maintained in `applications/vscode-extensions.txt`
- Compatible with VS Code on both macOS and Linux

## Updating

### Export current settings (macOS)

```bash
# Settings already symlinked, changes auto-saved

# Update extensions list
code --list-extensions > stow-packages/vscode/.config/Code/User/extensions.txt
```

### Sync to new machine

```bash
# 1. Stow the package
stow -t ~ vscode

# 2. Install extensions
while read -r ext; do
    [[ "$ext" =~ ^#.*$ || -z "$ext" ]] && continue
    code --install-extension "$ext"
done < ~/.config/Code/User/extensions.txt
```
