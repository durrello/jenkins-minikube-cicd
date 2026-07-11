#!/usr/bin/env bash
# teardown.sh — Stop and clean up the CI/CD environment.
# Usage: ./scripts/teardown.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# ---------- Stop Docker Compose ----------
info "Stopping Jenkins and Registry..."
docker compose -f "$PROJECT_DIR/docker-compose.yml" down --volumes --remove-orphans 2>/dev/null || warn "Docker Compose already stopped."

# ---------- Delete Minikube ----------
info "Deleting Minikube cluster..."
minikube delete 2>/dev/null || warn "Minikube already deleted."

# ---------- Done ----------
echo ""
info "✅ Environment torn down. All resources cleaned up."
echo ""
echo "  To start fresh: ./scripts/setup.sh"
