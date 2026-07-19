#!/bin/bash

set -e

mkdir -p /var/www/html

cd /var/www/html

until mariadb -h mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1"; do
    echo "Attente de MariaDB..."
    sleep 1
done

if [ ! -f wp-config.php ]
then
    echo "Installation WordPress..."

    wp core download --allow-root

    wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \
        --allow-root

    wp core install \
        --url=${DOMAIN_NAME} \
        --title="Inception" \
        --admin_user=${WP_ADMIN} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root
fi

exec php-fpm8.4 -F