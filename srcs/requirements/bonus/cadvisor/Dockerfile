FROM debian:bookworm

RUN apt-get update -y && \
	apt-get install -y --no-install-recommends \
	curl \
	ca-certificates && \
	curl -L https://github.com/google/cadvisor/releases/download/v0.49.1/cadvisor-v0.49.1-linux-amd64 -o /usr/local/bin/cadvisor && \
	chmod +x /usr/local/bin/cadvisor && \
	apt-get purge -y curl ca-certificates && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/*

EXPOSE 8080

CMD ["/usr/local/bin/cadvisor", "-logtostderr", "--port=8080"]
