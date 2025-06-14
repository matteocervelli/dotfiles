# macOS Preferences Analysis

**Generated**: 2025-06-13 19:11:49  
**Purpose**: Analyze current system preferences to identify automatable settings

---

## 🌍 GLOBAL PREFERENCES (.GlobalPreferences)

### Appearance & Interface

```
Interface Style: Key not found: AppleInterfaceStyle
Auto Switch Dark/Light: 1
```

### Language & Region

```json
(
    "en-US",
    "it-IT"
)

en_US@rg=itzzzz
```

### Keyboard Settings

```
15
2
```

## 🗂️ DOCK PREFERENCES (com.apple.dock)

### Position & Behavior

```
Key not found: orientation
1
64
Key not found: magnification
scale
1
0
```

### Persistent Applications

```
Number of persistent apps: 16
```

## 📁 FINDER PREFERENCES (com.apple.finder)

### View Settings

```
0
0
0
0
0
PfHm
Nlsv
```

## 🎛️ CONTROL CENTER (com.apple.controlcenter)

### Menu Bar Items

```
{
    "LastHeartbeatDateString.daily" = "2025-06-13T16:03:43Z";
    "NSStatusItem Preferred Position AudioVideoModule" = 397;
    "NSStatusItem Preferred Position Battery" = 5925;
    "NSStatusItem Preferred Position BentoBox" = 162;
    "NSStatusItem Preferred Position Display" = 6190;
    "NSStatusItem Preferred Position FocusModes" = 6357;
    "NSStatusItem Preferred Position NowPlaying" = 6372;
    "NSStatusItem Preferred Position ScreenMirroring" = 5959;
    "NSStatusItem Preferred Position Shortcuts" = 6515;
    "NSStatusItem Preferred Position Sound" = 6036;
    "NSStatusItem Preferred Position UserSwitcher" = 11715;
    "NSStatusItem Preferred Position WiFi" = 196;
    "NSStatusItem Visible AudioVideoModule" = 0;
    "NSStatusItem Visible Battery" = 1;
    "NSStatusItem Visible BentoBox" = 1;
    "NSStatusItem Visible Clock" = 1;
    "NSStatusItem Visible Display" = 0;
    "NSStatusItem Visible FocusModes" = 0;
    "NSStatusItem Visible Item-0" = 0;
```

## ♿ ACCESSIBILITY (com.apple.Accessibility)

```
{
    AXSClassicInvertColorsPreference = 0;
    AccessibilityEnabled = 1;
    ApplicationAccessibilityEnabled = 1;
    AutomationEnabled = 0;
    BrailleInputDeviceConnected = 0;
    CommandAndControlEnabled = 0;
    DarkenSystemColors = 0;
    DifferentiateWithoutColor = 0;
    EnhancedBackgroundContrastEnabled = 0;
```

## 🖱️ INPUT DEVICES

### Trackpad (com.apple.AppleMultitouchTrackpad)

```
{
    ActuateDetents = 1;
    ActuationStrength = 0;
    Clicking = 1;
    DragLock = 0;
    Dragging = 0;
    FirstClickThreshold = 1;
    ForceSuppressed = 0;
    SecondClickThreshold = 1;
    TrackpadCornerSecondaryClick = 0;
```

### Mouse (com.apple.driver.AppleBluetoothMultitouch.mouse)

```
{
    MouseButtonDivision = 55;
    MouseButtonMode = OneButton;
    MouseHorizontalScroll = 1;
    MouseMomentumScroll = 1;
    MouseOneFingerDoubleTapGesture = 0;
    MouseTwoFingerDoubleTapGesture = 3;
    MouseTwoFingerHorizSwipeGesture = 2;
    MouseVerticalScroll = 1;
    UserPreferences = 1;
```

## 🔒 SECURITY & PRIVACY

### Security Agent (com.apple.SecurityAgent)

```
Cannot read com.apple.SecurityAgent
```

---

## 📊 AUTOMATION ANALYSIS

### ✅ FULLY AUTOMATABLE (via defaults commands)

- **Dock**: Position, size, autohide, minimize effects, persistent apps
- **Finder**: Show hidden files, desktop icons, new window target, view style
- **Global**: Interface style, language, locale, keyboard repeat
- **Control Center**: Menu bar items visibility
- **Input Devices**: Trackpad gestures, mouse settings
- **Accessibility**: Basic accessibility features

### ⚠️ PARTIALLY AUTOMATABLE (requires additional steps)

- **Applications**: App-specific settings need individual configuration
- **File Associations**: Require `duti` utility or Launch Services
- **Network**: Wi-Fi networks require manual setup for security
- **User Data**: Contacts, calendars, reminders sync

### ❌ MANUAL SCREENSHOT REQUIRED (not automatable)

- **Visual Layouts**: Actual appearance of UI elements
- **Complex Workflows**: Multi-step processes
- **App Store/Setapp**: Third-party app internal settings
- **Hardware Specific**: Display calibration, audio devices
- **Security Sensitive**: Passwords, certificates, private keys

### 🎯 RECOMMENDED APPROACH

1. **Automate with defaults**: All basic system preferences
2. **Document with screenshots**: Visual layouts and complex settings
3. **Script with additional tools**: File associations, network configs
4. **Manual setup guide**: Security-sensitive and app-specific settings

### 📝 NEXT STEPS

1. Create `macos/defaults-***.sh` scripts for automatable settings
2. Screenshot only non-automatable visual elements
3. Create setup guides for manual configurations
4. Test automation scripts on clean system
