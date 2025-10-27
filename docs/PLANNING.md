# Dotfiles Project - Piano Completo

> **⚠️ NOTE**: This document is from the original project version (pre-refactor 2025-01-17).
>
> **Current active documents**:
> - [TASK.md](TASK.md) - Current task list and project status (**FASE 1 ✅ COMPLETED 2025-10-21**)
> - [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md) - Detailed implementation plan for FASE 1-6
> - [ARCHITECTURE-DECISIONS.md](ARCHITECTURE-DECISIONS.md) - All design decisions
>
> This file is kept for historical reference only.

---

## Obiettivo del Progetto

Creare un sistema completo di dotfiles per macOS che permetta di:

- Automatizzare completamente il setup di un nuovo Mac
- Utilizzare GNU Stow per gestione symlink elegante
- Integrare con l'infrastruttura esistente (Tailscale, Mac Studio, MCP servers)
- Servire come guida definitiva per l'uso del sistema di Matteo Cervelli

## Architettura del Sistema

### Stack Tecnologico

- **Shell**: ZSH + Oh My Zsh
- **Package Manager**: Homebrew + Mac App Store
- **Symlink Manager**: GNU Stow
- **Version Control**: Git con GPG (1Password)
- **Development**: HTML/SCSS, JS/TS, React.js/Next.js, Python, SwiftUI, PostgreSQL
- **Editor**: VS Code + Xcode
- **Infrastructure**: Docker, Tailscale, MCP servers

### Struttura Directory Finale

```bash
dotfiles/
├── packages/               # GNU Stow packages
│   ├── zsh/               # Shell configuration
│   ├── git/               # Git settings + templates
│   ├── ssh/               # SSH config per Tailscale
│   ├── vscode/            # VS Code settings
│   ├── claude/            # Claude Code configuration
│   ├── python/            # Python/pyenv setup
│   ├── node/              # Node.js/nvm setup
│   └── homebrew/          # Brewfile
├── scripts/               # Automation scripts
│   ├── install.sh         # Master installer
│   ├── scan-system.sh     # Pre-format system scan
│   ├── setup-homebrew.sh  # Homebrew automation
│   ├── setup-stow.sh      # GNU Stow management
│   ├── setup-macos.sh     # macOS system preferences
│   └── restore-dev.sh     # ~/dev structure recreation
├── macos/                 # macOS-specific configs
│   ├── defaults.sh        # System defaults via CLI
│   ├── dock.sh           # Dock configuration
│   ├── finder.sh         # Finder preferences
│   └── security.sh       # Privacy/security settings
├── templates/             # Project boilerplates
│   ├── react-project/     # React/Next.js template
│   ├── python-project/    # Python project template
│   └── swift-project/     # SwiftUI project template
├── fonts/                 # Custom fonts
├── screenshots/           # System configuration screenshots
├── backups/              # Backup configurations
└── docs/                 # Documentation
    ├── PLANNING.md       # This file
    ├── TASK.md          # Task tracking
    ├── system-guide.md   # Complete system guide
    └── troubleshooting.md # Common issues
```

## Fasi di Implementazione

### FASE 1: Setup Documentazione e Struttura ✅

**Obiettivo**: Creare base documentale e struttura directory

- [x] Creare docs/PLANNING.md
- [x] Creare docs/TASK.md  
- [x] Creare struttura directory completa
- [x] Aggiornare CLAUDE.md

### FASE 2: Scansione Sistema Attuale ✅

**Obiettivo**: Documentare configurazione esistente prima della formattazione

- [x] Script scan Homebrew (`brew list`, `brew list --cask`, `mas list`)
- [x] Script scan NPM globals e Python packages
- [x] Backup configurazioni shell esistenti (.zshrc, .zsh_aliases, zsh_plugins)
- [x] Screenshot configurazioni macOS (Dock, Finder, System Preferences) - Completato e documentato in docs/screenshot-list-exact.md
- [x] Documentare struttura ~/dev per replica
- [x] Backup chiavi SSH e configurazioni Tailscale
- [x] Creato documento preferences-analysis.md con analisi dettagliata screenshot
- [x] Identificate priorità per implementazione configurazioni

### FASE 3: Configurazioni Core con GNU Stow ✅

**Obiettivo**: Implementare configurazioni principali

- [x] packages/zsh/ - Oh My Zsh + aliases + functions personalizzate
- [x] packages/git/ - .gitconfig + .gitignore_global + templates PR/commit
- [x] stow-packages/vscode/ - Configurazioni VS Code (settings.json, keybindings.json, extensions.txt)
- [x] packages/python/ - pyenv + pip configurations (.pyenvrc, .pythonrc, pip.conf)
- [x] packages/node/ - nvm + npm configurations (.nvmrc, .npmrc, .nvmsh)
- [x] packages/ssh/ - SSH config per rete Tailscale
- [x] packages/homebrew/ - Brewfile completo con tutte le categorie
- [x] scripts/install.sh - Script di installazione master completo
- [x] packages/1password/ - 1Password CLI configuration (moved to FASE 1)

**Note**: packages/llm-tools (Claude Code e MCP) è stato spostato a FASE 4 per meglio allinearsi con le configurazioni applicazioni.

### FASE 4: Automazione Homebrew e macOS 🟡 READY TO START

**Obiettivo**: Automatizzare installazione software e configurazioni sistema

- [x] Brewfile completo basato su scan sistema
- [ ] Script macOS defaults (Dock, Finder, Trackpad, etc.)
- [ ] Integrazione Tailscale automatica
- [ ] Font management per font personalizzati
- [ ] Mac App Store automation
- [ ] Configurazioni Bitdefender/security

**DECISIONE RICHIESTA**: Preferisci screenshots manuali o script automatico per configurazioni macOS?

### FASE 5: Infrastruttura e Development Environment

**Obiettivo**: Integrare con infrastruttura esistente

- [ ] Template progetti con boilerplate esistenti
- [ ] packages/llm-tools/ - Configurazioni Claude Code e MCP (spostato da FASE 3)
- [ ] Configurazioni complete per 15+ MCP servers
- [ ] Environment variables template per progetti
- [ ] Script ricreazione struttura ~/dev
- [ ] Integrazione con Mac Studio via Tailscale
- [ ] Setup Docker environment

**DECISIONE RICHIESTA**: Come gestire sync/clone della struttura ~/dev?

### FASE 6: Testing e Documentazione

**Obiettivo**: Verificare funzionamento e documentare

- [ ] Guida completa sistema in docs/
- [ ] Testing install.sh su sistema pulito
- [ ] Troubleshooting guide comuni
- [ ] Backup/restore procedures
- [ ] Workflow per setup nuovo Mac

## Decisioni Tecniche Chiave

### GNU Stow vs Script Tradizionali

**Decisione**: Utilizzare GNU Stow per gestione symlink elegante
**Motivo**: Permette gestione modulare e sicura dei dotfiles

### Struttura Package

**Decisione**: Un package per ogni tool/applicazione
**Benefici**: Modularità, possibilità di enable/disable selettivo

### Brewfile vs Script Separati

**Decisione**: Brewfile unico con categorie commentate
**Benefici**: Gestione centralizzata, backup semplice

### Screenshots vs Automation

**Da decidere**: Approccio per configurazioni macOS GUI

## Integration Points

### Con Infrastruttura Esistente

- **Mac Studio**: Accesso via Tailscale, sync cartelle development
- **MCP Servers**: Configurazioni per 15+ server esistenti  
- **Docker Environment**: Integrazione con stack container esistente
- **Backup Strategy**: 3-tier backup (Time Machine, iCloud, NAS)

### Con Workflow Sviluppo

- **Project Templates**: Integrazione boilerplate esistenti
- **Git Workflow**: Templates PR/commit/issues
- **Environment Management**: .env template per progetti
- **IDE Integration**: VS Code + Xcode configurations

## Maintenance Strategy

### Aggiornamenti Regolari

- Sync configurazioni tra macchine via git
- Update Brewfile con nuovi package
- Backup periodico configurazioni

### Monitoring

- Health check script per verificare configurazioni
- Alert per configurazioni drift
- Automated testing install.sh

## Next Steps Immediati

1. **Completare setup documentazione**
2. **Decidere timing scansione sistema attuale**
3. **Creare struttura directory base**
4. **Iniziare implementazione packages/zsh/**

---

*Ultimo aggiornamento: 2024-12-14*  
*Progetto: TMP-dotfiles*  
*Owner: Matteo Cervelli*  
*Status: FASE 3 ✅ completata - FASE 4 🟡 pronta per iniziare*
