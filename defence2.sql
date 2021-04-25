----Защита: составить запрос, вычисляющий стоимость брошюр, хранящихся на каждом складе
------вывод цены и количества всех хранящихся брошюр 
SELECT
res.id,
res.name,
res.price,
res.brochure_amount,
(res.price * res.brochure_amount) as total_price
FROM(
  SELECT b.price, w.brochure_amount, w.name, w.id FROM
  warehouse w
  INNER JOIN brochures b
  on b.id = w.brochure_id) res; 
  
---запрос, вычисляющий стоимость брошюр, хранящихся на каждом складе
SELECT DISTINCT
res.name,
SUM(res.price * res.brochure_amount) OVER (PARTITION BY res.name)
FROM(
  SELECT b.price, w.brochure_amount, w.name, w.id FROM
  warehouse w
  INNER JOIN brochures b
  ON b.id = w.brochure_id) res; 