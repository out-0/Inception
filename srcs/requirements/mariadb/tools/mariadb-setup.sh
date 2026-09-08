#!/bin/sh

# Populate the database folders if they are empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB system tables..."
    mysql-install-db --user=mysql --datadir=/var/lib/mysql

	# Owning the database folder to the mysql user
	chown -R mysql:mysql /var/lib/mysql

    # Configure administrative and normal users safely using environment variables
	# with bootstrapping for quick command execution without starting the server
    echo "Creating database and users..."
    mysqld --user=mysql --bootstrap << EOF
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
exec mysqld --user=mysql --console
