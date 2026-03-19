/*
 * ============================================================================
 * Analysis: Cohort Retention Analysis - Do new users come back?
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: What percentage of new users return after 1, 7, and 30 days?
 * 
 * Methodology:
 * - Cohort = users by first touch date
 * - Track their activity on days 0, 1, 7, 30
 * - Calculate retention rate: (users active on day N) / (users in cohort)
 * 
 * Note: Only calculate retention for cohorts that have had time to reach each day
 * (e.g., don't calculate day 30 retention for users who joined 15 days ago)
 * ============================================================================
 */

-- Get max date to determine which cohorts are eligible for each retention period
WITH limits AS (
    SELECT MAX(dt) AS max_dt 
    FROM user_day_activity
),
-- Base data: user activity with day numbers since first touch
base AS (
    SELECT 
        uda.user_id,
        uft.first_touch_date,
        uda.dt,
        uda.dt - uft.first_touch_date AS day_number
    FROM user_day_activity uda
    JOIN user_first_touch uft
        ON uda.user_id = uft.user_id
),
-- Cohort aggregations: count users active on specific days
cohorts AS (
    SELECT
        first_touch_date,
        COUNT(DISTINCT CASE WHEN day_number = 0 THEN user_id END) AS users_d0,
        COUNT(DISTINCT CASE WHEN day_number = 1 THEN user_id END) AS users_d1,
        COUNT(DISTINCT CASE WHEN day_number = 7 THEN user_id END) AS users_d7,
        COUNT(DISTINCT CASE WHEN day_number = 30 THEN user_id END) AS users_d30
    FROM base
    WHERE first_touch_date NOT IN (
        '2020-02-27', '2019-11-15', '2020-01-02', 
        '2020-04-20', '2020-04-21'
    )
    GROUP BY first_touch_date
)

-- Final output with retention rates (only for eligible cohorts)
SELECT
    c.first_touch_date,
    c.users_d0 AS cohort_size,
    
    -- Day 1 retention (only if cohort is at least 1 day old)
    CASE
        WHEN c.first_touch_date <= l.max_dt - 1
        THEN ROUND(
            100.0 * c.users_d1 / NULLIF(c.users_d0, 0), 
            2
        )
    END AS retention_d1_pct,
    
    -- Day 7 retention (only if cohort is at least 7 days old)
    CASE
        WHEN c.first_touch_date <= l.max_dt - 7
        THEN ROUND(
            100.0 * c.users_d7 / NULLIF(c.users_d0, 0), 
            2
        )
    END AS retention_d7_pct,
    
    -- Day 30 retention (only if cohort is at least 30 days old)
    CASE
        WHEN c.first_touch_date <= l.max_dt - 30
        THEN ROUND(
            100.0 * c.users_d30 / NULLIF(c.users_d0, 0), 
            2
        )
    END AS retention_d30_pct
    
FROM cohorts c
CROSS JOIN limits l
ORDER BY c.first_touch_date;

/*
 * ============================================================================
 * Results Interpretation:
 * 
 * retention_d1: Immediate next-day return rate (shows initial engagement)
 * retention_d7: First week retention (shows weekly habit formation)
 * retention_d30: Monthly retention (shows long-term product stickiness)
 * 
 * Sample Output:
 * | first_touch_date | cohort_size | retention_d1_pct | retention_d7_pct | retention_d30_pct |
 * |------------------|-------------|------------------|------------------|-------------------|
 * |   2019-10-01     |    1,000    |      25.5%       |      15.2%       |       8.1%        |
 * |   2019-11-01     |    1,200    |      26.1%       |      15.8%       |       7.9%        |
 * |   2020-01-01     |    1,500    |      24.8%       |      14.9%       |       NULL        |
 * 
 * Note: NULL values for recent cohorts that haven't reached day 30 yet
 * ============================================================================
 */