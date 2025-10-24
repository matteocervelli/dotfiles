# ADR-001: Manifest Dimension Extraction

**Date**: 2025-01-24
**Status**: Accepted
**Context**: Issue [#29](https://github.com/matteocervelli/dotfiles/issues/29) - Enhanced Manifest System

## Context and Problem Statement

The R2 asset manifest system needs to track image dimensions for better asset management, but this requires:
1. Automatic extraction during manifest generation
2. Performance optimization to avoid re-processing unchanged files
3. Cross-platform compatibility (macOS, Linux)
4. Graceful handling of non-image files

## Decision Drivers

- **Performance**: Should handle 100+ files in <10 seconds
- **Reliability**: Must accurately extract dimensions from various image formats
- **Compatibility**: Must work on macOS (primary) and Linux (servers/CI)
- **Maintainability**: Simple, standard tools preferred over custom implementations

## Considered Options

### Option 1: ImageMagick (`identify` command)
**Pros**:
- Industry-standard image processing tool
- Supports 200+ image formats (PNG, JPG, GIF, WebP, SVG, TIFF, etc.)
- Reliable dimension extraction with `identify -format "%wx%h"`
- Available on all major platforms via package managers
- Battle-tested in production environments
- Single command execution (fast)

**Cons**:
- External dependency (requires `brew install imagemagick`)
- Larger install size (~40MB with dependencies)

### Option 2: Python PIL/Pillow
**Pros**:
- Pure Python solution
- Good format support

**Cons**:
- Requires Python environment setup
- Adds Python dependency to bash scripts
- Slower than native tools
- More complex error handling
- SVG support limited

### Option 3: Native `sips` (macOS only)
**Pros**:
- Pre-installed on macOS
- Fast

**Cons**:
- **macOS-only** - breaks on Linux servers
- Limited format support (no SVG)
- Not suitable for cross-platform dotfiles

### Option 4: Parse file headers manually
**Pros**:
- No external dependencies
- Fastest possible

**Cons**:
- Extremely complex to implement correctly
- Must handle 50+ format variations
- Error-prone
- High maintenance burden
- No SVG support

## Decision Outcome

**Chosen option**: **Option 1 - ImageMagick**

### Rationale

1. **Cross-Platform**: Works identically on macOS, Linux, Windows (WSL)
2. **Comprehensive Format Support**: Handles all image formats we need (PNG, JPG, GIF, WebP, SVG, TIFF)
3. **Industry Standard**: Used by millions of projects, well-tested
4. **Simple Integration**: Single shell command with consistent output
5. **Performance**: Fast native C implementation
6. **Reliability**: Handles edge cases (corrupted images, unusual formats)

### Implementation Details

```bash
# Extract dimensions
dimensions=$(identify -format "%wx%h" "$filepath" 2>/dev/null || echo "")

# Example output: "1920x1080"
```

## Performance Optimization: Dimension Cache

To avoid re-processing unchanged images on every manifest generation:

### Cache Strategy

**Cache Key**: `${filepath}:${mtime}:${size}`
- File path (relative)
- Modification time (Unix timestamp)
- File size (bytes)

**Rationale**: If all three are identical, the file content hasn't changed, so dimensions are the same.

**Implementation**:
- Store in `.dimensions-cache.json` (gitignored)
- JSON format: `{"path:mtime:size": "widthxheight"}`
- Update only on cache miss (new file or changed file)

**Performance Impact**:
- **Without cache**: ~100ms per image × 100 images = 10 seconds
- **With cache (90% hit rate)**: ~100ms × 10 new images = 1 second
- **Speedup**: 10x for typical workflows

### Cache Example

```json
{
  "logos/logo.svg:1706112000:15234": "512x512",
  "images/hero.jpg:1706115600:2097152": "1920x1080"
}
```

## File Type Detection

**Decision**: Use content-based detection, not extension-based

**Tool**: `file --mime-type` command
**Rationale**:
- More reliable than extension matching
- Detects actual file content (prevents misnamed files)
- Built-in to Unix systems
- Security: Prevents malicious file type spoofing

**Example**:
```bash
$ file --mime-type image.jpg
image.jpg: image/jpeg

$ file --mime-type renamed.txt  # Actually a PNG
renamed.txt: image/png
```

## Bash Compatibility

**Issue**: macOS ships with Bash 3.2 (released 2006), which lacks associative arrays (`declare -A`)

**Solution**: Use grep-based tracking instead of associative arrays

**Before (Bash 4+ only)**:
```bash
declare -A processed_paths
processed_paths["file.txt"]=1
if [ -n "${processed_paths[$key]}" ]; then
    # exists
fi
```

**After (Bash 3+ compatible)**:
```bash
touch /tmp/processed-paths-$$.txt
echo "file.txt" >> /tmp/processed-paths-$$.txt
if grep -Fxq "file.txt" /tmp/processed-paths-$$.txt; then
    # exists
fi
```

**Rationale**:
- Works on all macOS versions (Bash 3.2+)
- Works on Linux (Bash 4+)
- Minimal performance impact for typical file counts (<1000 files)
- Simple cleanup with `rm -f`

## Dependencies

### Required
- **imagemagick**: `brew install imagemagick` (macOS) or `apt-get install imagemagick` (Linux)
- **yq**: Already installed (YAML parsing)
- **shasum**: Built-in (checksums)
- **file**: Built-in (MIME type detection)

### Installation Check

Scripts verify dependencies on startup and provide clear installation instructions:

```bash
[ERROR] Missing required dependencies: imagemagick
[ERROR] Install with: brew install imagemagick
```

## Alternatives Considered for Cache

### Option A: No cache (rejected)
- Too slow for large libraries (10+ seconds for 100 images)
- Wastes CPU on unchanged files

### Option B: SQLite database (rejected)
- Over-engineered for simple key-value storage
- Adds external dependency
- More complex to debug

### Option C: Separate cache file per image (rejected)
- Creates hundreds of tiny files
- Filesystem overhead
- Harder to clean up

### Option D: JSON cache (chosen)
- **Simple**: Single file, easy to inspect
- **Fast**: Loaded once, written once
- **Portable**: Works everywhere
- **Human-readable**: Can be manually edited if needed
- **Self-cleaning**: Old entries naturally age out when files are removed

## Consequences

### Positive
- ✅ Fast manifest generation (10x speedup with cache)
- ✅ Accurate dimension extraction for all image formats
- ✅ Cross-platform compatibility (macOS, Linux)
- ✅ Graceful handling of non-images (no dimensions field)
- ✅ Simple, maintainable implementation

### Negative
- ⚠️ Requires ImageMagick installation (documented in README)
- ⚠️ Cache file adds ~1-10KB per 100 images (negligible)
- ⚠️ Bash 3 compatibility adds slight complexity (but necessary)

### Neutral
- 📝 Cache invalidation relies on mtime/size (standard approach)
- 📝 Manual cache cleanup: `rm .dimensions-cache.json` (rarely needed)

## Validation

### Test Coverage
- ✅ Unit tests for dimension extraction
- ✅ Unit tests for cache operations
- ✅ Integration tests for full workflow
- ✅ Edge case tests (corrupted images, non-images, special characters)

### Performance Testing
- ✅ 100 files processed in <10 seconds (target met)
- ✅ Cache hit rate >90% for typical workflows
- ✅ Tested on macOS 14.x (Bash 3.2)

## References

- **ImageMagick Documentation**: https://imagemagick.org/script/identify.php
- **Issue #29**: https://github.com/matteocervelli/dotfiles/issues/29
- **Asset Management Plan**: [docs/ASSET-MANAGEMENT-PLAN.md](../../ASSET-MANAGEMENT-PLAN.md)
- **Bash 3 Compatibility**: https://tldp.org/LDP/abs/html/bashver3.html

## Related Decisions

- ADR-002: Environment-Aware Asset Resolution (planned)
- ADR-003: Smart Sync Strategies (planned)

---

**Last Updated**: 2025-01-24
**Author**: Claude Code + Matteo Cervelli
