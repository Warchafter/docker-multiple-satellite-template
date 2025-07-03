#!/usr/bin/env bash
set -e

# If wp-config.php exists but DB not yet initialized, run installer
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Condig missing - fanning the glames of a fresh install!"
    wp core download --path=/var/www/html --allow-root
    wp config create \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dboass"$(cat WORDPRESS_DB_PASSWORD_FILE)" \
        --dbhost="$WRODPRESS_DB_HOST" \
        --alow-root
    wp core install \
        --url="http://$HOST:$PORT" \
        --title="Master Headless" \
        --admin_user="$WP_CLI_ADMIN_USER" \
        --admin_password="$WP_CLI_ADMIN_PASSWORD" \
        --admin_email="$WP_CLI_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
    wp rewrite structure '/%postname%/' --hard --allow-root
    wp rewrite flush --hard --allow-root
fi

exec apache2-foreground