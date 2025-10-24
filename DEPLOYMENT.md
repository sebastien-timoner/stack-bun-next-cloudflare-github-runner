# Système de Déploiement Sans Downtime

Guide complet du système de déploiement continu avec gestion des releases.

## 📋 Vue d'ensemble

Le système utilise une approche de **releases versionées** avec **symlinks** pour permettre des déploiements sans downtime:

```
/app/
├── releases/
│   ├── 1/                 # Première release (ancienne)
│   ├── 2/                 # ...
│   ├── 3/                 # ...
│   └── 4/                 # Dernière release
└── current -> releases/4  # Symlink pointant vers la release active
```

## 🔄 Processus de déploiement

### 1. Déploiement initial au démarrage du container

```
1. Configuration SSH
2. Exécution de /deploy.sh
   ├── Création du répertoire releases/1
   ├── Clone du repository
   ├── bun install
   ├── bun run build
   └── Création du symlink current -> releases/1
3. Démarrage de l'application (bun start)
4. Lancement du watcher
```

### 2. Déploiement ultérieur (via webhook/trigger)

```
1. Trigger du webhook /deploy
2. Exécution de /deploy.sh
   ├── Création du répertoire releases/N
   ├── Clone du repository (branche main)
   ├── bun install
   ├── bun run build
   └── Création du symlink current -> releases/N
3. Création du fichier RELOAD
4. Le watcher détecte le changement
5. Rechargement de l'application (graceful kill + restart)
6. Nettoyage: suppression des releases > 4
```

## 🚀 Utilisation

### Configuration minimale dans `.env`

```env
GIT_REPO=git@github.com:username/repo.git
GIT_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----\n...\n-----END OPENSSH PRIVATE KEY-----"
WEBHOOK_SECRET=votre_secret_github
```

### Démarrer le container

```bash
./console start
```

Le container:
1. Configure SSH
2. Clone la branche main
3. Build l'application
4. Démarre bun start
5. Écoute les webhooks de déploiement

### Déclencher un déploiement

#### Option 1: Webhook GitHub

1. Aller dans le repository GitHub
2. **Settings** > **Webhooks** > **Add webhook**
3. **Payload URL**: `http://your-domain.com/deploy`
4. **Content type**: `application/json`
5. **Secret**: Votre `WEBHOOK_SECRET`
6. **Events**: `Push events`
7. **Active**: ✓

Chaque push sur `main` déclenche un déploiement.

#### Option 2: Requête manuelle

```bash
# Sans signature
curl -X POST http://localhost:3000/deploy

# Avec signature GitHub (pour tester)
curl -X POST http://localhost:3000/deploy \
  -H "X-Hub-Signature-256: sha256=..." \
  -d '{"action":"completed"}'
```

#### Option 3: GitHub Actions (fourni)

Le workflow `.github/workflows/deploy.yml` se déclenche automatiquement sur chaque push vers `main`.

## 📁 Structure des releases

### Répertoires de releases

```
releases/
├── 1/
│   ├── src/
│   ├── package.json
│   ├── bunfig.toml
│   └── node_modules/ (après bun install)
├── 2/
│   └── ...
├── 3/
│   └── ...
├── 4/
│   └── ... (version actuelle)
└── RELOAD (créé lors d'un déploiement)
```

### Symlink courant

```bash
/app/current -> /app/releases/4
```

L'application démarre toujours depuis `/app/current`.

## 🔍 Monitoring et logs

### Afficher les logs en temps réel

```bash
./console logs -f
```

Logs du déploiement:
- Configuration SSH
- Clone du repo
- Installation des dépendances
- Build
- Démarrage de l'application
- Changements de déploiement

### Vérifier les releases actuelles

```bash
ls -la /app/releases
ls -la /app/current
```

### Vérifier le statut du container

```bash
./console status
```

## 🔄 Rechargement graceful

Le système utilise un **watcher** qui:

1. Écoute les changements dans `/app/releases`
2. Détecte la création du fichier `RELOAD`
3. Tue le processus bun courant (graceful shutdown)
4. Attend 1 seconde
5. Redémarre l'application avec la nouvelle release

**Avantage**: Pas de downtime, transition en ~2 secondes.

## 🧹 Gestion des releases

### Historique limité à 4 releases

Le script `deploy.sh` nettoie automatiquement:
- Garde les 4 dernières releases
- Supprime les releases numéro > 4
- Garde toujours `/app/current` valide

Exemple:
```
Avant nettoyage: releases/1, /2, /3, /4, /5
Après nettoyage:  releases/2, /3, /4, /5 (et /1 est supprimé)
Nouveau release:  releases/2, /3, /4, /5, /6 (et /2 est supprimé)
```

### Espace disque économisé

- 4 releases complètes (clones + node_modules)
- Les anciennes releases sont supprimées automatiquement
- Exemple: 200MB par release = max 800MB utilisé

## 🔄 Rollback manuel

### Revenir à une release précédente

```bash
# Voir les releases disponibles
ls -la releases/

# Pointer vers une release antérieure
rm /app/current
ln -s /app/releases/3 /app/current

# Recharger l'application
touch /app/releases/RELOAD
```

L'application redémarrera avec la version précédente.

## 🛡️ Sécurité

### Webhook et signature GitHub

- Le `WEBHOOK_SECRET` valide que la requête vient de GitHub
- Vérification HMAC-SHA256
- Rejet des requêtes non signées

### Clés SSH

- Clé Ed25519 (norme moderne)
- Permissions `600` (lecture/écriture uniquement)
- Stockée dans le container
- Jamais exposée en logs

### Permissions de fichiers

```bash
.ssh/          : 700 (rwx------)
.ssh/id_*      : 600 (rw-------)
.ssh/*.pub     : 644 (rw-r--r--)
```

## 🐛 Dépannage

### "Deploy failed: git clone error"

```bash
# Vérifier que la clé SSH est correcte
cat .env | grep GIT_SSH_KEY

# Vérifier que le repo est accessible
ssh -T git@github.com
```

### "Application won't restart"

```bash
# Vérifier que bun start fonctionne localement
cd /app/current
bun start

# Vérifier les logs du container
./console logs -f
```

### "Symlink is broken"

```bash
# Vérifier le symlink
ls -la /app/current

# Recréer manuellement
rm /app/current
ln -s /app/releases/4 /app/current
```

### "Webhook not triggered"

```bash
# Vérifier que le secret est correct
echo $WEBHOOK_SECRET

# Tester manuellement
curl -X POST http://localhost:3001/deploy

# Vérifier les logs GitHub webhook
# GitHub Settings > Webhooks > Dernière tentative
```

## 📊 Métriques

- **Temps de déploiement**: ~30-60 secondes
- **Downtime**: ~2 secondes (rechargement graceful)
- **Espace utilisé**: ~800MB (4 releases × 200MB)
- **Historique conservé**: 4 releases

## 🔗 Fichiers associés

- `services/web/Dockerfile` - Configuration de l'image
- `services/web/entrypoint.sh` - Script de démarrage et watcher
- `services/web/deploy.sh` - Script de déploiement
- `services/web/webhook.js` - Serveur webhook (optionnel)
- `.github/workflows/deploy.yml` - Workflow GitHub Actions
- `.env` - Configuration (GIT_REPO, SSH, SECRET)
