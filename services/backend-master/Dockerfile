# ── Stage 1: L’Architecte PHP - Build Artifacts ─────────────────────────────────────────
FROM php:8.1-apache AS l_architecte_php

# turns on Apaches rewrite engine
RUN a2enmod rewrite \
    && sed -ri 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
    # changes the global Apache config to allow per-directory overrides (.htaccess), to allow for
    # our rewrite rules to take effect

# Install system libs & PHP extensions for WP/Woo
# "apt-get update" refreshes the Debian package index
RUN apt-get update && apt-get install -y --no-install-recommends \
    # "apt-get install" bring in libraries needed to compile PHP extensions
    # libicu-dev for intl
    # libzip-dev for zip
    # libonig-dev for mbstring support via mysqli
        libicu-dev libzip-dev libonig-dev \
        autoconf g++ make \
    # "docker-php-ext-install" compiles and enables our required PHP modules
    && docker-php-ext-install intl pdo_mysql mysqli zip opcache \
    # allows us to use an argument variable to control the installation of the debugger tool
    # "rm -rf" remove build tools and package caches to slim down the layer
    && rm -rf /var/lib/apt/lists/*

ARG INSTALL_XDEBUG=false
    # only when passed down, otherwise in prod it will be omitted
    # We want it in a separate layer because otherwise it will make the entire previous re download
    # every single time
RUN if [ "$INSTALL_XDEBUG" = "true" ] ; then \
        pecl install xdebug && docker-php-ext-enable xdebug ; \
    fi \
    && apt-get purge -y --auto-remove autoconf g++ make

WORKDIR /var/www/html

# Install WP-CLI and download WordPress core
RUN curl -o wordpress.tar.gz https://wordpress.org/latest.tar.gz \
    && tar -xzf wordpress.tar.gz --strip-components=1 \
    && rm wordpress.tar.gz

# We lock in the dependencies to use docker caching ability
COPY composer.json ./
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer update --no-dev --optimize-autoloader \
    && rm /usr/local/bin/composer

COPY .htaccess wp-config.php ./

COPY wp-content ./wp-content

RUN mkdir -p wp-content/uploads \
    && chown -R www-data:www-data wp-content/uploads \
    && chmod -R 755 wp-content/uploads

# ── Stage 2: Le messager de Soie - Production Runtime ─────────────────────────────────────────
# The sole purpose of this second phase is to make the final container super lean by only copying
# the absolute required dependencies and libraries that are used.
FROM php:8.1-apache

# RUN a2enmod rewrite \
#     && sed -ri 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
COPY --from=l_architecte_php /etc/apache2/ /etc/apache2/

RUN apt-get update && apt-get install -y --no-install-recommends \
        g++ make autoconf \
        libicu-dev libonig-dev libzip-dev \
    && docker-php-ext-install intl pdo_mysql mysqli zip opcache \
    && apt-get purge -y --auto-remove g++ make autoconf libicu-dev libonig-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy the finished application
WORKDIR /var/www/html
COPY --from=l_architecte_php /var/www/html /var/www/html/

RUN chown -R www-data:www-data /var/www/html

# Final step: launch Apache quietly
CMD ["apache2-foreground"]