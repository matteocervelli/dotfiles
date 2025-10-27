# macOS Services & Automator Workflows

This directory contains macOS Services (Automator workflows) for system-wide context menu integration and automation.

## Contents

- **Active Workflows (6)** - Currently maintained and installed workflows
- **Archived Workflows (2)** - Deprecated workflows kept for reference
- **services.yml** - Workflow metadata and configuration

## What are macOS Services?

macOS Services are system-wide actions accessible from the **Services** submenu in any application's context menu (right-click) or the application menu. They're implemented as Automator workflows stored in `~/Library/Services/`.

### Benefits

- **Universal Access**: Available in Finder, text editors, browsers, and all macOS apps
- **Quick Actions**: One-click access to common file operations
- **Custom Automation**: Tailored workflows for your specific needs
- **No App Switching**: Perform actions without leaving your current app

## Active Workflows Inventory

### Conversion Tools (3 workflows)

#### 1. File to MD.workflow
**Purpose**: Convert any file to Markdown format

**Usage**:
- Right-click file → Services → File to MD
- Creates `.md` version with formatted content

**Use Cases**:
- Convert plain text to Markdown
- Extract content from various formats
- Prepare files for documentation

**Dependencies**: None

---

#### 2. File to TXT.workflow
**Purpose**: Convert any file to plain text format

**Usage**:
- Right-click file → Services → File to TXT
- Creates `.txt` version with stripped formatting

**Use Cases**:
- Remove formatting from rich text
- Extract text from documents
- Create clean text versions

**Dependencies**: None

---

#### 3. MD to Rich Text.workflow
**Purpose**: Convert Markdown to rich text for pasting

**Usage**:
- Right-click `.md` file → Services → MD to Rich Text
- Renders Markdown with formatting
- Output ready for pasting into rich text editors

**Use Cases**:
- Preview Markdown formatting
- Paste formatted text into Pages, Keynote, etc.
- Convert Markdown for emails

**Dependencies**: None
**Essential**: No (optional enhancement)

---

### Development Tools (2 workflows)

#### 4. open-in-vscode.workflow
**Purpose**: Open files or folders in Visual Studio Code from Finder

**Usage**:
- Right-click file/folder → Services → open-in-vscode
- Opens in VS Code immediately

**Use Cases**:
- Quick code editing from Finder
- Open project folders without dragging
- Fast workflow for development

**Dependencies**:
- Visual Studio Code.app must be installed
- Located in `/Applications/Visual Studio Code.app`

**Essential**: Yes (primary code editor)

---

#### 5. Open in Cursor.workflow
**Purpose**: Open files or folders in Cursor AI editor from Finder

**Usage**:
- Right-click file/folder → Services → Open in Cursor
- Opens in Cursor immediately

**Use Cases**:
- AI-assisted code editing
- Open projects in Cursor IDE
- Alternative to VS Code with AI features

**Dependencies**:
- Cursor.app must be installed
- Located in `/Applications/Cursor.app`

**Essential**: No (alternative editor)

---

### CDN & Asset Tools (1 workflow)

#### 6. Retrieve CDN url.workflow ⭐
**Purpose**: Get CDN URL from asset management system (project-specific)

**Usage**:
- Right-click image/asset → Services → Retrieve CDN url
- Retrieves CDN URL and copies to clipboard

**Use Cases**:
- Quick CDN URL lookup for projects
- Asset management integration
- Development workflow optimization

**Dependencies**:
- Asset management system configured
- Project-specific integration

**Essential**: No (project-specific)
**Note**: Custom workflow for Ad Limen S.r.l. infrastructure

---

## Archived Workflows

Located in `archived/` directory - kept for reference but no longer actively used.

### Send to Kindle.workflow
**Archived**: 2025-10-27
**Reason**: Kindle service discontinued
**Original Purpose**: Send documents to Kindle device via email

### Servizio Things.workflow
**Archived**: 2025-10-27
**Reason**: Things 3 integration deprecated
**Original Purpose**: Create Things 3 tasks from selected text

---

## Quick Start

### Installation

```bash
# Install only essential workflows (conversion + open-in-vscode)
make services-install-essential

# Install all workflows
make services-install

# Preview what would be installed
./scripts/services/install-services.sh --dry-run

# Force reinstall (overwrite existing)
make services-install FORCE=--force
```

### Verification

```bash
# Check installed workflows
make services-verify

# List workflows in ~/Library/Services/
ls -la ~/Library/Services/

# Test in Finder: Right-click any file → Services menu
```

### Backup

```bash
# Backup current workflows from ~/Library/Services/
make services-backup
```

---

## Installation Methods

### Method 1: Bootstrap (Automatic)

During fresh Mac setup, services are installed automatically:

```bash
./scripts/bootstrap/macos-bootstrap.sh
# Installs essential workflows (4): File to MD, File to TXT, MD to Rich Text, open-in-vscode
```

### Method 2: Makefile (Recommended)

```bash
# Essential workflows only (fast, 4 workflows)
make services-install-essential

# All workflows (6 workflows)
make services-install

# Verify installation
make services-verify

# Backup from system
make services-backup
```

### Method 3: Direct Script

```bash
# Essential mode
./scripts/services/install-services.sh --essential-only

# All workflows
./scripts/services/install-services.sh --all

# With options
./scripts/services/install-services.sh --all --force --verbose

# Dry-run preview
./scripts/services/install-services.sh --dry-run
```

---

## Installation Modes

### Essential Mode (Default for Bootstrap)
Installs 4 critical workflows:
- File to MD.workflow
- File to TXT.workflow
- MD to Rich Text.workflow
- open-in-vscode.workflow

**Use when**: Fresh Mac setup, minimal installation, essential tools only

### All Mode
Installs all 6 active workflows (essential + optional)

**Use when**: Full development setup, using Cursor editor, CDN integration needed

---

## Common Workflows

### Fresh macOS Setup

```bash
# 1. Clone dotfiles
git clone https://github.com/matteocervelli/dotfiles.git ~/dev/dotfiles
cd ~/dev/dotfiles

# 2. Bootstrap (includes essential services)
make bootstrap

# 3. Verify Services menu
# Open Finder → Right-click any file → Services menu should show workflows
```

### Add New Workflow

```bash
# 1. Create workflow in Automator.app
# File → New → Quick Action

# 2. Save to ~/Library/Services/My Workflow.workflow

# 3. Test in Finder (may need to restart Finder)
killall Finder

# 4. Backup to dotfiles
make services-backup

# 5. Update services.yml with metadata
vim system/macos/services/services.yml

# 6. Commit changes
git add system/macos/services/
git commit -m "feat: add My Workflow service"
```

### Sync Between Machines

```bash
# On Machine A: Update backup
make services-backup
git add system/macos/services/
git commit -m "chore: update services backup"
git push

# On Machine B: Pull and install
git pull
make services-install
```

### Remove Workflow

```bash
# Method 1: System Preferences
# System Settings → Keyboard → Keyboard Shortcuts → Services
# Uncheck the workflow or delete from ~/Library/Services/

# Method 2: Manual deletion
rm -rf ~/Library/Services/"Workflow Name.workflow"

# Rebuild Services cache
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
```

---

## Troubleshooting

### Services Not Appearing in Menu

**Problem**: Workflows installed but not visible in Services menu

**Solutions**:

1. **Rebuild Services cache**:
```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
```

2. **Restart Finder**:
```bash
killall Finder
```

3. **Check System Preferences**:
   - System Settings → Keyboard → Keyboard Shortcuts → Services
   - Ensure workflows are enabled (checked)

4. **Verify file permissions**:
```bash
chmod -R 755 ~/Library/Services/*.workflow
```

---

### Workflow Has Quarantine Flag

**Problem**: "App is damaged and can't be opened" or workflow won't run

**Cause**: macOS quarantine attribute on downloaded/copied files

**Solution**:
```bash
# Remove quarantine from all workflows
xattr -dr com.apple.quarantine ~/Library/Services/*.workflow

# Or use installation script (removes quarantine automatically)
make services-install --force
```

---

### Workflow Requires Missing Application

**Problem**: "Application not found" error when running workflow

**Solution**:

1. **Check dependencies** in services.yml or this README
2. **Install required application**:
   - open-in-vscode.workflow requires VS Code
   - Open in Cursor.workflow requires Cursor
3. **Verify application path** matches workflow configuration

**Fix application path in workflow**:
1. Open workflow in Automator.app
2. Update "Run Shell Script" action with correct path
3. Save workflow

---

### Services Menu Too Cluttered

**Problem**: Too many services, hard to find yours

**Solution**:

1. **Disable unused services**:
   - System Settings → Keyboard → Keyboard Shortcuts → Services
   - Uncheck services you don't use

2. **Organize with dividers**:
   - Workflows are sorted alphabetically
   - Use prefixes for grouping (e.g., "File to MD", "File to TXT")

3. **Install only essential**:
```bash
# Use essential mode to limit workflows
make services-install-essential
```

---

### Workflow Runs But Does Nothing

**Problem**: Service appears in menu but doesn't work

**Debug steps**:

1. **Open workflow in Automator**:
```bash
open ~/Library/Services/"Workflow Name.workflow"
```

2. **Run workflow manually** in Automator with test input

3. **Check Console.app** for error messages:
   - Open Console.app
   - Search for "Automator" or workflow name
   - Look for errors during workflow execution

4. **Verify input type**:
   - Check Info.plist for accepted input types
   - Ensure you're using workflow with compatible file types

---

### Services Cache Not Refreshing

**Problem**: Changes to workflows not taking effect

**Solution**:

```bash
# Full cache rebuild
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Restart Finder
killall Finder

# Log out and log back in (if above doesn't work)
```

---

## Technical Details

### Workflow Structure

```
Workflow Name.workflow/
├── Contents/
│   ├── Info.plist          # Metadata (name, input types, menu item)
│   ├── document.wflow      # Automator actions (XML format)
│   └── QuickLook/
│       ├── Thumbnail.png   # Preview thumbnail
│       └── Preview.png     # Full preview (optional)
```

### Info.plist Key Fields

```xml
<key>NSServices</key>
<array>
    <dict>
        <key>NSMenuItem</key>
        <dict>
            <key>default</key>
            <string>Workflow Name</string>  <!-- Menu text -->
        </dict>
        <key>NSMessage</key>
        <string>runWorkflowAsService</string>
        <key>NSSendFileTypes</key>
        <array>
            <string>public.item</string>    <!-- Accepted file types -->
        </array>
        <key>NSRequiredContext</key>
        <dict>
            <key>NSApplicationIdentifier</key>
            <string>com.apple.finder</string>  <!-- Where service appears -->
        </dict>
    </dict>
</array>
```

### File Permissions

**Recommended permissions**:
- Directories: `755` (drwxr-xr-x)
- Files: `644` (rw-r--r--)

**Set automatically by**:
```bash
./scripts/services/install-services.sh
```

### Services Cache

**Location**:
- ~/Library/Preferences/pbs.plist
- /Library/Preferences/com.apple.LaunchServices.plist

**Rebuild command**:
```bash
lsregister -kill -r -domain local -domain system -domain user
```

**When to rebuild**:
- After installing/removing workflows
- After modifying Info.plist
- When services don't appear in menu
- After system updates

---

## Development Guide

### Creating Custom Workflows

1. **Open Automator.app**

2. **Create Quick Action**:
   - File → New → Quick Action (formerly Service)

3. **Configure Workflow**:
   - Set "Workflow receives" (files, text, etc.)
   - Set "in" (Finder, any application, etc.)

4. **Add Actions**:
   - Drag actions from library
   - Configure action parameters
   - Test with sample input

5. **Save**:
   - File → Save
   - Save to `~/Library/Services/`
   - Name format: "Action Name.workflow"

6. **Test**:
   - Open Finder or appropriate app
   - Right-click → Services → Your Action Name

7. **Backup**:
```bash
make services-backup
```

8. **Document**:
   - Add to `services.yml`
   - Update this README
   - Commit to repository

### Workflow Categories

When creating workflows, follow these categories:

- **conversion**: File format converters
- **development**: Editor/IDE launchers, dev tools
- **productivity**: Task management, note-taking
- **cdn**: Asset and CDN management
- **media**: Image/video processing

### Testing Checklist

- [ ] Workflow appears in Services menu
- [ ] Works with intended file types
- [ ] Error handling for missing dependencies
- [ ] Fast execution (<2 seconds)
- [ ] No user prompts (unless necessary)
- [ ] Proper file permissions set
- [ ] Quarantine flag removed
- [ ] Cross-machine compatibility tested
- [ ] Documentation updated

---

## Related Files

- [services.yml](services.yml) - Workflow metadata and configuration
- [scripts/services/install-services.sh](../../scripts/services/install-services.sh) - Installation script
- [scripts/bootstrap/macos-bootstrap.sh](../../scripts/bootstrap/macos-bootstrap.sh) - Bootstrap integration
- [tests/test-50-macos-services.bats](../../tests/test-50-macos-services.bats) - Test suite

---

## Resources

### Apple Documentation
- [Automator User Guide](https://support.apple.com/guide/automator/welcome/mac)
- [Services Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/introduction.html)

### Useful Tools
- **Automator.app**: Built-in workflow editor
- **Console.app**: Debug workflow errors
- **System Settings → Services**: Enable/disable workflows
- **lsregister**: Services cache management

### Community Resources
- [Automator Actions List](https://www.macosxautomation.com/automator/)
- [Custom Automator Actions](https://github.com/topics/automator-actions)

---

## Changelog

### 2025-10-27
- Added open-in-vscode.workflow from MacBook backup
- Added Open in Cursor.workflow from MacBook backup
- Archived Send to Kindle.workflow (service discontinued)
- Archived Servizio Things.workflow (integration deprecated)
- Created services.yml metadata
- Created comprehensive README documentation
- Implemented installation script with essential/all modes
- Integrated with bootstrap and Makefile
- Added test suite

### Previous
- Initial backup of 6 workflows from MacBook
- File to MD, File to TXT, MD to Rich Text converters
- Retrieve CDN url custom workflow
- Send to Kindle (now archived)
- Servizio Things (now archived)

---

**Last Updated**: 2025-10-27
**Issue**: [#50 - macOS Services & Automator Workflows - Backup & Sync System](https://github.com/matteocervelli/dotfiles/issues/50)
**Related**: [#49 - Font Management System](https://github.com/matteocervelli/dotfiles/issues/49)
