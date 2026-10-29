#!/usr/bin/env bash
# Re-runs the seed script against the running database (it empties the tables first).
# The seed also runs automatically the first time `docker compose up` creates the volume.
#
# Usage: ./scripts/seed.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

wait_for_db
db_exec psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -q < db/seed/seed.sql > /dev/null

db_exec psql -U "$DB_USER" -d "$DB_NAME" -c \
  "SELECT (SELECT count(*) FROM hotel_bookings) AS bookings,
          (SELECT count(*) FROM booking_events) AS events,
          (SELECT count(DISTINCT city)   FROM hotel_bookings) AS cities,
          (SELECT count(DISTINCT org_id) FROM hotel_bookings) AS orgs,
          (SELECT count(DISTINCT status) FROM hotel_bookings) AS statuses;"
