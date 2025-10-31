#!/usr/bin/env bash
# Docker Volume Restore Script
# Restores Docker volumes from backup after formatting
#
# Usage:
#   ./scripts/docker/restore-volumes.sh /path/to/backup [OPTIONS]
#
# Options:
#   -h, --help              Show this help message
#   -n, --dry-run           Show what would be restored without doing it
#   -v, --volumes NAMES     Comma-separated list of volumes to restore
#   --all                   Restore all volumes (default)
#   --force                 Overwrite existing volumes
#
# Example:
#   ./scripts/docker/restore-volumes.sh /Volumes/Backup/docker-backups/2025-10-31_14-30-00
#   ./scripts/docker/restore-volumes.sh /Volumes/Backup/docker-backups/2025-10-31_14-30-00 --dry-run
#   ./scripts/docker/restore-volumes.sh /path/to/backup --volumes postgres-data,redis-data --force

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Default configuration
DRY_RUN=0
FORCE=0
SPECIFIC_VOLUMES=""
BACKUP_DIR=""

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Docker Volume Restore Script

Restores Docker volumes from backup after formatting.

USAGE:
    $0 BACKUP_PATH [OPTIONS]

ARGUMENTS:
    BACKUP_PATH          Path to backup directory

OPTIONS:
    -h, --help           Show this help message
    -n, --dry-run        Show what would be restored without doing it
    -v, --volumes NAMES  Comma-separated list of volumes to restore
    --all                Restore all volumes (default)
    --force              Overwrite existing volumes (WARNING: destructive)

EXAMPLES:
    # Restore all volumes
    $0 /Volumes/Backup/docker-backups/2025-10-31_14-30-00

    # Dry run to see what would be restored
    $0 /Volumes/Backup/docker-backups/2025-10-31_14-30-00 --dry-run

    # Restore specific volumes
    $0 /path/to/backup --volumes postgres-data,redis-data

    # Force overwrite existing volumes
    $0 /path/to/backup --force

CAUTION:
    - Using --force will DELETE and recreate volumes
    - Make sure no containers are using the volumes
    - Verify checksums after restore

EXIT CODES:
    0    Success
    1    General error
    2    Missing backup path
    3    Docker not available
    4    No backup files found

EOF
}

# Parse command-line arguments
parse_args() {
    if [[ $# -eq 0 ]]; then
        log_error "Error: Backup path required"
        show_help
        exit 2
    fi

    BACKUP_DIR="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -v|--volumes)
                if [[ -n "${2:-}" ]]; then
                    SPECIFIC_VOLUMES="$2"
                    shift 2
                else
                    log_error "Error: --volumes requires an argument"
                    exit 1
                fi
                ;;
            --all)
                SPECIFIC_VOLUMES=""
                shift
                ;;
            --force)
                FORCE=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 3
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is not running"
        exit 3
    fi

    log_success "Docker is available and running"
}

# Validate backup directory
validate_backup_dir() {
    local backup_path="$1"

    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup path does not exist: $backup_path"
        exit 2
    fi

    # Check for backup files
    local backup_files
    backup_files=$(find "$backup_path" -name "*.tar.gz" 2>/dev/null | wc -l | tr -d ' ')

    if [[ $backup_files -eq 0 ]]; then
        log_error "No backup files found in: $backup_path"
        exit 4
    fi

    log_success "Found $backup_files backup file(s) in directory"
}

# Get list of volumes from backup directory
get_backup_volumes() {
    local backup_path="$1"
    local volumes=""

    if [[ -n "$SPECIFIC_VOLUMES" ]]; then
        # Use specified volumes
        volumes=$(echo "$SPECIFIC_VOLUMES" | tr ',' '\n')
    else
        # Get all volumes from backup files
        volumes=$(find "$backup_path" -name "*.tar.gz" -exec basename {} .tar.gz \; | sort)
    fi

    if [[ -z "$volumes" ]]; then
        log_error "No volumes to restore"
        exit 4
    fi

    echo "$volumes"
}

# Check if volume exists
volume_exists() {
    local volume="$1"
    docker volume inspect "$volume" &> /dev/null
}

# Verify checksum
verify_checksum() {
    local backup_file="$1"
    local checksum_file="$2"
    local volume_name
    volume_name=$(basename "$backup_file")

    if [[ ! -f "$checksum_file" ]]; then
        log_warning "  Checksum file not found, skipping verification"
        return 0
    fi

    local expected_checksum
    expected_checksum=$(grep "$volume_name" "$checksum_file" | awk '{print $1}')

    if [[ -z "$expected_checksum" ]]; then
        log_warning "  No checksum found for $volume_name"
        return 0
    fi

    log_info "  Verifying checksum..."
    local actual_checksum
    actual_checksum=$(shasum -a 256 "$backup_file" | awk '{print $1}')

    if [[ "$expected_checksum" != "$actual_checksum" ]]; then
        log_error "  Checksum mismatch!"
        log_error "    Expected: $expected_checksum"
        log_error "    Actual:   $actual_checksum"
        return 1
    fi

    log_success "  Checksum verified"
    return 0
}

# Restore single volume
restore_volume() {
    local volume="$1"
    local backup_dir="$2"
    local backup_file="$backup_dir/${volume}.tar.gz"
    local checksum_file="$backup_dir/checksums.txt"

    log_step "Restoring volume: $volume"

    # Check if backup file exists
    if [[ ! -f "$backup_file" ]]; then
        log_error "  Backup file not found: $backup_file"
        return 1
    fi

    # Verify checksum
    if ! verify_checksum "$backup_file" "$checksum_file"; then
        log_error "  Skipping restore due to checksum failure"
        return 1
    fi

    # Check if volume already exists
    if volume_exists "$volume"; then
        if [[ $FORCE -eq 0 ]]; then
            log_warning "  Volume already exists: $volume"
            log_info "  Use --force to overwrite"
            return 0
        else
            if [[ $DRY_RUN -eq 0 ]]; then
                log_warning "  Removing existing volume: $volume"
                docker volume rm "$volume" 2>/dev/null || {
                    log_error "  Failed to remove volume (containers may be using it)"
                    return 1
                }
            else
                log_warning "  [DRY RUN] Would remove existing volume: $volume"
            fi
        fi
    fi

    # Create volume
    if [[ $DRY_RUN -eq 0 ]]; then
        log_info "  Creating volume: $volume"
        docker volume create "$volume" > /dev/null
    else
        log_info "  [DRY RUN] Would create volume: $volume"
    fi

    # Restore data
    if [[ $DRY_RUN -eq 1 ]]; then
        log_success "  [DRY RUN] Would restore from: ${volume}.tar.gz"
    else
        log_info "  Extracting archive..."

        # Use a temporary container to extract the backup
        docker run --rm \
            -v "$volume:/volume" \
            -v "$backup_dir:/backup:ro" \
            alpine \
            tar xzf "/backup/${volume}.tar.gz" -C /volume \
            2>/dev/null || {
                log_error "  Failed to restore volume: $volume"
                return 1
            }

        log_success "  Volume restored successfully"
    fi

    return 0
}

# Display manifest if available
show_manifest() {
    local backup_dir="$1"
    local manifest_file="$backup_dir/volume-manifest.txt"

    if [[ -f "$manifest_file" ]]; then
        echo ""
        log_step "Backup Manifest"
        cat "$manifest_file"
        echo ""
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    parse_args "$@"

    log_step "Docker Volume Restore"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN MODE - No actual restores will be performed"
    fi

    if [[ $FORCE -eq 1 ]]; then
        log_warning "FORCE MODE - Existing volumes will be overwritten"
    fi

    # Show manifest
    show_manifest "$BACKUP_DIR"

    # Validations
    check_docker
    validate_backup_dir "$BACKUP_DIR"

    # Get volumes to restore
    local volumes
    volumes=$(get_backup_volumes "$BACKUP_DIR")
    local volume_count
    volume_count=$(echo "$volumes" | wc -l | tr -d ' ')

    log_info "Found $volume_count volume(s) to restore"

    # Restore each volume
    local success_count=0
    local failed_count=0
    local skipped_count=0

    echo "$volumes" | while read -r volume; do
        if [[ -n "$volume" ]]; then
            if restore_volume "$volume" "$BACKUP_DIR"; then
                if volume_exists "$volume" || [[ $DRY_RUN -eq 1 ]]; then
                    ((success_count++))
                else
                    ((skipped_count++))
                fi
            else
                ((failed_count++))
            fi
        fi
    done

    # Summary
    echo ""
    log_step "Restore Summary"
    log_info "Total volumes: $volume_count"
    log_success "Successfully restored: $success_count"

    if [[ $skipped_count -gt 0 ]]; then
        log_warning "Skipped (already exist): $skipped_count"
    fi

    if [[ $failed_count -gt 0 ]]; then
        log_error "Failed: $failed_count"
    fi

    if [[ $DRY_RUN -eq 0 ]] && [[ $success_count -gt 0 ]]; then
        echo ""
        log_step "Next Steps"
        log_info "1. Start your Docker Compose services"
        log_info "2. Verify data integrity"
        log_info "3. Check application logs"
    fi
}

# Run main function
main "$@"
