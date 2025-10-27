# Dev Container Templates

Project-specific development container templates for isolated, reproducible development environments.

## Overview

These templates provide pre-configured dev containers for different project types, enabling:

- **Isolated Development**: Each project in its own container
- **Claude Code Integration**: Safe operations with "dangerously skip mode"
- **VS Code Integration**: Seamless Dev Containers experience
- **Automatic Setup**: Dependencies installed on container creation
- **Consistency**: Same environment across team members

---

## Quick Start

### Generate Dev Container

```bash
# Python project
make devcontainer-python PROJECT=~/my-python-app

# Node.js project
make devcontainer-nodejs PROJECT=~/my-web-app

# Or use generator directly
./scripts/devcontainer/generate-devcontainer.sh \
  --template python \
  --project ~/my-app
```

### Open in VS Code

```bash
code ~/my-app
```

Then: **Cmd/Ctrl + Shift + P** → "Dev Containers: Reopen in Container"

---

## Available Templates

### 1. Base (`base/`)

**Use Case**: Generic projects, shell scripts, utilities

**Includes**:
- Ubuntu 24.04 with dotfiles
- ZSH + Oh My Zsh
- Git + Docker CLI
- Basic development tools

**Size**: ~250 MB

**Generate**:
```bash
make devcontainer-generate TEMPLATE=base PROJECT=~/my-project
```

---

### 2. Python (`python/`)

**Use Case**: Python applications, APIs, data processing, automation

**Includes**:
- Base template +
- Python 3.11 with pyenv
- pip, poetry, pipenv
- black, ruff, pytest
- PostgreSQL client
- Image processing libraries

**Auto-detects**:
- `requirements.txt` → Creates venv + `pip install`
- `pyproject.toml` (Poetry) → `poetry install`
- `Pipfile` → `pipenv install`

**Ports**: 8000 (app), 5000 (Flask)

**VS Code Extensions**:
- Python
- Pylance
- Black Formatter
- Ruff
- AutoDocstring

**Generate**:
```bash
make devcontainer-python PROJECT=~/my-python-app
```

---

### 3. Node.js (`nodejs/`)

**Use Case**: Web applications, React/Vue/Angular, APIs, TypeScript

**Includes**:
- Base template +
- Node.js LTS with nvm
- npm, pnpm, yarn
- TypeScript, ts-node
- ESLint, Prettier
- Build tools (webpack, vite, rollup)

**Auto-detects**:
- `pnpm-lock.yaml` → `pnpm install`
- `yarn.lock` → `yarn install`
- `package-lock.json` → `npm install`

**Ports**: 3000 (app), 8080 (dev server), 5173 (Vite)

**VS Code Extensions**:
- ESLint
- Prettier
- npm Intellisense
- TypeScript

**Generate**:
```bash
make devcontainer-nodejs PROJECT=~/my-web-app
```

---

### 4. Full-Stack (`fullstack/`) [Planned]

**Use Case**: Full-stack applications with backend + frontend + database

**Includes**:
- Python + Node.js
- PostgreSQL 16
- Redis 7
- Nginx (optional)
- Adminer (database UI)

**Services**:
- `app` - Application container
- `postgres` - PostgreSQL database
- `redis` - Redis cache
- `adminer` - Database admin UI

**Ports**: 3000 (frontend), 8000 (backend), 5432 (Postgres), 6379 (Redis), 8080 (Adminer)

---

### 5. Data Science (`data-science/`) [Planned]

**Use Case**: Data analysis, machine learning, Jupyter notebooks

**Includes**:
- Python with scientific stack
- Jupyter Lab
- pandas, NumPy, Matplotlib, Seaborn
- Scikit-learn, TensorFlow, PyTorch
- PostgreSQL client
- Git LFS

**Ports**: 8888 (Jupyter)

---

## Template Structure

Each template directory contains:

```
template-name/
├── .devcontainer/
│   ├── devcontainer.json    # Dev container configuration
│   ├── Dockerfile            # Container image definition
│   ├── docker-compose.yml    # Docker Compose config (optional)
│   └── post-create.sh        # Post-creation script (optional)
└── README.md                 # Template documentation
```

---

## Template Files

### devcontainer.json

Main configuration file for VS Code Dev Containers:

```json
{
  "name": "Project Name",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python"]
    }
  },
  "forwardPorts": [8000],
  "remoteUser": "developer",
  "remoteEnv": {
    "CLAUDE_CODE_CONTAINER": "true",
    "PROJECT_ROOT": "/workspace"
  }
}
```

### Dockerfile

Container image extending `dotfiles-ubuntu:dev`:

```dockerfile
FROM dotfiles-ubuntu:dev

USER root
# Install project-specific tools
RUN apt-get update && apt-get install -y postgresql-client

USER developer
# Setup project environment
```

### docker-compose.yml

Multi-service orchestration (optional):

```yaml
version: '3.8'
services:
  devcontainer:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile
    volumes:
      - ..:/workspace:cached
```

### post-create.sh

Automatic setup after container creation:

```bash
#!/bin/bash
# Install dependencies
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi
```

---

## Customization

### Add VS Code Extensions

Edit `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  }
}
```

### Forward Additional Ports

```json
{
  "forwardPorts": [3000, 8000, 5432]
}
```

### Mount Additional Volumes

```json
{
  "mounts": [
    "source=my-data,target=/data,type=volume"
  ]
}
```

### Add Environment Variables

```json
{
  "containerEnv": {
    "DEBUG": "true",
    "DATABASE_URL": "postgresql://localhost/db"
  }
}
```

---

## Claude Code Integration

### Safe Operations

Dev containers provide isolation for Claude Code's operations:

```bash
# These commands are safe in dev containers:
pip install <package>      # Python packages
npm install <package>      # Node packages
apt-get install <package>  # System packages
docker run ...             # Docker containers (with Docker-in-Docker)
```

### Environment Variables

All templates set:

```bash
CLAUDE_CODE_CONTAINER=true    # Dev container indicator
PROJECT_ROOT=/workspace        # Project root
PROJECT_TYPE=python            # Template type
```

### Dangerously Skip Mode

When using Claude Code's "dangerously skip mode":

- All operations isolated to container
- File operations limited to `/workspace`
- System changes don't affect host
- Easy to reset (delete container)

---

## Workflow

### 1. Generate Dev Container

```bash
./scripts/devcontainer/generate-devcontainer.sh \
  --template python \
  --project ~/my-app
```

### 2. Open in VS Code

```bash
code ~/my-app
```

### 3. Reopen in Container

**Cmd/Ctrl + Shift + P** → "Dev Containers: Reopen in Container"

### 4. Develop with Claude

Claude can now safely:
- Install packages
- Run tests
- Make system changes
- Execute commands

All isolated to the container!

---

## Management Commands

```bash
# Generate
make devcontainer-generate TEMPLATE=python PROJECT=~/my-app

# Start container
make devcontainer-up PROJECT=~/my-app

# Stop container
make devcontainer-down PROJECT=~/my-app

# Shell into container
make devcontainer-shell PROJECT=~/my-app

# Rebuild container
make devcontainer-rebuild PROJECT=~/my-app

# Clean (remove volumes)
make devcontainer-clean PROJECT=~/my-app

# List templates
make devcontainer-templates

# Run tests
make devcontainer-test
```

---

## Creating Custom Templates

### 1. Copy Existing Template

```bash
cp -r templates/devcontainer/base templates/devcontainer/my-template
```

### 2. Customize Files

Edit `.devcontainer/devcontainer.json`, `Dockerfile`, etc.

### 3. Update Generator Script

Add template to `AVAILABLE_TEMPLATES` in `scripts/devcontainer/generate-devcontainer.sh`:

```bash
AVAILABLE_TEMPLATES=("base" "python" "nodejs" "my-template")
```

### 4. Test

```bash
./scripts/devcontainer/generate-devcontainer.sh \
  --template my-template \
  --project /tmp/test \
  --dry-run
```

---

## Best Practices

1. **Commit `.devcontainer/` to git** - Share environment with team
2. **Use `.env` for secrets** - Don't commit sensitive data
3. **Named volumes for data** - Persist important data across rebuilds
4. **Resource limits** - Constrain CPU/memory if needed
5. **Document setup** - Update template README with specifics

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs devcontainer-<project-name>

# Rebuild
make devcontainer-rebuild PROJECT=~/my-app
```

### Slow Performance (macOS)

Already optimized with `:cached` mounts. For `node_modules`:

```json
{
  "mounts": [
    "source=node_modules,target=/workspace/node_modules,type=volume"
  ]
}
```

### Permission Issues

Container uses UID 1000. If host user is different, rebuild with custom UID.

---

## Documentation

- **Comprehensive Guide**: [docs/docker/DEVCONTAINER-GUIDE.md](../../docs/docker/DEVCONTAINER-GUIDE.md)
- **Docker Images**: [docs/docker/DOCKER-UBUNTU-MINIMAL.md](../../docs/docker/DOCKER-UBUNTU-MINIMAL.md)
- **VS Code Docs**: https://code.visualstudio.com/docs/devcontainers/containers
- **Dev Container Spec**: https://containers.dev/

---

## Support

**Issue Tracker**: [GitHub Issues](https://github.com/matteocervelli/dotfiles/issues)

**Created**: 2025-10-27
**Status**: Active (Base, Python, Node.js templates available)
