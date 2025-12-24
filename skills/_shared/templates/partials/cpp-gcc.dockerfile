# ============================================================================
# C++ (GCC) Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects C++ (GCC) project type.
# Adds GCC toolchain, CMake, Ninja, and vcpkg package manager.
# ============================================================================

USER root

# Install GCC toolchain and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    gdb \
    cmake \
    ninja-build \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# C++ environment variables
ENV CXX=g++
ENV CC=gcc

# Install vcpkg package manager
RUN git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg && \
    /opt/vcpkg/bootstrap-vcpkg.sh && \
    ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg && \
    chown -R node:node /opt/vcpkg

ENV VCPKG_ROOT=/opt/vcpkg

USER node
