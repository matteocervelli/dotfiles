# Dotfiles

Personal dotfiles and development environment configuration for macOS.

## 🚀 Features

- ✅ ZSH configuration with custom aliases and functions
- ✅ Git configuration and aliases
- ✅ Development tools setup
- ✅ **Asset Management System** - Central library with auto-update propagation
- ✅ **Environment-Aware Helpers** - TypeScript & Python asset URL resolution
- ✅ R2 sync with Cloudflare integration
- 🚧 IDE configurations (in progress)

## 🛠️ Tech Stack

- [ZSH](https://www.zsh.org/) - Shell
- [Git](https://git-scm.com/) - Version control
- [Homebrew](https://brew.sh/) - Package manager

## 📦 Installation

```bash
git clone https://github.com/matteocervelli/dotfiles.git
cd dotfiles
./install.sh
```

## 🧪 Usage

```bash
# Source the configurations
source ~/.zshrc
```

## 📦 Asset Management System

Comprehensive asset management with central library, auto-update propagation, and environment-aware URL resolution.

### Quick Start

**Update central library and propagate to projects**:
```bash
update-cdn
# Regenerates manifest → Shows changes → Propagates to projects → Syncs to R2
```

**Sync project assets**:
```bash
cd ~/dev/projects/MY_PROJECT
sync-project pull
# Copies from ~/media/cdn/ (fast) or downloads from R2 (fallback)
```

**Sync library to R2**:
```bash
cdnsync
# Uploads ~/media/cdn/ to Cloudflare R2
```

### Key Features

1. **Central Library** (`~/media/cdn/`)
   - Single source of truth for shared assets
   - Automatic dimension extraction for images
   - Bidirectional R2 sync

2. **Auto-Update Propagation**
   - Detects library changes (size, dimensions, checksum)
   - Updates all affected projects automatically
   - Shows before/after comparison

3. **Library-First Sync**
   - Projects copy from library first (<0.1s per file)
   - Falls back to R2 download if needed (1-5s per file)
   - 90% library efficiency typical

4. **Environment-Aware Assets**
   - Development: Uses local paths (`/media/logo.svg`)
   - Production: Uses CDN URLs (`https://cdn.example.com/logo.svg`)
   - Zero dependencies TypeScript & Python helpers

### Command Reference

| Command | Purpose | Documentation |
|---------|---------|---------------|
| `update-cdn` | Update library + propagate + sync | [Central Library Guide](sync/library/README.md) |
| `sync-project pull` | Sync project assets | [Project Sync Guide](sync/manifests/README.md#3-sync-project-assets-new---issue-30) |
| `cdnsync` | Sync library to R2 | [Rclone Setup](sync/rclone/README.md) |
| `setup-rclone` | Configure R2 connection | [Rclone Setup](sync/rclone/README.md) |
| `test-rclone` | Test R2 connection | [Rclone Setup](sync/rclone/README.md) |

### Asset Helpers

Copy environment-aware asset helpers to your projects:

**TypeScript/React** (`templates/project/lib/assets.ts`):
```typescript
import { useAsset } from '@/lib/assets';

const logoUrl = useAsset('/media/logo.png', 'https://cdn.example.com/logo.png');
// Dev: '/media/logo.png' | Prod: 'https://cdn.example.com/logo.png'
```

**Python/FastAPI** (`templates/project/lib/assets.py`):
```python
from lib.assets import get_asset_url

logo_url = get_asset_url('/static/logo.png', 'https://cdn.example.com/logo.png')
# Dev: '/static/logo.png' | Prod: 'https://cdn.example.com/logo.png'
```

### Documentation

- **Central Library**: [sync/library/README.md](sync/library/README.md) - Managing ~/media/cdn/
- **Project Manifests**: [sync/manifests/README.md](sync/manifests/README.md) - Asset sync workflows
- **Asset Helpers**: [templates/README.md](templates/README.md) - TypeScript & Python helpers
- **Schema Reference**: [sync/manifests/schema.yml](sync/manifests/schema.yml) - Manifest format
- **Architecture**: [docs/ASSET-MANAGEMENT-PLAN.md](docs/ASSET-MANAGEMENT-PLAN.md) - Design decisions

### Example Workflow

```bash
# 1. Add new logo to central library
cp ~/Downloads/new-logo.svg ~/media/cdn/logos/company/

# 2. Update and propagate
update-cdn
# Shows: [+] logos/company/new-logo.svg (22.1KB, 1024×1024) - NEW
# Prompts: Propagate to projects? [Y/n]
# Updates: APP-Portfolio, WEB-Landing (2 projects)

# 3. On another machine, sync project
cd ~/dev/projects/APP-Portfolio
git pull  # Get updated .r2-manifest.yml
sync-project pull
# Copies new-logo.svg from ~/media/cdn/ (or downloads from R2)

# 4. Use in code with environment awareness
# Development: /media/new-logo.svg
# Production: https://cdn.example.com/logos/company/new-logo.svg
```

## 📁 Project Structure

```text
config/     # Configuration files
scripts/    # Installation and utility scripts
docs/       # Documentation
dotfiles/   # Actual dotfiles (.zshrc, .gitconfig, etc.)
```

## 🤝 Contributing

Contributions are welcome! Please open an issue or pull request.

## 📄 License

Distributed under the MIT License. See LICENSE for more information.
