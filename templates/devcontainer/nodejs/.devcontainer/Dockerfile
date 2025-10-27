# Node.js Development Container
# Based on dotfiles-ubuntu:dev with Node.js-specific tools

FROM dotfiles-ubuntu:dev

LABEL maintainer="Matteo Cervelli"
LABEL description="Node.js development container with dotfiles"
LABEL project.type="nodejs"

USER root

# Install Node.js build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Build tools for native modules
    g++ \
    make \
    python3 \
    # Image processing (for sharp, canvas, etc.)
    libvips-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER developer

# Install global Node.js tools
RUN npm install -g \
    npm@latest \
    pnpm \
    yarn \
    typescript \
    ts-node \
    nodemon \
    pm2 \
    eslint \
    prettier \
    @vue/cli \
    @angular/cli \
    create-react-app \
    create-next-app \
    vite

# Setup nvm (already installed, configure)
RUN echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc

# Create common Node.js project structure
RUN mkdir -p /workspace/src \
    /workspace/tests \
    /workspace/public \
    /workspace/dist

WORKDIR /workspace

# Environment variables
ENV NODE_ENV=development \
    NPM_CONFIG_PREFIX=/home/developer/.npm-global \
    PATH="/home/developer/.npm-global/bin:${PATH}"

CMD ["/bin/zsh"]
