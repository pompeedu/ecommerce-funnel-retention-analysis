/*
 * ============================================================================
 * Data Mart: user_first_touch
 * Description: User acquisition tracking - identifies when users first appeared
 * 
 * Business Value:
 * - Cohort analysis foundation (new vs returning users)
 * - User acquisition trends over time
 * - LTV calculation by acquisition cohorts
 * - Activation metrics tracking
 * 
 * Source: events table (raw event stream)
 * Update Strategy: One-time calculation, can be refreshed for new users
 * ============================================================================
 */

-- Create mart with user's first appearance date
CREATE TABLE user_first_touch AS
SELECT
    user_id,
    MIN(DATE(event_time)) AS first_touch_date  -- First date user appeared in system
FROM events
GROUP BY 1;

/*
 * Index Strategy:
 * - Unique index on user_id for fast lookups and joins
 * - Used extensively in cohort queries and user segmentation
 */
CREATE UNIQUE INDEX idx_uft_user ON user_first_touch(user_id);

/*
 * ============================================================================
 * Usage Example: Cohort Retention Query
 * 
 * SELECT 
 *     ft.first_touch_date AS cohort_date,
 *     COUNT(DISTINCT ft.user_id) AS cohort_size,
 *     COUNT(DISTINCT a.user_id) AS users_active_day_7
 * FROM user_first_touch ft
 * LEFT JOIN user_day_activity a 
 *     ON ft.user_id = a.user_id 
 *     AND a.dt = ft.first_touch_date + INTERVAL '7 days'
 * GROUP BY 1;
 * ============================================================================
 */

/*
 * Maintenance Note:
 * For incremental updates (new users only):
 * 
 * INSERT INTO user_first_touch
 * SELECT 
 *     e.user_id,
 *     MIN(DATE(e.event_time))
 * FROM events e
 * LEFT JOIN user_first_touch ft ON e.user_id = ft.user_id
 * WHERE ft.user_id IS NULL  -- Only new users
 * GROUP BY e.user_id;
 */