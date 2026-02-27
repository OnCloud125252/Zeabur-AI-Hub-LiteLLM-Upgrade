#!/usr/bin/env bash
# migrate.sh — Run database migrations on the remote server.
#
# Usage:
#   ./deploy/scripts/migrate.sh [phase_a|phase_b|all]
#
# Runs the SQL migration scripts against the remote PostgreSQL database.
# Default: run all phases.

set -euo pipefail

REMOTE="root@10.0.1.9"
REMOTE_DIR="~/litellm-upgrade-test"
PHASE="${1:-all}"
DB_CONTAINER="litellm-upgrade-test-db-1"

echo "================================================"
echo "  LiteLLM Database Migration"
echo "  Remote: $REMOTE"
echo "  Phase: $PHASE"
echo "================================================"

# Check DB is running
echo ""
echo "[1/4] Checking database connectivity..."
ssh "$REMOTE" "docker exec $DB_CONTAINER pg_isready -U llmproxy -d litellm" || {
  echo "ERROR: Database is not ready. Start it first:"
  echo "  ssh $REMOTE 'cd $REMOTE_DIR && docker compose -f docker-compose.base.yml up -d'"
  exit 1
}

# Backup
echo ""
echo "[2/4] Creating database backup..."
BACKUP_FILE="litellm_backup_$(date +%Y%m%d_%H%M%S).sql"
ssh "$REMOTE" "docker exec $DB_CONTAINER pg_dump -U llmproxy litellm > $REMOTE_DIR/data/$BACKUP_FILE"
echo "  Backup saved to: $REMOTE_DIR/data/$BACKUP_FILE"

# Run migrations
run_phase_a() {
  echo ""
  echo "[3/4] Running Phase A migration (v1.79.0 -> v1.80.11)..."
  ssh "$REMOTE" "docker exec -i $DB_CONTAINER psql -U llmproxy -d litellm" \
    < "$(cd "$(dirname "$0")/.." && pwd)/migrations/migration_phase_a.sql"
  echo "  Phase A complete."
}

run_phase_b() {
  echo ""
  echo "[3/4] Running Phase B migration (v1.80.11 -> v1.81.12)..."
  ssh "$REMOTE" "docker exec -i $DB_CONTAINER psql -U llmproxy -d litellm" \
    < "$(cd "$(dirname "$0")/.." && pwd)/migrations/migration_phase_b.sql"
  echo "  Phase B complete."
}

case "$PHASE" in
  phase_a)
    run_phase_a
    ;;
  phase_b)
    run_phase_b
    ;;
  all)
    run_phase_a
    run_phase_b
    ;;
  *)
    echo "ERROR: Unknown phase '$PHASE'. Use: phase_a, phase_b, or all"
    exit 1
    ;;
esac

# Verify
echo ""
echo "[4/4] Verifying migration..."
echo "  Table count:"
ssh "$REMOTE" "docker exec $DB_CONTAINER psql -U llmproxy -d litellm -c \"SELECT count(*) AS table_count FROM information_schema.tables WHERE table_schema = 'public';\""

echo ""
echo "  Checking new tables exist..."
for table in "LiteLLM_AgentsTable" "LiteLLM_DailyOrganizationSpend" "LiteLLM_DeletedTeamTable" "LiteLLM_PolicyTable" "LiteLLM_AccessGroupTable"; do
  result=$(ssh "$REMOTE" "docker exec $DB_CONTAINER psql -U llmproxy -d litellm -tAc \"SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = '$table');\"")
  if [ "$result" = "t" ]; then
    echo "    $table: exists"
  else
    echo "    $table: MISSING"
  fi
done

echo ""
echo "================================================"
echo "  Migration complete!"
echo "  Backup at: $REMOTE_DIR/data/$BACKUP_FILE"
echo "================================================"
