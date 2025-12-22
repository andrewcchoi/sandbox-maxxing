# === GO LANGUAGE ADDITIONS ===
# REQUIRED: Add to base multi-stage sources section:
#   FROM golang:1.22-bookworm AS go-source
# ============================================================================

USER root

# Copy Go toolchain from official image (proxy-friendly)
# NOTE: Requires 'go-source' stage in base Dockerfile
COPY --from=go-source /usr/local/go /usr/local/go

# Set Go environment variables
ENV GOROOT=/usr/local/go \
    GOPATH=/home/node/go \
    GOBIN=/home/node/go/bin \
    GO111MODULE=on \
    CGO_ENABLED=1
ENV PATH=$PATH:/usr/local/go/bin:/home/node/go/bin

# Create Go directories for non-root user
RUN mkdir -p /home/node/go/bin /home/node/go/pkg /home/node/go/src && \
    chown -R node:node /home/node/go

USER node

# Go development tools - conditional on INSTALL_DEV_TOOLS
# These require network access to proxy.golang.org
ARG INSTALL_GO_TOOLS=${INSTALL_DEV_TOOLS:-true}
RUN if [ "$INSTALL_GO_TOOLS" = "true" ]; then \
    go install golang.org/x/tools/gopls@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest; \
  fi

# === END GO LANGUAGE ADDITIONS ===
