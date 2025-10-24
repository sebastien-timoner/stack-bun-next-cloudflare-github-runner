# Timoner.com

Infrastructure Docker Compose complète avec déploiement continu sans downtime.

## 🎯 Caractéristiques

- ✅ Container web Bun avec intégration GitHub
- ✅ Tunnel Cloudflare pour accès sécurisé
- ✅ Déploiement sans downtime via releases versionées
- ✅ Gestion automatique de l'historique (4 releases max)
- ✅ Rechargement graceful de l'application
- ✅ Clés SSH Ed25519 modernes
- ✅ Scripts de gestion simples (./console)

## 📁 Structure du projet

```
stack/
├── console                          # Gestionnaire de containers
├── compose.yml                      # Configuration Docker Compose
├── DEPLOYMENT.md                    # Guide du déploiement
├── README.md                        # Ce fichier
├── .env                            # Configuration (non versionné)
├── .gitignore                      # Fichiers à ignorer
│
├── .github/
│   └── workflows/
│       └── deploy.yml              # Workflow GitHub Actions
│
├── .ssh/                           # Clés SSH
│   ├── id_ed25519                  # Clé privée (⚠️ confidentielle)
│   ├── id_ed25519.pub              # Clé publique
│   └── README.md                   # Documentation SSH
│
└── services/                       # Services organisés par domaine
    ├── README.md                   # Guide pour ajouter un service
    │
    ├── web/                        # Service web Bun
    │   ├── Dockerfile
    │   ├── entrypoint.sh           # Démarrage + watcher
    │   ├── deploy.sh               # Gestion des releases
    │   ├── webhook.js              # Webhook pour déploiements
    │   ├── .dockerignore
    │   └── README.md
    │
    └── cloudflare/                 # Service Cloudflare Tunnel
        └── README.md
```

## ⚡ Démarrage en 5 minutes (cas simple)

Vous avez une application Bun et vous voulez la déployer sans downtime ?

```bash
# 1. Cloner ce repo
git clone <ce-repo> && cd stack

# 2. Générer les clés SSH
./console ssh-keygen

# 3. Configurer
cp .env.example .env
# Éditer .env : GIT_REPO, GIT_SSH_KEY (voir ./console export-ssh-key), CLOUDFLARE_TUNNEL_TOKEN

# 4. Démarrer
./console start

# 5. Vérifier
./console logs -f
```

**Besoin de plus de détails ?** Voir la section "Démarrage rapide" complet ci-dessous.

---

## 🚀 Démarrage rapide

### 1. Configuration initiale

```bash
# Copier l'environnement
cp .env.example .env

# Générer les clés SSH
./console ssh-keygen

# Éditer .env avec vos valeurs
# - GIT_REPO: votre repo GitHub
# - GIT_SSH_KEY: exécuter './console export-ssh-key' pour obtenir la valeur
# - CLOUDFLARE_TUNNEL_TOKEN: votre tunnel Cloudflare
```

### 2. Ajouter la clé SSH à GitHub

```bash
# La clé publique s'affiche automatiquement après ./console ssh-keygen
# Ou pour l'afficher à nouveau:
cat .ssh/id_ed25519.pub

# Ajouter à GitHub:
# Repository > Settings > Deploy keys > Add deploy key
```

### 3. Configurer la clé SSH dans .env

```bash
# Injecter automatiquement la clé privée dans .env
./console export-ssh-key

# La commande va ajouter ou mettre à jour GIT_SSH_KEY dans .env
# Voir .ssh/README.md pour les détails
```

### 4. Configurer le tunnel Cloudflare

```bash
# Voir CLOUDFLARE_SETUP.md pour les détails
# ou services/cloudflare/README.md
```

### 5. Démarrer les services

```bash
./console start

# Ou en avant-plan pour voir les logs
./console up
```

## 📋 Commandes disponibles

```bash
# SSH Management
./console ssh-keygen       # Générer les clés SSH pour le déploiement
./console export-ssh-key   # Exporter la clé privée au format JSON pour .env

# Containers
./console start            # Démarrer les containers
./console stop             # Arrêter les containers
./console restart          # Redémarrer les containers
./console build            # Construire les images
./console logs             # Afficher les logs
./console logs -f          # Logs en temps réel
./console shell            # Shell dans le container web
./console status           # État des containers
./console up               # Démarrer en avant-plan
./console down             # Arrêter et supprimer
./console clean            # Tout nettoyer
./console help             # Aide
```

## 🔄 Déploiement

### Automatique via GitHub Actions (recommandé)

1. Push sur la branche `main`
2. GitHub Actions crée un job
3. Self-hosted runner poll le job depuis GitHub
4. Runner exécute le déploiement localement
5. Nouvelle release créée et déployée
6. Application rechargée sans downtime
7. Résultat visible dans GitHub Actions UI

#### Configuration du runner

**Dans ce repository (stack):**
```bash
./scripts/setup-runner.sh <github-repo-url> <runner-token>
./scripts/start-runner.sh
```

**Dans votre repository d'application:**
1. Copiez le workflow template:
   ```bash
   cp _templates/.github/workflows/deploy.yml.example <votre-app>/.github/workflows/deploy.yml
   ```
2. Configurez les secrets GitHub:
   - `GIT_REPO`: URL SSH de votre repo (ex: `git@github.com:user/repo.git`)
3. Poussez sur `main` pour tester

Voir [RUNNER_SETUP.md](RUNNER_SETUP.md) pour les détails complets.

### Manuel (depuis l'HOST)

```bash
# Via le script de déploiement
./scripts/deploy.sh git@github.com:username/repo.git

# Vérification
./console shell
ls -la /app/releases
readlink /app/current
```

### Rollback

```bash
# Voir les releases
./console shell
ls -la /app/releases

# Revenir à la release précédente
rm /app/current
ln -s /app/releases/3 /app/current
```

## 📊 Architecture

```
GitHub Repository
   ↓
Push sur 'main'
   ↓
GitHub Actions Job
   ↓
Self-Hosted Runner (HOST)
   ├─ ./scripts/deploy.sh
   └─ docker compose exec web /deploy.sh
      ↓
      Container Web (Bun)
      ├── git clone
      ├── bun install
      ├── bun run build
      └── Gestion des releases
          ├── /app/releases/1  ← Anciennes
          ├── /app/releases/2  ← versions
          ├── /app/releases/3  ← conservées
          └── /app/releases/4  ← (current)
               ↓
               bun start (port 3000)
               ↓
      Cloudflare Tunnel
               ↓
             Internet
```

## 🔐 Sécurité

- **SSH**: Clés Ed25519 (256-bit, moderne et sûr)
- **Webhooks**: Signature HMAC-SHA256
- **Secrets**: Stockés dans `.env` (git-ignoré)
- **Permissions**: Fichiers SSH avec permissions `600`

## 📖 Documentation

- **[RUNNER_SETUP.md](RUNNER_SETUP.md)** - Installation du GitHub self-hosted runner
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Guide complet du système de déploiement
- **[.ssh/README.md](.ssh/README.md)** - Gestion des clés SSH
- **[CLOUDFLARE_SETUP.md](CLOUDFLARE_SETUP.md)** - Configuration Cloudflare
- **[services/README.md](services/README.md)** - Ajouter de nouveaux services
- **[services/web/README.md](services/web/README.md)** - Service web Bun
- **[services/cloudflare/README.md](services/cloudflare/README.md)** - Service Cloudflare

## 🐛 Dépannage

### Container ne démarre pas

```bash
./console logs -f
```

Vérifiez:
- `.env` configuré correctement
- Clé SSH valide
- Repository GitHub accessible

### Déploiement échoue

```bash
# Logs du container
./console logs | grep Deploy

# État des releases
./console shell
ls -la /app/releases
```

### Accès refusé SSH

```bash
# Vérifier la clé SSH
cat .ssh/id_ed25519.pub

# La clé est-elle ajoutée à GitHub?
# Repository > Settings > Deploy keys
```

## 📦 Dépendances

- Docker + Docker Compose
- Bash (pour le script ./console)
- Bun (dans le container)
- Git (dans le container)

## 📝 Notes

- Historique limité à **4 releases** (configurable dans `deploy.sh`)
- Downtime lors du déploiement: **~2 secondes**
- Espace disque utilisé: **~800MB max** (4 releases)
- Port web: **3000** (non exposé localement)
- Port webhook: **3001** (optionnel)

## 🔗 Ressources

- [Bun Documentation](https://bun.sh)
- [Docker Compose](https://docs.docker.com/compose/)
- [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [SSH Best Practices](https://infosec.mozilla.org/guidelines/openssh)

## 📄 Licence

Ce projet est fourni tel quel. Modifiez-le selon vos besoins.

---

**Créé avec ❤️ pour des déploiements sans downtime**
