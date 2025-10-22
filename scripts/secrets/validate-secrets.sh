#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-.env>"
    exit 1
fi

ENV_FILE="$1"

if [ ! -f "$ENV_FILE" ]; then
    log_error "File not found: $ENV_FILE"
    exit 1
fi

log_info "Validating secrets in: $ENV_FILE"

# Check for remaining op:// references
if grep -q "op://" "$ENV_FILE"; then
    log_error "Found uninjected 1Password references:"
    grep "op://" "$ENV_FILE"
    exit 1
fi

# Check for empty values
EMPTY_VARS=$(grep -E "^[A-Z_]+=$" "$ENV_FILE" || true)
if [ -n "$EMPTY_VARS" ]; then
    log_warning "Found empty variables:"
    echo "$EMPTY_VARS"
fi

log_success "Secrets validation passed"
