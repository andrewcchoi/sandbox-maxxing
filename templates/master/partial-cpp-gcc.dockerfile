# === C++ (GCC) LANGUAGE ADDITIONS ===
# Uses apt packages for GCC toolchain (proxy-friendly)
# ============================================================================

USER root

# Install GCC toolchain and build tools (via apt - proxy-friendly)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    gdb \
    cmake \
    ninja-build \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set C++ environment variables
ENV CXX=g++ \
    CC=gcc

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

# === END C++ (GCC) LANGUAGE ADDITIONS ===
