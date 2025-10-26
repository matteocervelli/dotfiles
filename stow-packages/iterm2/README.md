# iTerm2 Stow Package

Backup and restore workflow for iTerm2 preferences on macOS.

## Overview

iTerm2 stores its preferences in a binary plist file at `~/Library/Preferences/com.googlecode.iterm2.plist`, which is unsuitable for version control. This package provides scripts to export preferences to human-readable formats (XML/JSON) for versioning, and restore them on new machines.

## Why Not XDG Compliance?

iTerm2 cannot be made XDG-compliant because:
- Preferences stored in macOS-specific binary plist format
- Custom location preference must be stored in default location (chicken-and-egg problem)
- Partial XDG support (`~/.config/iterm2/`) creates split configuration
- Export/import workflow more reliable than symlink hacks

See: [docs/xdg-compliance.md](../../docs/xdg-compliance.md#iterm2)

## What's Included

```
iterm2/
├── .local/
│   └── bin/
│       ├── iterm2-backup     # Export preferences to XML/JSON
│       └── iterm2-restore    # Import preferences from backup
├── backups/
│   └── .gitkeep              # Backup files stored here (gitignored)
├── .gitignore
├── .stow-local-ignore
└── README.md (this file)
```

## Installation

### 1. Deploy Package

```bash
cd /path/to/dotfiles
stow -t ~ iterm2
```

This creates:
- `~/.local/bin/iterm2-backup` → symlink to this package
- `~/.local/bin/iterm2-restore` → symlink to this package

### 2. Verify Installation

```bash
which iterm2-backup
# Should show: ~/.local/bin/iterm2-backup

iterm2-backup --help
iterm2-restore --help
```

Note: Ensure `~/.local/bin` is in your `$PATH`. The `bin` stow package should handle this.

## Usage

### Backing Up Preferences

Export current iTerm2 preferences:

```bash
# Default: Export to XML
iterm2-backup

# Export to JSON
iterm2-backup --format json

# Custom output location
iterm2-backup --output ~/my-iterm-prefs.xml
```

Output location: `stow-packages/iterm2/backups/iterm2-preferences-TIMESTAMP.{xml,json}`

A `iterm2-preferences-latest.{format}` symlink is created pointing to the most recent backup.

### Restoring Preferences

Import preferences from backup:

```bash
# Restore from latest backup
iterm2-restore

# Restore from specific file
iterm2-restore --input backups/iterm2-preferences-20251026-143022.xml

# Restore without creating safety backup
iterm2-restore --input myprefs.json --no-backup
```

**Safety Features:**
- Creates a safety backup of current preferences before restore (unless `--no-backup`)
- Warns if iTerm2 is currently running
- Reloads preferences if iTerm2 is running (sends SIGHUP)

**Post-Restore:**
- You may need to fully restart iTerm2 for all changes to take effect
- Some settings (window positions, session state) are not preserved

## Workflow

### On Primary Machine (Mac Studio)

1. Configure iTerm2 to your liking
2. Create backup:
   ```bash
   iterm2-backup
   ```
3. Commit backup to git:
   ```bash
   cd /path/to/dotfiles
   git add stow-packages/iterm2/backups/iterm2-preferences-latest.xml
   git commit -m "feat: update iTerm2 preferences"
   git push
   ```

### On New Machine (MacBook)

1. Clone dotfiles repo
2. Deploy iterm2 package:
   ```bash
   cd /path/to/dotfiles
   stow -t ~ iterm2
   ```
3. Restore preferences:
   ```bash
   iterm2-restore
   ```
4. Restart iTerm2

### Updating Preferences

When you make changes to iTerm2 configuration:

```bash
# 1. Create new backup
iterm2-backup

# 2. Review changes
cd /path/to/dotfiles/stow-packages/iterm2/backups
git diff iterm2-preferences-latest.xml

# 3. Commit if satisfied
git add iterm2-preferences-latest.xml
git commit -m "chore: update iTerm2 color scheme"
git push
```

## Backup File Formats

### XML (Default)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SomePreference</key>
    <string>value</string>
    ...
</dict>
</plist>
```

**Pros:**
- Human-readable
- Good diff-ability for version control
- Widely supported

**Cons:**
- Verbose
- Larger file size

### JSON (Optional)

```json
{
  "SomePreference": "value",
  ...
}
```

**Pros:**
- More compact than XML
- Still human-readable
- Good for scripting

**Cons:**
- Requires macOS 10.13+ (`plutil -convert json`)
- Less standard for macOS plists

**Recommendation**: Use XML for maximum compatibility.

## Included Preferences

iTerm2 preferences include:

- **Profiles**: Color schemes, fonts, keyboard shortcuts
- **General Settings**: Window behavior, tab bar configuration
- **Key Bindings**: Custom keyboard shortcuts
- **Advanced Settings**: All iTerm2 advanced preferences

**NOT Included:**
- Window positions and sizes (session state)
- Command history (separate from shell history)
- Temporary session data

## Version Control Best Practices

### What to Commit

✅ Commit:
- `iterm2-preferences-latest.xml` (or `.json`)
- Major preference snapshots with descriptive names

❌ Don't Commit:
- Timestamped backups (gitignored)
- Safety backups (gitignored)

### Commit Message Examples

```bash
# Initial setup
git commit -m "feat: add iTerm2 Solarized Dark profile"

# Updates
git commit -m "chore: update iTerm2 keyboard shortcuts"
git commit -m "style: change iTerm2 font to JetBrains Mono"

# Sync from another machine
git commit -m "sync: merge iTerm2 preferences from MacBook"
```

## Troubleshooting

### Script not found

**Symptoms**: `bash: iterm2-backup: command not found`

**Solutions:**
1. Verify stow package deployed: `ls -la ~/.local/bin/iterm2-backup`
2. Check `$PATH`: `echo $PATH | grep -o ~/.local/bin`
3. Add to `$PATH` if missing: `export PATH="$HOME/.local/bin:$PATH"`
4. Redeploy: `cd /path/to/dotfiles && stow -t ~ iterm2`

### Preferences not restored

**Symptoms**: iTerm2 doesn't reflect restored preferences

**Solutions:**
1. Fully quit iTerm2: ⌘Q (not just closing window)
2. Relaunch iTerm2
3. Check for errors in restore output
4. Verify backup file is valid:
   ```bash
   plutil -lint backups/iterm2-preferences-latest.xml
   ```

### Permission denied

**Symptoms**: Cannot write to plist file

**Solutions:**
1. Check file permissions:
   ```bash
   ls -la ~/Library/Preferences/com.googlecode.iterm2.plist
   ```
2. Fix ownership if needed:
   ```bash
   sudo chown $USER ~/Library/Preferences/com.googlecode.iterm2.plist
   ```

### Binary plist error

**Symptoms**: Error converting to/from binary plist

**Solutions:**
1. Verify plist format:
   ```bash
   file ~/Library/Preferences/com.googlecode.iterm2.plist
   ```
2. Convert manually if corrupted:
   ```bash
   plutil -convert xml1 ~/Library/Preferences/com.googlecode.iterm2.plist
   ```
3. Delete and let iTerm2 recreate: Backup first!

## Platform Support

- ✅ macOS only (iTerm2 is macOS-specific)
- ❌ Linux (not applicable)
- ❌ Windows (not applicable)

For cross-platform terminal configuration, consider:
- **Alacritty**: XDG-compliant, cross-platform
- **WezTerm**: Cross-platform, Lua configuration

## Alternative: Dynamic Preferences

iTerm2 supports loading preferences from a custom location:

**Preferences → General → Preferences → Load preferences from a custom folder**

**Downsides:**
- The custom location setting itself is stored in the default location
- Creates split configuration (some prefs in custom location, some in default)
- Can cause sync conflicts

**Our approach (backup/restore) is simpler and more reliable.**

## Documentation

- [iTerm2 Documentation](https://iterm2.com/documentation.html)
- [iTerm2 Preferences](https://iterm2.com/documentation-preferences.html)
- [XDG Compliance Strategy](../../docs/xdg-compliance.md)

## Version

- **Created**: 2025-10-26
- **Status**: Active
- **Part of**: FASE 3.4 - XDG Compliance Implementation
- **Platform**: macOS only
