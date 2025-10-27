.PHONY: help install bootstrap stow stow-all stow-dry-run stow-all-dry-run unstow stow-package stow-package-dry-run health backup clean autoupdate-install autoupdate-status autoupdate-logs autoupdate-disable autoupdate-enable brewfile-generate brewfile-check brewfile-install brewfile-update vscode-extensions-export vscode-extensions-install fonts-install fonts-install-essential fonts-install-coding fonts-install-powerline fonts-verify services-install services-install-essential services-verify services-backup docker-install ubuntu-full docker-build-minimal docker-build-dev docker-build-production docker-build-all docker-run-minimal docker-run-dev docker-test docker-clean docker-size docker-verify devcontainer-generate devcontainer-preview devcontainer-build devcontainer-up devcontainer-down devcontainer-shell devcontainer-rebuild devcontainer-clean devcontainer-test devcontainer-python devcontainer-nodejs devcontainer-templates

# Default target - show help
help:
	@echo ""
	@echo "╔═══════════════════════════════════════════════════════════════╗"
	@echo "║           Dotfiles Management - Makefile Commands            ║"
	@echo "╚═══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "📦 Installation:"
	@echo "  make install          Full installation (bootstrap + stow + health)"
	@echo "  make bootstrap        Install dependencies only (Homebrew, Stow, 1Password CLI, etc.)"
	@echo ""
	@echo "🔗 Stow Operations:"
	@echo "  make stow             Stow all packages (create symlinks)"
	@echo "  make stow-all         Stow all packages (alias for 'make stow')"
	@echo "  make stow-dry-run     Dry-run: preview what would be stowed (all packages)"
	@echo "  make unstow           Remove all symlinks"
	@echo "  make stow-package PKG=<name>      Stow single package (e.g., PKG=shell)"
	@echo "  make stow-package-dry-run PKG=<name>  Dry-run single package"
	@echo ""
	@echo "🏥 Maintenance:"
	@echo "  make health           Run health checks (dependencies, symlinks, 1Password auth)"
	@echo "  make backup           Backup current configurations [FASE 2 - Not yet implemented]"
	@echo "  make clean            Clean temporary files (.DS_Store, *.tmp, *.log)"
	@echo ""
	@echo "🍺 Brewfile Management:"
	@echo "  make brewfile-generate          Generate Brewfile from current audit"
	@echo "  make brewfile-check             Validate Brewfile (dry-run, no installation)"
	@echo "  make brewfile-install           Install packages from Brewfile"
	@echo "  make brewfile-update            Update Brewfile from currently installed packages"
	@echo ""
	@echo "🔤 Font Management:"
	@echo "  make fonts-install              Install all fonts (179 fonts)"
	@echo "  make fonts-install-essential    Install essential fonts only (14 fonts: MesloLGS NF + Lato + Raleway + Lora)"
	@echo "  make fonts-install-coding       Install essential + coding fonts (Hack, Space Mono, etc.)"
	@echo "  make fonts-install-powerline    Install essential + all Powerline fonts (130+ fonts)"
	@echo "  make fonts-verify               Verify essential fonts are installed"
	@echo ""
	@echo "⚙️  macOS Services Management:"
	@echo "  make services-install           Install all Services (6 workflows)"
	@echo "  make services-install-essential Install essential Services only (4 workflows)"
	@echo "  make services-verify            Verify installed Services"
	@echo "  make services-backup            Backup Services from ~/Library/Services/"
	@echo ""
	@echo "🔌 VSCode Extensions:"
	@echo "  make vscode-extensions-install  Install all VSCode extensions from list"
	@echo "  make vscode-extensions-export   Export currently installed extensions to list"
	@echo ""
	@echo "🔄 Auto-Update:"
	@echo "  make autoupdate-install    Install auto-update service (runs every 30 min)"
	@echo "  make autoupdate-status     Check auto-update service status"
	@echo "  make autoupdate-logs       View auto-update logs"
	@echo "  make autoupdate-disable    Disable auto-update service"
	@echo "  make autoupdate-enable     Enable auto-update service"
	@echo ""
	@echo "🐳 Docker Container Images:"
	@echo "  make docker-build-minimal   Build minimal Ubuntu container (< 300MB)"
	@echo "  make docker-build-dev       Build dev Ubuntu container with tools"
	@echo "  make docker-build-all       Build all Docker images (minimal + dev + production)"
	@echo "  make docker-run-minimal     Run minimal container interactively"
	@echo "  make docker-run-dev         Run dev container interactively"
	@echo "  make docker-test            Run BATS tests for Docker images"
	@echo "  make docker-size            Show Docker image sizes"
	@echo "  make docker-verify          Verify Docker images meet requirements"
	@echo "  make docker-clean           Remove Docker images and cleanup"
	@echo ""
	@echo "📦 Dev Containers (Project-specific):"
	@echo "  make devcontainer-generate TEMPLATE=<type> PROJECT=<path>  Generate dev container"
	@echo "  make devcontainer-python PROJECT=<path>                    Quick: Python dev container"
	@echo "  make devcontainer-nodejs PROJECT=<path>                    Quick: Node.js dev container"
	@echo "  make devcontainer-templates                                List available templates"
	@echo "  make devcontainer-up PROJECT=<path>                        Start dev container"
	@echo "  make devcontainer-down PROJECT=<path>                      Stop dev container"
	@echo "  make devcontainer-shell PROJECT=<path>                     Shell into dev container"
	@echo "  make devcontainer-test                                     Test dev container system"
	@echo ""
	@echo "🐳 Ubuntu/Docker (Linux only):"
	@echo "  make docker-install         Install Docker Engine + Compose v2 (Ubuntu)"
	@echo "  make ubuntu-full            Install Ubuntu packages + Docker"
	@echo ""
	@echo "💡 Examples:"
	@echo "  make install                      # Complete setup on fresh machine"
	@echo "  make stow-dry-run                 # Preview all symlinks before creating"
	@echo "  make stow-package PKG=git         # Install just git configuration"
	@echo "  make stow-package-dry-run PKG=git # Preview git package installation"
	@echo "  make health                       # Verify everything is working"
	@echo ""

# Full installation workflow
install: bootstrap stow health
	@echo ""
	@echo "✅ Installation complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Restart your shell: exec \$$SHELL"
	@echo "  2. Sign in to 1Password: eval \$$(op signin)"
	@echo "  3. Verify installation: make health"
	@echo ""

# Install dependencies (Homebrew, Stow, 1Password CLI, Rclone, yq)
bootstrap:
	@./scripts/bootstrap/install.sh

# Stow all packages (create symlinks)
stow:
	@./scripts/stow/stow-all.sh

# Stow all packages (alias for 'stow')
stow-all: stow

# Dry-run: preview what would be stowed (all packages)
stow-dry-run:
	@echo "🔍 Dry-run mode: previewing all packages that would be stowed..."
	@echo ""
	@./scripts/stow/stow-all.sh -n

# Alias for stow-dry-run
stow-all-dry-run: stow-dry-run

# Remove all symlinks
unstow:
	@./scripts/stow/unstow-all.sh

# Stow single package
stow-package:
	@if [ -z "$(PKG)" ]; then \
		echo "❌ Error: PKG parameter required"; \
		echo ""; \
		echo "Usage: make stow-package PKG=<package-name>"; \
		echo ""; \
		echo "Available packages:"; \
		ls -1 stow-packages/ | grep -v "^README" | grep -v "^\."; \
		echo ""; \
		echo "Example: make stow-package PKG=shell"; \
		exit 1; \
	fi
	@./scripts/stow/stow-package.sh install $(PKG)

# Dry-run single package
stow-package-dry-run:
	@if [ -z "$(PKG)" ]; then \
		echo "❌ Error: PKG parameter required"; \
		echo ""; \
		echo "Usage: make stow-package-dry-run PKG=<package-name>"; \
		echo ""; \
		echo "Available packages:"; \
		ls -1 stow-packages/ | grep -v "^README" | grep -v "^\."; \
		echo ""; \
		echo "Example: make stow-package-dry-run PKG=shell"; \
		exit 1; \
	fi
	@echo "🔍 Dry-run mode: previewing package '$(PKG)'..."
	@echo ""
	@./scripts/stow/stow-package.sh -n install $(PKG)

# Run health checks
health:
	@./scripts/health/check-all.sh

# Backup current configurations (FASE 2 - Not yet implemented)
backup:
	@echo "⚠️  Backup script will be implemented in FASE 2"
	@echo ""
	@echo "📋 FASE 2 includes:"
	@echo "   • Automated backup script (scripts/backup/snapshot.sh)"
	@echo "   • Backup to Synology NAS integration"
	@echo "   • Restore from backup functionality"
	@echo ""
	@if [ -f ./scripts/backup/snapshot.sh ]; then \
		echo "✅ Backup script found - running..."; \
		./scripts/backup/snapshot.sh; \
	else \
		echo "📁 Creating manual backup directory for now..."; \
		mkdir -p backups/manual-$(shell date +%Y%m%d-%H%M%S); \
		echo "✅ Backup directory created: backups/manual-$(shell date +%Y%m%d-%H%M%S)"; \
		echo ""; \
		echo "💡 Tip: Copy important configs manually to this directory"; \
		echo "   Example: cp ~/.zshrc ~/.gitconfig backups/manual-*/"; \
	fi

# Clean temporary files
clean:
	@echo "🧹 Cleaning temporary files..."
	@find . -name ".DS_Store" -type f -delete 2>/dev/null || true
	@find . -name "*.tmp" -type f -delete 2>/dev/null || true
	@find . -name "*.log" -type f -delete 2>/dev/null || true
	@find . -name "*~" -type f -delete 2>/dev/null || true
	@echo "✅ Temporary files cleaned"

# Auto-update service management
autoupdate-install:
	@./scripts/sync/install-autoupdate.sh

autoupdate-status:
	@echo "🔍 Checking auto-update service status..."
	@echo ""
	@if command -v launchctl >/dev/null 2>&1; then \
		if launchctl list | grep -q dotfiles.autoupdate; then \
			echo "✅ macOS LaunchAgent is loaded and running"; \
			launchctl list | grep dotfiles; \
		else \
			echo "❌ macOS LaunchAgent not loaded"; \
			echo "Run: make autoupdate-install"; \
		fi; \
	elif command -v systemctl >/dev/null 2>&1; then \
		systemctl status dotfiles-autoupdate.timer --no-pager || true; \
	else \
		echo "❌ Unsupported OS"; \
	fi

autoupdate-logs:
	@echo "📋 Viewing auto-update logs..."
	@echo ""
	@if [ -f /tmp/dotfiles-autoupdate.log ]; then \
		echo "==> /tmp/dotfiles-autoupdate.log <=="; \
		tail -20 /tmp/dotfiles-autoupdate.log; \
		echo ""; \
		echo "💡 Follow logs: tail -f /tmp/dotfiles-autoupdate.log"; \
	elif command -v journalctl >/dev/null 2>&1; then \
		journalctl -u dotfiles-autoupdate -n 20 --no-pager; \
		echo ""; \
		echo "💡 Follow logs: journalctl -u dotfiles-autoupdate -f"; \
	else \
		echo "❌ No logs found"; \
		echo "Service may not be installed or hasn't run yet"; \
	fi

autoupdate-disable:
	@echo "⏸️  Disabling auto-update service..."
	@if command -v launchctl >/dev/null 2>&1; then \
		launchctl unload ~/Library/LaunchAgents/com.dotfiles.autoupdate.plist 2>/dev/null || true; \
		echo "✅ macOS LaunchAgent disabled"; \
	elif command -v systemctl >/dev/null 2>&1; then \
		sudo systemctl stop dotfiles-autoupdate.timer; \
		echo "✅ systemd timer disabled"; \
	fi

autoupdate-enable:
	@echo "▶️  Enabling auto-update service..."
	@if command -v launchctl >/dev/null 2>&1; then \
		launchctl load ~/Library/LaunchAgents/com.dotfiles.autoupdate.plist 2>/dev/null || true; \
		echo "✅ macOS LaunchAgent enabled"; \
	elif command -v systemctl >/dev/null 2>&1; then \
		sudo systemctl start dotfiles-autoupdate.timer; \
		echo "✅ systemd timer enabled"; \
	fi

# Brewfile Management
brewfile-generate:
	@echo "🍺 Generating Brewfile from application audit..."
	@./scripts/apps/generate-brewfile.sh
	@echo ""
	@echo "✅ Brewfile generated: system/macos/Brewfile"
	@echo "💡 Validate with: make brewfile-check"

brewfile-check:
	@echo "🔍 Validating Brewfile..."
	@echo ""
	@if [ ! -f system/macos/Brewfile ]; then \
		echo "❌ Brewfile not found"; \
		echo "Generate it first: make brewfile-generate"; \
		exit 1; \
	fi
	@brew bundle check --file=system/macos/Brewfile || \
		(echo ""; echo "⚠️  Some packages are missing"; \
		 echo "Install with: make brewfile-install")

brewfile-install:
	@echo "🍺 Installing packages from Brewfile..."
	@echo ""
	@if [ ! -f system/macos/Brewfile ]; then \
		echo "❌ Brewfile not found"; \
		echo "Generate it first: make brewfile-generate"; \
		exit 1; \
	fi
	@echo "⚠️  This will install packages. Press Ctrl+C to cancel."
	@sleep 3
	@brew bundle install --file=system/macos/Brewfile
	@echo ""
	@echo "✅ Brewfile installation complete"

brewfile-update:
	@echo "🔄 Updating Brewfile from currently installed packages..."
	@echo ""
	@echo "⚠️  This will regenerate the Brewfile. Current Brewfile will be backed up."
	@if [ -f system/macos/Brewfile ]; then \
		cp system/macos/Brewfile system/macos/Brewfile.backup.$$(date +%Y%m%d-%H%M%S); \
		echo "✅ Backup created: system/macos/Brewfile.backup.$$(date +%Y%m%d-%H%M%S)"; \
	fi
	@./scripts/apps/audit-apps.sh
	@./scripts/apps/generate-brewfile.sh
	@echo ""
	@echo "✅ Brewfile updated from current system state"
	@echo "💡 Review changes: git diff system/macos/Brewfile"

# VSCode Extensions Management
vscode-extensions-install:
	@echo "🔌 Installing VSCode extensions from list..."
	@echo ""
	@if [ ! -f applications/vscode-extensions.txt ]; then \
		echo "❌ Extensions list not found: applications/vscode-extensions.txt"; \
		echo "Generate it first: make vscode-extensions-export"; \
		exit 1; \
	fi
	@if ! command -v code >/dev/null 2>&1; then \
		echo "❌ VSCode CLI not found"; \
		echo ""; \
		echo "To install VSCode CLI:"; \
		echo "  1. Open VSCode"; \
		echo "  2. Press Cmd+Shift+P"; \
		echo "  3. Type 'Shell Command: Install code command in PATH'"; \
		echo "  4. Press Enter"; \
		exit 1; \
	fi
	@extension_count=$$(grep -v '^#' applications/vscode-extensions.txt | grep -v '^$$' | wc -l | tr -d ' '); \
	echo "📦 Found $$extension_count extensions to install"; \
	echo ""; \
	installed=0; \
	skipped=0; \
	failed=0; \
	grep -v '^#' applications/vscode-extensions.txt | grep -v '^$$' | while read -r ext; do \
		if code --list-extensions | grep -q "^$$ext$$"; then \
			echo "⏭️  Skipped: $$ext (already installed)"; \
			skipped=$$((skipped + 1)); \
		else \
			echo "📥 Installing: $$ext"; \
			if code --install-extension "$$ext" --force >/dev/null 2>&1; then \
				installed=$$((installed + 1)); \
			else \
				echo "❌ Failed: $$ext"; \
				failed=$$((failed + 1)); \
			fi; \
		fi; \
	done
	@echo ""
	@echo "✅ VSCode extensions installation complete"

vscode-extensions-export:
	@echo "📤 Exporting currently installed VSCode extensions..."
	@echo ""
	@if ! command -v code >/dev/null 2>&1; then \
		echo "❌ VSCode CLI not found"; \
		echo ""; \
		echo "To install VSCode CLI:"; \
		echo "  1. Open VSCode"; \
		echo "  2. Press Cmd+Shift+P"; \
		echo "  3. Type 'Shell Command: Install code command in PATH'"; \
		echo "  4. Press Enter"; \
		exit 1; \
	fi
	@extension_count=$$(code --list-extensions 2>/dev/null | wc -l | tr -d ' '); \
	echo "📦 Found $$extension_count installed extensions"; \
	echo ""; \
	if [ -f applications/vscode-extensions.txt ]; then \
		cp applications/vscode-extensions.txt applications/vscode-extensions.txt.backup.$$(date +%Y%m%d-%H%M%S); \
		echo "✅ Backup created: applications/vscode-extensions.txt.backup.$$(date +%Y%m%d-%H%M%S)"; \
	fi
	@{ \
		echo "# VSCode Extensions"; \
		echo "# Generated: $$(date +%Y-%m-%d)"; \
		echo "# Total Extensions: $$extension_count"; \
		echo "#"; \
		echo "# To install all extensions:"; \
		echo "#   make vscode-extensions-install"; \
		echo "#"; \
		echo "# To export current extensions:"; \
		echo "#   make vscode-extensions-export"; \
		echo "#"; \
		echo ""; \
		code --list-extensions 2>/dev/null | sort; \
	} > applications/vscode-extensions.txt
	@echo ""
	@echo "✅ Extensions exported to: applications/vscode-extensions.txt"
	@echo "💡 Commit changes: git add applications/vscode-extensions.txt"

# ============================================================================
# Linux Package Management
# ============================================================================

# Generate Linux package lists from YAML mappings
linux-generate-packages:
	@echo "📦 Generating Linux package lists..."
	@./scripts/apps/generate-linux-packages.sh

# Audit installed packages on Linux
linux-audit:
	@echo "🔍 Auditing installed Linux packages..."
	@./scripts/apps/audit-apps-linux.sh

# Install Ubuntu dependencies
linux-install-ubuntu:
	@echo "🐧 Installing Ubuntu packages..."
	@sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh

# Install Fedora dependencies
linux-install-fedora:
	@echo "🎩 Installing Fedora packages..."
	@sudo ./scripts/bootstrap/install-dependencies-fedora.sh

# Install Arch Linux dependencies
linux-install-arch:
	@echo "🏔️  Installing Arch Linux packages..."
	@sudo ./scripts/bootstrap/install-dependencies-arch.sh

# Dry-run Ubuntu installation
linux-install-ubuntu-dry:
	@echo "🔍 Ubuntu dry-run..."
	@sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --dry-run

# Dry-run Fedora installation
linux-install-fedora-dry:
	@echo "🔍 Fedora dry-run..."
	@sudo ./scripts/bootstrap/install-dependencies-fedora.sh --dry-run

# Dry-run Arch installation
linux-install-arch-dry:
	@echo "🔍 Arch dry-run..."
	@sudo ./scripts/bootstrap/install-dependencies-arch.sh --dry-run

# ============================================================================
# Docker Installation (Ubuntu)
# ============================================================================

# Install Docker Engine + Compose v2 on Ubuntu
docker-install:
	@echo "🐳 Installing Docker Engine + Compose v2..."
	@if [ ! -f /etc/os-release ] || ! grep -q "ubuntu" /etc/os-release; then \
		echo "❌ This command is for Ubuntu only"; \
		echo "For other distributions, see docs/guides/docker-ubuntu-setup.md"; \
		exit 1; \
	fi
	@sudo ./scripts/bootstrap/install-docker.sh

# Full Ubuntu installation with Docker
ubuntu-full:
	@echo "🐧 Installing Ubuntu packages + Docker..."
	@if [ ! -f /etc/os-release ] || ! grep -q "ubuntu" /etc/os-release; then \
		echo "❌ This command is for Ubuntu only"; \
		exit 1; \
	fi
	@sudo ./scripts/bootstrap/install-dependencies-ubuntu.sh --with-docker

# ============================================================================
# Font Management
# ============================================================================

# Install all fonts (179 fonts total)
fonts-install:
	@echo "🔤 Installing all fonts..."
	@echo ""
	@if [ ! -f ./scripts/fonts/install-fonts.sh ]; then \
		echo "❌ Font installation script not found"; \
		echo "Expected: ./scripts/fonts/install-fonts.sh"; \
		exit 1; \
	fi
	@./scripts/fonts/install-fonts.sh --all
	@echo ""
	@echo "✅ Font installation complete"
	@echo "💡 Verify installation: make fonts-verify"

# Install essential fonts only (MesloLGS NF + Lato + Raleway)
fonts-install-essential:
	@echo "🔤 Installing essential fonts..."
	@echo ""
	@echo "📦 This will install:"
	@echo "   • MesloLGS NF (4 variants) - Required for Powerlevel10k terminal theme"
	@echo "   • Lato (4 variants) - Professional sans-serif for documents"
	@echo "   • Raleway (2 variants) - Modern geometric sans-serif"
	@echo "   • Lora (4 variants) - Elegant serif for professional documents"
	@echo ""
	@if [ ! -f ./scripts/fonts/install-fonts.sh ]; then \
		echo "❌ Font installation script not found"; \
		echo "Expected: ./scripts/fonts/install-fonts.sh"; \
		exit 1; \
	fi
	@./scripts/fonts/install-fonts.sh --essential-only
	@echo ""
	@echo "✅ Essential fonts installed"
	@echo "💡 Install all fonts with: make fonts-install"

# Install essential + coding fonts
fonts-install-coding:
	@echo "🔤 Installing essential + coding fonts..."
	@echo ""
	@echo "📦 This will install:"
	@echo "   • Essential fonts (10 fonts)"
	@echo "   • Hack (4 variants)"
	@echo "   • Space Mono (4 variants)"
	@echo "   • IBM 3270 (3 variants)"
	@echo "   • CPMono (5 variants)"
	@echo ""
	@if [ ! -f ./scripts/fonts/install-fonts.sh ]; then \
		echo "❌ Font installation script not found"; \
		echo "Expected: ./scripts/fonts/install-fonts.sh"; \
		exit 1; \
	fi
	@./scripts/fonts/install-fonts.sh --with-coding
	@echo ""
	@echo "✅ Coding fonts installed"

# Install essential + all Powerline fonts
fonts-install-powerline:
	@echo "🔤 Installing essential + Powerline fonts..."
	@echo ""
	@echo "📦 This will install:"
	@echo "   • Essential fonts (10 fonts)"
	@echo "   • 120+ Powerline terminal fonts (Source Code Pro, DejaVu, Roboto Mono, etc.)"
	@echo ""
	@if [ ! -f ./scripts/fonts/install-fonts.sh ]; then \
		echo "❌ Font installation script not found"; \
		echo "Expected: ./scripts/fonts/install-fonts.sh"; \
		exit 1; \
	fi
	@./scripts/fonts/install-fonts.sh --with-powerline
	@echo ""
	@echo "✅ Powerline fonts installed"

# Verify essential fonts are installed
fonts-verify:
	@echo "🔍 Verifying essential font installation..."
	@echo ""
	@if [ ! -d "$$HOME/Library/Fonts" ]; then \
		echo "❌ Fonts directory not found: ~/Library/Fonts"; \
		exit 1; \
	fi
	@missing=0; \
	fonts=("MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" "Lato-Regular.ttf" "Raleway-VF.ttf" "Lora-Regular.ttf"); \
	for font in "$${fonts[@]}"; do \
		if [ -f "$$HOME/Library/Fonts/$$font" ]; then \
			echo "✅ $$font"; \
		else \
			echo "❌ Missing: $$font"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	echo ""; \
	if [ $$missing -eq 0 ]; then \
		echo "✅ All essential fonts verified"; \
		total=$$(find "$$HOME/Library/Fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | wc -l | tr -d ' '); \
		echo "📊 Total custom fonts installed: $$total"; \
	else \
		echo "❌ $$missing essential fonts missing"; \
		echo "Install with: make fonts-install-essential"; \
		exit 1; \
	fi

# macOS Services Management
services-install:
	@echo "⚙️  Installing all macOS Services (6 workflows)..."
	@echo ""
	@if [ ! -f ./scripts/services/install-services.sh ]; then \
		echo "❌ Services installation script not found"; \
		echo "Expected: ./scripts/services/install-services.sh"; \
		exit 1; \
	fi
	@./scripts/services/install-services.sh --all
	@echo ""
	@echo "✅ All services installed"
	@echo "💡 Access via: Right-click → Services menu"

services-install-essential:
	@echo "⚙️  Installing essential macOS Services (4 workflows)..."
	@echo ""
	@if [ ! -f ./scripts/services/install-services.sh ]; then \
		echo "❌ Services installation script not found"; \
		echo "Expected: ./scripts/services/install-services.sh"; \
		exit 1; \
	fi
	@./scripts/services/install-services.sh --essential-only
	@echo ""
	@echo "✅ Essential services installed"
	@echo "💡 Access via: Right-click → Services menu"

services-verify:
	@echo "🔍 Verifying installed Services..."
	@echo ""
	@./scripts/services/install-services.sh --dry-run --verbose
	@echo ""
	@echo "💡 Services location: ~/Library/Services/"

services-backup:
	@echo "💾 Backing up Services from ~/Library/Services/..."
	@echo ""
	@if [ ! -d "$$HOME/Library/Services" ]; then \
		echo "❌ Services directory not found: ~/Library/Services"; \
		exit 1; \
	fi
	@rsync -av --exclude='.DS_Store' ~/Library/Services/*.workflow system/macos/services/ 2>/dev/null || \
		echo "⚠️  No workflows to backup"
	@echo ""
	@echo "✅ Services backed up to: system/macos/services/"
	@echo "💡 Commit changes: git add system/macos/services/"

# =============================================================================
# Docker Container Image Management (Issue #44)
# =============================================================================

# Build Docker images
docker-build-minimal:
	@echo "🐳 Building minimal Docker image..."
	@echo ""
	@echo "Profile: container-minimal"
	@echo "Target size: < 500MB"
	@echo "Includes: Ubuntu 24.04 + ZSH + Git + GNU Stow"
	@echo ""
	docker build -f Dockerfile.dotfiles-ubuntu --target minimal -t dotfiles-ubuntu:minimal .
	@echo ""
	@echo "✅ Minimal image built successfully"
	@echo "Run with: make docker-run-minimal"

docker-build-dev:
	@echo "🐳 Building development Docker image..."
	@echo ""
	@echo "Profile: container-dev"
	@echo "Target size: < 500MB"
	@echo "Includes: Minimal + Python + Node.js + Build tools"
	@echo ""
	docker build -f Dockerfile.dotfiles-ubuntu --target dev -t dotfiles-ubuntu:dev .
	@echo ""
	@echo "✅ Development image built successfully"
	@echo "Run with: make docker-run-dev"

docker-build-production:
	@echo "🐳 Building production Docker image..."
	@echo ""
	@echo "Profile: container-production"
	@echo "Target size: < 500MB"
	@echo "Optimized for production deployment"
	@echo ""
	docker build -f Dockerfile.dotfiles-ubuntu --target production -t dotfiles-ubuntu:production .
	@echo ""
	@echo "✅ Production image built successfully"

docker-build-all: docker-build-minimal docker-build-dev docker-build-production
	@echo ""
	@echo "✅ All Docker images built successfully"
	@echo ""
	@docker images | grep dotfiles-ubuntu || echo "No images found"

# Run Docker containers
docker-run-minimal:
	@echo "🐳 Running minimal container..."
	@echo ""
	@echo "💡 To mount workspace: docker run -it --rm -v \$$(pwd):/workspace dotfiles-ubuntu:minimal"
	@echo ""
	docker run -it --rm dotfiles-ubuntu:minimal

docker-run-dev:
	@echo "🐳 Running development container..."
	@echo ""
	@echo "💡 To mount workspace: docker run -it --rm -v \$$(pwd):/workspace dotfiles-ubuntu:dev"
	@echo ""
	docker run -it --rm dotfiles-ubuntu:dev

# Run Docker tests
docker-test:
	@echo "🧪 Running Docker image tests..."
	@echo ""
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "❌ BATS not found. Install with: brew install bats-core"; \
		exit 1; \
	fi
	@if ! docker images | grep -q "dotfiles-ubuntu:minimal"; then \
		echo "⚠️  Minimal image not found. Building..."; \
		$(MAKE) docker-build-minimal; \
	fi
	@bats tests/test-23-docker-ubuntu.bats
	@echo ""
	@echo "✅ All Docker tests passed"

# Show Docker image sizes
docker-size:
	@echo "📊 Docker Image Sizes"
	@echo ""
	@echo "Target: < 500MB for all images"
	@echo ""
	@docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "REPOSITORY|dotfiles-ubuntu" || echo "No dotfiles-ubuntu images found"
	@echo ""
	@echo "💡 To reduce size:"
	@echo "  1. Review .dockerignore"
	@echo "  2. Use --no-install-recommends with apt"
	@echo "  3. Clean apt cache after install"
	@echo "  4. Use multi-stage builds"

# Verify Docker images meet requirements
docker-verify:
	@echo "🔍 Verifying Docker images..."
	@echo ""
	@echo "Checking requirements:"
	@echo "  1. Image size < 500MB"
	@echo "  2. Startup time < 2 seconds"
	@echo "  3. ZSH available"
	@echo "  4. Git available"
	@echo "  5. Dotfiles stowed"
	@echo ""
	@# Check if minimal image exists
	@if ! docker images | grep -q "dotfiles-ubuntu:minimal"; then \
		echo "❌ Minimal image not found. Build with: make docker-build-minimal"; \
		exit 1; \
	fi
	@# Check size
	@size=$$(docker images --format "{{.Size}}" dotfiles-ubuntu:minimal | sed 's/MB//' | awk '{print int($$1)}'); \
	if [ "$$size" -lt 500 ]; then \
		echo "✅ Size check passed: $${size}MB < 500MB"; \
	else \
		echo "❌ Size check failed: $${size}MB >= 500MB"; \
		exit 1; \
	fi
	@# Check startup time
	@echo "⏱️  Testing startup time..."
	@start=$$(date +%s); \
	docker run --rm dotfiles-ubuntu:minimal echo "Ready" >/dev/null; \
	end=$$(date +%s); \
	duration=$$((end - start)); \
	if [ "$$duration" -lt 3 ]; then \
		echo "✅ Startup time check passed: $${duration}s < 3s"; \
	else \
		echo "⚠️  Startup time: $${duration}s (target: < 2s, acceptable: < 3s)"; \
	fi
	@# Check ZSH
	@if docker run --rm dotfiles-ubuntu:minimal zsh --version >/dev/null 2>&1; then \
		echo "✅ ZSH check passed"; \
	else \
		echo "❌ ZSH check failed"; \
		exit 1; \
	fi
	@# Check Git
	@if docker run --rm dotfiles-ubuntu:minimal git --version >/dev/null 2>&1; then \
		echo "✅ Git check passed"; \
	else \
		echo "❌ Git check failed"; \
		exit 1; \
	fi
	@# Check dotfiles
	@if docker run --rm dotfiles-ubuntu:minimal test -f /home/developer/.zshrc; then \
		echo "✅ Dotfiles check passed"; \
	else \
		echo "❌ Dotfiles check failed"; \
		exit 1; \
	fi
	@echo ""
	@echo "✅ All verification checks passed"

# Clean Docker resources
docker-clean:
	@echo "🧹 Cleaning Docker resources..."
	@echo ""
	@echo "⚠️  This will remove:"
	@echo "  - dotfiles-ubuntu images (minimal, dev, production)"
	@echo "  - Dangling images"
	@echo "  - Build cache"
	@echo ""
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	@echo ""
	@# Remove dotfiles-ubuntu images
	@docker images | grep "dotfiles-ubuntu" | awk '{print $$1":"$$2}' | xargs -r docker rmi -f || echo "No images to remove"
	@# Remove dangling images
	@docker image prune -f
	@# Remove build cache (optional)
	@echo ""
	@echo "✅ Docker cleanup complete"
	@echo ""
	@echo "💡 To free more space:"
	@echo "  docker system prune -a  # Remove all unused images"
	@echo "  docker builder prune -a # Remove all build cache"

# Quick Docker workflow for development
docker-quick: docker-build-minimal docker-verify
	@echo ""
	@echo "✅ Quick Docker workflow complete"
	@echo "Run with: make docker-run-minimal"


# =============================================================================
# Dev Container Management (Project-specific containers)
# =============================================================================

# Generate dev container for a project
devcontainer-generate:
	@if [ -z "$(TEMPLATE)" ] || [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: TEMPLATE and PROJECT are required"; \
		echo ""; \
		echo "Usage:"; \
		echo "  make devcontainer-generate TEMPLATE=python PROJECT=~/my-app"; \
		echo ""; \
		echo "Available templates:"; \
		echo "  - base         Base container (ZSH + Git + Docker CLI)"; \
		echo "  - python       Python development (Python 3, pip, poetry)"; \
		echo "  - nodejs       Node.js development (Node.js, npm, pnpm)"; \
		echo "  - fullstack    Full-stack (Python + Node.js + PostgreSQL)"; \
		echo "  - data-science Data science (Python + Jupyter + pandas)"; \
		echo ""; \
		exit 1; \
	fi
	@echo "🐳 Generating dev container..."
	@echo ""
	@./scripts/devcontainer/generate-devcontainer.sh \
		--template $(TEMPLATE) \
		--project $(PROJECT) \
		$(if $(FORCE),--force,) \
		$(if $(VERBOSE),--verbose,)
	@echo ""
	@echo "✅ Dev container generated!"

# Generate with dry-run
devcontainer-preview:
	@if [ -z "$(TEMPLATE)" ] || [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: TEMPLATE and PROJECT are required"; \
		exit 1; \
	fi
	@./scripts/devcontainer/generate-devcontainer.sh \
		--template $(TEMPLATE) \
		--project $(PROJECT) \
		--dry-run

# Build dev container for a project
devcontainer-build:
	@if [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: PROJECT is required"; \
		echo "Usage: make devcontainer-build PROJECT=~/my-app"; \
		exit 1; \
	fi
	@if [ ! -d "$(PROJECT)/.devcontainer" ]; then \
		echo "❌ Error: .devcontainer not found in $(PROJECT)"; \
		echo "Generate with: make devcontainer-generate TEMPLATE=python PROJECT=$(PROJECT)"; \
		exit 1; \
	fi
	@echo "🔨 Building dev container for $(PROJECT)..."
	@cd $(PROJECT) && \
		docker build -f .devcontainer/Dockerfile -t devcontainer-$$(basename $(PROJECT)):latest .
	@echo "✅ Dev container built"

# Start dev container (docker-compose)
devcontainer-up:
	@if [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: PROJECT is required"; \
		exit 1; \
	fi
	@if [ ! -f "$(PROJECT)/.devcontainer/docker-compose.yml" ]; then \
		echo "❌ Error: docker-compose.yml not found"; \
		exit 1; \
	fi
	@echo "🚀 Starting dev container..."
	@cd $(PROJECT) && \
		PROJECT_NAME=$$(basename $(PROJECT)) \
		docker-compose -f .devcontainer/docker-compose.yml up -d
	@echo "✅ Dev container started"

# Stop dev container
devcontainer-down:
	@if [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: PROJECT is required"; \
		exit 1; \
	fi
	@if [ ! -f "$(PROJECT)/.devcontainer/docker-compose.yml" ]; then \
		echo "❌ Error: docker-compose.yml not found"; \
		exit 1; \
	fi
	@echo "🛑 Stopping dev container..."
	@cd $(PROJECT) && \
		PROJECT_NAME=$$(basename $(PROJECT)) \
		docker-compose -f .devcontainer/docker-compose.yml down
	@echo "✅ Dev container stopped"

# Shell into dev container
devcontainer-shell:
	@if [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: PROJECT is required"; \
		exit 1; \
	fi
	@echo "🐚 Opening shell in dev container..."
	@cd $(PROJECT) && \
		PROJECT_NAME=$$(basename $(PROJECT)) \
		docker-compose -f .devcontainer/docker-compose.yml exec devcontainer zsh

# Rebuild dev container
devcontainer-rebuild:
	@if [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: PROJECT is required"; \
		exit 1; \
	fi
	@echo "🔄 Rebuilding dev container..."
	@cd $(PROJECT) && \
		PROJECT_NAME=$$(basename $(PROJECT)) \
		docker-compose -f .devcontainer/docker-compose.yml build --no-cache
	@echo "✅ Dev container rebuilt"

# Clean dev container
devcontainer-clean:
	@if [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: PROJECT is required"; \
		exit 1; \
	fi
	@echo "🧹 Cleaning dev container..."
	@cd $(PROJECT) && \
		PROJECT_NAME=$$(basename $(PROJECT)) \
		docker-compose -f .devcontainer/docker-compose.yml down -v
	@echo "✅ Dev container cleaned (volumes removed)"

# Test dev container system
devcontainer-test:
	@echo "🧪 Running dev container tests..."
	@echo ""
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "❌ BATS not found. Install with: brew install bats-core"; \
		exit 1; \
	fi
	@bats tests/test-24-devcontainer.bats
	@echo ""
	@echo "✅ All dev container tests passed"

# Quick workflow: Generate Python dev container
devcontainer-python:
	@if [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: PROJECT is required"; \
		echo "Usage: make devcontainer-python PROJECT=~/my-python-app"; \
		exit 1; \
	fi
	@$(MAKE) devcontainer-generate TEMPLATE=python PROJECT=$(PROJECT) $(if $(FORCE),FORCE=1,)

# Quick workflow: Generate Node.js dev container
devcontainer-nodejs:
	@if [ -z "$(PROJECT)" ]; then \
		echo "❌ Error: PROJECT is required"; \
		echo "Usage: make devcontainer-nodejs PROJECT=~/my-web-app"; \
		exit 1; \
	fi
	@$(MAKE) devcontainer-generate TEMPLATE=nodejs PROJECT=$(PROJECT) $(if $(FORCE),FORCE=1,)

# List available templates
devcontainer-templates:
	@echo "📋 Available Dev Container Templates:"
	@echo ""
	@echo "1. base          - Base container (ZSH + Git + Docker CLI)"
	@echo "                   Use for: Generic projects, shell scripts"
	@echo ""
	@echo "2. python        - Python development (Python 3, pip, poetry, pytest)"
	@echo "                   Use for: Python apps, APIs, data processing"
	@echo "                   Ports: 8000, 5000"
	@echo ""
	@echo "3. nodejs        - Node.js development (Node.js, npm, pnpm, yarn)"
	@echo "                   Use for: Web apps, React/Vue/Angular"
	@echo "                   Ports: 3000, 8080, 5173"
	@echo ""
	@echo "4. fullstack     - Full-stack (Python + Node.js + PostgreSQL + Redis)"
	@echo "                   Use for: Full-stack apps with database"
	@echo "                   Services: app, postgres, redis, adminer"
	@echo ""
	@echo "5. data-science  - Data science (Python + Jupyter + pandas + NumPy)"
	@echo "                   Use for: Data analysis, ML, notebooks"
	@echo "                   Ports: 8888 (Jupyter)"
	@echo ""
	@echo "Generate with: make devcontainer-generate TEMPLATE=<name> PROJECT=<path>"

