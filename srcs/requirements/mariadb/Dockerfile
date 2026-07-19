FROM debian:stable

#RUN apt-get update && apt-get install -y mariadb-server
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/mysql/*

COPY tools/init.sh /init.sh

RUN chmod +x /init.sh

ENTRYPOINT ["/init.sh"]
