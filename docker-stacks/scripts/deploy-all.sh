#!/usr/bin/env bash
# Deploy All Stacks - One-command deployment for complete infrastructure
#
# Usage:
#   ./scripts/deploy-all.sh [OPTIONS]
#
# Options:
#   -h, --help         Show this help message
#   --skip-observability   Skip observability stack
#   --skip-infrastructure  Skip infrastructure stack
#   --with-apps            Deploy application stacks
#   --pull                 Pull latest images before deploying

set -eo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
SKIP_OBSERVABILITY=0
SKIP_INFRASTRUCTURE=0
WITH_APPS=0
PULL_IMAGES=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

show_help() {
    cat << EOF
Deploy All Stacks

Deploy complete infrastructure with observability and application stacks.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help                Show this help message
    --skip-observability      Skip observability stack deployment
    --skip-infrastructure     Skip infrastructure stack deployment
    --with-apps               Deploy application stacks
    --pull                    Pull latest images before deploying

EXAMPLES:
    $0                        # Deploy observability + infrastructure
    $0 --with-apps            # Deploy everything including apps
    $0 --skip-observability   # Deploy only infrastructure

STACKS:
    1. Observability - Grafana, Prometheus, Loki, Alertmanager
    2. Infrastructure - PostgreSQL, Redis, Nginx
    3. Applications - FastAPI, Next.js, Vite (optional)

NOTES:
    - Ensure .env files are configured in each stack directory
    - Stacks will be deployed in order with dependency checks
    - Use --pull to get latest images from registry

EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --skip-observability)
                SKIP_OBSERVABILITY=1
                shift
                ;;
            --skip-infrastructure)
                SKIP_INFRASTRUCTURE=1
                shift
                ;;
            --with-apps)
                WITH_APPS=1
                shift
                ;;
            --pull)
                PULL_IMAGES=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run '$0 --help' for usage information."
                exit 1
                ;;
        esac
    done
}

check_prerequisites() {
    log_header "Checking Prerequisites"

    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    log_success "Docker installed"

    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    log_success "Docker Compose installed"

    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root - consider using Docker without sudo"
    fi
}

deploy_stack() {
    local stack_name=$1
    local stack_dir=$2

    log_header "Deploying $stack_name Stack"

    if [[ ! -d "$stack_dir" ]]; then
        log_error "Stack directory not found: $stack_dir"
        return 1
    fi

    cd "$stack_dir"

    # Check for .env file
    if [[ ! -f ".env" ]]; then
        log_warning ".env file not found in $stack_dir"
        if [[ -f ".env.example" ]]; then
            log_info "Copy .env.example to .env and configure it"
            log_info "  cp .env.example .env"
            log_info "  vim .env"
        fi
        return 1
    fi

    # Pull images if requested
    if [[ $PULL_IMAGES -eq 1 ]]; then
        log_info "Pulling latest images..."
        docker compose pull
    fi

    # Deploy stack
    log_info "Starting services..."
    docker compose up -d

    # Wait for services to be healthy
    log_info "Waiting for services to be ready..."
    sleep 10

    # Check status
    docker compose ps

    log_success "$stack_name stack deployed successfully"
}

# =============================================================================
# Main Deployment Flow
# =============================================================================

main() {
    log_header "Docker Stacks Deployment"

    parse_args "$@"

    log_info "Configuration:"
    log_info "  Observability: $([ $SKIP_OBSERVABILITY -eq 1 ] && echo 'SKIP' || echo 'DEPLOY')"
    log_info "  Infrastructure: $([ $SKIP_INFRASTRUCTURE -eq 1 ] && echo 'SKIP' || echo 'DEPLOY')"
    log_info "  Applications: $([ $WITH_APPS -eq 1 ] && echo 'DEPLOY' || echo 'SKIP')"
    log_info "  Pull Images: $([ $PULL_IMAGES -eq 1 ] && echo 'YES' || echo 'NO')"
    echo ""

    check_prerequisites

    # Deploy observability stack
    if [[ $SKIP_OBSERVABILITY -eq 0 ]]; then
        deploy_stack "Observability" "$STACKS_DIR/observability"
    fi

    # Deploy infrastructure stack
    if [[ $SKIP_INFRASTRUCTURE -eq 0 ]]; then
        deploy_stack "Infrastructure" "$STACKS_DIR/infrastructure"
    fi

    # Deploy application stacks
    if [[ $WITH_APPS -eq 1 ]]; then
        log_header "Deploying Application Stacks"

        if [[ -f "$STACKS_DIR/applications/fastapi-app.yml" ]]; then
            log_info "Deploying FastAPI application..."
            cd "$STACKS_DIR/applications"
            docker compose -f fastapi-app.yml up -d
        fi

        if [[ -f "$STACKS_DIR/applications/nextjs-app.yml" ]]; then
            log_info "Deploying Next.js application..."
            cd "$STACKS_DIR/applications"
            docker compose -f nextjs-app.yml up -d
        fi

        if [[ -f "$STACKS_DIR/applications/vite-app.yml" ]]; then
            log_info "Deploying Vite application..."
            cd "$STACKS_DIR/applications"
            docker compose -f vite-app.yml up -d
        fi

        log_success "Application stacks deployed"
    fi

    # Summary
    log_header "Deployment Complete!"

    log_success "All stacks deployed successfully"
    echo ""
    log_info "Access URLs:"

    if [[ $SKIP_OBSERVABILITY -eq 0 ]]; then
        echo "  Grafana:      http://localhost:3000"
        echo "  Prometheus:   http://localhost:9090"
        echo "  Alertmanager: http://localhost:9093"
    fi

    if [[ $SKIP_INFRASTRUCTURE -eq 0 ]]; then
        echo "  PostgreSQL:   localhost:5432"
        echo "  Redis:        localhost:6379"
        echo "  Nginx:        http://localhost"
    fi

    if [[ $WITH_APPS -eq 1 ]]; then
        echo "  FastAPI:      http://localhost:8000"
        echo "  Next.js:      http://localhost:3000"
        echo "  Vite:         http://localhost:5173"
        echo "  Flower:       http://localhost:5555"
    fi

    echo ""
    log_info "Next steps:"
    echo "  1. Check service status: docker compose ps"
    echo "  2. View logs: docker compose logs -f"
    echo "  3. Configure Grafana dashboards"
    echo "  4. Setup SSL certificates"
    echo ""
}

main "$@"
