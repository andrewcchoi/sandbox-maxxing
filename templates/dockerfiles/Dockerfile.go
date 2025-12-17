# ============================================================================
# Stage 1: Get Node.js from official image (Issue #29)
# ============================================================================
FROM node:20-slim AS node-source

# ============================================================================
# Stage 2: Go Development Environment
# ============================================================================
FROM golang:1.22-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    wget \
    sudo \
    build-essential \
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

# Install Go development tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

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

# Default command
CMD ["/bin/bash"]
