# SSH Keys for Deployment

Dossier contenant les clés SSH pour le déploiement.

## Clés générées

### `id_ed25519` (Privée) - ⚠️ CONFIDENTIELLE

- **Algorithme**: Ed25519 (dernière norme cryptographique)
- **Sécurité**: 256-bit, considéré plus sûr que RSA 4096
- **Permissions**: `600` (lecture/écriture pour l'owner uniquement)
- **Usage**: Authentification GitHub/GitLab pour le clone du repo

### `id_ed25519.pub` (Publique)

- **Permissions**: `644` (lisible par tous)
- **Usage**: À ajouter sur GitHub/GitLab en tant que "Deploy Key"

## Génération de la clé

### Utiliser le console manager (recommandé)

```bash
./console ssh-keygen
```

Le script va:
1. Générer la clé SSH Ed25519
2. Afficher la clé publique
3. Vous guider pour l'ajouter à GitHub

### Ou manuellement (alternative)

```bash
ssh-keygen -t ed25519 -C "deployment-key" -f .ssh/id_ed25519 -N ""
```

## Configuration

### 1. Ajouter la clé publique à GitHub

1. Aller sur le repository
2. **Settings** > **Deploy keys** (ou SSH keys)
3. **Add deploy key**
4. Copier le contenu de `id_ed25519.pub`
5. Cocher "Allow write access" si nécessaire

```bash
cat .ssh/id_ed25519.pub
```

### 2. Utiliser la clé privée dans le déploiement

#### Utiliser le console manager (recommandé)

```bash
./console export-ssh-key
```

La commande va:
1. Vérifier que `.env` existe
2. Générer la clé privée au format JSON-escaped
3. Ajouter ou mettre à jour `GIT_SSH_KEY` dans `.env` automatiquement
4. Afficher la valeur pour confirmation

#### Ou manuellement

```bash
# Générer la clé JSON-escaped
GIT_SSH_KEY="$(cat .ssh/id_ed25519 | jq -Rs .)"

# Puis éditer .env et ajouter:
# GIT_SSH_KEY=<la_valeur_affichée>
```

## Sécurité

⚠️ **NE JAMAIS:**
- Commiter `id_ed25519` dans Git
- Partager la clé privée
- Exposer en environnement non sécurisé

✅ **À FAIRE:**
- Garder `id_ed25519` privée (permissions `600`)
- Rotationner les clés régulièrement
- Utiliser des secrets managers en production

## Fingerprint

Après générer la clé SSH, vous verrez un fingerprint unique. Vérifiez ce fingerprint lors de l'ajout à GitHub pour confirmer l'authenticité.

Exemple:
```
SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX deployment-key
```

## Régénérer la clé

### Avec le console manager

```bash
./console ssh-keygen
```

Le script détectera que la clé existe et vous demandera de la régénérer.

### Manuellement

```bash
ssh-keygen -t ed25519 -C "deployment-key" -f .ssh/id_ed25519 -N ""
```

Dans les deux cas, après la régénération:
1. Ajouter la nouvelle clé publique à GitHub
2. Supprimer l'ancienne clé de GitHub
3. Mettre à jour le `.env` avec `./console export-ssh-key`
