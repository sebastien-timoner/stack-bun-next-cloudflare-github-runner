#!/bin/bash

set -e

# Script d'installation du self-hosted runner GitHub
# Usage: ./scripts/setup-runner.sh <github-repo-url> <runner-token>

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[Setup]${NC} $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Vérifier les arguments
if [ $# -lt 2 ]; then
    error "Usage: ./scripts/setup-runner.sh <github-repo-url> <runner-token>"
    echo ""
    echo "Exemple: ./scripts/setup-runner.sh https://github.com/username/repo abc123def456"
    echo ""
    echo "Comment obtenir le token:"
    echo "1. Aller sur GitHub Repository Settings"
    echo "2. Actions > Runners > New self-hosted runner"
    echo "3. Copier le token depuis les instructions"
fi

GITHUB_REPO="$1"
RUNNER_TOKEN="$2"
RUNNER_DIR="${3:-.github-runner}"

log "Installation du runner GitHub..."
log "Repository: $GITHUB_REPO"
log "Répertoire: $(pwd)/$RUNNER_DIR"

# Créer le répertoire du runner
if [ ! -d "$RUNNER_DIR" ]; then
    log "Création du répertoire $RUNNER_DIR..."
    mkdir -p "$RUNNER_DIR"
    success "Répertoire créé"
else
    log "Le répertoire $RUNNER_DIR existe déjà"
fi

cd "$RUNNER_DIR"

# Télécharger le runner
log "Téléchargement du runner..."
if [ ! -f "config.sh" ]; then
    # Déterminer l'OS et l'architecture
    OS=$(uname -s)
    ARCH=$(uname -m)

    case "$OS" in
        Linux)
            case "$ARCH" in
                x86_64)
                    RUNNER_FILE="actions-runner-linux-x64"
                    ;;
                aarch64)
                    RUNNER_FILE="actions-runner-linux-arm64"
                    ;;
                *)
                    error "Architecture non supportée: $ARCH"
                    ;;
            esac
            ;;
        Darwin)
            case "$ARCH" in
                x86_64)
                    RUNNER_FILE="actions-runner-osx-x64"
                    ;;
                arm64)
                    RUNNER_FILE="actions-runner-osx-arm64"
                    ;;
                *)
                    error "Architecture non supportée: $ARCH"
                    ;;
            esac
            ;;
        *)
            error "OS non supporté: $OS"
            ;;
    esac

    log "Téléchargement de $RUNNER_FILE..."

    # Obtenir la dernière version
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//')

    if [ -z "$LATEST_RELEASE" ]; then
        error "Impossible de récupérer la version du runner"
    fi

    log "Version du runner: $LATEST_RELEASE"

    curl -s -L \
        "https://github.com/actions/runner/releases/download/v${LATEST_RELEASE}/${RUNNER_FILE}-${LATEST_RELEASE}.tar.gz" \
        -o "runner.tar.gz" || error "Impossible de télécharger le runner"

    tar xzf "runner.tar.gz"
    rm -f "runner.tar.gz"

    success "Runner téléchargé et extrait"
else
    log "Le runner est déjà installé"
fi

# Configurer le runner
log "Configuration du runner..."
./config.sh \
    --url "$GITHUB_REPO" \
    --token "$RUNNER_TOKEN" \
    --name "app-runner-$(hostname)" \
    --work "_work" \
    --replace \
    --unattended \
    || error "La configuration a échoué"

success "Runner configuré avec succès"

# Créer un script de démarrage
log "Création du script de démarrage..."
cat > "start.sh" << 'SCRIPT'
#!/bin/bash
cd "$(dirname "$0")"
./run.sh
SCRIPT
chmod +x "start.sh"
success "Script de démarrage créé"

# Afficher les instructions suivantes
echo ""
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Installation réussie!${NC}"
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo ""
echo "Prochaines étapes:"
echo ""
echo "1. Pour démarrer le runner manuellement:"
echo "   cd $RUNNER_DIR"
echo "   ./run.sh"
echo ""
echo "2. Pour configurer le runner en tant que service systemd:"
echo "   cd $RUNNER_DIR"
echo "   sudo ./svc.sh install"
echo "   sudo ./svc.sh start"
echo ""
echo "3. Ou utiliser le script fourni:"
echo "   ./scripts/start-runner.sh"
echo ""
echo "4. Vérifier que le runner est actif:"
echo "   # GitHub Repository Settings > Actions > Runners"
echo "   # Vous devriez voir 'app-runner-<hostname>' avec le statut 'Idle'"
echo ""
