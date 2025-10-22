#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

log_step "Sync Media CDN to R2"

# Check rclone configured
if ! rclone listremotes | grep -q "remote-cdn:"; then
    log_error "Rclone non configurato"
    log_info "Esegui: ./scripts/sync/setup-rclone.sh"
    exit 1
fi

log_success "✓ Rclone configurato"

# Check source directory
SOURCE_DIR="$HOME/media/cdn"
if [ ! -d "$SOURCE_DIR" ]; then
    log_error "Directory non trovata: $SOURCE_DIR"
    log_info "Crea la directory o modifica lo script per usare un'altra path"
    exit 1
fi

log_success "✓ Source directory trovata: $SOURCE_DIR"

# Get directory size
if command -v du &> /dev/null; then
    SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)
    log_info "Size da sincronizzare: $SIZE"
fi

# Destination
DESTINATION="remote-cdn:media-adlimen"

echo ""
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "Source:      $SOURCE_DIR"
log_info "Destination: $DESTINATION"
log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Confirm
read -p "Procedi con la sincronizzazione? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Operazione annullata"
    exit 0
fi

# Sync with progress
log_info "Sincronizzazione in corso..."
echo ""

rclone sync "$SOURCE_DIR" "$DESTINATION" \
  --exclude ".DS_Store" \
  --exclude ".archive/**" \
  --exclude ".git/**" \
  --exclude ".gitignore" \
  --s3-no-check-bucket \
  --progress

echo ""
log_success "✓ Sincronizzazione completata!"

# Show stats
echo ""
log_info "Bucket content:"
rclone ls "$DESTINATION" | wc -l | xargs | while read count; do
    log_info "Total files in R2: $count"
done

log_info "Verifica su: https://dash.cloudflare.com → R2 → media-adlimen"
