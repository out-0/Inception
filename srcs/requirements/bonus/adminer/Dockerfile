FROM debian:bookworm

RUN apt-get update -y && \
	apt-get install -y --no-install-recommends \
	php8.2-cli \
	php8.2-mysql \
	curl \
	ca-certificates && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Download the lightweight MySQL-only English version as index.php
RUN curl -L https://www.adminer.org/latest-mysql-en.php -o /var/www/html/index.php

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]