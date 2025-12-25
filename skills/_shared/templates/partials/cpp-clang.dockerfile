# ============================================================================
# C++ (Clang) Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects C++ (Clang) project type.
# Adds Clang 17 toolchain, CMake, Ninja, and vcpkg package manager.
# ============================================================================

USER root

# Add LLVM apt repository for latest Clang toolchain
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-17 main" \
    > /etc/apt/sources.list.d/llvm.list

# Install Clang 17 toolchain and build tools
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

# C++ environment variables
ENV CXX=clang++
ENV CC=clang

# Install vcpkg package manager
RUN git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg && \
    /opt/vcpkg/bootstrap-vcpkg.sh && \
    ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg && \
    chown -R node:node /opt/vcpkg

ENV VCPKG_ROOT=/opt/vcpkg

USER node
