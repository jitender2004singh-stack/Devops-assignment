#!/usr/bin/env bash
# Shared settings and helpers. Sourced by the other scripts (not run directly).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Everything below can be overridden from the environment.
DB_SERVICE="${DB_SERVICE:-db}"                      # service name in docker-compose.yml
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-bookings}"                      # source database
RESTORE_DB_NAME="${RESTORE_DB_NAME:-bookings_restore}"  # fresh database used by restore.sh
BACKUP_DIR="${BACKUP_DIR:-backups}"

# Run a command inside the database container (no TTY, so redirects work).
db_exec() {
  docker compose exec -T "$DB_SERVICE" "$@"
}

# Wait until the final Postgres server (TCP, not the init-time one) accepts connections.
wait_for_db() {
  local tries=60
  until db_exec pg_isready -q -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; do
    tries=$((tries - 1))
    if [ "$tries" -le 0 ]; then
      echo "ERROR: database is not ready. Did you run 'docker compose up -d'?" >&2
      exit 1
    fi
    sleep 2
  done
}
