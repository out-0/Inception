FROM debian:bookworm

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        mariadb-server \
        mariadb-client && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

RUN sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/mariadb-setup.sh /usr/local/bin/mariadb-setup.sh
RUN chmod +x /usr/local/bin/mariadb-setup.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb-setup.sh"]
