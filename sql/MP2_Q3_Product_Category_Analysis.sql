--mp3 Q3: Which product categories generate the highest sales and order demand?
__Level 1 — Category
 Which categories have the highest sales?
 Which categories have the highest order demand?
  Level 2 — Product within category
 Which products/SKUs are driving those categories?
 Which products have the highest sales and order demand?

SELECT
    category_name_1 AS category,
    SUM((price * qty_ordered) - discount_amount) AS total_sales,
    COUNT(DISTINCT increment_id) AS order_demand
FROM pakistan_ecommerce_data
GROUP BY category_name_1
ORDER BY total_sales DESC;

SELECT
    category_name_1 AS category,
    COUNT(*) AS records,
    COUNT(DISTINCT sku) AS unique_skus,
    COUNT(DISTINCT increment_id) AS orders,
    SUM((price * qty_ordered) - discount_amount) AS sales
FROM pakistan_ecommerce_data
WHERE category_name_1 IN ('Others', 'Unknown')
GROUP BY category_name_1
ORDER BY category;

SELECT
    sku,
    COUNT(*) AS records,
    COUNT(DISTINCT increment_id) AS orders,
    SUM((price * qty_ordered) - discount_amount) AS sales
FROM pakistan_ecommerce_data
WHERE category_name_1 = 'Unknown'
  AND sku IS NOT NULL
GROUP BY sku
ORDER BY sales DESC
LIMIT 20;

Which categories generate the highest sales?

SELECT
    category_name_1 AS category,
    SUM((price * qty_ordered) - discount_amount) AS total_sales,
    COUNT(DISTINCT increment_id) AS order_demand,
    ROUND(
        SUM((price * qty_ordered) - discount_amount)
        / COUNT(DISTINCT increment_id),
        2
    ) AS sales_per_order
FROM pakistan_ecommerce_data
WHERE category_name_1 <> 'Unknown'
GROUP BY category_name_1
ORDER BY total_sales DESC;

WITH product_performance AS (
    SELECT
        category_name_1 AS category,
        sku,
        SUM((price * qty_ordered) - discount_amount) AS product_sales,
        COUNT(DISTINCT increment_id) AS order_demand
    FROM pakistan_ecommerce_data
    WHERE category_name_1 IN (
        'Mobiles & Tablets',
        'Appliances',
        'Entertainment',
        'Men''s Fashion'
    )
    AND sku IS NOT NULL
    GROUP BY category_name_1, sku
)

SELECT
    category,
    sku,
    product_sales,
    order_demand,
    RANK() OVER (
        PARTITION BY category
        ORDER BY product_sales DESC
    ) AS product_rank
FROM product_performance
ORDER BY category, product_rank;


final query

WITH product_performance AS (
    SELECT
        category_name_1 AS category,
        sku,
        SUM((price * qty_ordered) - discount_amount) AS product_sales,
        COUNT(DISTINCT increment_id) AS order_demand
    FROM pakistan_ecommerce_data
    WHERE category_name_1 IN (
        'Mobiles & Tablets',
        'Appliances',
        'Men''s Fashion'
    )
    AND sku IS NOT NULL
    GROUP BY category_name_1, sku
),

ranked_products AS (
    SELECT
        category,
        sku,
        product_sales,
        order_demand,
        RANK() OVER (
            PARTITION BY category
            ORDER BY product_sales DESC
        ) AS product_rank
    FROM product_performance
)

SELECT
    category,
    sku,
    product_sales,
    order_demand,
    product_rank
FROM ranked_products
WHERE product_rank <= 5
ORDER BY category, product_rank;


