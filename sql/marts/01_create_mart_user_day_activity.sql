/*
 * ============================================================================
 * Data Mart: user_day_activity
 * Description: Daily user-level aggregated activity metrics
 * 
 * Business Value:
 * - DAU (Daily Active Users) tracking
 * - Cohort retention analysis
 * - Purchase conversion rates (view-to-cart-to-purchase)
 * - Average revenue per user (ARPU) and daily revenue
 * 
 * Source: events table (raw event stream)
 * Update Strategy: Incremental, month-by-month for performance
 * ============================================================================
 */

-- Create mart table structure
CREATE TABLE user_day_activity (
    dt DATE NOT NULL,           -- Activity date
    user_id BIGINT NOT NULL,    -- User identifier
    events_cnt INTEGER,         -- Total events per user per day
    sessions_cnt INTEGER,       -- Distinct sessions per user per day
    has_purchase SMALLINT,      -- Purchase flag (1 if purchased, 0 otherwise)
    revenue NUMERIC,            -- Daily revenue from user
    PRIMARY KEY (dt, user_id)   -- Ensure unique user-day combinations
);

/*
 * Performance optimization:
 * - Index by date for time-range queries (daily/weekly/monthly reports)
 * - Index by user_id for joins with other marts and user-level analysis
 */
CREATE INDEX idx_uda_dt ON user_day_activity(dt);
CREATE INDEX idx_uda_user ON user_day_activity(user_id);

/*
 * ============================================================================
 * Incremental Load for Specific Month
 * 
 * Why month-by-month approach?
 * - Raw events table contains 700M+ rows → full refresh is too expensive
 * - Allows error isolation and reprocessing of specific periods
 * - Better control over ETL process and monitoring
 * ============================================================================
 */

-- Clean target period (ensures idempotency)
DELETE FROM user_day_activity
WHERE dt >= '2019-11-01'
    AND dt < '2019-12-01';

-- Load monthly aggregated data
INSERT INTO user_day_activity
SELECT
    DATE(event_time) AS dt,                    -- Daily grain
    user_id,
    COUNT(*) AS events_cnt,                     -- Total user activity
    COUNT(DISTINCT user_session) AS sessions_cnt, -- Session count
    MAX(CASE WHEN event_type = 'purchase' 
        THEN 1 ELSE 0 END) AS has_purchase,     -- At least one purchase
    SUM(CASE WHEN event_type = 'purchase' 
        THEN price ELSE 0 END) AS revenue       -- Total purchase value
FROM events 
WHERE event_time >= '2019-11-01'
    AND event_time < '2019-12-01'               -- Monthly filter
GROUP BY 1, 2                                    -- Aggregate by date and user
ON CONFLICT (dt, user_id) DO UPDATE             -- Handle reprocessing safely
SET
    events_cnt = EXCLUDED.events_cnt,
    sessions_cnt = EXCLUDED.sessions_cnt,
    has_purchase = EXCLUDED.has_purchase,
    revenue = EXCLUDED.revenue;

/*
 * Note: ON CONFLICT ensures idempotency - 
 * safe to rerun the same month multiple times
 */