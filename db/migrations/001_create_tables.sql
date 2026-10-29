-- 001_create_tables.sql
-- Core schema for the hotel bookings database.

CREATE TABLE IF NOT EXISTS hotel_bookings (
    id            UUID          PRIMARY KEY,
    org_id        UUID          NOT NULL,
    hotel_id      VARCHAR(100)  NOT NULL,
    city          VARCHAR(100)  NOT NULL,
    checkin_date  DATE          NOT NULL,
    checkout_date DATE          NOT NULL,
    amount        NUMERIC(12,2) NOT NULL,
    status        VARCHAR(50)   NOT NULL,
    created_at    TIMESTAMP     NOT NULL
);

CREATE TABLE IF NOT EXISTS booking_events (
    id         BIGSERIAL    PRIMARY KEY,
    booking_id UUID         NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload    JSONB,
    created_at TIMESTAMP    NOT NULL
);
