#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/logger.sh"

# ==============================================================================
# Create 1Password Secret with Multi-Level Tagging
# ==============================================================================
#
# Tag Strategy: [PROJECT] + [ENVIRONMENT] + [TYPE] + [CUSTOM]
#
# Usage:
#   ./create-project-secret-v3.sh <category> <project> <environment> <item-title> [options]
#
# Examples:
#   # Development database
#   ./create-project-secret-v3.sh database APP-Discreto development postgres-dev \
#     --hostname=localhost --port=5432 --database=discreto_dev \
#     --username=dev_user --password=$(openssl rand -base64 32)
#
#   # Production database
#   ./create-project-secret-v3.sh database APP-Discreto production postgres-prod \
#     --hostname=db.example.com --port=5432 --database=discreto_prod \
#     --username=prod_user --password=$(openssl rand -base64 32) \
#     --additional-tags=critical,encrypted
#
#   # Shared Stripe secret for multiple projects (production)
#   ./create-project-secret-v3.sh api APP-Discreto production stripe-api \
#     --credential=sk_live_123 \
#     --additional-tags=WEB-AdLimen,payment,shared
#
#   # Staging API
#   ./create-project-secret-v3.sh api API-Analytics staging openai-api \
#     --credential=sk-test-123 --additional-tags=ai,testing
# ==============================================================================

VAULT_NAME="Projects"

usage() {
    cat <<EOF
Usage: $0 <category> <project> <environment> <item-title> [options]

Arguments:
  category          Secret category (database, api, login, server, secure-note)
  project           Project name (e.g., APP-Discreto, WEB-AdLimen)
  environment       Environment (development, staging, production, ci)
  item-title        Item name (e.g., postgres-dev, stripe-api, redis-cache)

Environments:
  development       Local development
  staging           Staging/testing environment
  production        Production environment
  ci                CI/CD pipelines
  qa                QA/testing
  demo              Demo environment

Categories:
  database          Database with hostname, port, username, password
  api               API Credential with credential (API key)
  login             Login with username, password, url
  server            Server with url, username, password
  secure-note       Secure Note with custom fields

Common Options:
  --additional-tags=tag1,tag2    Add extra tags (type, feature, shared projects)
  --type=<type>                  Secret type (postgresql, mysql, redis, stripe, etc.)

Database Options:
  --hostname=<host>
  --port=<port>
  --database=<name>
  --username=<user>
  --password=<pass>
  --type=<dbtype>               (postgresql, mysql, mongodb, redis)

API Options:
  --credential=<key>
  --username=<user>             (optional)
  --type=<apitype>              (stripe, openai, github, aws, etc.)

Examples:
  # Development PostgreSQL
  $0 database APP-Discreto development postgres-dev \\
    --hostname=localhost --port=5432 --database=app_dev \\
    --username=dev_user --password=\$(openssl rand -base64 32) \\
    --type=postgresql

  # Production Stripe (shared with WEB-AdLimen)
  $0 api APP-Discreto production stripe-api \\
    --credential=sk_live_123456 --type=stripe \\
    --additional-tags=WEB-AdLimen,payment,shared,critical

  # Staging Redis (shared cache)
  $0 secure-note API-Analytics staging redis-cache \\
    --host=redis-staging.example.com --port=6379 \\
    --password=redispass --type=redis \\
    --additional-tags=API-ClientX,cache,shared

  # CI/CD GitHub token
  $0 api APP-Discreto ci github-actions \\
    --credential=ghp_\$(openssl rand -hex 20) --type=github \\
    --additional-tags=automation

Tag Structure:
  Automatic tags: <project>, <environment>
  Type tag: --type=<type> adds to tags automatically
  Custom tags: --additional-tags=tag1,tag2

Query Examples:
  # All APP-Discreto secrets
  op item list --vault=Projects --tags=APP-Discreto

  # All production secrets
  op item list --vault=Projects --tags=production

  # APP-Discreto production secrets only
  op item list --vault=Projects --tags=APP-Discreto,production

  # All database secrets across projects
  op item list --vault=Projects --tags=database

  # Shared secrets (multi-project)
  op item list --vault=Projects --tags=shared

EOF
    exit 1
}

# Parse arguments
if [ $# -lt 4 ]; then
    usage
fi

CATEGORY="$1"
PROJECT_NAME="$2"
ENVIRONMENT="$3"
ITEM_TITLE="$4"
shift 4

# Validate environment
case "$ENVIRONMENT" in
    development|dev|local)
        ENVIRONMENT="development"
        ;;
    staging|stage)
        ENVIRONMENT="staging"
        ;;
    production|prod)
        ENVIRONMENT="production"
        ;;
    ci|cicd|ci-cd)
        ENVIRONMENT="ci"
        ;;
    qa|test|testing)
        ENVIRONMENT="qa"
        ;;
    demo)
        ENVIRONMENT="demo"
        ;;
    *)
        log_error "Invalid environment: $ENVIRONMENT"
        log_info "Valid: development, staging, production, ci, qa, demo"
        exit 1
        ;;
esac

# Map category
case "$CATEGORY" in
    database|db)
        OP_CATEGORY="Database"
        AUTO_TYPE_TAG="database"
        ;;
    api|api-credential)
        OP_CATEGORY="API Credential"
        AUTO_TYPE_TAG="api"
        ;;
    login)
        OP_CATEGORY="Login"
        AUTO_TYPE_TAG="login"
        ;;
    server|ssh)
        OP_CATEGORY="Server"
        AUTO_TYPE_TAG="server"
        ;;
    secure-note|note)
        OP_CATEGORY="Secure Note"
        AUTO_TYPE_TAG=""
        ;;
    *)
        log_error "Unknown category: $CATEGORY"
        exit 1
        ;;
esac

# Parse options
FIELDS=()
ADDITIONAL_TAGS=""
SECRET_TYPE=""

for arg in "$@"; do
    if [[ "$arg" == --additional-tags=* ]]; then
        ADDITIONAL_TAGS="${arg#--additional-tags=}"
    elif [[ "$arg" == --type=* ]]; then
        SECRET_TYPE="${arg#--type=}"
    elif [[ "$arg" == --* ]]; then
        FIELD="${arg#--}"
        FIELDS+=("$FIELD")
    else
        log_error "Invalid argument: $arg"
        usage
    fi
done

log_step "Creating 1Password $OP_CATEGORY"
log_info "Project: $PROJECT_NAME"
log_info "Environment: $ENVIRONMENT"
log_info "Item: $ITEM_TITLE"
log_info "Vault: $VAULT_NAME"
log_info "Category: $OP_CATEGORY"

# Check 1Password authentication
if ! op whoami &> /dev/null; then
    log_info "Signing in to 1Password..."
    eval $(op signin)
fi

# Check if Projects vault exists
if ! op vault get "$VAULT_NAME" &> /dev/null; then
    log_warning "Vault '$VAULT_NAME' not found, creating..."
    op vault create "$VAULT_NAME"
    log_success "Created vault: $VAULT_NAME"
fi

# Build tags list with hierarchy
# Format: project, environment, type, custom
TAGS="$PROJECT_NAME,$ENVIRONMENT"

# Add category type tag
if [ -n "$AUTO_TYPE_TAG" ]; then
    TAGS="$TAGS,$AUTO_TYPE_TAG"
fi

# Add secret type tag (postgresql, stripe, redis, etc.)
if [ -n "$SECRET_TYPE" ]; then
    TAGS="$TAGS,$SECRET_TYPE"
fi

# Add additional tags
if [ -n "$ADDITIONAL_TAGS" ]; then
    TAGS="$TAGS,$ADDITIONAL_TAGS"
fi

log_info "Tags: $TAGS"

# Build command
CMD=(op item create
    --category="$OP_CATEGORY"
    --title="$ITEM_TITLE"
    --vault="$VAULT_NAME"
    --tags="$TAGS"
)

# Add fields
log_info "Fields:"
for field in "${FIELDS[@]}"; do
    KEY="${field%%=*}"
    log_info "  - $KEY"
    CMD+=("$field")
done

# Create item
log_info "Creating item in 1Password..."
if OUTPUT=$("${CMD[@]}" 2>&1); then
    log_success "Secret created: $ITEM_TITLE"

    echo ""
    log_success "$OP_CATEGORY created successfully!"
    echo ""
    echo "📋 Item Details:"
    echo "  Name: $ITEM_TITLE"
    echo "  Tags: $TAGS"
    echo ""
    echo "🔍 Query Examples:"
    echo ""
    echo "  # All $PROJECT_NAME secrets:"
    echo "  op item list --vault=$VAULT_NAME --tags=$PROJECT_NAME"
    echo ""
    echo "  # All $ENVIRONMENT secrets across projects:"
    echo "  op item list --vault=$VAULT_NAME --tags=$ENVIRONMENT"
    echo ""
    echo "  # $PROJECT_NAME $ENVIRONMENT secrets only:"
    echo "  op item list --vault=$VAULT_NAME --tags=$PROJECT_NAME,$ENVIRONMENT"
    echo ""

    # Show .env.template reference
    echo "📝 Use in .env.$ENVIRONMENT.template:"
    echo ""

    case "$OP_CATEGORY" in
        "Database")
            echo "  DATABASE_URL=op://$VAULT_NAME/$ITEM_TITLE/username:op://$VAULT_NAME/$ITEM_TITLE/password@op://$VAULT_NAME/$ITEM_TITLE/hostname:op://$VAULT_NAME/$ITEM_TITLE/port/op://$VAULT_NAME/$ITEM_TITLE/database"
            echo "  DB_HOST=op://$VAULT_NAME/$ITEM_TITLE/hostname"
            echo "  DB_PASSWORD=op://$VAULT_NAME/$ITEM_TITLE/password"
            ;;
        "API Credential")
            echo "  API_KEY=op://$VAULT_NAME/$ITEM_TITLE/credential"
            ;;
        "Login")
            echo "  LOGIN_URL=op://$VAULT_NAME/$ITEM_TITLE/url"
            echo "  LOGIN_USER=op://$VAULT_NAME/$ITEM_TITLE/username"
            echo "  LOGIN_PASS=op://$VAULT_NAME/$ITEM_TITLE/password"
            ;;
    esac

    echo ""
    log_info "Environment-specific files:"
    echo "  .env.development.template  → Development secrets"
    echo "  .env.staging.template      → Staging secrets"
    echo "  .env.production.template   → Production secrets"
    echo ""

else
    log_error "Failed to create secret"
    echo "$OUTPUT"
    exit 1
fi
