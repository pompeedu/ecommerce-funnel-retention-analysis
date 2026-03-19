/*
 * ============================================================================
 * Analysis: DAU Growth Drivers - New vs Returning Users
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: Who drives DAU growth - new or returning users?
 * 
 * Definitions:
 * - New users: First activity date equals current date
 * - Returning users: Activity date > first touch date
 * 
 * Source Tables:
 * - user_day_activity: Daily user activity
 * - user_first_touch: User acquisition dates
 * ============================================================================
 */

WITH daily_user_classification AS (
    -- Classify each user activity as new or returning
    SELECT
        uda.dt,
        COUNT(DISTINCT CASE 
            WHEN uda.dt = uft.first_touch_date THEN uda.user_id
        END) AS new_users,
        COUNT(DISTINCT CASE 
            WHEN uda.dt > uft.first_touch_date THEN uda.user_id
        END) AS returning_users
    FROM user_day_activity uda
    JOIN user_first_touch uft
        ON uda.user_id = uft.user_id
    WHERE uda.dt NOT IN (
        '2020-02-27',   -- Anomaly: data inconsistency
        '2019-11-15',   -- Anomaly: data inconsistency  
        '2020-01-02',   -- Anomaly: data inconsistency
        '2020-04-20',   -- Anomaly: data inconsistency
        '2020-04-21'    -- Anomaly: data inconsistency
    )
    GROUP BY uda.dt
)

-- Aggregate to see overall contribution
SELECT
    SUM(new_users) + SUM(returning_users) AS total_dau,
    SUM(new_users) AS total_new_users,
    SUM(returning_users) AS total_returning_users,
    ROUND(
        100.0 * SUM(new_users) / NULLIF(SUM(new_users) + SUM(returning_users), 0), 
        2
    ) AS new_users_pct,
    ROUND(
        100.0 * SUM(returning_users) / NULLIF(SUM(new_users) + SUM(returning_users), 0), 
        2
    ) AS returning_users_pct
FROM daily_user_classification;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * If new_users_pct > 50%: Growth is acquisition-driven
 * If returning_users_pct > 50%: Growth is retention-driven
 * 
 * Sample Output:
 * | total_dau | total_new_users | total_returning_users | new_users_pct | returning_users_pct |
 * |-----------|-----------------|----------------------|---------------|-------------------|
 * | 1,500,000 |     450,000     |      1,050,000       |    30.0%      |      70.0%        |
 * 
 * In this example: Growth is primarily driven by returning users (70%)
 * ============================================================================
 */