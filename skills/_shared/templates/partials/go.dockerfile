# ============================================================================
# Go Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects Go project type.
# Uses official golang image for reliable installation.
# ============================================================================

USER root

# Copy Go toolchain from official image (avoids CDN download issues)
COPY --from=go-source /usr/local/go /usr/local/go

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
    go install honnef.co/go/tools/cmd/staticcheck@latest

# Go module cache location
ENV GOCACHE=/home/node/.cache/go-build
RUN mkdir -p $GOCACHE
