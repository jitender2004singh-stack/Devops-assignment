-- 002_add_indexes.sql

-- Supports:
--   SELECT org_id, status, COUNT(*), SUM(amount)
--   FROM hotel_bookings
--   WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
--   GROUP BY org_id, status;
--
--  * city        -> equality filter, so it is the leading column
--  * created_at  -> range filter, so it comes right after the equality column
--  * INCLUDE     -> org_id, status, amount are only *read* by the query (GROUP BY /
--                   aggregates), so they are stored in the index leaf pages. This lets
--                   Postgres answer the query with an Index Only Scan, without
--                   touching the table heap.
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

-- Event lookups are always "all events for a booking".
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id
    ON booking_events (booking_id, created_at);
