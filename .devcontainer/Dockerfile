# Generated using sandbox-maxxing plugin Intermediate mode
# Development container for plugin development with services
# Includes PostgreSQL, Redis, RabbitMQ for testing examples

# Stage 1: Get Node.js from official image (Issue #29)
FROM node:20-slim AS node-source

# Stage 2: Main build
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install system packages including iptables for firewall
RUN apt-get update && apt-get install -y --no-install-recommends \
  git vim nano less procps sudo curl ca-certificates \
  iptables ipset \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Node.js from official image (Issue #29 - avoids NodeSource SSL issues)
COPY --from=node-source /usr/local/bin/node /usr/local/bin/
COPY --from=node-source /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Create node user
RUN groupadd --gid 1000 node && \
  useradd --uid 1000 --gid node --shell /bin/bash --create-home node

RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

# Create workspace
RUN mkdir -p /workspace && chown -R node:node /workspace

WORKDIR /workspace

# Setup npm registry allowlist for Claude Code updates (Issue #32)
RUN echo "registry.npmjs.org" >> /etc/claude-allowed-domains.txt && \
    echo "npmjs.org" >> /etc/claude-allowed-domains.txt

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
