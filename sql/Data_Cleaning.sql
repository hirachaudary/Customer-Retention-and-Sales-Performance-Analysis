SELECT current_database();
 create table raw_data (
    item_id                 INTEGER         PRIMARY KEY,
    status                  VARCHAR(20),
    created_at              DATE,
    sku                     VARCHAR(255),
    price                   NUMERIC(14,4),
    qty_ordered             INTEGER,
    grand_total             NUMERIC(14,4),
    increment_id            VARCHAR(20)     NOT NULL,
    category_name_1         VARCHAR(50),
    sales_commission_code   VARCHAR(150),
    discount_amount         NUMERIC(12,4),
    payment_method          VARCHAR(30),
    working_date            DATE,
    bi_status                VARCHAR(10),
    mv                      TEXT,           -- raw " MV " column, e.g. " 1,950 "
    order_year              SMALLINT,
    order_month             SMALLINT,
    customer_since          VARCHAR(7),     -- e.g. '2016-7'
    m_y                     VARCHAR(7),     -- e.g. '7-2016'
    fy                      VARCHAR(4),     -- e.g. 'FY17'
    customer_id             INTEGER
);

select * 
from raw_data

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'raw_data'
ORDER BY ordinal_position;

SELECT
    COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'raw_data';

select * from raw_data;
select count(*)  from raw_data;

CREATE TABLE pakistan_ecommerce_data (
    item_id                 INTEGER PRIMARY KEY,
    status                  VARCHAR(20),
    created_at              DATE,
    sku                     VARCHAR(255),
    price                   NUMERIC(14,4),
    qty_ordered             INTEGER,
    grand_total             NUMERIC(14,4),
    increment_id            VARCHAR(20) NOT NULL,
    category_name_1         VARCHAR(50),
    sales_commission_code   VARCHAR(150),
    discount_amount         NUMERIC(12,4),
    payment_method          VARCHAR(30),
    working_date            DATE,
    bi_status               VARCHAR(10),
    mv                      TEXT,           -- raw "MV" column, e.g. "1,950"
    order_year              SMALLINT,
    order_month             SMALLINT,
    customer_since          VARCHAR(7),    -- e.g. '2016-7'
    m_y                     VARCHAR(7),    -- e.g. '7-2016'
    fy                      VARCHAR(4),     -- e.g. 'FY17'
    customer_id             INTEGER
);

INSERT INTO pakistan_ecommerce_data
SELECT
    item_id,
    status,
    created_at,
    sku,
    price,
    qty_ordered,
    grand_total,
    increment_id,
    category_name_1,
    sales_commission_code,
    discount_amount,
    payment_method,
    working_date,
    bi_status,
    mv,
    order_year,
    order_month,
    customer_since,
    m_y,
    fy,
    customer_id
FROM raw_data;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(customer_id) AS missing_customer_id,
    COUNT(*) - COUNT(item_id) AS missing_item_id,
    COUNT(*) - COUNT(increment_id) AS missing_increment_id,
    COUNT(*) - COUNT(created_at) AS missing_created_at,
    COUNT(*) - COUNT(price) AS missing_price,
    COUNT(*) - COUNT(qty_ordered) AS missing_quantity,
    COUNT(*) - COUNT(grand_total) AS missing_grand_total
FROM pakistan_ecommerce_data;

SELECT COUNT(*) AS cleaned_rows
FROM pakistan_ecommerce_data;



SELECT
    COUNT(*) - COUNT(item_id) AS item_id_missing,
    COUNT(*) - COUNT(status) AS status_missing,
    COUNT(*) - COUNT(created_at) AS created_at_missing,
    COUNT(*) - COUNT(sku) AS sku_missing,
    COUNT(*) - COUNT(price) AS price_missing,
    COUNT(*) - COUNT(qty_ordered) AS qty_missing,
    COUNT(*) - COUNT(grand_total) AS grand_total_missing,
    COUNT(*) - COUNT(increment_id) AS increment_id_missing,
    COUNT(*) - COUNT(category_name_1) AS category_missing,
    COUNT(*) - COUNT(sales_commission_code) AS commission_code_missing,
    COUNT(*) - COUNT(discount_amount) AS discount_missing,
    COUNT(*) - COUNT(payment_method) AS payment_missing,
    COUNT(*) - COUNT(working_date) AS working_date_missing,
    COUNT(*) - COUNT(bi_status) AS bi_status_missing,
    COUNT(*) - COUNT(mv) AS mv_missing,
    COUNT(*) - COUNT(order_year) AS year_missing,
    COUNT(*) - COUNT(order_month) AS month_missing,
    COUNT(*) - COUNT(customer_since) AS customer_since_missing,
    COUNT(*) - COUNT(m_y) AS my_missing,
    COUNT(*) - COUNT(fy) AS fy_missing,
    COUNT(*) - COUNT(customer_id) AS customer_id_missing
FROM pakistan_ecommerce_data;

SELECT
    item_id,
    status,
    created_at,
    sku,
    increment_id,
    category_name_1,
    payment_method,
    customer_since,
    customer_id
FROM pakistan_ecommerce_data
WHERE customer_id IS NULL;
__Instead, we'll keep the rows in the cleaned dataset but exclude them only from analyses that require identifying customers.

SELECT *
FROM pakistan_ecommerce_data
WHERE status IS NULL;
__ 15 are null

SELECT *
FROM pakistan_ecommerce_data
WHERE sku IS NULL;
__ 20 sku is null

SELECT *
FROM pakistan_ecommerce_data
WHERE category_name_1 IS NULL;
__164 are null

-- Missing status 15
SELECT
    item_id,
    increment_id,
    created_at,
    sku,
    price,
    qty_ordered,
    grand_total,
    customer_id,
    payment_method
FROM pakistan_ecommerce_data
WHERE status IS NULL;

-- Missing SKU 20
SELECT
    item_id,
    increment_id,
    created_at,
    status,
    category_name_1,
    price,
    qty_ordered,
    grand_total,
    customer_id
FROM pakistan_ecommerce_data
WHERE sku IS NULL;

-- Missing category 164
SELECT
    item_id,
    increment_id,
    sku,
    status,
    price,
    qty_ordered,
    grand_total,
    customer_id
FROM pakistan_ecommerce_data
WHERE category_name_1 IS NULL
LIMIT 200;


SELECT *
FROM pakistan_ecommerce_data
WHERE status IS NULL;

UPDATE pakistan_ecommerce_data
SET status = 'Unknown'
WHERE status IS NULL;

SELECT *
FROM pakistan_ecommerce_data
WHERE sku IS NULL;
__Keep the records, leave sku as NULL, and exclude NULL SKUs from SKU/product-level analysis.


SELECT
    COUNT(*) FILTER (WHERE category_name_1 IS NULL) AS actual_null,
    COUNT(*) FILTER (WHERE category_name_1 = '\N') AS backslash_n,
    COUNT(*) FILTER (
        WHERE category_name_1 IS NULL
           OR category_name_1 = '\N'
    ) AS total_missing
FROM pakistan_ecommerce_data;

UPDATE pakistan_ecommerce_orders
SET status = 'Unknown'
WHERE status '\N' ;

__For overall sales analysis:
__Don't exclude them. Their sales still matter.

SELECT COUNT(*) AS total_rows
FROM pakistan_ecommerce_data;

SELECT
    COUNT(*) FILTER (WHERE status = '\N') AS status_backslash_n,
    COUNT(*) FILTER (WHERE sku = '\N') AS sku_backslash_n,
    COUNT(*) FILTER (WHERE category_name_1 = '\N') AS category_backslash_n,
    COUNT(*) FILTER (WHERE customer_id::text = '\N') AS customer_backslash_n
FROM pakistan_ecommerce_data;


SELECT
    status,
    COUNT(*) AS records,
    SUM(grand_total) AS total_sales
FROM pakistan_ecommerce_data
WHERE category_name_1 = '\N'
GROUP BY status
ORDER BY records DESC;

SELECT *
FROM pakistan_ecommerce_data
WHERE status = '\N';

SELECT
    sku,
    status,
    COUNT(*) AS records,
    SUM(grand_total) AS total_sales
FROM pakistan_ecommerce_data
WHERE sku LIKE 'test-product%'
GROUP BY sku, status
ORDER BY records DESC;

SELECT
    COUNT(*) AS test_product_rows,
    SUM(grand_total) AS test_product_sales
FROM pakistan_ecommerce_data
WHERE sku LIKE 'test-product%';


DELETE FROM pakistan_ecommerce_data
WHERE sku LIKE 'test-product%';
__"Test-product records were identified through SKU patterns and excluded from the analytical dataset 
because they represent test transactions rather than genuine customer purchases."


SELECT COUNT(*) AS total_rows
FROM pakistan_ecommerce_data;


UPDATE pakistan_ecommerce_data
SET category_name_1 = 'Unknown'
WHERE category_name_1 IS NULL
   OR category_name_1 = '\N';


SELECT
    COUNT(*) FILTER (WHERE category_name_1 IS NULL) AS actual_null,
    COUNT(*) FILTER (WHERE category_name_1 = '\N') AS backslash_n,
    COUNT(*) FILTER (WHERE category_name_1 = 'Unknown') AS unknown
FROM pakistan_ecommerce_data;


SELECT
    COUNT(*) FILTER (WHERE status IS NULL) AS status_null,
    COUNT(*) FILTER (WHERE status = '\N') AS status_backslash_n,
    COUNT(*) FILTER (WHERE status = 'Unknown') AS status_unknown
FROM pakistan_ecommerce_data;

UPDATE pakistan_ecommerce_data
SET status = 'Unknown'
WHERE status IS NULL;

__Handling duplicates

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT item_id) AS unique_item_ids,
    COUNT(*) - COUNT(DISTINCT item_id) AS duplicate_item_ids
FROM pakistan_ecommerce_data;

__cleaning data types

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'pakistan_ecommerce_data'
ORDER BY ordinal_position;

SELECT
    COUNT(*) FILTER (WHERE price < 0) AS negative_price,
    COUNT(*) FILTER (WHERE price = 0) AS zero_price,
    COUNT(*) FILTER (WHERE qty_ordered < 0) AS negative_quantity,
    COUNT(*) FILTER (WHERE qty_ordered = 0) AS zero_quantity,
    COUNT(*) FILTER (WHERE grand_total < 0) AS negative_grand_total,
    COUNT(*) FILTER (WHERE discount_amount < 0) AS negative_discount
FROM pakistan_ecommerce_data;


SELECT
    status,
    COUNT(*) AS records,
    SUM(grand_total) AS total_grand_total
FROM pakistan_ecommerce_data
WHERE price = 0
GROUP BY status
ORDER BY records DESC;

SELECT
    status,
    COUNT(*) AS records,
    SUM(grand_total) AS total_grand_total
FROM pakistan_ecommerce_data
WHERE grand_total < 0
GROUP BY status
ORDER BY records DESC;

SELECT
    item_id,
    increment_id,
    status,
    sku,
    price,
    qty_ordered,
    grand_total,
    discount_amount,
    payment_method,
    category_name_1,
    customer_id
FROM pakistan_ecommerce_data
WHERE grand_total < 0
ORDER BY status, grand_total;

__Is grand_total repeated within orders?

SELECT
    increment_id,
    COUNT(*) AS line_items,
    COUNT(DISTINCT grand_total) AS distinct_grand_totals,
    MIN(grand_total) AS min_grand_total,
    MAX(grand_total) AS max_grand_total
FROM pakistan_ecommerce_data
GROUP BY increment_id
HAVING COUNT(*) > 1
   AND COUNT(DISTINCT grand_total) > 1
ORDER BY line_items DESC
LIMIT 20;
__ showed no value which means If an order has 5 products and grand_total = 1,000 appears on all 5 rows, then:
SUM(grand_total) would count that order as 5,000, which would be wrong.

SELECT
    increment_id,
    COUNT(*) AS line_items,
    grand_total
FROM pakistan_ecommerce_data
GROUP BY increment_id, grand_total
HAVING COUNT(*) > 1
ORDER BY line_items DESC
LIMIT 20;
__For order-level sales, we'll use one grand_total per increment_id, rather than summing every line.

SELECT
    item_id,
    increment_id,
    status,
    sku,
    price,
    qty_ordered,
    grand_total,
    discount_amount,
    payment_method,
    category_name_1,
    customer_id
FROM pakistan_ecommerce_data
WHERE discount_amount < 0;


SELECT
    MIN(created_at) AS earliest_order,
    MAX(created_at) AS latest_order,
    COUNT(*) FILTER (WHERE created_at IS NULL) AS missing_created_at
FROM pakistan_ecommerce_data;

__DATA_TYPES
SELECT
    customer_since,
    m_y,
    fy,
    mv
FROM pakistan_ecommerce_data
WHERE customer_since IS NOT NULL
   OR m_y IS NOT NULL
   OR fy IS NOT NULL
   OR mv IS NOT NULL
LIMIT 20;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE mv IS NULL) AS mv_null,
    COUNT(*) FILTER (WHERE TRIM(mv) = '') AS mv_empty,
    COUNT(*) FILTER (
        WHERE TRIM(mv) !~ '^[0-9,]+$'
    ) AS non_numeric_mv
FROM pakistan_ecommerce_data;

SELECT
    mv,
    COUNT(*) AS records
FROM pakistan_ecommerce_data
WHERE TRIM(mv) !~ '^[0-9,]+$'
GROUP BY mv
ORDER BY records DESC;

SELECT
    COUNT(*) FILTER (WHERE TRIM(mv) = '-')
        AS dash_values,
    COUNT(*) FILTER (
        WHERE TRIM(mv) <> '-'
          AND TRIM(mv) <> ''
    ) AS numeric_values,
    MIN(
        NULLIF(REPLACE(TRIM(mv), ',', ''), '-')::numeric
    ) AS minimum_mv,
    MAX(
        NULLIF(REPLACE(TRIM(mv), ',', ''), '-')::numeric
    ) AS maximum_mv
FROM pakistan_ecommerce_data;

__Distinct_values

SELECT DISTINCT status
FROM pakistan_ecommerce_data
ORDER BY status;

SELECT DISTINCT payment_method
FROM pakistan_ecommerce_data
ORDER BY payment_method;

SELECT DISTINCT bi_status
FROM pakistan_ecommerce_data
ORDER BY bi_status;

SELECT
    bi_status,
    COUNT(*) AS record_count
FROM pakistan_ecommerce_data
GROUP BY bi_status
ORDER BY record_count DESC;

SELECT *
FROM pakistan_ecommerce_data
WHERE bi_status = '#REF!';

UPDATE pakistan_ecommerce_data
SET bi_status = 'Unknown'
WHERE bi_status = '#REF!';

SELECT
    sales_commission_code,
    COUNT(*) AS record_count
FROM pakistan_ecommerce_data
GROUP BY sales_commission_code
ORDER BY record_count DESC
LIMIT 30;

SELECT
    sales_commission_code,
    status,
    payment_method,
    category_name_1,
    COUNT(*) AS record_count
FROM pakistan_ecommerce_data
WHERE sales_commission_code = '0'
GROUP BY
    sales_commission_code,
    status,
    payment_method,
    category_name_1
ORDER BY record_count DESC;

__inconsistent_format
SELECT
    UPPER(
        REGEXP_REPLACE(
            TRIM(sales_commission_code),
            '[^A-Z0-9]',
            '',
            'g'
        )
    ) AS normalized_code,
    COUNT(DISTINCT sales_commission_code) AS original_variants,
    STRING_AGG(
        DISTINCT sales_commission_code,
        ', '
        ORDER BY sales_commission_code
    ) AS variants,
    SUM(1) AS record_count
FROM pakistan_ecommerce_data
WHERE sales_commission_code IS NOT NULL
  AND TRIM(sales_commission_code) NOT IN ('', '\N', '0')
GROUP BY normalized_code
HAVING COUNT(DISTINCT sales_commission_code) > 1
ORDER BY record_count DESC;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE sales_commission_code IS NULL) AS null_values,
    COUNT(*) FILTER (WHERE sales_commission_code = '\N') AS backslash_n,
    COUNT(*) FILTER (WHERE TRIM(sales_commission_code) = '') AS blank_values,
    COUNT(*) FILTER (WHERE sales_commission_code = '0') AS zero_values,
    COUNT(*) FILTER (
        WHERE sales_commission_code IS NOT NULL
          AND sales_commission_code <> '\N'
          AND TRIM(sales_commission_code) <> ''
          AND sales_commission_code <> '0'
    ) AS populated_codes
FROM pakistan_ecommerce_data;

UPDATE pakistan_ecommerce_data
SET sales_commission_code = NULL
WHERE sales_commission_code = '\N';

SELECT
    category_name_1,
    COUNT(*) AS record_count
FROM pakistan_ecommerce_data
WHERE category_name_1 <> TRIM(category_name_1)
GROUP BY category_name_1
ORDER BY record_count DESC;

SELECT
    LOWER(TRIM(category_name_1)) AS normalized_category,
    COUNT(DISTINCT category_name_1) AS variants,
    STRING_AGG(
        DISTINCT category_name_1,
        ', '
        ORDER BY category_name_1
    ) AS category_variants
FROM pakistan_ecommerce_data
GROUP BY LOWER(TRIM(category_name_1))
HAVING COUNT(DISTINCT category_name_1) > 1
ORDER BY variants DESC;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE created_at <> working_date
    ) AS different_dates,
    COUNT(*) FILTER (
        WHERE working_date IS NULL
    ) AS missing_working_date
FROM pakistan_ecommerce_data;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE increment_id IS NULL) AS missing_increment_id,
    COUNT(DISTINCT increment_id) AS unique_orders
FROM pakistan_ecommerce_data;

__order-level consistency
SELECT
    COUNT(*) AS multi_customer_orders
FROM (
    SELECT
        increment_id
    FROM pakistan_ecommerce_data
    GROUP BY increment_id
    HAVING COUNT(DISTINCT customer_id) > 1
) AS orders;

__customer_id missingness at the order level

SELECT
    COUNT(*) AS affected_orders,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS orders_with_missing_customer_id
FROM (
    SELECT
        increment_id,
        MAX(customer_id) AS customer_id
    FROM pakistan_ecommerce_data
    GROUP BY increment_id
) AS order_customer_check
WHERE customer_id IS NULL;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE sku IS NULL) AS null_sku,
    COUNT(*) FILTER (WHERE TRIM(sku) = '') AS blank_sku,
    COUNT(*) FILTER (WHERE sku = '\N') AS backslash_n_sku
FROM pakistan_ecommerce_data;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE order_year <> EXTRACT(YEAR FROM created_at)
    ) AS year_mismatches,
    COUNT(*) FILTER (
        WHERE order_month <> EXTRACT(MONTH FROM created_at)
    ) AS month_mismatches,
    COUNT(*) FILTER (WHERE order_year IS NULL) AS missing_year,
    COUNT(*) FILTER (WHERE order_month IS NULL) AS missing_month
FROM pakistan_ecommerce_data;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE customer_since IS NULL
           OR TRIM(customer_since) = ''
           OR customer_since = '\N'
    ) AS missing_or_placeholder,
    COUNT(*) FILTER (
        WHERE customer_since !~ '^[0-9]{4}-[0-9]{1,2}$'
    ) AS invalid_format
FROM pakistan_ecommerce_data;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE m_y IS NULL
           OR TRIM(m_y) = ''
           OR m_y = '\N'
    ) AS missing_or_placeholder,
    COUNT(*) FILTER (
        WHERE m_y !~ '^[0-9]{1,2}-[0-9]{4}$'
    ) AS invalid_format
FROM pakistan_ecommerce_data;

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE fy IS NULL
           OR TRIM(fy) = ''
           OR fy = '\N'
    ) AS missing_or_placeholder,
    COUNT(*) FILTER (
        WHERE fy !~ '^FY[0-9]{2}$'
    ) AS invalid_format
FROM pakistan_ecommerce_data;

--Numerical_consistencies

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE ABS((price * qty_ordered) - discount_amount - grand_total) > 0.01
    ) AS rows_with_difference
FROM pakistan_ecommerce_data;


SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE ABS(order_total - calculated_line_total) > 0.01
    ) AS orders_with_difference,
    COUNT(*) FILTER (
        WHERE ABS(order_total - calculated_line_total) <= 0.01
    ) AS orders_reconciled
FROM (
    SELECT
        increment_id,
        MAX(grand_total) AS order_total,
        SUM(price * qty_ordered - discount_amount) AS calculated_line_total
    FROM pakistan_ecommerce_data
    GROUP BY increment_id
) AS order_check;


SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE qty_ordered IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE qty_ordered < 0) AS negative_quantity,
    COUNT(*) FILTER (WHERE qty_ordered = 0) AS zero_quantity
FROM pakistan_ecommerce_data;

 select * from Pakistan_ecommerce_data;


