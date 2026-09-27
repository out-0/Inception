#!/bin/sh
set -e

# Read secrets from files (Docker secrets)
if [ -f "/run/secrets/db_root_password" ]; then
    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
fi

if [ -f "/run/secrets/db_password" ]; then
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)
fi

# Ensure the socket directory exists and is owned correctly
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Populate the database folders if they are empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB system tables..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # Own the database folder by the mysql user
    chown -R mysql:mysql /var/lib/mysql
fi

echo "Creating database and initial users..."
mariadbd --user=mysql --bootstrap << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
echo "MariaDB system tables and users initialized."

# Replace active shell with the daemon process as PID 1
echo "Launching MariaDB daemon in foreground..."
exec mariadbd --user=mysql --console
