/*
 * ============================================================================
 * Analysis: Purchase Behavior - New vs Returning Users
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Questions:
 * 1. Who makes orders? (new vs returning users)
 * 2. Who orders more frequently?
 * 
 * Metrics:
 * - Number of users who purchased (by type)
 * - Number of orders (by type)  
 * - Average orders per user (by type)
 * 
 * User Classification:
 * - 'new': Purchase on first touch date
 * - 'returning': Purchase after first touch date
 * ============================================================================
 */

-- Classify purchasing users
WITH base AS (
    SELECT
        fe.dt,
        fe.user_id,
        fe.purchase_cnt,
        CASE
            WHEN fe.dt = uft.first_touch_date THEN 'new'
            ELSE 'returning'
        END AS user_type
    FROM funnel_events fe
    JOIN user_first_touch uft
        ON fe.user_id = uft.user_id
    WHERE fe.purchase_cnt > 0 
        AND fe.dt NOT IN (
            '2020-02-27', '2019-11-15', '2020-01-02', 
            '2020-04-20', '2020-04-21'
        )
), 
-- Daily aggregations by user type
daily_stats AS (
    SELECT 
        dt,
        COUNT(DISTINCT CASE WHEN user_type = 'new' THEN user_id END) AS new_users,
        COUNT(DISTINCT CASE WHEN user_type = 'returning' THEN user_id END) AS returning_users,
        SUM(CASE WHEN user_type = 'new' THEN purchase_cnt ELSE 0 END) AS new_orders,
        SUM(CASE WHEN user_type = 'returning' THEN purchase_cnt ELSE 0 END) AS returning_orders
    FROM base 
    GROUP BY dt
),
-- Daily order frequency by user type
main AS (
    SELECT
        dt,
        new_users,
        NULLIF(returning_users, 0) AS returning_users,
        new_orders,
        NULLIF(returning_orders, 0) AS returning_orders,
        new_orders::float / NULLIF(new_users, 0) AS orders_per_new_user,
        returning_orders::float / NULLIF(returning_users, 0) AS orders_per_returning_user
    FROM daily_stats
)

-- Final aggregated results
SELECT
    SUM(new_users) + SUM(returning_users) AS total_ordered_users,
    SUM(new_users) AS total_new_users,
    SUM(returning_users) AS total_returning_users,
    SUM(new_orders) AS total_new_orders,
    SUM(returning_orders) AS total_returning_orders,
    SUM(new_orders)::float / NULLIF(SUM(new_users), 0) AS avg_orders_per_new_user,
    SUM(returning_orders)::float / NULLIF(SUM(returning_users), 0) AS avg_orders_per_returning_user
FROM main;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * Compare avg_orders_per_new_user vs avg_orders_per_returning_user
 * - If returning_user ratio is higher: Loyal customers drive order volume
 * - If similar: New users convert well on first purchase
 * - If new_user ratio is higher: Strong first-purchase motivation (discounts?)
 * 
 * Sample Output:
 * | total_ordered_users | total_new_users | total_returning_users | total_new_orders | total_returning_orders | avg_orders_per_new_user | avg_orders_per_returning_user |
 * |---------------------|-----------------|----------------------|------------------|----------------------|------------------------|---------------------------|
 * |      250,000        |     100,000     |        150,000       |     120,000      |        450,000       |          1.2           |            3.0            |
 * 
 * In this example: Returning users order 3x more frequently (3.0 vs 1.2 orders/user)
 * ============================================================================
 */