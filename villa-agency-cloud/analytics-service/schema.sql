CREATE DATABASE IF NOT EXISTS villa_analytics;

CREATE TABLE IF NOT EXISTS villa_analytics.events
(
    event_time DateTime DEFAULT now(),
    event_type String,
    property_category String,
    page_url String,
    session_id String,
    engagement_value String
)
ENGINE = MergeTree
ORDER BY (event_time, event_type);
