# Service Web

Service web basé sur **Bun** avec intégration Git et déploiement continu via GitHub Actions self-hosted runner.

## Fonctionnalités

- 🚀 Runtime Bun haute performance
- 🔐 Clone de repository GitHub via SSH
- 📦 Installation automatique des dépendances
- 🔨 Build automatique
- ⚡ Déploiement sans downtime
- 🔄 Releases versionées avec symlinks
- 📊 Historique de 4 releases maximum
- 🤖 Déploiement via GitHub Actions runner

## Variables d'environnement

- `GIT_REPO`: URL du repository GitHub (ex: `git@github.com:user/repo.git`)
- `GIT_SSH_KEY`: Clé SSH privée Ed25519 pour l'authentification GitHub

## Processus de démarrage

1. Configuration SSH avec la clé privée Ed25519
2. Vérification du premier déploiement
   - Si c'est la première fois, exécute `/deploy.sh`
   - Crée la release 1 et le symlink `current`
3. Démarrage de l'application (`bun start`)
4. Attente des déploiements via le GitHub runner

## Structure des releases

```
/app/
├── releases/
│   ├── 1/ → Release 1 (ancienne)
│   ├── 2/ → Release 2
│   ├── 3/ → Release 3
│   └── 4/ → Release 4 (actuelle)
└── current → symlink vers releases/4
```

L'application s'exécute toujours depuis `/app/current`.

## Déploiement

### Déploiement automatique via GitHub Actions

Chaque push sur la branche `main` déclenche:
1. GitHub Actions lance un job sur le self-hosted runner
2. Runner exécute `/deploy.sh` localement
3. Nouvelle release créée et buildée
4. Symlink mis à jour vers la nouvelle release
5. Vérification du déploiement et health check
6. Résultat affiché dans GitHub Actions UI

### Déploiement manuel

```bash
# Accès au container
./console shell

# Exécution manuelle du script
/deploy.sh "$GIT_REPO"

# Vérification
ls -la /app/releases
readlink /app/current
```

## Architecture de déploiement

```
Push sur 'main'
     ↓
GitHub Actions déclenche le job
     ↓
Self-hosted runner poll les jobs
     ↓
Runner exécute localement:
  ├── Checkout du code
  ├── Exécution de /deploy.sh
  │   ├── Création release/N
  │   ├── Clone du repo
  │   ├── bun install
  │   ├── bun run build
  │   └── Mise à jour du symlink
  ├── Vérification du déploiement
  └── Health check (curl localhost:3000)
     ↓
Résultat rapporté à GitHub
```

**Downtime**: ~2 secondes | **Historique**: 4 releases | **Espace**: ~800MB max

## Ports

- Port interne: **3000** (application, non exposé localement)

## Fichiers

- `Dockerfile`: Image Docker basée sur `oven/bun:latest`
- `entrypoint.sh`: Script de démarrage et initialisation
- `deploy.sh`: Script de déploiement et gestion des releases
- `.dockerignore`: Fichiers ignorés lors du build

## Dépannage

### Le container ne démarre pas

```bash
./console logs web -f
```

Vérifiez:
- `GIT_REPO` est correct
- `GIT_SSH_KEY` est valide et au format correct
- Le repository est accessible via SSH

### Le déploiement échoue

```bash
# Vérifier les logs du container
./console logs web | grep Deploy

# Vérifier l'état des releases
docker compose exec web ls -la /app/releases
```

### Revenir à une version antérieure

```bash
# Voir les releases disponibles
docker compose exec web ls -la /app/releases

# Pointer vers une release antérieure (ex: 3)
docker compose exec web rm /app/current
docker compose exec web ln -s /app/releases/3 /app/current

# Recharger l'application
docker compose exec web touch /app/releases/RELOAD
```

## Voir aussi

- [DEPLOYMENT.md](../../DEPLOYMENT.md) - Guide complet du système de déploiement
- [services/README.md](../README.md) - Structure des services
