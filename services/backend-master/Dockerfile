# ── Stage 1: L’Architecte PHP - Build Artifacts ─────────────────────────────────────────
FROM php:8.1-apache AS l_architecte_php

# turns on Apaches rewrite engine
RUN a2enmod rewrite \
    && sed -ri 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
    # changes the global Apache config to allow per-directory overrides (.htaccess), to allow for
    # our rewrite rules to take effect

# Install system libs & PHP extensions for WP/Woo
# "apt-get update" refreshes the Debian package index
RUN apt-get update \
    # "apt-get install" bring in libraries needed to compile PHP extensions
    # libicu-dev for intl
    # libzip-dev for zip
    # libonig-dev for mbstring support via mysqli
    && apt-get install -y --no-install-recommends \
        curl libicu-dev libzip-dev libonig-dev autoconf g++ make \
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

# Re-install the same extensions for runtime
RUN a2enmod rewrite \
    && sed -ri 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libicu-dev libzip-dev libonig-dev default-mysql-client \
    && docker-php-ext-install intl pdo_mysql mysqli zip opcache \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI for runtime use
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html
COPY --from=l_architecte_php /var/www/html /var/www/html

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# Ensuring correct single-layer permissions for persistence
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/wp-content/uploads

#Expose port for Apache
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost/wp-json/ || exit 1

# Final step: launch Apache quietly
CMD ["apache2-foreground"]