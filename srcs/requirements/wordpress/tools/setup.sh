#!/bin/bash

set -eu

echo "WordPress startup"
echo "================="

# Check required environment variables
: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

# Read secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
CREDENTIALS_FILE="/run/secrets/credentials"

get_credential() {
    key="$1"
    value=$(grep -m 1 "^${key}=" "$CREDENTIALS_FILE" | cut -d '=' -f 2- || true)

    if [ -z "$value" ]; then
        echo "ERROR: Missing ${key} in credentials secret." >&2
        exit 1
    fi

    printf '%s' "$value"
}

WP_ADMIN_USER=$(get_credential WP_ADMIN_USER)
WP_ADMIN_PASSWORD=$(get_credential WP_ADMIN_PASSWORD)
WP_ADMIN_EMAIL=$(get_credential WP_ADMIN_EMAIL)

WP_USER=$(get_credential WP_USER)
WP_USER_PASSWORD=$(get_credential WP_USER_PASSWORD)
WP_USER_EMAIL=$(get_credential WP_USER_EMAIL)

# Enforce the Inception administrator username requirement
if printf '%s' "$WP_ADMIN_USER" | grep -Eiq 'admin|administrator'; then
    echo "ERROR: The administrator username must not contain 'admin'." >&2
    exit 1
fi

# Populate the persistent volume if WordPress is not present
if [ ! -f /var/www/html/wp-load.php ]; then
    echo "Copying WordPress files into the persistent volume..."
    mkdir -p /var/www/html
    cp -a /usr/src/wordpress/. /var/www/html/
fi

chown -R www-data:www-data /var/www/html

# Wait for MariaDB to accept connections (maximum 60 seconds)
echo "Waiting for MariaDB..."

attempt=0

until mariadb-admin \
    --protocol=tcp \
    -h mariadb \
    -u "$MYSQL_USER" \
    --password="$DB_PASSWORD" \
    ping --silent >/dev/null 2>&1
do
    attempt=$((attempt + 1))

    if [ "$attempt" -ge 60 ]; then
        echo "ERROR: MariaDB did not become ready within 60 seconds." >&2
        exit 1
    fi

    sleep 1
done

echo "MariaDB is ready."

# Configure and install WordPress on first startup
if ! wp core is-installed --path=/var/www/html --allow-root 2>/dev/null; then

    echo "Creating WordPress configuration..."

    wp config create \
        --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb \
        --dbprefix=wp_ \
        --skip-check \
        --allow-root

    echo "Installing WordPress..."

    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    echo "Creating the second WordPress user..."

    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=subscriber \
        --path=/var/www/html \
        --allow-root

    echo "WordPress installation complete."

else
    echo "WordPress is already installed."
    echo "Skipping initial installation."
fi

echo "Starting PHP-FPM..."

exec php-fpm8.2 -F