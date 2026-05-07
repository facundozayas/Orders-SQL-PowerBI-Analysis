-- ============================================================
-- PORTFOLIO SQL - DATASET: ORDERS
-- ============================================================
-- Dataset: this dataset represents orders from an e-commerce platform.
-- Each row is a single order (order_id) placed by a customer (first_name, last_name, email)
-- with relevant information about location, date and amount (country, order_date, order_total).
--
-- The analysis is structured in five sections:
-- 1. EDA            - reference numbers to understand the business
-- 2. Temporal       - trends, growth and seasonality
-- 3. Customers      - retention, cohorts and acquisition
-- 4. Segmentation   - RFM model and VIP classification
-- 5. Revenue        - income concentration by country
-- ============================================================


-- ============================================================
-- SECTION 1: EDA — Business Reference Numbers
-- ============================================================

-- Which categories generated the most revenue overall?
SELECT product_category, SUM(order_total) AS suma
FROM orders
GROUP BY product_category
ORDER BY suma DESC;

-- Which category ranked first in revenue for each year?
WITH categorias AS (
    SELECT product_category, strftime('%Y', order_date) AS year, SUM(order_total) AS suma
    FROM orders
    GROUP BY year, product_category
)
SELECT *, RANK() OVER(PARTITION BY year ORDER BY suma DESC)
FROM categorias;

-- Which are the top countries by total revenue and number of orders?
WITH countries AS (
    SELECT country, SUM(order_total) AS suma, COUNT(order_total) AS conteo
    FROM orders
    GROUP BY country
)
SELECT *, RANK() OVER(ORDER BY suma DESC)
FROM countries;


-- ============================================================
-- SECTION 2: TEMPORAL ANALYSIS — Trends, Growth and Seasonality
-- ============================================================

-- A1. For each customer, what is the difference between the current
--     and previous purchase? Show only rows where the difference is positive.
WITH diferencias AS (
    SELECT 
        email,
        order_total,
        order_total - LAG(order_total, 1) OVER (PARTITION BY email ORDER BY order_date) AS diferencia
    FROM orders
)
SELECT *
FROM diferencias
WHERE diferencia > 0;

-- A2. What was each customer's first and last purchase?
--     How much did their ticket change between the two?
SELECT DISTINCT
    email,
    FIRST_VALUE(order_total) OVER (PARTITION BY email ORDER BY order_date) AS primera_compra,
    FIRST_VALUE(order_total) OVER (
        PARTITION BY email ORDER BY order_date DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS ultima_compra,
    FIRST_VALUE(order_total) OVER (
        PARTITION BY email ORDER BY order_date DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) - FIRST_VALUE(order_total) OVER (PARTITION BY email ORDER BY order_date) AS diferencia
FROM orders;

-- B1. How much did we sell each month of each year?
--     Which month had the highest growth compared to the previous month?
WITH ventas_mes AS (
    SELECT 
        strftime('%Y-%m', order_date) AS año_mes,
        SUM(order_total) AS total
    FROM orders
    GROUP BY strftime('%Y-%m', order_date)
),
con_crecimiento AS (
    SELECT 
        año_mes,
        total,
        total - LAG(total) OVER (ORDER BY año_mes) AS crecimiento,
        ROW_NUMBER() OVER (ORDER BY total - LAG(total) OVER (ORDER BY año_mes) DESC) AS rn
    FROM ventas_mes
)
SELECT año_mes, total, crecimiento
FROM con_crecimiento
WHERE rn = 1;

-- B2. Which category grew the most between 2022 and 2025?
--     Absolute difference and percentage growth.
WITH calculo AS (
    SELECT 
        product_category,
        SUM(CASE WHEN strftime('%Y', order_date) = '2022' THEN order_total END) AS total_2022,
        SUM(CASE WHEN strftime('%Y', order_date) = '2023' THEN order_total END) AS total_2023,
        SUM(CASE WHEN strftime('%Y', order_date) = '2024' THEN order_total END) AS total_2024,
        SUM(CASE WHEN strftime('%Y', order_date) = '2025' THEN order_total END) AS total_2025
    FROM orders
    GROUP BY product_category
)
SELECT *,
    total_2025 - total_2022 AS diferencia_total,
    (total_2025 - total_2022) * 100.0 / total_2022 AS diferencia_porcentual
FROM calculo;

-- Is there seasonality? Monthly revenue broken down by year.
-- Note: pivot format makes it easier to compare the same month across years.
SELECT 
    strftime('%m', order_date) AS mes,
    SUM(CASE WHEN strftime('%Y', order_date) = '2022' THEN order_total END) AS total_2022,
    SUM(CASE WHEN strftime('%Y', order_date) = '2023' THEN order_total END) AS total_2023,
    SUM(CASE WHEN strftime('%Y', order_date) = '2024' THEN order_total END) AS total_2024,
    SUM(CASE WHEN strftime('%Y', order_date) = '2025' THEN order_total END) AS total_2025
FROM orders
GROUP BY strftime('%m', order_date)
ORDER BY strftime('%m', order_date);

-- D1. For each customer, show how much they spent on each purchase
--     and how much they spent on the previous one.
--     Add a column indicating if the current purchase was higher, lower or equal.
WITH valor_anterior AS (
    SELECT email, order_total AS actual, LAG(order_total, 1) OVER(PARTITION BY email ORDER BY order_date) AS last
    FROM orders
)
SELECT *, CASE 
    WHEN actual > last THEN 'mayor'
    WHEN actual < last THEN 'menor'
    ELSE 'igual'
END AS comparacion 
FROM valor_anterior;

-- D2. Which month had the highest revenue for each year?
--     One result per year showing the month and total sold.
WITH year_month AS (
    SELECT strftime('%Y', order_date) AS year, strftime('%m', order_date) AS month, SUM(order_total) AS suma
    FROM orders
    GROUP BY strftime('%Y', order_date), strftime('%m', order_date)
),
ranking_1 AS (
    SELECT *, RANK() OVER(PARTITION BY year ORDER BY suma DESC) AS ranking
    FROM year_month
)
SELECT * 
FROM ranking_1
WHERE ranking = 1;


-- ============================================================
-- SECTION 3: CUSTOMER ANALYSIS — Retention and Cohorts
-- ============================================================

-- C1. In which year did each customer make their first purchase?
--     How many new customers joined each year?
WITH primera_compra AS (
    SELECT email, MIN(strftime('%Y', order_date)) AS año
    FROM orders
    GROUP BY email
)
SELECT año, COUNT(año) AS primeros_clientes
FROM primera_compra
GROUP BY año
ORDER BY COUNT(año) DESC;

-- C2. Of the customers who joined in 2022, how many came back in 2023? And in 2024?
WITH primera_compra AS (
    SELECT email, MIN(strftime('%Y', order_date)) AS año_entrada
    FROM orders
    GROUP BY email
)
SELECT 
    COUNT(DISTINCT pc.email) AS cohorte_2022,
    COUNT(DISTINCT CASE WHEN strftime('%Y', o.order_date) = '2023' THEN o.email END) AS volvieron_2023,
    COUNT(DISTINCT CASE WHEN strftime('%Y', o.order_date) = '2024' THEN o.email END) AS volvieron_2024
FROM primera_compra pc
JOIN orders o ON pc.email = o.email
WHERE pc.año_entrada = '2022';

-- D4. Extended cohort analysis: for each entry year (2022, 2023, 2024),
--     how many customers came back the following year? All cohorts in a single query.
WITH primera_compra AS (
    SELECT email, MIN(strftime('%Y', order_date)) AS año_entrada
    FROM orders
    GROUP BY email
)
SELECT 
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2022' THEN p.email END) AS cohorte_2022,
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2022' AND strftime('%Y', order_date) = '2023' THEN p.email END) AS volvieron_2023_cohorte22,  
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2022' AND strftime('%Y', order_date) = '2024' THEN p.email END) AS volvieron_2024_cohorte22,
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2023' THEN p.email END) AS cohorte_2023,
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2023' AND strftime('%Y', order_date) = '2024' THEN p.email END) AS volvieron_2024_cohorte23,  
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2023' AND strftime('%Y', order_date) = '2025' THEN p.email END) AS volvieron_2025_cohorte23,
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2024' THEN p.email END) AS cohorte_2024,
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2024' AND strftime('%Y', order_date) = '2025' THEN p.email END) AS volvieron_2025_cohorte24,  
    COUNT(DISTINCT CASE WHEN p.año_entrada = '2025' THEN p.email END) AS cohorte_2025
FROM primera_compra p
JOIN orders o ON o.email = p.email;


-- ============================================================
-- SECTION 4: SEGMENTATION — RFM Model and VIP Classification
-- ============================================================

-- E1. RFM base metrics per customer.
--     Recency in days from the last purchase to the most recent date in the dataset.
--     Note: LAST_VALUE without an explicit frame only looks up to the current row,
--     not to the end of the partition. MAX + GROUP BY is cleaner for this use case.
WITH fecha_ref AS (
    SELECT MAX(order_date) AS hoy FROM orders
)
SELECT 
    o.email,
    CAST(julianday((SELECT hoy FROM fecha_ref)) - julianday(MAX(o.order_date)) AS INT) AS recencia_dias,
    COUNT(o.order_id) AS frecuencia,
    SUM(o.order_total) AS monetario
FROM orders o
GROUP BY o.email;

-- E2. VIP classification based on RFM metrics.
--     A customer is VIP if they have more than 1 purchase OR spent more than 1000 total.
WITH fecha_ref AS (
    SELECT MAX(order_date) AS hoy FROM orders
), 
cuentas AS (
    SELECT 
        o.email,
        CAST(julianday((SELECT hoy FROM fecha_ref)) - julianday(MAX(o.order_date)) AS INT) AS recencia_dias,
        COUNT(o.order_id) AS frecuencia,
        SUM(o.order_total) AS monetario
    FROM orders o
    GROUP BY o.email
)
SELECT *,
    CASE WHEN frecuencia > 1 OR monetario > 1000 THEN 'VIP' ELSE 'No-VIP' END AS vip
FROM cuentas
ORDER BY CASE WHEN vip = 'VIP' THEN 0 ELSE 1 END;

-- What is the average ticket difference between VIP and non-VIP customers?
WITH cuentas AS (
    SELECT COUNT(o.order_id) AS frecuencia, SUM(o.order_total) AS monetario
    FROM orders o
    GROUP BY o.email
),
vip1 AS (
    SELECT *,
        CASE WHEN frecuencia > 1 OR monetario > 1000 THEN 'VIP' ELSE 'No-VIP' END AS vip
    FROM cuentas
)
SELECT AVG(monetario) AS AVG_Ticket, vip
FROM vip1
GROUP BY vip;

-- D3. Total revenue by country and category — pivot format.
--     Each category is a column, each country is a row.
--     Note: this approach works well for a known, fixed set of categories.
--     For dynamic or large category sets, long format + external pivot (Power BI, pandas) is preferred.
SELECT country,
    SUM(CASE WHEN product_category = 'Beauty'      THEN order_total END) AS Beauty,
    SUM(CASE WHEN product_category = 'Sports'      THEN order_total END) AS Sports,
    SUM(CASE WHEN product_category = 'Home'        THEN order_total END) AS Home,
    SUM(CASE WHEN product_category = 'Clothing'    THEN order_total END) AS Clothing,
    SUM(CASE WHEN product_category = 'Electronics' THEN order_total END) AS Electronics,
    SUM(CASE WHEN product_category = 'Books'       THEN order_total END) AS Books
FROM orders
GROUP BY country;


-- ============================================================
-- SECTION 5: REVENUE CONCENTRATION — Pareto Analysis
-- ============================================================

-- E3. Which countries account for 80% of total revenue?
--     Cumulative percentage allows identifying the Pareto cutoff point.
WITH paises AS (
    SELECT country, SUM(order_total) AS monto  
    FROM orders
    GROUP BY country
),
fraccion1 AS (
    SELECT *,
        SUM(monto) OVER(ORDER BY monto DESC) AS acumulado,
        100.0 * monto / SUM(monto) OVER() AS fraccion
    FROM paises
)
SELECT *, SUM(fraccion) OVER(ORDER BY monto DESC) AS fraccion_acum
FROM fraccion1
ORDER BY monto DESC;


-- ============================================================
-- CONCLUSIONS
-- ============================================================
/*
The top revenue category overall is Beauty, and the top country is the USA.
However, when broken down by year, Beauty does not always rank first — and the gap
between categories is relatively small, which suggests no single category dominates
the business. If investment needs to be prioritized, the data does not point clearly
to one winner.

Retention is the main pain point: very few customers return after their first purchase.
This pattern is consistent across all cohorts and should be a priority for the business.

The VIP segment is small in absolute numbers but represents a disproportionate share
of total revenue. Even with a low classification threshold (more than 1 purchase or
more than $1,000 spent), the average ticket difference between VIP and non-VIP
customers is significant — which makes this segment worth targeting with promotions.

New customer acquisition is growing year over year. The difference between 2022 and 2024
is over 100 new customers. The challenge now is converting them into repeat buyers before
they churn.

Seasonality is not conclusive from the numbers alone. A chart would make this much easier
to interpret — which is one of the main reasons to move this analysis into a dashboard.
*/