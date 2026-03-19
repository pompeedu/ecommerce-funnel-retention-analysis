/*
 * ============================================================================
 * Analysis: Daily KPI Trends Analysis
 * Author: Firuzjon Qurbonov
 * Date: 2026
 * 
 * Business Question: Are DAU, Revenue, and Orders growing over time?
 * 
 * Metrics Tracked:
 * 1. DAU (Daily Active Users) - User base growth
 * 2. Orders - Purchase volume trend
 * 3. Orders per User - Purchase frequency/intensity
 * 
 * Data Quality: Excluding anomalous dates identified during data cleaning
 * ============================================================================
 */

WITH daily_metrics AS (
    -- Get DAU from user activity mart
    SELECT 
        dt, 
        COUNT(DISTINCT user_id) AS dau
    FROM user_day_activity
    WHERE dt NOT IN (
        '2020-02-27',   -- Anomaly: data inconsistency
        '2019-11-15',   -- Anomaly: data inconsistency  
        '2020-01-02',   -- Anomaly: data inconsistency
        '2020-04-20',   -- Anomaly: data inconsistency
        '2020-04-21'    -- Anomaly: data inconsistency
    )
    GROUP BY dt
),
daily_orders AS (
    -- Get orders from funnel mart
    SELECT 
        dt, 
        SUM(purchase_cnt) AS orders
    FROM funnel_events
    WHERE dt NOT IN (
        '2020-02-27',   -- Anomaly: data inconsistency
        '2019-11-15',   -- Anomaly: data inconsistency  
        '2020-01-02',   -- Anomaly: data inconsistency
        '2020-04-20',   -- Anomaly: data inconsistency
        '2020-04-21'    -- Anomaly: data inconsistency
    )
    GROUP BY dt
)

-- Final output with trend indicators
SELECT
    d.dt,
    d.dau,
    o.orders,
    -- Orders per user (purchase frequency)
    ROUND((o.orders::NUMERIC / d.dau), 3) AS orders_per_user,
    -- Moving averages for trend analysis (7-day window)
    ROUND(AVG(d.dau) OVER(ORDER BY d.dt ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0) AS dau_7d_avg,
    ROUND(AVG(o.orders) OVER(ORDER BY d.dt ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 0) AS orders_7d_avg,
    -- Week-over-week growth
    ROUND(100.0 * (d.dau - LAG(d.dau, 7) OVER(ORDER BY d.dt)) / NULLIF(LAG(d.dau, 7) OVER(ORDER BY d.dt), 0), 2) AS wow_dau_growth_pct,
    ROUND(100.0 * (o.orders - LAG(o.orders, 7) OVER(ORDER BY d.dt)) / NULLIF(LAG(o.orders, 7) OVER(ORDER BY d.dt), 0), 2) AS wow_orders_growth_pct
FROM daily_metrics d
LEFT JOIN daily_orders o ON d.dt = o.dt 
ORDER BY d.dt;

/*
 * ============================================================================
 * Results Interpretation Guide:
 * 
 * Growing Trend Indicators:
 * - Increasing DAU → User base expansion
 * - Increasing Orders → Revenue growth
 * - Stable/Increasing Orders per User → Healthy engagement
 * 
 * Sample Output:
 * |    dt    | dau  | orders | orders_per_user | dau_7d_avg | wow_dau_growth |
 * |----------|------|--------|-----------------|------------|----------------|
 * |2019-10-01| 5000 |   120  |     0.024       |   4850     |      +2.5      |
 * 
 * ============================================================================
 */

/*
 * ============================================================================
 * Bonus: Visualization-Ready Output
 * For BI tools (Tableau/Power BI/Looker), use this simplified version:
 * 
 * CREATE VIEW v_daily_kpi_trends AS
 * SELECT 
 *     d.dt,
 *     d.dau,
 *     o.orders,
 *     ROUND((o.orders::NUMERIC / d.dau), 3) AS orders_per_user,
 *     EXTRACT(DOW FROM d.dt) AS day_of_week,  -- For day-of-week pattern analysis
 *     EXTRACT(MONTH FROM d.dt) AS month,
 *     EXTRACT(YEAR FROM d.dt) AS year
 * FROM daily_metrics d
 * LEFT JOIN daily_orders o ON d.dt = o.dt;
 * ============================================================================
 */