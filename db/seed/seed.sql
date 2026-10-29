-- seed.sql
-- Generates 10,000 bookings (change the 10000 below for more/less) across
-- 6 cities, 5 organisations and 4 statuses, plus booking events.
-- Safe to re-run: it empties the tables first.

SELECT setseed(0.42);  -- repeatable cities/amounts/statuses (UUIDs are always random)

TRUNCATE booking_events, hotel_bookings RESTART IDENTITY;

INSERT INTO hotel_bookings
    (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT
    gen_random_uuid(),
    (ARRAY[
        '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222',
        '33333333-3333-3333-3333-333333333333',
        '44444444-4444-4444-4444-444444444444',
        '55555555-5555-5555-5555-555555555555'
    ])[1 + floor(random() * 5)::int]::uuid,
    'hotel_' || lpad((1 + floor(random() * 40)::int)::text, 3, '0'),
    s.city,
    s.created_at::date + s.lead_days,
    s.created_at::date + s.lead_days + s.nights,
    round((s.nights * (2000 + random() * 8000))::numeric, 2),
    s.status,
    s.created_at
FROM (
    SELECT
        (ARRAY['delhi', 'mumbai', 'bangalore', 'goa', 'chennai', 'hyderabad'])
            [1 + floor(random() * 6)::int]                              AS city,
        (ARRAY['confirmed', 'pending', 'cancelled', 'completed'])
            [1 + floor(random() * 4)::int]                              AS status,
        (NOW() - make_interval(days => floor(random() * 90)::int,
                               secs => floor(random() * 86400)::int))::timestamp AS created_at,
        (1 + floor(random() * 30))::int                                 AS lead_days,
        (1 + floor(random() * 5))::int                                  AS nights
    FROM generate_series(1, 10000)
) AS s;

-- Every booking gets a "booking_created" event.
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'booking_created',
       jsonb_build_object(
           'source', (ARRAY['web', 'mobile', 'api'])[1 + floor(random() * 3)::int],
           'amount', amount
       ),
       created_at
FROM hotel_bookings;

-- Confirmed / completed bookings were paid.
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'payment_received',
       jsonb_build_object(
           'method', (ARRAY['card', 'upi', 'netbanking'])[1 + floor(random() * 3)::int],
           'amount', amount
       ),
       created_at + INTERVAL '5 minutes'
FROM hotel_bookings
WHERE status IN ('confirmed', 'completed');

-- Cancelled bookings carry a cancellation reason.
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'booking_cancelled',
       jsonb_build_object(
           'reason', (ARRAY['customer_request', 'payment_failed', 'hotel_unavailable'])[1 + floor(random() * 3)::int]
       ),
       created_at + INTERVAL '1 hour'
FROM hotel_bookings
WHERE status = 'cancelled';

-- Completed stays get a check-out event.
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'checked_out',
       '{}'::jsonb,
       checkout_date::timestamp + TIME '11:00'
FROM hotel_bookings
WHERE status = 'completed';

-- Refresh planner statistics and the visibility map (needed for index-only scans).
VACUUM ANALYZE hotel_bookings;
VACUUM ANALYZE booking_events;
