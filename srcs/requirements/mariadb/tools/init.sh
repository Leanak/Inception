#!/bin/bash

set -e

DATADIR="/var/lib/mysql"

# Première initialisation uniquement
if [ ! -d "${DATADIR}/mysql" ]
then
	echo "Initialisation de MariaDB..."

	mariadb-install-db \
		--user=mysql \
		--datadir="${DATADIR}"

    	mkdir -p /run/mysqld
    	chown mysql:mysql /run/mysqld

	mariadbd \
		--user=mysql \
		--skip-networking &

	until mysqladmin ping --silent
	do
        	echo "Attente du démarrage de MariaDB..."
		sleep 1
	done

	echo "Configuration de la base..."

	mariadb -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"

	mariadb -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"

	mariadb -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"

	mariadb -e "FLUSH PRIVILEGES;"

	mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

	echo "Arrêt du serveur temporaire..."

	mysqladmin \
		-u root \
		-p"${MYSQL_ROOT_PASSWORD}" \
		shutdown

	echo "Initialisation terminée."
else
	echo "MariaDB déjà initialisée."
fi

echo "Lancement du serveur MariaDB..."

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
exec mariadbd --user=mysql --bind-address=0.0.0.0
