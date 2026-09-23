#!/bin/sh
set -e

# Read secrets from files mounted by Docker secrets
if [ -f "/run/secrets/db_password" ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

if [ -f "/run/secrets/wp_admin_password" ]; then
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
fi

if [ -f "/run/secrets/wp_user_password" ]; then
    WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
fi

# Ensure /run/php exists for PHP-FPM PID and socket files
mkdir -p /run/php

# Wait for MariaDB to become accessible
echo "Waiting for MariaDB to be available..."
while ! mariadb-admin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    sleep 2
done
echo "MariaDB connection established successfully."

# Install and configure WordPress if not already configured
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Downloading WordPress core files..."
    wp core download --allow-root --path=/var/www/html

    echo "Configuring wp-config.php..."
    wp config create --allow-root \
        --path=/var/www/html \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306"

    echo "Installing WordPress..."
    wp core install --allow-root \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    echo "Creating secondary user..."
    wp user create --allow-root \
        --path=/var/www/html \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author

    echo "Configuring Redis object cache..."
    wp config set WP_REDIS_HOST redis --allow-root --path=/var/www/html
    wp config set WP_REDIS_PORT 6379 --raw --allow-root --path=/var/www/html
    wp config set WP_CACHE true --raw --allow-root --path=/var/www/html
    wp plugin install redis-cache --activate --allow-root --path=/var/www/html
    wp redis enable --allow-root --path=/var/www/html || true

    echo "Adjusting file permissions..."
    chown -R www-data:www-data /var/www/html
fi

echo "Starting PHP-FPM (v8.2) in foreground mode..."
exec php-fpm8.2 -F
