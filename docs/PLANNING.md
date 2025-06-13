# Dotfiles Project - Piano Completo

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
- **Editor**: Cursor (VS Code based) + Xcode
- **Infrastructure**: Docker, Tailscale, MCP servers

### Struttura Directory Finale
```
dotfiles/
├── packages/               # GNU Stow packages
│   ├── zsh/               # Shell configuration
│   ├── git/               # Git settings + templates
│   ├── ssh/               # SSH config per Tailscale
│   ├── cursor/            # Cursor/VS Code settings
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
- [ ] Creare docs/TASK.md  
- [ ] Creare struttura directory completa
- [ ] Aggiornare CLAUDE.md

### FASE 2: Scansione Sistema Attuale (PRE-FORMAT)
**Obiettivo**: Documentare configurazione esistente prima della formattazione
- [ ] Script scan Homebrew (`brew list`, `brew list --cask`, `mas list`)
- [ ] Script scan NPM globals e Python packages
- [ ] Backup configurazioni shell esistenti (.zshrc, .zsh_aliases, zsh_plugins)
- [ ] Screenshot configurazioni macOS (Dock, Finder, System Preferences)
- [ ] Documentare struttura ~/dev per replica
- [ ] Backup chiavi SSH e configurazioni Tailscale

**DECISIONE RICHIESTA**: Quando facciamo la scansione? Prima di formattare o usando sistema attuale?

### FASE 3: Configurazioni Core con GNU Stow
**Obiettivo**: Implementare configurazioni principali
- [ ] packages/zsh/ - Oh My Zsh + aliases + functions personalizzate
- [ ] packages/git/ - .gitconfig + .gitignore_global + templates PR/commit
- [ ] packages/cursor/ - Configurazioni Cursor/VS Code
- [ ] packages/claude/ - Configurazioni Claude Code e MCP
- [ ] packages/python/ - pyenv + pip configurations
- [ ] packages/node/ - nvm + npm configurations
- [ ] packages/ssh/ - SSH config per rete Tailscale

**DECISIONE RICHIESTA**: Quali altre app necessitano configurazioni specifiche?

### FASE 4: Automazione Homebrew e macOS
**Obiettivo**: Automatizzare installazione software e configurazioni sistema
- [ ] Brewfile completo basato su scan sistema
- [ ] Script macOS defaults (Dock, Finder, Trackpad, etc.)
- [ ] Integrazione Tailscale automatica
- [ ] Font management per font personalizzati
- [ ] Mac App Store automation
- [ ] Configurazioni Bitdefender/security

**DECISIONE RICHIESTA**: Preferisci screenshots manuali o script automatico per configurazioni macOS?

### FASE 5: Infrastruttura e Development Environment  
**Obiettivo**: Integrare con infrastruttura esistente
- [ ] Template progetti con boilerplate esistenti
- [ ] Configurazioni MCP servers
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
- **IDE Integration**: Cursor + Xcode configurations

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

*Ultimo aggiornamento: 2024-12-06*  
*Progetto: TMP-dotfiles*  
*Owner: Matteo Cervelli*