#!/usr/bin/env bash
################################################################################
# sync-ollama-models.sh
#
# Sync Ollama models from macOS to Ubuntu VM
#
# Strategy:
# - Read model list from macOS (via shared folder)
# - Pull same models in VM Ollama
# - Verify downloads
#
# Usage: ./scripts/setup/sync-ollama-models.sh
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Check if Ollama is installed
if ! command -v ollama >/dev/null 2>&1; then
    log_error "Ollama not found. Install it first:"
    echo "  curl -fsSL https://ollama.com/install.sh | sh"
    echo "  Or run: ./scripts/setup/install-gui-apps.sh"
    exit 1
fi

log_section "Ollama Model Sync"
log_info "This script will sync Ollama models from macOS to VM"
echo ""

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    log_warning "Ollama is not running"
    log_info "Starting Ollama server..."
    ollama serve > /dev/null 2>&1 &
    sleep 2
    log_success "Ollama server started"
    OLLAMA_STARTED_HERE=true
else
    log_success "Ollama server is already running"
    OLLAMA_STARTED_HERE=false
fi

# Function to get macOS Ollama models
get_macos_models() {
    # Try multiple locations for macOS Ollama manifest
    local MACOS_LOCATIONS=(
        "$HOME/.ollama/models/manifests"  # Via shared folder
        "/Volumes/MacOS-Home/.ollama/models/manifests"  # Alternate mount
    )

    for location in "${MACOS_LOCATIONS[@]}"; do
        if [[ -d "$location" ]]; then
            log_success "Found macOS Ollama models at: $location"
            # List models from manifest
            find "$location" -type f | sed 's|.*/manifests/||' | sed 's|/|:|'
            return 0
        fi
    done

    return 1
}

# Get macOS models
log_section "Discovering Models from macOS"
log_info "Searching for macOS Ollama models via shared folder..."

MACOS_MODELS=$(get_macos_models)

if [[ -n "$MACOS_MODELS" ]]; then
    log_success "Found models on macOS:"
    echo "$MACOS_MODELS" | while read -r model; do
        echo "  - $model"
    done
    echo ""

    log_info "These models will be pulled to VM Ollama"
else
    log_warning "Could not find macOS Ollama models"
    log_info "You can manually specify models to download"
    echo ""

    # Offer default models
    log_info "Would you like to install these common models instead?"
    echo "  - llama3.2:3b (lightweight, 2GB)"
    echo "  - codellama:7b (coding, 4GB)"
    echo ""

    read -p "Install default models? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        MACOS_MODELS="llama3.2:3b
codellama:7b"
    else
        log_info "Sync cancelled - no models to install"
        exit 0
    fi
fi

# Show disk space requirements
log_section "Disk Space Check"
AVAILABLE_SPACE=$(df -h "$HOME" | awk 'NR==2 {print $4}')
log_info "Available disk space: $AVAILABLE_SPACE"
log_warning "Models are large (2-10GB each)"
echo ""

read -p "Do you want to continue with model sync? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Sync cancelled"
    exit 0
fi

# Pull models
log_section "Pulling Models"
echo ""

PULLED=0
FAILED=()

while IFS= read -r model; do
    [[ -z "$model" ]] && continue

    log_info "Pulling model: ${BLUE}$model${NC}"
    echo ""

    if ollama pull "$model"; then
        log_success "Pulled: $model"
        PULLED=$((PULLED + 1))
    else
        log_error "Failed to pull: $model"
        FAILED+=("$model")
    fi

    echo ""
done <<< "$MACOS_MODELS"

# Verify installed models
log_section "Verifying Installation"
echo ""

log_info "Currently installed models:"
ollama list

echo ""

if [[ ${#FAILED[@]} -gt 0 ]]; then
    log_warning "${#FAILED[@]} model(s) failed to pull:"
    for model in "${FAILED[@]}"; do
        echo "  - $model"
    done
    echo ""
    log_info "You can try pulling them manually later:"
    echo "  ollama pull <model-name>"
else
    log_success "All models pulled successfully!"
fi

# Cleanup
if [[ "$OLLAMA_STARTED_HERE" == "true" ]]; then
    log_info "Stopping Ollama server (started by script)..."
    pkill -x "ollama" || true
    log_info "Ollama stopped (manual start only per preference)"
fi

# Final summary
log_section "Sync Complete!"
echo ""
log_success "Ollama model sync finished"
echo ""
echo "Summary:"
echo "  ${GREEN}✓${NC} Models pulled: $PULLED"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "  ${YELLOW}⚠${NC} Models failed: ${#FAILED[@]}"
fi

echo ""
echo "Using Ollama:"
echo "  ${BLUE}ollama serve${NC}          - Start Ollama server (manual)"
echo "  ${BLUE}ollama list${NC}           - List installed models"
echo "  ${BLUE}ollama run llama3.2${NC}   - Run a model"
echo "  ${BLUE}ollama pull <model>${NC}   - Pull additional models"
echo ""
log_info "Note: Ollama does NOT autostart (per your preference)"
log_info "Start manually when needed: ${BLUE}ollama serve${NC}"
echo ""
