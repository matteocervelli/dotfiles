# R2 Asset Manifests

## Purpose

Track binary assets stored in Cloudflare R2 and manage their synchronization across multiple devices. The manifest system provides:

- **Version-controlled asset tracking**: Manifests live in git, binary files don't
- **Selective synchronization**: Choose which assets to sync and to which devices
- **Integrity verification**: SHA256 checksums ensure downloaded files are correct
- **Multi-device support**: Different devices can have different asset requirements
- **Automated workflow**: Integration with dev-setup.sh for seamless project initialization

## Manifest Location

Each project should have a `.r2-manifest.yml` file in its root directory:

```
~/dev/projects/my-project/
├── .r2-manifest.yml        ← Manifest (committed to git)
├── data/                   ← Binary assets (gitignored)
│   ├── models/
│   ├── datasets/
│   └── media/
├── src/
└── README.md
```

**Important**: The manifest file is committed to version control, but the actual binary assets in `data/` are gitignored.

## Schema Overview

See [schema.yml](schema.yml) for the complete schema definition with examples.

**Basic structure**:
```yaml
project: my-project        # Project name
version: "1.0"             # Manifest version
updated: 2025-01-17T10:30:00Z  # Last update timestamp

assets:
  - path: data/models/model.bin   # Local path
    r2_key: my-project/models/model.bin  # R2 path
    size: 2847213568                     # File size (bytes)
    sha256: a1b2c3d4...                  # SHA256 checksum
    type: model                          # Asset type
    sync: true                           # Auto-sync enabled
    devices: [macbook, mac-studio]       # Target devices
    description: "AI model description"  # Optional description
```

## Enhanced Features (v1.1)

### Automatic Dimension Extraction

The enhanced manifest system automatically extracts image dimensions using ImageMagick:

- **Supported formats**: PNG, JPG, GIF, WebP, SVG, TIFF, and 200+ more
- **Performance**: Dimension caching provides 10x speedup for unchanged files
- **Graceful handling**: Non-images are processed without dimensions field

**Requirements**:
```bash
brew install imagemagick  # macOS
# or
apt-get install imagemagick  # Linux
```

**Example output**:
```yaml
assets:
  - path: logos/logo.svg
    size: 15234
    sha256: a1b2c3d4...
    dimensions: {width: 512, height: 512}  # ← Automatically extracted
    type: media
```

### Update Notifications

Compare old and new manifests to see changes before committing:

```bash
~/dotfiles/scripts/sync/notify-cdn-updates.sh ~/media/cdn
```

**Features**:
- Colored terminal output (green=new, yellow=updated, red=removed)
- Size and dimension deltas with percentages
- Markdown report generation for commit messages
- Summary statistics

**Example output**:
```
[+] logos/adlimen/logo.svg (15.2KB, 512×512) - NEW
[~] logos/matteocervelli/logo.png - UPDATED
    Size: 18.8KB → 22.1KB (+3.3KB, +17.6%)
    Dimensions: 800×600 → 1200×900 (+400×300, +50%)
[=] branding/colors.json (2.3KB) - UNCHANGED

📊 Summary: 1 new, 1 updated, 148 unchanged (total: 150 files, +18.5KB)
```

### Environment-Aware Assets

Control when to use local vs CDN URLs with the `env_mode` field:

- `cdn-production-local-dev`: Local in development, CDN in production (default)
- `cdn-always`: Always use CDN URL
- `local-always`: Always use local file path

**Example**:
```yaml
assets:
  - path: public/media/logo.svg
    cdn_url: https://cdn.adlimen.com/logos/logo.svg
    env_mode: cdn-production-local-dev
    # Development: Uses /media/logo.svg (local file)
    # Production: Uses https://cdn.adlimen.com/logos/logo.svg (CDN)
```

### Smart Sync Strategies

The enhanced `sync` field supports multiple strategies:

- `copy-from-library`: Copy from `~/media/cdn/` (fastest, recommended)
- `download`: Download directly from R2
- `cdn-only`: Asset only on CDN, don't sync locally
- `true/false`: Legacy boolean support

**Example**:
```yaml
assets:
  # Fast local copy from central library
  - path: public/media/logo.svg
    source: ~/media/cdn/logos/logo.svg
    sync: copy-from-library

  # Download from R2
  - path: data/models/model.bin
    r2_key: project/models/model.bin
    sync: download

  # CDN-only, no local copy
  - path: public/images/hero.jpg
    cdn_url: https://cdn.adlimen.com/images/hero.jpg
    sync: cdn-only
```

## Workflow

### 1. Generate Central Library Manifest

For the central CDN library at `~/media/cdn/`:

```bash
~/dotfiles/scripts/sync/generate-cdn-manifest.sh ~/media/cdn
```

**Features**:
- Automatic dimension extraction for all images
- Content-based file type detection
- Dimension caching for performance
- Colored output showing new/updated/unchanged files

### 2. Generate Project Manifest (New - Issue #30)

When you add new binary assets to a project, generate a project-specific manifest:

```bash
~/dotfiles/scripts/sync/generate-project-manifest.sh PROJECT_NAME [PROJECT_DIR]
```

**What it does**:
- Scans project directories: `public/media/`, `data/`, `public/images/`, `assets/`
- Checks if files exist in central library (`~/media/cdn/`) by filename
- For library files: Sets `sync: copy-from-library` + `source` path
- For project files: Sets `sync: download` + R2 key
- Calculates SHA256 checksums
- Smart defaults based on file size (>100MB = manual download)
- Generates `.r2-manifest.yml` in project root

**Example**:
```bash
cd ~/dev/projects/APP-Portfolio
# Add some assets
cp ~/media/cdn/logos/logo.svg public/media/
echo "config data" > data/config.json

# Generate manifest
~/dotfiles/scripts/sync/generate-project-manifest.sh app-portfolio

# Review generated manifest
cat .r2-manifest.yml
```

**Output**:
```
[INFO] Generating project manifest for: app-portfolio
[INFO] Loading central library manifest from: /Users/you/media/cdn
[✓] Library loaded: 150 files indexed

[INFO] Scanning project directories...
[📚 Library] public/media/logo.svg (15.2KB) → from library
[📦 Project] data/config.json (12B) → R2 download

📊 Summary:
  📚 From library: 1 files (copy-from-library)
  📦 Project-specific: 1 files (R2 download)
  Total: 2 files

[✓] Manifest generated: .r2-manifest.yml
[INFO] Library efficiency: 50% of files can be copied locally (fast!)
```

### 3. Sync Project Assets (New - Issue #30)

After cloning a project or updating assets, sync them to your local machine:

```bash
cd ~/dev/projects/APP-Portfolio
sync-project pull
# OR
~/dotfiles/scripts/sync/sync-project-assets.sh pull
```

**What it does**:
- Reads `.r2-manifest.yml` in project
- For each asset:
  - **copy-from-library**: Tries to copy from `~/media/cdn/` (fast, <0.1s)
  - If library unavailable: Falls back to R2 download (slower, 1-5s)
  - **download**: Downloads directly from R2
  - **cdn-only**: Verifies CDN URL is accessible, skips local sync
  - **false**: Shows manual download instructions
- Filters by device (skips assets not for this device)
- Verifies SHA256 checksums on all operations
- Reports statistics (copied vs downloaded)

**Example output**:
```
[INFO] Syncing assets for project: APP-Portfolio
[INFO] Device: macbook

[📚 Copy] public/media/logo.svg (15.2KB) ← logos
[⬇️  Download] data/config.json (12B) ← R2
[✓ Synced] public/images/hero.jpg (2.1MB)
[⊘ Skip] data/models/large.bin (not for device: macbook)

📊 Sync Summary:
  📚 Copied from library: 1 files (fast)
  ⬇️  Downloaded from R2: 1 files
  ✓ Already synced: 1 files
  ⊘ Skipped (device): 1 files
  Total synced: 2 files

[INFO] Library efficiency: 50% of synced files copied locally (fast!)
[✓] All assets synced successfully!
```

**Push mode** (upload project-specific files to R2):
```bash
cd ~/dev/projects/APP-Portfolio
sync-project push
```

**What it does**:
- Uploads project-specific files (not library files) to R2
- Skips files with `copy-from-library` sync mode
- Updates manifest with new checksums (future enhancement)

### 4. Auto-Update Propagation (New - Issue #31)

When you update an asset in the central library (`~/media/cdn/`), automatically propagate changes to all projects using that asset:

```bash
update-cdn
# OR
~/dotfiles/scripts/sync/update-cdn-and-notify.sh ~/media/cdn
```

**Interactive workflow**:
1. Backs up current central manifest
2. Regenerates manifest with dimension extraction
3. Shows notification with before/after comparison:
   - Size changes: 18.8KB → 22.1KB (+3.3KB, +17.6%)
   - Dimensions: 800×600 → 1200×900 (+400×300, +50%)
   - SHA256 changes
4. Prompts: "Propagate updates to projects? [Y/n]"
5. If yes: Scans all projects, updates affected ones
6. Prompts: "Sync to R2? [Y/n]"
7. If yes: Runs `rclone-cdn-sync` to upload changes

**Example output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 CDN Update & Notification Workflow
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] Step 1: Backing up current manifest...
[✓] Backup created: ~/media/cdn/.r2-manifest.yml.backup

[INFO] Step 2: Regenerating central manifest...
[+] logos/adlimen/logo.svg (22.1KB, 1200×900) - NEW
[~] branding/colors.json
    Size: 2.3KB → 2.5KB (+0.2KB, +8.7%)

📊 Summary: 1 new, 1 updated, 148 unchanged (total: 150 files, +0.2KB)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Change Notification
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] Changed files detected: 2

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Propagate Updates to Projects
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

? Propagate updates to projects using these files? [Y/n] y

[INFO] Running propagation...
[↻ Update] APP-Portfolio
  ✓ logos/adlimen/logo.svg → public/images/logo.svg (22.1KB)
  ✓ branding/colors.json → src/theme/colors.json (2.5KB)

[⊘ Skip] WEB-Landing (not affected)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Propagation Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Projects scanned: 2
  Projects updated: 1
  Files copied: 2
  Projects skipped: 1

Affected projects:
  ✓ APP-Portfolio

[✓] Propagation completed successfully

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
☁️  Sync to R2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

? Sync changes to R2? [Y/n] y

[INFO] Running R2 sync...
[✓] R2 sync completed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Workflow Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[✓] CDN manifest updated
[INFO] Changed files: 2
```

**Non-interactive modes**:
```bash
# Fully automated
update-cdn --auto-propagate --auto-sync

# Skip propagation
update-cdn --no-propagate

# Skip R2 sync
update-cdn --no-sync

# With git commits in projects
propagate-cdn-updates --git-commit logo.svg
```

**What it does**:
- **Project detection**: Scans `~/dev/projects/*/` for projects using changed files
- **Detection methods**:
  - Exact source match: `source: ~/media/cdn/logos/logo.svg`
  - Filename match: Projects using same filename from library
- **Updates per project**:
  - Updates manifest (checksum, size, dimensions)
  - Re-copies file from library to project
  - Verifies checksum after copy
  - Optional: Creates git commit with auto-generated message
- **Smart skipping**: Projects not using changed files are skipped
- **Statistics**: Shows copied files, updated projects, skipped projects

**Manual propagation** (for specific files):
```bash
~/dotfiles/scripts/sync/propagate-cdn-updates.sh logo.svg colors.json
```

**Performance**: Completes in <5 minutes for 10+ projects (vs ~30 min manual)

**Safety**:
- User confirmation required before propagation
- Checksum verification on all copy operations
- No destructive operations without explicit consent
- Git commits optional (off by default)

### 6. Update Manifest (Legacy)

After modifying assets (adding, removing, updating files):

```bash
~/dotfiles/scripts/sync/update-manifest.sh PROJECT_NAME
```

**What it does**:
- Updates the `updated:` timestamp
- Recalculates checksums for modified files
- Creates backup of previous manifest

**Example**:
```bash
# After modifying data files
~/dotfiles/scripts/sync/update-manifest.sh my-ai-app

# Commit updated manifest
git add .r2-manifest.yml
git commit -m "chore: update asset manifest"
```

## Integration with dev-setup.sh

The manifest system integrates seamlessly with project setup scripts:

**In your project's `scripts/dev-setup.sh`**:
```bash
#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 1. Git pull
git pull origin main

# 2. Inject secrets from 1Password
if [ -f ".env.template" ]; then
    op inject -i .env.template -o .env
fi

# 3. Sync R2 assets (if manifest exists)
if [ -f ".r2-manifest.yml" ]; then
    ~/dotfiles/scripts/sync/sync-r2.sh pull "$(basename "$PROJECT_ROOT")"
fi

# 4. Project-specific setup
npm install
# or: pip install -r requirements.txt
# or: other setup commands
```

This way, running `./scripts/dev-setup.sh` automatically pulls the latest assets from R2!

## Best Practices

### 1. Commit Manifest to Git

The `.r2-manifest.yml` file should be committed to your project's git repository:

```bash
git add .r2-manifest.yml
git commit -m "chore: add/update asset manifest"
git push
```

**Why**: This tracks what assets your project needs over time. Team members and other machines know exactly which assets to download.

### 2. Gitignore Actual Assets

Add binary assets to `.gitignore`:

```gitignore
# In project/.gitignore

# R2 assets (tracked in manifest, not in git)
data/
*.bin
*.model
*.weights
*.tar.gz
*.gguf
*.safetensors

# Large datasets
datasets/
*.parquet
*.csv.gz
```

**Why**: Binary files bloat git repositories. With R2 + manifests, you get the benefits of version control without the storage cost.

### 3. Selective Sync

Use `sync: false` for assets that should not be automatically synchronized:

```yaml
assets:
  - path: data/datasets/huge-dataset.tar.gz
    r2_key: my-project/datasets/huge-dataset.tar.gz
    size: 53687091200  # 50 GB
    sha256: e5f6789...
    type: dataset
    sync: false  # Manual download only
    description: "Full training dataset - only download if needed"
```

**Manual download when needed**:
```bash
rclone copy r2:dotfiles-assets/my-project/datasets/huge-dataset.tar.gz data/datasets/ --progress
```

**Why**: Not all machines need all assets. Developers can download large datasets only when actively training models.

### 4. Device Targeting

Specify which devices need which assets:

```yaml
assets:
  # Lightweight model for laptop
  - path: data/models/small-model.bin
    devices: [macbook]
    sync: true
    description: "Small model for development on MacBook"

  # Full model for powerful machines
  - path: data/models/large-model.bin
    devices: [mac-studio, ubuntu-vm-1]
    sync: true
    description: "Large model for training on Mac Studio and Ubuntu VM"
```

**How it works**: The sync script checks the hostname against the `devices:` list. If your machine isn't listed, the asset is skipped.

**Why**: MacBooks have limited disk space. Workstations and servers can handle larger assets.

### 5. Verify Checksums

After syncing, verify integrity:

```bash
~/dotfiles/scripts/sync/verify-manifest.sh PROJECT_NAME
```

This compares SHA256 checksums in the manifest against actual downloaded files.

**Why**: Ensures files weren't corrupted during download. Critical for model files and datasets where corruption leads to incorrect results.

### 6. Document Your Assets

Use the `description:` field generously:

```yaml
assets:
  - path: data/models/whisper-large-v3.bin
    description: "OpenAI Whisper Large V3 - English transcription, 99M params, trained on 680k hours"
    # ... other fields
```

**Why**: Helps team members understand what each asset is for, especially important for AI/ML projects with multiple model versions.

### 7. Regular Manifest Updates

Update the manifest whenever you modify assets:

```bash
# After adding/removing/modifying files in data/
~/dotfiles/scripts/sync/generate-manifest.sh my-project

# Review changes
git diff .r2-manifest.yml

# Commit
git add .r2-manifest.yml
git commit -m "chore: update asset manifest - added new model v2.0"
```

**Why**: Keeps the manifest in sync with actual R2 state. Other team members and machines know about new assets immediately after pulling the repo.

## Troubleshooting

### Checksum Mismatch

**Problem**: Downloaded file checksum doesn't match manifest.

**Symptoms**:
```
[ERROR] Checksum mismatch for data/models/model.bin
Expected: a1b2c3d4...
Got:      b2c3d4e5...
```

**Solutions**:

1. **Re-download with checksum verification**:
   ```bash
   rclone copy --checksum r2:dotfiles-assets/PROJECT/file data/ --progress
   ```

2. **Regenerate manifest** (if you modified the file locally):
   ```bash
   ~/dotfiles/scripts/sync/generate-manifest.sh PROJECT
   git diff .r2-manifest.yml  # Review changes
   ```

3. **Check R2 file integrity**:
   ```bash
   rclone md5sum r2:dotfiles-assets/PROJECT/file
   ```

### Missing Assets in R2

**Problem**: Manifest references files that don't exist in R2.

**Symptoms**:
```
[ERROR] File not found in R2: dotfiles-assets/my-project/models/missing.bin
```

**Solutions**:

1. **List R2 contents**:
   ```bash
   rclone ls r2:dotfiles-assets/PROJECT/
   ```

2. **Upload missing file**:
   ```bash
   ~/dotfiles/scripts/sync/sync-r2.sh push PROJECT --path data/models/missing.bin
   ```

3. **Remove from manifest** (if file is no longer needed):
   Edit `.r2-manifest.yml` and remove the asset entry, then commit.

### Manifest Not Found

**Problem**: Sync script can't find `.r2-manifest.yml`.

**Symptoms**:
```
[ERROR] Manifest not found: /Users/you/dev/projects/my-project/.r2-manifest.yml
```

**Solutions**:

1. **Generate manifest**:
   ```bash
   cd ~/dev/projects/my-project
   ~/dotfiles/scripts/sync/generate-manifest.sh my-project
   ```

2. **Pull from git** (if manifest exists in repo but not locally):
   ```bash
   git pull origin main
   ```

3. **Check project structure**:
   ```bash
   ls -la ~/dev/projects/my-project/
   ```

### Large File Transfers

**Problem**: Very large files (>5GB) take too long or fail.

**Solutions**:

1. **Use rclone directly with progress and resume**:
   ```bash
   rclone copy \
     --progress \
     --transfers 4 \
     --checkers 8 \
     data/huge-file.bin \
     r2:dotfiles-assets/PROJECT/
   ```

2. **Split large files** (for >10GB):
   ```bash
   # Split
   split -b 5G huge-file.bin huge-file.bin.part-

   # Upload parts
   rclone copy huge-file.bin.part-* r2:dotfiles-assets/PROJECT/

   # Download and reassemble
   rclone copy r2:dotfiles-assets/PROJECT/huge-file.bin.part-* ./
   cat huge-file.bin.part-* > huge-file.bin
   ```

3. **Set `sync: false`** in manifest and document manual download:
   ```yaml
   - path: data/huge-file.bin
     sync: false
     description: "10GB file - manual download: rclone copy r2:dotfiles-assets/PROJECT/huge-file.bin data/"
   ```

### Permission Denied

**Problem**: Can't access R2 bucket.

**Symptoms**:
```
[ERROR] Access denied: dotfiles-assets
```

**Solutions**:

1. **Verify rclone configuration**:
   ```bash
   rclone config show r2
   ```

2. **Test connection**:
   ```bash
   test-rclone
   # Or: rclone lsd r2:
   ```

3. **Reconfigure rclone**:
   ```bash
   setup-rclone
   ```

4. **Check R2 credentials in 1Password**:
   ```bash
   op item get "Cloudflare-R2" --vault Private
   ```

### Device Hostname Mismatch

**Problem**: Assets with device targeting aren't syncing.

**Cause**: Your machine's hostname doesn't match the `devices:` list in manifest.

**Solutions**:

1. **Check hostname**:
   ```bash
   hostname -s
   ```

2. **Update manifest** with correct hostname:
   ```yaml
   devices: [matteocervelli-macbook, mac-studio]  # Use actual hostname
   ```

3. **Or remove device targeting** (sync to all devices):
   ```yaml
   # Remove or comment out devices field
   # devices: [macbook]
   ```

## Advanced Usage

### Bulk Asset Operations

**Upload entire data directory**:
```bash
cd ~/dev/projects/my-project
rclone sync data/ r2:dotfiles-assets/my-project/ --progress --stats 1s
```

**Download entire project assets**:
```bash
rclone sync r2:dotfiles-assets/my-project/ data/ --progress --stats 1s
```

**Dry-run before syncing**:
```bash
rclone sync data/ r2:dotfiles-assets/my-project/ --dry-run
```

### Asset Versioning

Track different versions of models in manifest:

```yaml
assets:
  - path: data/models/model-v1.0.bin
    r2_key: my-project/models/model-v1.0.bin
    sync: false  # Keep for reference, don't auto-sync
    description: "Model v1.0 - baseline, accuracy: 85%"

  - path: data/models/model-v2.0.bin
    r2_key: my-project/models/model-v2.0.bin
    sync: true  # Current version
    description: "Model v2.0 - improved, accuracy: 92%"
```

### CDN URLs for Public Assets

For assets served publicly via Cloudflare CDN, include the `cdn_url` field:

```yaml
assets:
  - path: data/media/logo.svg
    r2_key: my-project/media/logo.svg
    cdn_url: https://cdn.example.com/media/logo.svg
    size: 15234
    sha256: a1b2c3d4...
    type: media
    sync: true
    description: "Company logo - publicly accessible via CDN"
```

**Use cases**:
- **Web assets**: Images, videos, fonts served to website visitors
- **Public downloads**: Documentation, installers, user guides
- **API responses**: Media URLs returned by your API
- **Sharing links**: Direct links to share files with clients

**Benefits**:
- **Documentation**: Team knows the public URL for each asset
- **Code generation**: Scripts can generate code with correct CDN URLs
- **Verification**: Check if file is accessible publicly
- **Migration**: Track which files need CDN setup

**Example workflow**:
```bash
# 1. Upload to R2
rclone copy data/media/logo.svg r2:dotfiles-assets/my-project/media/

# 2. Configure Cloudflare R2 public bucket or custom domain
# (via Cloudflare dashboard)

# 3. Add cdn_url to manifest
yq eval '.assets[0].cdn_url = "https://cdn.example.com/media/logo.svg"' -i .r2-manifest.yml

# 4. Test public access
curl -I https://cdn.example.com/media/logo.svg
```

### Cross-Project Assets

Share assets between projects by using consistent R2 paths:

**Project A manifest**:
```yaml
assets:
  - path: data/shared/embedding-model.bin
    r2_key: shared-assets/embeddings/sentence-transformer.bin
```

**Project B manifest**:
```yaml
assets:
  - path: data/embeddings/model.bin
    r2_key: shared-assets/embeddings/sentence-transformer.bin
```

Both projects reference the same R2 object but store it in different local paths.

### Custom Sync Scripts

Create project-specific sync scripts:

**`scripts/sync-assets.sh`**:
```bash
#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

echo "Syncing assets for $PROJECT_NAME..."

# Pull from R2
~/dotfiles/scripts/sync/sync-r2.sh pull "$PROJECT_NAME"

# Run post-sync processing
echo "Processing downloaded assets..."
python scripts/process-assets.py

echo "Asset sync complete!"
```

### Monitoring Asset Usage

Track which assets are actually used:

```bash
# List all assets in manifest
yq '.assets[].path' .r2-manifest.yml

# Check which exist locally
for asset in $(yq '.assets[].path' .r2-manifest.yml); do
    if [ -f "$asset" ]; then
        echo "✓ $asset ($(du -h "$asset" | cut -f1))"
    else
        echo "✗ $asset (missing)"
    fi
done
```

## Integration with Existing Tools

### Rclone

The manifest system is built on top of rclone. All standard rclone commands work:

```bash
# List buckets
rclone lsd r2:

# Check bandwidth
rclone check data/ r2:dotfiles-assets/PROJECT/ --one-way

# Calculate sizes
rclone size r2:dotfiles-assets/PROJECT/
```

See [sync/rclone/README.md](../rclone/README.md) for rclone setup and configuration.

### 1Password

Asset manifests don't contain secrets, but they integrate with the 1Password-secured rclone configuration:

```bash
# Rclone uses 1Password credentials automatically
setup-rclone  # Injects R2 credentials from 1Password
```

See [docs/IMPLEMENTATION-PLAN.md](../../docs/IMPLEMENTATION-PLAN.md#21-1password-cli-integration) for secret management details.

### Project Templates

New projects can include manifest setup:

**In `templates/project/dev-setup.sh.template`**:
```bash
# 3. Sync R2 assets (if manifest exists)
if [ -f ".r2-manifest.yml" ]; then
    log_step "Syncing R2 assets..."
    ~/dotfiles/scripts/sync/sync-r2.sh pull "$PROJECT_NAME"
    log_success "R2 assets synced"
fi
```

See [templates/project/README.md](../../templates/project/README.md) for project template documentation.

### Git Hooks

Prevent accidentally committing large files:

**`.git/hooks/pre-commit`**:
```bash
#!/usr/bin/env bash

# Check for large files in commit
for file in $(git diff --cached --name-only); do
    if [ -f "$file" ]; then
        size=$(du -k "$file" | cut -f1)
        if [ "$size" -gt 10240 ]; then  # 10 MB
            echo "ERROR: Large file in commit: $file (${size}KB)"
            echo "Add to .gitignore and use R2 manifest instead"
            exit 1
        fi
    fi
done
```

## Related Scripts

After `stow bin`, these scripts and commands are available:

**Central Library Management**:
- **`generate-cdn-manifest.sh`**: Generate/update central library manifest with dimensions
- **`notify-cdn-updates.sh`**: Show before/after comparison of manifest changes
- **`update-cdn`**: Convenience wrapper - update library + notify + propagate (Issue #31)
- **`update-cdn-and-notify.sh`**: Full update workflow with prompts
- **`propagate-cdn-updates.sh`**: Propagate library changes to all affected projects

**Project Asset Management**:
- **`generate-project-manifest.sh`**: Create project manifest with library detection
- **`sync-project`**: Convenience wrapper - sync project assets
- **`sync-project-assets.sh`**: Sync assets with library-first strategy

**Legacy/Manual Operations**:
- **`generate-manifest.sh`**: Create/update manifest from data/ directory
- **`sync-r2.sh`**: Pull/push assets to R2
- **`update-manifest.sh`**: Update timestamps and checksums
- **`verify-manifest.sh`**: Verify asset integrity

**R2 Configuration**:
- **`setup-rclone`**: Configure rclone for R2 (from stow-packages/bin)
- **`test-rclone`**: Test R2 connection (from stow-packages/bin)
- **`rclone-cdn-sync`**: Sync central library to R2

## Additional Resources

- **Schema Reference**: [schema.yml](schema.yml) - Complete YAML schema with examples
- **Rclone Documentation**: [sync/rclone/README.md](../rclone/README.md) - R2 setup and configuration
- **Implementation Plan**: [docs/IMPLEMENTATION-PLAN.md](../../docs/IMPLEMENTATION-PLAN.md#24-r2-manifest-system) - Architecture decisions
- **Project Templates**: [templates/project/](../../templates/project/) - Project setup script templates
- **Rclone Official Docs**: https://rclone.org/docs/
- **Cloudflare R2 Docs**: https://developers.cloudflare.com/r2/

---

**Questions or issues?** Check the [troubleshooting section](#troubleshooting) or open an issue on GitHub.
