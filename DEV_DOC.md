# DEV_DOC — Documentation technique

Documentation destinée à comprendre, maintenir ou faire évoluer le
projet, et à vérifier sa conformité avec le sujet 42 Inception.

## 1. Architecture générale

```
                        ┌───────────────────────────┐
   navigateur  ── 443 ─▶│   nginx_container          │
   (HTTPS/TLS)          │   nginx (Debian 13.6)      │
                        └─────────────┬──────────────┘
                                      │ fastcgi :9000
                                      ▼
                        ┌───────────────────────────┐
                        │  wordpress_container       │
                        │  php-fpm 8.4 + WP-CLI      │
                        └─────────────┬──────────────┘
                                      │ mysql :3306
                                      ▼
                        ┌───────────────────────────┐
                        │  mariadb_container          │
                        │  mariadb-server             │
                        └───────────────────────────┘

Réseau Docker commun : inception_network (bridge)

Seul `nginx` expose un port sur l'hôte (443). `wordpress` et `mariadb`
ne sont accessibles que depuis les autres conteneurs du réseau
`inception_network`, jamais depuis l'extérieur.

## 2. Détail par service

### 2.1 `nginx`

- **Dockerfile** : `srcs/requirements/nginx/Dockerfile`
- Base : `debian:13.6`
- Installe `nginx` + `openssl`, génère un certificat auto-signé au build
  (`openssl req -x509 ... -subj "/CN=leakache.42.fr"`), valide 365 jours.
- Copie `conf/nginx.conf` dans `/etc/nginx/sites-available/default`.
- `EXPOSE 443` uniquement — pas de port 80 (le sujet impose TLS only).
- `ENTRYPOINT ["nginx", "-g", "daemon off;"]` : nginx tourne au premier
  plan, condition nécessaire pour que le conteneur reste `Up`.
- `nginx.conf` : termine le TLS (`ssl_protocols TLSv1.2 TLSv1.3`), sert
  les fichiers statiques depuis `/var/www/html` (volume partagé avec
  `wordpress`), et relaie les requêtes `.php` vers
  `wordpress:9000` en FastCGI.

### 2.2 `wordpress`

- **Dockerfile** : `srcs/requirements/wordpress/Dockerfile`
- Base : `debian:13.6`
- Installe `php-fpm`, `php-cli`, `php-mysql`, `php-curl`, `wp-cli`.
- Pas de serveur web dans ce conteneur (nginx s'en charge) — conforme au
  sujet : *"WordPress + php-fpm ... only without nginx"*.
- `init.sh` (exécuté à chaque démarrage du conteneur) :
  1. Attend que MariaDB réponde (`mariadb -h mariadb ... SELECT 1`).
  2. Si `wp-config.php` n'existe pas encore (premier lancement) :
     - télécharge le core WordPress (`wp core download`) ;
     - génère `wp-config.php` avec les creds de la base ;
     - installe WordPress (`wp core install`) avec le compte admin ;
     - crée un second utilisateur avec le rôle `author`.
  3. Lance `php-fpm8.4` au premier plan (`-F`).
- Idempotent : au redémarrage, l'étape d'installation est sautée car
  `wp-config.php` existe déjà sur le volume persistant.

### 2.3 `mariadb`

- **Dockerfile** : `srcs/requirements/mariadb/Dockerfile`
- Base : `debian:13.6`
- Installe `mariadb-server` + `mariadb-client`, vide `/var/lib/mysql` au
  build pour partir propre (le vrai contenu viendra du volume monté).
- `init.sh` :
  1. Si `/var/lib/mysql/mysql` n'existe pas → première init :
     - `mariadb-install-db` ;
     - démarre un serveur temporaire sans réseau (`--skip-networking`) ;
     - crée la base `MYSQL_DATABASE`, l'utilisateur applicatif
       `MYSQL_USER`, lui donne tous les droits sur cette base ;
     - fixe le mot de passe root (`MYSQL_ROOT_PASSWORD`) ;
     - arrête le serveur temporaire.
  2. Relance `mariadbd` en avant-plan, bindé sur `0.0.0.0` (accessible
     depuis le réseau `inception_network`, pas depuis l'hôte).
- Healthcheck Compose (`mysqladmin ping`) : `wordpress` attend que
  `mariadb` soit `service_healthy` avant de démarrer
  (`depends_on: condition: service_healthy`).

## 3. Réseau

Un unique réseau bridge défini dans `docker-compose.yml` :

```yaml
networks:
  inception_network:
```

Tous les services y sont rattachés. La résolution de nom Docker permet
à `wordpress` de joindre `mariadb` par son nom de service (`mariadb`),
et à `nginx` de joindre `wordpress:9000` de la même façon — aucune IP en
dur nulle part.

## 4. Volumes et persistance des données

### 4.1 Exigence du sujet

Le sujet impose que les données (base + fichiers WordPress) soient
stockées sur la machine hôte, dans `/home/<login>/data`, et pas
uniquement dans la couche writable du conteneur (qui serait perdue à
la suppression du conteneur).

### 4.2 Implémentation

Deux volumes nommés, chacun bindé sur un dossier hôte via
`driver_opts` :

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_PATH}/mariadb
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_PATH}/wordpress
```

- `mariadb_data` → monté sur `/var/lib/mysql` dans le conteneur
  `mariadb`.
- `wordpress_data` → monté sur `/var/www/html`, **partagé** entre
  `wordpress` (écrit les fichiers PHP/uploads) et `nginx` (sert les
  fichiers statiques en lecture).
- `DATA_PATH` (défini dans `srcs/.env`) vaut `/home/lenakach/data`.

### 4.3 Point d'attention

Avec `driver_opts` en mode `bind`, Docker **n'auto-crée pas** les
dossiers hôte cibles — contrairement à un volume nommé "classique". Le
`Makefile` doit donc créer `${DATA_PATH}/mariadb` et
`${DATA_PATH}/wordpress` (`mkdir -p`) **avant** le premier
`docker compose up`, sinon Compose échoue avec une erreur de montage.

## 5. Variables d'environnement / secrets

Actuellement tout passe par `srcs/.env`, chargé par Compose
automatiquement (fichier au nom `.env`) et explicitement via `env_file`
pour `wordpress` et `nginx`. Les mots de passe transitent donc en clair
dans les variables d'environnement du conteneur.


## 6. Conformité avec le sujet Inception (check-list)

- [x] Une image par service, buildée depuis un `Dockerfile` maison (pas
      d'image toute faite du Docker Hub)
- [x] Base Alpine ou Debian (ici Debian 13.6, avant-dernière stable)
- [x] `wordpress` + `php-fpm` sans serveur web dans le même conteneur
- [x] `mariadb` dédié, pas d'image toute faite
- [x] `docker-compose.yml` + `Makefile` à la racine
- [x] Réseau Docker dédié entre les conteneurs
- [x] Fichier `.env` pour les variables d'environnement
- [x] Volumes persistants sous `/home/<login>/data`
- [x] Redémarrage automatique des conteneurs en cas de crash
      (`restart: always` — à vérifier/ajouter sur tous les services)
