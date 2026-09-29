#!/bin/sh
set -e

FTP_PASSWORD=$(cat /run/secrets/ftp_password)
FTP_USER=${FTP_USER:-ftpuser}

mkdir -p /var/run/vsftpd/empty

if ! id "$FTP_USER" >/dev/null 2>&1; then
    useradd -s /bin/bash -d /var/www/html -G www-data "$FTP_USER"
fi

echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
chmod -R g+w /var/www/html

exec /usr/sbin/vsftpd /etc/vsftpd.conf
