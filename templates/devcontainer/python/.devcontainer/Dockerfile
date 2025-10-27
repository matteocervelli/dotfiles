# Python Development Container
# Based on dotfiles-ubuntu:dev with Python-specific tools

FROM dotfiles-ubuntu:dev

LABEL maintainer="Matteo Cervelli"
LABEL description="Python development container with dotfiles"
LABEL project.type="python"

USER root

# Install Python development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Python build dependencies
    python3-dev \
    python3-pip \
    python3-venv \
    python3-wheel \
    pipx \
    # Database drivers
    libpq-dev \
    libmysqlclient-dev \
    # Image processing
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    # Other useful tools
    sqlite3 \
    postgresql-client \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install global Python tools via pipx
USER developer
RUN pipx install poetry && \
    pipx install pipenv && \
    pipx install black && \
    pipx install ruff && \
    pipx install pytest && \
    pipx install ipython

# Add pipx binaries to PATH
ENV PATH="/home/developer/.local/bin:${PATH}"

# Setup pyenv (already installed in base, just configure)
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc && \
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# Create common Python project directories
RUN mkdir -p /workspace/.venv \
    /workspace/src \
    /workspace/tests \
    /workspace/docs

WORKDIR /workspace

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    PIPENV_VENV_IN_PROJECT=1

CMD ["/bin/zsh"]
