# Nginx Dockerfile to build the image for the nginx container
# Its install nginx, openssl for ssl/tls certificates and
# gettext-base for envsubst command to replace env vars in
# the nginx.conf file


FROM debian:bookworm

# Install Needed Packages
RUN apk update && apk add nginx && \
	apk add openssl && \
	apk add gettext-base # TODO: CHECK IF NEEDED LATER

WORKDIR /the/workdir/path

# Copy the Nginx configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf


# Generate a self-signed SSL certificate for the server
RUN openssl req -x509 -nodes -days 365 \
	-newkey rsa:2048 \
	-keyout /etc/ssl/private/aarid.key \
	-out /etc/ssl/certs/aarid.crt \
	-subj "/CN=${DOMAIN_NAME}"
