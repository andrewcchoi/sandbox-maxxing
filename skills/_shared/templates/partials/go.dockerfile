# ============================================================================
# Go Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects Go project type.
# Adds Go toolchain, linters, and development tools.
# ============================================================================

USER root

# Install Go 1.24 (architecture-aware, using wget for HTTP/1.1)
ARG GO_VERSION=1.24.10
RUN ARCH=$(dpkg --print-architecture) && \
    wget "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
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
