# Screenshot Priority - Revised Based on Preferences Analysis

**Basato su**: Analisi preferences in `~/Library/Preferences/` e `defaults` commands

---

## 🚫 **NON SERVE SCREENSHOT** (Automatizzabile via script)

### ✅ Dock Settings (com.apple.dock)
- **Autohide**: `defaults write com.apple.dock autohide -bool true`
- **Position**: `defaults write com.apple.dock orientation left/bottom/right`
- **Size**: `defaults write com.apple.dock tilesize -int 64`
- **Minimize effect**: `defaults write com.apple.dock mineffect scale`
- **Minimize to app**: `defaults write com.apple.dock minimize-to-application -bool true`
- **Launch animation**: `defaults write com.apple.dock launchanim -bool false`
- **Persistent apps**: Script per aggiungere/rimuovere app

### ✅ Finder Settings (com.apple.finder)
- **Show hidden files**: `defaults write com.apple.finder AppleShowAllFiles -bool true`
- **Desktop icons**: `defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false`
- **New window target**: `defaults write com.apple.finder NewWindowTarget PfHm`
- **View style**: `defaults write com.apple.finder FXPreferredViewStyle clmv`

### ✅ Global Interface (.GlobalPreferences)
- **Dark/Light mode**: `defaults write .GlobalPreferences AppleInterfaceStyle Dark`
- **Auto switch**: `defaults write .GlobalPreferences AppleInterfaceStyleSwitchesAutomatically -bool true`
- **Language**: `defaults write .GlobalPreferences AppleLanguages '("en-US", "it-IT")'`
- **Locale**: `defaults write .GlobalPreferences AppleLocale "en_US@rg=itzzzz"`
- **Key repeat**: `defaults write .GlobalPreferences InitialKeyRepeat -int 15`
- **Key repeat rate**: `defaults write .GlobalPreferences KeyRepeat -int 2`

### ✅ Control Center (com.apple.controlcenter)
- **Menu bar items**: Tutti i moduli Control Center
- **Battery percentage**: `defaults write com.apple.controlcenter BatteryShowPercentage -bool true`

### ✅ Trackpad/Mouse Settings
- **Trackpad gestures**: Tutte le gesture via defaults
- **Tracking speed**: Velocità trackpad/mouse
- **Click settings**: Secondary click, tap to click

### ✅ Basic Accessibility
- **Reduce motion**: `defaults write com.apple.Accessibility ReduceMotionEnabled -bool true`
- **Increase contrast**: Via defaults commands
- **Basic display accessibility**: Automatable

---

## 📸 **SERVE SCREENSHOT** (Non automatizzabile)

### 🔴 HIGH PRIORITY - Visual Layout & Complex UI

#### System Preferences
- [ ] **Mission Control visual**: Layout actual spaces, hot corners UI
- [ ] **Desktop & Screen Saver**: Visual wallpaper selection interface
- [ ] **Displays arrangement**: Multi-monitor physical arrangement
- [ ] **Privacy & Security panels**: Complex permission layouts
- [ ] **Keyboard shortcuts interface**: Visual shortcut assignment UI
- [ ] **Sound input/output selection**: Device selection interface

#### Applications Visual Settings
- [ ] **Finder toolbar customization**: Visual toolbar layout
- [ ] **Finder sidebar visual**: Actual sidebar appearance and order
- [ ] **Safari extension interface**: Extension management UI
- [ ] **Mail account setup flow**: Visual setup process
- [ ] **Calendar view preferences**: Visual calendar layouts

### 🟡 MEDIUM PRIORITY - App-Specific Configurations

#### Third-Party Apps (Setapp)
- [ ] **BetterTouchTool gesture mapping**: Visual gesture configuration
- [ ] **Bartender menu organization**: Visual menu bar organization
- [ ] **CleanShot X interface**: Screenshot tool settings interface
- [ ] **Paste clipboard interface**: Visual clipboard manager

#### Development Tools
- [ ] **Cursor/VS Code interface**: Theme and layout (already covered by settings sync)
- [ ] **Terminal profile visual**: Color scheme and appearance
- [ ] **Xcode interface preferences**: Visual IDE preferences

### 🟢 LOW PRIORITY - Reference Documentation

#### Complex Workflows
- [ ] **File association dialogs**: "Open with" selection process
- [ ] **Network setup process**: Wi-Fi configuration flow (sensitive)
- [ ] **User account setup**: Visual account management (sensitive)
- [ ] **Time Zone selection**: Visual world map interface

---

## 🎯 **REVISED SCREENSHOT PLAN**

### Phase 1: High Priority Visual Elements (~25 screenshots)
1. **Mission Control**: Spaces layout, hot corners visual
2. **Desktop wallpaper**: Selection interface
3. **Finder visual**: Toolbar and sidebar appearance
4. **Privacy panels**: Permission interfaces
5. **Keyboard shortcuts**: Visual shortcut interface
6. **Display arrangement**: Multi-monitor setup
7. **Sound devices**: Input/output selection

### Phase 2: Third-Party App Interfaces (~20 screenshots)
1. **Setapp apps**: BetterTouchTool, Bartender, CleanShot X visual configs
2. **Development**: Terminal themes, tool interfaces
3. **Productivity**: App-specific interfaces not automatable

### Phase 3: Reference Documentation (~15 screenshots)
1. **Complex workflows**: Multi-step processes
2. **Setup flows**: Account and network setup processes
3. **File associations**: Default app selection interfaces

---

## 🚀 **AUTOMATION SCRIPTS TO CREATE**

Based on preferences analysis, create these automation scripts:

### Core System (macos/ directory)
- [ ] **dock.sh**: Complete dock configuration
- [ ] **finder.sh**: All finder preferences
- [ ] **interface.sh**: Dark mode, languages, keyboard
- [ ] **controlcenter.sh**: Menu bar modules
- [ ] **input.sh**: Trackpad and mouse settings
- [ ] **accessibility.sh**: Basic accessibility features

### Advanced Configuration
- [ ] **defaults-backup.sh**: Export current settings
- [ ] **defaults-restore.sh**: Apply saved settings
- [ ] **app-associations.sh**: File type associations via `duti`

---

## 📊 **IMPACT SUMMARY**

**🎉 MASSIVE REDUCTION**: Da ~150-200 screenshot a ~60 screenshot!

**✅ Automatable (90+ settings)**:
- Dock: 7+ settings
- Finder: 10+ settings  
- Interface: 8+ settings
- Control Center: 15+ modules
- Input devices: 20+ settings
- Basic accessibility: 10+ settings

**📸 Screenshot Only (60 settings)**:
- Visual layouts: 25 screenshots
- App interfaces: 20 screenshots
- Reference docs: 15 screenshots

**⏱️ Time Saved**: 
- Old approach: 4-6 ore screenshot
- New approach: 1.5-2 ore screenshot + 2 ore script automation
- **Result**: Setup automatizzato al 85%!

---

## 🔄 **NEXT STEPS**

1. **✅ DONE**: Preferences analysis 
2. **🚧 IN PROGRESS**: Reduced screenshot list
3. **⏳ TODO**: Create automation scripts in `macos/`
4. **⏳ TODO**: Take only essential visual screenshots
5. **⏳ TODO**: Test full automation on clean system