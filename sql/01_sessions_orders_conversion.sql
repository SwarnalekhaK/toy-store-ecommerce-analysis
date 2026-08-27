USE maven_fuzzy_factory;

-- =====================================================
-- 01. Website Sessions, Orders & Conversion Rate
-- =====================================================
-- Business Questions:
-- 1. What is the trend in website sessions and order volume?
-- 2. How has the session-to-order conversion rate changed?
-- =====================================================

SELECT
    s.month,
    s.sessions,
    COALESCE(o.orders, 0) AS orders,
    ROUND(
        COALESCE(o.orders, 0) / s.sessions * 100,
        2
    ) AS conversion_rate
FROM
(
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS month,
        COUNT(*) AS sessions
    FROM website_sessions
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
) AS s

LEFT JOIN
(
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS month,
        COUNT(*) AS orders
    FROM orders
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
) AS o

ON s.month = o.month

ORDER BY s.month;