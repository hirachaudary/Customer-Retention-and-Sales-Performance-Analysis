SELECT
    customer_id,
    COUNT(DISTINCT increment_id) AS total_orders,
    SUM(price * qty_ordered) AS total_spending,
    ROUND(
        SUM(price * qty_ordered)
        / NULLIF(COUNT(DISTINCT increment_id), 0),
        2
    ) AS avg_order_value
FROM pakistan_ecommerce_data
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY total_spending DESC;

order-level table first
WITH order_level AS (
    SELECT
        increment_id,
        customer_id,
        MAX(grand_total) AS order_value
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
    GROUP BY increment_id, customer_id
),

customer_metrics AS (
    SELECT
        customer_id,
        COUNT(DISTINCT increment_id) AS total_orders,
        SUM(order_value) AS total_spending,
        ROUND(
            SUM(order_value) / NULLIF(COUNT(DISTINCT increment_id), 0),
            2
        ) AS avg_order_value
    FROM order_level
    GROUP BY customer_id
)

SELECT *
FROM customer_metrics
ORDER BY total_spending DESC;


Step 2 — Create the high-value classification
WITH order_level AS (
    SELECT
        increment_id,
        customer_id,
        MAX(grand_total) AS order_value
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
    GROUP BY increment_id, customer_id
),

customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(order_value) AS total_spending,
        ROUND(
            SUM(order_value) / NULLIF(COUNT(*), 0),
            2
        ) AS avg_order_value
    FROM order_level
    GROUP BY customer_id
),

customer_quartiles AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY total_orders) AS frequency_quartile,
        NTILE(4) OVER (ORDER BY total_spending) AS spending_quartile
    FROM customer_metrics
)

SELECT
    customer_id,
    total_orders,
    total_spending,
    avg_order_value,
    frequency_quartile,
    spending_quartile,
    CASE
        WHEN frequency_quartile = 4
             AND spending_quartile = 4
            THEN 'High-Value Loyal'

        WHEN frequency_quartile <= 2
             AND spending_quartile = 4
            THEN 'High-Spending Occasional'

        WHEN frequency_quartile = 4
             AND spending_quartile <= 2
            THEN 'Frequent Lower-Value'

        ELSE 'Other'
    END AS customer_segment
FROM customer_quartiles
ORDER BY total_spending DESC;

final query 

WITH order_level AS (
    SELECT
        increment_id,
        customer_id,
        MAX(grand_total) AS order_value
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
    GROUP BY increment_id, customer_id
),

customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(order_value) AS total_spending,
        ROUND(
            SUM(order_value) / NULLIF(COUNT(*), 0),
            2
        ) AS avg_order_value
    FROM order_level
    GROUP BY customer_id
),

customer_quartiles AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY total_orders) AS frequency_quartile,
        NTILE(4) OVER (ORDER BY total_spending) AS spending_quartile
    FROM customer_metrics
),

segmented_customers AS (
    SELECT
        *,
        CASE
            WHEN frequency_quartile = 4
                 AND spending_quartile = 4
                THEN 'High-Value Loyal'

            WHEN frequency_quartile <= 2
                 AND spending_quartile = 4
                THEN 'High-Spending Occasional'

            WHEN frequency_quartile = 4
                 AND spending_quartile <= 2
                THEN 'Frequent Lower-Value'

            ELSE 'Other'
        END AS customer_segment
    FROM customer_quartiles
)

SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(AVG(total_spending), 2) AS avg_spending,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value
FROM segmented_customers
GROUP BY customer_segment
ORDER BY avg_spending DESC;

final final query 


WITH order_level AS (
    SELECT
        increment_id,
        customer_id,
        MAX(grand_total) AS order_value
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
    GROUP BY increment_id, customer_id
),

customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(order_value) AS total_spending,
        ROUND(
            SUM(order_value) / NULLIF(COUNT(*), 0),
            2
        ) AS avg_order_value
    FROM order_level
    GROUP BY customer_id
),

customer_quartiles AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY total_orders) AS frequency_quartile,
        NTILE(4) OVER (ORDER BY total_spending) AS spending_quartile
    FROM customer_metrics
),

segmented_customers AS (
    SELECT
        *,
        CASE
            WHEN frequency_quartile = 4
                 AND spending_quartile = 4
                THEN 'High-Value Loyal'

            WHEN frequency_quartile <= 2
                 AND spending_quartile = 4
                THEN 'High-Spending Occasional'

            WHEN frequency_quartile = 4
                 AND spending_quartile <= 2
                THEN 'Frequent Lower-Value'

            ELSE 'Other'
        END AS customer_segment
    FROM customer_quartiles
),

segment_summary AS (
    SELECT
        customer_segment,
        COUNT(*) AS customer_count,
        SUM(total_spending) AS segment_spending
    FROM segmented_customers
    GROUP BY customer_segment
)

SELECT
    customer_segment,
    customer_count,
    ROUND(
        100.0 * customer_count
        / SUM(customer_count) OVER (),
        2
    ) AS customer_percentage,
    ROUND(segment_spending, 2) AS segment_spending,
    ROUND(
        100.0 * segment_spending
        / SUM(segment_spending) OVER (),
        2
    ) AS spending_percentage
FROM segment_summary
ORDER BY segment_spending DESC;