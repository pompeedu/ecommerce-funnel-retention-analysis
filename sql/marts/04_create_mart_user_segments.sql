/*
 * ============================================================================
 * Data Mart: user_segments
 * Description: User lifecycle segmentation based on activity history
 * 
 * Business Value:
 * - User lifecycle stage analysis
 * - Segmented marketing campaigns
 * - Behavioral cohort analysis
 * - Churn risk identification
 * 
 * Segmentation Logic:
 * - '0d' : New users (first day, no activity yet)
 * - '31+d' : Engaged users (active for more than a month)
 * - 'other' : Users with 1-30 days lifetime
 * 
 * Source Tables:
 * - user_first_touch: User acquisition dates
 * - user_day_activity: Daily user activity for last activity calculation
 * ============================================================================
 */

-- Create mart structure with proper constraints
CREATE TABLE user_segments (
    user_id BIGINT PRIMARY KEY,           -- User identifier
    lifetime_days INT,                     -- Days between first and last activity
    user_age_segment TEXT                  -- Business segment classification
);

/*
 * Data Quality Note:
 * Excluding specific dates that showed anomalous behavior:
 * - '2020-02-27', '2019-11-15', '2020-01-02', '2020-04-20', '2020-04-21'
 * These dates had data inconsistencies that would skew the analysis
 */

-- Populate segments with cleaned data
INSERT INTO user_segments
SELECT
    t.user_id,
    lifetime_days,
    CASE
        WHEN lifetime_days = 0 THEN '0d'          -- New users, first day
        WHEN lifetime_days >= 31 THEN '31+d'      -- Long-term engaged users
        ELSE 'other'                               -- Mid-term users (1-30 days)
    END AS user_age_segment
FROM (
    -- Calculate user lifetime based on first and last activity
    SELECT
        uft.user_id,
        (uda.last_activity - uft.first_touch_date) AS lifetime_days
    FROM user_first_touch uft
    JOIN (
            -- Get last activity date per user (excluding anomalous dates)
            SELECT
                user_id,
                MAX(dt) AS last_activity
            FROM user_day_activity
            WHERE dt NOT IN (
                '2020-02-27',   -- Anomaly: data inconsistency
                '2019-11-15',   -- Anomaly: data inconsistency  
                '2020-01-02',   -- Anomaly: data inconsistency
                '2020-04-20',   -- Anomaly: data inconsistency
                '2020-04-21'    -- Anomaly: data inconsistency
            )
            GROUP BY user_id
        ) uda
    ON uft.user_id = uda.user_id
) t;

/*
 * Index Strategy:
 * - Primary key on user_id ensures fast lookups
 * - Additional index on segment for cohort analysis and marketing queries
 */
CREATE INDEX idx_user_segments_segment 
ON user_segments(user_age_segment);

/*
 * ============================================================================
 * Usage Examples:
 * 
 * -- 1. Segment Distribution Analysis
 * SELECT 
 *     user_age_segment,
 *     COUNT(*) AS users_count,
 *     ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
 *     AVG(lifetime_days) AS avg_lifetime_days
 * FROM user_segments
 * GROUP BY user_age_segment
 * ORDER BY 
 *     CASE user_age_segment
 *         WHEN '0d' THEN 1
 *         WHEN 'other' THEN 2 
 *         WHEN '31+d' THEN 3
 *     END;
 * 
 * -- 2. Segment Performance Analysis (with funnel data)
 * SELECT 
 *     s.user_age_segment,
 *     AVG(f.view_cnt) AS avg_views,
 *     AVG(f.cart_cnt) AS avg_carts,
 *     AVG(f.purchase_cnt) AS avg_purchases,
 *     ROUND(100.0 * SUM(f.purchase_cnt) / NULLIF(SUM(f.view_cnt), 0), 2) AS conversion_rate
 * FROM user_segments s
 * LEFT JOIN funnel_events f ON s.user_id = f.user_id
 * WHERE f.dt >= CURRENT_DATE - 30
 * GROUP BY s.user_age_segment;
 * 
 * -- 3. Marketing Target Selection
 * SELECT 
 *     user_id,
 *     lifetime_days,
 *     user_age_segment
 * FROM user_segments
 * WHERE user_age_segment IN ('0d', 'other')  -- Focus on newer users for activation campaigns
 * ORDER BY lifetime_days DESC;
 * ============================================================================
 */

/*
 * Maintenance Note:
 * For regular updates, consider creating a stored procedure:
 * 
 * CREATE OR REPLACE FUNCTION refresh_user_segments()
 * RETURNS void AS $$
 * BEGIN
 *     TRUNCATE user_segments;
 *     INSERT INTO user_segments ... (the query above)
 * END;
 * $$ LANGUAGE plpgsql;
 */