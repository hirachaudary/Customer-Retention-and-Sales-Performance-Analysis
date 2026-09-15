
__Understand customer/order coverage.
MP1 is specifically about customer retention, so we need to know how much of our order data can actually be attributed to a customer.

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE customer_id IS NOT NULL) AS orders_with_customer_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS orders_without_customer_id
FROM (
    SELECT
        increment_id,
        MAX(customer_id) AS customer_id
    FROM pakistan_ecommerce_data
    GROUP BY increment_id
) AS orders;

__Build the order-level foundation

SELECT
    increment_id,
    MAX(customer_id) AS customer_id,
    MAX(grand_total) AS order_total,
    MIN(created_at) AS order_date
FROM pakistan_ecommerce_data
GROUP BY increment_id
ORDER BY increment_id
LIMIT 20;

__customer_level dataset

SELECT
    customer_id,
    COUNT(DISTINCT increment_id) AS total_orders,
    SUM(order_total) AS total_spend,
    AVG(order_total) AS average_order_value
FROM (
    SELECT
        increment_id,
        MAX(customer_id) AS customer_id,
        MAX(grand_total) AS order_total
    FROM pakistan_ecommerce_data
    GROUP BY increment_id
) AS orders
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY total_orders DESC;

__classify customer_type

SELECT
    customer_id,
    total_orders,
    total_spend,
    average_order_value,
    CASE
        WHEN total_orders = 1 THEN 'One-Time'
        WHEN total_orders > 1 THEN 'Repeat'
    END AS customer_type
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT increment_id) AS total_orders,
        SUM(order_total) AS total_spend,
        AVG(order_total) AS average_order_value
    FROM (
        SELECT
            increment_id,
            MAX(customer_id) AS customer_id,
            MAX(grand_total) AS order_total
        FROM pakistan_ecommerce_data
        GROUP BY increment_id
    ) AS orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) AS customers
ORDER BY total_orders DESC;

__ MP1 summary

SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_customers,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(AVG(total_spend), 2) AS avg_spend,
    ROUND(AVG(average_order_value), 2) AS avg_aov
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT increment_id) AS total_orders,
        SUM(order_total) AS total_spend,
        AVG(order_total) AS average_order_value,
        CASE
            WHEN COUNT(DISTINCT increment_id) = 1 THEN 'One-Time'
            WHEN COUNT(DISTINCT increment_id) > 1 THEN 'Repeat'
        END AS customer_type
    FROM (
        SELECT
            increment_id,
            MAX(customer_id) AS customer_id,
            MAX(grand_total) AS order_total
        FROM pakistan_ecommerce_data
        GROUP BY increment_id
    ) AS orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) AS customers
GROUP BY customer_type
ORDER BY customer_type;


Question 1: What proportion of customers are one-time versus repeat customers?

SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS pct_customers
FROM (
    SELECT
        customer_id,
        CASE
            WHEN COUNT(DISTINCT increment_id) = 1 THEN 'One-Time'
            WHEN COUNT(DISTINCT increment_id) > 1 THEN 'Repeat'
        END AS customer_type
    FROM (
        SELECT
            increment_id,
            MAX(customer_id) AS customer_id
        FROM pakistan_ecommerce_data
        GROUP BY increment_id
    ) AS orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) AS customers
GROUP BY customer_type
ORDER BY customer_type;

Question 2: How do order frequency, total spend, and average order value differ between one-time and repeat customers?

SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(total_orders), 2) AS avg_orders,
    ROUND(AVG(total_spend), 2) AS avg_spend,
    ROUND(AVG(average_order_value), 2) AS avg_aov
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT increment_id) AS total_orders,
        SUM(order_total) AS total_spend,
        AVG(order_total) AS average_order_value,
        CASE
            WHEN COUNT(DISTINCT increment_id) = 1 THEN 'One-Time'
            WHEN COUNT(DISTINCT increment_id) > 1 THEN 'Repeat'
        END AS customer_type
    FROM (
        SELECT
            increment_id,
            MAX(customer_id) AS customer_id,
            MAX(grand_total) AS order_total
        FROM pakistan_ecommerce_data
        GROUP BY increment_id
    ) AS orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) AS customers
GROUP BY customer_type
ORDER BY customer_type;