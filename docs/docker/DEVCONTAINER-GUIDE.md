# Dev Container System Guide

**Feature**: Project-specific development containers
**Related**: [Docker Ubuntu Minimal](DOCKER-UBUNTU-MINIMAL.md)
**Created**: 2025-10-27

---

## Overview

The **Dev Container System** provides templates and tools for creating isolated, project-specific development environments that work seamlessly with **Claude Code**, **VS Code**, and **Docker**. Perfect for Claude's "dangerously skip mode" operations in isolated environments.

### Key Benefits

- **Isolation**: Each project runs in its own container
- **Consistency**: Same environment across team members
- **Safety**: Claude Code operations isolated from host system
- **Portability**: Share dev environments via configuration
- **Fast Setup**: Templates for common project types

---

## Quick Start

### 1. Generate Dev Container for Your Project

```bash
# Python project
./scripts/devcontainer/generate-devcontainer.sh \
  --template python \
  --project ~/my-python-app

# Node.js project
./scripts/devcontainer/generate-devcontainer.sh \
  --template nodejs \
  --project ~/my-web-app

# Use Make target
make devcontainer-generate TEMPLATE=python PROJECT=~/my-app
```

### 2. Open in VS Code

```bash
code ~/my-python-app
```

Then: **Cmd/Ctrl + Shift + P** → "**Dev Containers: Reopen in Container**"

### 3. Or Use Docker Compose

```bash
cd ~/my-python-app
docker-compose -f .devcontainer/docker-compose.yml up -d
docker-compose -f .devcontainer/docker-compose.yml exec devcontainer zsh
```

---

## Autonomous Claude Development (Leaving Computer)

**Use Case**: Run Claude Code autonomously while away from your computer

Dev containers provide the perfect isolation for unattended Claude Code sessions. All operations are contained, safe, and easy to monitor.

### Quick Setup for Autonomous Sessions

```bash
# 1. Generate dev container for your project
./scripts/devcontainer/generate-devcontainer.sh -t python -p ~/my-ai-project

# 2. Open in VS Code and reopen in container
code ~/my-ai-project
# Then: Cmd+Shift+P → "Dev Containers: Reopen in Container"

# 3. Start Claude Code session
# Claude can now work autonomously with full isolation
```

### Safety Checklist

Before leaving your computer with Claude working:

- ✅ **Container Isolation**: All changes confined to `/workspace`
- ✅ **Resource Limits**: Set CPU/memory limits (see Advanced Usage)
- ✅ **Backup Data**: Container volumes persist, but backup important work
- ✅ **Monitor Logs**: Check `.devcontainer/post-create.sh` logs on return
- ✅ **Easy Reset**: Delete container to start fresh if needed

### Recommended Container Configuration

For autonomous sessions, add resource limits to `.devcontainer/docker-compose.yml`:

```yaml
services:
  devcontainer:
    deploy:
      resources:
        limits:
          cpus: '2.0'      # Limit to 2 CPU cores
          memory: 4G        # Limit to 4GB RAM
        reservations:
          cpus: '1.0'
          memory: 2G
```

### Monitoring Autonomous Work

When you return, check what Claude accomplished:

```bash
# View container logs
docker logs devcontainer-my-ai-project-python

# Check git history
cd ~/my-ai-project
git log --oneline --since="8 hours ago"

# Review changes
git diff HEAD~5

# Check resource usage
docker stats devcontainer-my-ai-project-python
```

### Common Scenarios

**Scenario 1: Overnight Refactoring**
```bash
# Before leaving:
# - Give Claude clear instructions
# - Ensure dev container is running
# - Claude has access to all project files in /workspace
# - All package installations contained in container

# Upon return:
# - Review git commits made by Claude
# - Run tests in container
# - Approve and merge changes
```

**Scenario 2: Multi-Hour Data Processing**
```bash
# Before leaving:
# - Start dev container with data science template
# - Set resource limits appropriate for task
# - Claude can install analysis libraries
# - All outputs saved to /workspace

# Upon return:
# - Check Jupyter notebooks created
# - Review analysis results
# - Export findings from container
```

### Why Dev Containers Are Perfect for This

1. **No Host Impact**: Claude can't accidentally modify your system
2. **Easy Rollback**: Delete container and regenerate if issues occur
3. **Reproducible**: Same environment every time
4. **Resource Controlled**: Set limits to prevent runaway processes
5. **Isolated Network**: Container networking separate from host

### Troubleshooting Autonomous Sessions

**Container Stopped Unexpectedly**
```bash
# Check why container stopped
docker ps -a | grep my-project
docker logs devcontainer-my-project-python

# Restart container
docker start devcontainer-my-project-python
```

**Out of Resources**
```bash
# Check resource usage
docker stats

# Increase limits in .devcontainer/docker-compose.yml
# Then rebuild: docker-compose up -d --force-recreate
```

**Work Not Saved**
```bash
# Verify /workspace mount
docker inspect devcontainer-my-project-python | grep -A 10 Mounts

# Ensure changes are in ~/my-project (host)
ls -la ~/my-project
```

---

## Available Templates

### 1. Base Template

**Use Case**: Generic projects, shell scripting, simple tools

**Includes**:
- Ubuntu 24.04 with dotfiles
- ZSH + Oh My Zsh
- Git configuration
- Docker CLI
- Basic dev tools

**Generate**:
```bash
./scripts/devcontainer/generate-devcontainer.sh -t base -p ~/my-project
```

---

### 2. Python Template

**Use Case**: Python applications, APIs, data processing

**Includes**:
- Base template +
- Python 3.11 with pyenv
- pip, poetry, pipenv, black, pytest
- PostgreSQL client
- Image processing libraries

**Auto-detects**:
- `requirements.txt` → Creates venv + `pip install`
- `pyproject.toml` → Poetry install
- `Pipfile` → Pipenv install

**Generate**:
```bash
./scripts/devcontainer/generate-devcontainer.sh -t python -p ~/my-python-app
```

**Ports**: 8000 (app), 5000 (Flask)

---

### 3. Node.js Template

**Use Case**: Web apps, APIs, React/Vue/Angular

**Includes**:
- Base template +
- Node.js LTS with nvm
- npm, pnpm, yarn
- TypeScript, ESLint, Prettier
- Build tools (webpack, vite, etc.)

**Auto-detects**:
- `package.json` + `pnpm-lock.yaml` → `pnpm install`
- `package.json` + `yarn.lock` → `yarn install`
- `package.json` + `package-lock.json` → `npm install`

**Generate**:
```bash
./scripts/devcontainer/generate-devcontainer.sh -t nodejs -p ~/my-web-app
```

**Ports**: 3000 (app), 8080 (dev server), 5173 (Vite)

---

### 4. Full-Stack Template

**Use Case**: Full-stack applications with backend + frontend + database

**Includes**:
- Python + Node.js
- PostgreSQL 16
- Redis 7
- Nginx (optional)
- docker-compose with services

**Services**:
- `app` - Application container (Python + Node.js)
- `postgres` - PostgreSQL database
- `redis` - Redis cache
- `adminer` - Database admin UI (port 8080)

**Generate**:
```bash
./scripts/devcontainer/generate-devcontainer.sh -t fullstack -p ~/my-fullstack-app
```

**Ports**: 3000 (frontend), 8000 (backend), 5432 (Postgres), 6379 (Redis), 8080 (Adminer)

---

### 5. Data Science Template

**Use Case**: Data analysis, machine learning, Jupyter notebooks

**Includes**:
- Python with data science stack
- Jupyter Lab
- pandas, NumPy, Matplotlib, Scikit-learn
- PostgreSQL client for data sources
- Git LFS for large files

**Generate**:
```bash
./scripts/devcontainer/generate-devcontainer.sh -t data-science -p ~/my-data-project
```

**Ports**: 8888 (Jupyter)

---

## Claude Code Integration

### Environment Variables

All dev containers set:

```bash
CLAUDE_CODE_CONTAINER=true    # Indicates dev container environment
PROJECT_ROOT=/workspace        # Project root directory
PROJECT_TYPE=python            # Template type (python, nodejs, etc.)
```

### Safe Operations

Dev containers provide isolation for Claude's operations:

1. **File Operations**: Limited to `/workspace` mount
2. **Package Installation**: Contained within container
3. **System Changes**: Don't affect host
4. **Experiments**: Easy to reset (delete container)

### Dangerously Skip Mode

When using Claude Code's dangerously skip mode in dev containers:

```bash
# Claude can safely run commands like:
pip install <package>           # Python packages
npm install <package>           # Node packages
apt-get install <package>       # System packages
docker run ...                  # Docker containers (Docker-in-Docker)
```

All changes are isolated to the container and don't affect your host system.

---

## Directory Structure

After generating a dev container, your project will have:

```
my-project/
├── .devcontainer/
│   ├── devcontainer.json       # Dev container configuration
│   ├── Dockerfile              # Container image
│   ├── docker-compose.yml      # Docker Compose config (optional)
│   ├── post-create.sh          # Post-creation script
│   └── README.md               # Template-specific docs
├── src/                        # Your source code
├── tests/                      # Your tests
└── README.md                   # Your project docs
```

---

## Configuration

### devcontainer.json

Main configuration file:

```json
{
  "name": "My Project",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python"
      ]
    }
  },
  "forwardPorts": [8000],
  "remoteUser": "developer"
}
```

### Key Settings

#### Add VS Code Extensions

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

#### Forward Ports

```json
{
  "forwardPorts": [3000, 8000, 5432],
  "portsAttributes": {
    "3000": {
      "label": "Frontend",
      "onAutoForward": "notify"
    }
  }
}
```

#### Add Environment Variables

```json
{
  "containerEnv": {
    "DEBUG": "true",
    "DATABASE_URL": "postgresql://user:pass@postgres:5432/db"
  }
}
```

#### Mount Additional Volumes

```json
{
  "mounts": [
    "source=my-data,target=/data,type=volume"
  ]
}
```

---

## Advanced Usage

### Docker-in-Docker

All dev containers include Docker CLI. To enable Docker-in-Docker:

**Method 1: Docker socket mount**

Edit `.devcontainer/docker-compose.yml`:

```yaml
services:
  devcontainer:
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

**Method 2: DinD feature**

Edit `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  }
}
```

---

### Multi-Service Projects

For projects requiring multiple services (database, cache, etc.), use `docker-compose.yml`:

```yaml
version: '3.8'

services:
  app:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile
    volumes:
      - ..:/workspace:cached
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: developer
      POSTGRES_PASSWORD: developer
      POSTGRES_DB: myapp
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres-data:
```

Then open with:
```bash
code ~/my-project
# VS Code will automatically detect docker-compose.yml and use it
```

---

### SSH Keys in Container

**Method 1: Agent forwarding (Recommended)**

Edit `.devcontainer/devcontainer.json`:

```json
{
  "mounts": [
    "type=bind,source=${localEnv:SSH_AUTH_SOCK},target=/ssh-agent"
  ],
  "remoteEnv": {
    "SSH_AUTH_SOCK": "/ssh-agent"
  }
}
```

**Method 2: Direct mount (Less secure)**

```json
{
  "mounts": [
    "type=bind,source=${localEnv:HOME}/.ssh,target=/home/developer/.ssh-host,readonly"
  ],
  "postCreateCommand": "cp -r /home/developer/.ssh-host /home/developer/.ssh && chmod 600 /home/developer/.ssh/*"
}
```

---

### Custom Post-Create Script

Edit `.devcontainer/post-create.sh`:

```bash
#!/bin/bash
set -e

echo "Running custom setup..."

# Install additional tools
pip install pre-commit
pre-commit install

# Setup database
createdb myapp

# Seed data
python manage.py migrate
python manage.py seed

echo "Setup complete!"
```

---

## Workflow Examples

### Example 1: New Python Project

```bash
# 1. Generate dev container
./scripts/devcontainer/generate-devcontainer.sh -t python -p ~/my-api

# 2. Create Python project
cd ~/my-api
cat > requirements.txt << EOF
fastapi
uvicorn[standard]
sqlalchemy
alembic
EOF

# 3. Open in VS Code
code ~/my-api

# 4. Reopen in container (Cmd+Shift+P)
# Container will auto-install requirements.txt

# 5. Start coding with Claude
# Claude can now safely run commands in isolated container
```

---

### Example 2: Existing Node.js Project

```bash
# 1. Navigate to existing project
cd ~/existing-web-app

# 2. Generate dev container (will backup existing .devcontainer if exists)
~/dotfiles/scripts/devcontainer/generate-devcontainer.sh -t nodejs -p .

# 3. Open in VS Code
code .

# 4. Reopen in container
# Container will auto-run npm install

# 5. Continue development
# All team members can now use same environment
```

---

### Example 3: Full-Stack with Database

```bash
# 1. Generate full-stack template
./scripts/devcontainer/generate-devcontainer.sh -t fullstack -p ~/my-fullstack

# 2. Open in VS Code
code ~/my-fullstack

# 3. Services start automatically:
#    - PostgreSQL on port 5432
#    - Redis on port 6379
#    - Adminer on port 8080

# 4. Connect to database
# Host: postgres (from container) or localhost (from host)
# User: developer
# Password: developer
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs devcontainer-<project-name>

# Rebuild container
docker-compose -f .devcontainer/docker-compose.yml build --no-cache
docker-compose -f .devcontainer/docker-compose.yml up -d
```

---

### VS Code Can't Connect

1. Check Docker is running: `docker ps`
2. Check container is running: `docker ps | grep devcontainer`
3. Restart VS Code
4. Try: **Cmd+Shift+P** → "Dev Containers: Rebuild Container"

---

### Port Already in Use

Edit `.devcontainer/devcontainer.json`:

```json
{
  "forwardPorts": [3001]  // Changed from 3000
}
```

Or in `docker-compose.yml`:

```yaml
ports:
  - "3001:3000"  # Map host 3001 to container 3000
```

---

### Slow Performance (macOS)

Use `:cached` consistency for volumes (already configured):

```json
{
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
}
```

For large `node_modules`, use volume mount:

```json
{
  "mounts": [
    "source=node_modules,target=/workspace/node_modules,type=volume"
  ]
}
```

---

### Permission Issues

Ensure container user UID matches host:

```bash
# Check host UID
id -u  # Should be 1000

# If different, rebuild with custom UID
# Edit Dockerfile:
ARG USER_UID=1501
RUN usermod -u ${USER_UID} developer && \
    groupmod -g ${USER_UID} developer
```

---

## Best Practices

### 1. Version Control

**Commit** `.devcontainer/` to git:

```bash
git add .devcontainer/
git commit -m "Add dev container configuration"
```

This ensures all team members use the same environment.

---

### 2. Environment Variables

Use `.env` file for secrets (add to `.gitignore`):

```bash
# .env
DATABASE_URL=postgresql://user:pass@localhost/db
API_KEY=secret-key
```

Then load in `devcontainer.json`:

```json
{
  "runArgs": ["--env-file", ".env"]
}
```

---

### 3. Persistent Data

Use named volumes for data that should persist:

```yaml
volumes:
  postgres-data:  # Named volume (persists across rebuilds)
```

---

### 4. Resource Limits

For resource-intensive projects:

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

---

### 5. Documentation

Update `.devcontainer/README.md` with project-specific setup:

```markdown
# My Project Dev Container

## Setup
1. Open in VS Code
2. Reopen in container
3. Run: `make setup`

## Database
- Host: postgres
- Port: 5432
- User: developer
```

---

## Makefile Integration

Common dev container operations via Make:

```bash
# Generate dev container
make devcontainer-generate TEMPLATE=python PROJECT=~/my-app

# Build dev container image
make devcontainer-build PROJECT=~/my-app

# Start dev container
make devcontainer-up PROJECT=~/my-app

# Stop dev container
make devcontainer-down PROJECT=~/my-app

# Shell into dev container
make devcontainer-shell PROJECT=~/my-app

# Rebuild dev container
make devcontainer-rebuild PROJECT=~/my-app

# Clean dev container
make devcontainer-clean PROJECT=~/my-app
```

---

## VS Code Extensions

### Required

- [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) - Core extension

### Recommended

- [Docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) - Docker management
- [Remote Explorer](https://marketplace.visualstudio.com/items?itemName=ms-vscode.remote-explorer) - Browse containers

---

## Related Documentation

- [Docker Ubuntu Minimal](DOCKER-UBUNTU-MINIMAL.md) - Base images
- [ADR-005: Docker Installation](../architecture/ADR/ADR-005-docker-ubuntu-installation.md)
- [VS Code Dev Containers Docs](https://code.visualstudio.com/docs/devcontainers/containers)
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code/)

---

## Support

**Issue Tracker**: [GitHub Issues](https://github.com/matteocervelli/dotfiles/issues)
**Dev Container Spec**: [containers.dev](https://containers.dev/)

---

## Changelog

### 2025-10-27 - v1.0

- Initial dev container system
- Templates: base, python, nodejs, fullstack, data-science
- Generator script with template selection
- Docker Compose configurations
- Claude Code integration
- Comprehensive documentation
- Makefile integration

---

**Status**: ✅ Complete
**Templates**: 5 (base, python, nodejs, fullstack, data-science)
**Integration**: VS Code, Claude Code, Docker Compose
