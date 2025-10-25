.PHONY: help install bootstrap stow stow-all stow-dry-run stow-all-dry-run unstow stow-package stow-package-dry-run health backup clean autoupdate-install autoupdate-status autoupdate-logs autoupdate-disable autoupdate-enable

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
	@echo "🔄 Auto-Update:"
	@echo "  make autoupdate-install    Install auto-update service (runs every 30 min)"
	@echo "  make autoupdate-status     Check auto-update service status"
	@echo "  make autoupdate-logs       View auto-update logs"
	@echo "  make autoupdate-disable    Disable auto-update service"
	@echo "  make autoupdate-enable     Enable auto-update service"
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
