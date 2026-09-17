FROM debian:bookworm

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        nginx \
        openssl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
