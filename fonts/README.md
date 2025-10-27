# Font Management System

Complete automated font management for macOS across multiple devices (Mac Studio & MacBook).

## Overview

This system manages **179 custom fonts** organized into categories for selective installation:
- **Essential**: Terminal + Professional fonts (10 fonts)
- **Coding**: Monospace fonts for development (16 fonts)
- **Powerline**: Terminal fonts with special glyphs (120+ fonts)
- **Optional**: Complete font families for design work (33 fonts)

## Quick Start

### Install Essential Fonts Only (Recommended for Bootstrap)

```bash
# Install MesloLGS NF + Lato + Raleway (10 fonts, <5 seconds)
make fonts-install-essential

# Or via script
./scripts/fonts/install-fonts.sh --essential-only
```

Essential fonts include:
- **MesloLGS NF** (4 variants) - Required for Powerlevel10k terminal theme
- **Lato** (Regular, Bold, Italic, BoldItalic) - Professional sans-serif
- **Raleway** (Variable font + Italic) - Modern geometric sans-serif

### Install All Fonts

```bash
# Install all 179 fonts (~15 seconds)
make fonts-install

# Or via script
./scripts/fonts/install-fonts.sh --all
```

### Verify Installation

```bash
# Check essential fonts
make fonts-verify

# Run health check (includes font check)
make health
```

## Font Categories

### Essential (10 fonts)

**Terminal:**
- MesloLGS NF Regular.ttf
- MesloLGS NF Bold.ttf
- MesloLGS NF Italic.ttf
- MesloLGS NF Bold Italic.ttf

**Professional:**
- Lato-Regular.ttf
- Lato-Bold.ttf
- Lato-Italic.ttf
- Lato-BoldItalic.ttf
- Raleway-VF.ttf (Variable font)
- Raleway-Italic-VF.ttf (Variable font)

### Coding Fonts (16 fonts)

**Hack** (4 variants) - Clean, crisp monospace
**Space Mono** (4 variants) - Google's monospace for technical work
**IBM 3270** (3 variants) - Classic mainframe terminal aesthetic
**CPMono** (5 variants) - Modern monospace with multiple weights

### Powerline Fonts (120+ fonts)

Terminal fonts with special glyphs for status lines:
- **Meslo variants** (24 fonts) - Different sizes and spacing
- **Source Code Pro** (14 fonts) - Adobe's monospace
- **DejaVu Sans Mono** (4 fonts) - Open-source classic
- **Roboto Mono** (10 fonts) - Google's monospace
- **Terminus** (18 PCF bitmap fonts) - Terminal emulator fonts
- **Other Powerline** (50+ fonts) - Anonymice, Arimo, Cousine, Droid, FuraMono, Go Mono, Inconsolata, Literation, Monofur, Noto, Ubuntu, and more

### Optional Development (14 fonts)

**Lato Complete Family** (10 additional weights):
- Hairline, Thin, Light, Medium, Semibold, Heavy, Black (+ Italics)

**UI Fonts** (6 variable fonts):
- Montserrat, Outfit, Overpass, Rubik

### Optional Design (9 fonts)

**Serif Fonts**:
- Fanwood (4 variants) - Classic serif
- Noto Serif (2 variable fonts) - Google's serif family
- GoudyBookletter1911 - Decorative serif

**Display Fonts**:
- Playlist (3 variants) - Caps + Script

## Installation Options

### Via Makefile (Recommended)

```bash
# Essential only (fast, for bootstrap)
make fonts-install-essential

# Essential + coding fonts
make fonts-install-coding

# Essential + Powerline fonts
make fonts-install-powerline

# All fonts
make fonts-install

# Verify installation
make fonts-verify
```

### Via Script

```bash
# Essential only
./scripts/fonts/install-fonts.sh --essential-only

# With coding fonts
./scripts/fonts/install-fonts.sh --with-coding

# With Powerline fonts
./scripts/fonts/install-fonts.sh --with-powerline

# All fonts
./scripts/fonts/install-fonts.sh --all

# Dry run (preview without installing)
./scripts/fonts/install-fonts.sh --all --dry-run

# Force reinstall
./scripts/fonts/install-fonts.sh --all --force

# Verbose output
./scripts/fonts/install-fonts.sh --all --verbose
```

## How It Works

### Directory Structure

```
fonts/
├── backup/              # 179 font files backed up from system
├── audit/               # Font audit reports
│   ├── current-system-fonts.txt
│   ├── missing-from-backup.txt
│   └── non-powerline-missing.txt
├── fonts.yml            # Font categorization (parsed by yq)
└── README.md            # This file
```

### Installation Process

1. **Parse Configuration** - Load fonts.yml with yq to get font list
2. **Check Existing** - Skip fonts already installed (unless --force)
3. **Copy Fonts** - Copy from `fonts/backup/` to `~/Library/Fonts/`
4. **Clear Cache** - Rebuild macOS font cache with `atsutil databases -remove`
5. **Verify** - Check essential fonts are present
6. **Report** - Show installation statistics

### Bootstrap Integration

Essential fonts are automatically installed during macOS bootstrap:

```bash
# Included in bootstrap
./scripts/bootstrap/macos-bootstrap.sh
```

The bootstrap installs MesloLGS NF (required for Powerlevel10k) plus professional fonts (Lato, Raleway) for document work.

### Health Check Integration

Font installation is verified during health checks:

```bash
# Run health check (includes font verification)
make health

# Or directly
./scripts/health/check-all.sh
```

Health check verifies:
- ✅ All essential fonts present
- ✅ Fonts directory accessible
- ✅ Font cache working
- ⚠️ Optional fonts (warning if missing, not error)

## Adding New Fonts

### 1. Add Font Files

Copy font files to `fonts/backup/`:

```bash
cp ~/Library/Fonts/NewFont-*.ttf fonts/backup/
```

### 2. Update Configuration

Edit `fonts/fonts.yml` and add to appropriate category:

```yaml
optional-development:
  new-font-family:
    - NewFont-Regular.ttf
    - NewFont-Bold.ttf
    - NewFont-Italic.ttf
```

### 3. Install

```bash
# Install all fonts (includes new ones)
make fonts-install
```

## Removing Fonts

### Remove from System

```bash
# Remove specific font
rm ~/Library/Fonts/FontName.ttf

# Clear font cache
atsutil databases -remove
```

### Remove from Dotfiles

1. Delete from `fonts/backup/`
2. Remove from `fonts/fonts.yml`
3. Commit changes

## Troubleshooting

### Fonts Not Appearing

```bash
# Clear font cache manually
atsutil databases -remove

# Restart Font Book
killall "Font Book"

# Verify fonts are in place
ls -la ~/Library/Fonts/ | grep MesloLGS
```

### Installation Fails

```bash
# Check prerequisites
make health

# Verify yq is installed
which yq
brew install yq

# Run with verbose output
./scripts/fonts/install-fonts.sh --all --verbose
```

### Permission Issues

```bash
# Ensure fonts directory is writable
ls -ld ~/Library/Fonts
chmod 755 ~/Library/Fonts

# Reinstall with force
make fonts-install FORCE=true
```

## Technical Details

### Font Formats Supported

- **TrueType** (.ttf) - Most common format
- **OpenType** (.otf) - Adobe/Microsoft format
- **PCF** (.pcf.gz) - Bitmap fonts (Terminus)
- **Variable Fonts** - Single file with multiple styles (Raleway, Montserrat, etc.)

### macOS Font Locations

- **User Fonts**: `~/Library/Fonts/` (used by this system, no sudo required)
- **System Fonts**: `/Library/Fonts/` (requires sudo, not modified)
- **macOS Fonts**: `/System/Library/Fonts/` (system fonts, never modified)

### Font Cache Management

macOS caches font data for performance. After installing fonts:

```bash
# Clear cache (automatic in install script)
atsutil databases -remove

# Verify cache rebuild
atsutil databases -verify

# Check font recognition (may take a few seconds)
system_profiler SPFontsDataType | grep MesloLGS
```

### Performance Characteristics

- **Essential fonts**: <5 seconds (10 fonts)
- **With coding**: <8 seconds (26 fonts)
- **With Powerline**: <12 seconds (130+ fonts)
- **All fonts**: <15 seconds (179 fonts)

Time includes font copy + cache rebuild. Skipping cache (--skip-cache) reduces time but fonts won't appear immediately.

## Cross-Device Sync

Fonts are synced across devices via Git:

```bash
# On MacBook (source)
cp ~/Library/Fonts/*.ttf fonts/backup/
git add fonts/backup/
git commit -m "feat: add new fonts"
git push

# On Mac Studio (target)
git pull
make fonts-install
```

## Integration Points

### Powerlevel10k Theme

MesloLGS NF is required for Powerlevel10k theme:

```bash
# Installed automatically during bootstrap
./scripts/bootstrap/macos-bootstrap.sh
```

Configure in `~/.p10k.zsh`:
```zsh
typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
```

### VS Code

Configure terminal font in VS Code settings:

```json
{
  "terminal.integrated.fontFamily": "MesloLGS NF",
  "editor.fontFamily": "Hack, 'Space Mono', Menlo, Monaco, 'Courier New', monospace"
}
```

### iTerm2

Configure in iTerm2 preferences:
- Preferences → Profiles → Text
- Font: MesloLGS NF (13pt)
- Use ligatures: Yes (if supported)

## Related Documentation

- [TECH-STACK.md](../docs/TECH-STACK.md) - Complete technology stack
- [macos-bootstrap.sh](../scripts/bootstrap/macos-bootstrap.sh) - Bootstrap integration
- [check-all.sh](../scripts/health/check-all.sh) - Health check integration
- [Makefile](../Makefile) - All available commands

## Font License Information

All fonts in this collection are either:
- **Open Source** (OFL, Apache, MIT licenses) - Most fonts
- **Free for Personal Use** - Some display fonts
- **System Fonts** - Included with macOS or development tools

Fonts are for personal development use. Check individual font licenses for commercial use.

### Notable Font Sources

- **MesloLGS NF**: [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Powerline Fonts**: [powerline/fonts](https://github.com/powerline/fonts)
- **Hack**: [source-foundry/Hack](https://github.com/source-foundry/Hack)
- **Lato**: [Google Fonts](https://fonts.google.com/specimen/Lato)
- **Raleway**: [Google Fonts](https://fonts.google.com/specimen/Raleway)
- **Source Code Pro**: [Adobe Fonts](https://adobe-fonts.github.io/source-code-pro/)
- **Space Mono**: [Google Fonts](https://fonts.google.com/specimen/Space+Mono)

## FAQ

**Q: Why not use Homebrew casks for fonts?**
A: We need exact versions for consistency across devices. Brew cask fonts can update independently. Direct file management ensures identical fonts everywhere.

**Q: Can I use this on Linux?**
A: Currently macOS only. Linux support planned for FASE 3 (fonts go to `~/.local/share/fonts/`, use `fc-cache -f` instead of atsutil).

**Q: Why so many Powerline variants?**
A: Different terminal emulators and use cases benefit from different fonts. The collection provides maximum flexibility.

**Q: Do I need all fonts?**
A: No! Use `--essential-only` for most cases. Additional fonts are available if needed for specific projects.

**Q: How do I update fonts?**
A: Font files rarely change. If needed, replace files in `fonts/backup/` and run `make fonts-install --force`.

**Q: Can I use different professional fonts?**
A: Yes! Add your preferred fonts to `fonts/backup/`, update `fonts/fonts.yml` under `essential.professional`, and reinstall.

---

**Last Updated**: 2025-01-27
**Total Fonts**: 179
**Essential Fonts**: 10
**Maintained By**: Matteo Cervelli
