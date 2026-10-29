-- Shows the query plan WITHOUT and WITH the index.
-- Run with:  ./scripts/explain.sh

\echo '=== BEFORE: index dropped ==='
DROP INDEX IF EXISTS idx_hotel_bookings_city_created_at;
ANALYZE hotel_bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;

\echo '=== AFTER: index created ==='
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
VACUUM ANALYZE hotel_bookings;

EXPLAIN (ANALYZE, BUFFERS)
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
