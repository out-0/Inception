#!/bin/sh

# Read secrets from files (Docker secrets), not plain env vars
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Ensure the socket directory exists and is owned correctly
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Populate the database folders if they are empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB system tables..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # Owning the database folder to the mysql user
    chown -R mysql:mysql /var/lib/mysql

    # Configure administrative and normal users safely using secrets + env vars
    echo "Creating database and users..."
    mariadbd --user=mysql --bootstrap << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
fi

# Replace the active shell with the daemon process as PID 1
echo "Launching MariaDB daemon..."

# Hand on the control to MariaDB and direct logs to stdout with console
exec mariadbd --user=mysql --console
