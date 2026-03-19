/*
 * ============================================================================
 * Data Mart: funnel_events
 * Description: Daily user-level event funnel for conversion analysis
 * 
 * Business Value:
 * - Conversion funnel analysis (view → cart → purchase)
 * - Drop-off points identification
 * - User behavior patterns across different stages
 * - A/B test performance monitoring
 * 
 * Funnel Stages:
 * 1. VIEW - Product page views (top of funnel)
 * 2. CART - Add to cart actions (consideration stage)
 * 3. PURCHASE - Successful transactions (bottom of funnel)
 * 
 * Source: events table (raw event stream)
 * Update Strategy: Incremental, aligned with user_day_activity mart
 * ============================================================================
 */

-- Create funnel mart with daily user-level aggregations
CREATE TABLE funnel_events AS
SELECT 
    DATE(event_time) AS dt,                    -- Activity date
    user_id,                                    -- User identifier
    SUM(CASE WHEN event_type = 'view' 
        THEN 1 ELSE 0 END) AS view_cnt,        -- Product views count
    SUM(CASE WHEN event_type = 'cart' 
        THEN 1 ELSE 0 END) AS cart_cnt,        -- Add-to-cart actions
    SUM(CASE WHEN event_type = 'purchase' 
        THEN 1 ELSE 0 END) AS purchase_cnt     -- Successful purchases
FROM events
GROUP BY 1, 2;                                   -- Daily user grain

/*
 * Index Strategy:
 * - Index on date for time-based funnel analysis (daily/weekly/monthly trends)
 * - Index on user_id for user-level analysis and joins with other marts
 */
CREATE INDEX idx_fe_dt ON funnel_events(dt);
CREATE INDEX idx_fe_user ON funnel_events(user_id);

/*
 * ============================================================================
 * Usage Examples:
 * 
 * -- 1. Daily Conversion Rates
 * SELECT 
 *     dt,
 *     SUM(view_cnt) AS total_views,
 *     SUM(cart_cnt) AS total_carts,
 *     SUM(purchase_cnt) AS total_purchases,
 *     ROUND(100.0 * SUM(cart_cnt) / NULLIF(SUM(view_cnt), 0), 2) AS view_to_cart_rate,
 *     ROUND(100.0 * SUM(purchase_cnt) / NULLIF(SUM(cart_cnt), 0), 2) AS cart_to_purchase_rate,
 *     ROUND(100.0 * SUM(purchase_cnt) / NULLIF(SUM(view_cnt), 0), 2) AS overall_conversion
 * FROM funnel_events
 * GROUP BY dt
 * ORDER BY dt;
 * 
 * -- 2. User Behavior Segmentation
 * SELECT 
 *     CASE 
 *         WHEN view_cnt > 0 AND cart_cnt = 0 THEN 'view_only'
 *         WHEN cart_cnt > 0 AND purchase_cnt = 0 THEN 'abandoned_cart'
 *         WHEN purchase_cnt > 0 THEN 'converted'
 *         ELSE 'inactive'
 *     END AS user_segment,
 *     COUNT(DISTINCT user_id) AS users_count,
 *     AVG(view_cnt) AS avg_views
 * FROM funnel_events
 * WHERE dt = CURRENT_DATE - 1
 * GROUP BY 1;
 * ============================================================================
 */

/*
 * ============================================================================
 * Incremental Update Pattern (if needed):
 * 
 * DELETE FROM funnel_events WHERE dt >= '2019-11-01' AND dt < '2019-12-01';
 * 
 * INSERT INTO funnel_events
 * SELECT 
 *     DATE(event_time) AS dt,
 *     user_id,
 *     SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS view_cnt,
 *     SUM(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS cart_cnt,
 *     SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_cnt
 * FROM events
 * WHERE event_time >= '2019-11-01' AND event_time < '2019-12-01'
 * GROUP BY 1, 2;
 * ============================================================================
 */