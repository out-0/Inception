FROM debian:bookworm

RUN apt-get update -y && \
	apt-get install -y --no-install-recommends \
	vsftpd && \
	rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp-setup.sh /usr/local/bin/ftp-setup.sh
RUN chmod +x /usr/local/bin/ftp-setup.sh

# FTP use two channels, one for data exchange and one for control(commends)
EXPOSE 21 21100-21105

ENTRYPOINT ["/usr/local/bin/ftp-setup.sh"]
