USE maven_fuzzy_factory;

-- =====================================================
-- 02. Marketing Channel Performance
-- =====================================================
-- Business Question:
-- Which marketing channels have been most successful?
--
-- Metrics:
-- 1. Sessions
-- 2. Orders
-- 3. Conversion Rate
-- 4. Revenue
-- =====================================================

SELECT
    COALESCE(ws.utm_source, 'Organic / Direct') AS marketing_channel,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,

    ROUND(
        COUNT(DISTINCT o.order_id)
        / COUNT(DISTINCT ws.website_session_id) * 100,
        2
    ) AS conversion_rate,

    ROUND(
        COALESCE(SUM(o.price_usd), 0),
        2
    ) AS revenue

FROM website_sessions AS ws

LEFT JOIN orders AS o
    ON ws.website_session_id = o.website_session_id

GROUP BY
    COALESCE(ws.utm_source, 'Organic / Direct')

ORDER BY revenue DESC;