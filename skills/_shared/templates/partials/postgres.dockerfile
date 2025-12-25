# ============================================================================
# PostgreSQL Development Tools Partial
# ============================================================================
# Appended to base.dockerfile when user selects PostgreSQL Dev project type.
# Adds PostgreSQL client tools, development libraries, and pgvector extension.
# ============================================================================

USER root

# Install PostgreSQL development tools and libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    postgresql-server-dev-all \
    libpq-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Attempt to install pgvector extension (if available in repos)
# Falls back gracefully if not available - can be compiled manually later
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-16-pgvector \
    && apt-get clean && rm -rf /var/lib/apt/lists/* || \
    echo "pgvector package not available - install manually if needed"

# Note: PGHOST, PGUSER, PGDATABASE are already defined in base.dockerfile
# No need to redefine here to avoid conflicts

USER node
