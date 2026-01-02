# ============================================================================
# Base Dockerfile for Sandboxxer DevContainer
# ============================================================================
# Includes Python 3.12 + Node 20 + common development tools
# Language-specific additions are inserted at the marker below
#
# BUILD ARGUMENTS:
#   INSTALL_SHELL_EXTRAS=true  - git-delta, zsh plugins (default: true)
#   INSTALL_DEV_TOOLS=true     - Language dev tools, linters (default: true)
#   INSTALL_CA_CERT=false      - Corporate CA certificate (default: false)
#   ENABLE_FIREWALL=false      - Install firewall packages and script (default: false)
#
# PROXY-FRIENDLY: Set INSTALL_SHELL_EXTRAS/INSTALL_DEV_TOOLS to "false" for
# minimal builds behind corporate proxies that block GitHub releases.
#
# CORPORATE CA CERTIFICATE: For SSL inspection environments, place your CA
# certificate as 'corporate-ca.crt' in .devcontainer/ and set INSTALL_CA_CERT=true
# ============================================================================

# === GLOBAL BUILD ARGUMENTS ===
ARG INSTALL_SHELL_EXTRAS=true
ARG INSTALL_DEV_TOOLS=true
ARG INSTALL_CA_CERT=false
ARG ENABLE_FIREWALL=false

# === MULTI-STAGE SOURCES ===
# Stage 1: Get Python + uv from official Astral image
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS python-uv-source

# Stage 2: Get Go from official image (used when go partial is selected)
FROM golang:1.25-bookworm AS go-source

# Stage 3: Get Rust from official image (used when rust partial is selected)
FROM rust:bookworm AS rust-source

# Stage 4: Get Clang from community-maintained image (used when cpp-clang partial is selected)
FROM silkeh/clang:17-bookworm AS clang-source

# Stage 5: Get PHP from official image (used when php partial is selected)
FROM php:8.3-cli-bookworm AS php-source

# Stage 6: Get Composer from official image (used when php partial is selected)
FROM composer:latest AS composer-source

# Stage 7: Get GCC from official image (used when cpp-gcc partial is selected)
FROM gcc:13-bookworm AS gcc-source

# Stage 8: Get Azure CLI from official Microsoft image (used when azure-cli partial is selected)
FROM mcr.microsoft.com/azure-cli:latest AS azure-cli-source

# Stage 9: Main build
FROM node:20-bookworm-slim

# Re-declare ARGs after FROM (Docker requirement)
ARG INSTALL_SHELL_EXTRAS=true
ARG INSTALL_DEV_TOOLS=true
ARG INSTALL_CA_CERT=false
ARG ENABLE_FIREWALL=false

# Timezone configuration
ARG TZ=America/Los_Angeles
ENV TZ="$TZ"


# Install base system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
  # Core utilities
  git vim nano less procps sudo unzip wget curl ca-certificates gnupg gnupg2 \
  # JSON processing and manual pages
  jq man-db uuid-runtime \
  # Shell and CLI enhancements
  zsh fzf \
  # GitHub CLI
  gh \
  build-essential \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Firewall packages (conditionally installed based on ENABLE_FIREWALL)
RUN if [ "$ENABLE_FIREWALL" = "true" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
      iptables ipset iproute2 dnsutils aggregate \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "Firewall packages installed"; \
  else \
    echo "Firewall packages skipped (YOLO mode)"; \
  fi

# Corporate CA certificate support (for SSL inspection)
# To use: place your CA cert as 'corporate-ca.crt' in .devcontainer/ and set INSTALL_CA_CERT=true
COPY corporate-ca.crt* /tmp/
RUN if [ "$INSTALL_CA_CERT" = "true" ] && [ -f /tmp/corporate-ca.crt ]; then \
    cp /tmp/corporate-ca.crt /usr/local/share/ca-certificates/corporate-ca.crt && \
    chmod 644 /usr/local/share/ca-certificates/corporate-ca.crt && \
    update-ca-certificates && \
    echo "Corporate CA certificate installed successfully"; \
  else \
    echo "No corporate CA certificate to install"; \
  fi && rm -f /tmp/corporate-ca.crt

# Copy Python 3.12 binaries
COPY --from=python-uv-source /usr/local/bin/python3* /usr/local/bin/
COPY --from=python-uv-source /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=python-uv-source /usr/local/bin/pip* /usr/local/bin/
RUN ln -sf /usr/local/bin/python3.12 /usr/local/bin/python && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3

# Copy uv and uvx binaries
COPY --from=python-uv-source /usr/local/bin/uv /usr/local/bin/
COPY --from=python-uv-source /usr/local/bin/uvx /usr/local/bin/

# Database clients
RUN apt-get update && apt-get install -y --no-install-recommends \
  postgresql-client \
  default-mysql-client \
  sqlite3 \
  redis-tools \
  pgcli \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Puppeteer dependencies for mermaid-cli (updated for Puppeteer v24)
RUN apt-get update && apt-get install -y --no-install-recommends \
  # Core libraries
  libglib2.0-0 libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
  libcups2 libdrm2 libdbus-1-3 libexpat1 \
  # X11 and display libraries
  libx11-xcb1 libxkbcommon0 libxcomposite1 libxcb1 \
  libxdamage1 libxfixes3 libxrandr2 libxext6 libxss1 libxtst6 \
  # Graphics and rendering
  libgbm1 libpango-1.0-0 libcairo2 libasound2 libxshmfence1 \
  # Fonts for proper text rendering
  fonts-liberation \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create node user if it doesn't exist (may already exist in base image)
RUN if ! id -u node > /dev/null 2>&1; then \
  groupadd --gid 1000 node && \
  useradd --uid 1000 --gid node --shell /bin/bash --create-home node; \
fi

RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

# Persistent bash history
RUN mkdir /commandhistory && \
  touch /commandhistory/.bash_history && \
  chown -R node /commandhistory

ENV DEVCONTAINER=true

# Create workspace and config directories
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# GIT delta (enhanced git diff) - conditional on INSTALL_SHELL_EXTRAS
ARG GIT_DELTA_VERSION=0.18.2
RUN if [ "$INSTALL_SHELL_EXTRAS" = "true" ]; then \
    ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"; \
  fi

# Domain allowlist - conditional based on ENABLE_FIREWALL
RUN if [ "$ENABLE_FIREWALL" = "true" ]; then \
    echo "Domain allowlist will be configured by init-firewall.sh"; \
  else \
    touch /etc/claude-allowed-domains.txt && \
    echo "Empty domain allowlist created (YOLO mode)"; \
  fi

# Download fzf shell integration files (not included in Debian package)
# Issue #110: Debian fzf package doesn't include shell integration scripts
# Must run as root to write to /usr/share/doc/fzf/examples/
RUN if [ "$INSTALL_SHELL_EXTRAS" = "true" ]; then \
    mkdir -p /usr/share/doc/fzf/examples && \
    wget -q -O /usr/share/doc/fzf/examples/key-bindings.zsh \
      https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh && \
    wget -q -O /usr/share/doc/fzf/examples/completion.zsh \
      https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh; \
  fi

USER node

# NPM global config
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# ZSH with Powerlevel10k - conditional on INSTALL_SHELL_EXTRAS
ARG ZSH_IN_DOCKER_VERSION=1.2.0
ENV SHELL=/bin/zsh

RUN if [ "$INSTALL_SHELL_EXTRAS" = "true" ]; then \
    sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
      -p git \
      -p fzf \
      -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
      -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
      -a "source /usr/share/doc/fzf/examples/completion.zsh" \
      -x; \
  fi

# Pre-download gitstatusd for powerlevel10k - conditional on INSTALL_SHELL_EXTRAS
ARG GITSTATUSD_VERSION=v1.5.4
RUN if [ "$INSTALL_SHELL_EXTRAS" = "true" ]; then \
    mkdir -p ~/.cache/gitstatus && \
    wget -qO- "https://github.com/romkatv/gitstatus/releases/download/${GITSTATUSD_VERSION}/gitstatusd-linux-x86_64.tar.gz" | \
    tar -xz -C ~/.cache/gitstatus; \
  fi

# Editor configuration
ENV EDITOR=nano
ENV VISUAL=nano

# Python uv environment
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV PATH="/workspace/.venv/bin:$PATH"

# PostgreSQL environment (connects to container service by default)
ENV PGHOST=postgres \
    PGUSER=sandboxxer_user \
    PGDATABASE=sandboxxer_dev

# Initialize uv project with core packages
RUN uv init --name workspace-env && \
    uv add --no-cache deepagents tavily-python requests

# Python dev tools - conditional on INSTALL_DEV_TOOLS
RUN if [ "$INSTALL_DEV_TOOLS" = "true" ]; then \
    uv add --no-cache pytest black flake8 mypy ipython; \
  fi

# Install Claude Code (always required)
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Core Node tools (always installed - package managers)
RUN npm install -g yarn pnpm

# Node dev tools - conditional on INSTALL_DEV_TOOLS
RUN if [ "$INSTALL_DEV_TOOLS" = "true" ]; then \
    npm install -g \
      typescript \
      ts-node \
      eslint \
      prettier \
      nodemon \
      @mermaid-js/mermaid-cli \
      puppeteer@24; \
  fi

# Python tools system-wide - conditional on INSTALL_DEV_TOOLS
ENV PATH="/home/node/.local/bin:$PATH"
RUN if [ "$INSTALL_DEV_TOOLS" = "true" ]; then \
    uv tool install ruff && \
    uv tool install poetry; \
  fi

# === LANGUAGE PARTIALS ===

# === AZURE TOOLING (inserted when deploy-to-azure selected) ===

# Firewall initialization script - conditional setup
# File is copied by setup commands (quickstart or yolo-vibe-maxxing)
COPY .devcontainer/init-firewall.s[h] /tmp/firewall/

USER root
RUN if [ "$ENABLE_FIREWALL" = "true" ]; then \
    # Verify firewall script exists when firewall is enabled
    if [ ! -f /tmp/firewall/init-firewall.sh ]; then \
      echo "ERROR: ENABLE_FIREWALL=true but init-firewall.sh not found" && exit 1; \
    fi && \
    cp /tmp/firewall/init-firewall.sh /usr/local/bin/ && \
    chmod +x /usr/local/bin/init-firewall.sh; \
  else \
    # Create no-op firewall script for YOLO mode
    printf '#!/bin/bash\necho "Firewall disabled (YOLO mode)"\nexit 0\n' > /usr/local/bin/init-firewall.sh && \
    chmod +x /usr/local/bin/init-firewall.sh; \
  fi && \
  # Sudoers entry needed for both modes (postStartCommand compatibility)
  echo "node ALL=(root) NOPASSWD: SETENV: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall && \
  rm -rf /tmp/firewall
USER node

# Set the default command
CMD ["/bin/zsh"]
