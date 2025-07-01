# ── Stage 1: L’Architecte PHP ─────────────────────────────────────────
FROM php:8.1-fpm-alpine AS l_architecte_php

# Install system libs & PHP extensions for WP/Woo
RUN apk add --no-cache \
        curl \
        icu-dev \
        libzip-dev \
        oniguruma-dev \
    && docker-php-ext-install \
        intl \
        pdo_mysql \
        zip \
        opcache \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug

WORKDIR /var/www/html

# We lock in the dependencies to use docker caching ability
COPY composer.json composer.lock ./
RUN curl -sS https://getcomposer.org/installer | php -- --installer-dir=/usr/bin --filename=composer \
    && composer install --no-dev --optimize-autoloader

# We bring WordPress core & our themes/plugins
COPY wp-content ./wp-content
COPY .htaccess wp-config.php ./

# Ensuring correct permissions for persistence
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html



# ── Stage 2: Le messager de Soie ─────────────────────────────────────────
FROM php:8.1-fpm-alpine AS le_messager_de_soie

WORKDIR /var/www/html

# Copy built application from architect stage
COPY --from=l_architecte_php /var/www/html /var/www/html

# Mount wp-content as a volumen for persistence
VOLUME ["/var/www/html/wp-content"]

#Expose PHP-FPM port for NGINX or sidecar proxy
EXPOSE 9000

# Final step: launch PHP-FPM quietly
CMD ["php-fpm"]