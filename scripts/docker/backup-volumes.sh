#!/usr/bin/env bash
# Docker Volume Backup Script
# Backs up Docker volumes to external drive before formatting
#
# Usage:
#   ./scripts/docker/backup-volumes.sh /Volumes/ExternalDrive [OPTIONS]
#
# Options:
#   -h, --help              Show this help message
#   -n, --dry-run           Show what would be backed up without doing it
#   -v, --volumes NAMES     Comma-separated list of volumes to backup
#   --all                   Backup all volumes (default)
#   --skip-stop             Don't stop containers before backup
#
# Example:
#   ./scripts/docker/backup-volumes.sh /Volumes/Backup
#   ./scripts/docker/backup-volumes.sh /Volumes/Backup --dry-run
#   ./scripts/docker/backup-volumes.sh /Volumes/Backup --volumes postgres-data,redis-data

set -eo pipefail

# Script directory and root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
# shellcheck source=../utils/logger.sh
source "$PROJECT_ROOT/scripts/utils/logger.sh"

# Default configuration
DRY_RUN=0
STOP_CONTAINERS=1
SPECIFIC_VOLUMES=""
BACKUP_DIR=""
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Docker Volume Backup Script

Safely backs up Docker volumes to external drive before formatting.

USAGE:
    $0 BACKUP_PATH [OPTIONS]

ARGUMENTS:
    BACKUP_PATH          Path to external drive (e.g., /Volumes/ExternalDrive)

OPTIONS:
    -h, --help           Show this help message
    -n, --dry-run        Show what would be backed up without doing it
    -v, --volumes NAMES  Comma-separated list of volumes to backup
    --all                Backup all volumes (default)
    --skip-stop          Don't stop containers before backup (risky for databases)

EXAMPLES:
    # Backup all volumes
    $0 /Volumes/Backup

    # Dry run to see what would be backed up
    $0 /Volumes/Backup --dry-run

    # Backup specific volumes
    $0 /Volumes/Backup --volumes postgres-data,redis-data

    # Backup without stopping containers (faster but risky)
    $0 /Volumes/Backup --skip-stop

OUTPUT:
    Creates organized backup structure:
    /Volumes/Backup/
    └── docker-backups/
        └── 2025-10-31_14-30-00/
            ├── adlimen_infra-postgres-data.tar.gz
            ├── app-cna-crm_postgres_data.tar.gz
            ├── volume-manifest.txt
            └── backup-summary.log

EXIT CODES:
    0    Success
    1    General error
    2    Missing backup path
    3    Docker not available
    4    No volumes found

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
            --skip-stop)
                STOP_CONTAINERS=0
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
        log_info "Please mount your external drive first"
        exit 2
    fi

    if [[ ! -w "$backup_path" ]]; then
        log_error "Backup path is not writable: $backup_path"
        exit 2
    fi

    log_success "Backup destination is valid and writable"
}

# Get list of Docker volumes
get_volumes() {
    local volumes

    if [[ -n "$SPECIFIC_VOLUMES" ]]; then
        # Convert comma-separated list to newline-separated
        volumes=$(echo "$SPECIFIC_VOLUMES" | tr ',' '\n')
    else
        # Get all volumes
        volumes=$(docker volume ls -q)
    fi

    if [[ -z "$volumes" ]]; then
        log_error "No volumes found"
        exit 4
    fi

    echo "$volumes"
}

# Get containers using a volume
get_containers_using_volume() {
    local volume="$1"
    docker ps -q --filter volume="$volume"
}

# Get volume size (approximate)
get_volume_size() {
    local volume="$1"

    # Use docker system df to get volume size
    docker system df -v 2>/dev/null | grep "$volume" | awk '{print $3}' || echo "unknown"
}

# Stop containers using volume
stop_volume_containers() {
    local volume="$1"
    local containers
    containers=$(get_containers_using_volume "$volume")

    if [[ -z "$containers" ]]; then
        log_info "  No containers using volume $volume"
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "  [DRY RUN] Would stop containers: $containers"
        return 0
    fi

    log_warning "  Stopping containers: $containers"
    # shellcheck disable=SC2086
    docker stop $containers > /dev/null
    echo "$containers"
}

# Start containers
start_containers() {
    local containers="$1"

    if [[ -z "$containers" ]]; then
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "  [DRY RUN] Would restart containers: $containers"
        return 0
    fi

    log_info "  Restarting containers: $containers"
    # shellcheck disable=SC2086
    docker start $containers > /dev/null
}

# Backup single volume
backup_volume() {
    local volume="$1"
    local output_dir="$2"
    local backup_file="$output_dir/${volume}.tar.gz"
    local stopped_containers=""

    log_step "Backing up volume: $volume"

    # Check if volume exists
    if ! docker volume inspect "$volume" &> /dev/null; then
        log_error "  Volume does not exist: $volume"
        return 1
    fi

    # Get volume size
    local size
    size=$(get_volume_size "$volume")
    log_info "  Volume size: $size"

    # Stop containers if requested
    if [[ $STOP_CONTAINERS -eq 1 ]]; then
        stopped_containers=$(stop_volume_containers "$volume")
    fi

    # Backup volume
    if [[ $DRY_RUN -eq 1 ]]; then
        log_success "  [DRY RUN] Would create: $backup_file"
    else
        log_info "  Creating archive: ${volume}.tar.gz"

        # Use a temporary container to tar the volume
        docker run --rm \
            -v "$volume:/volume:ro" \
            -v "$output_dir:/backup" \
            alpine \
            tar czf "/backup/${volume}.tar.gz" -C /volume . \
            2>/dev/null || {
                log_error "  Failed to backup volume: $volume"
                start_containers "$stopped_containers"
                return 1
            }

        # Generate checksum
        local checksum
        checksum=$(shasum -a 256 "$backup_file" | awk '{print $1}')
        echo "$checksum  ${volume}.tar.gz" >> "$output_dir/checksums.txt"

        log_success "  Backup complete: ${volume}.tar.gz"
        log_info "  Checksum: $checksum"
    fi

    # Restart containers
    if [[ $STOP_CONTAINERS -eq 1 ]]; then
        start_containers "$stopped_containers"
    fi

    return 0
}

# Generate backup manifest
generate_manifest() {
    local output_dir="$1"
    local volumes="$2"
    local manifest_file="$output_dir/volume-manifest.txt"

    {
        echo "Docker Volume Backup Manifest"
        echo "=============================="
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Backup Location: $output_dir"
        echo ""
        echo "Volumes Backed Up:"
        echo "------------------"
        echo "$volumes" | while read -r volume; do
            if [[ -n "$volume" ]]; then
                local size
                size=$(get_volume_size "$volume")
                echo "  - $volume (size: $size)"
            fi
        done
        echo ""
        echo "Restore Instructions:"
        echo "--------------------"
        echo "Use the companion restore script:"
        echo "  ./scripts/docker/restore-volumes.sh $output_dir"
        echo ""
    } > "$manifest_file"

    log_info "Manifest saved to: $manifest_file"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    parse_args "$@"

    log_step "Docker Volume Backup"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN MODE - No actual backups will be performed"
    fi

    # Validations
    check_docker
    validate_backup_dir "$BACKUP_DIR"

    # Get volumes to backup
    local volumes
    volumes=$(get_volumes)
    local volume_count
    volume_count=$(echo "$volumes" | wc -l | tr -d ' ')

    log_info "Found $volume_count volume(s) to backup"

    # Create backup directory structure
    local output_dir="$BACKUP_DIR/docker-backups/$TIMESTAMP"

    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$output_dir"
        log_success "Created backup directory: $output_dir"
    else
        log_info "[DRY RUN] Would create: $output_dir"
    fi

    # Backup each volume
    local success_count=0
    local failed_count=0

    echo "$volumes" | while read -r volume; do
        if [[ -n "$volume" ]]; then
            if backup_volume "$volume" "$output_dir"; then
                ((success_count++))
            else
                ((failed_count++))
            fi
        fi
    done

    # Generate manifest
    if [[ $DRY_RUN -eq 0 ]]; then
        generate_manifest "$output_dir" "$volumes"
    fi

    # Summary
    echo ""
    log_step "Backup Summary"
    log_info "Total volumes: $volume_count"
    log_success "Successfully backed up: $success_count"

    if [[ $failed_count -gt 0 ]]; then
        log_error "Failed: $failed_count"
    fi

    if [[ $DRY_RUN -eq 0 ]]; then
        log_success "All backups saved to: $output_dir"
        log_info ""
        log_info "To restore these volumes after formatting:"
        log_info "  ./scripts/docker/restore-volumes.sh $output_dir"
    fi
}

# Run main function
main "$@"
