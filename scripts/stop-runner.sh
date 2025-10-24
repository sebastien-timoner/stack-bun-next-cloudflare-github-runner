#!/bin/bash

set -e

# Script pour arrêter le self-hosted runner GitHub

RUNNER_DIR="${1:-.github-runner}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Runner]${NC} $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Vérifier que le répertoire du runner existe
if [ ! -d "$RUNNER_DIR" ]; then
    error "Le répertoire du runner '$RUNNER_DIR' n'existe pas"
fi

log "Vérification du statut du service..."

# Vérifier si le service systemd est actif
if systemctl is-active --quiet github-runner 2>/dev/null; then
    log "Arrêt du service systemd..."
    sudo $RUNNER_DIR/svc.sh stop || error "L'arrêt du service a échoué"
    success "Service arrêté"

    # Vérifier l'arrêt
    sleep 1
    if ! systemctl is-active --quiet github-runner 2>/dev/null; then
        success "Service désactivé"
    else
        error "Le service n'a pas pu être arrêté"
    fi
else
    log "Le service systemd n'est pas actif"
    echo "Pour arrêter le runner en mode manuel, appuyez sur Ctrl+C"
fi
