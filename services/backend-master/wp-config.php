<?php
// Load environment secrets
$db_host = getenv('WORDPRESS_DB_HOST');
$db_port = getenv('WORDPRESS_DB_PORT');

// Combine host and port for WordPress (required for non-standard ports)
define('DB_HOST', $db_port ? $db_host . ':' . $db_port : $db_host);
define('DB_NAME', getenv('WORDPRESS_DB_NAME'));
define('DB_USER', getenv('WORDPRESS_DB_USER'));
define('DB_PASSWORD', trim(file_get_contents(getenv('WORDPRESS_DB_PASSWORD_FILE'))));

// Keys & Salts (use simple fallbacks for now)
define('AUTH_KEY',         getenv('WP_AUTH_KEY') ?: 'put-your-unique-phrase-here-auth-key');
define('SECURE_AUTH_KEY',  getenv('WP_SECURE_AUTH_KEY') ?: 'put-your-unique-phrase-here-secure-auth-key');
define('LOGGED_IN_KEY',    getenv('WP_LOGGED_IN_KEY') ?: 'put-your-unique-phrase-here-logged-in-key');
define('NONCE_KEY',        getenv('WP_NONCE_KEY') ?: 'put-your-unique-phrase-here-nonce-key');

$table_prefix = 'wp_';
define('WP_SITEURL', getenv('PUBLIC_WP_API'));
define('WP_HOME',    getenv('PUBLIC_WP_API'));

// Disable file edits, enforce REST usage
define('DISALLOW_FILE_EDIT', true);
define('WP_REST_RESPONSE_CACHE_DEFAULT_TIMEOUT', 0);

// Standard settings
if ( ! defined('ABSPATH') ) {
    define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
