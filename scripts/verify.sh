#!/bin/bash

set -e

# Script de vérification du déploiement
# Lance les vérifications dans le container web via docker compose exec

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Verify]${NC} $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Récupérer les paramètres
STACK_DIR="${1:-/app/stack}"

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
fi

success "Container web actif"

log "État des releases:"
docker compose -f "$STACK_DIR/compose.yml" exec -T web ls -la /app/releases

echo ""

log "Release actuelle:"
docker compose -f "$STACK_DIR/compose.yml" exec -T web readlink /app/current

success "Vérification terminée"
