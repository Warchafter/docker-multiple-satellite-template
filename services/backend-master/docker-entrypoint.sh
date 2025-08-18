#!/usr/bin/env bash
set -Eeuo pipefail
trap 'echo "[entrypoint] failed at line $LINENO" >&2' ERR

: "${WP_URL:?}" "${WP_TITLE:?}" "${WP_ADMIN_USER:?}" "${WP_ADMIN_EMAIL:?}" "${WP_ADMIN_PASS:?}"

wait_for_db() {
    local t=${DB_WAIT_TIMEOUT:-60}
    until mysqladmin ping -h"${WORDPRESS_DB_HOST}" -P"${WORDPRESS_DB_PORT:-3306}" --silent >/dev/null 2>&1; do
        ((t--)) || { echo "DB wait timed out"; exit 1; }
        sleep 1
    done
}

ensure_plugin() {
    local slug="$1" ver="${2:-}"
    if ! wp plugin is-installed "$slug" --allow-root; then
        wp plugin install "$slug" ${ver:+--version="$ver"} --activate --allow-root
    else
        wp plugin activate "$slug" --allow-root
    fi
}

wait_for_db

if ! wp core is-installed --allow-root; then
    wp core inttall --url="$WP_URL" --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" --skip-email --allow-root
fi

ensure_plugin woocommerce "10.0.4"

wp user get "$WP_ADMIN_USER" --field=ID --allow-root >/dev/null 2>&1 || \
    wp user create "$WP_ADMIN_USER" "$WP_ADMIN_EMAIL" --user_pass="$WP_ADMIN_PASS" --role=administrator --allow-root

# Permalinks (only change if needed)
current_struct=$(wp option get permalink_structure --allow-root || echo '')
if [[ "$current_struct" != "/%postname%/" ]]; then
    wp rewrite structure '/%postname%' --hard --allow-root
    wp rewrite flush --hard --allow-root
fi

# Ensure headless user (author)
if ! wp user get headless --field=ID --allow-root >/dev/null 2>&1; then
    : "${WP_DEPLOYER_EMAIL:?}" "${WP_DEPLOYER_PASS:?}"
    wp user create headless "$WP_DEPLOYER_EMAIL" --role=author --user_pass="$WP_DEPLOYER_PASS" --allow-root
fi

# Optional: create an application password once and store it to a writable file
# Provide APP_PASS_FILE as a bind mount like /var/run/wp_app_pass
if [[ "${CREATE_APP_PASSWORD:-0}" == "1" && -n "${APP_PASS_FILE:-}" && ! -f "$APP_PASS_FILE" ]]; then
    app_pass=$(wp user application-password create headless "Astro Client" --porcelain --allow-root)
    printf "%s" "$app_pass" > "$APP_PASS_FILE"
    chmod 600 "$APP_PASS_FILE"
    echo "[entrypoint] headless app password written to $APP_PASS_FILE"
fi

# Seed "Home" page and tagline (idempotent)
home_id=$(wp post list --post_type=page --pagename=home --field=ID --allow-root || true)
if [[ -z "$home_id" ]]; then
    home_id=$(wp post create --post_type=page --post_title="Home" --post_status=publish --porcelain --allow-root)
fi
# Tagline
if [[ "$(wp option get blogdescription --allow-root)" != "Headless by Design" ]]; then
    wp option update blogdescription "Headless by Design" --allow-root
fi

exec apache2-foreground