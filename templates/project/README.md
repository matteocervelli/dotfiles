# Project Setup Script Template

## Purpose

This template provides a standard `dev-setup.sh` script for all development projects, automating the complete development environment setup workflow.

## Features

The template automates:

1. **Git Operations** - Fetch and pull latest changes from remote
2. **Secret Management** - Inject secrets from 1Password using `.env.template`
3. **R2 Asset Sync** - Download binary assets from Cloudflare R2 (FASE 2.5)
4. **Manifest Updates** - Update asset manifest timestamps (FASE 2.5)
5. **Project-Specific Setup** - Extensible section for custom project needs

## Quick Start

### 1. Copy Template to New Project

```bash
# Copy template to your project
cp ~/dev/projects/dotfiles/templates/project/dev-setup.sh.template \
   ~/dev/projects/MY_PROJECT/scripts/dev-setup.sh

# Make it executable
chmod +x ~/dev/projects/MY_PROJECT/scripts/dev-setup.sh
```

### 2. Customize Project-Specific Setup

Edit `scripts/dev-setup.sh` and uncomment/modify section 5 based on your stack:

```bash
# Example for Node.js project
if [ -f "package.json" ]; then
    log_info "Installing npm dependencies..."
    npm install
    log_success "npm dependencies installed"
fi

# Example for Python project
if [ -f "requirements.txt" ]; then
    log_info "Installing Python dependencies..."
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -r requirements.txt
    log_success "Python dependencies installed"
fi
```

### 3. Run Setup

```bash
cd ~/dev/projects/MY_PROJECT
./scripts/dev-setup.sh
```

## Detailed Usage

### Git Operations (Section 1)

Automatically handles:
- Check if `.git` directory exists
- Fetch from remote origin
- Pull latest changes on current branch
- Handles branches without upstream gracefully

**When it runs**: Always (if git repository detected)

**Skip condition**: Not a git repository or no remote configured

### Secret Injection (Section 2)

Integrates with 1Password CLI to inject secrets into `.env` files.

**Prerequisites**:
- 1Password CLI installed: `brew install --cask 1password-cli`
- `.env.template` file in project root with 1Password references

**Template format** (`.env.template`):
```bash
# Database credentials
DATABASE_URL=op://vault/my-project/database_url
DB_PASSWORD=op://vault/my-project/db_password

# API keys
API_KEY=op://vault/my-project/api_key
API_SECRET=op://vault/my-project/api_secret

# Cloudflare R2
AWS_ACCESS_KEY_ID=op://vault/r2-cloudflare/access_key
AWS_SECRET_ACCESS_KEY=op://vault/r2-cloudflare/secret_key
```

**Workflow**:
1. Script checks if `.env.template` exists
2. Authenticates with 1Password (prompts if needed)
3. Calls `inject-env.sh` or falls back to `op inject`
4. Generates `.env` file with actual secrets
5. `.env` is gitignored (never committed)

**When it runs**: If `.env.template` file exists

### R2 Asset Sync (Section 3)

Downloads binary assets from Cloudflare R2 storage based on manifest.

**Prerequisites**:
- Rclone installed and configured: `~/dev/projects/dotfiles/scripts/sync/setup-rclone.sh`
- `.r2-manifest.yml` file in project root
- R2 sync scripts implemented (FASE 2.5)

**Manifest format** (`.r2-manifest.yml`):
```yaml
project: my-project
version: "1.0"
updated: 2025-01-22T10:30:00Z

assets:
  - path: data/models/whisper-large-v3.bin
    r2_key: my-project/models/whisper-large-v3.bin
    size: 2847213568
    sha256: a1b2c3d4e5f6...
    type: model
    sync: true
    devices: [macbook, mac-studio]
    description: "OpenAI Whisper Large V3 model"
```

**Workflow**:
1. Script checks if `.r2-manifest.yml` exists
2. Calls `sync-r2.sh pull` to download assets
3. Verifies checksums after download
4. Updates manifest timestamps

**When it runs**: If `.r2-manifest.yml` file exists

**Current status**: ⚠️ Section 3 ready for FASE 2.5 - currently shows helpful message

### Project-Specific Setup (Section 5)

**Customize this section** for your project's needs. Common examples:

#### Node.js / JavaScript / TypeScript
```bash
if [ -f "package.json" ]; then
    log_info "Installing npm dependencies..."
    npm install
    log_success "npm dependencies installed"
fi
```

#### Python
```bash
if [ -f "requirements.txt" ]; then
    log_info "Installing Python dependencies..."
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -r requirements.txt
    log_success "Python dependencies installed"
fi
```

#### Docker
```bash
if [ -f "docker-compose.yml" ]; then
    log_info "Pulling Docker images..."
    docker compose pull
    log_success "Docker images pulled"
fi
```

#### Database Migrations
```bash
if [ -d "migrations" ]; then
    log_info "Running database migrations..."
    npm run migrate  # or: python manage.py migrate
    log_success "Migrations complete"
fi
```

#### Build / Compile
```bash
if [ -f "Makefile" ]; then
    log_info "Running build..."
    make build
    log_success "Build complete"
fi
```

## Integration with Dotfiles

This script depends on scripts from your dotfiles repository:

### Required (FASE 1-2.1)
- `~/dev/projects/dotfiles/scripts/secrets/inject-env.sh` - Secret injection

### Optional (FASE 2.5+)
- `~/dev/projects/dotfiles/scripts/sync/sync-r2.sh` - R2 asset sync
- `~/dev/projects/dotfiles/scripts/sync/update-manifest.sh` - Manifest updates

**Ensure dotfiles are installed**: `cd ~/dev/projects/dotfiles && make install`

## Requirements

### Core Requirements
- **Bash 3.2+** (macOS default) or **Bash 4+** (Linux)
- **Git** (for git operations)

### Optional Requirements
- **1Password CLI** (`op`) - For secret injection
  ```bash
  brew install --cask 1password-cli
  eval $(op signin)
  ```

- **Rclone** - For R2 asset sync (FASE 2.5)
  ```bash
  brew install rclone
  ~/dev/projects/dotfiles/scripts/sync/setup-rclone.sh
  ```

## Best Practices

### 1. Commit Template, Not Generated Script
- Commit `dev-setup.sh` to your project's git repository
- Each project can customize it for specific needs
- Keep it updated as project requirements change

### 2. Run on Every Environment Setup
- New machine setup
- After clean clone
- VM or container initialization
- Onboarding new team members

### 3. Make it Idempotent
- Safe to run multiple times
- Checks before executing
- Updates rather than duplicates

### 4. Document Custom Steps
```bash
# Example: Add comments for complex setup
# Install Swift dependencies (requires Xcode)
if [ -f "Package.swift" ]; then
    log_info "Building Swift package..."
    swift build
    log_success "Swift package built"
fi
```

### 5. Create Project Alias
Add to your shell config (`.zshrc` or `.bashrc`):
```bash
# In project root
alias dev-setup='./scripts/dev-setup.sh'
```

Then simply run: `dev-setup`

## Troubleshooting

### 1Password Authentication Fails
```bash
# Symptom: "op: not signed in"
# Solution: Sign in manually
eval $(op signin)

# Then run setup again
./scripts/dev-setup.sh
```

### Secret Injection Fails
```bash
# Check if .env.template has correct format
cat .env.template

# Verify 1Password references
op read "op://vault/item/field"

# Test injection manually
op inject -i .env.template -o .env
```

### Git Pull Conflicts
```bash
# Script will fail if there are local changes
# Stash or commit changes before running
git stash
./scripts/dev-setup.sh
git stash pop
```

### R2 Sync Not Working (FASE 2.5)
```bash
# Check rclone configuration
rclone lsd r2:

# Verify manifest exists
cat .r2-manifest.yml

# Test sync manually
rclone sync r2:dotfiles-assets/MY_PROJECT/ data/
```

### Permission Denied
```bash
# Make script executable
chmod +x scripts/dev-setup.sh

# Check file ownership
ls -la scripts/dev-setup.sh
```

## Examples

### Full Stack Next.js + PostgreSQL Project
```bash
# Section 5 customization
if [ -f "package.json" ]; then
    log_info "Installing npm dependencies..."
    npm install
    log_success "Dependencies installed"
fi

if command -v docker &> /dev/null; then
    log_info "Starting PostgreSQL container..."
    docker compose up -d postgres
    sleep 3
    log_info "Running migrations..."
    npm run db:migrate
    log_success "Database ready"
fi

log_info "Starting development server..."
log_info "Run: npm run dev"
```

### Python ML Project with R2 Assets
```bash
# Section 5 customization
if [ -f "requirements.txt" ]; then
    log_info "Setting up Python environment..."
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -r requirements.txt
    log_success "Python environment ready"
fi

# Assets already synced from R2 in section 3
log_info "ML models downloaded from R2:"
ls -lh data/models/
```

### Swift iOS Project
```bash
# Section 5 customization
if [ -f "Package.swift" ]; then
    log_info "Resolving Swift packages..."
    swift package resolve
    log_info "Building project..."
    swift build
    log_success "Swift project built"
fi

log_info "Open in Xcode:"
echo "  open *.xcodeproj"
```

## Version History

- **v1.0** (2025-01-22) - Initial template with Git, 1Password, R2 placeholder integration

## Related Documentation

- [1Password CLI Integration](../../scripts/secrets/README.md)
- [R2 Asset Management](../../sync/manifests/README.md) (FASE 2.5)
- [Dotfiles Architecture](../../docs/ARCHITECTURE-DECISIONS.md)
- [Implementation Plan](../../docs/IMPLEMENTATION-PLAN.md)

## Support

For issues or questions:
1. Check dotfiles health: `cd ~/dev/projects/dotfiles && make health`
2. Review dotfiles documentation: `~/dev/projects/dotfiles/docs/`
3. Verify dependencies installed: `make bootstrap`

## License

Part of personal dotfiles repository - customize freely for your projects.
