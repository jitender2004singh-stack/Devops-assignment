#!/usr/bin/env bash
# Prints EXPLAIN ANALYZE for the Delhi report query before and after the index.
# The index is re-created at the end, so the database is left in its normal state.
#
# Usage: ./scripts/explain.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

wait_for_db
db_exec psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 < db/queries/explain_before_after.sql
