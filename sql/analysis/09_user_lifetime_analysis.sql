/*
 * ============================================================================
 * Analysis: User Lifetime Analysis - How long do users stay active?
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: What's the typical lifespan of a user from first to last activity?
 * 
 * Definition:
 * - Lifetime = days between first and last activity
 * - User is considered "active" during this period
 * 
 * Note: This doesn't mean continuous activity - just the span between first and last visit
 * ============================================================================
 */

-- Calculate lifetime for each user
WITH user_lifetime AS (
    SELECT
        uda.user_id,
        MIN(uda.dt) AS first_visit,
        MAX(uda.dt) AS last_visit,
        MAX(uda.dt) - MIN(uda.dt) AS lifetime_days
    FROM user_day_activity uda
    WHERE uda.dt NOT IN (
        '2020-02-27',
        '2019-11-15',
        '2020-01-02',
        '2020-04-20',
        '2020-04-21'
    )
    GROUP BY uda.user_id
)

-- Aggregate statistics
SELECT
    COUNT(*) AS total_users,
    ROUND(AVG(lifetime_days), 2) AS avg_lifetime_days,
    MIN(lifetime_days) AS min_lifetime_days,
    MAX(lifetime_days) AS max_lifetime_days
FROM user_lifetime;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * avg_lifetime_days: How long users typically stay engaged
 * min_lifetime_days: Should be 0 (one-day users)
 * max_lifetime_days: Maximum observed lifespan
 * 
 * Sample Output:
 * | total_users | avg_lifetime_days | min_lifetime_days | max_lifetime_days |
 * |-------------|-------------------|-------------------|-------------------|
 * |   500,000   |       12.5        |        0          |       180         |
 * 
 * In this example: Average user engages over ~12.5 days, some stay 6 months
 * ============================================================================
 */

/*
 * ============================================================================
 * Bonus: Lifetime Distribution (for deeper analysis)
 * 
 * SELECT
 *     CASE
 *         WHEN lifetime_days = 0 THEN '1 day only'
 *         WHEN lifetime_days <= 7 THEN '2-7 days'
 *         WHEN lifetime_days <= 30 THEN '8-30 days'
 *         WHEN lifetime_days <= 90 THEN '31-90 days'
 *         ELSE '90+ days'
 *     END AS lifetime_segment,
 *     COUNT(*) AS users_count,
 *     ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_users
 * FROM user_lifetime
 * GROUP BY 1
 * ORDER BY 
 *     CASE lifetime_segment
 *         WHEN '1 day only' THEN 1
 *         WHEN '2-7 days' THEN 2
 *         WHEN '8-30 days' THEN 3
 *         WHEN '31-90 days' THEN 4
 *         ELSE 5
 *     END;
 * ============================================================================
 */