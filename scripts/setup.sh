#!/usr/bin/env bash
# setup.sh — Bootstrap the Jenkins + Minikube CI/CD environment.
# Usage: ./scripts/setup.sh

set -euo pipefail

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ---------- Prerequisite checks ----------
info "Checking prerequisites..."

command -v docker   >/dev/null 2>&1 || error "Docker is not installed. Install Docker Desktop: https://docs.docker.com/desktop/"
command -v minikube >/dev/null 2>&1 || error "Minikube is not installed. Install: https://minikube.sigs.k8s.io/docs/start/"
command -v kubectl  >/dev/null 2>&1 || error "kubectl is not installed. Install: https://kubernetes.io/docs/tasks/tools/"

# Verify Docker daemon is running
docker info >/dev/null 2>&1 || error "Docker daemon is not running. Start Docker Desktop first."

info "All prerequisites met ✓"

# ---------- Start Minikube ----------
info "Starting Minikube with insecure registry (localhost:5000)..."

if minikube status --format='{{.Host}}' 2>/dev/null | grep -q "Running"; then
    warn "Minikube is already running. Skipping start."
else
    minikube start \
        --driver=docker \
        --insecure-registry="localhost:5000" \
        --cpus=2 \
        --memory=4096
fi

info "Minikube is running ✓"

# ---------- Start Docker Compose (Jenkins + Registry) ----------
info "Starting Jenkins and Docker Registry..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Detect macOS AirPlay Receiver conflict on port 5000
REGISTRY_PORT=5000
if lsof -i :5000 >/dev/null 2>&1; then
    warn "Port 5000 is in use (macOS AirPlay Receiver?)."
    warn "Using port 5001 for the Docker registry instead."
    warn "To free port 5000: System Settings → General → AirDrop & Handoff → AirPlay Receiver → Off"
    export REGISTRY_PORT=5001
fi

docker compose -f "$PROJECT_DIR/docker-compose.yml" up -d --build

# ---------- Wait for Jenkins ----------
info "Waiting for Jenkins to be ready (this may take 1-2 minutes on first run)..."

JENKINS_URL="http://localhost:8080"
MAX_ATTEMPTS=60
ATTEMPT=0

until curl -sf "$JENKINS_URL/login" >/dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
        error "Jenkins did not become ready within ${MAX_ATTEMPTS}s. Check: docker logs jenkins"
    fi
    sleep 2
done

info "Jenkins is ready ✓"

# ---------- Print access info ----------
echo ""
echo "=============================================="
echo "  🚀 CI/CD Environment Ready!"
echo "=============================================="
echo ""
echo "  Jenkins UI:      ${JENKINS_URL}"
echo "  Registry:        http://localhost:${REGISTRY_PORT}"
echo "  Minikube IP:     $(minikube ip)"
echo ""

# Print initial admin password if it exists
ADMIN_PASS=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || true)
if [ -n "$ADMIN_PASS" ]; then
    echo "  Jenkins Password: ${ADMIN_PASS}"
    echo ""
fi

echo "  Next steps:"
echo "    1. Open Jenkins at ${JENKINS_URL}"
echo "    2. Create a Pipeline job pointing to this repo"
echo "    3. Run the pipeline!"
echo ""
echo "  Tear down: ./scripts/teardown.sh"
echo "=============================================="
