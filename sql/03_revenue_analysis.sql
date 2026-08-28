USE maven_fuzzy_factory;

-- =====================================================
-- Q4. Revenue Analysis
-- =====================================================
-- Business Questions:
-- 1. How has revenue per order evolved?
-- 2. How has revenue per session evolved?
--
-- Gross Revenue = Total order revenue before refunds
-- Refunds       = Total refunds issued
-- Net Revenue   = Gross Revenue - Refunds
-- =====================================================

SELECT
    s.month,

    -- Website traffic
    s.sessions,

    -- Orders
    COALESCE(o.orders, 0) AS orders,

    -- Revenue before refunds
    ROUND(COALESCE(o.gross_revenue, 0), 2) AS gross_revenue,

    -- Refunds
    ROUND(COALESCE(o.refunds, 0), 2) AS refunds,

    -- Revenue after refunds
    ROUND(
        COALESCE(o.gross_revenue, 0)
        - COALESCE(o.refunds, 0),
        2
    ) AS net_revenue,

    -- Net revenue per order
    ROUND(
        (
            COALESCE(o.gross_revenue, 0)
            - COALESCE(o.refunds, 0)
        ) / NULLIF(o.orders, 0),
        2
    ) AS net_revenue_per_order,

    -- Net revenue per website session
    ROUND(
        (
            COALESCE(o.gross_revenue, 0)
            - COALESCE(o.refunds, 0)
        ) / NULLIF(s.sessions, 0),
        2
    ) AS net_revenue_per_session

FROM
(
    -- ================================================
    -- All website sessions by month
    -- ================================================
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS month,
        COUNT(*) AS sessions
    FROM website_sessions
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
) AS s

LEFT JOIN
(
    -- ================================================
    -- Orders, revenue and refunds by order month
    -- ================================================
    SELECT
        DATE_FORMAT(o.created_at, '%Y-%m') AS month,

        COUNT(DISTINCT o.order_id) AS orders,

        SUM(o.price_usd) AS gross_revenue,

        COALESCE(
            SUM(r.total_refund),
            0
        ) AS refunds

    FROM orders AS o

    LEFT JOIN
    (
        -- ============================================
        -- Aggregate refunds once per order
        -- ============================================
        SELECT
            order_id,
            SUM(refund_amount_usd) AS total_refund
        FROM order_item_refunds
        GROUP BY order_id

    ) AS r
        ON o.order_id = r.order_id

    GROUP BY
        DATE_FORMAT(o.created_at, '%Y-%m')

) AS o

    ON s.month = o.month

ORDER BY
    s.month;