#!/usr/bin/env bash
# Restores a backup into a FRESH database (bookings_restore) and verifies it
# against the source database.
#
# Usage: ./scripts/restore.sh [path/to/backup.sql]
#        (without an argument the newest file in ./backups is used)
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

FILE="${1:-}"
if [ -z "$FILE" ]; then
  FILE="$(ls -1 "$BACKUP_DIR"/*.sql 2>/dev/null | sort | tail -n 1 || true)"
fi
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "ERROR: no backup file found. Run ./scripts/backup.sh first or pass a file path." >&2
  exit 1
fi

wait_for_db

echo "Restoring $FILE into fresh database '$RESTORE_DB_NAME'"
db_exec psql -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 -q \
  -c "DROP DATABASE IF EXISTS \"$RESTORE_DB_NAME\" WITH (FORCE);"
db_exec psql -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 -q \
  -c "CREATE DATABASE \"$RESTORE_DB_NAME\";"
db_exec psql -U "$DB_USER" -d "$RESTORE_DB_NAME" -v ON_ERROR_STOP=1 -q < "$FILE" > /dev/null

echo
echo "Verifying restore ('$DB_NAME' vs '$RESTORE_DB_NAME'):"

FAILED=0
check() {
  local label="$1" sql="$2" src dst
  src="$(db_exec psql -U "$DB_USER" -d "$DB_NAME" -tAc "$sql")"
  dst="$(db_exec psql -U "$DB_USER" -d "$RESTORE_DB_NAME" -tAc "$sql")"
  if [ "$src" = "$dst" ]; then
    printf '  OK    %-22s %s\n' "$label" "$src"
  else
    printf '  FAIL  %-22s source=%s restored=%s\n' "$label" "$src" "$dst"
    FAILED=1
  fi
}

check "hotel_bookings rows"  "SELECT count(*) FROM hotel_bookings"
check "booking_events rows"  "SELECT count(*) FROM booking_events"
check "total amount"         "SELECT COALESCE(sum(amount), 0) FROM hotel_bookings"
check "booking ids checksum" "SELECT md5(string_agg(id::text, ',' ORDER BY id)) FROM hotel_bookings"
check "index count"          "SELECT count(*) FROM pg_indexes WHERE schemaname = 'public'"

echo
if [ "$FAILED" -eq 0 ]; then
  echo "Restore verified: '$RESTORE_DB_NAME' matches '$DB_NAME'."
else
  echo "Restore verification FAILED (if data changed after the backup was taken, that is expected)." >&2
  exit 1
fi
