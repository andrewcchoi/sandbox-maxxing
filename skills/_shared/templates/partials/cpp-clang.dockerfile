# ============================================================================
# C++ (Clang) Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects C++ (Clang) project type.
# Uses official/community Docker images where possible for proxy-friendliness.
# Adds Clang 17 toolchain, CMake, Ninja, and vcpkg package manager.
# ============================================================================

USER root

# Copy Clang from community-maintained silkeh/clang image (proxy-friendly)
# This avoids downloading from apt.llvm.org during build
COPY --from=clang-source /usr/bin/clang* /usr/bin/
COPY --from=clang-source /usr/bin/lldb* /usr/bin/
COPY --from=clang-source /usr/bin/lld* /usr/bin/
COPY --from=clang-source /usr/lib/llvm-17 /usr/lib/llvm-17
COPY --from=clang-source /usr/lib/x86_64-linux-gnu/libLLVM-17.so* /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true

# Install build tools via APT (proxy-friendly)
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    ninja-build \
    git \
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
# NOTE: This requires GitHub access during build (no proxy-friendly alternative exists)
# If behind strict proxy, consider pre-caching vcpkg or skipping this step
RUN git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg && \
    /opt/vcpkg/bootstrap-vcpkg.sh && \
    ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg && \
    chown -R node:node /opt/vcpkg

ENV VCPKG_ROOT=/opt/vcpkg

USER node
