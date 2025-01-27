-- KPI : Chiffre d’affaires par mois et par région + taux d’évolution mensuel :
-- Suivre les revenus générés par Pays et par mois pour identifier les tendances géographiques.

-- Selection des tables 

SELECT od.orderNumber, SUM(quantityOrdered * priceEach) as total_sales
FROM orderdetails AS od
GROUP BY od.orderNumber ;

SELECT o.orderNumber,o.customerNumber, o.orderDate, YEAR(o.orderDate) AS année, MONTH(o.orderDate) AS mois
FROM orders AS o
WHERE status != 'Cancelled';

SELECT c.customerNumber, c.country, c.city
FROM customers AS c;

SELECT COUNT( DISTINCT c.country)
FROM customers AS c;


-- requête finale => ok pour Power BI

WITH 
  country_sales AS(
	SELECT *, 
	LAG (total_sales) OVER(PARTITION BY country, mois ORDER BY année) as previous_sales
	FROM (SELECT c.country, YEAR(o.orderDate) AS année, MONTH(o.orderDate) AS mois,
		         SUM(quantityOrdered * priceEach) as total_sales
		    FROM orders AS o
		    LEFT JOIN customers AS c ON c.customerNumber = o.customerNumber
		    LEFT JOIN orderdetails AS od ON od.orderNumber= o.orderNumber
		    WHERE status != 'Cancelled'
		    GROUP BY c.country,année, mois
		    ORDER BY c.country,année, mois) AS total_sales_per_counrty
        )
SELECT *,
	ROUND(((total_sales - previous_sales)/ previous_sales),2)*100 AS taux_variation,
    ROUND((total_sales / previous_sales),1) AS coeff_evolution
FROM country_sales;


-- KPI:  Taux de retour des clients (repeat customers) 
-- Mesurer la fidélité des clients en identifiant ceux qui passent plusieurs commandes.

SELECT c.customerNumber, c.customerName, c.country, COUNT(o.orderNumber) as nb_cmde, YEAR(o.orderDate) AS année
FROM customers AS c
INNER JOIN orders AS o ON o.customerNumber = c.customerNumber
WHERE status != 'Cancelled' AND YEAR(o.orderDate) = 2023
GROUP BY c.customerNumber, c.customerName, c.country, année
ORDER BY année DESC;

-- Le nombre de clients existants :

SELECT count(c.customerNumber) AS nb_client, YEAR(o.orderDate) AS année
FROM customers AS c
INNER JOIN orders AS o ON o.customerNumber = c.customerNumber
WHERE status != 'Cancelled'
GROUP BY année;


-- KPI : Produits les plus/moins vendus par catégorie :
-- Identifier les produits les plus performants dans chaque catégorie.

-- visualiser les tables
SELECT *
FROM orderdetails;

SELECT p.productCode, p.productLine, p.productName
FROM products AS p;


-- total sales par catégorie produits avec classement => ok requête finale

SELECT p.productLine, COUNT(od.orderNumber) AS nb_cmde, 
      SUM(quantityOrdered * priceEach) as total_sales,
      RANK() OVER(ORDER BY SUM(quantityOrdered * priceEach) DESC) as ranking
FROM orderdetails AS od
LEFT JOIN products AS p ON p.productCode = od.productCode
GROUP BY p.productLine;

-- Identifier les produits les plus performants dans chaque catégorie avec un classement  => ok requête finale

SELECT od.productCode, p.productLine, p.productName, COUNT(od.orderNumber) AS nb_cmde, 
	    SUM(quantityOrdered * priceEach) as total_sales,
      RANK() OVER(PARTITION BY p.productLine ORDER BY SUM(quantityOrdered * priceEach) DESC) AS ranking
FROM orderdetails AS od
LEFT JOIN products AS p ON p.productCode = od.productCode
GROUP BY od.productCode, p.productName ;


-- KPI: La marge brute par produit et par catégorie 

-- visualiser la table
SELECT p.*
FROM products AS p;

-- calculer le prix d'achat unitaire de chaque produits
SELECT p.productCode, p.productLine, p.productName, p.quantityInStock,p.buyPrice
FROM products AS p;

-- calculer le CA de chaque produits
SELECT od.productCode, od.quantityOrdered
FROM orderdetails AS od
GROUP BY od.productCode;

-- requête finale

WITH 
product_cout AS (
	SELECT p.productCode, p.productLine, p.productName, p.buyPrice
	FROM products AS p),
product_sales AS (
	SELECT od.productCode, p.productLine, p.productName, SUM(od.quantityOrdered) AS qtite_vendus,
		SUM(quantityOrdered * priceEach) as total_sales
	FROM orderdetails AS od
	LEFT JOIN products AS p ON p.productCode = od.productCode
	GROUP BY od.productCode, p.productName)
SELECT pc.productCode, pc.productLine, pc.productName, pc.buyPrice, ps.qtite_vendus, ps.total_sales, 
	(pc.buyPrice*ps.qtite_vendus) AS cout_achat,
    (ps.total_sales - (pc.buyPrice*ps.qtite_vendus)) AS marge_brut
FROM product_cout AS pc
LEFT JOIN product_sales AS ps ON pc.productCode = ps.productCode
UNION
SELECT pc.productCode, pc.productLine, pc.productName, pc.buyPrice, ps.qtite_vendus, ps.total_sales,
	(pc.buyPrice*ps.qtite_vendus) AS cout_achat, 
    (ps.total_sales - (pc.buyPrice*ps.qtite_vendus)) AS marge_brut
FROM product_cout AS pc
RIGHT JOIN product_sales AS ps ON pc.productCode = ps.productCode;

