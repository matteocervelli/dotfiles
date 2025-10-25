#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/../utils/logger.sh"

cd "$DOTFILES_DIR"

log_info "Checking for dotfiles changes..."

# Check if there are local changes
HAS_LOCAL_CHANGES=false
if [ -n "$(git status --porcelain)" ]; then
    HAS_LOCAL_CHANGES=true
fi

# Check if we're on main branch
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ]; then
    log_warning "Not on main branch (current: $BRANCH), skipping auto-update"
    exit 0
fi

# Try to pull remote changes first (before committing local changes)
log_info "Fetching remote changes..."
if git fetch origin main 2>/dev/null; then
    # Check if remote is ahead
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" != "$REMOTE" ]; then
        log_info "Remote has changes, attempting pull..."

        if [ "$HAS_LOCAL_CHANGES" = true ]; then
            # Stash local changes before pull
            log_info "Stashing local changes..."
            git stash push -u -m "auto-update: temporary stash - $(date +%s)"

            # Pull remote changes
            if git pull --rebase origin main; then
                log_success "Pulled remote changes"

                # Re-apply stashed changes
                log_info "Re-applying local changes..."
                if git stash pop; then
                    log_success "Local changes re-applied successfully"
                else
                    log_error "CONFLICT: Could not re-apply local changes!"
                    log_error "Manual intervention required: git stash list"
                    exit 1
                fi
            else
                log_error "Failed to pull remote changes"
                # Restore stashed changes
                git stash pop
                exit 1
            fi
        else
            # No local changes, just pull
            if git pull --rebase origin main; then
                log_success "Pulled remote changes"
            else
                log_error "Failed to pull remote changes"
                exit 1
            fi
        fi
    fi
else
    log_warning "Could not fetch remote (offline?), skipping pull"
fi

# Now check if there are still local changes to commit
if [ -z "$(git status --porcelain)" ]; then
    log_info "No local changes to commit after pull"
    exit 0
fi

# Show changes
log_info "Detected local changes:"
git status --short

# Commit local changes
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname -s)

log_info "Committing local changes..."
git add -A
git commit -m "chore: auto-update dotfiles from $HOSTNAME - $TIMESTAMP"

# Push to GitHub
log_info "Pushing to GitHub..."
if git push origin main; then
    log_success "Dotfiles auto-updated and pushed!"
else
    log_error "Failed to push to GitHub"
    log_error "Try manual: git push origin main"
    exit 1
fi
