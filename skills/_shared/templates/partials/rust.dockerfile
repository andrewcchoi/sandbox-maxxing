# ============================================================================
# Rust Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects Rust project type.
# Adds Rust toolchain, Cargo, and development tools.
# ============================================================================

USER node

# Install Rust via rustup (use --http1.1 to avoid HTTP/2 stream errors)
RUN curl --http1.1 --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Rust environment
ENV PATH=/home/node/.cargo/bin:$PATH

# Install common Rust development tools
RUN rustup component add rustfmt clippy rust-analyzer && \
    cargo install cargo-watch cargo-edit

# Cargo cache location
ENV CARGO_HOME=/home/node/.cargo
