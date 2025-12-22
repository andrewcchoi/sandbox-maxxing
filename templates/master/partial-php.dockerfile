# === PHP LANGUAGE ADDITIONS ===
# REQUIRED: Add to base multi-stage sources section:
#   FROM php:8.3-cli-bookworm AS php-source
#   FROM composer:2 AS composer-source
# ============================================================================

USER root

# Copy PHP from official image (proxy-friendly)
# NOTE: Requires 'php-source' stage in base Dockerfile
COPY --from=php-source /usr/local/bin/php /usr/local/bin/
COPY --from=php-source /usr/local/lib/php /usr/local/lib/php
COPY --from=php-source /usr/local/etc/php /usr/local/etc/php

# Copy Composer from official image (proxy-friendly)
# NOTE: Requires 'composer-source' stage in base Dockerfile
COPY --from=composer-source /usr/bin/composer /usr/local/bin/composer

# Install PHP extension dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev \
    libpng-dev \
    libicu-dev \
    libpq-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure PHP
RUN mkdir -p /usr/local/etc/php/conf.d && \
    echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/99-custom.ini && \
    echo "upload_max_filesize = 64M" >> /usr/local/etc/php/conf.d/99-custom.ini && \
    echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/99-custom.ini

# Set PHP environment
ENV PATH=/usr/local/bin:$PATH \
    COMPOSER_HOME=/home/node/.composer

# Create composer directory for user
RUN mkdir -p /home/node/.composer && \
    chown -R node:node /home/node/.composer

USER node

# === END PHP LANGUAGE ADDITIONS ===
