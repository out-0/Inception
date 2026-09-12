FROM debian:bookworm

RUN apt-get update -y && \
    apt-get install -y mariadb-server

WORKDIR /

COPY ./tools/mariadb-setup.sh /tmp/mariadb-setup.sh
RUN chmod +x /tmp/mariadb-setup.sh

#TODO: CHECK THIS LATER
RUN sed -i "s/127.0.0.1/0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf


EXPOSE 3306

ENTRYPOINT ["sh", "/tmp/mariadb-setup.sh"]
