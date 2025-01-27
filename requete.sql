-- Le chiffre d’affaires des commandes des deux derniers mois par pays => ok final MAJ / Ranking pour avoir les 2 mois 
-- chaque année par Pays

SELECT customers.country , YEAR(orderDate) AS year, MONTH(orderDate) AS month,SUM(quantityOrdered) AS quantity, 
SUM(priceEach) AS price, SUM(quantityordered*priceEach) AS revenue,
LAG(SUM(quantityordered*priceEach))OVER (PARTITION BY country ORDER BY YEAR(orderDate), MONTH(orderDate)) as last_month,
RANK() OVER(PARTITION BY customers.country, YEAR(orderDate) ORDER BY YEAR(orderDate), MONTH(orderDate) DESC) as ranking
FROM customers
INNER JOIN orders
ON customers.customerNumber=orders.customerNumber
INNER JOIN orderdetails
ON orderdetails.orderNumber=orders.orderNumber
WHERE `status`!= "Cancelled" 
GROUP BY `year`, month, customers.country;