/*
 * ============================================================================
 * Analysis: User Age Segments - Impact on DAU and Orders
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Questions:
 * 1. Which user segments contribute most to DAU?
 * 2. How does user "age" affect ordering behavior?
 * 
 * User Age Segments:
 * - '0d': Brand new users (first day)
 * - '1-7d': First week users
 * - '8-30d': First month users
 * - '31+d': Established users
 * 
 * Metrics:
 * - Users count: Size of each segment in DAU
 * - Orders: Total orders from each segment
 * - Orders per user: Purchase frequency by segment
 * ============================================================================
 */

-- Calculate user lifetime and total orders
WITH user_lifetime AS (
    SELECT 
        uda.user_id,
        MAX(uda.dt) - uft.first_touch_date AS lifetime_days,
        SUM(COALESCE(fe.purchase_cnt, 0)) AS orders
    FROM user_day_activity uda
    JOIN user_first_touch uft
        ON uda.user_id = uft.user_id
    LEFT JOIN funnel_events fe
        ON uda.user_id = fe.user_id
        AND uda.dt = fe.dt
    WHERE uda.dt NOT IN (
        '2020-02-27', 
        '2019-11-15', 
        '2020-01-02', 
        '2020-04-20', 
        '2020-04-21'
    )
    GROUP BY
        uda.user_id,
        uft.first_touch_date
),
-- Assign users to age segments based on lifetime
segmented AS (
    SELECT 
        user_id,
        orders,
        CASE
            WHEN lifetime_days = 0 THEN '0d'
            WHEN lifetime_days BETWEEN 1 AND 7 THEN '1-7d'
            WHEN lifetime_days BETWEEN 8 AND 30 THEN '8-30d'
            ELSE '31+d'
        END AS user_age_segment
    FROM user_lifetime
)

-- Segment analysis: size, orders, and average order frequency
SELECT
    user_age_segment,
    COUNT(*) AS users,                    -- Number of users in segment
    SUM(orders) AS total_orders,          -- Total orders from segment
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 
        2
    ) AS users_share_pct,                  -- % of total users
    ROUND(
        SUM(orders)::numeric / NULLIF(COUNT(*), 0),
        4
    ) AS orders_per_user                   -- Average orders per user in segment
FROM segmented
GROUP BY user_age_segment
ORDER BY 
    CASE user_age_segment
        WHEN '0d' THEN 1
        WHEN '1-7d' THEN 2
        WHEN '8-30d' THEN 3
        WHEN '31+d' THEN 4
    END;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * users_share_pct: Which segments dominate daily active users
 * orders_per_user: How purchase behavior matures with user age
 * 
 * Sample Output:
 * | user_age_segment | users | total_orders | users_share_pct | orders_per_user |
 * |------------------|-------|--------------|-----------------|-----------------|
 * |       0d         | 50,000|    2,500     |     25.0%       |     0.05        |
 * |      1-7d        | 40,000|    8,000     |     20.0%       |     0.20        |
 * |      8-30d       | 60,000|   24,000     |     30.0%       |     0.40        |
 * |      31+d        | 50,000|   35,000     |     25.0%       |     0.70        |
 * 
 * Key Insights:
 * - New users (0d) are 25% of DAU but order very little (0.05 per user)
 * - Established users (31+d) are also 25% of DAU but order 14x more (0.70 per user)
 * - Orders_per_user increases with user age → retention drives revenue
 * ============================================================================
 */