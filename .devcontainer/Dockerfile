# Generated using sandboxxer plugin
# Development container for plugin development
# Lightweight Node.js + Python environment with CLI tools

# Stage 1: Get Python + uv from official Astral image
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS python-uv-source

# Stage 2: Main build
FROM node:20-bookworm-slim

# Timezone configuration
ARG TZ=America/Los_Angeles
ENV TZ="$TZ"


# Install system packages including iptables for firewall
RUN apt-get update && apt-get install -y --no-install-recommends \
  # Core utilities
  git vim nano less procps sudo unzip wget curl ca-certificates gnupg gnupg2 \
  openssh-client \
  # JSON processing and manual pages
  jq man-db uuid-runtime \
  # Shell and CLI enhancements
  zsh fzf \
  # GitHub CLI
  gh \
  build-essential \
  # Network security tools (firewall)
  iptables ipset iproute2 dnsutils \
  # Timezone data
  tzdata \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Python 3.12 binaries and shared library
COPY --from=python-uv-source /usr/local/bin/python3* /usr/local/bin/
COPY --from=python-uv-source /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=python-uv-source /usr/local/lib/libpython3.12.so* /usr/local/lib/
COPY --from=python-uv-source /usr/local/bin/pip* /usr/local/bin/
RUN ln -sf /usr/local/bin/python3.12 /usr/local/bin/python && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3 && \
    ldconfig

# Copy uv and uvx binaries
COPY --from=python-uv-source /usr/local/bin/uv /usr/local/bin/
COPY --from=python-uv-source /usr/local/bin/uvx /usr/local/bin/

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

# GIT delta (enhanced git diff)
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Copy domain allowlist and extract all domains (Issue #32)
COPY skills/_shared/templates/data/allowable-domains.json /tmp/allowable-domains.json
RUN jq -r '[.categories | to_entries[] | .value | ((.domains // []), (.wildcard_domains // []), (.sub_categories // {} | to_entries[] | .value | (.domains // []), (.wildcard_domains // [])))] | flatten | unique | .[]' \
    /tmp/allowable-domains.json > /etc/claude-allowed-domains.txt && \
    rm /tmp/allowable-domains.json

# Download fzf shell integration files (not included in Debian package)
# Issue #110: Debian fzf package doesn't include shell integration scripts
# Must run as root to write to /usr/share/doc/fzf/examples/
RUN mkdir -p /usr/share/doc/fzf/examples && \
    wget -O /usr/share/doc/fzf/examples/key-bindings.zsh \
      https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh && \
    wget -O /usr/share/doc/fzf/examples/completion.zsh \
      https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh

USER node

# NPM global config
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# ZSH with Powerlevel10k
ARG ZSH_IN_DOCKER_VERSION=1.2.0
ENV SHELL=/bin/zsh

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git \
  -p fzf \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -x

# Pre-download gitstatusd for powerlevel10k (avoid runtime download failure)
ARG GITSTATUSD_VERSION=v1.5.4
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64) GITSTATUS_ARCH="x86_64" ;; \
      aarch64) GITSTATUS_ARCH="aarch64" ;; \
      armv7l) GITSTATUS_ARCH="armv7l" ;; \
      *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
    esac && \
    mkdir -p ~/.cache/gitstatus && \
    wget -O- "https://github.com/romkatv/gitstatus/releases/download/${GITSTATUSD_VERSION}/gitstatusd-linux-${GITSTATUS_ARCH}.tar.gz" | \
    tar -xz -C ~/.cache/gitstatus

# Editor configuration
ENV EDITOR=nano
ENV VISUAL=nano

# Python uv environment
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV PATH="/workspace/.venv/bin:$PATH"

# Initialize uv project and install Python packages to .venv
# Note: uv init creates a new pyproject.toml. If your workspace has an existing
# pyproject.toml, it will be overwritten. Consider using 'uv sync' instead.
RUN uv init --name workspace-env && \
    uv add --no-cache \
      deepagents \
      tavily-python \
      pytest \
      black \
      flake8 \
      mypy \
      ipython \
      requests

# Install Claude Code
# Security note: Piping curl to bash executes remote code directly.
# This is the official installation method from claude.ai. Review the script
# at https://claude.ai/install.sh before use in production environments.
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN npm install -g \
  typescript \
  ts-node \
  eslint \
  prettier \
  nodemon \
  yarn \
  pnpm \
  @mermaid-js/mermaid-cli \
  puppeteer@24

# Install Python tools system-wide (available outside venv)
ENV PATH="/home/node/.local/bin:$PATH"
RUN uv tool install ruff && \
    uv tool install poetry

# Firewall initialization script
COPY .devcontainer/init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: SETENV: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall

# Allow node user to set up SSH directory with proper permissions
RUN echo "node ALL=(root) NOPASSWD: /bin/mkdir -p /home/node/.ssh, /bin/chmod 700 /home/node/.ssh, /bin/chown -R node\\:node /home/node/.ssh" > /etc/sudoers.d/node-ssh && \
  chmod 0440 /etc/sudoers.d/node-ssh

USER node

# Set the default command
CMD ["/bin/zsh"]
