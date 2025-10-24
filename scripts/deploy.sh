#!/bin/bash

set -e

# Script de déploiement sur l'HOST
# Lance le déploiement dans le container web via docker compose exec

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Deploy]${NC} $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Récupérer les paramètres
GIT_REPO="${1:-$GIT_REPO}"
STACK_DIR="${2:-/app/stack}"

if [ -z "$GIT_REPO" ]; then
    error "GIT_REPO non défini"
    echo ""
    echo "Usage: ./scripts/deploy.sh <git-repo-url> [stack-directory]"
    echo "Exemple: ./scripts/deploy.sh git@github.com:username/repo.git /app/stack"
fi

# Vérifier que le compose.yml existe
if [ ! -f "$STACK_DIR/compose.yml" ]; then
    error "compose.yml not found at $STACK_DIR/compose.yml"
fi

log "Vérification que le container est en cours d'exécution..."

# Vérifier que docker compose est disponible
if ! command -v docker compose &> /dev/null; then
    error "docker compose n'est pas installé"
fi

# Vérifier que le container web est en cours d'exécution
if ! docker compose -f "$STACK_DIR/compose.yml" ps web 2>/dev/null | grep -q "web"; then
    error "Le container web n'est pas en cours d'exécution"
    echo ""
    echo "Démarrez-le avec:"
    echo "  cd $STACK_DIR && ./console start"
fi

success "Container web actif"

log "Lancement du déploiement dans le container..."
echo ""

# Exécuter le script de déploiement dans le container
docker compose -f "$STACK_DIR/compose.yml" exec -T web /deploy.sh "$GIT_REPO"

DEPLOY_STATUS=$?

echo ""

if [ $DEPLOY_STATUS -eq 0 ]; then
    success "Déploiement réussi!"

    log "État des releases:"
    docker compose -f "$STACK_DIR/compose.yml" exec -T web ls -la /app/releases | grep -E "^d|^l" || true

    echo ""
    log "Release actuelle:"
    docker compose -f "$STACK_DIR/compose.yml" exec -T web readlink /app/current

    echo ""
    success "L'application a été mise à jour"
else
    error "Le déploiement a échoué (code $DEPLOY_STATUS)"
fi

exit $DEPLOY_STATUS
