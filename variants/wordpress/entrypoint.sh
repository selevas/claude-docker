#!/usr/bin/env bash
set -euo pipefail

DB_NAME="wordpress"
DB_USER="wordpress"
DB_PASS="wordpress"
WP_DIR="/var/www/html"

# Initialize MariaDB data directory on first run
if [ ! -d /var/lib/mysql/mysql ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# Start MariaDB
mysqld_safe --user=mysql &

# Wait for MariaDB to be ready
until mysqladmin ping --silent 2>/dev/null; do
    sleep 1
done

# Create database and user if not already present
mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

# Seed wp-content from the bundled WordPress files if the bind mount is empty
if [ ! -d "${WP_DIR}/wp-content/themes" ]; then
    cp -a /var/www/html-seed/wp-content/. "${WP_DIR}/wp-content/"
fi

# Allow www-data (Apache) to write to wp-content (bind mount is owned by root)
chmod -R 777 "${WP_DIR}/wp-content"

# Generate wp-config.php if missing (container is ephemeral, config is not)
if [ ! -f "${WP_DIR}/wp-config.php" ]; then
    wp config create \
        --path="${WP_DIR}" \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASS}" \
        --dbhost="localhost" \
        --allow-root
fi

# Allow WordPress to write files directly without FTP
wp config set FS_METHOD direct --path="${WP_DIR}" --allow-root 2>/dev/null || true

# Run WordPress install only if not already installed in the database
if ! wp core is-installed --path="${WP_DIR}" --allow-root 2>/dev/null; then
    wp core install \
        --path="${WP_DIR}" \
        --url="http://localhost:${WP_PORT:-8080}" \
        --title="WordPress Dev" \
        --admin_user="admin" \
        --admin_password="admin" \
        --admin_email="admin@example.com" \
        --allow-root
fi

# Start Apache
apache2ctl start

echo ""
echo "WordPress running at http://localhost:${WP_PORT:-8080}"
echo "Admin: http://localhost:${WP_PORT:-8080}/wp-admin  (admin / admin)"
echo ""

exec "$@"
