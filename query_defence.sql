---список наиболее часто востребованного (арендуемого) инвентаря
SELECT DISTINCT
res.item_id, 
res.item_name, 
SUM(res.amount_chosen) OVER (PARTITION BY res.item_id) as total_chooses 
FROM(
  SELECT *
  FROM cust_shopping_bag c
  INNER JOIN items i
  ON i.id = c.item_id
) res
ORDER BY total_chooses DESC;
