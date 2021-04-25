DROP DATABASE IF EXISTS ski_shops;

DROP TABLE IF EXISTS manufactures, items, categories, store, customer, cust_shopping_bag CASCADE;

CREATE DATABASE ski_shops;
\c ski_shops

CREATE SCHEMA test;

SET search_path TO test;

CREATE TABLE
manufactures (
    id SERIAL PRIMARY KEY,
    manufacture_name VARCHAR(20) UNIQUE NOT NULL,
    country VARCHAR(20) NOT NULL DEFAULT 'Russia',
    city VARCHAR NOT NULL,
    phone VARCHAR(11) NOT NULL
);

CREATE TABLE
categories (
  id SERIAL PRIMARY KEY,
  category VARCHAR(11) NOT NULL,
  specification jsonb NOT NULL,
  CONSTRAINT check_category 
    CHECK (category IN ('Snowboard', 'Ski', 'Ice skates'))
);

CREATE TABLE
items (
    id SERIAL PRIMARY KEY,
    manufacture_id INT NOT NULL,
    item_name VARCHAR NOT NULL,
    category_id INT NOT NULL,
    item_size INT NOT NULL CHECK (item_size >= 34 AND item_size < 48),
    release_year VARCHAR(4) NOT NULL,
    rent_price NUMERIC(6,2) NOT NULL,
    FOREIGN KEY (manufacture_id)
        REFERENCES manufactures(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (category_id)
        REFERENCES categories(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE
store (
  id SERIAL PRIMARY KEY,
  item_id INT NOT NULL,
  free_amount INT NOT NULL CHECK (free_amount >= 0),
  is_available BOOLEAN DEFAULT TRUE,
  address VARCHAR NOT NULL,
  phone VARCHAR(11) NOT NULL,
  FOREIGN KEY (item_id)
    REFERENCES items(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE
customer (
  id SERIAL PRIMARY KEY,
  email VARCHAR NOT NULL,
  full_name VARCHAR NOT NULL,
  phone VARCHAR(11) NOT NULL,
  age INT NOT NULL CHECK (age > 13),
  country VARCHAR NOT NULL CHECK (country = 'Russia')
);

CREATE TABLE
cust_shopping_bag (
  id SERIAL PRIMARY KEY,
  item_id INT NOT NULL,
  customer_id INT NOT NULL,
  amount_chosen INT NOT NULL DEFAULT 1 CHECK (amount_chosen >= 0),
  days_amount INT DEFAULT 1 CHECK (days_amount >= 0),
  total_price INT,
  FOREIGN KEY (item_id)
    REFERENCES items(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (customer_id)
    REFERENCES customer(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE 
item_audits (
   id SERIAL PRIMARY KEY,
   item_id INT NOT NULL,
   previous_name VARCHAR NOT NULL,
   changed_on TIMESTAMP(6) NOT NULL
);

INSERT INTO 
    manufactures(manufacture_name, country, city, phone)
VALUES
    ('Vostok', 'Russia', 'Irkutsk', '79124446730'),
    ('Sputnik', 'Russia', 'Moscow', '79054446767'),
    ('Fischer', 'Austria', 'Vienna', '79054449999'),
    ('Roxy', 'Australia', 'Sidney', '79054445589'),
    ('Burton', 'USA', 'Berlingthon', '79054446887'),
    ('Salomon', 'France', 'Paris', '79153346567'),
    ('Lib Tech', 'USA', 'Washington', '79059956877'),
    ('Volki', 'Germany', 'Strassburg', '79058896767'),
    ('Graf', 'Switzerland', 'Geneva', '79155556767');

INSERT INTO 
    categories(category, specification)
VALUES
    ('Snowboard', '{"type": "mountain snowboard", "shape": "twin-tip", "num": 1}' ),
    ('Snowboard', '{"type": "trainee`s snowboard", "shape": "directional", "num": 1}' ),
    ('Ice skates', '{"type": "figure skates", "num": 2}' ),
    ('Ski', '{"type": "all-mountain ski", "width mm": 90, "num": 2}' );

INSERT INTO 
    items(manufacture_id, item_name, category_id, item_size, release_year, rent_price)
VALUES
    (1, 'Riders season boys', 1, 39, '2015', 999.99),
    (1, 'Riders season boys', 1, 40, '2015', 1199.99),
    (1, 'Riders season boys', 1, 41, '2015', 1299.99),
    (9, 'Best ice skates', 3, 42, '2020', 499.99),
    (3, 'Ski premium class', 4, 44, '2020', 1699.99),
    (4, 'Girls snowboard', 2, 37, '2019', 1599.99),
    (4, 'Girls snowboard', 2, 36, '2019', 1499.99),
    (4, 'Girls snowboard', 2, 35, '2019', 1399.99),
    (5, 'Basic snowboard', 1, 40, '2018', 1999.99);

INSERT INTO 
    store(item_id, free_amount, is_available, address, phone)
VALUES
    (1, 2, TRUE, '12, Morskaya str, Sochi', '79157846731'),
    (2, 3, TRUE, '12, Morskaya str, Sochi', '79157846731'),
    (3, 5, TRUE, '12, Morskaya str, Sochi', '79157846731'),
    (4, 1, TRUE, '12, Morskaya str, Sochi', '79157846731'),
    (5, 4, TRUE, '12, Morskaya str, Sochi', '79157846731'),
    (6, 5, TRUE, '1, Gornaya str, Kemerovo', '79139946744'),
    (7, 5, TRUE, '1, Gornaya str, Kemerovo', '79139946744'),
    (8, 5, TRUE, '1, Gornaya str, Kemerovo', '79139946744'),
    (9, 1, TRUE, '1, Gornaya str, Kemerovo', '79139946744');

INSERT INTO 
    customer(email, full_name, phone, age, country)
VALUES
    ('peter@mail.ru', 'Peter Basmannov', '79137846756', 23, 'Russia'),
    ('lev@test.ru', 'Lev Merkulov', '79145558944', 22, 'Russia'),
    ('vlad_k@mail.ru', 'Vlad Kutashov', '79523536789', 21, 'Russia');
    
INSERT INTO 
    cust_shopping_bag(item_id, customer_id, amount_chosen, days_amount)
VALUES
    (1, 1, 2, 3),
    (5, 1, 1, 3),
    (9, 3, 1, 4),
    (5, 2, 2, 4),
    (2, 3, 1, 4);

----Оконные функции
  ---средняя стоимость аренды товара из магазина в сочи
SELECT
    res.item_name,
    res.rent_price,
    res.category,
    ROUND(AVG(res.rent_price) OVER (PARTITION BY res.category), 2) AS avg_price
FROM
    (SELECT * 
     FROM 
       items AS i
     INNER JOIN store AS s
     ON 
       s.item_id = i.id
     INNER JOIN categories AS c
     ON
       c.id = i.category_id
    ) res
WHERE res.address LIKE '%Sochi'
ORDER BY avg_price;

  --- количество и суммарная стоимость товаров общей стоимостью до 2000.00
WITH temp_table AS 
(
  SELECT
    MIN(res.rent_price) OVER (PARTITION BY res.item_id) AS min_prices
  FROM 
  (
    SELECT * FROM store s
    INNER JOIN items i
    ON i.id = s.item_id
  ) res
WHERE (res.rent_price * res.free_amount) < 2000.00
)
SELECT
  COUNT(*) AS total_amount,
  SUM(min_prices) AS overall_price
FROM temp_table; 

----CTE
  ---из таблицы пользователей выбрать самого молодого
WITH tmp_table AS (
  SELECT 
    full_name, 
    age
  FROM
    customer
  ORDER BY age ASC)
SELECT 
  * 
FROM
  tmp_table 
LIMIT 1;

---сколько магазинов с различными адресами существует?
  with tmp_table AS (
    SELECT DISTINCT 
      address 
    FROM 
    store 
  )
  SELECT 
  COUNT(*) AS store_num 
  FROM
  tmp_table;

---выбрать пользователя с максимальным количеством заказанных товаров
with tmp_table as (
  select *
  from customer cust
  inner join cust_shopping_bag bag
  on
    bag.customer_id = cust.id
)
select
  SUM(amount_chosen) OVER (PARTITION BY customer_id),
  full_name
from
  tmp_table
order by sum desc
limit 1;

----Подзапросы
  --- выбрать поставщиков не из России с годом выпуска раньше 2020
SELECT DISTINCT manufacture_name 
FROM manufactures 
WHERE 
id IN (
SELECT res.manufacture_id
FROM
  (manufactures m
  INNER JOIN items i
  ON i.manufacture_id = m.id) res
WHERE 
  res.country <> 'Russia'
AND
  res.release_year < '2020');

----Триггеры и триггерные функции к ним 
  ---если число свободных вещей == 0, то изменить флажок is_available на False
  CREATE OR REPLACE FUNCTION change_availability()
    RETURNS trigger AS
    $$
    BEGIN
      IF NEW.free_amount = 0 THEN
        NEW.is_available = False;

      ELSIF NEW.free_amount > 0 THEN
        NEW.is_available = True;
      END IF;
    RETURN NEW;
    END;
    $$
    LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS change_availability ON store;

CREATE TRIGGER change_availability BEFORE INSERT OR UPDATE ON store
    FOR EACH ROW
    EXECUTE PROCEDURE change_availability();

SELECT * FROM store WHERE id = 1;

UPDATE store SET free_amount = 0 WHERE id = 1 returning * ;
UPDATE store SET free_amount = 2 WHERE id = 1 returning * ;

---если total_price в корзине не задан (NULL), то заменить его на 0.
    CREATE OR REPLACE FUNCTION set_zero()
    RETURNS trigger AS
    $$
    BEGIN
      IF OLD.total_price IS NULL THEN
        NEW.total_price = 0;
      END IF;

    RETURN NEW;
    END;
    $$
    LANGUAGE plpgsql;
  DROP TRIGGER if EXISTS set_zero ON cust_shopping_bag;
  CREATE TRIGGER set_zero BEFORE INSERT OR UPDATE ON cust_shopping_bag
    FOR EACH ROW
    EXECUTE PROCEDURE set_zero();

SELECT * FROM cust_shopping_bag WHERE id = 1;

UPDATE cust_shopping_bag SET days_amount = (SELECT floor(random() * 5 + 1)::int) WHERE id < 3;
UPDATE cust_shopping_bag SET days_amount = (SELECT floor(random() * 5 + 1)::int) WHERE id >= 3 AND id < 5;
UPDATE cust_shopping_bag SET days_amount = (SELECT floor(random() * 5 + 1)::int) WHERE id = 5;

SELECT * FROM cust_shopping_bag;

  
  ---логирование изменений названия товара.
    CREATE OR REPLACE FUNCTION log_item_name_changes()
    RETURNS TRIGGER AS
    $$
    BEGIN
    IF NEW.item_name <> OLD.item_name THEN
      INSERT INTO item_audits(item_id, previous_name, changed_on)
      VALUES(OLD.id, OLD.item_name, now());
    END IF;

    RETURN NEW;
    END;
    $$
    LANGUAGE plpgsql;
  
  CREATE TRIGGER item_name_changes BEFORE UPDATE ON items
  FOR EACH ROW
  EXECUTE PROCEDURE log_item_name_changes();

UPDATE items SET item_name = 'Smallest boys size' WHERE id = 1;

SELECT * FROM item_audits;

----Хранимые Функции(процедуры) pl/pgsql

  --Функция заполнения поля total_price, перемножив поля days_amount, amount_chosen и rent_price из таблицы items.
  CREATE or replace FUNCTION count_total() returns VOID AS
$$
DECLARE v_cursor record;
BEGIN
   FOR v_cursor IN
        SELECT i.rent_price, i.id as item_id, bag.id as bag_id, bag.days_amount, bag.amount_chosen, bag.total_price
        FROM cust_shopping_bag bag
        INNER JOIN items i
        ON i.id = bag.item_id
   LOOP 
       UPDATE cust_shopping_bag
           SET total_price = v_cursor.rent_price * days_amount * amount_chosen
         WHERE item_id = v_cursor.item_id;
   END LOOP;
END;
$$
LANGUAGE plpgsql;

SELECT count_total();
SELECT * FROM cust_shopping_bag;

--Функция поиска доступных товаров по поставщику.
  CREATE OR REPLACE FUNCTION search_items_of(p_name text) RETURNS TABLE(f1 character varying, f2 character varying, f3 character varying, f4 jsonb)
  AS $$  
    BEGIN
    Return QUERY(SELECT m.manufacture_name, i.item_name, c.category, c.specification
    FROM manufactures m
    INNER JOIN items i
    ON i.manufacture_id = m.id
    INNER JOIN categories c
    ON c.id = i.category_id
    WHERE m.manufacture_name = p_name);
    END;
$$
LANGUAGE plpgsql;
SELECT search_items_of('Roxy');

