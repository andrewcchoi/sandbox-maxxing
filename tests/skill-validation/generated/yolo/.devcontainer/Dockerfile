# YOLO MODE CONFIGURATION
# Base image: python:3.12-slim (official)
# Firewall: Optional (not enforced)
# Full customization enabled
# Generated: 2025-12-20

FROM python:3.12-slim

# Install ALL development tools (YOLO mode - no restrictions)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    build-essential \
    postgresql-client \
    mysql-client \
    redis-tools \
    sqlite3 \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    sudo \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with full sudo access
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install Claude Code CLI (latest)
RUN curl -fsSL https://cli.claude.ai/install.sh | bash || true

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER $USERNAME

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python --version || exit 1
