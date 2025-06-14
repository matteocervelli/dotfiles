# Dotfiles Project - Task List

## Status Overview
- ✅ **Completed**: FASE 1 - Setup Documentazione e Struttura
- ✅ **Completed**: FASE 2 - Scansione Sistema Attuale
- ✅ **Completed**: FASE 3 - Configurazioni Core con GNU Stow
- 🟡 **Ready to Start**: FASE 4 - Automazione Homebrew e macOS
- ⚪ **Pending**: FASE 5-6 - Infrastruttura e Testing

## FASE 1: Setup Documentazione e Struttura ✅
**Obiettivo**: Creare base documentale e struttura directory

- [x] **1.1** Creare docs/PLANNING.md con piano dettagliato
- [x] **1.2** Creare docs/TASK.md con lista task (questo file)  
- [x] **1.3** Creare struttura directory completa
- [x] **1.4** Aggiornare CLAUDE.md con istruzioni specifiche progetto

## FASE 2: Scansione Sistema Attuale ✅
**Obiettivo**: Documentare configurazione esistente prima della formattazione

### 2.1 Backup Configurazioni Shell ✅
- [x] **2.1.1** Backup .zshrc esistente
- [x] **2.1.2** Backup .zsh_aliases esistenti  
- [x] **2.1.3** Backup zsh_plugins/functions esistenti
- [x] **2.1.4** Documentare Oh My Zsh themes/plugins in uso

### 2.2 Scan Software Installato ✅
- [x] **2.2.1** Script scan Homebrew (`brew list --formula`)
- [x] **2.2.2** Script scan Homebrew Casks (`brew list --cask`)
- [x] **2.2.3** Script scan Mac App Store (`mas list`)
- [x] **2.2.4** Script scan NPM globals (`npm list -g --depth=0`)
- [x] **2.2.5** Script scan Python packages (`pip list`)
- [x] **2.2.6** Documentare versioni pyenv/nvm in uso

### 2.3 Configurazioni Sistema ✅
- [x] **2.3.1** Screenshot Dock (posizione, dimensione, apps)
- [x] **2.3.2** Screenshot Finder (sidebar, preferences)
- [x] **2.3.3** Screenshot System Preferences principali
- [x] **2.3.4** Backup configurazioni Tailscale
- [x] **2.3.5** Backup chiavi SSH
- [x] **2.3.6** Documentare font installati
- [x] **2.3.7** Screenshot completi salvati in screenshots/
- [x] **2.3.8** Analisi dettagliata in docs/preferences-analysis.md
- [x] **2.3.9** Lista esatta screenshot in docs/screenshot-list-exact.md

### 2.4 Development Environment ✅ 
- [x] **2.4.1** Documentare struttura ~/dev
- [x] **2.4.2** Lista progetti attivi da preservare
- [x] **2.4.3** Backup configurazioni Cursor/VS Code
- [x] **2.4.4** Backup configurazioni Claude Code
- [x] **2.4.5** Documentare MCP servers configurati

## FASE 3: Configurazioni Core con GNU Stow ✅
**Obiettivo**: Implementare configurazioni principali

### 3.1 Shell Configuration (ZSH) ✅
- [x] **3.1.1** Creare packages/zsh/.zshrc con Oh My Zsh
- [x] **3.1.2** Migrare .zsh_aliases esistenti  
- [x] **3.1.3** Convertire zsh_plugins in .zsh_functions
- [x] **3.1.4** Configurare tema e plugin Oh My Zsh preferiti
- [x] **3.1.5** Completare configurazione ZSH

### 3.2 Git Configuration ✅
- [x] **3.2.1** Creare packages/git/.gitconfig (user, GPG 1Password)
- [x] **3.2.2** Creare packages/git/.gitignore_global estensivo
- [x] **3.2.3** Aggiungere templates commit/PR/issues (.gitmessage)
- [x] **3.2.4** Configurare Git aliases utili
- [x] **3.2.5** Completare configurazione Git

### 3.3 Development Tools ✅
- [x] **3.3.1** Creare packages/python/ con pyenv configs (.pyenvrc, .pythonrc, pip.conf)
- [x] **3.3.2** Creare packages/node/ con nvm configs (.nvmrc, .npmrc, .nvmsh)
- [x] **3.3.3** Creare packages/cursor/ con settings Cursor (settings.json, keybindings.json)
- [x] **3.3.4** Creare packages/claude/ con Claude Code configs (CLAUDE.md)
- [x] **3.3.5** Completare configurazioni development

### 3.4 SSH & Network ✅
- [x] **3.4.1** Creare packages/ssh/.ssh/config per Tailscale
- [x] **3.4.2** Configurare connessioni automatiche
- [x] **3.4.3** Completare configurazioni SSH

### 3.5 Package Management ✅
- [x] **3.5.1** Creare packages/homebrew/Brewfile completo
- [x] **3.5.2** Organizzare per categorie (dev, apps, fonts, extensions)
- [x] **3.5.3** Includere Mac App Store apps

### 3.6 Installation Automation ✅
- [x] **3.6.1** Creare scripts/install.sh master installer
- [x] **3.6.2** Implementare dry-run e opzioni modulari
- [x] **3.6.3** Aggiungere backup automatico configurazioni esistenti
- [x] **3.6.4** Error handling e logging completo

## FASE 4: Automazione Homebrew e macOS
**Obiettivo**: Automatizzare installazione software e configurazioni sistema

### 4.1 Homebrew Management ✅
- [x] **4.1.1** Creare Brewfile completo da scan sistema
- [x] **4.1.2** Organizzare Brewfile per categorie (dev, apps, fonts)
- [x] **4.1.3** Includere nel master installer
- [ ] **4.1.4** Testing installazione Brewfile

### 4.2 macOS System Configuration
- [ ] **4.2.1** Creare macos/dock.sh (posizione, dimensione, apps)
- [ ] **4.2.2** Creare macos/finder.sh (hidden files, extensions, sidebar)
- [ ] **4.2.3** Creare macos/trackpad.sh (velocità, gesture)
- [ ] **4.2.4** Creare macos/security.sh (firewall, privacy)
- [ ] **4.2.5** Creare macos/energy.sh (sleep, screensaver)
- [ ] **4.2.6** Testing configurazioni macOS

### 4.3 Font & App Management
- [ ] **4.3.1** Setup fonts/ directory per font personalizzati
- [ ] **4.3.2** Script installazione Mac App Store apps
- [ ] **4.3.3** Configurazioni Bitdefender (se automatizzabile)
- [ ] **4.3.4** Testing installazione completa

**🔴 DECISIONE RICHIESTA**: Preferisci screenshots manuali o script automatico per configurazioni macOS?

## FASE 5: Infrastruttura e Development Environment
**Obiettivo**: Integrare con infrastruttura esistente

### 5.1 Project Templates
- [ ] **5.1.1** Migrare boilerplate React/Next.js esistenti
- [ ] **5.1.2** Creare template Python project
- [ ] **5.1.3** Creare template SwiftUI project  
- [ ] **5.1.4** Script generazione progetti da template

### 5.2 Infrastructure Integration
- [ ] **5.2.1** Configurazioni MCP servers (15+ server)
- [ ] **5.2.2** Template environment variables per progetti
- [ ] **5.2.3** Script connessione Mac Studio via Tailscale
- [ ] **5.2.4** Setup Docker environment integrato

### 5.3 Development Environment Recreation
- [ ] **5.3.1** Script ricreazione struttura ~/dev
- [ ] **5.3.2** Automazione clone/sync cartelle principali
- [ ] **5.3.3** Setup workspace Cursor per progetti
- [ ] **5.3.4** Testing environment completo

**🔴 DECISIONE RICHIESTA**: Come gestire sync/clone della struttura ~/dev?

## FASE 6: Testing e Documentazione
**Obiettivo**: Verificare funzionamento e documentare

### 6.1 Master Installation Script ✅
- [x] **6.1.1** Creare scripts/install.sh master installer
- [x] **6.1.2** Integrare tutti gli script in workflow unico
- [x] **6.1.3** Aggiungere logging e error handling
- [ ] **6.1.4** Testing install.sh su sistema pulito

### 6.2 Documentation
- [ ] **6.2.1** Creare docs/system-guide.md (guida completa sistema)
- [ ] **6.2.2** Creare docs/troubleshooting.md (problemi comuni)
- [ ] **6.2.3** Documentare workflow setup nuovo Mac
- [ ] **6.2.4** Creare README.md finale del progetto

### 6.3 Maintenance & Backup
- [ ] **6.3.1** Script backup periodico configurazioni
- [ ] **6.3.2** Health check script per verifiche
- [ ] **6.3.3** Automated testing per install.sh
- [ ] **6.3.4** Procedure sync tra macchine

## Milestone Tracking

### 🎯 Milestone 1: Documentation Complete
**Target**: Fine Fase 1
**Criteri**: Tutta la documentazione base creata, struttura directory pronta

### 🎯 Milestone 2: System Scanned  
**Target**: Fine Fase 2
**Criteri**: Sistema attuale completamente documentato e backed up

### 🎯 Milestone 3: Core Configs Ready
**Target**: Fine Fase 3  
**Criteri**: Configurazioni principali (ZSH, Git, Dev tools) funzionanti

### 🎯 Milestone 4: Automation Complete
**Target**: Fine Fase 4
**Criteri**: Installazione software e configurazioni macOS automatizzate

### 🎯 Milestone 5: Infrastructure Integrated
**Target**: Fine Fase 5
**Criteri**: Integrazione completa con infrastruttura esistente

### 🎯 Milestone 6: Production Ready
**Target**: Fine Fase 6
**Criteri**: Sistema testato e documentato, pronto per uso su nuovo Mac

## Notes & Decisions Log

### Decisioni Confermate
- ✅ **GNU Stow**: Confermato per gestione symlink
- ✅ **Oh My Zsh**: Framework shell preferito
- ✅ **Structure**: packages/ per GNU Stow confirmed

### Decisioni Pending
- 🔴 **Timing scan sistema**: Prima o dopo formattazione?
- 🔴 **macOS configs**: Screenshots vs script automatici?
- 🔴 **~/dev sync**: Strategia sync/clone cartelle development?
- 🔴 **Additional apps**: Altre app che necessitano configurazioni?

---

*Creato*: 2024-12-06  
*Ultima modifica*: 2024-12-14  
*Status*: FASE 3 ✅ completata - FASE 4 🟡 pronta per iniziare