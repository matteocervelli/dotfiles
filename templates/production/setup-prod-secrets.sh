#!/usr/bin/env bash
set -e

# Production Secret Setup for Docker Swarm/Compose
#
# This script creates Docker secrets from 1Password on production VPS
# Secrets are encrypted at rest and mounted as files (not env vars)
#
# Prerequisites:
#   - 1Password CLI installed on VPS
#   - Authenticated: eval $(op signin)
#   - Docker swarm initialized: docker swarm init
#
# Usage:
#   ./setup-prod-secrets.sh <project-name>
#
# Example:
#   ./setup-prod-secrets.sh APP-Discreto

PROJECT_NAME="${1:-APP-Discreto}"
VAULT_NAME="Projects"

echo "==> Setting up production secrets for $PROJECT_NAME"

# Check 1Password authentication
if ! op whoami &> /dev/null; then
    echo "Signing in to 1Password..."
    eval $(op signin)
fi

# Check Docker swarm mode (required for secrets)
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "Initializing Docker swarm mode..."
    docker swarm init
fi

# Create secrets from 1Password
echo "Creating Docker secrets from 1Password vault: $VAULT_NAME"

# Database password
if ! docker secret ls | grep -q "db_password"; then
    echo "  Creating db_password..."
    op read "op://$VAULT_NAME/database-prod/password" | \
        docker secret create db_password -
else
    echo "  ✓ db_password already exists"
fi

# API key
if ! docker secret ls | grep -q "api_key"; then
    echo "  Creating api_key..."
    op read "op://$VAULT_NAME/stripe-api/credential" | \
        docker secret create api_key -
else
    echo "  ✓ api_key already exists"
fi

# JWT secret
if ! docker secret ls | grep -q "jwt_secret"; then
    echo "  Creating jwt_secret..."
    op read "op://$VAULT_NAME/env-production/jwt_secret" | \
        docker secret create jwt_secret -
else
    echo "  ✓ jwt_secret already exists"
fi

echo ""
echo "✓ Production secrets configured!"
echo ""
echo "Secrets available:"
docker secret ls

echo ""
echo "Next steps:"
echo "  1. Create .env.prod with non-sensitive config:"
echo "     DB_HOST=db.example.com"
echo "     DB_NAME=app_prod"
echo "     DB_USER=app_user"
echo ""
echo "  2. Deploy application:"
echo "     docker compose -f docker-compose.prod.yml up -d"
echo ""
echo "  3. Secrets will be available in containers at:"
echo "     /run/secrets/db_password"
echo "     /run/secrets/api_key"
echo "     /run/secrets/jwt_secret"
