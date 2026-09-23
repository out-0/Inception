FROM debian:bookworm

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/static

COPY app/ ./app/
COPY server.js .

EXPOSE 3000

CMD ["node", "server.js"]
