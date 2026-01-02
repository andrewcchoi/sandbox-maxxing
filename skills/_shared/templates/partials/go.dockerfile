# ============================================================================
# Go Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects Go project type.
# Adds Go toolchain, linters, and development tools.
# ============================================================================

USER root

# Install latest stable Go (architecture-aware, dynamically discovered from go.dev API)
RUN ARCH=$(dpkg --print-architecture) && \
    GO_VERSION=$(curl -fsSL --http1.1 'https://go.dev/dl/?mode=json' | \
        grep -o '"version": *"go[0-9.]*"' | head -1 | \
        sed 's/.*"go\([0-9.]*\)".*/\1/') && \
    echo "Installing Go ${GO_VERSION} for ${ARCH}" && \
    curl -fsSL --http1.1 -o "go${GO_VERSION}.linux-${ARCH}.tar.gz" \
        "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
    rm "go${GO_VERSION}.linux-${ARCH}.tar.gz"

# Go environment variables
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/node/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# Create GOPATH directory
RUN mkdir -p $GOPATH && chown -R node:node $GOPATH

USER node

# Install Go development tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install golang.org/x/lint/golint@latest

# Go module cache location
ENV GOCACHE=/home/node/.cache/go-build
RUN mkdir -p $GOCACHE
