USE maven_fuzzy_factory;

-- ============================================================
-- Q5: PRODUCT PERFORMANCE ANALYSIS
-- ============================================================
-- Business Question:
-- Which products generate the most revenue and profit?
--
-- This analysis calculates:
-- 1. Units sold
-- 2. Gross revenue
-- 3. Refunds
-- 4. Net revenue
-- 5. Gross profit
-- 6. Gross profit margin
--
-- Important:
-- Refunds are aggregated by order_item_id first.
-- This prevents multiple refund records for the same
-- order item from duplicating revenue or COGS.
-- ============================================================


SELECT

    -- Product identification
    p.product_id,
    p.product_name,

    -- ========================================================
    -- 1. UNITS SOLD
    -- ========================================================
    -- COUNT counts the number of order items sold for each
    -- product.
    COUNT(oi.order_item_id) AS units_sold,


    -- ========================================================
    -- 2. GROSS REVENUE
    -- ========================================================
    -- Revenue generated before deducting refunds.
    --
    -- price_usd represents the selling price of each
    -- order item.
    SUM(oi.price_usd) AS gross_revenue
    -- Rounded below for easier presentation.


    -- ========================================================
    -- 3. REFUNDS
    -- ========================================================
    -- Total refund amount associated with each product.
    --
    -- COALESCE converts NULL to 0 for products that
    -- have no refunds.
    ROUND(
        COALESCE(SUM(r.total_refund), 0),
        2
    ) AS refunds,


    -- ========================================================
    -- 4. NET REVENUE
    -- ========================================================
    -- Net Revenue = Gross Revenue - Refunds
    --
    -- This represents revenue remaining after refunds.
    ROUND(
        SUM(oi.price_usd)
        - COALESCE(SUM(r.total_refund), 0),
        2
    ) AS net_revenue,


    -- ========================================================
    -- 5. GROSS PROFIT
    -- ========================================================
    -- Gross Profit = Net Revenue - COGS
    --
    -- COGS = Cost of Goods Sold
    -- It represents the cost of the products sold.
    --
    -- Therefore:
    -- Gross Profit =
    -- Sales revenue - Refunds - Cost of products
    ROUND(
        SUM(oi.price_usd)
        - COALESCE(SUM(r.total_refund), 0)
        - SUM(oi.cogs_usd),
        2
    ) AS gross_profit,


    -- ========================================================
    -- 6. GROSS PROFIT MARGIN
    -- ========================================================
    -- Gross Profit Margin =
    -- (Gross Profit / Net Revenue) × 100
    --
    -- NULLIF prevents a division-by-zero error if
    -- net revenue is 0.
    ROUND(
        (
            SUM(oi.price_usd)
            - COALESCE(SUM(r.total_refund), 0)
            - SUM(oi.cogs_usd)
        )
        /
        NULLIF(
            SUM(oi.price_usd)
            - COALESCE(SUM(r.total_refund), 0),
            0
        ) * 100,
        2
    ) AS profit_margin


-- ============================================================
-- SOURCE TABLES AND JOINS
-- ============================================================

FROM products AS p

-- Connect products to the individual items sold.
LEFT JOIN order_items AS oi
    ON p.product_id = oi.product_id


-- ============================================================
-- REFUND SUBQUERY
-- ============================================================
-- Refunds are first aggregated at the order-item level.
--
-- Why?
-- An order item could potentially have multiple refund
-- records. Aggregating first prevents duplicate rows when
-- joining refunds to order_items.
LEFT JOIN
(
    SELECT
        order_item_id,

        -- Total refund amount for each order item
        SUM(refund_amount_usd) AS total_refund

    FROM order_item_refunds

    GROUP BY order_item_id

) AS r

    -- Match each order item with its refund amount
    ON oi.order_item_id = r.order_item_id


-- ============================================================
-- GROUPING
-- ============================================================
-- We want one row per product.
GROUP BY
    p.product_id,
    p.product_name


-- ============================================================
-- SORTING
-- ============================================================
-- Display the products from highest to lowest net revenue.
ORDER BY
    net_revenue DESC;