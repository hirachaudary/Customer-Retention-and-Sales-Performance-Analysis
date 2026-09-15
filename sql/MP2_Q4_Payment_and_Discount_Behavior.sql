Question no 4

4. Payment and Discount Behavior
How do payment methods and discount usage differ between
one-time and repeat customers?


two comparisons:
1.	Payment method behavior 
o	One-time vs. repeat customers 
o	Number of orders 
o	Percentage/share of orders by payment method 
2.	Discount behavior 
o	One-time vs. repeat customers 
o	Discount usage rate 
o	Possibly average discount/value if the dataset supports it


__ classify the customer

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT increment_id) AS order_count
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY
    CASE
        WHEN order_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END
ORDER BY customer_type;

__payment_behaviour

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT increment_id) AS order_count
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),

customer_type AS (
    SELECT
        customer_id,
        CASE
            WHEN order_count = 1 THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type
    FROM customer_orders
),

payment_summary AS (
    SELECT
        ct.customer_type,
        p.payment_method,
        COUNT(DISTINCT p.increment_id) AS orders
    FROM pakistan_ecommerce_data p
    JOIN customer_type ct
        ON p.customer_id = ct.customer_id
    WHERE p.payment_method IS NOT NULL
    GROUP BY
        ct.customer_type,
        p.payment_method
)

SELECT
    customer_type,
    payment_method,
    orders,
    ROUND(
        100.0 * orders /
        SUM(orders) OVER (PARTITION BY customer_type),
        2
    ) AS percentage
FROM payment_summary
ORDER BY
    customer_type,
    orders DESC;

__discount_usage

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT increment_id) AS order_count
    FROM pakistan_ecommerce_data
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),

customer_type AS (
    SELECT
        customer_id,
        CASE
            WHEN order_count = 1 THEN 'One-time'
            ELSE 'Repeat'
        END AS customer_type
    FROM customer_orders
),

order_level AS (
    SELECT
        p.increment_id,
        ct.customer_type,
        SUM(COALESCE(p.discount_amount, 0)) AS total_discount
    FROM pakistan_ecommerce_data p
    JOIN customer_type ct
        ON p.customer_id = ct.customer_id
    GROUP BY
        p.increment_id,
        ct.customer_type
)

SELECT
    customer_type,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE total_discount > 0
    ) AS discounted_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE total_discount > 0
        ) / COUNT(*),
        2
    ) AS discount_usage_percentage,
    ROUND(
        AVG(total_discount) FILTER (
            WHERE total_discount > 0
        ),
        2
    ) AS avg_discount_when_used
FROM order_level
GROUP BY customer_type
ORDER BY customer_type;

SELECT
    increment_id,
    COUNT(*) AS item_rows,
    COUNT(DISTINCT discount_amount) AS different_discount_values,
    MIN(discount_amount) AS min_discount,
    MAX(discount_amount) AS max_discount
FROM pakistan_ecommerce_data
GROUP BY increment_id
HAVING COUNT(DISTINCT discount_amount) > 1
ORDER BY item_rows DESC
LIMIT 20;

	