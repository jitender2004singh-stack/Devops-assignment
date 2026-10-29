#!/usr/bin/env bash
# Creates a timestamped plain-SQL dump of the bookings database in ./backups.
#
# Usage: ./scripts/backup.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

wait_for_db
mkdir -p "$BACKUP_DIR"

FILE="$BACKUP_DIR/${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
trap 'rm -f "$FILE.tmp"' EXIT

echo "Backing up '$DB_NAME' -> $FILE"
db_exec pg_dump -U "$DB_USER" --no-owner --no-privileges "$DB_NAME" > "$FILE.tmp"

# Only publish the file name once the dump finished successfully.
mv "$FILE.tmp" "$FILE"
echo "Backup created: $FILE ($(du -h "$FILE" | cut -f1))"
