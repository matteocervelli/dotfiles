#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-.env.template> [output-path]"
    echo ""
    echo "Example:"
    echo "  $0 ~/dev/projects/my-app/.env.template"
    echo "  $0 ~/dev/projects/my-app/.env.template ~/dev/projects/my-app/.env"
    exit 1
fi

TEMPLATE="$1"
OUTPUT="${2:-${TEMPLATE%.template}}"

if [ ! -f "$TEMPLATE" ]; then
    log_error "Template not found: $TEMPLATE"
    exit 1
fi

log_info "Injecting secrets from 1Password..."
log_info "Template: $TEMPLATE"
log_info "Output: $OUTPUT"

# Check 1Password authentication
if ! op whoami &> /dev/null; then
    log_info "Signing in to 1Password..."
    eval $(op signin)
fi

# Inject secrets
if op inject -i "$TEMPLATE" -o "$OUTPUT"; then
    log_success "Secrets injected to $OUTPUT"

    # Verify output has no remaining op:// references
    if grep -q "op://" "$OUTPUT"; then
        log_warning "Some secrets may not have been injected (check 1Password references)"
    fi
else
    log_error "Failed to inject secrets"
    exit 1
fi
