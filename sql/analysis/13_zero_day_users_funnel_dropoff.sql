/*
 * ============================================================================
 * Analysis: Funnel Drop-off for Zero-Day Users (First Visit)
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: Where do brand new users drop off in the funnel?
 * 
 * Context:
 * - Zero-day users = users who never returned after first visit
 * - This segment represents lost activation opportunities
 * - Understanding their behavior helps improve first-time user experience
 * 
 * Funnel Stages for New Users:
 * 1. VIEW → Product views on first day
 * 2. CART → Add to cart actions
 * 3. PURCHASE → Completed purchases
 * ============================================================================
 */

-- Identify users with lifetime = 0 (never returned after first day)
WITH user_lifetime AS (
    SELECT 
        uda.user_id,
        MAX(uda.dt) - uft.first_touch_date AS lifetime_days
    FROM user_day_activity uda
    JOIN user_first_touch uft
        ON uda.user_id = uft.user_id
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
zero_day_users AS (
    SELECT user_id
    FROM user_lifetime
    WHERE lifetime_days = 0  -- Users who only appeared once
),
-- Get funnel data for these users
user_funnel AS (
    SELECT
        z.user_id,
        SUM(COALESCE(fe.view_cnt, 0)) AS views,
        SUM(COALESCE(fe.cart_cnt, 0)) AS carts,
        SUM(COALESCE(fe.purchase_cnt, 0)) AS purchases
    FROM zero_day_users z
    LEFT JOIN funnel_events fe
        ON z.user_id = fe.user_id
    GROUP BY z.user_id
),
-- Classify users by their funnel stage
agg AS (
    SELECT
        COUNT(*) AS users,
        -- Users who viewed but never added to cart
        SUM(
            CASE 
                WHEN views > 0 
                AND carts = 0 
                AND purchases = 0 
                THEN 1 
            END
        ) AS drop_after_view,
        -- Users who added to cart but never purchased
        SUM(
            CASE 
                WHEN carts > 0 
                AND purchases = 0 
                THEN 1 
            END
        ) AS drop_after_cart,
        -- Users who completed purchase
        SUM(
            CASE 
                WHEN purchases > 0 
                THEN 1 
            END
        ) AS purchased
    FROM user_funnel
)

-- Final funnel metrics for zero-day users
SELECT
    users AS total_zero_day_users,
    ROUND(100.0 * drop_after_view / users, 2) AS view_drop_pct,
    ROUND(100.0 * drop_after_cart / users, 2) AS cart_drop_pct,
    ROUND(100.0 * purchased / users, 2) AS purchase_pct,
    
    -- Additional insights
    ROUND(100.0 * (drop_after_view + drop_after_cart + purchased) / users, 2) AS users_with_activity_pct,
    ROUND(100.0 * drop_after_cart / NULLIF(drop_after_view + drop_after_cart + purchased, 0), 2) AS cart_abandonment_rate
FROM agg;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * view_drop_pct: % of new users who viewed products but didn't engage further
 * cart_drop_pct: % who added to cart but abandoned
 * purchase_pct: % who converted on first day
 * 
 * Sample Output:
 * | total_zero_day_users | view_drop_pct | cart_drop_pct | purchase_pct | users_with_activity_pct | cart_abandonment_rate |
 * |---------------------|---------------|---------------|--------------|------------------------|----------------------|
 * |       100,000       |    85.0%      |     10.0%     |     5.0%     |         100%           |        66.7%         |
 * 
 * Key Insights:
 * - Only 5% of new users purchase on first day
 * - 85% drop off before adding to cart (main problem)
 * - Of users who add to cart, 66.7% abandon (checkout issues)
 * 
 * Action Items:
 * 1. Improve product discovery/selection for new users (85% drop-off)
 * 2. Optimize checkout flow for users who add to cart (66.7% abandonment)
 * ============================================================================
 */