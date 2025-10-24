# GitHub Self-Hosted Runner Setup

Guide d'installation et de configuration du runner GitHub auto-hébergé pour les déploiements continus.

## 🎯 Vue d'ensemble

Au lieu d'utiliser des webhooks, nous utilisons un **self-hosted runner GitHub** qui:
- ✅ Poll les jobs depuis GitHub (pull model)
- ✅ Exécute le déploiement localement
- ✅ Contrôle complètement par GitHub
- ✅ Plus sûr et fiable qu'un webhook
- ✅ Comme GitLab CI runners

## 📋 Prérequis

- Machine Linux (ou macOS/Windows avec WSL)
- Accès administrateur (pour systemd)
- Permissions sur le repository GitHub
- Bun et Git installés

## 🚀 Installation

### 1. Obtenir le token du runner

1. Aller sur GitHub: **Repository Settings**
2. **Actions** > **Runners** > **New self-hosted runner**
3. Sélectionner **Linux** (ou votre OS)
4. Copier l'URL du repository et le **token**

Exemple:
```
Repository: https://github.com/username/repo
Token: ABS2GVJ3XXXXXXXXXXXXXXXXXXXXX
```

### 2. Lancer le script d'installation

```bash
./scripts/setup-runner.sh https://github.com/username/repo ABS2GVJ3XXXXXXXXXXXXXXXXXXXXX
```

Le script va:
- Télécharger le runner GitHub Actions
- Extraire les fichiers
- Configurer le runner
- Créer les scripts de démarrage

**Output:**
```
[Setup] Installation du runner GitHub...
[Setup] Repository: https://github.com/username/repo
[Setup] Répertoire: .github-runner

...

✓ Installation réussie!

Prochaines étapes:
1. Pour démarrer le runner manuellement:
   cd .github-runner
   ./run.sh

2. Pour configurer en tant que service systemd:
   cd .github-runner
   sudo ./svc.sh install
   sudo ./svc.sh start

3. Ou utiliser le script fourni:
   ./scripts/start-runner.sh
```

### 3. Démarrer le runner

#### Option A: Service systemd (recommandé en production)

```bash
./scripts/start-runner.sh .github-runner systemd
```

Le runner devient un service et redémarre automatiquement.

#### Option B: Mode manuel (développement)

```bash
./scripts/start-runner.sh .github-runner manual
```

Le runner s'exécute en avant-plan et affiche les logs en temps réel.

#### Option C: Démarrage direct

```bash
cd .github-runner
./run.sh
```

### 4. Vérifier que le runner est actif

**Via GitHub:**
1. Repository Settings > Actions > Runners
2. Vous devriez voir **app-runner-<hostname>** avec le statut **Idle**

**Via terminal:**
```bash
systemctl status github-runner  # Si service systemd
# ou voir les logs en avant-plan si mode manuel
```

## 📖 Comment ça marche

### Flux de déploiement

```
1. Push sur 'main'
   ↓
2. GitHub détecte le changement
   ↓
3. GitHub crée un job GitHub Actions
   ↓
4. Runner poll les jobs depuis GitHub
   ↓
5. Runner exécute le job localement (HOST)
   ├── Checkout du code
   ├── Exécution de ./scripts/deploy.sh
   │   ↓
   │   Lance dans le container:
   │   └── docker compose exec web /deploy.sh
   │       ├── Création release/N
   │       ├── Clone du repo
   │       ├── bun install
   │       ├── bun run build
   │       └── Mise à jour du symlink
   ├── Vérification du déploiement
   └── Health check (curl localhost:3000)
   ↓
6. Runner reporte les résultats à GitHub
   ↓
7. Workflow terminé (visible dans GitHub UI)
```

### Séparation des responsabilités

**HOST (Runner GitHub):**
- Poll les jobs depuis GitHub
- Déclenche le déploiement
- Orchestre le workflow
- Rapporte les résultats

**CONTAINER Web:**
- Clone le repository
- Installe les dépendances (bun install)
- Build l'application (bun run build)
- Gère les releases et symlinks
- Démarre l'application
- Exécute le health check

### Avantages vs Webhook

| Aspect | Webhook | Self-Hosted Runner |
|--------|---------|-------------------|
| Modèle | Push (HTTP) | Pull (polling) |
| Sécurité | Endpoint public | Connexion sécurisée sortante |
| Dépendance | Container doit être accessible | Aucune |
| Intégration | Besoin de signature HMAC | Native GitHub |
| Performance | Réseau dépendant | Exécution locale directe |
| Contrôle | Runner contrôle le déploiement | GitHub contrôle le runner |

## ⚙️ Configuration

### Variables d'environnement du runner

Depuis `/deploy.sh`:

```bash
GIT_REPO=${{ secrets.GIT_REPO }}  # Récupéré du workflow
```

### Secrets GitHub

Vous devez configurer dans **Repository Settings > Secrets and variables > Actions**:

```
GIT_REPO = git@github.com:username/repo.git
```

Utilisé dans le workflow:
```yaml
- name: Deploy application
  run: /deploy.sh "${{ secrets.GIT_REPO }}"
```

### Variables d'environnement du container

Le runner s'exécute sur la machine hôte, pas dans le container. Pour déployer:

```yaml
- name: Deploy application
  run: |
    # Le runner exécute ceci sur la machine hôte
    docker compose exec web /deploy.sh "${{ secrets.GIT_REPO }}"
```

## 🔧 Gestion du runner

### Arrêter le runner

```bash
./scripts/stop-runner.sh
```

Ou manuellement:
```bash
cd .github-runner
sudo ./svc.sh stop
```

### Redémarrer le runner

```bash
cd .github-runner
sudo ./svc.sh restart
```

### Voir les logs

**Mode systemd:**
```bash
journalctl -u github-runner -f
```

**Mode manuel:**
Les logs s'affichent en temps réel dans le terminal.

### Désinstaller le runner

```bash
cd .github-runner
sudo ./svc.sh uninstall  # Si service systemd
rm -rf .github-runner
```

Puis sur GitHub:
- Repository Settings > Actions > Runners
- Cliquer sur le runner
- Cliquer sur **Remove**

## 📊 Workflow GitHub Actions

Notre workflow utilise le self-hosted runner:

```yaml
jobs:
  deploy:
    runs-on: [self-hosted]  # ← Utilise le runner local

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Deploy application
        run: /deploy.sh "${{ secrets.GIT_REPO }}"

      - name: Health check
        run: curl -f http://localhost:3000
```

### Étapes du workflow

1. **Checkout code** - Clone le repository dans le workspace du runner
2. **Display environment** - Affiche les infos du runner
3. **Deploy application** - Exécute `/deploy.sh`
   - Crée une nouvelle release
   - Clone le repo
   - Installe les dépendances
   - Build l'application
   - Met à jour le symlink
4. **Verify deployment** - Vérifie que la release est bien déployée
5. **Health check** - Vérifie que l'application est accessible
6. **Notify success/failure** - Affiche le résultat

## 🔒 Sécurité

### Tokens

- Le token du runner est stocké dans `~/.github-runner/.credentials`
- Permissions restreintes à ce repository
- Peut être régénéré si compromis

### Communication

- Runner → GitHub: HTTPS sécurisé
- Exécution locale: Pas d'exposition réseau
- Logs: Stockés localement et sur GitHub

### Secrets

```yaml
- name: Deploy
  run: /deploy.sh "${{ secrets.GIT_REPO }}"
  # Les secrets ne sont jamais affichés dans les logs
```

## 🐛 Dépannage

### "Runner not found in GitHub UI"

1. Vérifier que le runner est en cours d'exécution:
   ```bash
   systemctl status github-runner  # ou consulter les logs
   ```

2. Vérifier la configuration:
   ```bash
   cat .github-runner/.runner
   ```

3. Redémarrer:
   ```bash
   ./scripts/start-runner.sh
   ```

### "Job timeout"

- Vérifier que le runner n'est pas bloqué
- Vérifier les logs de déploiement
- Augmenter le timeout dans le workflow

### "Deployment fails"

1. Voir les logs du job GitHub
2. Vérifier que le secret `GIT_REPO` est configuré
3. Vérifier que la clé SSH est correcte:
   ```bash
   ssh -T git@github.com
   ```

   Ou regarder le guide SSH:
   ```bash
   cat .ssh/README.md
   ```

   Pour générer une nouvelle clé:
   ```bash
   ./console ssh-keygen
   ./console export-ssh-key  # Pour mettre à jour .env
   ```

### "Permission denied" sur systemd

Assurez-vous que l'utilisateur peut exécuter `sudo ./svc.sh`:

```bash
# Voir quelle permission est manquante
sudo ./svc.sh install
sudo systemctl status github-runner
```

## 📚 Fichiers associés

- `.github/workflows/deploy.yml` - Workflow GitHub Actions
- `services/web/deploy.sh` - Script de déploiement
- `scripts/setup-runner.sh` - Installation du runner
- `scripts/start-runner.sh` - Démarrage du runner
- `scripts/stop-runner.sh` - Arrêt du runner

## 🔗 Ressources

- [GitHub Actions - Self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
- [GitHub Runner - Documentation](https://github.com/actions/runner)
- [Securing GitHub Actions](https://docs.github.com/en/actions/security-guides)

## ✅ Checklist de déploiement

- [ ] Clés SSH générées: `./console ssh-keygen`
- [ ] Clé publique ajoutée à GitHub (Deploy keys)
- [ ] Clé privée exportée: `./console export-ssh-key`
- [ ] Variable `GIT_SSH_KEY` configurée dans `.env`
- [ ] Runner installé et actif
- [ ] Secret `GIT_REPO` configuré sur GitHub
- [ ] Workflow `.github/workflows/deploy.yml` présent
- [ ] Premiers tests de push sur `main`
- [ ] Health check fonctionne
- [ ] Logs visibles dans GitHub Actions

Vous êtes prêt! 🚀
