WITH primera_compra AS (
    SELECT 
        email, 
        MIN(strftime('%Y', order_date)) AS año_entrada
    FROM orders
    GROUP BY email
), años_retorno AS (
	SELECT p.año_entrada , strftime('%Y', o.order_date) AS año_retorno , COUNT (DISTINCT o.email) as clients
	FROM primera_compra p
	JOIN orders o
	ON o.email = p.email
	GROUP BY p.año_entrada, strftime('%Y', o.order_date))
SELECT * 
FROM años_retorno
WHERE año_retorno >= año_entrada
ORDER BY año_entrada , año_retorno
;
