#!/usr/bin/env bash
# Logging Utilities
# Provides consistent, colored logging across all dotfiles scripts
#
# Usage:
#   This script must be sourced, not executed directly:
#
#   source scripts/utils/logger.sh
#   log_info "Installing dependencies..."
#   log_success "Installation complete!"
#   log_error "Something went wrong"
#   log_warning "This is deprecated"
#   log_step "Running Health Checks"
#
# Functions:
#   log_info    - Blue informational messages
#   log_success - Green success messages with ✓ symbol
#   log_error   - Red error messages with ✗ symbol (to stderr)
#   log_warning - Yellow warning messages with ! symbol
#   log_step    - Blue section headers with separators

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging Functions

# Log informational messages (blue)
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Log success messages (green with checkmark)
log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

# Log error messages (red with X, to stderr)
log_error() {
    echo -e "${RED}[✗]${NC} $*" >&2
}

# Log warning messages (yellow with exclamation)
log_warning() {
    echo -e "${YELLOW}[!]${NC} $*"
}

# Log section headers (blue with separators)
log_step() {
    echo ""
    echo -e "${BLUE}==>${NC} $*"
    echo ""
}

# Check if script is being executed directly (incorrect usage)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "ERROR: This script should be sourced, not executed directly" >&2
    echo "" >&2
    echo "Correct usage:" >&2
    echo "  source scripts/utils/logger.sh" >&2
    echo "" >&2
    echo "Then use the logging functions:" >&2
    echo "  log_info \"message\"" >&2
    echo "  log_success \"message\"" >&2
    echo "  log_error \"message\"" >&2
    echo "  log_warning \"message\"" >&2
    echo "  log_step \"message\"" >&2
    exit 1
fi
