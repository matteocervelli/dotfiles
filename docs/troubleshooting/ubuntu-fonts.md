# Ubuntu Font Troubleshooting

## Problem: Meslo Fonts Not Working in Oh My Zsh Powerlevel10k

### Symptoms
- Terminal shows broken icons/symbols (�, boxes, or missing characters)
- Powerlevel10k theme doesn't render correctly
- Fonts work on macOS/Fedora but not Ubuntu

### Root Cause
Ubuntu uses a different font installation directory than macOS:
- **macOS**: `~/Library/Fonts/`
- **Ubuntu**: `~/.local/share/fonts/`

The general font installation script may not properly install or cache fonts on Ubuntu systems.

### Quick Fix

Run the Ubuntu-specific font fix script:

```bash
# From dotfiles directory
./scripts/fonts/fix-ubuntu-fonts.sh

# With terminal auto-configuration
./scripts/fonts/fix-ubuntu-fonts.sh --configure-terminal

# Preview what would be done
./scripts/fonts/fix-ubuntu-fonts.sh --dry-run --verbose
```

Then **close and reopen your terminal** (or logout/login).

### What the Script Does

1. **Installs MesloLGS NF fonts** to `~/.local/share/fonts/`
   - MesloLGS NF Regular.ttf
   - MesloLGS NF Bold.ttf
   - MesloLGS NF Italic.ttf
   - MesloLGS NF Bold Italic.ttf

2. **Rebuilds font cache** using `fc-cache -f`

3. **Verifies installation** by checking:
   - Font files exist in target directory
   - Fonts appear in system font cache

4. **Optionally configures GNOME Terminal** (with `--configure-terminal`):
   - Disables "Use system font"
   - Sets font to "MesloLGS NF Regular 11"

### Manual Installation

If the script doesn't work, install fonts manually:

```bash
# 1. Create fonts directory
mkdir -p ~/.local/share/fonts

# 2. Copy MesloLGS NF fonts from backup
cd ~/dev/projects/dotfiles
cp fonts/backup/MesloLGS*.ttf ~/.local/share/fonts/

# 3. Rebuild font cache
fc-cache -f -v ~/.local/share/fonts

# 4. Verify fonts are available
fc-list | grep "MesloLGS NF"
```

Expected output:
```
~/.local/share/fonts/MesloLGS NF Regular.ttf: MesloLGS NF:style=Regular
~/.local/share/fonts/MesloLGS NF Bold.ttf: MesloLGS NF:style=Bold
~/.local/share/fonts/MesloLGS NF Italic.ttf: MesloLGS NF:style=Italic
~/.local/share/fonts/MesloLGS NF Bold Italic.ttf: MesloLGS NF:style=Bold Italic
```

### Manual Terminal Configuration

#### GNOME Terminal

1. Open Terminal → **Preferences**
2. Select your profile (usually "Unnamed")
3. Go to **Text** tab
4. **Uncheck** "Use the system fixed width font"
5. Click **font selector**, choose:
   - Font: **MesloLGS NF Regular**
   - Size: **11** (or your preference)
6. Close preferences

#### Other Terminals

**Terminator:**
```bash
# Edit ~/.config/terminator/config
[profiles]
  [[default]]
    font = MesloLGS NF Regular 11
    use_system_font = False
```

**Tilix:**
```bash
# Settings → Profiles → Default → Text
# Uncheck "Use system font"
# Select: MesloLGS NF Regular 11
```

**Alacritty:**
```yaml
# ~/.config/alacritty/alacritty.yml
font:
  normal:
    family: MesloLGS NF
    style: Regular
  size: 11.0
```

### Verification

Test font rendering with special characters:

```bash
echo '\ue0b0 \u00b1 \ue0a0 \u27a6 \u2718 \u26a1 \u2699'
```

You should see: ` ± ➦ ✘ ⚡ ⚙` (with a special triangle at the start)

If you see boxes or question marks, the font isn't loaded correctly.

### Powerlevel10k Reconfiguration

After fixing fonts, reconfigure Powerlevel10k:

```bash
p10k configure
```

This will:
1. Detect the new font
2. Enable proper icon rendering
3. Let you choose your preferred prompt style

### Still Not Working?

1. **Log out and log back in** (not just close terminal)
   - This ensures font cache is fully reloaded

2. **Check font file permissions**:
   ```bash
   ls -la ~/.local/share/fonts/MesloLGS*
   ```
   Should show `-rw-r--r--` (readable by all)

3. **Rebuild font cache system-wide** (requires sudo):
   ```bash
   sudo fc-cache -f -v
   ```

4. **Check for font conflicts**:
   ```bash
   fc-match monospace
   ```
   Should prefer MesloLGS NF if set in terminal

5. **Verify fontconfig is installed**:
   ```bash
   sudo apt install fontconfig
   ```

6. **Check terminal environment**:
   ```bash
   echo $TERM
   # Should be: xterm-256color or similar
   ```

### Common Issues

#### Issue: "Font exists but icons still broken"

**Solution**: Terminal emulator not using the font
- Check terminal preferences
- Some terminals cache font settings - restart required

#### Issue: "fc-cache command not found"

**Solution**: Install fontconfig
```bash
sudo apt install fontconfig
```

#### Issue: "Fonts work in new terminal but not existing sessions"

**Solution**: Font cache loaded at session start
- Close all terminals
- Logout and login
- Or restart your system

#### Issue: "Only some icons work"

**Solution**: Using wrong MesloLGS variant
- Must use **MesloLGS NF** (Nerd Font version)
- Not "Meslo LG", "Meslo for Powerline", etc.
- These are different fonts with different glyphs

### Platform Differences

| Platform | Font Directory | Cache Command |
|----------|----------------|---------------|
| **macOS** | `~/Library/Fonts/` | `atsutil databases -remove` |
| **Ubuntu** | `~/.local/share/fonts/` | `fc-cache -f` |
| **Fedora** | `~/.local/share/fonts/` | `fc-cache -f` |

### Related Files

- Font installation script: [`scripts/fonts/install-fonts.sh`](../../scripts/fonts/install-fonts.sh)
- Ubuntu fix script: [`scripts/fonts/fix-ubuntu-fonts.sh`](../../scripts/fonts/fix-ubuntu-fonts.sh)
- Font backup: [`fonts/backup/`](../../fonts/backup/)
- Font configuration: [`fonts/fonts.yml`](../../fonts/fonts.yml)

### Further Reading

- [Powerlevel10k Font Documentation](https://github.com/romkatv/powerlevel10k#fonts)
- [Nerd Fonts](https://www.nerdfonts.com/)
- [Linux Font Configuration](https://www.freedesktop.org/wiki/Software/fontconfig/)
