# Generated using windows-sandbox plugin Intermediate mode
# Development container for plugin development with services
# Includes PostgreSQL, Redis, RabbitMQ for testing examples

FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install system packages including iptables for firewall
RUN apt-get update && apt-get install -y --no-install-recommends \
  git vim nano less procps sudo curl ca-certificates \
  iptables ipset \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
  apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Create node user
RUN groupadd --gid 1000 node && \
  useradd --uid 1000 --gid node --shell /bin/bash --create-home node

RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

# Create workspace
RUN mkdir -p /workspace && chown -R node:node /workspace

WORKDIR /workspace

USER node

# NPM global config
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Python uv environment
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV PATH="/workspace/.venv/bin:$PATH"

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code
