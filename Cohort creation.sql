Use olistDB;
-- creating base table..
CREATE TABLE base_orders AS
SELECT
    o.customer_id,
    o.order_id,
    DATE(o.order_purchase_timestamp) AS order_date,
    SUM(p.payment_value) AS order_value
FROM orders o
JOIN order_payments p
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY 
    o.customer_id,
    o.order_id,
    DATE(o.order_purchase_timestamp);
    
    -- validation.
    SELECT COUNT(*) FROM base_orders;
SELECT COUNT(DISTINCT order_id) FROM base_orders;

-- creating table first purchase.
CREATE TABLE customer_first_purchase AS
SELECT
    customer_id,
    MIN(order_date) AS first_order_date
FROM base_orders
GROUP BY customer_id;

-- creating cohort transaction table..
CREATE TABLE cohort_orders AS
SELECT
    b.customer_id,
    b.order_id,
    b.order_date,

    -- Cohort month (first purchase month)
    DATE(bfp.first_order_date - INTERVAL DAY(bfp.first_order_date)-1 DAY) AS cohort_month,

    -- Order month
    DATE(b.order_date - INTERVAL DAY(b.order_date)-1 DAY) AS order_month,

    -- Cohort index (months since first purchase)
    TIMESTAMPDIFF(
        MONTH,
        DATE(bfp.first_order_date - INTERVAL DAY(bfp.first_order_date)-1 DAY),
        DATE(b.order_date - INTERVAL DAY(b.order_date)-1 DAY)
    ) AS cohort_index,

    b.order_value

FROM base_orders b
JOIN customer_first_purchase bfp
    ON b.customer_id = bfp.customer_id;
    
   -- 

SELECT DISTINCT cohort_index FROM cohort_orders ORDER BY cohort_index;

--
CREATE TABLE customer_metricsdb AS
SELECT
    customer_unique_id,
    COUNT(order_id) AS total_orders,
    SUM(order_value) AS total_revenue,
    AVG(order_value) AS avg_order_value
FROM base_orders
GROUP BY customer_unique_id;

SELECT * FROM customer_metrics LIMIT 10;

SELECT
    ROUND(
        COUNT(CASE WHEN total_orders > 1 THEN 1 END) * 100.0 /
        COUNT(*),
    2) AS repeat_purchase_rate
FROM customer_metricsdb;

SELECT
    ROUND(AVG(total_revenue), 2) AS avg_ltv
FROM customer_metricsdb;

SELECT
    ROUND(SUM(order_value) / COUNT(order_id), 2) AS avg_order_value
FROM base_orders;

SELECT
    customer_unique_id,
    total_revenue,
    CASE
        WHEN total_revenue > 500 THEN 'High Value'
        WHEN total_revenue BETWEEN 200 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_metricsdb;











