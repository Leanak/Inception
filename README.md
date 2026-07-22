# Inception — 42 School Project

Infrastructure Docker complète servant un site WordPress, orchestrée via
Docker Compose, avec des images construites entièrement à la main
(aucune image "ready-made" tirée du Docker Hub).

> Projet : `Inception` — 42 School
> Login : `lenakach`
> Domaine : `leakache.42.fr`

---

## Aperçu

Le projet met en place trois conteneurs qui communiquent sur un réseau
Docker dédié :

| Service      | Rôle                                                    | Base image     |
|--------------|----------------------------------------------------------|----------------|
| `nginx`      | Reverse proxy / point d'entrée HTTPS (TLSv1.2 / TLSv1.3)  | Debian 13.6    |
| `wordpress`  | WordPress + PHP-FPM (sans serveur web embarqué)           | Debian 13.6    |
| `mariadb`    | Base de données du site WordPress                         | Debian 13.6    |

Chaque service :
- possède son propre `Dockerfile`, construit depuis Alpine ou Debian (jamais une image toute faite) ;
- tourne dans son propre conteneur, redémarre automatiquement (`restart: always`) ;
- communique avec les autres uniquement via le réseau `inception_network`.

Les données persistantes (base MariaDB, fichiers WordPress) sont stockées
sur la machine hôte, sous `/home/lenakach/data/`, via des volumes Docker.

## Structure du projet

```
.
├── Makefile
└── srcs/
    ├── .env
    ├── docker-compose.yml
    ├── todo.txt
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/init.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/nginx.conf
        └── wordpress/
            ├── Dockerfile
            └── tools/init.sh
```

## Démarrage rapide

```bash
git clone <url-du-repo> inception
cd inception
make
```

Une fois les conteneurs up, le site est accessible à l'adresse :

```
https://leakache.42.fr
```

(après avoir ajouté l'entrée correspondante dans `/etc/hosts`, voir `USER_DOC.md`).

## Documentation

- [`USER_DOC.md`](./USER_DOC.md) — utilisation courante : lancer/arrêter le projet,
  se connecter au site, gérer WordPress, dépanner les problèmes fréquents.
- [`DEV_DOC.md`](./DEV_DOC.md) — documentation technique : architecture,
  détail de chaque conteneur, gestion des volumes et du réseau, variables
  d'environnement, conformité avec le sujet 42.

## Prérequis

- Docker Engine + Docker Compose plugin (`docker compose`, pas `docker-compose`)
- `make`
- Droits d'écriture dans `/home/lenakach/data`

## Statut / TODO

- [ ] Docker secrets pour les identifiants sensibles (actuellement en `.env`)
- [x] Volumes stockés sous `/home/lenakach/data`
- [ ] Bonus (Redis, Adminer, FTP, etc. — non implémentés actuellement)

## Auteur

`lenakach` — 42 Paris
