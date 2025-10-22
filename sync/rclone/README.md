# Rclone Configuration for Cloudflare R2

## Overview

This directory contains the Rclone configuration template for Cloudflare R2 storage. The configuration uses 1Password for secure credential management, following the same pattern as `.env` files in the project.

## Directory Structure

```
sync/rclone/
├── rclone.conf.template    # Template with 1Password references (committed)
└── README.md               # This file

~/.config/rclone/
└── rclone.conf            # Generated config with actual credentials (gitignored)
```

## Prerequisites

1. **1Password CLI** installed and authenticated
   ```bash
   # Install (if not already)
   brew install --cask 1password-cli

   # Authenticate
   eval $(op signin)
   ```

2. **Rclone** installed
   ```bash
   # Install (if not already)
   brew install rclone
   ```

3. **1Password Item** configured with R2 credentials

## 1Password Item Setup

You need to create an item in 1Password with the following structure:

- **Vault**: `Private`
- **Item Name**: `Cloudflare-R2`
- **Item Type**: `Login` or `API Credential`
- **Fields**:
  - `access_key_id`: Your Cloudflare R2 Access Key ID
  - `secret_access_key`: Your Cloudflare R2 Secret Access Key
  - `endpoint`: Your R2 endpoint URL (e.g., `https://605c06bedaf25b851bad46ee769660d5.r2.cloudflarestorage.com`)

### How to Get R2 Credentials

1. Login to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to **R2** → **Overview**
3. Click **Manage R2 API Tokens**
4. Create a new API token or use existing one
5. Copy the credentials to 1Password

## Installation

### Quick Setup

```bash
# 1. Authenticate with 1Password
eval $(op signin)

# 2. Run setup script
~/dotfiles/scripts/sync/setup-rclone.sh
```

The script will:
- ✅ Check if rclone is already configured
- ✅ Verify 1Password authentication
- ✅ Inject credentials from 1Password template
- ✅ Create `~/.config/rclone/rclone.conf` with permissions 600
- ✅ Test R2 connection automatically

### Manual Setup

If you prefer to set up manually:

```bash
# 1. Authenticate with 1Password
eval $(op signin)

# 2. Inject credentials manually
op inject \
  -i ~/dotfiles/sync/rclone/rclone.conf.template \
  -o ~/.config/rclone/rclone.conf

# 3. Set proper permissions
chmod 600 ~/.config/rclone/rclone.conf

# 4. Test connection
rclone lsd remote-cdn:
```

## Usage

### List Configured Remotes

```bash
rclone listremotes
# Output: remote-cdn:
```

### List R2 Buckets

```bash
rclone lsd remote-cdn:
# Output:
#           -1 2024-01-15 10:30:00        -1 media-adlimen
```

### List Files in Bucket

```bash
rclone ls remote-cdn:media-adlimen
```

### Sync Local Directory to R2

```bash
# Sync ~/media/cdn to R2
rclone sync ~/media/cdn remote-cdn:media-adlimen --progress

# Or use the provided script
~/dotfiles/scripts/sync/sync-cdn-media.sh
```

### Download from R2

```bash
rclone copy remote-cdn:media-adlimen/file.jpg ~/Downloads/
```

## Testing

### Test Connection

```bash
~/dotfiles/scripts/sync/test-rclone.sh
```

### Manual Connection Test

```bash
# List remotes
rclone listremotes

# Test remote-cdn connection
rclone lsd remote-cdn:

# Check config (careful: contains secrets!)
cat ~/.config/rclone/rclone.conf
```

## Troubleshooting

### Error: "op:// reference not found"

**Problem**: 1Password injection failed because the item or field doesn't exist.

**Solution**:
```bash
# Verify 1Password item exists
op item get "Cloudflare-R2" --vault Private

# Test individual field access
op read "op://Private/Cloudflare-R2/access_key_id"
op read "op://Private/Cloudflare-R2/secret_access_key"
op read "op://Private/Cloudflare-R2/endpoint"
```

If any command fails, create or update the 1Password item with the correct fields.

### Error: "Connection failed"

**Problem**: Rclone config is valid but can't connect to R2.

**Possible causes**:
1. **Invalid credentials**: Check credentials in 1Password
2. **Wrong endpoint**: Verify endpoint URL format
3. **Network issues**: Test connectivity to R2

**Debug steps**:
```bash
# Verify config file exists
ls -la ~/.config/rclone/rclone.conf

# Check config contents (careful: contains secrets!)
cat ~/.config/rclone/rclone.conf

# Test endpoint connectivity
curl -I https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com

# Verbose rclone test
rclone lsd remote-cdn: -vv
```

### Error: "Permission denied"

**Problem**: Config file has wrong permissions.

**Solution**:
```bash
chmod 600 ~/.config/rclone/rclone.conf
```

### Regenerate Configuration

If you need to regenerate the config (e.g., after credential rotation):

```bash
# Remove existing config
rm ~/.config/rclone/rclone.conf

# Regenerate from template
~/dotfiles/scripts/sync/setup-rclone.sh
```

## Security Notes

### ✅ What's Safe to Commit

- `rclone.conf.template` - Template with 1Password references
- Documentation and scripts
- `.gitignore` rules

### ⛔ Never Commit

- `~/.config/rclone/rclone.conf` - Contains actual credentials
- Any file with real R2 credentials

### Best Practices

1. **Keep credentials in 1Password**: Never hardcode in scripts
2. **Use `op inject`**: Automate credential injection
3. **Rotate credentials**: Update in 1Password, regenerate config
4. **File permissions**: Always `600` for config files
5. **Audit access**: Review who has access to 1Password item

## Integration with Other Tools

### Git Hooks

You can add a pre-commit hook to prevent accidental commit of actual config:

```bash
# .git/hooks/pre-commit
if git diff --cached --name-only | grep -q "rclone.conf$"; then
    echo "ERROR: Attempting to commit rclone.conf with credentials!"
    exit 1
fi
```

### Environment Variables

Rclone can also use environment variables (alternative to config file):

```bash
export RCLONE_CONFIG_REMOTE_CDN_TYPE=s3
export RCLONE_CONFIG_REMOTE_CDN_PROVIDER=Cloudflare
export RCLONE_CONFIG_REMOTE_CDN_ACCESS_KEY_ID="$(op read 'op://Private/Cloudflare-R2/access_key_id')"
export RCLONE_CONFIG_REMOTE_CDN_SECRET_ACCESS_KEY="$(op read 'op://Private/Cloudflare-R2/secret_access_key')"
export RCLONE_CONFIG_REMOTE_CDN_ENDPOINT="$(op read 'op://Private/Cloudflare-R2/endpoint')"
```

## Related Scripts

- [`scripts/sync/setup-rclone.sh`](../../scripts/sync/setup-rclone.sh) - Setup script
- [`scripts/sync/test-rclone.sh`](../../scripts/sync/test-rclone.sh) - Connection test
- [`scripts/sync/sync-cdn-media.sh`](../../scripts/sync/sync-cdn-media.sh) - Media sync script

## Additional Resources

- [Rclone Documentation](https://rclone.org/docs/)
- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [Project IMPLEMENTATION-PLAN.md](../../docs/IMPLEMENTATION-PLAN.md#23-rclone-setup-for-r2)
