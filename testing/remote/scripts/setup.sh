#!/usr/bin/env bash
# setup.sh — Initialize the remote Docker environment for LiteLLM upgrade testing.
#
# Usage (from local machine):
#   ./deploy/scripts/setup.sh
#
# Prerequisites:
#   - SSH access to root@10.0.1.9
#   - VERTEX_API_KEY environment variable set

set -euo pipefail

REMOTE="root@10.0.1.9"
REMOTE_DIR="~/litellm-upgrade-test"
LOCAL_DEPLOY="$(cd "$(dirname "$0")/.." && pwd)"

echo "================================================"
echo "  LiteLLM Upgrade Test — Environment Setup"
echo "  Remote: $REMOTE"
echo "  Deploy dir: $LOCAL_DEPLOY"
echo "================================================"

# --- Verify prerequisites ---
if [ -z "${VERTEX_API_KEY:-}" ]; then
  echo "ERROR: VERTEX_API_KEY is not set."
  echo "  export VERTEX_API_KEY=<your-key>"
  exit 1
fi

echo ""
echo "[1/6] Checking SSH connectivity..."
ssh -o ConnectTimeout=5 "$REMOTE" "echo 'SSH OK'" || {
  echo "ERROR: Cannot SSH to $REMOTE"; exit 1;
}

echo ""
echo "[2/6] Checking Docker on remote..."
ssh "$REMOTE" "docker --version && docker compose version"

echo ""
echo "[3/6] Creating remote directory structure..."
ssh "$REMOTE" "mkdir -p $REMOTE_DIR/{config,migrations,scripts,data,reports}"

echo ""
echo "[4/6] Copying deployment files to remote..."
scp -r "$LOCAL_DEPLOY/docker-compose.base.yml" "$REMOTE:$REMOTE_DIR/"
scp -r "$LOCAL_DEPLOY/docker-compose.v1.79.0.yml" "$REMOTE:$REMOTE_DIR/"
scp -r "$LOCAL_DEPLOY/docker-compose.v1.81.12.yml" "$REMOTE:$REMOTE_DIR/"
scp -r "$LOCAL_DEPLOY/config/config.yaml" "$REMOTE:$REMOTE_DIR/config/"
scp -r "$LOCAL_DEPLOY/migrations/"*.sql "$REMOTE:$REMOTE_DIR/migrations/"
scp -r "$LOCAL_DEPLOY/scripts/"*.sh "$REMOTE:$REMOTE_DIR/scripts/"

echo ""
echo "[5/6] Setting VERTEX_API_KEY on remote..."
ssh "$REMOTE" "cat > $REMOTE_DIR/.env << 'ENVEOF'
VERTEX_API_KEY=${VERTEX_API_KEY}
ENVEOF"

echo ""
echo "[6/6] Pre-pulling Docker images..."
echo "  Pulling postgres:16..."
ssh "$REMOTE" "docker pull postgres:16"
echo "  Pulling redis:7-alpine..."
ssh "$REMOTE" "docker pull redis:7-alpine"
echo "  Pulling litellm v1.79.0-stable..."
ssh "$REMOTE" "docker pull ghcr.io/berriai/litellm:v1.79.0-stable"
echo "  Pulling litellm v1.81.12-stable.1..."
ssh "$REMOTE" "docker pull docker.litellm.ai/berriai/litellm:v1.81.12-stable.1"

echo ""
echo "================================================"
echo "  Setup complete!"
echo ""
echo "  Next steps:"
echo "    1. SSH to remote: ssh $REMOTE"
echo "    2. cd $REMOTE_DIR"
echo "    3. Start baseline: docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml up -d"
echo "    4. Or run: ./deploy/scripts/test.sh baseline"
echo "================================================"
