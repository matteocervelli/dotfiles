# Application Management

This directory contains application management files for auditing and cleaning up macOS applications.

## Workflow

### 1. Run Application Audit

First, run the audit script to discover all installed applications:

```bash
./scripts/apps/audit-apps.sh
```

This will generate `current_macos_apps_YYYY-MM-DD.txt` with a categorized list of all applications:
- **Homebrew Casks**: GUI apps installed via `brew install --cask`
- **Homebrew Formulae**: CLI tools installed via `brew install`
- **Mac App Store**: Apps installed via Mac App Store
- **Setapp Apps**: Apps from Setapp subscription service
- **Manual Installations**: Apps in `/Applications` not managed by Homebrew, MAS, or Setapp

### 2. Manual Review

Review the generated audit file and manually categorize applications:

**Create two lists**:

1. **keep-apps.txt** - Applications you want to keep
   - Add one app name per line
   - Match exact names from the audit report
   - These apps will NOT be removed

2. **remove-apps.txt** - Applications you want to remove
   - Add one app name per line
   - Match exact names from the audit report
   - These apps will be uninstalled by the cleanup script

### 3. Test Cleanup (Dry-Run)

Always test first with dry-run mode (default):

```bash
./scripts/apps/cleanup-apps.sh
```

This will:
- ✅ Show what would be removed
- ✅ Display removal method (Homebrew vs manual)
- ❌ NOT actually delete anything

### 4. Execute Cleanup

When you're confident, run the actual cleanup:

```bash
./scripts/apps/cleanup-apps.sh --execute
```

This will:
- ✅ Remove apps listed in `remove-apps.txt`
- ✅ Use `brew uninstall --cask` for Homebrew apps
- ✅ Use `rm -rf` for manually installed apps
- ✅ Require user confirmation before proceeding
- ✅ Log all operations

## File Descriptions

| File | Description | Auto-Generated |
|------|-------------|----------------|
| `current-apps.txt` | Complete list of installed applications | ✅ Yes |
| `keep-apps.txt` | Apps to preserve (user-curated) | ❌ No |
| `remove-apps.txt` | Apps to remove (user-curated) | ❌ No |
| `vscode-extensions.txt` | VSCode extensions list with install commands | ✅ Yes |
| `README.md` | This file | ❌ No |

## Example Files

### Example: current-apps.txt

```
=== Homebrew Casks (15) ===
1password-cli
docker
google-chrome
visual-studio-code
...

=== Mac App Store Apps (8) ===
1Password (1333542190)
Slack (803453959)
Xcode (497799835)
...

=== Manual Installations (12) ===
Adobe Photoshop
Claude
Figma
...
```

### Example: keep-apps.txt

```
# Applications to Keep
# One app name per line, matching names from current-apps.txt

1password-cli
docker
visual-studio-code
1Password
Xcode
Claude
Figma
```

### Example: remove-apps.txt

```
# Applications to Remove
# One app name per line, matching names from current-apps.txt

google-chrome
ungoogled-chromium
microsoft-edge
firefox
libreoffice
```

## Tips

### Finding App Names

- **Homebrew**: Run `brew list --cask` to see exact cask names
- **MAS**: Run `mas list` to see app names and IDs
- **Manual**: Look in `/Applications` directory

### Handling Spaces

App names with spaces are supported. Examples:
- `Google Chrome` (spaces work fine)
- `Visual Studio Code`
- `1Password`

### Comments

You can add comments in keep-apps.txt and remove-apps.txt:

```
# Development Tools
visual-studio-code
docker

# Communication
# slack  <-- commented out, will NOT be processed
```

Lines starting with `#` are ignored.

### Safety Features

The cleanup script has multiple safety features:

1. **Dry-run by default** - Preview changes without executing
2. **Explicit execution** - Requires `--execute` flag for real deletions
3. **User confirmation** - Interactive prompt before removal
4. **App validation** - Checks if app exists before attempting removal
5. **Smart detection** - Identifies Homebrew vs manual apps
6. **Detailed logging** - Records all operations

### Rollback

**Important**: Deleted applications cannot be automatically restored.

- **Homebrew apps**: Can be reinstalled with `brew install --cask <name>`
- **MAS apps**: Can be reinstalled from Mac App Store
- **Manual apps**: Must be re-downloaded from original source
- **Time Machine**: Restore from backup if available

## Troubleshooting

### App won't uninstall via Homebrew

If an app was originally installed via Homebrew but won't uninstall:

```bash
# Try forcing uninstall
brew uninstall --cask --force <app-name>

# Or remove manually
rm -rf "/Applications/<AppName>.app"
```

### App name doesn't match

If the script can't find an app:

1. Check exact spelling in `current-apps.txt`
2. Case sensitivity matters: `Xcode` ≠ `xcode`
3. Use exact names including version numbers if present

### Permission denied

If you get permission errors:

```bash
# Make scripts executable
chmod +x scripts/apps/audit-apps.sh
chmod +x scripts/apps/cleanup-apps.sh

# Some apps may require sudo (not recommended)
# Better: Manually remove via Finder (drag to Trash)
```

### Audit missing apps

If audit doesn't show all apps:

1. **Homebrew**: Ensure `brew` is in PATH
2. **MAS**: Ensure `mas` is installed (`brew install mas`)
3. **Manual**: Check if apps are in `/Applications` (not `~/Applications`)

## Best Practices

1. **Always run audit first** - Get current state before making changes
2. **Use dry-run** - Test cleanup before executing
3. **Keep backups** - Use Time Machine or manual backups
4. **Review carefully** - Double-check remove-apps.txt before execution
5. **Document decisions** - Add comments explaining why you removed certain apps
6. **Iterative cleanup** - Remove a few apps at a time, test, repeat
7. **Update Brewfile** - Keep `system/macos/Brewfile` in sync with kept apps

## Brewfile Management

After running the audit, you can generate a Brewfile to manage Homebrew packages declaratively:

```bash
# Generate Brewfile from audit data
make brewfile-generate

# Validate what's installed
make brewfile-check

# Install packages from Brewfile
make brewfile-install

# Update Brewfile from current system
make brewfile-update
```

The Brewfile is located at [`system/macos/Brewfile`](../system/macos/Brewfile) and contains all:
- **Formulae**: CLI tools (`brew "git"`, `brew "node"`, etc.)
- **Casks**: GUI applications (`cask "visual-studio-code"`, etc.)
- **Taps**: Third-party repositories
- **Mac App Store**: Apps via mas-cli

See [system/macos/README.md](../system/macos/README.md) for complete Brewfile documentation.

## VSCode Extensions Management

Manage VSCode extensions separately from applications:

### Export Current Extensions

```bash
# Using Makefile (recommended)
make vscode-extensions-export

# Or manually
code --list-extensions | sort > applications/vscode-extensions.txt
```

### Install All Extensions

```bash
# Using Makefile (recommended)
make vscode-extensions-install

# Or manually
cat applications/vscode-extensions.txt | grep -v '^#' | xargs -L 1 code --install-extension
```

The Makefile targets provide:
- ✅ VSCode CLI detection and installation instructions
- ✅ Automatic backup of existing extensions list
- ✅ Progress tracking (skipped/installed/failed)
- ✅ Proper error handling

### Backup Extensions

The `vscode-extensions.txt` file contains 92+ extensions and serves as:
- **Backup** for reinstalling VSCode
- **Sync** across multiple machines
- **Documentation** of your development environment

## Integration with Dotfiles

After cleanup, ensure consistency:

```bash
# 1. Run audit
./scripts/apps/audit-apps.sh

# 2. Clean up unwanted apps
./scripts/apps/cleanup-apps.sh --execute

# 3. Update Brewfile
make brewfile-update

# 4. Commit changes
git add system/macos/Brewfile applications/
git commit -m "chore: update package manifests after cleanup"
```

This ensures future installations only include apps you want to keep.

## Related Scripts

- [scripts/apps/audit-apps.sh](../scripts/apps/audit-apps.sh) - Application discovery
- [scripts/apps/cleanup-apps.sh](../scripts/apps/cleanup-apps.sh) - Application removal
- [scripts/apps/generate-brewfile.sh](../scripts/apps/generate-brewfile.sh) - Brewfile generation
- [system/macos/Brewfile](../system/macos/Brewfile) - Homebrew package manifest
- [system/macos/README.md](../system/macos/README.md) - Brewfile documentation

## References

- [Homebrew Cask Documentation](https://github.com/Homebrew/homebrew-cask/blob/master/USAGE.md)
- [mas-cli Documentation](https://github.com/mas-cli/mas)

---

**Created**: 2025-01-25
**Last Updated**: 2025-10-25
**Part of**:
- FASE 3.1 - Application Audit & Cleanup ([Issue #19](https://github.com/matteocervelli/dotfiles/issues/19))
- FASE 3.2 - Brewfile & App Management ([Issue #20](https://github.com/matteocervelli/dotfiles/issues/20))
