USE maven_fuzzy_factory;

-- =====================================================
-- 02. Marketing Channel Performance
-- =====================================================
-- Business Question:
-- Which marketing channels have been most successful?
--
-- Metrics:
-- - Sessions
-- - Orders
-- - Conversion Rate
-- - Gross Revenue
-- - Refunds
-- - Net Revenue
-- - Net Revenue per Order
-- =====================================================


SELECT
    COALESCE(ws.utm_source, 'Organic / Direct') AS marketing_channel,

    -- Traffic
    COUNT(DISTINCT ws.website_session_id) AS sessions,

    -- Orders
    COUNT(DISTINCT o.order_id) AS orders,

    -- Conversion rate
    ROUND(
        COUNT(DISTINCT o.order_id)
        / COUNT(DISTINCT ws.website_session_id) * 100,
        2
    ) AS conversion_rate,

    -- Gross revenue
    ROUND(
        COALESCE(SUM(o.price_usd), 0),
        2
    ) AS gross_revenue,

    -- Refunds
    ROUND(
        COALESCE(SUM(r.total_refund), 0),
        2
    ) AS refunds,

    -- Net revenue
    ROUND(
        COALESCE(SUM(o.price_usd), 0)
        - COALESCE(SUM(r.total_refund), 0),
        2
    ) AS net_revenue,

    -- Net revenue per order
    ROUND(
        (
            COALESCE(SUM(o.price_usd), 0)
            - COALESCE(SUM(r.total_refund), 0)
        )
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS net_revenue_per_order

FROM website_sessions AS ws

LEFT JOIN orders AS o
    ON ws.website_session_id = o.website_session_id

-- Refunds are first aggregated by order
-- to prevent duplicate revenue from multiple refunds
LEFT JOIN
(
    SELECT
        order_id,
        SUM(refund_amount_usd) AS total_refund
    FROM order_item_refunds
    GROUP BY order_id
) AS r
    ON o.order_id = r.order_id

GROUP BY
    COALESCE(ws.utm_source, 'Organic / Direct')

ORDER BY
    net_revenue DESC;