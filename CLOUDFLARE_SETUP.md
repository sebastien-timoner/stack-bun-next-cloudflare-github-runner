# Configuration Cloudflare Tunnel

## Prérequis

- Un compte Cloudflare
- Un domaine configuré sur Cloudflare

## Étapes de configuration

### 1. Créer un tunnel Cloudflare

```bash
# Via Cloudflare Dashboard
# 1. Aller sur https://dash.cloudflare.com
# 2. Sélectionner votre domaine
# 3. Aller dans "Networks" -> "Tunnels"
# 4. Créer un nouveau tunnel
```

### 2. Configurer le tunnel

1. Une fois le tunnel créé, Cloudflare vous fournira un **Tunnel Token**
2. Copier le token et l'ajouter à votre fichier `.env`:

```env
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX...
```

### 3. Configurer la route publique

Dans le Dashboard Cloudflare:

1. Aller sur le tunnel créé
2. Dans l'onglet "Public Hostname", ajouter une nouvelle route:
   - **Domain**: `yourdomain.com` (ou subdomain)
   - **Service**: `http://web:3000` (le container web sur le port 3000)

### 4. Démarrer les containers

```bash
./console start
# ou
./console up
```

L'application sera accessible via votre domaine Cloudflare!

## Avantages du setup

✅ Pas d'exposition du port 3000 localement
✅ HTTPS automatique fourni par Cloudflare
✅ Protection DDoS incluse
✅ Flexible et sécurisé

## Dépannage

### Le tunnel ne se connecte pas

```bash
./console logs cloudflare
```

Vérifiez que:
- Le token dans `.env` est correct
- Le tunnel est activé dans Cloudflare Dashboard
- La route publique est configurée

### Réinitialiser le tunnel

```bash
./console clean
# Recréer un nouveau tunnel dans Cloudflare et mettre à jour le token
```
