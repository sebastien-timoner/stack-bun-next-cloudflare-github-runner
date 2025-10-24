# Service Cloudflare Tunnel

Service de tunnel Cloudflare pour exposer l'application web de manière sécurisée.

## Fonctionnalités

- 🌐 Tunnel Cloudflare officiel
- 🔒 HTTPS automatique
- 🛡️ Protection DDoS
- 📡 Pas d'exposition de port locale
- ⚡ Connection directe vers le service web

## Configuration

### Variables d'environnement

- `TUNNEL_TOKEN`: Token du tunnel Cloudflare (obligatoire)

### Obtenir le token

1. Aller sur [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Sélectionner votre domaine
3. Naviguer vers **Networks > Tunnels**
4. Créer un nouveau tunnel
5. Copier le **Tunnel Token**
6. Ajouter à `.env`:
   ```env
   CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX...
   ```

## Configuration du routage

Dans le Dashboard Cloudflare:

1. Sélectionner le tunnel créé
2. Aller dans l'onglet **Public Hostname**
3. Ajouter une nouvelle route:
   - **Domain**: `yourdomain.com` (ou subdomain)
   - **Service**: `http://web:3000`

## Dépannage

### Vérifier les logs du tunnel

```bash
./console logs cloudflare
```

### Erreurs courantes

**"Failed to connect to tunnel"**
- Vérifier que le token est correct
- Vérifier que le tunnel est activé dans Cloudflare

**"Cannot reach service"**
- Vérifier que le container web est en cours d'exécution
- Vérifier la configuration du routage dans Cloudflare
