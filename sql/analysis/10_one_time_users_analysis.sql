/*
 * ============================================================================
 * Analysis: One-Time Users Analysis - Do users purchase only once?
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: What percentage of users make only a single purchase?
 * 
 * Definition:
 * - One-time users: Users with exactly 1 purchase in their entire history
 * - Multiple purchase users: Users with 2+ purchases
 * 
 * Business Impact:
 * - High % of one-time users → potential issues with retention/product fit
 * - Low % of one-time users → strong repeat purchase behavior
 * ============================================================================
 */

-- Calculate total purchases per user
WITH user_purchases AS (
    SELECT
        user_id,
        SUM(purchase_cnt) AS total_purchases
    FROM funnel_events
    WHERE dt NOT IN (
        '2020-02-27',
        '2019-11-15',
        '2020-01-02',
        '2020-04-20',
        '2020-04-21'
    )
    GROUP BY user_id
)

-- Aggregate to see one-time user percentage
SELECT 
    COUNT(*) AS total_users_with_purchases,
    
    -- Users who purchased exactly once
    COUNT(CASE WHEN total_purchases = 1 THEN 1 END) AS one_time_users,
    
    -- Users who purchased multiple times
    COUNT(CASE WHEN total_purchases > 1 THEN 1 END) AS repeat_users,
    
    -- Percentage of one-time users
    ROUND(
        100.0 * COUNT(CASE WHEN total_purchases = 1 THEN 1 END) 
        / NULLIF(COUNT(*), 0),
        2
    ) AS one_time_users_pct,
    
    -- Average purchases per user (excluding non-purchasers)
    ROUND(AVG(total_purchases), 2) AS avg_purchases_per_user
    
FROM user_purchases
WHERE total_purchases > 0;  -- Only users who actually purchased

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * one_time_users_pct:
 * - < 30%: Healthy repeat purchase behavior
 * - 30-50%: Mixed behavior, room for improvement
 * - > 50%: Potential red flag - users try once and don't return
 * 
 * Sample Output:
 * | total_users_with_purchases | one_time_users | repeat_users | one_time_users_pct | avg_purchases_per_user |
 * |---------------------------|----------------|--------------|-------------------|----------------------|
 * |         100,000           |     65,000     |   35,000     |      65.0%        |         1.8          |
 * 
 * In this example: 65% of users purchase only once, avg 1.8 purchases total
 * ============================================================================
 */