FROM debian:13.6

#RUN apt-get update && apt-get install -y mariadb-server
RUN apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y mariadb-server && \
	apt-get install -y mariadb-client && \
	rm -rf /var/lib/mysql/*

COPY tools/init.sh /init.sh
RUN chmod +x /init.sh
ENTRYPOINT ["/init.sh"]
