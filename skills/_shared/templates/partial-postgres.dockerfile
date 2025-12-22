# === POSTGRESQL DEVELOPMENT ADDITIONS ===
USER root

# Install PostgreSQL development tools and pgvector dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-server-dev-all \
    libpq-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install pgvector development libraries (if available in repo)
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-16-pgvector \
    && apt-get clean && rm -rf /var/lib/apt/lists/* || \
    echo "pgvector package not available, will need manual installation"

# Set PostgreSQL environment variables (for connecting to external DB)
ENV PGHOST=postgres \
    PGUSER=sandboxxer_user \
    PGDATABASE=sandboxxer_dev

USER node

# === END POSTGRESQL DEVELOPMENT ADDITIONS ===
