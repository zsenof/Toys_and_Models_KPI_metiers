-- KPI: Performance des représentants commerciaux
-- Mesurer le chiffre d’affaires généré par chaque employé chargé des ventes.
-- on a besoin de la table employees, customers, orders and orderdetails

USE toys_and_models;

SELECT *
FROM employees
WHERE jobTitle LIKE 'Sales%';

SELECT * 
FROM customers;

SELECT * 
FROM orders;

SELECT * 
FROM orderdetails;

-- les statuts des commandes : On peux prendre les status 'Shipped', 'Resolved' and 'On Hold'
SELECT status,COUNT(status)
FROM orders
GROUP BY status;

-- que signifie le status 'Resolved' , 'Cancelled' , 'On Hold' ? => lire les commentaires pour comprendre.
SELECT *
FROM orders
WHERE status = 'Resolved';


-- dans la table customers, on retrouve l'attribut "salesRepEmployeeNumber" qui est une clé étrangère faisant reference à la
-- clé primaire "EmployeeNumber" de la table employees => On peux donc faire une jointure entre la table customers et employees.

SELECT e.employeeNumber, CONCAT_WS(' ',e.lastName, e.firstName) AS employeeName, e.officeCode, e.jobTitle, 
	c.customerNumber, c.customerName, CONCAT_WS(' ', c.contactLastName, c.contactFirstName) AS contactName
FROM employees as e
INNER JOIN customers as c
ON c.salesRepEmployeeNumber = e.employeeNumber;

-- dans la table orders, on retrouve l'attribut "customerNumber" qui est la clé étrangère faisant référence à la clé primaire 
-- customerNumber de la table "customers". La jointure serait orders.customerNumber = customers.customerNumber
-- orderdetails.orderNumber = orders.orderNumber

SELECT e.employeeNumber, CONCAT_WS(' ',e.lastName, e.firstName) AS employeeName, e.officeCode, e.jobTitle, o.orderDate,
	c.customerNumber, c.customerName, o.orderNumber, od.productCode, od.quantityOrdered, od.priceEach, 
    (od.quantityOrdered*od.priceEach) AS CA
FROM employees AS e
INNER JOIN customers AS c
ON c.salesRepEmployeeNumber = e.employeeNumber
INNER JOIN orders AS o
ON c.customerNumber = o.customerNumber
INNER JOIN orderdetails AS od 
ON od.orderNumber = o.orderNumber 
WHERE o.status != 'Cancelled'
ORDER BY e.employeeNumber,c.customerNumber, o.orderDate ;

-- requête affinée

SELECT e.employeeNumber, CONCAT_WS(' ',e.lastName, e.firstName) AS employeeName, e.officeCode, YEAR(o.orderDate) as année,
	MONTH(o.orderDate) as mois, c.customerNumber, c.customerName, COUNT(DISTINCT o.orderNumber) AS nbre_cmde_clt,
    SUM(od.quantityOrdered*od.priceEach) AS CA,
    RANK() OVER(PARTITION BY YEAR(o.orderDate), MONTH(o.orderDate) ORDER BY SUM(od.quantityOrdered * od.priceEach) DESC) AS Ranking
FROM employees AS e
INNER JOIN customers AS c
ON c.salesRepEmployeeNumber = e.employeeNumber
INNER JOIN orders AS o
ON c.customerNumber = o.customerNumber
INNER JOIN orderdetails AS od 
ON od.orderNumber = o.orderNumber 
WHERE o.status != 'Cancelled'
GROUP BY e.employeeNumber, employeeName, e.officeCode, e.jobTitle, c.customerNumber, c.customerName, année, mois;


-- ranking_ca_per_month : ok requête finale

WITH 
  ranking_employee_ca AS (
  SELECT 
  	e.employeeNumber, CONCAT_WS(' ',e.lastName, e.firstName) AS employeeName, e.officeCode, offi.city,
  	YEAR(o.orderDate) as année, MONTH(o.orderDate) as mois, COUNT(DISTINCT o.orderNumber) AS nbre_cmde_clt,
      SUM(od.quantityOrdered*od.priceEach) AS CA,
      RANK() OVER(
  		PARTITION BY YEAR(o.orderDate), MONTH(o.orderDate) 
          ORDER BY SUM(od.quantityOrdered * od.priceEach) DESC) AS ranking_année_mois
  FROM employees AS e
  INNER JOIN offices AS offi
  	ON e.officeCode = offi.officeCode
  INNER JOIN customers AS c
  	ON c.salesRepEmployeeNumber = e.employeeNumber
  INNER JOIN orders AS o
  	ON c.customerNumber = o.customerNumber
  INNER JOIN orderdetails AS od 
  	ON od.orderNumber = o.orderNumber 
  WHERE o.status != 'Cancelled'
  GROUP BY e.employeeNumber, e.officeCode,offi.city, e.jobTitle, année, mois
  )
SELECT *
FROM ranking_employee_ca
WHERE ranking_année_mois <=2;


-- KPI : Performance des bureaux 
-- Mesurer le chiffre d’affaire généré par chaque bureau.

-- Visualiser la table offices pour récupérer la colonne officeCode ect...
SELECT officeCode, country, city
FROM offices;

-- Calculer le chiffre d'affaires généré par chaque bureau
SELECT e.officeCode, COUNT(DISTINCT e.employeeNumber) AS nb_employee,
		SUM(od.quantityOrdered*od.priceEach) AS total_sales
FROM employees AS e
INNER JOIN customers AS c ON c.salesRepEmployeeNumber = e.employeeNumber
INNER JOIN orders AS o ON c.customerNumber = o.customerNumber
INNER JOIN orderdetails AS od ON od.orderNumber = o.orderNumber
WHERE o.status != 'Cancelled'
GROUP BY e.officeCode;

-- requête principale : chiffre d'affaires généré par chaque bureau avec la localisation du bureau

SELECT office_sales.* , o.country, o.city
FROM (SELECT e.officeCode, COUNT(DISTINCT e.employeeNumber) AS nb_employee,
		SUM(od.quantityOrdered*od.priceEach) AS total_sales
	FROM employees AS e
	INNER JOIN customers AS c 
		ON c.salesRepEmployeeNumber = e.employeeNumber
	INNER JOIN orders AS o 
		ON c.customerNumber = o.customerNumber
	INNER JOIN orderdetails AS od	
		ON od.orderNumber = o.orderNumber
	WHERE o.status != 'Cancelled'
	GROUP BY e.officeCode) AS office_sales
LEFT JOIN offices AS o ON o.officeCode = office_sales.officeCode
ORDER BY total_sales DESC;
