# Services

Structure organisée par domaine/service pour une meilleure évolutivité.

## Structure

```
services/
├── web/                    # Service web (Bun + Git)
│   ├── Dockerfile         # Configuration Docker
│   ├── entrypoint.sh      # Script de démarrage
│   └── .dockerignore      # Fichiers à ignorer lors du build
│
├── cloudflare/            # Configuration Cloudflare Tunnel (pas de Dockerfile)
│   └── README.md          # Documentation spécifique
│
└── [autres services]/     # Ajouter d'autres services ici
    ├── Dockerfile
    ├── .dockerignore
    └── README.md
```

## Ajouter un nouveau service

### 1. Créer la structure du service

```bash
mkdir -p services/mon-service
cd services/mon-service
touch Dockerfile .dockerignore README.md
```

### 2. Configurer le Dockerfile

```dockerfile
FROM image-de-base
WORKDIR /app
# Votre configuration...
```

### 3. Ajouter le service au `compose.yml`

```yaml
services:
  mon-service:
    build:
      context: services/mon-service
      dockerfile: Dockerfile
    # Configuration...
    networks:
      - app_network
```

### 4. Documenter dans le README local

Créer un `services/mon-service/README.md` avec les spécificités du service.

## Avantages

✅ Chaque service est isolé et indépendant
✅ Facile d'ajouter/supprimer des services
✅ Structure cohérente et maintenable
✅ `.dockerignore` personnalisé par service
✅ Documentation locale pour chaque service
