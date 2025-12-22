# === RUBY LANGUAGE ADDITIONS ===
# REQUIRED: Add to base multi-stage sources section:
#   FROM ruby:3.3-bookworm AS ruby-source
# ============================================================================

USER root

# Copy Ruby from official image (proxy-friendly)
# NOTE: Requires 'ruby-source' stage in base Dockerfile
COPY --from=ruby-source /usr/local/bin/ruby /usr/local/bin/
COPY --from=ruby-source /usr/local/bin/gem /usr/local/bin/
COPY --from=ruby-source /usr/local/bin/bundle /usr/local/bin/
COPY --from=ruby-source /usr/local/bin/bundler /usr/local/bin/
COPY --from=ruby-source /usr/local/lib/ruby /usr/local/lib/ruby
COPY --from=ruby-source /usr/local/include/ruby* /usr/local/include/

# Install ruby build dependencies (needed for native gems)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libyaml-dev libffi-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure gem installation for user
RUN mkdir -p /home/node/.gem && \
    chown -R node:node /home/node/.gem

# Set Ruby environment variables
ENV GEM_HOME=/home/node/.gem \
    PATH=/home/node/.gem/bin:/usr/local/bin:$PATH

USER node

# Ruby development tools - conditional on INSTALL_DEV_TOOLS
# These require network access to rubygems.org
ARG INSTALL_RUBY_TOOLS=${INSTALL_DEV_TOOLS:-true}
RUN if [ "$INSTALL_RUBY_TOOLS" = "true" ]; then \
    gem install rake rspec rubocop; \
  fi

# === END RUBY LANGUAGE ADDITIONS ===
