/*
 * ============================================================================
 * Analysis: Category Cart Rate - Zero-Day vs Established Users (31+d)
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: What product categories do different user segments add to cart?
 * 
 * Segments:
 * - '0d': Users who never returned after first day
 * - '31+d': Long-term engaged users
 * 
 * Metrics:
 * - users_view: Unique users who viewed the category
 * - users_cart: Unique users who added to cart from this category  
 * - cart_rate: % of viewers who added to cart (conversion by category)
 * 
 * Business Value:
 * - Understand category preferences by user maturity
 * - Identify which categories resonate with new vs loyal users
 * - Optimize category placement and recommendations
 * ============================================================================
 */

-- Get unique user-category interactions (view or cart)
WITH filtered_events AS (
    SELECT DISTINCT
        user_id,
        category_code,
        event_type
    FROM events
    WHERE event_type IN ('view', 'cart')
),
-- Get segment sizes for percentage calculations
segment_size AS (
    SELECT
        user_age_segment,
        COUNT(*) AS users_in_segment
    FROM user_segments
    WHERE user_age_segment IN ('0d', '31+d')
    GROUP BY user_age_segment
)

-- Category performance by segment
SELECT
    us.user_age_segment,
    ss.users_in_segment,
    fe.category_code,
    
    -- User counts at each funnel stage
    COUNT(CASE WHEN fe.event_type = 'view' THEN 1 END) AS users_view,
    COUNT(CASE WHEN fe.event_type = 'cart' THEN 1 END) AS users_cart,
    
    -- Cart rate (conversion from view to cart)
    ROUND(
        100.0 * COUNT(CASE WHEN fe.event_type = 'cart' THEN 1 END) 
        / NULLIF(COUNT(CASE WHEN fe.event_type = 'view' THEN 1 END), 0),
        2
    ) AS cart_rate,
    
    -- Penetration rates (what % of segment viewed/added this category)
    ROUND(
        100.0 * COUNT(CASE WHEN fe.event_type = 'view' THEN 1 END) 
        / ss.users_in_segment,
        2
    ) AS view_penetration_pct,
    
    ROUND(
        100.0 * COUNT(CASE WHEN fe.event_type = 'cart' THEN 1 END) 
        / ss.users_in_segment,
        2
    ) AS cart_penetration_pct
    
FROM filtered_events fe
JOIN user_segments us
    ON fe.user_id = us.user_id
JOIN segment_size ss
    ON us.user_age_segment = ss.user_age_segment
WHERE us.user_age_segment IN ('0d', '31+d')
GROUP BY
    us.user_age_segment,
    ss.users_in_segment,
    fe.category_code
ORDER BY users_view DESC;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * cart_rate: Shows which categories have the strongest "add to cart" appeal
 * view_penetration: Popularity of category (how many users look at it)
 * 
 * Sample Output:
 * | segment | users_in_segment | category_code | users_view | users_cart | cart_rate | view_penetration | cart_penetration |
 * |---------|------------------|---------------|------------|------------|-----------|------------------|------------------|
 * |   0d    |     100,000      | electronics   |  15,000    |   1,500    |  10.0%    |      15.0%       |      1.5%        |
 * |   31+d  |     100,000      | electronics   |  40,000    |  20,000    |  50.0%    |      40.0%       |     20.0%        |
 * |   0d    |     100,000      | fashion       |  10,000    |   2,000    |  20.0%    |      10.0%       |      2.0%        |
 * |   31+d  |     100,000      | fashion       |  25,000    |  15,000    |  60.0%    |      25.0%       |     15.0%        |
 * 
 * Key Insights:
 * 
 * 1. Category Preferences:
 *    - Both segments view electronics most, but 31+d users 2.7x more likely
 *    - Fashion has higher cart rate for both segments
 * 
 * 2. Behavioral Differences:
 *    - 31+d users have 3-5x higher cart rates across categories
 *    - New users show stronger relative preference for fashion (20% vs 10% cart rate)
 * 
 * 3. Actionable Takeaways:
 *    - Feature fashion more prominently for new users (higher relative engagement)
 *    - Electronics needs better conversion optimization for new users (only 10% cart rate)
 *    - 31+d users are "power users" across all categories
 * ============================================================================
 */