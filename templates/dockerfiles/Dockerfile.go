# ============================================================================
# Stage 1: Get Node.js from official image (Issue #29)
# ============================================================================
FROM node:20-slim AS node-source

# ============================================================================
# Stage 2: Get Python + uv from official Astral image
# ============================================================================
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS python-uv-source

# ============================================================================
# Stage 3: Go Development Environment
# ============================================================================
FROM golang:1.22-bookworm

# Install system dependencies (mandatory base packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    git vim nano less procps sudo unzip wget curl ca-certificates gnupg gnupg2 \
    # JSON processing and manual pages
    jq man-db \
    # Shell and CLI enhancements
    zsh fzf \
    # GitHub CLI
    gh \
    # Build tools
    build-essential \
    # Network security tools (firewall)
    iptables ipset iproute2 dnsutils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Node.js from official image (Issue #29 - avoids NodeSource SSL issues)
COPY --from=node-source /usr/local/bin/node /usr/local/bin/
COPY --from=node-source /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Copy Python + uv from Astral image
COPY --from=python-uv-source /usr/local/bin/python3* /usr/local/bin/
COPY --from=python-uv-source /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=python-uv-source /usr/local/bin/pip* /usr/local/bin/
COPY --from=python-uv-source /usr/local/bin/uv /usr/local/bin/
COPY --from=python-uv-source /usr/local/bin/uvx /usr/local/bin/
RUN ln -sf /usr/local/bin/python3.12 /usr/local/bin/python && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3

# Create non-root user with sudo access
RUN groupadd -g 1000 node && \
    useradd -m -u 1000 -g 1000 -s /bin/bash node && \
    echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Go development tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Install Mermaid CLI (Diagram Generation)
RUN npm install -g @mermaid-js/mermaid-cli

# Install DeepAgents + Tavily (AI/LLM Tools)
RUN uv pip install --system deepagents tavily-python

# Install git-delta (enhanced git diff)
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Set Go environment variables
ENV GOPATH=/home/node/go \
    GOBIN=/home/node/go/bin \
    PATH=$PATH:/home/node/go/bin \
    GO111MODULE=on \
    CGO_ENABLED=1

# Create Go directories for non-root user
RUN mkdir -p /home/node/go/bin /home/node/go/pkg /home/node/go/src && \
    chown -R node:node /home/node/go

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER node

# Install ZSH with Powerlevel10k (as non-root user)
ARG ZSH_IN_DOCKER_VERSION=1.2.0
ENV SHELL=/bin/zsh
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
    -p git -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -x

# Default command
CMD ["/bin/zsh"]
