# Dev Container Quick-Start Cheat Sheet

**One-page reference for common dev container operations**

---

## ⚡ Quick Generate

```bash
# Python project
./scripts/devcontainer/generate-devcontainer.sh -t python -p ~/my-app

# Node.js project
./scripts/devcontainer/generate-devcontainer.sh -t nodejs -p ~/web-app

# Base/Generic project
./scripts/devcontainer/generate-devcontainer.sh -t base -p ~/project
```

---

## 🚀 Launch Methods

### Method 1: VS Code (Recommended)

```bash
code ~/my-app
# Then: Cmd+Shift+P → "Dev Containers: Reopen in Container"
```

### Method 2: Docker Compose

```bash
cd ~/my-app
docker-compose -f .devcontainer/docker-compose.yml up -d
docker-compose -f .devcontainer/docker-compose.yml exec devcontainer zsh
```

### Method 3: Docker Direct

```bash
cd ~/my-app
docker build -f .devcontainer/Dockerfile -t my-app-dev .
docker run -it -v $(pwd):/workspace my-app-dev zsh
```

---

## 🌙 Autonomous Claude Sessions

Perfect for leaving computer running overnight or during breaks.

### Quick Setup

```bash
# 1. Generate container
./scripts/devcontainer/generate-devcontainer.sh -t python -p ~/ai-project

# 2. Open and reopen in container
code ~/ai-project
# Cmd+Shift+P → "Dev Containers: Reopen in Container"

# 3. Start Claude Code session
# All work isolated to /workspace!
```

### Safety Checklist ✅

- ✅ Container isolation (all changes in `/workspace`)
- ✅ Resource limits set (see Configuration below)
- ✅ Backup important data before long runs
- ✅ Git commits for tracking progress
- ✅ Easy rollback (delete container)

### When You Return

```bash
# Check what Claude did
cd ~/ai-project
git log --oneline --since="8 hours ago"
git diff HEAD~5

# Check container logs
docker logs devcontainer-ai-project-python

# Check resource usage
docker stats devcontainer-ai-project-python
```

---

## ⚙️ Configuration

### Resource Limits

Edit `.devcontainer/docker-compose.yml`:

```yaml
services:
  devcontainer:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
```

### Add VS Code Extensions

Edit `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "your-extension-here"
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

---

## 🔧 Common Operations

### Rebuild Container

```bash
# In VS Code
# Cmd+Shift+P → "Dev Containers: Rebuild Container"

# Or via Docker
cd ~/my-app
docker-compose -f .devcontainer/docker-compose.yml build --no-cache
docker-compose -f .devcontainer/docker-compose.yml up -d
```

### Shell Into Running Container

```bash
docker-compose -f .devcontainer/docker-compose.yml exec devcontainer zsh
```

### Stop Container

```bash
docker-compose -f .devcontainer/docker-compose.yml down
```

### Delete and Start Fresh

```bash
docker-compose -f .devcontainer/docker-compose.yml down -v
./scripts/devcontainer/generate-devcontainer.sh -t python -p ~/my-app --force
```

---

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs devcontainer-<project>-<template>

# Rebuild
docker-compose -f .devcontainer/docker-compose.yml build --no-cache
```

### VS Code Can't Connect

1. Check Docker is running: `docker ps`
2. Restart VS Code
3. Rebuild: Cmd+Shift+P → "Dev Containers: Rebuild Container"

### Port Already in Use

Edit `.devcontainer/devcontainer.json`:

```json
{
  "forwardPorts": [3001]  // Changed from 3000
}
```

### Work Not Saved

Verify workspace mount:

```bash
docker inspect devcontainer-<project> | grep -A 5 Mounts
ls -la ~/my-project  # Should see your files
```

---

## 📚 Templates

### Base Template

- **For**: Shell scripts, utilities, generic projects
- **Includes**: Ubuntu + ZSH + Git + Docker CLI
- **Size**: ~250MB

### Python Template

- **For**: Python apps, APIs, data processing
- **Includes**: Base + Python 3.11 + pip/poetry/pipenv
- **Ports**: 8000, 5000
- **Auto-detects**: requirements.txt, pyproject.toml, Pipfile

### Node.js Template

- **For**: Web apps, React/Vue, APIs
- **Includes**: Base + Node.js LTS + npm/pnpm/yarn
- **Ports**: 3000, 8080, 5173 (Vite)
- **Auto-detects**: package.json + lock files

---

## 🎯 Use Cases

### Scenario: Overnight Refactoring

```bash
# Before leaving
./scripts/devcontainer/generate-devcontainer.sh -t python -p ~/refactor
code ~/refactor  # Reopen in container
# Give Claude clear instructions
# Leave running

# Next morning
cd ~/refactor
git log --oneline --since="yesterday"
# Review and approve changes
```

### Scenario: Safe Experimentation

```bash
# Try risky changes in container
./scripts/devcontainer/generate-devcontainer.sh -t nodejs -p ~/experiment
# Make changes, test, experiment
# If failed: delete container and start fresh
# If successful: commit and push
```

### Scenario: Team Consistency

```bash
# Commit .devcontainer/ to git
git add .devcontainer/
git commit -m "Add dev container configuration"
git push

# Team members:
git pull
code .  # Reopen in container
# Everyone has identical environment!
```

---

## 🔗 Quick Links

- **Full Guide**: [DEVCONTAINER-GUIDE.md](DEVCONTAINER-GUIDE.md)
- **Docker Images**: [DOCKER-UBUNTU-MINIMAL.md](DOCKER-UBUNTU-MINIMAL.md)
- **VS Code Docs**: https://code.visualstudio.com/docs/devcontainers/containers
- **Dev Container Spec**: https://containers.dev/

---

## 💡 Pro Tips

1. **Commit early**: Push to git before long autonomous sessions
2. **Resource limits**: Set appropriate CPU/RAM limits for task
3. **Named volumes**: Use volumes for data that persists across rebuilds
4. **SSH keys**: Use SSH agent forwarding, not direct mounts
5. **Secrets**: Use `.env` files, never commit secrets

---

**Created**: 2025-10-28
**Status**: Active
**Templates Available**: base, python, nodejs
**Coming Soon**: fullstack, data-science
