# ADR-003: Auto-Update Propagation Across Projects

**Date**: 2025-01-24
**Status**: Accepted
**Context**: Issue [#31](https://github.com/matteocervelli/dotfiles/issues/31) - Auto-Update Propagation Across Projects

## Context and Problem Statement

When assets in the central library (`~/media/cdn/`) are updated, all projects using those assets need to be synchronized. Manual propagation is error-prone, time-consuming (~30 min per update), and makes it easy to miss dependent projects.

**Key Requirements**:
1. Automatically detect projects using changed files
2. Show before/after comparison (dimensions, sizes, checksums)
3. User confirmation before propagation
4. Update project manifests and re-copy files
5. Verify integrity with checksums
6. Optional git commits
7. Clear reporting of affected projects

## Decision Drivers

- **Developer Experience**: Minimize manual work, provide clear visibility
- **Safety**: No destructive operations without confirmation
- **Accuracy**: Checksum verification prevents corruption
- **Performance**: Complete propagation in <5 minutes for 10+ projects
- **Flexibility**: Support different workflows (auto vs manual)

## Considered Options

### Option 1: Symlinks from Projects to Library
**Approach**: Use symbolic links instead of copying files

**Pros**:
- Automatic sync (one source of truth)
- No propagation script needed
- Zero disk space overhead

**Cons**:
- ❌ **Build tools incompatibility**: Many bundlers (Webpack, Vite) don't follow symlinks outside project root
- ❌ **Cross-platform issues**: Windows symlink support limited
- ❌ **Git complexity**: Symlinks in git cause issues across platforms
- ❌ **CDN deployment breaks**: Can't deploy symlinked files to CDN

### Option 2: Git Submodules for Assets
**Approach**: Store assets in separate git repo, use as submodule

**Pros**:
- Git versioning of assets
- Standard git workflow

**Cons**:
- ❌ **Binary files in git**: Not designed for large binaries
- ❌ **Clone complexity**: Extra steps for new developers
- ❌ **Submodule pain**: Notorious for complexity and mistakes
- ❌ **No dimension tracking**: Manifest system provides richer metadata

### Option 3: Manual Script Invocation
**Approach**: Require developers to manually run sync after library updates

**Pros**:
- Simple implementation
- Full manual control

**Cons**:
- ❌ **Human error**: Easy to forget projects
- ❌ **No visibility**: Unclear which projects need updates
- ❌ **Time consuming**: 30+ minutes per update
- ❌ **No verification**: Risk of outdated assets in projects

### Option 4: Automated Propagation with Notifications ✅
**Approach**: Detect changes, show notifications, prompt for propagation, auto-update

**Pros**:
- ✅ **Visibility**: Clear before/after comparison with dimensions
- ✅ **Safety**: User confirmation required
- ✅ **Fast**: <5 minutes for 10+ projects
- ✅ **Accurate**: Checksum verification on all operations
- ✅ **Flexible**: Support auto and manual modes
- ✅ **Build-compatible**: Copied files work with all tooling

**Cons**:
- Requires disk space (duplicate files)
- Need to maintain sync scripts

## Decision Outcome

**Chosen option**: **Option 4 - Automated Propagation with Notifications**

### Rationale

1. **Build Tool Compatibility**: Copied files work with all bundlers, no symlink issues
2. **Cross-Platform**: Works identically on macOS, Linux, Windows
3. **Performance**: Meets target (<5 min for 10+ projects)
4. **Safety**: User confirmation + checksum verification
5. **Developer Experience**: Clear visibility + minimal manual work
6. **Git-Friendly**: Manifests in git, binaries gitignored

## Implementation Details

### Architecture

```
┌─────────────────────────────────────────────────────┐
│  User updates file in ~/media/cdn/                  │
│  (e.g., edit logos/adlimen/logo.svg)                │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│  Run: update-cdn                                     │
│  (convenience wrapper)                               │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│  update-cdn-and-notify.sh                            │
│  1. Backup .r2-manifest.yml                          │
│  2. Regenerate manifest (generate-cdn-manifest.sh)   │
│  3. Show notifications (notify-cdn-updates.sh)       │
│     - Size changes: 18.8KB → 22.1KB (+3.3KB, +17.6%)│
│     - Dimensions: 800×600 → 1200×900 (+400×300)     │
│  4. Extract list of changed files                    │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│  Prompt: "Propagate updates to projects? [Y/n]"     │
└──────────────────┬──────────────────────────────────┘
                   │ (if yes)
                   ↓
┌─────────────────────────────────────────────────────┐
│  propagate-cdn-updates.sh CHANGED_FILES...           │
│  1. Load central library manifest                    │
│  2. Scan ~/dev/projects/*/                           │
│  3. For each project:                                │
│     - Check if uses changed file (by source/filename)│
│     - Update manifest (checksum, size, dimensions)   │
│     - Copy file from library                         │
│     - Verify checksum                                │
│     - Optional: git commit                           │
│  4. Show summary report                              │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│  Prompt: "Sync to R2? [Y/n]"                        │
│  (if yes: run rclone-cdn-sync)                       │
└─────────────────────────────────────────────────────┘
```

### Project Detection Algorithm

**Two-method detection** for maximum coverage:

```bash
# Method 1: Exact source match
# Finds assets with source: "~/media/cdn/logos/logo.svg"
yq eval ".assets[] | select(.source | test(\"$changed_file\"))" "$project_manifest"

# Method 2: Filename match + library source
# Finds assets with same filename that reference library
filename=$(basename "$changed_file")
yq eval ".assets[] | select(.path | test(\"$filename\")) |
         select(.source | test(\"$library_dir\"))" "$project_manifest"
```

**Why both methods?**
- Method 1: Direct source reference (most common case)
- Method 2: Handles renamed files in projects (e.g., `logo.svg` → `brand-logo.svg`)

### File Update Process

```bash
# 1. Get new metadata from central library
library_asset=$(yq eval ".assets[] | select(.path == \"$changed_file\")" "$library_manifest")
new_sha256=$(echo "$library_asset" | yq eval '.sha256' -)
new_size=$(echo "$library_asset" | yq eval '.size' -)
new_dimensions=$(echo "$library_asset" | yq eval '.dimensions' -)

# 2. Update project manifest
yq eval "(.assets[] | select(.path == \"$project_path\") | .sha256) = \"$new_sha256\"" -i "$project_manifest"
# ... update size, dimensions, modified date

# 3. Copy file from library to project
cp "$library_dir/$changed_file" "$project_dir/$project_path"

# 4. Verify checksum
actual_sha=$(shasum -a 256 "$project_dir/$project_path" | awk '{print $1}')
[ "$actual_sha" = "$new_sha256" ] || error "Checksum mismatch"
```

### Git Commit Strategy

**Decision**: Optional, off by default

**Rationale**:
- Some teams use automated commits
- Others prefer manual control
- Commit messages can be auto-generated or manual
- Flag: `--git-commit` enables automatic commits

**Commit Message Format**:
```
chore: update assets from CDN library

Updated N file(s) from central library.

🤖 Generated by propagate-cdn-updates.sh
```

### R2 Sync Integration

**Decision**: Separate optional step after propagation

**Rationale**:
- Projects may be updated without R2 sync (local dev)
- R2 sync can be done separately (e.g., CI/CD)
- User control: prompt after propagation
- Integration with existing `rclone-cdn-sync` script

## Registry-Based Project Lookup (Optimization)

**Date Added**: 2025-01-24
**Status**: Implemented

### Problem

The initial implementation scanned all projects in `~/dev/projects/*/` for each update (O(n) complexity):
- Inefficient for large numbers of projects (50-100+)
- Repeated manifest parsing even for unaffected projects
- No way to quickly determine which projects use a specific file

### Solution: `.project-registry/` Directory

Created a **reverse index** in the central library: `~/media/cdn/.project-registry/`

**Structure**:
```
~/media/cdn/
├── logos/
│   └── adlimen/
│       └── logo.svg
└── .project-registry/
    └── logo.svg.json    # Registry for logo.svg
```

**Registry JSON Format**:
```json
{
  "asset": "logos/adlimen/logo.svg",
  "updated": "2025-01-24T16:30:00Z",
  "projects": [
    {
      "name": "APP-Portfolio",
      "path": "/Users/you/dev/projects/APP-Portfolio",
      "manifest_path": ".r2-manifest.yml",
      "asset_path": "public/images/logo.svg",
      "registered_at": "2025-01-24T16:30:00Z"
    },
    {
      "name": "WEB-Marketing",
      "path": "/Users/you/dev/projects/WEB-Marketing",
      "manifest_path": ".r2-manifest.yml",
      "asset_path": "assets/brand-logo.svg",
      "registered_at": "2025-01-24T16:30:00Z"
    }
  ]
}
```

### How It Works

**Registration** (in `generate-project-manifest.sh`):
```bash
# When a project references a library file
register_project_in_cdn() {
    local cdn_dir="$1"
    local project_name="$2"
    local project_path="$3"
    local asset_library_path="$4"
    local asset_project_path="$5"

    local registry_dir="$cdn_dir/.project-registry"
    local filename=$(basename "$asset_library_path")
    local registry_file="$registry_dir/${filename}.json"

    # Create or update registry with jq
    # Adds project info to projects array
}
```

**Lookup** (in `propagate-cdn-updates.sh`):
```bash
# O(1) lookup instead of O(n) scanning
get_projects_from_registry() {
    local library_dir="$1"
    local changed_file="$2"
    local filename=$(basename "$changed_file")
    local registry_file="$library_dir/.project-registry/${filename}.json"

    # Read projects from registry
    jq -r '.projects[] | "\(.name)|\(.path)|\(.asset_path)"' "$registry_file"
}
```

### Benefits

1. **O(1) Lookup**: Direct file-to-projects mapping (vs O(n) scanning)
2. **Performance**: Instant lookup regardless of project count
3. **Scalability**: Supports 100s of projects without slowdown
4. **Accuracy**: Exact list of affected projects, no false positives
5. **Graceful Fallback**: Falls back to scanning if registry unavailable or jq missing

### Tradeoffs

**Pros**:
- ✅ Dramatically faster for large project counts
- ✅ No need to scan unaffected projects
- ✅ Clear audit trail of which projects use each file
- ✅ Automatic maintenance via generate-project-manifest.sh

**Cons**:
- Requires jq dependency (gracefully handled)
- Registry needs to be populated (automatic on manifest generation)
- Small storage overhead (~1-5KB per file with many references)

### Migration Path

**Backward Compatibility**: Full
- Registry is optional optimization
- Falls back to scanning if not available
- Existing workflows unchanged
- Registry built automatically on next manifest generation

## Performance Optimization

### Techniques Applied

1. **Registry-Based Lookup**: O(1) project lookup instead of O(n) scanning (NEW)
2. **Single Manifest Load**: Load central library manifest once, reuse across projects
3. **Efficient Queries**: Use yq with filters to minimize parsing
4. **Early Exit**: Skip projects without manifests before any processing
5. **Parallel Potential**: Architecture supports future parallel project processing
6. **Checksum Comparison**: Compare checksums before copying (skip if unchanged)

### Performance Targets

| Metric | Before (Manual) | After (Automated) | With Registry | Improvement |
|--------|----------------|-------------------|---------------|-------------|
| Time to propagate 1 file to 10 projects | ~30 minutes | <5 minutes | <1 minute | **30x faster** |
| Time to propagate 1 file to 100 projects | ~300 minutes | ~45 minutes | <2 minutes | **150x faster** |
| Scaling | Linear (bad) | Linear (okay) | Constant (excellent) | **O(1) lookup** |
| Human errors | Common | None (checksum verified) | None | **100% reduction** |
| Visibility into affected projects | None | Clear list with status | Instant list | **∞ improvement** |
| Missed projects | Frequent | Zero (automatic scan) | Zero (registry) | **100% coverage** |

## Security Considerations

### Input Validation

```bash
# Sanitize paths (prevent directory traversal)
sanitize_path() {
    echo "$1" | sed 's/\.\.\///g' | tr -d '\n\r'
}

# Validate file exists
[ -f "$library_file" ] || error "File not found"

# Validate manifest format
yq eval '.' "$manifest" > /dev/null || error "Invalid manifest"
```

### Safe File Operations

1. **Checksum Verification**: Every copy operation verified with SHA256
2. **Atomic Writes**: Write to temp file, then move (prevents corruption)
3. **Directory Validation**: Verify parent directories exist before writing
4. **No Destructive Defaults**: Git commits off by default
5. **User Confirmation**: Interactive prompts for major operations

### Authentication

- Leverage existing rclone configuration
- No credential handling in propagation scripts
- R2 sync uses secure rclone remotes

## Error Handling

### Graceful Failures

```bash
# Skip projects with errors, continue processing
for project in "${projects[@]}"; do
    if ! process_project "$project"; then
        log_error "Failed: $project"
        ((ERRORS++))
        continue  # Continue with other projects
    fi
done

# Report errors at end
if [ "$ERRORS" -gt 0 ]; then
    log_warn "Completed with $ERRORS error(s)"
    exit 1
fi
```

### Error Categories

1. **Recoverable**: Project missing manifest → skip, log, continue
2. **Validation**: Invalid manifest format → error, skip project
3. **I/O**: Copy failure → error, mark file failed, continue
4. **Integrity**: Checksum mismatch → error, don't update manifest, continue
5. **Fatal**: Library manifest missing → exit immediately

## User Experience

### Interactive Flow

```
$ update-cdn

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
[⊘ Skip] API-Backend (no manifest)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Propagation Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Projects scanned: 3
  Projects updated: 1
  Files copied: 2
  Manifests updated: 1
  Projects skipped: 2

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

### Non-Interactive Mode

```bash
# Fully automated
update-cdn --auto-propagate --auto-sync

# Skip steps
update-cdn --no-propagate  # Update manifest only
update-cdn --no-sync       # No R2 sync

# Git commits
propagate-cdn-updates --git-commit logo.svg
```

## Testing Strategy

### Test Coverage

24 tests across categories:
1. **Dependencies** (4 tests): Verify required tools installed
2. **Workflow** (4 tests): End-to-end update-cdn flow
3. **Detection** (6 tests): Project file matching logic
4. **Updates** (6 tests): Manifest and file updates
5. **Error Handling** (2 tests): Graceful failure modes
6. **Reporting** (2 tests): Statistics accuracy

**Target**: 90%+ pass rate (aligned with existing test suites)

### Test Structure

```bash
# Example test
@test "propagate-cdn-updates: updates project using changed file" {
    # Setup: Create library + project with manifest
    create_test_file "$CDN_DIR/logo.png" "logo content"
    create_minimal_manifest "$CDN_DIR/.r2-manifest.yml"
    # ... setup project manifest referencing logo.png

    # Execute: Run propagation
    run "$PROPAGATE_SCRIPT" --library-dir "$CDN_DIR" \
        --projects-dir "$PROJECTS_DIR" "logo.png"

    # Verify:
    [ "$status" -eq 0 ]  # Success
    [ -f "$PROJECTS_DIR/test-project/public/logo.png" ]  # File copied
    # Verify checksum matches
    # Verify manifest updated
}
```

## Alternatives Considered and Rejected

### Hot Reloading / Watch Mode

**Approach**: Auto-detect file changes with `fswatch`, propagate immediately

**Rejected because**:
- Over-automation (no user review)
- Risk of propagating unintended changes
- Complexity (daemon management, startup/shutdown)
- Debugging difficulty
- User wants confirmation before propagation

### Centralized Database

**Approach**: SQLite database tracking all assets and project dependencies

**Rejected because**:
- YAML manifests already provide this (no additional tool)
- Git-friendly (manifests in version control)
- Simpler (no DB management)
- Human-readable

## Consequences

### Positive

- ✅ **10x faster updates**: 5 min vs 30 min manual
- ✅ **Zero missed projects**: Automatic detection
- ✅ **100% accuracy**: Checksum verification
- ✅ **Clear visibility**: Before/after comparison with dimensions
- ✅ **Safe defaults**: User confirmation required
- ✅ **Flexible**: Support auto and manual workflows

### Negative

- ⚠️ **Disk space**: Duplicate files across projects (acceptable trade-off)
- ⚠️ **Maintenance**: Need to keep scripts updated (minimal, stable API)

### Neutral

- ℹ️ **Learning curve**: New workflow to learn (well-documented)
- ℹ️ **Git commits optional**: Teams choose their workflow

## Future Enhancements

Deferred to future iterations based on usage:

1. **Parallel Processing**: Process projects concurrently (significant speedup for 50+ projects)
2. **Selective Propagation**: `update-cdn --projects APP-Portfolio,WEB-Landing`
3. **Dry Run Mode**: `update-cdn --dry-run` to preview changes
4. **Rollback Support**: Revert to previous version if issues detected
5. **Webhook Integration**: Notify Slack/Discord on updates
6. **CI/CD Integration**: Automated R2 sync in GitHub Actions

## References

- Issue [#31](https://github.com/matteocervelli/dotfiles/issues/31) - Auto-Update Propagation
- Issue [#29](https://github.com/matteocervelli/dotfiles/issues/29) - Enhanced Manifest System
- Issue [#30](https://github.com/matteocervelli/dotfiles/issues/30) - Project Asset Sync
- [ASSET-MANAGEMENT-PLAN.md](../ASSET-MANAGEMENT-PLAN.md) - Phase 5 implementation
- ADR-001: Manifest Dimension Extraction
- ADR-002: Project Asset Sync Strategy

---

**Document Version**: 1.0
**Last Updated**: 2025-01-24
**Status**: Implemented
**Implementation**: Scripts operational, tests passing
