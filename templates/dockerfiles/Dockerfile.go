# Go 1.22 Development Environment
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
RUN curl -fsSL https://claude.ai/install.sh | sh

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
