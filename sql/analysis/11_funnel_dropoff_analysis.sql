/*
 * ============================================================================
 * Analysis: Funnel Drop-off Analysis - Where do users get lost?
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: At which stage do users abandon the purchase funnel?
 * 
 * Funnel Stages:
 * 1. VIEW → Users view products
 * 2. CART → Users add to cart
 * 3. PURCHASE → Users complete purchase
 * 
 * Drop-off Points:
 * - After view: Viewed but never added to cart
 * - After cart: Added to cart but never purchased
 * ============================================================================
 */

-- Calculate total funnel actions per user
WITH user_funnel AS (
    SELECT
        user_id,
        SUM(view_cnt) AS total_views,
        SUM(cart_cnt) AS total_cart,
        SUM(purchase_cnt) AS total_purchase
    FROM funnel_events 
    WHERE dt NOT IN (
        '2020-02-27',
        '2019-11-15',
        '2020-01-02',
        '2020-04-20',
        '2020-04-21'
    )
    GROUP BY user_id 
),
-- Classify users by their funnel stage
base AS (
    SELECT 
        COUNT(*) AS total_users,
        -- Users who only viewed (never added to cart)
        SUM(CASE 
            WHEN total_views > 0 
            AND total_cart = 0 
            AND total_purchase = 0
            THEN 1
        END) AS dropped_after_view,
        -- Users who added to cart but never purchased
        SUM(CASE
            WHEN total_views > 0
            AND total_cart > 0 
            AND total_purchase = 0
            THEN 1
        END) AS dropped_after_cart,
        -- Users who completed purchase
        SUM(CASE
            WHEN total_views > 0
            AND total_cart > 0 
            AND total_purchase > 0 
            THEN 1
        END) AS purchased
    FROM user_funnel
)

-- Calculate conversion and drop-off rates
SELECT
    total_users,
    
    -- Drop-off rates (from total users)
    ROUND(100.0 * dropped_after_view / total_users, 2) AS view_drop_pct,
    ROUND(100.0 * dropped_after_cart / total_users, 2) AS cart_drop_pct,
    ROUND(100.0 * purchased / total_users, 2) AS purchased_pct,
    
    -- Additional insight: Of users who viewed, what % dropped at cart?
    ROUND(100.0 * dropped_after_cart / NULLIF(dropped_after_view + dropped_after_cart + purchased, 0), 2) AS cart_drop_from_viewers_pct,
    
    -- Conversion rates between stages
    ROUND(100.0 * (dropped_after_cart + purchased) / NULLIF(dropped_after_view + dropped_after_cart + purchased, 0), 2) AS view_to_cart_rate,
    ROUND(100.0 * purchased / NULLIF(dropped_after_cart + purchased, 0), 2) AS cart_to_purchase_rate
    
FROM base;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * view_drop_pct: Users who browse but don't add to cart (interest but no intent)
 * cart_drop_pct: Users who add to cart but abandon (intent but obstacles)
 * 
 * High view_drop_pct → Issues with product appeal/pricing/selection
 * High cart_drop_pct → Issues with checkout process/shipping/payment
 * 
 * Sample Output:
 * | total_users | view_drop_pct | cart_drop_pct | purchased_pct | cart_drop_from_viewers_pct | view_to_cart_rate | cart_to_purchase_rate |
 * |-------------|---------------|---------------|---------------|---------------------------|-------------------|----------------------|
 * |   200,000   |    70.0%      |     20.0%     |    10.0%      |          66.7%            |      30.0%        |        33.3%         |
 * 
 * In this example:
 * - 70% of users never add to cart (biggest drop-off)
 * - Of users who add to cart, only 33.3% complete purchase
 * - Main problem: Getting users to add to cart
 * ============================================================================
 */