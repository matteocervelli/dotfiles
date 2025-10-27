# Base Development Container
# Extends dotfiles-ubuntu:dev with additional dev container features
#
# Build:
#   docker build -t devcontainer-base:latest .
#
# Usage:
#   Used as base for project-specific dev containers

FROM dotfiles-ubuntu:dev

# Metadata
LABEL maintainer="Matteo Cervelli"
LABEL description="Base development container with dotfiles"
LABEL devcontainer="true"

# Switch to root for installations
USER root

# Install additional dev container tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Additional CLI tools
    less \
    man-db \
    openssh-client \
    rsync \
    unzip \
    zip \
    # Network tools
    iputils-ping \
    netcat-openbsd \
    # Process tools
    procps \
    psmisc \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Docker CLI (for Docker-in-Docker scenarios)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install docker-compose v2
RUN curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Create directories for dev container volumes
RUN mkdir -p /home/developer/.history \
    /home/developer/.vscode-server \
    /home/developer/.vscode-server/extensions \
    && chown -R developer:developer /home/developer/.history /home/developer/.vscode-server

# Switch back to developer user
USER developer
WORKDIR /workspace

# Set environment variables for dev container
ENV DEVCONTAINER=true
ENV WORKSPACE_FOLDER=/workspace

# Default command (overridden by devcontainer.json)
CMD ["/bin/zsh"]
