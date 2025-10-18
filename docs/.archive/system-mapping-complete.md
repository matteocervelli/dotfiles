# Mappatura Completa Sistema - Matteo Cervelli

## Obiettivo

Documentazione ultra-completa dell'intero ecosistema tecnologico per replicazione e riferimento futuro.

---

## 🖥️ HARDWARE - Mac Studio (Riferimento Base)

### Specifiche Hardware Mac Studio

- [ ] **Processore**: M1/M2 Max/Ultra specs
- [ ] **RAM**: Quantità installata
- [ ] **Storage**: SSD primario + storage aggiuntivo
- [ ] **Porte**: Utilizzo specifico per ogni porta
- [ ] **Display**: Monitor collegati (modelli, risoluzioni, configurazione)
- [ ] **Periferiche**: Tastiera, mouse, trackpad, webcam, microfono
- [ ] **Audio**: Speaker, cuffie, interfacce audio
- [ ] **Storage Esterno**: Drive esterni, backup drives

### Configurazione Display

- [ ] **Monitor Primario**: Modello, risoluzione, color profile
- [ ] **Monitor Secondario**: Se presente, configurazione
- [ ] **Arrangement**: Posizione display in System Preferences
- [ ] **Scaling**: Retina/scaling settings
- [ ] **Night Shift**: Configurazione automatica
- [ ] **True Tone**: Settings se supportato

---

## 🖱️ SISTEMA OPERATIVO - macOS

### System Preferences - General

- [ ] **Appearance**: Light/Dark/Auto
- [ ] **Accent Color**: Colore scelto
- [ ] **Highlight Color**: Colore evidenziazione
- [ ] **Sidebar Icon Size**: Small/Medium/Large
- [ ] **Auto-hide menu bar**: On/Off
- [ ] **Show scroll bars**: Always/When scrolling/Automatically
- [ ] **Click in scroll bar**: Jump to here/Jump to spot clicked
- [ ] **Default web browser**: Browser predefinito
- [ ] **Ask to keep changes**: Document settings
- [ ] **Close windows when quitting**: App behavior

### Desktop & Screen Saver

- [ ] **Desktop Wallpaper**: File/path del wallpaper
- [ ] **Desktop Picture**: Rotation settings
- [ ] **Screen Saver**: Tipo e timing
- [ ] **Hot Corners**: Configurazione 4 angoli
- [ ] **Mission Control**: Spaces configuration

### Dock & Menu Bar

- [ ] **Dock Position**: Bottom/Left/Right
- [ ] **Dock Size**: Slider position
- [ ] **Magnification**: On/Off + level
- [ ] **Minimize Effect**: Genie/Scale
- [ ] **Show/Hide Dock**: Automatically
- [ ] **Animate Opening**: On/Off
- [ ] **Show Indicators**: For open apps
- [ ] **Show Recent**: In Dock
- [ ] **Menu Bar Icons**: Quali icone visibili
- [ ] **Control Center**: Configurazione moduli

### Finder Preferences

- [ ] **New Finder Windows Show**: Cartella predefinita
- [ ] **Open Folders in Tabs**: On/Off
- [ ] **Sidebar Items**: Quali elementi visualizzati
- [ ] **Advanced**:
  - Show all filename extensions
  - Show warning before changing extension
  - Show warning before removing from iCloud Drive
  - Show warning before emptying Trash
  - Remove items from Trash after 30 days
  - Keep folders on top in windows sorted by name
  - When performing search: Search current folder/This Mac
- [ ] **View Options**: Default view (Icon/List/Column/Gallery)
- [ ] **Tags**: Configurazione tags Finder

### Security & Privacy

- [ ] **General**: Require password settings
- [ ] **FileVault**: On/Off + Recovery key location
- [ ] **Firewall**: On/Off + configuration
- [ ] **Privacy**:
  - Location Services permissions
  - Contacts permissions
  - Calendar permissions
  - Camera permissions
  - Microphone permissions
  - Files and Folders permissions
  - Full Disk Access permissions
  - Developer Tools permissions
- [ ] **Screen Recording**: App permissions
- [ ] **Accessibility**: App permissions

### Trackpad & Mouse

- [ ] **Point & Click**:
  - Look up & data detectors
  - Secondary click
  - Tap to click
  - Force Click and haptic feedback
  - Silent clicking
- [ ] **Scroll & Zoom**:
  - Scroll direction natural
  - Zoom in or out
  - Smart zoom
  - Rotate
- [ ] **More Gestures**:
  - Swipe between pages
  - Swipe between full-screen apps
  - Notification Center
  - Mission Control
  - App Exposé
  - Launchpad
  - Show Desktop

### Keyboard

- [ ] **Keyboard**:
  - Key Repeat rate
  - Delay Until Repeat
  - Touch Bar settings (se applicabile)
- [ ] **Text**:
  - Correct spelling automatically
  - Capitalize words automatically
  - Add period with double-space
  - Touch Bar typing suggestions
  - Use smart quotes and dashes
- [ ] **Shortcuts**:
  - Mission Control shortcuts
  - Keyboard shortcuts customization
  - Input Sources shortcuts
  - Screenshots shortcuts
  - Services shortcuts
  - Spotlight shortcuts
  - Accessibility shortcuts
  - App Shortcuts personalizzati
- [ ] **Input Sources**: Language settings
- [ ] **Dictation**: On/Off + language

### Sound

- [ ] **Sound Effects**:
  - Play sound on startup
  - Play user interface sound effects
  - Select alert sound
  - Alert volume
- [ ] **Output**: Selected output device + balance
- [ ] **Input**: Selected input device + input volume
- [ ] **Ambient Noise Reduction**: On/Off

### Network

- [ ] **Wi-Fi**:
  - Network prioritization
  - Ask to join networks
  - Ask to join hotspots
  - Advanced settings (DNS, Proxies, Hardware)
- [ ] **Ethernet**: Configuration se collegato
- [ ] **Firewall**: Detailed settings
- [ ] **VPN**: Configurazioni VPN (Tailscale etc.)

### Energy Saver / Battery

- [ ] **Power Adapter**:
  - Turn display off after
  - Prevent computer from sleeping automatically
  - Put hard disks to sleep when possible
  - Wake for network access
  - Start up automatically after power failure
- [ ] **Schedule**: Auto startup/shutdown times

### Time Machine

- [ ] **Backup Settings**: Destinations + frequency
- [ ] **Options**: Items to exclude
- [ ] **Encryption**: On/Off

### Sharing

- [ ] **Computer Name**: Nome computer rete
- [ ] **AirDrop**: Configurazione
- [ ] **Screen Sharing**: On/Off + settings
- [ ] **File Sharing**: Cartelle condivise
- [ ] **Printer Sharing**: Se abilitato
- [ ] **Remote Login**: SSH settings
- [ ] **Remote Management**: Apple Remote Desktop
- [ ] **Internet Sharing**: Configuration

---

## 🛠️ SOFTWARE INSTALLATO

### Development Tools (Homebrew Scan)

```bash
# Comando per scansione completa
brew list --formula > software-formula.txt
brew list --cask > software-casks.txt
mas list > software-mas.txt
```

### Categorizzazione Software

- [ ] **Development**:
  - IDE/Editors (Cursor, Xcode, etc.)
  - Version Control (Git, SourceTree, etc.)
  - Databases (PostgreSQL, Redis, etc.)
  - Containers (Docker, etc.)
  - API Tools (Postman, Insomnia, etc.)
  - Package Managers (Node, Python, etc.)

- [ ] **Productivity**:
  - Office Suite
  - Note-taking apps
  - Task management
  - Calendar apps
  - PDF tools
  - Image/Video editing

- [ ] **System Utilities**:
  - CleanMyMac
  - Activity Monitor alternatives
  - Disk utilities
  - Archive tools
  - System monitoring
  - Backup utilities

- [ ] **Communication**:
  - Slack, Teams, Discord
  - Email clients
  - Video conferencing
  - Social media apps

- [ ] **Security**:
  - 1Password
  - Bitdefender
  - VPN clients
  - Firewall apps

- [ ] **Browser & Extensions**:
  - Browser principali installati
  - Extensions per ogni browser
  - Search engines configurati
  - Homepage/startup settings

### Node.js Environment

- [ ] **NVM**: Versioni Node installate
- [ ] **Global Packages**: `npm list -g --depth=0`
- [ ] **Yarn**: Se installato + versione
- [ ] **Package Registries**: npm/yarn configurations

### Python Environment  

- [ ] **Pyenv**: Versioni Python installate
- [ ] **Virtual Environments**: Lista venv attivi
- [ ] **Global Packages**: `pip list` per ogni versione
- [ ] **Conda**: Se installato + environments

### iOS/macOS Development

- [ ] **Xcode**: Versione + simulatori installati
- [ ] **iOS Simulators**: Versioni disponibili
- [ ] **Provisioning Profiles**: Developer account setup
- [ ] **Certificates**: Code signing certificates

---

## 🔐 SICUREZZA & ACCOUNT

### Password Manager (1Password)

- [ ] **Vault Structure**: Organizzazione vault
- [ ] **SSH Keys**: Gestione chiavi SSH
- [ ] **GPG Keys**: Configurazione signing Git
- [ ] **API Keys**: Storage chiavi sviluppo
- [ ] **Browser Integration**: Setup extension
- [ ] **CLI Tool**: `op` CLI configuration

### SSH Configuration

- [ ] **SSH Keys**: Lista chiavi + utilizzo
- [ ] **SSH Config**: ~/.ssh/config entries
- [ ] **Known Hosts**: Server configurati
- [ ] **SSH Agent**: Configurazione agent

### GPG Configuration

- [ ] **GPG Keys**: Public/private keys
- [ ] **Git Signing**: Configurazione commit signing
- [ ] **Keychain Integration**: macOS Keychain setup

### Cloud Services & Sync

- [ ] **iCloud**: Cosa viene sincronizzato
- [ ] **Dropbox/Google Drive**: Sync folders
- [ ] **OneDrive**: Business account sync
- [ ] **GitHub**: Account + SSH keys + tokens

---

## 🌐 RETE & INFRASTRUTTURA

### Router Configuration

- [ ] **Router Model**: Marca/modello router principale
- [ ] **Firmware**: Versione firmware
- [ ] **WiFi Settings**:
  - SSID names
  - Security protocols (WPA3, etc.)
  - Channel configuration
  - Bandwidth settings
- [ ] **Network Configuration**:
  - DHCP range
  - Static IP assignments
  - Port forwarding rules
  - Guest network setup
- [ ] **QoS Settings**: Bandwidth prioritization
- [ ] **VPN Server**: Se configurato sul router
- [ ] **Firewall Rules**: Configurazioni security
- [ ] **Dynamic DNS**: Se configurato

### Network Infrastructure

- [ ] **Switch**: Modelli e configurazione
- [ ] **Access Points**: WiFi mesh/extender setup
- [ ] **Ethernet Cabling**: Cat6/Cat7 infrastructure
- [ ] **Network Printer**: Setup e condivisione
- [ ] **Smart Home Devices**: IoT device network

### Internet Connection

- [ ] **ISP**: Provider + piano
- [ ] **Speed**: Download/Upload speeds
- [ ] **IP Configuration**: Static/Dynamic public IP
- [ ] **Backup Connection**: Mobile hotspot/backup ISP

---

## 💾 STORAGE & BACKUP

### NAS Configuration

- [ ] **NAS Model**: Synology/QNAP/altro modello
- [ ] **Drive Configuration**: RAID setup + capacity
- [ ] **Shared Folders**: Structure e permissions
- [ ] **User Accounts**: Account configurati
- [ ] **Backup Jobs**:
  - Mac Time Machine targets
  - Cloud sync (Google Drive, Dropbox)
  - Remote backup destinations
- [ ] **Services Running**:
  - File sharing protocols (SMB, AFP, NFS)
  - Media server (Plex, etc.)
  - VPN server
  - Download station
  - Photo management
  - Note taking server
- [ ] **Security Settings**:
  - Firewall configuration
  - Access controls
  - Encryption settings
- [ ] **Mobile Apps**: Configurazione app mobili
- [ ] **Remote Access**: External access setup

### Local Storage Strategy

- [ ] **Internal Storage**: SSD configuration
- [ ] **External Drives**:
  - Backup drives (Time Machine)
  - Working storage
  - Archive storage
- [ ] **Cloud Storage**:
  - iCloud storage plan + usage
  - Google Drive organization
  - Dropbox structure
  - OneDrive business setup

### Backup Strategy (3-2-1 Rule)

- [ ] **Local Backup**: Time Machine configuration
- [ ] **Cloud Backup**: iCloud + other cloud services
- [ ] **Remote Backup**: NAS + offsite backup
- [ ] **Archive Strategy**: Long-term data retention
- [ ] **Recovery Testing**: Backup restore procedures

---

## 🔧 DEVELOPMENT ENVIRONMENT

### Project Structure

- [ ] **~/dev Directory**: Complete structure mapping
- [ ] **Active Projects**: Currently in development
- [ ] **Template Projects**: Boilerplate repositories
- [ ] **Client Work**: Organization per client
- [ ] **Personal Projects**: Side projects structure
- [ ] **Learning/Experiments**: Sandbox directories

### Git Configuration

- [ ] **Global Git Config**: User, email, signing
- [ ] **Git Aliases**: Custom aliases in use
- [ ] **Git Hooks**: Project-specific hooks
- [ ] **GitHub CLI**: Configuration and usage
- [ ] **Repository Organization**: Public/private repo strategy

### Database Setup

- [ ] **PostgreSQL**:
  - Version installed
  - Databases created
  - User accounts
  - Extension installed
- [ ] **Redis**: Configuration per caching
- [ ] **Database Tools**: GUI tools (Sequel Pro, etc.)

### Container Environment

- [ ] **Docker Desktop**: Configuration
- [ ] **Docker Compose**: Standard compose files
- [ ] **Container Registry**: Private registry setup
- [ ] **Kubernetes**: Local development setup

---

## 📱 MOBILE & TABLET INTEGRATION

### iOS/iPadOS Devices

- [ ] **iPhone**: Model + iOS version
- [ ] **iPad**: Model + iPadOS version
- [ ] **Apps Installed**: Developer/productivity apps
- [ ] **Sync Configuration**:
  - iCloud sync settings
  - App-specific sync (1Password, etc.)
  - Development-related apps (Xcode companion, etc.)

### Cross-Device Workflow

- [ ] **Handoff**: Configuration apps
- [ ] **Universal Clipboard**: Usage pattern
- [ ] **AirDrop**: File sharing workflow
- [ ] **Continuity Camera**: Integration setup
- [ ] **Sidecar**: iPad as second display

---

## 🖨️ PERIFERICHE & HARDWARE AGGIUNTIVO

### Input Devices

- [ ] **Keyboard**:
  - Model (Apple Magic, mechanical, etc.)
  - Layout language
  - Custom key mappings
- [ ] **Mouse/Trackpad**:
  - Model e configurazione
  - Button assignments
  - Gesture configuration
- [ ] **Graphics Tablet**: Se presente (Wacom, etc.)

### Audio/Video Equipment  

- [ ] **Microphone**: Model per recording/calls
- [ ] **Webcam**: External camera setup
- [ ] **Speakers**: Audio system configuration
- [ ] **Headphones**: Primary/secondary headphones
- [ ] **Audio Interface**: Se presente per recording

### Other Hardware

- [ ] **Printer**: Network printer configuration
- [ ] **Scanner**: Document scanning setup
- [ ] **External Storage**: USB drives, SD cards
- [ ] **Charging Station**: Device charging organization
- [ ] **Cable Management**: Desk cable organization

---

## ⚙️ AUTOMAZIONE & WORKFLOW

### Automation Tools

- [ ] **Shortcuts (macOS)**: Automated workflows
- [ ] **Automator**: Custom automations
- [ ] **Shell Scripts**: Custom automation scripts
- [ ] **Cron Jobs**: Scheduled tasks
- [ ] **Hazel**: File organization automation
- [ ] **Alfred/Raycast**: Launcher configuration

### MCP Servers (Model Context Protocol)

- [ ] **Active MCP Servers**: Lista 15+ server configurati
- [ ] **Configuration Files**: Settings per ogni server
- [ ] **Integration Points**: App che utilizzano MCP
- [ ] **Custom MCP Development**: Server personalizzati

### Tailscale Network

- [ ] **Device Configuration**: Tutti i device nella rete
- [ ] **Access Controls**: Permissions e routing
- [ ] **Magic DNS**: Configurazione DNS interno
- [ ] **Exit Nodes**: Node configurati per traffico
- [ ] **Subnet Routing**: Access a reti locali

---

## 📊 MONITORING & MAINTENANCE

### System Monitoring

- [ ] **Activity Monitor**: Usage patterns
- [ ] **Console**: Log monitoring setup
- [ ] **Third-party Tools**: Stats monitoring apps
- [ ] **Disk Utility**: Disk health monitoring
- [ ] **Network Monitoring**: Bandwidth usage tools

### Maintenance Schedule

- [ ] **Software Updates**: Automatic/manual preferences
- [ ] **Backup Verification**: Testing schedule
- [ ] **Disk Cleanup**: Automated cleaning tools
- [ ] **Security Scans**: Regular security checks
- [ ] **Performance Optimization**: Regular maintenance tasks

---

## 🔍 SCREENSHOT & DOCUMENTATION CHECKLIST

### macOS System Screenshots

- [ ] **System Preferences**: Every single pane
- [ ] **Finder Preferences**: All tabs
- [ ] **Dock**: Configuration e apps
- [ ] **Menu Bar**: All icons e configuration
- [ ] **Control Center**: Configuration
- [ ] **Notification Center**: Settings
- [ ] **Privacy & Security**: All permission screens
- [ ] **Network**: All network configurations
- [ ] **Displays**: Multi-monitor setup
- [ ] **Sound**: Input/output settings

### Application Screenshots

- [ ] **Cursor/VS Code**:
  - Settings.json complete
  - Extensions installed
  - Themes e color schemes
  - Keybinding customizations
- [ ] **Terminal/Shell**:
  - Prompt configuration
  - Color schemes
  - Font settings
- [ ] **Browser Configuration**:
  - Homepage settings
  - Extension setup
  - Bookmark organization
- [ ] **1Password**:
  - Vault organization
  - Browser integration
  - SSH agent setup

### Development Environment Screenshots

- [ ] **Git Configuration**: Global config file
- [ ] **SSH Configuration**: Config file structure
- [ ] **Database Tools**: Connection setup
- [ ] **Docker Desktop**: Configuration screens
- [ ] **Project Structure**: ~/dev organization

### Network & Infrastructure Screenshots

- [ ] **Router Admin**: Complete configuration
- [ ] **NAS Admin**: All configuration screens
- [ ] **Tailscale Admin**: Network topology
- [ ] **DNS Configuration**: All DNS settings

---

*Obiettivo: Documentazione completa per replicazione esatta dell'ecosistema su qualsiasi nuovo Mac*

**PROSSIMO PASSO**: Creare script di scansione automatica per tutti i punti mappabili via CLI + lista prioritizzata screenshot manuali.
