# Fedora systemd Services

This directory contains systemd service and timer units for Fedora Linux.

## Auto-Update Service

Automatically updates dotfiles to GitHub every 30 minutes.

### Installation

1. **Copy files to systemd user directory**:
   ```bash
   mkdir -p ~/.config/systemd/user
   cp system/fedora/systemd/dotfiles-autoupdate.* ~/.config/systemd/user/
   ```

2. **Update USERNAME placeholders**:
   ```bash
   # Edit the service file and replace YOUR_USERNAME with your actual username
   sed -i "s/YOUR_USERNAME/$USER/g" ~/.config/systemd/user/dotfiles-autoupdate.service
   ```

3. **Reload systemd and enable the timer**:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable dotfiles-autoupdate.timer
   systemctl --user start dotfiles-autoupdate.timer
   ```

4. **Enable lingering** (so services run even when not logged in):
   ```bash
   loginctl enable-linger $USER
   ```

### Status and Management

**Check timer status**:
```bash
systemctl --user status dotfiles-autoupdate.timer
systemctl --user list-timers
```

**View logs**:
```bash
journalctl --user -u dotfiles-autoupdate.service -f
```

**Manually trigger update**:
```bash
systemctl --user start dotfiles-autoupdate.service
```

**Stop and disable**:
```bash
systemctl --user stop dotfiles-autoupdate.timer
systemctl --user disable dotfiles-autoupdate.timer
```

## SELinux Considerations

On Fedora with SELinux enabled (default), you may need to adjust SELinux contexts:

```bash
# Check for SELinux denials
ausearch -m avc -ts recent

# If needed, create a custom policy (advanced)
# Or set the context for the script
chcon -t bin_t ~/dev/projects/dotfiles/scripts/sync/auto-update-dotfiles.sh
```

## Fedora-Specific Notes

- **firewalld**: Ensure firewall allows outbound HTTPS (usually enabled by default)
- **SELinux**: Services run in user context, usually no policy changes needed
- **User services**: These are user services (not system-wide), no sudo required
- **Persistent timers**: Will catch up missed runs if system was off

## Troubleshooting

**Timer not running**:
```bash
# Check if lingering is enabled
loginctl show-user $USER | grep Linger

# Enable if needed
loginctl enable-linger $USER
```

**Permission denied errors**:
```bash
# Ensure script is executable
chmod +x ~/dev/projects/dotfiles/scripts/sync/auto-update-dotfiles.sh

# Check SELinux contexts
ls -Z ~/dev/projects/dotfiles/scripts/sync/auto-update-dotfiles.sh
```

**Network issues**:
```bash
# Verify network is available when service runs
systemctl --user status dotfiles-autoupdate.service

# Check firewalld status
sudo firewall-cmd --state
```

## Comparison with Ubuntu

These systemd units are identical to Ubuntu versions and can be used interchangeably. The main difference is SELinux enforcement on Fedora vs AppArmor on Ubuntu.
