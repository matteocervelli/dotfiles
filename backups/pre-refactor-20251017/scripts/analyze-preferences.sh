#!/bin/bash

# Analyze macOS Preferences Script
# Extracts current system preferences to understand what can be automated

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="${PROJECT_ROOT}/docs/preferences-analysis.md"

echo "============================================================================="
echo "  MACOS PREFERENCES ANALYZER"
echo "============================================================================="
echo

# Initialize output file
cat > "$OUTPUT_FILE" << EOF
# macOS Preferences Analysis

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')  
**Purpose**: Analyze current system preferences to identify automatable settings

---

EOF

echo -e "${BLUE}[INFO]${NC} Analyzing system preferences..."

# Function to safely read defaults
read_defaults() {
    local domain="$1"
    local name="$2"
    defaults read "$domain" 2>/dev/null || echo "Cannot read $domain"
}

# Function to extract specific keys
extract_key() {
    local domain="$1"
    local key="$2"
    defaults read "$domain" "$key" 2>/dev/null || echo "Key not found: $key"
}

#=============================================================================
# GLOBAL PREFERENCES
#=============================================================================

cat >> "$OUTPUT_FILE" << EOF
## 🌍 GLOBAL PREFERENCES (.GlobalPreferences)

### Appearance & Interface
EOF

echo -e "${BLUE}[INFO]${NC} Analyzing global preferences..."

# Interface Style
interface_style=$(extract_key ".GlobalPreferences" "AppleInterfaceStyle")
auto_switch=$(extract_key ".GlobalPreferences" "AppleInterfaceStyleSwitchesAutomatically")

cat >> "$OUTPUT_FILE" << EOF
\`\`\`
Interface Style: ${interface_style}
Auto Switch Dark/Light: ${auto_switch}
\`\`\`

### Language & Region
\`\`\`
EOF

extract_key ".GlobalPreferences" "AppleLanguages" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
extract_key ".GlobalPreferences" "AppleLocale" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << EOF

### Keyboard Settings
\`\`\`
EOF

extract_key ".GlobalPreferences" "InitialKeyRepeat" >> "$OUTPUT_FILE"
extract_key ".GlobalPreferences" "KeyRepeat" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"

#=============================================================================
# DOCK PREFERENCES
#=============================================================================

cat >> "$OUTPUT_FILE" << EOF

## 🗂️ DOCK PREFERENCES (com.apple.dock)

### Position & Behavior
\`\`\`
EOF

echo -e "${BLUE}[INFO]${NC} Analyzing dock preferences..."

extract_key "com.apple.dock" "orientation" >> "$OUTPUT_FILE"
extract_key "com.apple.dock" "autohide" >> "$OUTPUT_FILE"
extract_key "com.apple.dock" "tilesize" >> "$OUTPUT_FILE"
extract_key "com.apple.dock" "magnification" >> "$OUTPUT_FILE"
extract_key "com.apple.dock" "mineffect" >> "$OUTPUT_FILE"
extract_key "com.apple.dock" "minimize-to-application" >> "$OUTPUT_FILE"
extract_key "com.apple.dock" "launchanim" >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << EOF

### Persistent Applications
\`\`\`
EOF

# Count dock apps
app_count=$(defaults read com.apple.dock persistent-apps 2>/dev/null | grep -c "bundle-identifier" || echo "0")
echo "Number of persistent apps: $app_count" >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"

#=============================================================================
# FINDER PREFERENCES
#=============================================================================

cat >> "$OUTPUT_FILE" << EOF

## 📁 FINDER PREFERENCES (com.apple.finder)

### View Settings
\`\`\`
EOF

echo -e "${BLUE}[INFO]${NC} Analyzing finder preferences..."

extract_key "com.apple.finder" "AppleShowAllFiles" >> "$OUTPUT_FILE"
extract_key "com.apple.finder" "ShowHardDrivesOnDesktop" >> "$OUTPUT_FILE"
extract_key "com.apple.finder" "ShowExternalHardDrivesOnDesktop" >> "$OUTPUT_FILE"
extract_key "com.apple.finder" "ShowRemovableMediaOnDesktop" >> "$OUTPUT_FILE"
extract_key "com.apple.finder" "ShowMountedServersOnDesktop" >> "$OUTPUT_FILE"
extract_key "com.apple.finder" "NewWindowTarget" >> "$OUTPUT_FILE"
extract_key "com.apple.finder" "FXPreferredViewStyle" >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"

#=============================================================================
# CONTROL CENTER
#=============================================================================

cat >> "$OUTPUT_FILE" << EOF

## 🎛️ CONTROL CENTER (com.apple.controlcenter)

### Menu Bar Items
\`\`\`
EOF

echo -e "${BLUE}[INFO]${NC} Analyzing control center preferences..."

read_defaults "com.apple.controlcenter" | head -20 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"

#=============================================================================
# ACCESSIBILITY
#=============================================================================

cat >> "$OUTPUT_FILE" << EOF

## ♿ ACCESSIBILITY (com.apple.Accessibility)

\`\`\`
EOF

echo -e "${BLUE}[INFO]${NC} Analyzing accessibility preferences..."

read_defaults "com.apple.Accessibility" | head -10 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"

#=============================================================================
# TRACKPAD/MOUSE
#=============================================================================

cat >> "$OUTPUT_FILE" << EOF

## 🖱️ INPUT DEVICES

### Trackpad (com.apple.AppleMultitouchTrackpad)
\`\`\`
EOF

echo -e "${BLUE}[INFO]${NC} Analyzing input device preferences..."

read_defaults "com.apple.AppleMultitouchTrackpad" | head -10 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << EOF

### Mouse (com.apple.driver.AppleBluetoothMultitouch.mouse)
\`\`\`
EOF

read_defaults "com.apple.driver.AppleBluetoothMultitouch.mouse" | head -10 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"

#=============================================================================
# SECURITY & PRIVACY
#=============================================================================

cat >> "$OUTPUT_FILE" << EOF

## 🔒 SECURITY & PRIVACY

### Security Agent (com.apple.SecurityAgent)
\`\`\`
EOF

echo -e "${BLUE}[INFO]${NC} Analyzing security preferences..."

read_defaults "com.apple.SecurityAgent" | head -10 >> "$OUTPUT_FILE"

echo '```' >> "$OUTPUT_FILE"

#=============================================================================
# ANALYSIS SUMMARY
#=============================================================================

cat >> "$OUTPUT_FILE" << EOF

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
- **File Associations**: Require \`duti\` utility or Launch Services
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
1. Create \`macos/defaults-***.sh\` scripts for automatable settings
2. Screenshot only non-automatable visual elements
3. Create setup guides for manual configurations
4. Test automation scripts on clean system

EOF

echo -e "${GREEN}[SUCCESS]${NC} Preferences analysis completed!"
echo -e "${BLUE}[INFO]${NC} Report saved to: $OUTPUT_FILE"

# Count different categories
automatable=$(grep -c "✅" "$OUTPUT_FILE" || echo "0")
partial=$(grep -c "⚠️" "$OUTPUT_FILE" || echo "0") 
manual=$(grep -c "❌" "$OUTPUT_FILE" || echo "0")

echo
echo "============================================================================="
echo "  ANALYSIS SUMMARY"
echo "============================================================================="
echo -e "${GREEN}✅ Fully Automatable:${NC} Core system preferences"
echo -e "${YELLOW}⚠️  Partially Automatable:${NC} App-specific settings"
echo -e "${RED}❌ Manual Required:${NC} Visual layouts and security-sensitive"
echo
echo "📄 Full analysis: docs/preferences-analysis.md"
echo "🎯 Recommendation: Focus screenshots on visual elements only"