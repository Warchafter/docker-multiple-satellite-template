<?php
// Load environment secrets
define('DB_HOST', getenv('WORDPRESS_DB_HOST'));
define('DB_NAME', getenv('WORDPRESS_DB_NAME'));
define('DB_USER', getenv('WORDPRESS_DB_USER'));
define('DB_PASSWORD', file_exists(getenv('WORDPRESS_DB_PASSWORD_FILE'))
    ? trim(file_get_contents(getenv('WORDPRESS_DB_PASSWORD_FILE')))
    : getenv('WORDPRESS_DB_PASSWORD'));

// Keys & Salts (use Docker secrets or direct envs)
define('AUTH_KEY',         getenv('WP_AUTH_KEY'));
define('SECURE_AUTH_KEY',  getenv('WP_SECURE_AUTH_KEY'));
define('LOGGED_IN_KEY',    getenv('WP_LOGGED_IN_KEY'));
define('NONCE_KEY',        getenv('WP_NONCE_KEY'));

$table_prefix = 'wp_';
define('WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST']);
define('WP_HOME',    'http://' . $_SERVER['HTTP_HOST']);

// Disable file edits, enforce REST usage
define('DISALLOW_FILE_EDIT', true);
define('WP_REST_RESPONSE_CACHE_DEFAULT_TIMEOUT', 0);

// Standard settings
if ( ! defined('ABSPATH') ) {
    define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
