#!/bin/bash
# Pre-format backup check script
# Run this to identify valuable data to backup before formatting

set -e

BACKUP_LOG="$HOME/Desktop/pre-format-backup-checklist.txt"
EXTERNAL_HDD="${1:-/Volumes/YourExternalDrive}"

echo "==================================="
echo "PRE-FORMAT BACKUP CHECK"
echo "==================================="
echo ""
echo "Backup checklist will be saved to: $BACKUP_LOG"
echo "External HDD path: $EXTERNAL_HDD"
echo ""

{
echo "Generated: $(date)"
echo "=========================================="
echo ""

# 1. CRITICAL: Docker volumes with databases
echo "🐳 DOCKER VOLUMES (CRITICAL - Contains databases!)"
echo "-------------------------------------------"
if command -v docker &> /dev/null; then
    echo "Docker volumes found:"
    docker volume ls --format "{{.Name}}" 2>/dev/null || echo "Docker not running"
    echo ""
    echo "⚠️  ACTION: Backup Docker volumes with:"
    echo "    cd ~/dev && make backup"
    echo "    OR manually: docker run --rm -v VOLUME_NAME:/data -v /path/to/backup:/backup alpine tar czf /backup/VOLUME_NAME.tar.gz /data"
else
    echo "Docker not installed or not in PATH"
fi
echo ""

# 2. SSH/GPG Keys (should be in 1Password, but verify)
echo "🔑 SSH & GPG KEYS"
echo "-------------------------------------------"
if [ -d "$HOME/.ssh" ]; then
    echo "SSH keys found:"
    ls -lh "$HOME/.ssh/"*.pub 2>/dev/null || echo "No public keys found"
    echo ""
    echo "Private keys (should be in 1Password):"
    ls -1 "$HOME/.ssh/id_*" 2>/dev/null | grep -v ".pub" || echo "No private keys found"
fi
echo ""
if [ -d "$HOME/.gnupg" ]; then
    echo "GPG keys found:"
    gpg --list-secret-keys 2>/dev/null || echo "No GPG keys or gpg not installed"
fi
echo ""

# 3. Application data NOT in dotfiles
echo "📦 APPLICATION DATA (Not in dotfiles)"
echo "-------------------------------------------"

# VS Code extensions (should be in dotfiles, but verify)
if [ -d "$HOME/.vscode/extensions" ]; then
    EXTENSION_COUNT=$(ls -1 "$HOME/.vscode/extensions" 2>/dev/null | wc -l)
    echo "VS Code extensions: $EXTENSION_COUNT installed"
    echo "⚠️  Verify: packages/vscode/extensions.txt is up to date"
fi
echo ""

# Obsidian vault (if exists)
if [ -d "$HOME/Documents/Obsidian" ] || [ -d "$HOME/Library/Mobile Documents/iCloud~md~obsidian" ]; then
    echo "📓 Obsidian vault detected"
    echo "⚠️  ACTION: Copy Obsidian vault to HDD"
fi
echo ""

# 4. Browser data
echo "🌐 BROWSER DATA"
echo "-------------------------------------------"
echo "Chrome/Brave profiles:"
ls -1d "$HOME/Library/Application Support/Google/Chrome"* 2>/dev/null || echo "Chrome not found"
ls -1d "$HOME/Library/Application Support/BraveSoftware"* 2>/dev/null || echo "Brave not found"
echo ""
echo "⚠️  Bookmarks/passwords should be in browser sync"
echo "⚠️  Check for local-only browser data/extensions"
echo ""

# 5. Fonts
echo "🔤 CUSTOM FONTS"
echo "-------------------------------------------"
FONT_COUNT=$(ls -1 "$HOME/Library/Fonts" 2>/dev/null | wc -l)
echo "User fonts: $FONT_COUNT files"
if [ "$FONT_COUNT" -gt 0 ]; then
    echo "⚠️  ACTION: Copy ~/Library/Fonts to HDD (if not in dotfiles/fonts/)"
    echo "Current fonts:"
    ls -1 "$HOME/Library/Fonts" 2>/dev/null | head -10
    [ "$FONT_COUNT" -gt 10 ] && echo "... and $(($FONT_COUNT - 10)) more"
fi
echo ""

# 6. Documents (should be in iCloud/Time Machine)
echo "📄 DOCUMENTS"
echo "-------------------------------------------"
if [ -d "$HOME/Documents" ]; then
    DOC_SIZE=$(du -sh "$HOME/Documents" 2>/dev/null | awk '{print $1}')
    echo "~/Documents size: $DOC_SIZE"
    echo "⚠️  Verify: iCloud sync complete OR copy to HDD"
fi
echo ""

# 7. Database dumps
echo "💾 DATABASE DUMPS"
echo "-------------------------------------------"
echo "Looking for database dumps..."
find "$HOME" -name "*.sql" -o -name "*.dump" -o -name "*.db" 2>/dev/null | grep -v ".git" | grep -v "node_modules" | head -10
echo ""

# 8. Application licenses/settings
echo "🎫 APPLICATION LICENSES & SETTINGS"
echo "-------------------------------------------"
echo "Check these for license keys or custom settings:"
echo "  - ~/Library/Application Support/"
echo "  - ~/Library/Preferences/"
echo ""
echo "Common apps with local licenses:"
for app in "Sublime Text" "TablePlus" "Transmit" "Xcode"; do
    if [ -d "/Applications/$app.app" ]; then
        echo "  ✓ $app installed (check for license)"
    fi
done
echo ""

# 9. Homebrew installed packages (should be in Brewfile)
echo "🍺 HOMEBREW PACKAGES"
echo "-------------------------------------------"
if command -v brew &> /dev/null; then
    BREW_COUNT=$(brew list --formula | wc -l)
    CASK_COUNT=$(brew list --cask | wc -l)
    echo "Formulas: $BREW_COUNT | Casks: $CASK_COUNT"
    echo "⚠️  Verify: packages/homebrew/Brewfile is up to date"
    echo ""
    echo "Run to update Brewfile:"
    echo "    brew bundle dump --force --file=~/dev/projects/dotfiles/packages/homebrew/Brewfile"
fi
echo ""

# 10. Git repositories status
echo "📊 GIT REPOSITORIES STATUS"
echo "-------------------------------------------"
echo "Checking for uncommitted changes..."
find "$HOME/dev" -name .git -type d 2>/dev/null | while read gitdir; do
    repo_dir=$(dirname "$gitdir")
    cd "$repo_dir"
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "⚠️  UNCOMMITTED: $(basename "$repo_dir")"
    fi
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "⚠️  UNTRACKED: $(basename "$repo_dir")"
    fi
done
echo ""

# 11. Screenshots/system documentation
echo "📸 SCREENSHOTS & DOCUMENTATION"
echo "-------------------------------------------"
if [ -d "$HOME/Desktop" ]; then
    SCREENSHOT_COUNT=$(find "$HOME/Desktop" -name "Screenshot*.png" 2>/dev/null | wc -l)
    echo "Desktop screenshots: $SCREENSHOT_COUNT"
    [ "$SCREENSHOT_COUNT" -gt 0 ] && echo "⚠️  ACTION: Copy important screenshots to HDD"
fi
echo ""

# 12. Local environment files
echo "🔐 ENVIRONMENT FILES"
echo "-------------------------------------------"
echo "Looking for .env files with secrets..."
find "$HOME/dev" -name ".env" -o -name ".env.*" 2>/dev/null | grep -v ".env.example" | grep -v ".env.template" | head -10
echo "⚠️  Verify: All secrets are in 1Password"
echo ""

# 13. Summary
echo "=========================================="
echo "BACKUP SUMMARY"
echo "=========================================="
echo ""
echo "✅ Already backed up:"
echo "   - ~/dev/projects (copied to HDD)"
echo ""
echo "⚠️  MUST backup before format:"
echo "   1. Docker volumes (databases!)"
echo "   2. Any uncommitted git changes"
echo "   3. Custom fonts (if not in dotfiles)"
echo "   4. Obsidian vault (if exists)"
echo "   5. .env files with secrets (verify in 1Password)"
echo ""
echo "✅ Should be safe (already synced):"
echo "   - iCloud Documents"
echo "   - 1Password vault"
echo "   - Git repositories (if pushed)"
echo "   - Browser data (if synced)"
echo ""
echo "📝 RECOMMENDED BACKUP COMMAND:"
echo "   rsync -av --exclude='node_modules' --exclude='.git' \\"
echo "         ~/Library/Fonts \\"
echo "         ~/Documents \\"
echo "         ~/Desktop \\"
echo "         $EXTERNAL_HDD/MacBackup-$(date +%Y%m%d)/"
echo ""
echo "=========================================="
echo "FINAL CHECKLIST"
echo "=========================================="
echo "[ ] Docker volumes backed up"
echo "[ ] All git repos pushed"
echo "[ ] Brewfile updated and committed"
echo "[ ] Dotfiles repo pushed"
echo "[ ] Custom fonts copied"
echo "[ ] Important screenshots saved"
echo "[ ] Verified all secrets in 1Password"
echo "[ ] Verified iCloud sync complete"
echo "[ ] Time Machine backup is recent"
echo ""

} | tee "$BACKUP_LOG"

echo ""
echo "✅ Backup checklist saved to: $BACKUP_LOG"
echo ""
echo "Review the checklist above, then format with confidence!"
