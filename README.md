Project Overview

The Pakistan Largest E-Commerce Dataset records ~585,000 order line items placed between July 2016 and August 2018. This project uses SQL to explore that data and investigate what separates one-time buyers from repeat customers, and which products, payment behaviors, and order outcomes are associated with stronger sales performance.

Business Problem

The business wants to know where to focus retention effort: which customers are worth prioritizing, which products actually drive revenue vs. just order volume, and whether a cancelled or refunded order really means a customer is lost. Without this, retention spend and discounts risk being spread evenly instead of aimed at the customers and moments that matter most.

Key Questions Answered

* What proportion of customers are one-time vs. repeat buyers, and how much more valuable are repeat customers?
* Which product categories generate the strongest sales and order demand?
* How do payment method and discount usage differ between one-time and repeat customers?
* Are customers with a cancelled or refunded order less likely to buy again?
* Which customers qualify as "high-value" based on purchase frequency and total spend?

Data Overview

| Attribute | Detail |
|---|---|
| Dataset | Pakistan Largest E-Commerce Dataset |
| Raw records | 584,524 order line items |
| Date range | July 1, 2016 – August 28, 2018 |
| Grain | Line-item level, not order level — `item_id` = one product line, `increment_id` = the actual order (an order can span multiple rows) |
| Core fields | Customer ID, order ID, order date, product category, SKU, price, quantity, discount amount, `grand_total`, payment method, order status |
| Key quirk | `grand_total` is an order-level value repeated on every line item in that order, not a per-item amount |
| Post-cleaning size | 582,878 line items across 407,285 unique orders (see Data Profiling below) |

Data Profiling

Before analysis, the raw dataset (584,524 records) was profiled and cleaned into a separate working table, leaving the original data untouched:

* Removed 1,646 test-product records (SKU starting `test-product`) that weren't genuine transactions.
* Confirmed `item_id` as a unique line-item key (0 duplicates) and `increment_id` as the true order key — 582,878 line items collapse to 407,285 unique orders.
* Standardized missing/placeholder values instead of guessing them: NULL/`\N` categories and statuses became `"Unknown"`; an Excel `#REF!` error in one field became `"Unknown"`; missing customer IDs and SKUs (11 and 20 records) were kept as NULL and excluded only from the specific analyses they'd distort, never inferred.
* Investigated rather than auto-deleted anomalies — 2,224 zero-price records, 76 negative `grand_total` records, and 2 negative discounts were all retained after checking they reflected real business cases (promotions, refunds, accounting convention) rather than data-entry errors.
* Discovered `grand_total` is an order-level value repeated on every line item in an order, so it must be collapsed with `MAX(grand_total)` per order before summing — otherwise revenue gets inflated by the number of items per order.
* Reconciled `price × quantity − discount` against `grand_total` at the order level: 81.1% of orders matched exactly; the 18.9% that didn't weren't limited to refunds/cancellations, so `grand_total` was kept as the recorded order value rather than recalculated.
* Verified dates (`created_at`, 0 missing, matches `working_date` 100% of the time) and quantities (fully clean — no NULLs, negatives, or zeros) as reliable for analysis.

Full step-by-step detail is in `ANALYSIS_REPORT.md`.

## Calculated Columns

Beyond the raw fields, the following derived columns were built during analysis and reused across multiple questions.

### Order-Level

| Column            | Derivation                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| `order_total`     | `MAX(grand_total)` per `increment_id` — collapses the repeated line-item value to one true order total |
| `order_demand`    | `COUNT(DISTINCT increment_id)` — number of unique orders                                               |
| `sales_per_order` | Total sales ÷ order demand                                                                             |

### Customer-Level

| Column                                     | Derivation                                                                                                                           |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------ |
| `total_orders`                             | `COUNT(DISTINCT increment_id)` per customer                                                                                          |
| `total_spend` / `total_spending`           | `SUM(order_total)` per customer                                                                                                      |
| `average_order_value` (AOV)                | `AVG(order_total)` or `total_spend ÷ total_orders` per customer                                                                      |
| `customer_type`                            | `CASE WHEN total_orders = 1 THEN 'One-Time' ELSE 'Repeat' END`                                                                       |
| `frequency_quartile` / `spending_quartile` | `NTILE(4)` over `total_orders` / `total_spending`                                                                                    |
| `customer_segment`                         | Combination of frequency and spending quartiles → `High-Value Loyal`, `High-Spending Occasional`, `Frequent Lower-Value`, or `Other` |

### Product / Category-Level

| Column                          | Derivation                                                                                                                  |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `total_sales` / `product_sales` | `SUM((price * qty_ordered) - discount_amount)`, calculated at the line-item level (not `grand_total`, which is order-level) |
| `product_rank`                  | `RANK() OVER (PARTITION BY category ORDER BY product_sales DESC)` — top SKUs within each category                           |

### Payment & Discount

| Column                              | Derivation                                                                            |
| ----------------------------------- | ------------------------------------------------------------------------------------- |
| `percentage` (payment method share) | Orders for a payment method ÷ total orders for that customer type, by `customer_type` |
| `total_discount`                    | `SUM(COALESCE(discount_amount, 0))` per order                                         |
| `discount_usage_percentage`         | Orders with `total_discount > 0` ÷ total orders                                       |
| `avg_discount_when_used`            | `AVG(total_discount)` filtered to orders where a discount was applied                 |

### Order Outcomes

| Column                     | Derivation                                                                                                         |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `customer_group`           | `Affected` (had a cancelled/refunded order) vs. `Unaffected`, based on order `status`                              |
| `index_date`               | Earliest qualifying order date used as the reference point per customer                                            |
| `subsequent_purchase_rate` | Customers with a completed/received/paid order within 30/60/90 days of `index_date` ÷ total customers in the group |


Tools Used

* PostgreSQL
* Excel

Key Findings

* 53.98% of customers are one-time buyers; the remaining 46.02% are repeat customers.
* Repeat customers place 6.51 orders on average (vs. 1.0) and spend ~9.55× more in total, with an AOV ~28% higher.
* Mobiles & Tablets is the strongest category by both sales (Rs 2.18B) and demand (107,868 orders); Men's Fashion has very high order volume (67,576 orders) but comparatively low sales value (Rs 81.11M) — order demand and sales value tell different stories.
* COD accounts for 70.26% of one-time customers' orders but only 40.01% of repeat customers' orders, who spread usage across digital payment methods instead.
* Repeat customers use discounts far more often (38.15% of orders vs. 17.07%), though one-time customers receive a slightly larger discount when one is used.
* Customers who had a cancelled or refunded order were more, not less, likely to buy again within 90 days (23.05% vs. 11.07% for unaffected customers) — an association, not evidence that cancellations help retention.
* High-Value Loyal customers are just 15.55% of the customer base but generate 78.51% of total spending.

Recommendations

* Prioritize retention for repeat customers, since they're worth ~9.55× more than one-time buyers and already make up a meaningful share of spend.
* Evaluate products using both sales value and order volume, not order count alone — high demand (Men's Fashion) doesn't guarantee high revenue.
* Pilot targeted discounts for one-time customers and measure whether they actually convert into repeat purchases, rather than assuming broad discounting works.
* Follow up with customers after a cancelled or refunded order instead of writing them off — a meaningful share return within 90 days.
* Protect and invest in the High-Value Loyal segment specifically, since it drives the large majority of total spending relative to its size.

File

- [ANALYSIS_REPORT.md](ANALYSIS_REPORT.md) — full data-cleaning log, SQL queries, results, and findings for each question above
- [sql/Data_Cleaning.sql](sql/Data_Cleaning.sql) — table creation, profiling, and all cleaning steps (test-record removal, placeholder standardization, `#REF!`/`\N` fixes, reconciliation checks)
- [sql/MP1_One_Time_vs_Repeat_Customers.sql](sql/MP1_One_Time_vs_Repeat_Customers.sql) — Q1 & Q2: one-time vs. repeat classification, order frequency, spend, AOV
- [sql/MP2_Q3_Product_Category_Analysis.sql](sql/MP2_Q3_Product_Category_Analysis.sql) — Q3: category and SKU-level sales/demand analysis
- [sql/MP2_Q4_Payment_and_Discount_Behavior.sql](sql/MP2_Q4_Payment_and_Discount_Behavior.sql) — Q4: payment method and discount usage by customer type
- [sql/MP2_Q5_Order_Outcomes_Subsequent_Purchases.sql](sql/MP2_Q5_Order_Outcomes_Subsequent_Purchases.sql) — Q5: cancelled/refunded customers and 30/60/90-day repurchase rates
- [sql/MP3_Q6_Customer_Segmentation.sql](sql/MP3_Q6_Customer_Segmentation.sql) — Q6: frequency/spending quartile segmentation
- [customer_segmentation_share_vs_spending.png](images/customer_segmentation_share_vs_spending.png)
- [customer_type_breakdown.png](images/customer_type_breakdown.png)
- [customer_value_one_time_vs_repeat.png](images/customer_value_one_time_vs_repeat.png)
- [discount_usage_by_customer_type.png](images/discount_usage_by_customer_type.png)
- [payment_method_usage_by_customer_type.png](images/payment_method_usage_by_customer_type.png)
- - [Pakistan Largest E-Commerce Dataset](https://www.kaggle.com/datasets/zusmani/pakistans-largest-ecommerce-dataset/code) — source dataset (~585,000 order line items)
    
Attribution

This analysis was completed as a capstone project for AuratTech, with team members Samana Batool and Paras Ikram. The dataset is from kaggle; the data cleaning, SQL queries, interpretation, and recommendations above are our own.
