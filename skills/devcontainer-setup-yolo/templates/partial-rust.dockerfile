# === RUST LANGUAGE ADDITIONS ===
# REQUIRED: Add to base multi-stage sources section:
#   FROM rust:1.75-bookworm AS rust-source
# ============================================================================

USER root

# Copy Rust toolchain from official image (proxy-friendly)
# NOTE: Requires 'rust-source' stage in base Dockerfile
COPY --from=rust-source /usr/local/rustup /usr/local/rustup
COPY --from=rust-source /usr/local/cargo /usr/local/cargo

# Set Rust environment variables
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/home/node/.cargo \
    PATH=/usr/local/cargo/bin:/home/node/.cargo/bin:$PATH

# Create user cargo directory and set ownership
RUN mkdir -p /home/node/.cargo && \
    chown -R node:node /home/node/.cargo

USER node

# Rust development tools - conditional on INSTALL_DEV_TOOLS
# These require network access to crates.io
ARG INSTALL_RUST_TOOLS=${INSTALL_DEV_TOOLS:-true}
RUN if [ "$INSTALL_RUST_TOOLS" = "true" ]; then \
    rustup component add rustfmt clippy rust-src && \
    cargo install cargo-edit cargo-watch cargo-outdated; \
  fi

# === END RUST LANGUAGE ADDITIONS ===
