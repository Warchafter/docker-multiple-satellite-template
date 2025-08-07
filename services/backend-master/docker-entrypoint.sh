#!/usr/bin/env bash
set -e

# Wait for the DB to accept connections
until mysqladmin ping -h"${WORDPRESS_DB_HOST}" -P"${WORDPRESS_DB_PORT}" -u"${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" --silent; do
    echo "Waiting on ${WORDPRESS_DB_HOST}:${WORDPRESS_DB_PORT}..."
    sleep 3
done

echo "Database connection successful!"

# Function to safely read secrets with fallbacks
read_secret() {
    local secret_file="/run/secrets/$1"
    local fallback="$2"
    
    if [[ -f "$secret_file" ]]; then
        cat "$secret_file" | tr -d '\n\r'
    else
        echo "Warning: Secret file $secret_file not found, using fallback" >&2
        echo "$fallback"
    fi
}

# Read WordPress admin credentials from secrets with fallbacks
WP_ADMIN_USER=$(read_secret "wp_cli_user" "admin")
WP_ADMIN_PASS=$(read_secret "wp_cli_pass" "admin123")
WP_ADMIN_EMAIL=$(read_secret "wp_cli_email" "admin@example.com")

echo "Using WordPress admin credentials:"
echo "  Username: $WP_ADMIN_USER"
echo "  Email: $WP_ADMIN_EMAIL"
echo "  Password: [hidden]"

# Check if WordPress is installed in database
if ! wp core is-installed --allow-root --path=/var/www/html 2>/dev/null; then
    echo "WordPress not found in database. Installing..."
    wp core install \
        --url="http://localhost:9001" \
        --title="Master Headless WordPress" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root \
        --path=/var/www/html
    echo "WordPress installed successfully!"
    echo "Admin credentials: $WP_ADMIN_USER / [password from secrets]"
else
    echo "WordPress already installed in database."
    
    # Check if the admin user from secrets exists, if not create it
    if ! wp user get "$WP_ADMIN_USER" --allow-root --path=/var/www/html 2>/dev/null; then
        echo "Creating admin user '$WP_ADMIN_USER' from secrets..."
        wp user create "$WP_ADMIN_USER" "$WP_ADMIN_EMAIL" \
            --role=administrator \
            --user_pass="$WP_ADMIN_PASS" \
            --allow-root \
            --path=/var/www/html
        echo "Admin user '$WP_ADMIN_USER' created successfully!"
    else
        echo "Admin user '$WP_ADMIN_USER' already exists."
        # Update password and email to match secrets
        wp user update "$WP_ADMIN_USER" \
            --user_pass="$WP_ADMIN_PASS" \
            --user_email="$WP_ADMIN_EMAIL" \
            --allow-root \
            --path=/var/www/html
        echo "Admin user '$WP_ADMIN_USER' updated with current secrets."
    fi
fi

# Install WooCommerce
echo "Checking WooCommerce..."
if ! wp plugin is-installed woocommerce --allow-root --path=/var/www/html; then
    echo "Installing WooCommerce..."
    wp plugin install woocommerce --activate --allow-root --path=/var/www/html
    # wp plugin install jwt-auth --activate --allow-root --path=/var/www/html
else
    echo "WooCommerce already installed. Ensuring it's activated..."
    wp plugin activate woocommerce --allow-root --path=/var/www/html
    # wp plugin activate jwt-auth --allow-root --path=/var/www/html
    
    # Check for updates
    if wp plugin update woocommerce --dry-run --allow-root --path=/var/www/html 2>/dev/null | grep -q "Available"; then
        echo "Updating WooCommerce to latest version..."
        wp plugin update woocommerce --allow-root --path=/var/www/html
    else
        echo "WooCommerce is already up to date."
    fi

    # if wp plugin update jwt-auth --dry-run --allow-root --path=/var/www/html 2>/dev/null | grep -q "Available"; then
    #     echo "Updating JWT Authentication to latest version..."
    #     wp plugin update jwt-auth --allow-root --path=/var/www/html
    # else
    #     echo "JWT Authentication is already up to date."
    # fi
fi

if [ ! -f /var/www/html/.bootstrapped ]; then
    wp rewrite structure '/%postname%' --hard --allow-root --path=/var/www/html
    wp rewrite flush --hard --allow-root --path=/var/www/html

    wp user create headless "$WP_DEPLOYER_EMAIL" \
        --role=author --user_pass="$WP_DEPLOYER_PASS" --allow-root --path=/var/www/html

    wp user application-password create headless "Astro Client" \
        --porcelain --allow-root --path=/var/www/html > /run/secrets/wp_app_pass

    wp post create --post_type=page --post_title="Home" --post_status=publish --allow-root --path=/var/www/html
    wp option update blogdescription "Headless by Design" --allow-root --path=/var/www/html
    
    touch /var/www/html/.bootstrapped
fi

echo "=== Setup Complete ==="
echo "WordPress Admin: http://localhost:9001/wp-admin/"
echo "Username: $WP_ADMIN_USER"
echo "Password: [from secrets]"
echo "Starting Apache..."
exec apache2-foreground