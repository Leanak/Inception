# USER_DOC — Guide d'utilisation

Ce document explique comment lancer, utiliser et arrêter le projet
Inception au quotidien, sans entrer dans le détail technique de
l'implémentation (voir `DEV_DOC.md` pour ça).

## 1. Prérequis avant le premier lancement

1. Docker et le plugin Compose installés :
   ```bash
   docker --version
   docker compose version
   ```
2. Ajouter le domaine dans `/etc/hosts` (remplace `<IP_VM>` par l'IP de
   ta machine/VM si tu n'es pas en local) :
   ```
   127.0.0.1   leakache.42.fr
   ```
3. Vérifier/adapter le fichier `srcs/.env` (voir section 4).

## 2. Lancer le projet

Depuis la racine du repo :

```bash
make
```

Cette commande :
- crée les dossiers de données sur l'hôte (`/home/lenakach/data/mariadb`,
  `/home/lenakach/data/wordpress`) s'ils n'existent pas ;
- build les 3 images Docker ;
- démarre les conteneurs en arrière-plan.

Vérifier que tout tourne :

```bash
docker ps
```

Tu dois voir `mariadb_container`, `wordpress_container` et
`nginx_container` avec le statut `Up`.

## 3. Accéder au site

Ouvre dans ton navigateur :

```
https://leakache.42.fr
```

Le certificat étant auto-signé, le navigateur affiche un avertissement de
sécurité — c'est normal, clique sur "Continuer" / "Avancé" pour accéder au
site.

### Accès administrateur WordPress

```
https://leakache.42.fr/wp-admin
```

Identifiants définis dans `srcs/.env` :
- Utilisateur : valeur de `WP_ADMIN`
- Mot de passe : valeur de `WP_ADMIN_PASSWORD`

Un second utilisateur (rôle "author") est créé automatiquement au premier
démarrage, avec les identifiants `USER1_LOGIN` / `USER1_PASSWORD`.

## 4. Configuration (`srcs/.env`)

| Variable              | Description                                   |
|-----------------------|------------------------------------------------|
| `MYSQL_DATABASE`      | Nom de la base WordPress                        |
| `MYSQL_USER`          | Utilisateur MySQL applicatif                    |
| `MYSQL_PASSWORD`      | Mot de passe de cet utilisateur                 |
| `MYSQL_ROOT_PASSWORD` | Mot de passe root MariaDB                       |
| `DOMAIN_NAME`         | Nom de domaine du site (`leakache.42.fr`)       |
| `WP_ADMIN`            | Identifiant admin WordPress                     |
| `WP_ADMIN_PASSWORD`   | Mot de passe admin WordPress                    |
| `WP_ADMIN_EMAIL`      | Email admin WordPress                           |
| `USER1_LOGIN`         | Identifiant du second utilisateur WordPress     |
| `USER1_MAIL`          | Email du second utilisateur                     |
| `USER1_PASSWORD`      | Mot de passe du second utilisateur              |
| `DATA_PATH`           | Dossier hôte où sont stockées les données       |

> ⚠️ Ne jamais commiter un `.env` avec de vrais secrets sur un repo public.

## 5. Arrêter / redémarrer le projet

```bash
make down      # arrête les conteneurs (les données sont conservées)
make up        # relance les conteneurs existants
make re        # tout supprime et relance depuis zéro (perte des données)
```

## 6. Où sont mes données ?

Les données persistent sur la machine hôte (pas seulement dans le
conteneur), sous :

```
/home/lenakach/data/mariadb     → base de données MariaDB
/home/lenakach/data/wordpress   → fichiers WordPress (thèmes, plugins, uploads...)
```

Elles survivent donc à un `docker compose down` ou à la suppression des
conteneurs. Seul `make fclean` les efface.

## 7. Problèmes fréquents

| Symptôme                                     | Cause probable / solution                                                        |
|-----------------------------------------------|-------------------------------------------------------------------------------------|
| Le navigateur ne trouve pas `leakache.42.fr`  | Entrée manquante dans `/etc/hosts`                                                 |
| "Connexion non sécurisée" au chargement       | Normal : certificat auto-signé, cliquer sur "Continuer"                            |
| `docker compose up` échoue sur les volumes    | Le dossier `/home/lenakach/data/...` n'existe pas encore → relancer `make build`   |
| Page blanche / erreur 502                     | Le conteneur `wordpress` n'est pas encore prêt → attendre quelques secondes        |
| Modifs WordPress perdues après `make re`      | Comportement normal, `fclean` supprime les données host                            |

## 8. Support

Pour toute question technique sur le fonctionnement interne
(Dockerfiles, réseau, volumes, choix d'implémentation), voir `DEV_DOC.md`.
