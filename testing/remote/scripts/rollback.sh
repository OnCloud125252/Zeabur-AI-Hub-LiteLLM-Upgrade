#!/usr/bin/env bash
# rollback.sh — Rollback from v1.81.12 to v1.79.0 on the remote server.
#
# Usage:
#   ./deploy/scripts/rollback.sh
#
# This script:
#   1. Stops the v1.81.12 LiteLLM container
#   2. Starts v1.79.0 (database stays as-is — schema is backward-compatible)
#   3. Verifies health

set -euo pipefail

REMOTE="root@10.0.1.9"
REMOTE_DIR="~/litellm-upgrade-test"
HOST="10.0.1.9"
PORT=4000

echo "================================================"
echo "  LiteLLM Rollback: v1.81.12 -> v1.79.0"
echo "  Remote: $REMOTE"
echo "================================================"

echo ""
echo "[1/4] Stopping v1.81.12..."
ssh "$REMOTE" "cd $REMOTE_DIR && docker compose -f docker-compose.base.yml -f docker-compose.v1.81.12.yml stop litellm" 2>/dev/null || true

echo ""
echo "[2/4] Starting v1.79.0..."
ssh "$REMOTE" "cd $REMOTE_DIR && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml --env-file .env up -d"

echo ""
echo "[3/4] Waiting for health check..."
max_attempts=12
attempt=0
while [ $attempt -lt $max_attempts ]; do
  if curl -sf "http://$HOST:$PORT/health/liveliness" > /dev/null 2>&1; then
    echo "  LiteLLM v1.79.0 is healthy!"
    break
  fi
  attempt=$((attempt + 1))
  echo "  Attempt $attempt/$max_attempts — waiting 10s..."
  sleep 10
done

if [ $attempt -eq $max_attempts ]; then
  echo "  WARNING: LiteLLM did not become healthy after $((max_attempts * 10))s"
  echo "  Check logs: ssh $REMOTE 'cd $REMOTE_DIR && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml logs litellm'"
  exit 1
fi

echo ""
echo "[4/4] Quick verification..."
curl -s "http://$HOST:$PORT/health/liveliness"
echo ""

echo ""
echo "================================================"
echo "  Rollback complete!"
echo "  v1.79.0 is running on http://$HOST:$PORT"
echo ""
echo "  Note: The database retains v1.81.12 schema changes."
echo "  These are backward-compatible (all additive)."
echo "================================================"
