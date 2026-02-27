#!/usr/bin/env bash
# test.sh — Run LiteLLM upgrade verification tests.
#
# Usage:
#   ./deploy/scripts/test.sh <command>
#
# Commands:
#   baseline   — Start v1.79.0 and run baseline tests
#   upgrade    — Stop v1.79.0, migrate DB, start v1.81.12, run tests
#   regression — Run regression tests only (against running proxy)
#   signature  — Run thought_signature tests only (against running proxy)
#   all        — Run full baseline + upgrade + rollback cycle

set -euo pipefail

REMOTE="root@10.0.1.9"
REMOTE_DIR="~/litellm-upgrade-test"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEPLOY_DIR="$PROJECT_ROOT/deploy"
TESTING_DIR="$PROJECT_ROOT/testing"
REPORTS_DIR="$PROJECT_ROOT/reports"
HOST="10.0.1.9"
PORT=4000
COMMAND="${1:-all}"

echo "================================================"
echo "  LiteLLM Upgrade Verification Tests"
echo "  Command: $COMMAND"
echo "  Remote: $REMOTE"
echo "  Test target: http://$HOST:$PORT"
echo "================================================"

wait_for_healthy() {
  local max_attempts=12
  local attempt=0
  echo "  Waiting for LiteLLM to be healthy..."
  while [ $attempt -lt $max_attempts ]; do
    if curl -sf "http://$HOST:$PORT/health/liveliness" > /dev/null 2>&1; then
      echo "  LiteLLM is healthy!"
      return 0
    fi
    attempt=$((attempt + 1))
    echo "  Attempt $attempt/$max_attempts — waiting 10s..."
    sleep 10
  done
  echo "  ERROR: LiteLLM did not become healthy after $((max_attempts * 10))s"
  return 1
}

run_baseline() {
  echo ""
  echo "--- Starting v1.79.0 baseline ---"

  echo "[1/4] Starting v1.79.0..."
  ssh "$REMOTE" "cd $REMOTE_DIR && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml --env-file .env up -d"

  echo "[2/4] Waiting for health check..."
  wait_for_healthy

  echo "[3/4] Running regression tests..."
  cd "$TESTING_DIR"
  python test_regression.py --host "$HOST" --port "$PORT" 2>&1 | tee "$REPORTS_DIR/baseline-v1.79.0.txt" || true

  echo "[4/4] Running thought_signature test..."
  python test_gemini_signature.py --host "$HOST" --port "$PORT" 2>&1 | tee "$REPORTS_DIR/signature-v1.79.0.txt" || true

  echo ""
  echo "Baseline tests complete. Reports in $REPORTS_DIR/"
}

run_upgrade() {
  echo ""
  echo "--- Upgrading to v1.81.12 ---"

  echo "[1/5] Stopping v1.79.0 litellm..."
  ssh "$REMOTE" "cd $REMOTE_DIR && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml stop litellm" || true

  echo "[2/5] Running database migrations..."
  "$DEPLOY_DIR/scripts/migrate.sh" all

  echo "[3/5] Starting v1.81.12..."
  ssh "$REMOTE" "cd $REMOTE_DIR && docker compose -f docker-compose.base.yml -f docker-compose.v1.81.12.yml --env-file .env up -d"

  echo "[4/5] Waiting for health check..."
  wait_for_healthy

  echo "[5/5] Running tests..."
  cd "$TESTING_DIR"
  echo "  Running regression tests..."
  python test_regression.py --host "$HOST" --port "$PORT" 2>&1 | tee "$REPORTS_DIR/regression-v1.81.12.txt" || true

  echo "  Running thought_signature test..."
  python test_gemini_signature.py --host "$HOST" --port "$PORT" 2>&1 | tee "$REPORTS_DIR/signature-v1.81.12.txt" || true

  echo ""
  echo "Upgrade tests complete. Reports in $REPORTS_DIR/"
}

run_regression() {
  echo ""
  echo "--- Running regression tests only ---"
  cd "$TESTING_DIR"
  python test_regression.py --host "$HOST" --port "$PORT"
}

run_signature() {
  echo ""
  echo "--- Running thought_signature tests only ---"
  cd "$TESTING_DIR"
  python test_gemini_signature.py --host "$HOST" --port "$PORT"
}

run_rollback() {
  echo ""
  echo "--- Rollback test: v1.81.12 -> v1.79.0 ---"

  echo "[1/3] Stopping v1.81.12..."
  ssh "$REMOTE" "cd $REMOTE_DIR && docker compose -f docker-compose.base.yml -f docker-compose.v1.81.12.yml stop litellm" || true

  echo "[2/3] Starting v1.79.0 (with migrated DB)..."
  ssh "$REMOTE" "cd $REMOTE_DIR && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml --env-file .env up -d"

  echo "[3/3] Waiting for health check..."
  wait_for_healthy

  echo "  Running regression tests after rollback..."
  cd "$TESTING_DIR"
  python test_regression.py --host "$HOST" --port "$PORT" 2>&1 | tee "$REPORTS_DIR/rollback-v1.79.0.txt" || true

  echo ""
  echo "Rollback test complete."
}

run_all() {
  run_baseline
  run_upgrade
  run_rollback

  echo ""
  echo "================================================"
  echo "  Full verification cycle complete!"
  echo ""
  echo "  Reports:"
  echo "    $REPORTS_DIR/baseline-v1.79.0.txt"
  echo "    $REPORTS_DIR/regression-v1.81.12.txt"
  echo "    $REPORTS_DIR/signature-v1.79.0.txt"
  echo "    $REPORTS_DIR/signature-v1.81.12.txt"
  echo "    $REPORTS_DIR/rollback-v1.79.0.txt"
  echo "================================================"
}

case "$COMMAND" in
  baseline)   run_baseline ;;
  upgrade)    run_upgrade ;;
  regression) run_regression ;;
  signature)  run_signature ;;
  rollback)   run_rollback ;;
  all)        run_all ;;
  *)
    echo "ERROR: Unknown command '$COMMAND'"
    echo "Usage: $0 {baseline|upgrade|regression|signature|rollback|all}"
    exit 1
    ;;
esac
