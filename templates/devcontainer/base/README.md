# Base Dev Container Template

This is the base development container template that extends the `dotfiles-ubuntu:dev` image with additional dev container features.

## What's Included

- **Base**: Ubuntu 24.04 with dotfiles (shell + git)
- **Languages**: Python 3, Node.js with pyenv/nvm
- **Tools**: Git, Docker CLI, docker-compose, build-essential
- **Shell**: ZSH with Oh My Zsh
- **Dev Container Features**: VS Code integration, volume persistence

## Quick Start

### 1. Copy Template to Your Project

```bash
# From dotfiles directory
./scripts/devcontainer/generate-devcontainer.sh \
  --template base \
  --project ~/my-project
```

Or manually:

```bash
cd ~/my-project
cp -r ~/dotfiles/templates/devcontainer/base/.devcontainer .
```

### 2. Open in VS Code

```bash
code ~/my-project
```

Then: `Cmd/Ctrl + Shift + P` → "Dev Containers: Reopen in Container"

### 3. Or Use Docker Compose

```bash
cd ~/my-project
docker-compose -f .devcontainer/docker-compose.yml up -d
docker-compose -f .devcontainer/docker-compose.yml exec devcontainer zsh
```

## Customization

### Add VS Code Extensions

Edit `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "dbaeumer.vscode-eslint"
      ]
    }
  }
}
```

### Expose Ports

Edit `.devcontainer/devcontainer.json`:

```json
{
  "forwardPorts": [3000, 8000]
}
```

Or in `.devcontainer/docker-compose.yml`:

```yaml
services:
  devcontainer:
    ports:
      - "3000:3000"
      - "8000:8000"
```

### Install Additional Packages

Create `.devcontainer/post-create.sh`:

```bash
#!/bin/bash
sudo apt-get update
sudo apt-get install -y postgresql-client redis-tools
```

Then reference in `devcontainer.json`:

```json
{
  "postCreateCommand": "bash .devcontainer/post-create.sh"
}
```

## Claude Code Integration

This dev container is designed to work with Claude Code's "dangerously skip mode" for isolated development:

### Environment Variables

- `CLAUDE_CODE_CONTAINER=true` - Indicates running in dev container
- `PROJECT_ROOT=/workspace` - Project root directory
- `DEVCONTAINER=true` - Dev container marker

### Volume Persistence

- **History**: Bash/ZSH history persisted across container rebuilds
- **Extensions**: VS Code extensions cached
- **Workspace**: Your project files mounted from host

### Safety Features

1. **Non-root user**: Runs as `developer` (UID 1000)
2. **Isolated environment**: Changes don't affect host system
3. **Volume mounts**: Easy to reset by deleting volumes
4. **Resource limits**: Optional CPU/memory constraints

## Directory Structure

```
.devcontainer/
├── devcontainer.json    # Dev container configuration
├── Dockerfile          # Container image definition
├── docker-compose.yml  # Docker Compose configuration
└── post-create.sh      # Optional post-creation script
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs devcontainer-<project-name>

# Rebuild container
docker-compose -f .devcontainer/docker-compose.yml build --no-cache
```

### Permission Issues

Ensure your host user ID matches container user (1000):

```bash
id -u  # Should be 1000
```

If not, rebuild with custom UID:

```dockerfile
# In Dockerfile
ARG USER_UID=1000
RUN usermod -u ${USER_UID} developer
```

### Slow Performance

Use `:cached` mount option (already configured):

```json
{
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
}
```

## Related Documentation

- [Dev Container Python Template](../python/README.md)
- [Dev Container Node.js Template](../nodejs/README.md)
- [Docker Ubuntu Minimal](../../../docs/docker/DOCKER-UBUNTU-MINIMAL.md)
