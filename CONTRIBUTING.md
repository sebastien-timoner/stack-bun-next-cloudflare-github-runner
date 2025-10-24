# Contributing

Merci de votre intérêt pour ce projet ! 🎉

## Comment contribuer

### Signaler un bug 🐛

1. Vérifiez que le bug n'est pas déjà reporté dans [Issues](../../issues)
2. Créez une nouvelle issue avec:
   - **Titre clair**: "Erreur SSH quand GIT_SSH_KEY est vide"
   - **Description**: Reproduire le bug étape par étape
   - **Environnement**: OS, version Docker, version Bun
   - **Logs**: Incluez les erreurs complètes

### Proposer une feature ✨

1. Créez une issue avec `[Feature Request]` dans le titre
2. Décrivez le use case et les avantages
3. Proposez une approche d'implémentation si possible

### Soumettre du code 💻

1. **Fork** le projet
2. **Créez une branche**: `git checkout -b feature/ma-feature`
3. **Commitez vos changements**: `git commit -m "feat: ajouter support X"`
4. **Poussez**: `git push origin feature/ma-feature`
5. **Créez une Pull Request** avec une description claire

### Standards de code

#### Shell Scripts
- Utilisez `set -e` pour arrêter à la première erreur
- Ajoutez des messages d'erreur clairs avec les fonctions `log()`, `success()`, `error()`
- Testez avec `shellcheck` si possible
- Commentez les sections complexes

#### Docker
- Respectez les best practices :
  - Pin les versions d'images (pas de `latest`)
  - Utilisez des utilisateurs non-root
  - Multi-stage builds si nécessaire
  - Minimisez les couches
- Incluez un `.dockerignore` pour chaque service

#### Documentation
- Mettez à jour les README correspondants
- Expliquez les changements de breaking
- Incluez des exemples si une nouvelle feature est ajoutée
- Vérifiez que les liens fonctionnent

#### Commits
Suivez ce format:
- `fix: corriger bug SSH`
- `feat: ajouter support pour...`
- `docs: mettre à jour README`
- `refactor: réorganiser deploy.sh`

### Avant de soumettre

- [ ] Les tests passent (si applicable)
- [ ] Le code est bien commenté
- [ ] Les README sont à jour
- [ ] Pas de secrets en dur (tokens, clés, IPs)
- [ ] Les scripts shell passent `shellcheck`

## Questions ?

- 📖 Consultez la [documentation](README.md)
- 🐛 Cherchez dans les [Issues existantes](../../issues)
- 💬 Créez une [Discussion](../../discussions)

## Licence

En contribuant, vous acceptez que votre code soit sous licence MIT.

---

Merci d'avoir contribué ! ❤️
