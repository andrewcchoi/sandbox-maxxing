# === C++ (CLANG) LANGUAGE ADDITIONS ===
# Uses LLVM's official apt repository for latest Clang (proxy-friendly via apt)
# ============================================================================

USER root

# Add LLVM apt repository for latest Clang toolchain
# The GPG key download is one-time during build
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-17 main" \
    > /etc/apt/sources.list.d/llvm.list

# Install Clang 17 toolchain and build tools (via apt - proxy-friendly)
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang-17 \
    clang-format-17 \
    clang-tidy-17 \
    lldb-17 \
    lld-17 \
    cmake \
    ninja-build \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create version-agnostic symlinks
RUN ln -sf /usr/bin/clang-17 /usr/bin/clang && \
    ln -sf /usr/bin/clang++-17 /usr/bin/clang++ && \
    ln -sf /usr/bin/clang-format-17 /usr/bin/clang-format && \
    ln -sf /usr/bin/clang-tidy-17 /usr/bin/clang-tidy && \
    ln -sf /usr/bin/lldb-17 /usr/bin/lldb

# Set C++ environment variables for Clang
ENV CXX=clang++ \
    CC=clang

# vcpkg installation - conditional on INSTALL_DEV_TOOLS
# Requires network access to github.com
ARG INSTALL_CPP_TOOLS=${INSTALL_DEV_TOOLS:-true}
RUN if [ "$INSTALL_CPP_TOOLS" = "true" ]; then \
    git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg && \
    /opt/vcpkg/bootstrap-vcpkg.sh && \
    ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg && \
    chown -R node:node /opt/vcpkg; \
  fi
ENV VCPKG_ROOT=/opt/vcpkg

USER node

# === END C++ (CLANG) LANGUAGE ADDITIONS ===
