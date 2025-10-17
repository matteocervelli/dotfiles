# Screenshots Directory

Directory strutturata per i 45 screenshot necessari alla documentazione dotfiles macOS.

## 📁 Struttura Basata su screenshot-list-exact.md

### 🖥️ System Preferences (`system-preferences/`)

- `mission-control/` - Screenshots #01-#02: Spaces overview, hot corners
- `desktop-screensaver/` - Screenshots #03-#04: Wallpaper e screen saver selection
- `displays/` - Screenshots #05-#06: Display arrangement, color profiles
- `privacy-security/` - Screenshots #07-#11: Privacy sidebar, permissions (5 screenshots)
- `keyboard/` - Screenshots #12-#14: Shortcuts categories, Mission Control, custom
- `sound/` - Screenshots #15-#16: Output/input devices
- `network/` - Screenshots #33-#34: Wi-Fi advanced, DNS settings
- `users-groups/` - Screenshots #35-#36: Login items, user settings
- `date-time/` - Screenshot #37: Timezone map interface
- `language-region/` - Screenshot #38: Language list interface

### 📱 Applications (`applications/`)

- `finder/` - Screenshots #17-#18: Toolbar customization, sidebar layout
- `development/`
  - `terminal/` - Screenshot #28: Terminal profile visual
  - `cursor-vscode/` - Screenshots #29-#30: Interface theme, extensions

### 🔧 Third-Party (`third-party/`)

- `setapp-apps/`
  - `bettertouchtool/` - Screenshots #19-#21: Gesture mapping, trackpad, shortcuts
  - `bartender/` - Screenshots #22-#23: Menu bar organization, settings
  - `cleanshot-x/` - Screenshots #24-#25: Screenshot settings, annotation tools
  - `other-setapp/` - Screenshots #26-#27: AirBuddy, Proxyman interfaces

### 🌐 Menu Bar & Overview (`menu-bar/`, `overview/`)

- `menu-bar/` - Screenshots #39-#41: Full overview, Control Center, Notification Center
- `overview/` - Screenshots #42-#43: Desktop complete, dock apps layout

### ⚙️ Special Configurations (`special-configs/`)

- `file-associations/` - Screenshots #31-#32: Get Info dialogs, default apps
- `tailscale/` - Screenshot #44: Status interface (no sensitive data)
- `docker/` - Screenshot #45: Dashboard overview

## 📸 Screenshot Mapping

### Priorità e Numerazione

- **🔴 High Priority**: Screenshots #01-#18 (18 screenshots)
- **🟡 Medium Priority**: Screenshots #19-#30 (12 screenshots)
- **🟢 Low Priority**: Screenshots #31-#45 (15 screenshots)

### Directory → Screenshot Numbers

```
system-preferences/
├── mission-control/     → #01-#02
├── desktop-screensaver/ → #03-#04
├── displays/           → #05-#06
├── privacy-security/   → #07-#11
├── keyboard/           → #12-#14
├── sound/              → #15-#16
├── network/            → #33-#34
├── users-groups/       → #35-#36
├── date-time/          → #37
└── language-region/    → #38

applications/
├── finder/             → #17-#18
└── development/
    ├── terminal/       → #28
    └── cursor-vscode/  → #29-#30

third-party/setapp-apps/
├── bettertouchtool/    → #19-#21
├── bartender/          → #22-#23
├── cleanshot-x/        → #24-#25
└── other-setapp/       → #26-#27

menu-bar/               → #39-#41
overview/               → #42-#43

special-configs/
├── file-associations/  → #31-#32
├── tailscale/          → #44
└── docker/             → #45
```

## 🎯 Ordine di Shooting Raccomandato

### Phase 1 (30 min): Foundation + Core

1. **#42** `overview/desktop-complete-overview.png`
2. **#39** `menu-bar/menu-bar-full-overview.png`
3. **#01-#02** `system-preferences/mission-control/`
4. **#17-#18** `applications/finder/`

### Phase 2 (30 min): System Settings

1. **#07-#11** `system-preferences/privacy-security/` (batch 5)
2. **#12-#14** `system-preferences/keyboard/` (batch 3)
3. **#03-#06** `system-preferences/desktop-screensaver/`, `displays/`
4. **#15-#16** `system-preferences/sound/`

### Phase 3 (30 min): Third-Party Apps

1. **#19-#21** `third-party/setapp-apps/bettertouchtool/`
2. **#22-#23** `third-party/setapp-apps/bartender/`
3. **#24-#25** `third-party/setapp-apps/cleanshot-x/`
4. **#26-#27** `third-party/setapp-apps/other-setapp/`
5. **#28-#30** `applications/development/`

### Phase 4 (30 min): References & Remaining

1. **#40-#41, #43** Menu bar details + dock
2. **#31-#32** `special-configs/file-associations/`
3. **#33-#38** Remaining system preferences
4. **#44-#45** `special-configs/tailscale/`, `docker/`

## 📝 File Naming Convention

Ogni screenshot deve seguire esattamente il nome dal file `screenshot-list-exact.md`:

**Esempi:**

- `#01` → `spaces-overview.png`
- `#07` → `privacy-sidebar.png`
- `#19` → `gesture-mapping-interface.png`
- `#42` → `desktop-complete-overview.png`

## ✅ Progress Tracking

Usa la checklist dal file `screenshot-list-exact.md` per tracciare:

```
🔴 HIGH PRIORITY (0/18 completed)
☐ #01  ☐ #02  ☐ #03  ☐ #04  ☐ #05  ☐ #06
☐ #07  ☐ #08  ☐ #09  ☐ #10  ☐ #11  ☐ #12
☐ #13  ☐ #14  ☐ #15  ☐ #16  ☐ #17  ☐ #18

🟡 MEDIUM PRIORITY (0/12 completed)
☐ #19  ☐ #20  ☐ #21  ☐ #22  ☐ #23  ☐ #24
☐ #25  ☐ #26  ☐ #27  ☐ #28  ☐ #29  ☐ #30

🟢 LOW PRIORITY (0/15 completed)  
☐ #31  ☐ #32  ☐ #33  ☐ #34  ☐ #35  ☐ #36
☐ #37  ☐ #38  ☐ #39  ☐ #40  ☐ #41  ☐ #42
☐ #43  ☐ #44  ☐ #45
```

**TOTAL DIRECTORIES: 29**
**TOTAL SCREENSHOTS: 45**
**ESTIMATED TIME: 2 hours (4 phases × 30 min)**
