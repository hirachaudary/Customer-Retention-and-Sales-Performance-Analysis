CHECK THE OBSERVATION WINDOW

SELECT
    MIN(created_at) AS min_order_date,
    MAX(created_at) AS max_order_date
FROM pakistan_ecommerce_data;

Step 2 — Check whether orders have multiple statuses

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE status_count > 1) AS orders_with_multiple_statuses
FROM (
    SELECT
        increment_id,
        COUNT(DISTINCT status) AS status_count
    FROM pakistan_ecommerce_data
    WHERE increment_id IS NOT NULL
    GROUP BY increment_id
) x;


SELECT
    increment_id,
    COUNT(DISTINCT status) AS status_count,
    STRING_AGG(DISTINCT status, ', ' ORDER BY status) AS statuses
FROM pakistan_ecommerce_data
WHERE increment_id IS NOT NULL
GROUP BY increment_id
HAVING COUNT(DISTINCT status) > 1
ORDER BY status_count DESC
LIMIT 20;



WITH order_level AS (
    SELECT
        customer_id,
        increment_id,
        MIN(created_at) AS order_date,
        MIN(status) AS status
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
      AND increment_id IS NOT NULL
    GROUP BY
        customer_id,
        increment_id
),

affected AS (
    SELECT
        customer_id,
        MIN(order_date) AS index_date
    FROM order_level
    WHERE status IN ('canceled', 'order_refunded', 'refund')
    GROUP BY customer_id
),

unaffected AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS index_date
    FROM order_level o
    WHERE NOT EXISTS (
        SELECT 1
        FROM affected a
        WHERE a.customer_id = o.customer_id
    )
    GROUP BY o.customer_id
),

customer_groups AS (
    SELECT
        customer_id,
        'Affected' AS customer_group,
        index_date
    FROM affected
    WHERE index_date <= DATE '2018-05-30'

    UNION ALL

    SELECT
        customer_id,
        'Unaffected' AS customer_group,
        index_date
    FROM unaffected
    WHERE index_date <= DATE '2018-05-30'
),

subsequent_purchase AS (
    SELECT DISTINCT
        c.customer_id
    FROM customer_groups c
    JOIN order_level o
        ON c.customer_id = o.customer_id
       AND o.order_date > c.index_date
       AND o.order_date <= c.index_date + INTERVAL '90 days'
       AND o.status IN ('complete', 'received', 'paid')
)

SELECT
    c.customer_group,
    COUNT(*) AS customers,
    COUNT(s.customer_id) AS customers_with_subsequent_purchase,
    ROUND(
        100.0 * COUNT(s.customer_id) / COUNT(*),
        2
    ) AS subsequent_purchase_rate
FROM customer_groups c
LEFT JOIN subsequent_purchase s
    ON c.customer_id = s.customer_id
GROUP BY c.customer_group
ORDER BY c.customer_group;




















these are just sensivity check

WITH order_level AS (
    SELECT
        customer_id,
        increment_id,
        MIN(created_at) AS order_date,
        MIN(status) AS status
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
      AND increment_id IS NOT NULL
    GROUP BY customer_id, increment_id
),

affected AS (
    SELECT
        customer_id,
        MIN(order_date) AS index_date
    FROM order_level
    WHERE status IN ('canceled', 'order_refunded', 'refund')
    GROUP BY customer_id
),

unaffected AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS index_date
    FROM order_level o
    WHERE NOT EXISTS (
        SELECT 1
        FROM affected a
        WHERE a.customer_id = o.customer_id
    )
    GROUP BY o.customer_id
),

customer_groups AS (
    SELECT
        customer_id,
        'Affected' AS customer_group,
        index_date
    FROM affected

    UNION ALL

    SELECT
        customer_id,
        'Unaffected' AS customer_group,
        index_date
    FROM unaffected
),

eligible AS (
    SELECT *
    FROM customer_groups
    WHERE index_date <= DATE '2018-05-30'
),

window_results AS (
    SELECT
        e.customer_id,
        e.customer_group,

        MAX(
            CASE
                WHEN o.order_date > e.index_date
                 AND o.order_date <= e.index_date + INTERVAL '30 days'
                 AND o.status IN ('complete', 'received', 'paid')
                THEN 1 ELSE 0
            END
        ) AS purchase_30,

        MAX(
            CASE
                WHEN o.order_date > e.index_date
                 AND o.order_date <= e.index_date + INTERVAL '60 days'
                 AND o.status IN ('complete', 'received', 'paid')
                THEN 1 ELSE 0
            END
        ) AS purchase_60,

        MAX(
            CASE
                WHEN o.order_date > e.index_date
                 AND o.order_date <= e.index_date + INTERVAL '90 days'
                 AND o.status IN ('complete', 'received', 'paid')
                THEN 1 ELSE 0
            END
        ) AS purchase_90

    FROM eligible e
    LEFT JOIN order_level o
        ON e.customer_id = o.customer_id
    GROUP BY
        e.customer_id,
        e.customer_group
)

SELECT
    customer_group,
    COUNT(*) AS customers,

    ROUND(100.0 * AVG(purchase_30), 2) AS purchase_rate_30_days,
    ROUND(100.0 * AVG(purchase_60), 2) AS purchase_rate_60_days,
    ROUND(100.0 * AVG(purchase_90), 2) AS purchase_rate_90_days

FROM window_results
GROUP BY customer_group
ORDER BY customer_group;










