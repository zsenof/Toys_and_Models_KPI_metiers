-- KPI : Le chiffre d’affaires des commandes des deux derniers mois par pays => ok final MAJ / Ranking pour avoir les 2 mois 

-- requête intermédiaire : chaque année par Pays

SELECT customers.country , 
  YEAR(orderDate) AS year, MONTH(orderDate) AS month,
  SUM(quantityOrdered) AS quantity, SUM(priceEach) AS price, SUM(quantityordered*priceEach) AS revenue,
  LAG(SUM(quantityordered*priceEach))OVER (PARTITION BY country ORDER BY YEAR(orderDate), MONTH(orderDate)) as last_month,
  RANK() OVER(PARTITION BY customers.country, YEAR(orderDate) ORDER BY YEAR(orderDate), MONTH(orderDate) DESC) as ranking
FROM customers
INNER JOIN orders ON customers.customerNumber=orders.customerNumber
INNER JOIN orderdetails ON orderdetails.orderNumber=orders.orderNumber
WHERE `status`!= "Cancelled" 
GROUP BY `year`, month, customers.country;


-- requête finale : selection des 2 mois 

WITH 
revenue_per_month_rank AS (
  	WITH 
    revenue_per_month AS (
  		SELECT customers.country , 
        YEAR(orderDate) AS year, MONTH(orderDate) AS month,
        SUM(quantityOrdered) AS quantity, SUM(priceEach) AS price, SUM(quantityordered*priceEach) AS revenue_current_month,
  		  LAG(SUM(quantityordered*priceEach))OVER (PARTITION BY country ORDER BY YEAR(orderDate), MONTH(orderDate)) as revenue_last_month,
  		  RANK() OVER(PARTITION BY customers.country, YEAR(orderDate) ORDER BY YEAR(orderDate), MONTH(orderDate) DESC) as ranking
  		FROM customers
  		INNER JOIN orders ON customers.customerNumber=orders.customerNumber
  		INNER JOIN orderdetails ON orderdetails.orderNumber=orders.orderNumber
  		WHERE `status`!= "Cancelled"
  		GROUP BY `year`, month, customers.country)
  	SELECT *,
  	LAG(month)OVER (PARTITION BY country ORDER BY year, month) as last_month
  	FROM revenue_per_month
  	WHERE ranking <=2)
SELECT *
FROM revenue_per_month_rank
WHERE ranking =1;


