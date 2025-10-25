# Project Templates

## Overview

This directory contains **reusable templates** for setting up new development projects with best practices built-in:

- **Project Setup Scripts** - Automated environment initialization
- **Asset Helpers** - Environment-aware URL resolution (TypeScript & Python)
- **Environment Templates** - 1Password-integrated secret management
- **Example Tests** - Comprehensive test suites for asset helpers

## Available Templates

### 1. Project Setup Template

**Location**: [`templates/project/`](project/)

Complete project initialization template with:
- Git operations (fetch, pull)
- Secret injection from 1Password
- R2 asset synchronization
- Project-specific setup hooks

**Documentation**: [templates/project/README.md](project/README.md)

### 2. Asset Helper Templates

Environment-aware asset URL resolution libraries:

#### TypeScript/JavaScript Helper
**File**: [`templates/project/lib/assets.ts`](project/lib/assets.ts) (370 lines)

**Features**:
- ✅ AssetResolver singleton with cached environment detection
- ✅ `getAssetUrl()` convenience function
- ✅ `useAsset()` React hook with useMemo optimization
- ✅ `batchResolveAssets()` for multiple assets
- ✅ Full TypeScript types and JSDoc
- ✅ Zero dependencies

**Works with**: Next.js, Vite, React, any Node.js/browser environment

#### Python Helper
**File**: [`templates/project/lib/assets.py`](project/lib/assets.py) (380 lines)

**Features**:
- ✅ AssetResolver singleton with @lru_cache optimization
- ✅ `get_asset_url()` convenience function
- ✅ `batch_resolve_assets()` for multiple assets
- ✅ Complete type hints with typing module
- ✅ Comprehensive docstrings
- ✅ Zero dependencies

**Works with**: FastAPI, Flask, Django, standalone Python apps

### 3. Example Tests

Comprehensive test suites showing how to test asset helpers:

**TypeScript Tests**: [`templates/project/lib/__tests__/assets.test.ts`](project/lib/__tests__/assets.test.ts) (280 lines)
- Jest/Vitest compatible
- 36 test cases covering all scenarios
- Environment mocking examples

**Python Tests**: [`templates/project/lib/tests/test_assets.py`](project/lib/tests/test_assets.py) (440 lines)
- pytest compatible
- 27 test cases with fixtures
- Mock environment examples

## Quick Start

### Using Asset Helpers in a New Project

#### TypeScript/React Project

```bash
# 1. Copy helper to your project
cp ~/dev/projects/dotfiles/templates/project/lib/assets.ts src/lib/

# 2. Copy tests (optional but recommended)
mkdir -p src/lib/__tests__
cp ~/dev/projects/dotfiles/templates/project/lib/__tests__/assets.test.ts src/lib/__tests__/

# 3. Use in your code
```

**Next.js example** (`app/components/Logo.tsx`):
```typescript
import { useAsset } from '@/lib/assets';

export default function Logo() {
  const logoUrl = useAsset(
    '/media/logo.png',
    'https://cdn.example.com/logos/logo.png'
  );

  return <img src={logoUrl} alt="Logo" />;
}
```

**Vite example** (`src/components/Hero.tsx`):
```typescript
import { getAssetUrl } from '@/lib/assets';

export function Hero() {
  const bannerUrl = getAssetUrl(
    '/assets/banner.jpg',
    'https://cdn.example.com/banners/hero.jpg'
  );

  return <img src={bannerUrl} alt="Hero" />;
}
```

#### Python/FastAPI Project

```bash
# 1. Copy helper to your project
mkdir -p lib
cp ~/dev/projects/dotfiles/templates/project/lib/assets.py lib/

# 2. Copy tests (optional but recommended)
mkdir -p tests
cp ~/dev/projects/dotfiles/templates/project/lib/tests/test_assets.py tests/

# 3. Use in your code
```

**FastAPI example** (`app/main.py`):
```python
from fastapi import FastAPI
from lib.assets import get_asset_url

app = FastAPI()

@app.get("/")
def read_root():
    return {
        "logo": get_asset_url('/static/logo.png', 'https://cdn.example.com/logo.png'),
        "banner": get_asset_url('/static/banner.jpg', 'https://cdn.example.com/banner.jpg')
    }
```

**Flask example** (`app.py`):
```python
from flask import Flask, render_template
from lib.assets import get_asset_url

app = Flask(__name__)

@app.route("/")
def index():
    context = {
        'logo_url': get_asset_url('/static/logo.png', 'https://cdn.example.com/logo.png')
    }
    return render_template('index.html', **context)
```

## Environment Configuration

### TypeScript/JavaScript

Create `.env.development` and `.env.production`:

```bash
# .env.development
NODE_ENV=development
ASSET_MODE=auto  # Uses local paths in dev

# .env.production
NODE_ENV=production
ASSET_MODE=auto  # Uses CDN URLs in prod
```

### Python

Create `.env.development` and `.env.production`:

```bash
# .env.development
ENVIRONMENT=development
ASSET_MODE=auto  # Uses local paths in dev

# .env.production
ENVIRONMENT=production
ASSET_MODE=auto  # Uses CDN URLs in prod
```

## Asset Helper Features

### Environment Detection

**Automatic** (based on NODE_ENV or ENVIRONMENT):
```typescript
// Development
const url = getAssetUrl('/media/logo.png', 'https://cdn.example.com/logo.png');
// Returns: '/media/logo.png'

// Production
const url = getAssetUrl('/media/logo.png', 'https://cdn.example.com/logo.png');
// Returns: 'https://cdn.example.com/logo.png'
```

**Manual override** (via ASSET_MODE):
```bash
# Force local paths (useful for offline testing)
ASSET_MODE=local npm run dev

# Force CDN URLs (useful for testing production behavior)
ASSET_MODE=cdn npm run dev
```

### Environment Modes

**cdn-production-local-dev** (default):
```typescript
// Most common use case
const url = getAssetUrl('/media/hero.jpg', 'https://cdn.example.com/hero.jpg');
// Dev: '/media/hero.jpg' | Prod: 'https://cdn.example.com/hero.jpg'
```

**cdn-always**:
```typescript
// Always use CDN (shared assets, third-party embeds)
const url = getAssetUrl(
  '/media/shared.jpg',
  'https://cdn.example.com/shared.jpg',
  'cdn-always'
);
// Dev: 'https://cdn.example.com/shared.jpg' | Prod: 'https://cdn.example.com/shared.jpg'
```

**local-always**:
```typescript
// Always use local (large files, ML models)
const url = getAssetUrl(
  '/data/model.bin',
  'https://cdn.example.com/model.bin',
  'local-always'
);
// Dev: '/data/model.bin' | Prod: '/data/model.bin'
```

### Security Features

Both helpers include built-in security:

✅ **Path traversal prevention**: Rejects paths containing `..`
```typescript
getAssetUrl('../../../etc/passwd', 'https://cdn.example.com/file')
// Throws: "Invalid local path: contains directory traversal"
```

✅ **HTTPS validation in production**: Requires secure CDN URLs
```typescript
// In production
getAssetUrl('/media/logo.png', 'http://cdn.example.com/logo.png')
// Throws: "CDN URL must use HTTPS in production environment"
```

✅ **Input sanitization**: Validates all parameters
```typescript
getAssetUrl('', '')
// Throws: "Local path cannot be empty"
```

### Performance Optimizations

**TypeScript**:
- Singleton pattern caches environment detection
- React hook uses `useMemo` to prevent re-renders
- Zero network calls (pure URL resolution)

**Python**:
- `@lru_cache` decorator caches environment detection
- No I/O operations for URL resolution
- Zero external dependencies

## Testing

### TypeScript/Jest

```bash
# Install test dependencies
npm install --save-dev jest @types/jest ts-jest

# Copy test file
cp ~/dev/projects/dotfiles/templates/project/lib/__tests__/assets.test.ts src/lib/__tests__/

# Run tests
npm test
```

**Test coverage**: 36 test cases covering:
- Environment detection (development, production, test)
- Mode overrides (cdn-production-local-dev, cdn-always, local-always)
- Manual ASSET_MODE override
- Security validation (path traversal, HTTPS check)
- Edge cases (empty paths, invalid inputs)
- React hook behavior (useAsset)
- Batch operations

### TypeScript/Vitest

```bash
# Install Vitest
npm install --save-dev vitest

# Tests are already Vitest-compatible
npm run test
```

### Python/pytest

```bash
# Install pytest
pip install pytest pytest-cov

# Copy test file
mkdir -p tests
cp ~/dev/projects/dotfiles/templates/project/lib/tests/test_assets.py tests/

# Run tests
pytest tests/test_assets.py -v

# With coverage
pytest tests/test_assets.py -v --cov=lib.assets --cov-report=html
```

**Test coverage**: 27 test cases covering:
- Environment detection (development, production, test)
- Mode overrides (all three modes)
- Manual ASSET_MODE override
- Security validation
- Edge cases
- Batch operations
- Type hint validation

## Integration with R2 Manifests

Asset helpers work alongside `.r2-manifest.yml` files:

**Example workflow**:

1. **Create manifest** with CDN URLs:
```yaml
# .r2-manifest.yml
project: my-app
assets:
  - path: public/media/logo.png
    r2_key: media-cdn/logos/logo.png
    cdn_url: https://cdn.example.com/logos/logo.png
    sync: copy-from-library
    env_mode: cdn-production-local-dev
```

2. **Sync assets** to local project:
```bash
sync-project pull
# Copies logo.png from ~/media/cdn/ to public/media/
```

3. **Use in code** with asset helper:
```typescript
import manifest from '@/.r2-manifest.yml';

const logoAsset = manifest.assets.find(a => a.path.endsWith('logo.png'));
const logoUrl = useAsset(logoAsset.path, logoAsset.cdn_url);
// Dev: 'public/media/logo.png' | Prod: 'https://cdn.example.com/logos/logo.png'
```

4. **Deploy to production**:
```bash
# Build uses CDN URLs automatically
npm run build
# All asset references use https://cdn.example.com/...
```

## Best Practices

### 1. Use Type-Safe Imports

**TypeScript**:
```typescript
import { getAssetUrl, useAsset, batchResolveAssets } from '@/lib/assets';
// TypeScript autocomplete and type checking
```

**Python**:
```python
from lib.assets import get_asset_url, batch_resolve_assets
from typing import List
# Type hints provide IDE autocomplete
```

### 2. Batch Operations for Multiple Assets

**TypeScript**:
```typescript
const [logoUrl, bannerUrl, iconUrl] = batchResolveAssets([
  { localPath: '/media/logo.png', cdnUrl: 'https://cdn.example.com/logo.png' },
  { localPath: '/media/banner.jpg', cdnUrl: 'https://cdn.example.com/banner.jpg' },
  { localPath: '/media/icon.svg', cdnUrl: 'https://cdn.example.com/icon.svg' }
]);
```

**Python**:
```python
urls = batch_resolve_assets([
    {'local_path': '/static/logo.png', 'cdn_url': 'https://cdn.example.com/logo.png'},
    {'local_path': '/static/banner.jpg', 'cdn_url': 'https://cdn.example.com/banner.jpg'}
])
logo_url, banner_url = urls
```

### 3. Centralize Asset Configuration

**Create asset config file** (`src/lib/assetConfig.ts`):
```typescript
export const ASSETS = {
  logo: {
    localPath: '/media/logo.png',
    cdnUrl: 'https://cdn.example.com/logos/logo.png'
  },
  banner: {
    localPath: '/media/banner.jpg',
    cdnUrl: 'https://cdn.example.com/banners/hero.jpg'
  }
} as const;
```

**Use in components**:
```typescript
import { useAsset } from '@/lib/assets';
import { ASSETS } from '@/lib/assetConfig';

export function Logo() {
  const url = useAsset(ASSETS.logo.localPath, ASSETS.logo.cdnUrl);
  return <img src={url} alt="Logo" />;
}
```

### 4. Generate Config from Manifest

**Automate asset config generation**:
```typescript
// scripts/generate-asset-config.ts
import manifest from '../.r2-manifest.yml';
import fs from 'fs';

const config = manifest.assets.reduce((acc, asset) => {
  const key = asset.path.split('/').pop().replace(/\.[^/.]+$/, '');
  acc[key] = {
    localPath: asset.path,
    cdnUrl: asset.cdn_url
  };
  return acc;
}, {});

fs.writeFileSync(
  'src/lib/assetConfig.generated.ts',
  `export const ASSETS = ${JSON.stringify(config, null, 2)} as const;`
);
```

### 5. Test Both Environments

```bash
# Test development mode
NODE_ENV=development npm run dev

# Test production mode locally
NODE_ENV=production npm run build && npm run preview

# Test with CDN override
ASSET_MODE=cdn npm run dev
```

## Troubleshooting

### TypeScript Import Errors

**Problem**: `Cannot find module '@/lib/assets'`

**Solution**: Configure TypeScript path alias in `tsconfig.json`:
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  }
}
```

### React Hook Not Re-rendering

**Problem**: Asset URL doesn't update when environment changes

**Cause**: `useAsset` caches based on inputs

**Solution**: Change `ASSET_MODE` triggers re-detection automatically. For dynamic switching at runtime, use `getAssetUrl` directly:
```typescript
const [mode, setMode] = useState<'local' | 'cdn'>('auto');
const url = getAssetUrl('/media/logo.png', 'https://cdn.example.com/logo.png');
// Updates on mode change
```

### Python Import Errors

**Problem**: `ModuleNotFoundError: No module named 'lib'`

**Solution**: Ensure `lib/__init__.py` exists:
```bash
touch lib/__init__.py
```

### CDN URLs Not Working in Development

**Problem**: Assets load from CDN even with `NODE_ENV=development`

**Possible causes**:
1. **ASSET_MODE override**: Check if `ASSET_MODE=cdn` is set
2. **env_mode**: Asset might have `cdn-always` mode
3. **.env not loaded**: Verify dotenv configuration

**Debug**:
```typescript
import { AssetResolver } from '@/lib/assets';

console.log(process.env.NODE_ENV);           // Should be 'development'
console.log(process.env.ASSET_MODE);         // Should be undefined or 'auto'
console.log(AssetResolver.getInstance().getEnvironment());  // Should be 'development'
```

## Related Documentation

- [Project Setup Template](project/README.md) - Complete dev-setup.sh documentation
- [R2 Asset Manifests](../sync/manifests/README.md) - Manifest system and sync workflows
- [Central Library Guide](../sync/library/README.md) - Managing the ~/media/cdn/ library
- [Asset Management Plan](../docs/ASSET-MANAGEMENT-PLAN.md) - Architecture and decisions

## Command Reference

| Command | Purpose |
|---------|---------|
| `sync-project pull` | Download project assets from library/R2 |
| `update-cdn` | Update central library and propagate to projects |
| `cdnsync` | Sync central library to R2 |

---

**Last Updated**: 2025-01-24
**Related Issues**: [#32](https://github.com/matteocervelli/dotfiles/issues/32), [#34](https://github.com/matteocervelli/dotfiles/issues/34)
