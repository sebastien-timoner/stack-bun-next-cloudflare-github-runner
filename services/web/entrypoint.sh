#!/bin/sh

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Init]${NC} $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Configurer SSH avec la clé privée
log "Configuration SSH..."

SSH_DIR="$HOME/.ssh"

mkdir -p "$SSH_DIR" || error "Impossible de créer le répertoire SSH"

if [ -z "$GIT_SSH_KEY" ]; then
    error "La variable GIT_SSH_KEY n'est pas définie"
fi

echo "$GIT_SSH_KEY" > "$SSH_DIR/id_ed25519" || error "Impossible d'écrire la clé SSH"
chmod 600 "$SSH_DIR/id_ed25519" || error "Impossible de définir les permissions SSH"

success "SSH configuré"

# Ajouter github.com aux hosts connus
ssh-keyscan -t ed25519 github.com >> "$SSH_DIR/known_hosts" 2>/dev/null

# Vérifier si c'est le premier déploiement
if [ ! -L "/app/current" ]; then
    log "Premier déploiement détecté..."
    /deploy.sh "$GIT_REPO" || error "Le déploiement initial a échoué"
fi

# Boucle infinie pour relancer l'application
log "Démarrage de la boucle de gestion de l'application..."

while true; do
    log "Démarrage de l'application..."
    cd /app/current

    # Démarrer bun start
    bun start

    # Si bun s'arrête, on log et on relance après une pause
    log "L'application s'est arrêtée, redémarrage..."
    sleep 0.5
done
