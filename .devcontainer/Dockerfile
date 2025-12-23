# Generated using sandboxxer-maxxing plugin Intermediate mode
# Development container for plugin development with services
# Includes PostgreSQL, Redis, RabbitMQ for testing examples

# Stage 1: Get Python + uv from official Astral image
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS python-uv-source

# Stage 2: Main build
FROM node:20-bookworm-slim

# Timezeone configuration
ARG TZ=America/Los_Angeles
ENV TZ="$TZ"


# Install system packages including iptables for firewall
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
  # Network security tools (firewall)
  iptables ipset iproute2 dnsutils \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

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

# GIT delta (enhanced git diff)
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Copy domain allowlist and extract all domains (Issue #32)
COPY skills/_shared/data/allowable-domains.json /tmp/allowable-domains.json
RUN jq -r '[.categories | to_entries[] | .value | ((.domains // []), (.wildcard_domains // []), (.sub_categories // {} | to_entries[] | .value | (.domains // []), (.wildcard_domains // [])))] | flatten | unique | .[]' \
    /tmp/allowable-domains.json > /etc/claude-allowed-domains.txt && \
    rm /tmp/allowable-domains.json

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
RUN mkdir -p ~/.cache/gitstatus && \
    wget -qO- "https://github.com/romkatv/gitstatus/releases/download/${GITSTATUSD_VERSION}/gitstatusd-linux-x86_64.tar.gz" | \
    tar -xz -C ~/.cache/gitstatus

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

# Initialize uv project and install Python packages to .venv
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
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
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

# The langgraph.json file has the assistant ID as the key:
#   "graphs": {
#     "research": "./agent.py:agent"
#   },

# export ANTHROPIC_API_KEY=your_anthropic_api_key_here  # Required for Claude model
# export GOOGLE_API_KEY=your_google_api_key_here        # Required for Gemini model ([get one here](https://ai.google.dev/gemini-api/docs))
# export TAVILY_API_KEY=your_tavily_api_key_here        # Required for web search ([get one here](https://www.tavily.com/)) with a generous free tier
# export LANGSMITH_API_KEY=your_langsmith_api_key_here  # [LangSmith API key](https://smith.langchain.com/settings) (free to sign up)
# export NEXT_PUBLIC_LANGSMITH_API_KEY="lsv2_xxxx"

# $ git clone https://github.com/langchain-ai/deepagents-quickstarts.git
# $ cd deepagents-quickstarts/deep_research
# $ uv build
# $ langgraph dev

# deep-agents-ui configuration 
# env.local settings
# NEXT_PUBLIC_DEPLOYMENT_URL="http://127.0.0.1:2024"
# NEXT_PUBLIC_AGENT_ID="research"

# $ git clone https://github.com/langchain-ai/deep-agents-ui.git
# $ cd deep-agents-ui
# $ yarn install
# $ yarn dev

# ╦  ┌─┐┌┐┌┌─┐╔═╗┬─┐┌─┐┌─┐┬ ┬
# ║  ├─┤││││ ┬║ ╦├┬┘├─┤├─┘├─┤
# ╩═╝┴ ┴┘└┘└─┘╚═╝┴└─┴ ┴┴  ┴ ┴

# - 🚀 API: http://127.0.0.1:2024
# - 🎨 Studio UI: https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
# - 📚 API Docs: http://127.0.0.1:2024/docs
# - ⚙️ Deepagents UI: http://localhost:3000
# ...

# Firewall initialization script
COPY .devcontainer/init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
USER node

# Set the default command
CMD ["/bin/zsh"]