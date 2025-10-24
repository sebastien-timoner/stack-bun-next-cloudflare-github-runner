#!/bin/sh

set -e

# Script de déploiement sans downtime
# Utilise le système de releases avec symlinks

RELEASES_DIR="/app/releases"
CURRENT_LINK="/app/current"
MAX_RELEASES=4
GIT_REPO="${1:-$GIT_REPO}"

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

# Créer le répertoire de la nouvelle release
get_next_release_number() {
    if [ ! -d "$RELEASES_DIR" ]; then
        echo "1"
        return
    fi

    max=0
    for dir in "$RELEASES_DIR"/*; do
        if [ -d "$dir" ]; then
            num=$(basename "$dir")
            # Vérifier que c'est un nombre
            if echo "$num" | grep -qE '^[0-9]+$'; then
                if [ "$num" -gt "$max" ]; then
                    max=$num
                fi
            fi
        fi
    done

    echo $((max + 1))
}

cleanup_old_releases() {
    log "Nettoyage des anciennes releases..."

    # Lister les releases triées par numéro (décroissant)
    releases=$(find "$RELEASES_DIR" -maxdepth 1 -type d -name '[0-9]*' | sort -rn)
    count=0

    for release_dir in $releases; do
        count=$((count + 1))
        release_num=$(basename "$release_dir")

        if [ $count -gt $MAX_RELEASES ]; then
            log "Suppression de la release ${release_num}..."
            rm -rf "$release_dir"
            success "Release ${release_num} supprimée"
        fi
    done
}

# Main deployment process
main() {
    log "Début du déploiement..."

    # Valider GIT_REPO
    if [ -z "$GIT_REPO" ]; then
        error "GIT_REPO non défini"
    fi

    # Créer le répertoire des releases
    mkdir -p "$RELEASES_DIR"

    # Obtenir le numéro de la prochaine release
    NEXT_RELEASE=$(get_next_release_number)
    RELEASE_DIR="$RELEASES_DIR/$NEXT_RELEASE"

    log "Création de la release ${NEXT_RELEASE}..."
    mkdir -p "$RELEASE_DIR"

    # Clone du repo
    log "Clone du repository..."
    git clone "$GIT_REPO" "$RELEASE_DIR" 2>&1 || error "Impossible de cloner le repository"
    success "Repository cloné"

    # Installation des dépendances
    log "Installation des dépendances..."
    cd "$RELEASE_DIR"
    bun install 2>&1 || error "bun install a échoué"
    success "Dépendances installées"

    # Build
    log "Build de l'application..."
    bun run build 2>&1 || error "bun run build a échoué"
    success "Build réussi"

    # Créer/mettre à jour le symlink
    log "Activation de la nouvelle release..."
    rm -f "$CURRENT_LINK"
    ln -s "$RELEASE_DIR" "$CURRENT_LINK" || error "Impossible de créer le symlink"
    success "Symlink créé vers la release ${NEXT_RELEASE}"

    # Tuer le process Bun pour forcer le redémarrage
    log "Redémarrage de l'application..."
    pkill -f "bun start" || true
    success "Application redémarrée"

    # Nettoyage des anciennes releases
    cleanup_old_releases

    log "Déploiement réussi!"
    return 0
}

# Exécution
main "$@"
