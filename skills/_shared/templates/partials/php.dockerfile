# ============================================================================
# PHP Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects PHP project type.
# Uses official PHP Docker image via multi-stage build for proxy-friendliness.
# Includes PHP 8.3, Composer, and common PHP extensions.
# ============================================================================

USER root

# Copy PHP from official image (proxy-friendly - no external downloads)
COPY --from=php-source /usr/local/bin/php /usr/local/bin/php
COPY --from=php-source /usr/local/etc/php /usr/local/etc/php
COPY --from=php-source /usr/local/include/php /usr/local/include/php
COPY --from=php-source /usr/local/lib/php /usr/local/lib/php
COPY --from=php-source /usr/local/php /usr/local/php

# Install PHP dependencies and extensions available via APT
RUN apt-get update && apt-get install -y --no-install-recommends \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    libpng-dev \
    libicu-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer from official Composer image (proxy-friendly)
COPY --from=composer-source /usr/bin/composer /usr/local/bin/composer

# PHP configuration
RUN mkdir -p /usr/local/etc/php/conf.d && \
    echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/99-custom.ini && \
    echo "upload_max_filesize = 64M" >> /usr/local/etc/php/conf.d/99-custom.ini && \
    echo "post_max_size = 64M" >> /usr/local/etc/php/conf.d/99-custom.ini

# PHP environment
ENV PATH=/usr/local/bin:$PATH
ENV COMPOSER_HOME=/home/node/.composer

# Create composer directory for user
RUN mkdir -p /home/node/.composer && \
    chown -R node:node /home/node/.composer

USER node
