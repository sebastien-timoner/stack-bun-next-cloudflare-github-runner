# Templates

Ce dossier contient des exemples de configuration à adapter pour votre projet.

## Structure attendue

Quand vous utilisez cette stack pour déployer votre application, vous devez créer la structure suivante dans **le dépôt** de l'app :

```
votre-app/
├── .github/
│   └── workflows/
│       └── deploy.yml
└── ...
```

## Comment utiliser les templates

1. Copiez `_templates/.github/workflows/deploy.yml.example` vers votre dépôt
2. Créez le fichier `.github/workflows/deploy.yml` dans **votre projet**
3. Adaptez les chemins :
   - Remplacez `/app/your-project` par votre chemin réel depuis la stack
   - Configurez vos secrets GitHub (`GIT_REPO`, etc.)
