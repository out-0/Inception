#!/bin/sh
set -e

# Read FTP password from Docker secret
if [ -f "/run/secrets/ftp_password" ]; then
    FTP_PASSWORD=$(cat /run/secrets/ftp_password)
elif [ -z "$FTP_PASSWORD" ]; then
    FTP_PASSWORD="default_ftp_pass"
fi

# Read FTP user from environment, and default to "ftpuser" if not set
FTP_USER=${FTP_USER:-ftpuser}

# Ensure runtime directories exist
mkdir -p /var/run/vsftpd/empty
mkdir -p /var/www/html

# Create FTP user if not already existing
if ! id "$FTP_USER" >/dev/null 2>&1; then
    echo "Creating FTP user: $FTP_USER"
    useradd -m -s /bin/bash -d /var/www/html "$FTP_USER"
    usermod -aG www-data "$FTP_USER"
fi

# Set password for the user
echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd

# Authorize user in vsftpd userlist
echo "$FTP_USER" > /etc/vsftpd.userlist

# Set write permissions on WordPress directory for group www-data
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html

echo "Starting vsftpd daemon in foreground..."
exec /usr/sbin/vsftpd /etc/vsftpd.conf
