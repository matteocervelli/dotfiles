#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

RCLONE_CONF="$HOME/.config/rclone/rclone.conf"
TEMPLATE="$DOTFILES_DIR/sync/rclone/rclone.conf.template"

log_step "Setup Rclone for Cloudflare R2"

# Check if already configured
if [ -f "$RCLONE_CONF" ] && rclone listremotes | grep -q "remote-cdn"; then
    log_success "Rclone già configurato con remote: remote-cdn"
    log_info "Test connessione..."

    if rclone lsd remote-cdn: &> /dev/null; then
        log_success "✓ Connessione R2 attiva"
        echo ""
        log_info "Bucket disponibili:"
        rclone lsd remote-cdn:
    else
        log_warning "Config esistente ma connessione fallita"
        log_info "Potrebbe essere necessario rigenerare la configurazione"
    fi

    exit 0
fi

log_info "Configurazione non trovata, genero da template..."

# Verify template exists
if [ ! -f "$TEMPLATE" ]; then
    log_error "Template non trovato: $TEMPLATE"
    exit 1
fi

# Check 1Password authentication
log_info "Verifico autenticazione 1Password..."
if ! op whoami &> /dev/null; then
    log_info "Autenticazione 1Password necessaria..."
    log_info "Esegui: eval \$(op signin)"
    exit 1
fi

log_success "1Password autenticato come: $(op whoami)"

# Create config directory
mkdir -p "$(dirname "$RCLONE_CONF")"

# Inject secrets from 1Password
log_info "Inietto credenziali da 1Password..."
log_info "Template: $TEMPLATE"
log_info "Output: $RCLONE_CONF"
echo ""

if op inject -i "$TEMPLATE" -o "$RCLONE_CONF"; then
    chmod 600 "$RCLONE_CONF"
    log_success "Rclone configurato con successo!"

    # Verify no remaining op:// references
    if grep -q "op://" "$RCLONE_CONF"; then
        log_error "Alcune credenziali non sono state iniettate!"
        echo ""
        log_info "Verifica che l'item 1Password esista con i campi corretti:"
        log_info "  Vault: Private"
        log_info "  Item: Cloudflare-R2"
        log_info "  Fields: access_key_id, secret_access_key, endpoint"
        echo ""
        log_info "Test manuale:"
        log_info "  op read \"op://Private/Cloudflare-R2/access_key_id\""
        log_info "  op read \"op://Private/Cloudflare-R2/secret_access_key\""
        log_info "  op read \"op://Private/Cloudflare-R2/endpoint\""
        exit 1
    fi

    # Test connection
    echo ""
    log_info "Test connessione R2..."
    if rclone lsd remote-cdn: &> /dev/null; then
        log_success "✓ Connessione R2 riuscita!"
        echo ""
        log_info "Bucket disponibili:"
        rclone lsd remote-cdn:
    else
        log_error "✗ Connessione R2 fallita"
        log_info "Possibili cause:"
        log_info "  - Credenziali non corrette in 1Password"
        log_info "  - Endpoint R2 non valido"
        log_info "  - Problemi di rete"
        echo ""
        log_info "Debug: cat $RCLONE_CONF"
        exit 1
    fi
else
    log_error "1Password injection fallita"
    exit 1
fi

echo ""
log_success "Setup completato!"
log_info "Configurazione salvata in: $RCLONE_CONF"
log_info "Per testare: rclone lsd remote-cdn:"
