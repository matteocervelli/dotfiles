# Central Media Library Guide

## Purpose

The central media library (`~/media/cdn/`) serves as the **single source of truth** for all shared assets across your projects. It provides:

- **Centralized storage**: One location for logos, fonts, images, and other media
- **Automatic dimension tracking**: Image dimensions extracted and tracked in manifest
- **Version control**: Track changes with checksums, sizes, and modification dates
- **Project propagation**: Automatically update all projects using changed assets
- **CDN synchronization**: Bidirectional sync with Cloudflare R2

## Library Location

```
~/media/cdn/
├── .r2-manifest.yml        # Central manifest (auto-generated)
├── .dimensions-cache.json  # Performance cache (gitignored)
├── logos/                  # Brand logos
│   ├── adlimen/
│   └── matteocervelli/
├── fonts/                  # Custom fonts
├── branding/               # Brand assets (colors, patterns)
├── images/                 # General images
├── videos/                 # Video files
└── ...                     # Other categories

```

**Important**: The library should be version-controlled (git) with the manifest committed but large binaries gitignored.

## Quick Start

### Adding a New Asset

```bash
# 1. Copy file to library
cp ~/Downloads/new-logo.svg ~/media/cdn/logos/company/

# 2. Update manifest and propagate
update-cdn

# This will:
# - Regenerate manifest with dimensions
# - Show before/after comparison
# - Prompt to propagate to projects
# - Optionally sync to R2
```

### Updating an Existing Asset

```bash
# 1. Replace file in library
cp ~/Downloads/updated-logo.svg ~/media/cdn/logos/company/logo.svg

# 2. Run update workflow
update-cdn

# You'll see:
# [~] logos/company/logo.svg - UPDATED
#     Size: 15.2KB → 18.3KB (+3.1KB, +20.4%)
#     Dimensions: 512×512 → 1024×1024 (+512×512, +100%)
#     SHA256: a1b2c3... → d4e5f6...
#
# ? Propagate updates to projects? [Y/n] y
```

### Removing an Asset

```bash
# 1. Delete file from library
rm ~/media/cdn/logos/old-logo.svg

# 2. Update manifest
update-cdn

# 3. Manually remove from project manifests
# (auto-removal not yet implemented for safety)
```

## Workflows

### 1. Full Update Workflow (Interactive)

The `update-cdn` command orchestrates the complete workflow:

```bash
update-cdn
```

**Steps**:
1. **Backup**: Creates `.r2-manifest.yml.backup` with timestamp
2. **Regenerate**: Scans library, extracts dimensions, generates new manifest
3. **Notify**: Shows colored diff of changes (new/updated/removed files)
4. **Propagate** (optional): Updates all projects using changed files
5. **Sync to R2** (optional): Uploads changes to Cloudflare R2

**Example output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 CDN Update & Notification Workflow
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] Step 1: Backing up current manifest...
[✓] Backup created: ~/media/cdn/.r2-manifest.yml.backup

[INFO] Step 2: Regenerating central manifest...
[+] logos/new-company/logo.svg (22.1KB, 1200×900) - NEW
[~] branding/colors.json
    Size: 2.3KB → 2.5KB (+0.2KB, +8.7%)

📊 Summary: 1 new, 1 updated, 148 unchanged (total: 150 files)

? Propagate updates to projects? [Y/n] y

[↻ Update] APP-Portfolio
  ✓ logos/new-company/logo.svg → public/images/logo.svg (22.1KB)

📊 Propagation Summary:
  Projects scanned: 5
  Projects updated: 1
  Files copied: 1

? Sync changes to R2? [Y/n] y
[✓] R2 sync completed
```

### 2. Non-Interactive Modes

**Fully automated** (no prompts):
```bash
update-cdn --auto-propagate --auto-sync
```

**Skip propagation**:
```bash
update-cdn --no-propagate
```

**Skip R2 sync**:
```bash
update-cdn --no-sync
```

**With git commits in projects** (off by default):
```bash
update-cdn --git-commit
```

### 3. Manual Propagation

Propagate specific files without full update:

```bash
propagate-cdn-updates logo.svg colors.json

# Or full paths:
propagate-cdn-updates ~/media/cdn/logos/company/logo.svg
```

**Options**:
```bash
# With git commits in affected projects
propagate-cdn-updates --git-commit logo.svg

# Dry run (show what would be updated)
propagate-cdn-updates --dry-run logo.svg
```

### 4. R2 Synchronization

**Upload library to R2**:
```bash
cdnsync
# Or: rclone-cdn-sync
```

**Download from R2 to library**:
```bash
rclone sync r2:media-cdn ~/media/cdn --progress
```

**Check sync status**:
```bash
rclone check ~/media/cdn r2:media-cdn
```

## Directory Structure Best Practices

### Organize by Category

```
~/media/cdn/
├── logos/           # Company and brand logos
├── fonts/           # Custom typefaces
├── branding/        # Brand guidelines, color palettes
├── images/          # General images
│   ├── backgrounds/
│   ├── icons/
│   └── patterns/
├── videos/          # Video content
└── audio/           # Audio files
```

### Naming Conventions

**Folders**: lowercase-with-hyphens
```
logos/ad-limen/
logos/matteo-cervelli/
branding/color-palettes/
```

**Files**: descriptive-lowercase-with-hyphens.ext
```
logo-adlimen-stacked-original-bn-transparent-edge.svg
color-palette-primary-2025.json
font-inter-variable.woff2
```

**Version in filename** (optional):
```
logo-v2.svg          # Explicit version
logo-2025-01-24.svg  # Date-based version
```

### Size Guidelines

| Asset Type | Recommended Max Size | Reason |
|------------|---------------------|---------|
| Logos (SVG) | 50 KB | Keep vectors optimized |
| Icons | 10 KB each | Fast loading |
| Images (optimized) | 500 KB | Balance quality/performance |
| Fonts | 200 KB each | Web font performance |
| Videos | 50 MB | Local copies manageable |

**For larger assets**: Store in R2 only, use `sync: cdn-only` in manifests.

## Understanding Update Notifications

### Color-Coded Output

```
[+] logos/new-logo.svg (15.2KB, 512×512) - NEW
    ↑ Green: New file added

[~] logos/updated-logo.png - UPDATED
    ↑ Yellow: Existing file changed
    Size: 18.8KB → 22.1KB (+3.3KB, +17.6%)
    Dimensions: 800×600 → 1200×900 (+400×300, +50%)
    SHA256: 226465... → 8f3a21...

[=] branding/colors.json (2.3KB) - UNCHANGED
    ↑ Gray: No changes

[-] logos/old-logo.svg - REMOVED
    ↑ Red: File deleted
```

### What Changed

**Size changes**:
- Absolute: `18.8KB → 22.1KB (+3.3KB)`
- Percentage: `+17.6%`

**Dimension changes** (images only):
- Absolute: `800×600 → 1200×900 (+400×300)`
- Percentage: `+50%` (based on total pixels)

**Checksum changes**:
- SHA256 hash verifies file content changed
- Even identical sizes get new checksum if content differs

### Interpreting Changes

**Size increased significantly (+>20%)**:
- ⚠️ Check if optimization needed
- Consider if affects page load times
- Review if CDN bandwidth costs matter

**Dimensions changed**:
- ✅ Update responsive image configs
- ✅ Regenerate srcset if used
- ✅ Check if UI layouts need adjusting

**Checksum changed but size same**:
- ✅ Content modified (color correction, metadata)
- ✅ Quality changes (recompression)
- ✅ Format conversion (PNG→WebP same visual size)

## Project Propagation

### How It Works

When you run `update-cdn`, the propagation system:

1. **Scans all projects** in `~/dev/projects/*/`
2. **Checks each `.r2-manifest.yml`** for usage of changed files
3. **Matches by**:
   - Exact source path: `source: ~/media/cdn/logos/logo.svg`
   - Filename: Projects using `logo.svg` from library
4. **For each affected project**:
   - Updates manifest (checksum, size, dimensions)
   - Re-copies file from library to project
   - Verifies checksum after copy
   - Optionally creates git commit (with `--git-commit`)

### Detection Methods

**Method 1: Source field match** (most reliable):
```yaml
# In project .r2-manifest.yml
assets:
  - path: public/media/logo.svg
    source: ~/media/cdn/logos/company/logo.svg  # ← Exact match
    sync: copy-from-library
```

**Method 2: Filename match** (fallback):
```yaml
# In project .r2-manifest.yml
assets:
  - path: public/images/logo.svg  # ← Same filename as library file
    sync: copy-from-library
```

### Skipped Projects

Projects are skipped if:
- No `.r2-manifest.yml` file
- None of the changed files are used
- File exists locally but `sync: false` (manual only)

**Example output**:
```
[⊘ Skip] WEB-Landing (no manifest)
[⊘ Skip] APP-Notes (not affected by changes)
[⊘ Skip] DOC-Portfolio (sync: false for changed files)
```

### Statistics

After propagation, you'll see:
```
📊 Propagation Summary:
  Projects scanned: 10
  Projects updated: 3
  Files copied: 5
  Projects skipped: 7

Affected projects:
  ✓ APP-Portfolio
  ✓ WEB-Company
  ✓ API-Backend
```

**Performance**: Typically <5 minutes for 10+ projects.

## Best Practices

### 1. Regular Updates

```bash
# Weekly workflow:
# 1. Review assets
ls -lh ~/media/cdn/logos/
ls -lh ~/media/cdn/branding/

# 2. Run update
update-cdn

# 3. Review changes
git diff ~/media/cdn/.r2-manifest.yml

# 4. Commit library changes
cd ~/media/cdn
git add .
git commit -m "feat: update logos and branding assets

- Updated company logo (1200×900, +50% larger)
- Added new color palette JSON
- Optimized hero background (-15% size)
"
git push
```

### 2. Optimize Before Adding

**Images**:
```bash
# Optimize PNGs
pngquant logo.png --output logo-optimized.png

# Optimize JPEGs
jpegoptim --max=85 photo.jpg

# Optimize SVGs
svgo logo.svg --output logo-optimized.svg
```

**Batch optimization**:
```bash
# All PNGs in directory
find ~/media/cdn/images -name "*.png" -exec pngquant --quality=80-95 {} \;

# All JPEGs
find ~/media/cdn/images -name "*.jpg" -exec jpegoptim --max=85 {} \;
```

### 3. Use Descriptive Names

❌ **Bad**:
```
logo.svg
logo2.svg
logo-new.svg
img1.png
```

✅ **Good**:
```
logo-adlimen-stacked-original-bn-transparent-edge.svg
logo-adlimen-horizontal-white-on-dark.svg
background-hero-landing-page-gradient.png
icon-checkmark-success-green-24px.svg
```

### 4. Version Control

**Option 1: Filename versioning**:
```
logo-v1.svg
logo-v2.svg
logo-v3.svg
```

**Option 2: Date versioning**:
```
logo-2025-01-24.svg  # Clear timeline
logo-2025-02-15.svg
```

**Option 3: Git commits** (recommended):
- Keep filename stable: `logo.svg`
- Git history tracks changes
- Manifest tracks checksums per version

### 5. Document Changes

Add descriptions to manifest (manual edit):
```yaml
assets:
  - path: logos/company/logo-v2.svg
    size: 22134
    sha256: a1b2c3...
    dimensions: {width: 1024, height: 1024}
    description: "Version 2 - Updated colors to match 2025 brand guidelines"
```

### 6. Backup Before Major Changes

```bash
# Create timestamped backup
cp -r ~/media/cdn ~/media/cdn.backup-$(date +%Y%m%d-%H%M%S)

# Or use Time Machine tag
tmutil localsnapshot
```

### 7. Test Before Propagating

```bash
# 1. Update library
cp new-logo.svg ~/media/cdn/logos/company/

# 2. Run update WITHOUT propagation
update-cdn --no-propagate

# 3. Review changes
cat ~/media/cdn/.r2-manifest.yml | grep -A 10 "new-logo.svg"

# 4. Test in ONE project first
cd ~/dev/projects/TEST-Project
sync-project pull

# 5. If good, propagate to all
update-cdn --auto-propagate --no-sync
```

## Troubleshooting

### Manifest Not Updating

**Problem**: Running `update-cdn` doesn't detect changes.

**Solutions**:
```bash
# 1. Check ImageMagick installed
identify --version
# If not: brew install imagemagick

# 2. Clear dimension cache
rm ~/media/cdn/.dimensions-cache.json

# 3. Regenerate from scratch
cd ~/media/cdn
rm .r2-manifest.yml
~/dotfiles/scripts/sync/generate-cdn-manifest.sh ~/media/cdn

# 4. Check file permissions
ls -la ~/media/cdn
# Should be readable
```

### Propagation Not Finding Projects

**Problem**: `update-cdn` says "0 projects updated" but you know projects use the asset.

**Solutions**:
```bash
# 1. Verify project has manifest
ls ~/dev/projects/*/. r2-manifest.yml

# 2. Check source field in project manifest
cat ~/dev/projects/APP-MyApp/.r2-manifest.yml | grep -B 2 -A 5 "logo.svg"

# Should have:
# source: ~/media/cdn/logos/company/logo.svg
# OR
# sync: copy-from-library

# 3. Regenerate project manifest
cd ~/dev/projects/APP-MyApp
~/dotfiles/scripts/sync/generate-project-manifest.sh app-myapp
```

### R2 Sync Failing

**Problem**: `cdnsync` command fails or times out.

**Solutions**:
```bash
# 1. Test rclone connection
test-rclone

# 2. Check credentials
rclone config show r2

# 3. Verify bucket access
rclone lsd r2:media-cdn

# 4. Manual sync with verbose output
rclone sync ~/media/cdn r2:media-cdn --progress --verbose
```

### Checksum Mismatches

**Problem**: Same file, different checksums between library and projects.

**Cause**: File was modified in project but not library (or vice versa).

**Solutions**:
```bash
# 1. Compare checksums
shasum -a 256 ~/media/cdn/logos/logo.svg
shasum -a 256 ~/dev/projects/APP-MyApp/public/media/logo.svg

# 2. Identify which is correct
ls -lh ~/media/cdn/logos/logo.svg
ls -lh ~/dev/projects/APP-MyApp/public/media/logo.svg

# 3. Copy from library to project
propagate-cdn-updates logo.svg

# OR copy from project to library
cp ~/dev/projects/APP-MyApp/public/media/logo.svg ~/media/cdn/logos/
update-cdn
```

## Advanced Usage

### Batch Operations

**Add multiple files**:
```bash
# Copy entire directory
cp -r ~/Downloads/new-branding/* ~/media/cdn/branding/

# Update manifest
update-cdn
```

**Rename with propagation**:
```bash
# 1. Rename in library
cd ~/media/cdn/logos
mv old-name.svg new-name.svg

# 2. Update manifest (will show as removed + added)
update-cdn

# 3. Manually update project manifests
# (auto-rename not yet implemented)
```

### Selective Propagation

**Update specific projects only**:
```bash
# 1. Update library
update-cdn --no-propagate

# 2. Manually sync chosen projects
cd ~/dev/projects/APP-Important
sync-project pull

cd ~/dev/projects/WEB-Landing
sync-project pull
```

### Integration with CI/CD

**Pre-deployment check**:
```bash
# In CI pipeline
cd ~/media/cdn
~/dotfiles/scripts/sync/generate-cdn-manifest.sh ~/media/cdn

# Check for uncommitted changes
if git diff --exit-code .r2-manifest.yml; then
    echo "✓ Library manifest up to date"
else
    echo "✗ Library manifest out of sync"
    exit 1
fi
```

## Related Documentation

- [R2 Asset Manifests](../manifests/README.md) - Manifest system and project sync
- [Rclone Setup](../rclone/README.md) - R2 configuration and sync
- [Project Templates](../../templates/README.md) - Asset helpers for TypeScript/Python
- [Implementation Plan](../../docs/ASSET-MANAGEMENT-PLAN.md) - Architecture decisions

## Command Reference

| Command | Purpose | Options |
|---------|---------|---------|
| `update-cdn` | Full update workflow | `--auto-propagate`, `--auto-sync`, `--no-propagate`, `--no-sync`, `--git-commit` |
| `propagate-cdn-updates [files...]` | Propagate specific files | `--git-commit`, `--dry-run` |
| `cdnsync` | Sync library to R2 | (alias for `rclone-cdn-sync`) |
| `sync-project pull` | Sync project assets | `--verbose` |

---

**Last Updated**: 2025-01-24
**Related Issues**: [#29](https://github.com/matteocervelli/dotfiles/issues/29), [#30](https://github.com/matteocervelli/dotfiles/issues/30), [#31](https://github.com/matteocervelli/dotfiles/issues/31), [#34](https://github.com/matteocervelli/dotfiles/issues/34)
