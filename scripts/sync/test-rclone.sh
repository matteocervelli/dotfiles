#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Test Rclone R2 Connection"

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    log_error "Rclone non installato"
    log_info "Installa con: brew install rclone"
    exit 1
fi

log_success "✓ Rclone installato: $(rclone version | head -1)"

# Check if configured
if [ ! -f "$HOME/.config/rclone/rclone.conf" ]; then
    log_error "Rclone non configurato"
    log_info "Config non trovato: ~/.config/rclone/rclone.conf"
    log_info "Esegui: ./scripts/sync/setup-rclone.sh"
    exit 1
fi

log_success "✓ Config trovato: ~/.config/rclone/rclone.conf"

# Check file permissions
PERMS=$(stat -f "%OLp" "$HOME/.config/rclone/rclone.conf" 2>/dev/null || stat -c "%a" "$HOME/.config/rclone/rclone.conf")
if [ "$PERMS" != "600" ]; then
    log_warning "Permessi config non sicuri: $PERMS (dovrebbe essere 600)"
    log_info "Fix con: chmod 600 ~/.config/rclone/rclone.conf"
else
    log_success "✓ Permessi config corretti: 600"
fi

# List remotes
echo ""
log_info "Remotes configurati:"
REMOTES=$(rclone listremotes)
if [ -z "$REMOTES" ]; then
    log_error "Nessun remote configurato"
    exit 1
fi
echo "$REMOTES"

# Check for remote-cdn
if ! echo "$REMOTES" | grep -q "remote-cdn:"; then
    log_error "Remote 'remote-cdn:' non trovato"
    log_info "Remotes disponibili:"
    echo "$REMOTES"
    exit 1
fi

log_success "✓ Remote 'remote-cdn:' configurato"

# Test remote-cdn connection
echo ""
log_info "Test connessione remote-cdn..."
if ! rclone lsd remote-cdn: 2>/dev/null; then
    log_error "✗ Connessione remote-cdn fallita"
    log_info "Debug con: rclone lsd remote-cdn: -vv"
    exit 1
fi

log_success "✓ Connessione remote-cdn attiva"

# List buckets
echo ""
log_info "Bucket disponibili su remote-cdn:"
rclone lsd remote-cdn:

# Test bucket access (if media-adlimen exists)
echo ""
if rclone lsd remote-cdn: | grep -q "media-adlimen"; then
    log_info "Test accesso bucket media-adlimen..."
    if rclone ls remote-cdn:media-adlimen --max-depth 1 &>/dev/null; then
        log_success "✓ Accesso bucket media-adlimen riuscito"

        # Count files
        FILE_COUNT=$(rclone ls remote-cdn:media-adlimen | wc -l | xargs)
        log_info "File nel bucket: $FILE_COUNT"
    else
        log_warning "Bucket esiste ma accesso limitato"
    fi
else
    log_info "Bucket 'media-adlimen' non trovato (potrebbe essere normale)"
fi

# Summary
echo ""
log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "✓ Tutti i test superati!"
log_success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Comandi utili:"
echo "  • Lista bucket:     rclone lsd remote-cdn:"
echo "  • Lista files:      rclone ls remote-cdn:BUCKET_NAME"
echo "  • Sync directory:   rclone sync LOCAL remote-cdn:BUCKET"
echo "  • Copia file:       rclone copy FILE remote-cdn:BUCKET/"
