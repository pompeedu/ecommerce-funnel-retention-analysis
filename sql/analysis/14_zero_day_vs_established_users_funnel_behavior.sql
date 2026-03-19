/*
 * ============================================================================
 * Analysis: Funnel Behavior Comparison - Zero-Day vs Established Users (31+d)
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: How do brand new users behave differently from loyal users?
 * 
 * Segments Compared:
 * - '0d': Users who never returned after first day
 * - '31+d': Long-term engaged users (active for over a month)
 * 
 * Metrics:
 * - View %: Percentage of users who viewed products
 * - Cart %: Percentage who added to cart
 * - Purchase %: Percentage who completed purchase
 * 
 * Business Value:
 * - Identify behavioral gaps between new and loyal users
 * - Understand what "successful" user behavior looks like
 * - Set benchmarks for new user activation
 * ============================================================================
 */

-- Calculate user lifetime and funnel metrics
WITH user_lifetime AS (
    SELECT 
        uda.user_id,
        MAX(uda.dt) - uft.first_touch_date AS lifetime_days,
        SUM(COALESCE(fe.purchase_cnt, 0)) AS orders,
        SUM(COALESCE(fe.view_cnt, 0)) AS views,
        SUM(COALESCE(fe.cart_cnt, 0)) AS carts
    FROM user_day_activity uda
    JOIN user_first_touch uft
        ON uda.user_id = uft.user_id
    LEFT JOIN funnel_events fe
        ON uda.user_id = fe.user_id
        AND uda.dt = fe.dt
    WHERE uda.dt NOT IN(
        DATE '2020-02-27', 
        DATE '2019-11-15', 
        DATE '2020-01-02', 
        DATE '2020-04-20', 
        DATE '2020-04-21'
    )
    GROUP BY
        uda.user_id,
        uft.first_touch_date
),
-- Segment users by lifetime
segmented AS (
    SELECT
        user_id,
        orders,
        views,
        carts,
        CASE
            WHEN lifetime_days = 0 THEN '0d'
            WHEN lifetime_days >= 31 THEN '31+d'
            ELSE 'other'
        END AS user_age_segment
    FROM user_lifetime
)

-- Compare funnel participation rates between segments
SELECT
    user_age_segment,
    COUNT(*) AS users,
    
    -- Funnel stage participation rates
    ROUND(100.0 * SUM(CASE WHEN views > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS view_pct,
    ROUND(100.0 * SUM(CASE WHEN carts > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS cart_pct,
    ROUND(100.0 * SUM(CASE WHEN orders > 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS purchase_pct,
    
    -- Conversion rates between stages
    ROUND(100.0 * SUM(CASE WHEN carts > 0 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN views > 0 THEN 1 ELSE 0 END), 0), 2) AS view_to_cart_rate,
    ROUND(100.0 * SUM(CASE WHEN orders > 0 THEN 1 ELSE 0 END) / 
          NULLIF(SUM(CASE WHEN carts > 0 THEN 1 ELSE 0 END), 0), 2) AS cart_to_purchase_rate
    
FROM segmented
WHERE user_age_segment IN ('0d', '31+d')
GROUP BY user_age_segment
ORDER BY user_age_segment;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * Sample Output:
 * | user_age_segment | users  | view_pct | cart_pct | purchase_pct | view_to_cart_rate | cart_to_purchase_rate |
 * |------------------|--------|----------|----------|--------------|-------------------|----------------------|
 * |       0d         | 50,000 |  80.0%   |  15.0%   |    5.0%      |      18.8%        |        33.3%         |
 * |      31+d        | 50,000 |  95.0%   |  70.0%   |   45.0%      |      73.7%        |        64.3%         |
 * 
 * Key Insights:
 * 
 * 1. View Rate:
 *    - 0d: 80% view products → 20% bounce without viewing
 *    - 31+d: 95% view products → almost all engaged users view
 * 
 * 2. Cart Rate:
 *    - 0d: Only 15% add to cart (biggest drop-off)
 *    - 31+d: 70% add to cart (4.7x higher)
 * 
 * 3. Purchase Rate:
 *    - 0d: Only 5% purchase
 *    - 31+d: 45% purchase (9x higher)
 * 
 * 4. Conversion Efficiency:
 *    - View→Cart: 0d (18.8%) vs 31+d (73.7%) → 4x difference
 *    - Cart→Purchase: 0d (33.3%) vs 31+d (64.3%) → 2x difference
 * 
 * Conclusion:
 * - New users struggle most with "add to cart" step
 * - Established users are 4x better at converting views to carts
 * - Once new users add to cart, they still abandon 2x more often
 * ============================================================================
 */