# Enhanced CDN/R2 Asset Management System
## Implementation Plan

**Version**: 1.0
**Date**: 2025-01-24
**Status**: Ready for Implementation
**Estimated Time**: ~16 hours
**Author**: Claude Code + Matteo Cervelli

---

## 📋 Executive Summary

### Problem Statement

Currently, the dotfiles project has basic R2 manifest support planned in FASE 2, but lacks:
- **Central media library** as single source of truth
- **Smart sync strategies** (copy from library vs download from R2)
- **Environment-aware asset resolution** (local in dev, CDN in production)
- **Auto-update notifications** showing dimension/size changes
- **Interactive project templates** with asset management pre-configured

### Solution Overview

Implement a comprehensive asset management system with:

1. **Central Media Library** (`~/media/cdn/`) - Already exists, needs enhancement
2. **Enhanced Manifests** - Track dimensions, sync modes, environment settings
3. **Smart Sync Logic** - Copy from library first (fast), fallback to R2 (slow)
4. **Auto-Update Workflow** - Propagate changes to all projects automatically
5. **Environment Helpers** - TypeScript/Python libraries for local/CDN switching
6. **Interactive Templates** - Generate new projects with asset support in <3 min

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Copy vs Symlinks** | ✅ Copy files | Build tools compatibility, cross-platform support |
| **Sync Strategy** | ✅ Library-first with R2 fallback | Fast local copies, reliable R2 backup |
| **Update Propagation** | ✅ Auto-update with notifications | Show dimensions/size delta before propagating |
| **Manifest Granularity** | ✅ Single entry per file | Detailed tracking, explicit control |
| **Environment Switching** | ✅ `.env` files with 1Password | Secure, version-controlled templates |
| **Template Generation** | ✅ Interactive CLI | Multiple stacks, customizable features |

---

## 🏗️ Architecture

### System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Mac Studio (Primary)                      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  ~/media/cdn/ (Central Library)                        │ │
│  │  ├── .r2-manifest.yml (with dimensions)                │ │
│  │  ├── logos/                                             │ │
│  │  ├── fonts/                                             │ │
│  │  ├── images/                                            │ │
│  │  └── videos/                                            │ │
│  └────────────────────────────────────────────────────────┘ │
│                           ↕ bidirectional                    │
│                  (rclone-cdn-sync - exists)                  │
└─────────────────────────────────────────────────────────────┘
                             ↓
                    ┌────────────────────┐
                    │  Cloudflare R2     │
                    │  ┌──────────────┐  │
                    │  │ media-cdn/   │  │ ← Already configured
                    │  │ projects/    │  │
                    │  └──────────────┘  │
                    └────────────────────┘
                             ↓
                    ┌────────────────────┐
                    │  CDN Distribution  │
                    │  cdn.adlimen.it    │ ← Working
                    └────────────────────┘
                             ↓
        ┌────────────────────┴────────────────────┐
        ↓                                          ↓
┌───────────────────┐                   ┌──────────────────┐
│  MacBook (Dev)    │                   │  Ubuntu VMs      │
│  sync-project     │                   │  sync-project    │
│  (copy or R2)     │                   │  (R2 download)   │
└───────────────────┘                   └──────────────────┘
        ↓                                          ↓
┌───────────────────────────────────────────────────────────┐
│           Project Repositories (Git)                       │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  ~/dev/projects/APP-MyApp/                          │  │
│  │  ├── .r2-manifest.yml (versioned in git)            │  │
│  │  ├── lib/assets.ts (environment helper)             │  │
│  │  ├── public/media/ (local copies, gitignored)       │  │
│  │  └── data/models/ (project assets, gitignored)      │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### Data Flow

#### Upload Flow (Mac Studio → R2 → Other Devices)
1. Update asset in `~/media/cdn/`
2. Run `update-cdn` → Regenerate manifest + notifications
3. Optional: Propagate to projects using that file
4. `rclone-cdn-sync` → Upload to R2
5. Other devices: `git pull` + `sync-project` → Get updates

#### Download Flow (New Device Setup)
1. `git clone` project repository
2. `./scripts/dev-setup.sh` → Calls `sync-project pull`
3. For each asset in `.r2-manifest.yml`:
   - If `sync: copy-from-library` AND library exists → Copy (fast)
   - Else → Download from R2 (slower)
4. Verify checksums
5. Ready to develop

#### Environment Switching (Dev vs Prod)
- **Development**: `ASSET_MODE=local` → Use `/media/logo.svg` (local file)
- **Production**: `ASSET_MODE=cdn` → Use `https://cdn.adlimen.it/logos/logo.svg`
- Helper libraries (`assets.ts`, `assets.py`) handle switching automatically

---

## 📅 Implementation Phases

### Phase 1: Core Manifest System (4 hours)
**GitHub Issue**: [#29](https://github.com/matteocervelli/dotfiles/issues/29) ✅ Created

#### 1.1 Enhanced Manifest Schema (30 min)
- Add `dimensions: {width, height}` field for images
- Add `env_mode` field: `cdn-production-local-dev` | `cdn-always` | `local-always`
- Enhanced `sync` field: `copy-from-library` | `download` | `cdn-only` | `false`
- Update `sync/manifests/schema.yml` documentation

#### 1.2 Auto-Generate Central Manifest (2 hours)
**Script**: `scripts/sync/generate-cdn-manifest.sh`

**Features**:
- Recursive scan of `~/media/cdn/`
- Calculate SHA256, size, modification date
- **Extract image dimensions** using ImageMagick (`identify -format "%wx%h"`)
- Detect file type from content (not just extension)
- Generate/update `.r2-manifest.yml`
- Cache dimensions in `.dimensions-cache.json` for performance

**Output Example**:
```
[INFO] Scanning ~/media/cdn/...
[+] logos/adlimen/logo.svg (15.2KB, 512×512) - NEW
[~] logos/matteocervelli/logo.png - UPDATED
    Size: 18.8KB → 22.1KB (+3.3KB, +17.6%)
    Dimensions: 800×600 → 1200×900 (+400×300, +50%)
    SHA256: 226465...d15 → 8f3a21...c49
[=] branding/colors.json (2.3KB) - UNCHANGED

📊 Summary: 1 new, 1 updated, 148 unchanged (total: 150 files, +18.5KB)
```

#### 1.3 Update Notification System (1.5 hours)
**Script**: `scripts/sync/notify-cdn-updates.sh`

**Features**:
- Compare old vs new manifest
- Show changes in terminal with colors (green/red/yellow)
- Display dimension/size changes
- Generate Markdown report for commit messages

---

### Phase 2: Project Asset Sync (3 hours)
**GitHub Issue**: [#30](https://github.com/matteocervelli/dotfiles/issues/30) ✅ Created

#### 2.1 Generate Project Manifest (1.5 hours)
**Script**: `scripts/sync/generate-project-manifest.sh PROJECT_NAME`

**Features**:
- Scan project's `public/media/` and `data/` directories
- For each file:
  - Check if exists in `~/media/cdn/` (filename match)
  - If YES → add `source: ~/media/cdn/...` + `sync: copy-from-library`
  - If NO → add `r2_key: projects/PROJECT/...` + `sync: download`
- Calculate checksums
- Smart sync mode defaults based on size/type
- Generate `.r2-manifest.yml` in project root

#### 2.2 Sync Project Assets (1.5 hours)
**Script**: `scripts/sync/sync-project-assets.sh [pull|push]`

**Pull Logic**:
1. Read `.r2-manifest.yml`
2. For `sync: copy-from-library`:
   - Copy from `source` path in `~/media/cdn/`
   - If source missing → Fallback: download from R2 via `r2_key`
3. For `sync: download` → Download from R2
4. For `sync: cdn-only` → Skip (verify CDN URL accessible)
5. For `sync: false` → Show manual download instructions
6. Verify all checksums

**Push Logic**:
- Upload project-specific files to `R2://projects/PROJECT_NAME/`
- Update manifest with new checksums

---

### Phase 3: Environment Helpers (2 hours)
**GitHub Issue**: [#32](https://github.com/matteocervelli/dotfiles/issues/32) ✅ Created

#### 3.1 TypeScript Asset Helper (1 hour)
**File**: `templates/project/lib/assets.ts`

**Features**:
- `AssetResolver` class
- Reads `process.env.ASSET_MODE` from `.env`
- `getAssetUrl(localPath, cdnUrl, envMode?)` function
- `useAsset()` React hook for Next.js/React
- Full TypeScript types

**Usage**:
```tsx
import { useAsset } from '@/lib/assets';

function Logo() {
  const url = useAsset('/media/logo.png', 'https://cdn.adlimen.it/logos/logo.png');
  return <img src={url} />;
}
```

#### 3.2 Python Asset Helper (1 hour)
**File**: `templates/project/lib/assets.py`

**Features**:
- `AssetResolver` class
- Reads `os.getenv('ASSET_MODE')`
- `get_asset_url(local_path, cdn_url, env_mode?)` function
- Type hints with `typing` module

**Usage**:
```python
from lib.assets import get_asset_url

model_path = get_asset_url(
    'data/models/whisper.bin',
    'https://cdn.adlimen.it/models/whisper.bin'
)
```

---

### Phase 4: Interactive Project Templates (3 hours)
**GitHub Issue**: [#33](https://github.com/matteocervelli/dotfiles/issues/33) ✅ Created

#### 4.1 Template Generator Script (2 hours)
**Script**: `scripts/templates/new-project.sh`

**Interactive Prompts**:
- Project name
- Project type (Frontend, Fullstack, Backend, AI/ML, Mobile, Monorepo)
- Stack selection (Next.js, Vite, Python, Swift, etc.)
- Features (Asset management, 1Password, Tailwind, Testing)

**Output**: Complete project structure ready to develop

#### 4.2 Create Templates (1 hour)
- `templates/nextjs-app/` - Next.js 14 (App Router)
- `templates/nextjs-pages/` - Next.js 14 (Pages Router)
- `templates/vite-react/` - Vite + React + TypeScript
- `templates/python-fastapi/` - FastAPI + SQLAlchemy
- `templates/python-ml/` - Python + Jupyter + MLX
- `templates/swift-app/` - SwiftUI + SwiftPM
- `templates/monorepo/` - Turborepo structure

Each template includes:
- Asset helper pre-configured
- `.env.template` with 1Password refs
- `.r2-manifest.yml` (empty)
- `scripts/dev-setup.sh` with asset sync
- `.gitignore` (ignores assets)

---

### Phase 5: Integration & Auto-Update (2 hours)
**GitHub Issue**: [#31](https://github.com/matteocervelli/dotfiles/issues/31) ✅ Created

#### 5.1 Update & Notify Script (1 hour)
**Script**: `scripts/sync/update-cdn-and-notify.sh`

**Workflow**:
1. Regenerate central manifest
2. Show diff with `notify-cdn-updates.sh`
3. Prompt: "Propagate to projects? [Y/n]"
4. If yes → call propagate script
5. Sync to R2

#### 5.2 Propagate Updates Script (1 hour)
**Script**: `scripts/sync/propagate-cdn-updates.sh CHANGED_FILES...`

**Features**:
- Scan all projects in `~/dev/projects/*/`
- For each project with `.r2-manifest.yml`:
  - Check if uses any changed files
  - Update checksum in project manifest
  - Re-copy file from library to project
- Show summary report

---

### Phase 6: Documentation (2 hours)
**GitHub Issue**: [#34](https://github.com/matteocervelli/dotfiles/issues/34) ✅ Created

- Create `sync/library/README.md` - Central library guide
- Update `sync/manifests/README.md` - Add library workflow, env switching
- Update `sync/manifests/schema.yml` - Document new fields
- Update `README.md` - Add asset management section
- Create `templates/README.md` - Template generator usage
- Update `docs/TASK.md` - Add FASE 2.X tasks

---

## 📊 Detailed Task Breakdown

### Implementation Tracking

| Phase | Issue | Milestone | Estimate | Status |
|-------|-------|-----------|----------|--------|
| Phase 1: Core Manifest | [#29](https://github.com/matteocervelli/dotfiles/issues/29) | FASE 2 | 4h | ⚪ Ready |
| Phase 2: Project Sync | [#30](https://github.com/matteocervelli/dotfiles/issues/30) | FASE 2 | 3h | ⚪ Ready |
| Phase 3: Env Helpers | [#32](https://github.com/matteocervelli/dotfiles/issues/32) | FASE 2 | 2h | ⚪ Ready |
| Phase 4: Templates | [#33](https://github.com/matteocervelli/dotfiles/issues/33) | FASE 5 | 3h | ⚪ Ready |
| Phase 5: Auto-Update | [#31](https://github.com/matteocervelli/dotfiles/issues/31) | FASE 2 | 2h | ⚪ Ready |
| Phase 6: Documentation | [#34](https://github.com/matteocervelli/dotfiles/issues/34) | FASE 2 | 2h | ⚪ Ready |
| **TOTAL** | | | **16h** | |

---

## 📁 Files to Create (25 new files)

### Scripts (9 files)
1. `scripts/sync/generate-cdn-manifest.sh` - Generate central library manifest
2. `scripts/sync/notify-cdn-updates.sh` - Show update notifications
3. `scripts/sync/generate-project-manifest.sh` - Generate project manifest
4. `scripts/sync/sync-project-assets.sh` - Sync project assets (pull/push)
5. `scripts/sync/update-cdn-and-notify.sh` - Update + notify workflow
6. `scripts/sync/propagate-cdn-updates.sh` - Propagate to projects
7. `scripts/templates/new-project.sh` - Interactive project generator
8. `stow-packages/bin/.local/bin/update-cdn` - Convenience wrapper (symlink)
9. `stow-packages/bin/.local/bin/sync-project` - Convenience wrapper (symlink)

### Helpers (2 files)
10. `templates/project/lib/assets.ts` - TypeScript asset helper
11. `templates/project/lib/assets.py` - Python asset helper

### Templates (7 directories with complete structures)
12. `templates/nextjs-app/` - Next.js 14 App Router
13. `templates/nextjs-pages/` - Next.js 14 Pages Router
14. `templates/vite-react/` - Vite + React
15. `templates/python-fastapi/` - FastAPI backend
16. `templates/python-ml/` - Python ML/AI
17. `templates/swift-app/` - SwiftUI mobile
18. `templates/monorepo/` - Turborepo

### Documentation (4 files)
19. `sync/library/README.md` - Central library guide
20. `templates/README.md` - Template generator docs
21. `docs/ASSET-MANAGEMENT-PLAN.md` - This document
22. `docs/PROJECT-TEMPLATES.md` - Template customization guide

### Config (2 files)
23. `templates/project/.env.template` - Environment template
24. `templates/project/scripts/dev-setup.sh` - Enhanced setup script

### Misc (1 file)
25. `~/media/cdn/.dimensions-cache.json` - Dimension cache (gitignored)

---

## 📝 Files to Update (6 existing files)

1. **`sync/manifests/schema.yml`**
   - Add `dimensions` field
   - Document enhanced `sync` modes
   - Add `env_mode` field
   - Add Example 6 (environment-aware assets)

2. **`sync/manifests/README.md`**
   - Add "Central Library Workflow" section
   - Add "Environment Switching" guide
   - Add "Auto-Update" workflow
   - Update examples with new fields

3. **`README.md`**
   - Add "Asset Management System" section
   - Quick start guide
   - Link to detailed documentation

4. **`docs/TASK.md`**
   - Add FASE 2.X section
   - Link to issues #29-#34
   - Update completion criteria

5. **`docs/IMPLEMENTATION-PLAN.md`**
   - Add detailed asset management notes
   - Migration guide section

6. **`~/media/cdn/.r2-manifest.yml`**
   - Regenerate with `dimensions` field
   - Update all checksums

---

## ✅ Acceptance Criteria

### Core Functionality
- ✅ Central manifest auto-generated with dimensions (W×H for images)
- ✅ Update notifications show size/dimension deltas
- ✅ Project manifest generation detects library files automatically
- ✅ Asset sync tries library first, falls back to R2
- ✅ Environment helpers work (local in dev, CDN in prod)

### Interactive Templates
- ✅ `new-project` command works interactively
- ✅ Supports 7 different project types/stacks
- ✅ Generated projects include asset helpers
- ✅ Projects ready to develop in <3 minutes

### Automation
- ✅ Auto-update propagates to all projects using changed files
- ✅ Notifications show before/after comparison
- ✅ Checksums verified on all operations

### Documentation
- ✅ Complete library guide with workflows
- ✅ Template documentation with examples
- ✅ Updated manifest schema docs
- ✅ Migration guide for existing projects

---

## 🧪 Testing Plan

### Test 1: Central Manifest Generation
```bash
cd ~/media/cdn
~/dotfiles/scripts/sync/generate-cdn-manifest.sh

# Expected:
# - Scans all files
# - Extracts dimensions for images using ImageMagick
# - Updates .r2-manifest.yml with dimensions field
# - Shows summary with changes
```

### Test 2: Project Manifest Generation
```bash
cd ~/dev/projects/APP-Portfolio
~/dotfiles/scripts/sync/generate-project-manifest.sh app-portfolio

# Expected:
# - Scans public/media/ and data/
# - Detects files in ~/media/cdn/ and adds source field
# - Generates .r2-manifest.yml with smart sync modes
# - Reports library vs R2 files
```

### Test 3: Asset Sync (Library-First)
```bash
cd ~/dev/projects/TEST-Project
~/dotfiles/scripts/sync/sync-project-assets.sh pull

# Expected:
# - Tries to copy from ~/media/cdn/ first
# - Shows "Copied from library" messages
# - Falls back to R2 if library unavailable
# - Reports copy vs download statistics
```

### Test 4: Auto-Update Workflow
```bash
# 1. Update file in library
echo "test" >> ~/media/cdn/logos/test.svg

# 2. Run update command
update-cdn

# Expected:
# - Detects change
# - Shows notification with size/dimension change
# - Asks to propagate
# - Updates project manifests
# - Syncs to R2
# - Shows summary
```

### Test 5: Environment Switching
```bash
# Create test Next.js app
new-project  # → Choose Next.js

# Test dev mode
ASSET_MODE=local npm run dev
# → Should use /media/logo.svg

# Test prod build
ASSET_MODE=cdn npm run build
# → Should use https://cdn.adlimen.it/logos/logo.svg
```

### Test 6: Interactive Template Generator
```bash
new-project

# Interactive prompts:
# - Project name: test-interactive
# - Type: Web Frontend
# - Stack: Next.js 14 (App Router)
# - Features: All selected

# Expected:
# - Project created in ~/dev/projects/TEST-Interactive/
# - Asset helper included
# - Dev setup script works
# - Ready to develop
```

---

## 🔄 Migration Strategy

### For Existing `~/media/cdn/`

```bash
# 1. Backup current manifest
cp ~/media/cdn/.r2-manifest.yml ~/media/cdn/.r2-manifest.yml.backup-$(date +%Y%m%d)

# 2. Install ImageMagick (if not installed)
brew install imagemagick

# 3. Regenerate manifest with dimensions
cd ~/media/cdn
~/dotfiles/scripts/sync/generate-cdn-manifest.sh

# 4. Review changes
git diff .r2-manifest.yml

# Expected changes:
# - dimensions field added to images
# - sync field added (defaults to true)
# - env_mode field added where applicable

# 5. Commit
git add .r2-manifest.yml
git commit -m "feat: add dimensions and enhanced fields to manifest"
git push
```

### For Existing Projects

```bash
# For each project with assets:
cd ~/dev/projects/APP-MyProject

# 1. Backup existing manifest (if exists)
[ -f .r2-manifest.yml ] && cp .r2-manifest.yml .r2-manifest.yml.backup

# 2. Regenerate with new script
~/dotfiles/scripts/sync/generate-project-manifest.sh app-myproject

# Expected:
# - Detects files in ~/media/cdn/ and adds source field
# - Adds sync: copy-from-library for library files
# - Adds sync: download for project-specific files
# - Smart defaults based on file size/type

# 3. Review changes
git diff .r2-manifest.yml

# 4. Add asset helper (if applicable)
# For Next.js/React:
mkdir -p src/lib
cp ~/dotfiles/templates/project/lib/assets.ts src/lib/

# For Python:
mkdir -p lib
cp ~/dotfiles/templates/project/lib/assets.py lib/

# 5. Update .gitignore
echo "public/media/" >> .gitignore
echo "data/" >> .gitignore
echo ".env" >> .gitignore

# 6. Commit
git add .r2-manifest.yml src/lib/assets.ts .gitignore
git commit -m "chore: regenerate manifest with library support"
git push
```

---

## 🚨 Dependencies

### Required Tools

| Tool | Status | Installation | Purpose |
|------|--------|--------------|---------|
| `rclone` | ✅ Installed | N/A | R2 sync |
| `yq` | ✅ Installed | `brew install yq` | YAML parsing |
| `imagemagick` | ⚠️ **NEEDS INSTALL** | `brew install imagemagick` | Dimension extraction |
| `shasum` | ✅ Built-in | N/A | Checksums |
| `1Password CLI` | ✅ Installed | N/A | Secret injection |

### Installation Commands

```bash
# Install ImageMagick (required for dimension extraction)
brew install imagemagick

# Verify installation
identify --version
# Should show: ImageMagick 7.x.x
```

---

## 📈 Success Metrics

After implementation, you should be able to:

1. ✅ **New project setup <3 min**: `new-project` → choose stack → ready to develop
2. ✅ **Asset updates visible**: Change logo → notification shows W×H + size delta
3. ✅ **Auto-propagation**: Update logo → all projects using it get updated automatically
4. ✅ **Library-first sync**: 90% of assets copied from library (not downloaded from R2)
5. ✅ **Environment switching**: Dev uses local paths, prod uses CDN URLs (verified in build)
6. ✅ **Zero manual manifest editing**: Scripts handle all generation/updates

### Performance Metrics

**Before** (baseline):
- New project setup: ~10 min (manual file copying)
- Asset update propagation: ~30 min (manual per-project updates)
- Library sync: Manual rclone commands
- Environment switching: Manual URL editing

**After** (target):
- New project setup: <3 min (automated with `new-project`)
- Asset update propagation: <5 min (automated with `update-cdn`)
- Library sync: Automatic with notifications
- Environment switching: Automatic via helper libraries

---

## ⏱️ Implementation Timeline

### Week 1 (8 hours)
**Day 1-2**: Phase 1 - Core Manifest System (4h)
- Enhanced schema
- Auto-generate script with ImageMagick
- Notification system

**Day 3-4**: Phase 2 - Project Asset Sync (3h)
- Generate project manifest
- Sync with library-first strategy

**Day 5**: Phase 3.1 - TypeScript Helper (1h)
- Asset resolver for Next.js/React

### Week 2 (8 hours)
**Day 1**: Phase 3.2 + 5 - Python Helper + Integration (3h)
- Asset resolver for Python
- Auto-update scripts

**Day 2-3**: Phase 4 - Interactive Templates (3h)
- Template generator
- 7 project templates

**Day 4-5**: Phase 6 - Documentation (2h)
- Library guide
- Update existing docs
- Migration guide

**Total**: ~16 hours over 2 weeks

---

## 🎉 Expected Outcomes

### Developer Experience Improvements
- ⚡ **10x faster project setup** (3 min vs 30 min)
- 🔄 **Automatic asset updates** across all projects
- 📊 **Visual change tracking** (dimensions, sizes, checksums)
- 🎯 **Smart sync** (library copy vs R2 download)
- 🌐 **Seamless environment switching** (local/CDN)

### Operational Benefits
- 📦 **Single source of truth** (`~/media/cdn/` → R2)
- 🔍 **Detailed tracking** (dimensions, checksums, sizes)
- 🚀 **Fast project cloning** (assets from local library)
- 🔐 **Secure secret management** (1Password integration)
- 📚 **Comprehensive documentation** (all workflows covered)

### Technical Benefits
- ✅ **No symlinks** (build tools compatibility)
- ✅ **Cross-platform** (macOS, Linux, future Windows)
- ✅ **Git-friendly** (manifests versioned, binaries gitignored)
- ✅ **CDN-ready** (production builds use CDN URLs)
- ✅ **Modular** (each script has single responsibility)

---

## ❓ Open Questions (Future Enhancements)

These are **optional** and can be deferred to later:

1. **CDN Cache Purging**: Auto-purge Cloudflare cache on file update?
2. **Versioned URLs**: Use `logo-v2.svg` vs `logo.svg?v=2` for cache busting?
3. **R2 Versioning**: Implement R2 object versioning or rely on Time Machine?
4. **Multi-CDN Support**: Add AWS CloudFront alongside Cloudflare?
5. **Image Optimization**: Auto-optimize/compress images on upload to R2?
6. **Asset Compression**: Gzip/Brotli compression for text assets?
7. **Responsive Images**: Auto-generate srcset variants?

All deferred to future iterations based on actual usage patterns.

---

## 📚 References

- **Rclone Documentation**: https://rclone.org/docs/
- **Cloudflare R2 Guide**: https://developers.cloudflare.com/r2/
- **ImageMagick**: https://imagemagick.org/script/identify.php
- **YAML Specification**: https://yaml.org/spec/1.2.2/
- **GNU Stow**: https://www.gnu.org/software/stow/manual/
- **1Password CLI**: https://developer.1password.com/docs/cli/

---

## 🚀 Next Steps

1. **Approve this plan** ✅ (Done)
2. **Create GitHub issues** #29-#34 (Next)
3. **Begin Phase 1 implementation** (Core Manifest System)
4. **Test each phase** before moving to next
5. **Update documentation** as implementation progresses

---

**Document Version**: 1.0
**Last Updated**: 2025-01-24
**Status**: Ready for Implementation
**GitHub Issues**: #29-#34 (to be created)
