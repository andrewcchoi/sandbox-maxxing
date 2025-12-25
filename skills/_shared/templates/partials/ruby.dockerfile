# ============================================================================
# Ruby Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects Ruby project type.
# Adds Ruby 3.3, bundler, and development tools.
# ============================================================================

USER root

# Install Ruby 3.3 and development dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby-full \
    ruby-dev \
    build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install bundler and common gems
RUN gem install bundler rake rspec rubocop solargraph

# Ruby environment
ENV GEM_HOME=/home/node/.gem
ENV PATH=$GEM_HOME/bin:$PATH

USER node

# Create gem directory
RUN mkdir -p $GEM_HOME
