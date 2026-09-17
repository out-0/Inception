#!/bin/sh
set -e

# Generate self-signed SSL certificate if it does not already exist
if [ ! -f /etc/ssl/certs/inception.crt ] || [ ! -f /etc/ssl/private/inception.key ]; then
    echo "Generating self-signed SSL certificate for ${DOMAIN_NAME:-aarid.42.fr}..."
    mkdir -p /etc/ssl/certs /etc/ssl/private
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/ssl/private/inception.key \
        -out /etc/ssl/certs/inception.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME:-aarid.42.fr}"
fi

echo "Starting NGINX in foreground..."
exec nginx -g "daemon off;"