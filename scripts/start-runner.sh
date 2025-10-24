#!/bin/bash

set -e

# Script pour démarrer le self-hosted runner GitHub
# Support pour systemd ou exécution manuelle

RUNNER_DIR="${1:-.github-runner}"
USE_SYSTEMD="${2:-auto}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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
    echo ""
    echo "Commande d'installation:"
    echo "  ./scripts/setup-runner.sh <github-repo-url> <runner-token>"
fi

# Vérifier que le runner est configuré
if [ ! -f "$RUNNER_DIR/.runner" ]; then
    error "Le runner n'est pas configuré"
    echo ""
    echo "Exécutez d'abord:"
    echo "  ./scripts/setup-runner.sh <github-repo-url> <runner-token>"
fi

log "Vérification de systemd..."

# Déterminer si on utilise systemd
HAS_SYSTEMD=$(command -v systemctl &> /dev/null && echo "yes" || echo "no")

if [ "$USE_SYSTEMD" = "auto" ] && [ "$HAS_SYSTEMD" = "yes" ]; then
    USE_SYSTEMD="yes"
elif [ "$USE_SYSTEMD" = "auto" ]; then
    USE_SYSTEMD="no"
fi

if [ "$USE_SYSTEMD" = "yes" ]; then
    log "Démarrage via systemd..."

    cd "$RUNNER_DIR"

    # Installer le service seulement s'il n'existe pas
    if ! systemctl list-unit-files | grep -q "actions.runner"; then
        log "Installation du service systemd..."
        sudo ./svc.sh install || error "L'installation du service a échoué"
        success "Service installé"
    else
        log "Le service systemd existe déjà"
    fi

    # Démarrer le service
    log "Démarrage du service..."
    sudo ./svc.sh start || error "Le démarrage du service a échoué"
    success "Service démarré"

    # Vérifier le statut
    sleep 2
    if systemctl list-units --all | grep -q "actions.runner.*running"; then
        success "Service actif et en cours d'exécution"
    else
        log "Vérification du statut du service..."
        sudo systemctl status actions.runner* --no-pager || true
    fi

else
    log "Démarrage en mode manuel..."

    cd "$RUNNER_DIR"

    # Afficher les informations
    success "Runner en cours d'exécution..."
    echo ""
    echo -e "${YELLOW}Le runner s'exécute au premier plan.${NC}"
    echo "Appuyez sur Ctrl+C pour arrêter."
    echo ""
    echo -e "${BLUE}Attendez les jobs GitHub...${NC}"
    echo ""

    # Démarrer le runner
    ./run.sh
fi
