# ============================================================================
# Rust Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects Rust project type.
# Uses official rust image for reliable installation.
# ============================================================================

USER root

# Copy Rust toolchain from official image (avoids CDN download issues)
COPY --from=rust-source /usr/local/rustup /usr/local/rustup
COPY --from=rust-source /usr/local/cargo /usr/local/cargo

# Rust environment variables
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

# Make cargo accessible to node user
RUN chown -R node:node /usr/local/rustup /usr/local/cargo

USER node

# Install common Rust development tools
RUN rustup component add rustfmt clippy rust-analyzer && \
    cargo install cargo-watch cargo-edit
