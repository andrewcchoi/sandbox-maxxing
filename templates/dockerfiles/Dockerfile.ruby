# ============================================================================
# Stage 1: Get Node.js from official image (Issue #29)
# ============================================================================
FROM node:20-slim AS node-source

# ============================================================================
# Stage 2: Ruby Development Environment
# ============================================================================
FROM ruby:3.3-slim-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    wget \
    sudo \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Node.js from official image (Issue #29 - avoids NodeSource SSL issues)
COPY --from=node-source /usr/local/bin/node /usr/local/bin/
COPY --from=node-source /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Create non-root user with sudo access
RUN groupadd -g 1000 node && \
    useradd -m -u 1000 -g 1000 -s /bin/bash node && \
    echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install bundler and common gems
RUN gem update --system && \
    gem install bundler && \
    gem install rake rspec rubocop

# Configure gem installation for user
RUN mkdir -p /home/node/.gem && \
    chown -R node:node /home/node/.gem

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER node

# Configure gem home for non-root user
ENV GEM_HOME=/home/node/.gem \
    PATH=/home/node/.gem/bin:$PATH

# Default command
CMD ["/bin/bash"]
