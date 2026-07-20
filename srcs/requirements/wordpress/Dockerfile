FROM debian:13.6

RUN apt-get update && apt-get install -y \
		php-fpm \
        php-cli \
		php-mysql \
		php-gd \
		php-xml \
		php-curl \
		php-mbstring \
		wget \
		tar \
        curl \
        mariadb-client
       
RUN sed -i "s|^listen = .*|listen = 9000|" /etc/php/8.4/fpm/pool.d/www.conf

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY tools/init.sh /init.sh

RUN chmod +x /init.sh

ENTRYPOINT ["/init.sh"]