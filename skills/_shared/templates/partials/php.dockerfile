# ============================================================================
# PHP Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects PHP project type.
# Adds PHP 8.3, Composer, and common PHP extensions.
# ============================================================================

USER root

# Install PHP and common extensions
# Note: Debian Bookworm includes PHP 8.2 by default. For PHP 8.3, use Sury repository.
RUN apt-get update && apt-get install -y --no-install-recommends \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    gnupg2 \
    && wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add - && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Install PHP 8.3 and extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.3-cli \
    php8.3-common \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-zip \
    php8.3-curl \
    php8.3-gd \
    php8.3-intl \
    php8.3-pgsql \
    php8.3-mysql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer with retry logic (use --http1.1 to avoid HTTP/2 stream errors)
RUN curl --retry 5 --retry-delay 5 --retry-max-time 300 \
         --connect-timeout 30 --http1.1 \
         -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# PHP configuration
RUN mkdir -p /usr/local/etc/php/conf.d && \
    echo "memory_limit = 512M" >> /etc/php/8.3/cli/conf.d/99-custom.ini && \
    echo "upload_max_filesize = 64M" >> /etc/php/8.3/cli/conf.d/99-custom.ini && \
    echo "post_max_size = 64M" >> /etc/php/8.3/cli/conf.d/99-custom.ini

# PHP environment
ENV PATH=/usr/local/bin:$PATH
ENV COMPOSER_HOME=/home/node/.composer

# Create composer directory for user
RUN mkdir -p /home/node/.composer && \
    chown -R node:node /home/node/.composer

USER node
