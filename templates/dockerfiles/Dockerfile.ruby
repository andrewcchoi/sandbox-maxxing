# Ruby 3.3 Development Environment
FROM ruby:3.3-slim-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    wget \
    sudo \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with sudo access
RUN groupadd -g 1000 node && \
    useradd -m -u 1000 -g 1000 -s /bin/bash node && \
    echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install bundler and common gems
RUN gem update --system && \
    gem install bundler && \
    gem install rake rspec rubocop

# Configure gem installation for user
RUN mkdir -p /home/node/.gem && \
    chown -R node:node /home/node/.gem

# Install Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | sh

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER node

# Configure gem home for non-root user
ENV GEM_HOME=/home/node/.gem \
    PATH=/home/node/.gem/bin:$PATH

# Default command
CMD ["/bin/bash"]
