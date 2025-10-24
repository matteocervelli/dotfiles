# Project Setup Script Template

## Purpose

This directory contains **template files** for development projects, including:
- **Project Setup Script** (`dev-setup.sh.template`) - Automates development environment setup
- **Asset Helpers** (`lib/assets.ts`, `lib/assets.py`) - Environment-aware asset URL resolution
- **Example Tests** (`lib/__tests__/`, `lib/tests/`) - Test templates for asset helpers

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

## Asset Helpers

### Overview

The asset helpers provide **environment-aware URL resolution** for assets (images, fonts, videos, ML models, etc.):
- **Development**: Uses local file paths (`/media/logo.png`)
- **Production**: Uses CDN URLs (`https://cdn.example.com/logo.png`)
- **Zero dependencies**: Pure TypeScript/Python implementations

### TypeScript/JavaScript Helper

**Location**: `lib/assets.ts` (370 lines)

**Features**:
- ✅ AssetResolver singleton class with cached environment detection
- ✅ getAssetUrl() convenience function
- ✅ useAsset() React hook with useMemo optimization
- ✅ batchResolveAssets() for multiple assets
- ✅ Full TypeScript types and JSDoc documentation
- ✅ Security: Path traversal prevention, HTTPS validation
- ✅ Works with: Next.js, Vite, React, any Node.js/browser environment

**Quick Start**:
```bash
# Copy to your TypeScript/JavaScript project
cp ~/dev/projects/dotfiles/templates/project/lib/assets.ts src/lib/
cp -r ~/dev/projects/dotfiles/templates/project/lib/__tests__ src/lib/
```

**Usage Examples**:

```tsx
// Next.js App Router
import { useAsset } from '@/lib/assets';

export default function Logo() {
  const logoUrl = useAsset(
    '/media/logo.png',
    'https://cdn.example.com/logos/logo.png'
  );
  return <img src={logoUrl} alt="Logo" />;
}

// Next.js Pages Router or Vite
import { getAssetUrl } from '@/lib/assets';

const bannerUrl = getAssetUrl(
  '/media/banner.jpg',
  'https://cdn.example.com/banners/hero.jpg'
);

// Batch resolution
import { batchResolveAssets } from '@/lib/assets';

const [logoUrl, bannerUrl, iconUrl] = batchResolveAssets([
  { localPath: '/media/logo.png', cdnUrl: 'https://cdn.example.com/logo.png' },
  { localPath: '/media/banner.jpg', cdnUrl: 'https://cdn.example.com/banner.jpg' },
  { localPath: '/media/icon.svg', cdnUrl: 'https://cdn.example.com/icon.svg' }
]);
```

**Environment Configuration**:
```bash
# .env.development
NODE_ENV=development
ASSET_MODE=auto  # optional, defaults to 'auto'

# .env.production
NODE_ENV=production
ASSET_MODE=auto
```

**Testing**:
```bash
# Copy example tests
cp ~/dev/projects/dotfiles/templates/project/lib/__tests__/assets.test.ts src/lib/__tests__/

# Run with Jest
npm install --save-dev jest @types/jest ts-jest
npm test

# Or with Vitest
npm install --save-dev vitest
npm run test
```

### Python Helper

**Location**: `lib/assets.py` (380 lines)

**Features**:
- ✅ AssetResolver singleton class with @lru_cache optimization
- ✅ get_asset_url() convenience function
- ✅ batch_resolve_assets() for multiple assets
- ✅ Complete type hints with typing module
- ✅ Comprehensive docstrings with examples
- ✅ Security: Path traversal prevention, HTTPS validation
- ✅ Works with: FastAPI, Flask, Django, standalone Python apps

**Quick Start**:
```bash
# Copy to your Python project
mkdir -p lib
cp ~/dev/projects/dotfiles/templates/project/lib/assets.py lib/
cp -r ~/dev/projects/dotfiles/templates/project/lib/tests tests/
```

**Usage Examples**:

```python
# FastAPI
from fastapi import FastAPI
from lib.assets import get_asset_url

app = FastAPI()

@app.get("/")
def read_root():
    return {
        "logo": get_asset_url('/static/logo.png', 'https://cdn.example.com/logo.png'),
        "banner": get_asset_url('/static/banner.jpg', 'https://cdn.example.com/banner.jpg')
    }

# Flask
from flask import Flask
from lib.assets import get_asset_url

app = Flask(__name__)

@app.route("/")
def index():
    logo_url = get_asset_url('/static/logo.png', 'https://cdn.example.com/logo.png')
    return f'<img src="{logo_url}" />'

# ML/AI Model Loading
from lib.assets import get_asset_url

model_path = get_asset_url(
    'data/models/whisper-large-v3.bin',
    'https://cdn.example.com/models/whisper-large-v3.bin',
    env_mode='local-always'  # Always use local for ML models
)
model = load_model(model_path)

# Batch resolution
from lib.assets import batch_resolve_assets

urls = batch_resolve_assets([
    {'local_path': '/static/logo.png', 'cdn_url': 'https://cdn.example.com/logo.png'},
    {'local_path': '/static/banner.jpg', 'cdn_url': 'https://cdn.example.com/banner.jpg'}
])
logo_url, banner_url = urls
```

**Environment Configuration**:
```bash
# .env.development
ENVIRONMENT=development
ASSET_MODE=auto  # optional, defaults to 'auto'

# .env.production
ENVIRONMENT=production
ASSET_MODE=auto
```

**Testing**:
```bash
# Copy example tests
mkdir -p tests
cp ~/dev/projects/dotfiles/templates/project/lib/tests/test_assets.py tests/

# Run with pytest
pip install pytest pytest-cov
pytest tests/test_assets.py -v
pytest tests/test_assets.py -v --cov=lib.assets
```

### Environment Modes

Both helpers support three environment modes:

1. **cdn-production-local-dev** (default)
   - Production: Uses CDN URL
   - Development: Uses local path
   - Most common use case

2. **cdn-always**
   - Always uses CDN URL regardless of environment
   - Useful for shared assets that must always come from CDN

3. **local-always**
   - Always uses local path regardless of environment
   - Useful for large files (ML models, datasets) that should never be downloaded

**Example**:
```typescript
// TypeScript
const url = getAssetUrl(
  '/data/model.bin',
  'https://cdn.example.com/model.bin',
  'local-always'  // Never download this 5GB model
);
```

```python
# Python
url = get_asset_url(
    '/data/model.bin',
    'https://cdn.example.com/model.bin',
    env_mode='local-always'
)
```

### Manual Override

Override environment detection with `ASSET_MODE` environment variable:

```bash
# Force local paths (useful for testing CDN failures)
ASSET_MODE=local npm run dev

# Force CDN URLs (useful for testing production behavior in dev)
ASSET_MODE=cdn npm run dev
```

### Security Features

Both helpers include security measures:
- ✅ **Path traversal prevention**: Rejects paths containing `..`
- ✅ **HTTPS validation**: Requires HTTPS in production environment
- ✅ **Input sanitization**: Validates all inputs before processing
- ✅ **No eval/exec**: Pure string manipulation, no code execution

### Performance Optimizations

- **TypeScript**: Singleton pattern caches environment detection
- **Python**: @lru_cache decorator caches environment detection
- **React hook**: useMemo prevents unnecessary re-renders
- **Zero network calls**: Pure URL resolution (no fetching)

### Integration with R2 Manifests

Asset helpers work alongside `.r2-manifest.yml` files:

```yaml
# .r2-manifest.yml
assets:
  - path: public/media/logo.png
    r2_key: media-cdn/logos/logo.png
    cdn_url: https://cdn.example.com/logos/logo.png
    sync: copy-from-library
```

```typescript
// In your code, reference the CDN URL from manifest
import manifest from '@/r2-manifest.yml';

const logoAsset = manifest.assets.find(a => a.path.endsWith('logo.png'));
const logoUrl = useAsset('/media/logo.png', logoAsset.cdn_url);
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
