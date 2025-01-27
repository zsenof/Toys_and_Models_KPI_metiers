-- KPI : Durée moyenne de traitement des commandes & commandes au-dessus de la moyenne de livraison :
-- Mesurer l’efficacité opérationnelle en analysant le temps entre la date de commande et la date d’expédition.

SELECT o.*
FROM orderdetails o;

-- valorisation stock 

SELECT SUM(buyPrice*quantityInStock)
FROM products;

-- calcul delai livraison
SELECT o.orderNumber, od.productCode, o.orderDate, o.shippedDate, (o.shippedDate-o.orderDate) AS delai_livraison
FROM orders o
INNER JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
WHERE (status != 'Cancelled') AND (status != 'ON Hold');


-- nb de commande par delai de livraison en jours : ss requête 1
-- requête imbriquée pour récupérer les commande avec un delai <= au delai moyen
-- resultat nb_cmde_dans_delai

SELECT SUM(nb_cmde) AS nb_cmde_ontime
FROM (
	SELECT (o.shippedDate-o.orderDate) AS delai_livraison, COUNT(DISTINCT o.orderNumber) as nb_cmde
	FROM orders o
	INNER JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
	WHERE (status != 'Cancelled') AND (status != 'ON Hold')
	GROUP BY delai_livraison
	ORDER BY nb_cmde DESC) AS delai_livraison_cmde
WHERE delai_livraison <= 12;


-- statistique sur delai de livraison : sous requête 2

SELECT COUNT(DISTINCT o.orderNumber) as nb_cmde_total,
    MIN((o.shippedDate-o.orderDate)) as delai_min , MAX((o.shippedDate-o.orderDate)) as delai_max,
	ROUND(AVG((o.shippedDate-o.orderDate))) as delai_moyen
FROM orders o
INNER JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
WHERE (status != 'Cancelled') AND (status != 'ON Hold')
ORDER BY nb_cmde_total DESC;


-- % livraison dans les temps cad avant 13 jours la moyenne => les stats: requête principale ok Power BI

WITH 
livraisons_dans_les_temps AS (
	SELECT SUM(nb_cmde) AS nb_cmde_ontime
	FROM (
		SELECT (o.shippedDate-o.orderDate) AS delai_livraison, COUNT(DISTINCT o.orderNumber) as nb_cmde
		FROM orders o
		INNER JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
		WHERE (status != 'Cancelled') AND (status != 'ON Hold')
		GROUP BY delai_livraison
		ORDER BY nb_cmde DESC) AS delai_livraison_cmde
	WHERE delai_livraison <= 12),
statistiques_livraison AS(
	SELECT COUNT(DISTINCT o.orderNumber) as nb_cmde_total,
    MIN((o.shippedDate-o.orderDate)) as delai_min , MAX((o.shippedDate-o.orderDate)) as delai_max,
	ROUND(AVG((o.shippedDate-o.orderDate))) as delai_moyen
	FROM orders o
	INNER JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
	WHERE (status != 'Cancelled') AND (status != 'ON Hold')
	ORDER BY nb_cmde_total DESC)
SELECT * , ROUND((nb_cmde_ontime/nb_cmde_total),2) AS percent_livraison_ok
FROM statistiques_livraison, livraisons_dans_les_temps;

    
-- commandes au-dessus de la moyenne de livraison : requête principale ok Power BI

SELECT *  
FROM (
	SELECT (o.shippedDate-o.orderDate) AS delai_livraison, COUNT(DISTINCT o.orderNumber) as nb_cmde, o.orderNumber
	FROM orders o
	INNER JOIN orderdetails AS od ON o.orderNumber = od.orderNumber
	WHERE (status != 'Cancelled') AND (status != 'ON Hold')
	GROUP BY delai_livraison, o.orderNumber
	ORDER BY nb_cmde DESC) AS delai_livraison_cmde
WHERE delai_livraison > 12;


-- pourquoi on a des delais important pour certains produits ? il nous manque la table vendor pour faire cet analyse

SELECT *
FROM products;
