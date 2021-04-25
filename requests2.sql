DROP DATABASE IF EXISTS accounting_system;

DROP TABLE IF EXISTS providers, brochures, warehouse, employees, invoice, logs CASCADE;

CREATE DATABASE accounting_system;
\c accounting_system

CREATE SCHEMA demo;

SET search_path TO demo;

CREATE TABLE
providers (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  address VARCHAR NOT NULL,
  phone VARCHAR(11) NOT NULL
);

CREATE TABLE
brochures (
    id SERIAL PRIMARY KEY,
  	vendor_code VARCHAR(7) UNIQUE NOT NULL,
    name VARCHAR UNIQUE NOT NULL,
  	release_year VARCHAR(4) DEFAULT '0000',
  	provider_id INT NOT NULL,
    price INT NOT NULL,
    FOREIGN KEY (provider_id)
    REFERENCES providers(id)
      ON DELETE CASCADE
      ON UPDATE CASCADE,
  	CONSTRAINT check_code
  	CHECK ((LENGTH(vendor_code) = 7) AND (vendor_code LIKE 'B%' OR vendor_code LIKE 'O%'))
);

CREATE TABLE
warehouse (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  brochure_id INT NOT NULL,
  manager_name VARCHAR NOT NULL,
  brochure_amount INT NOT NULL,
  FOREIGN KEY (brochure_id)
  REFERENCES brochures(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT check_name 
  CHECK (name IN ('Основной', 'Вспомогательный'))
);         

CREATE TABLE
employees (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  position VARCHAR NOT NULL,
  dep_name VARCHAR NOT NULL
);
         
CREATE TABLE
invoice (
  id SERIAL PRIMARY KEY,
  receiver_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  brochure_id INT NOT NULL,
  amount INT NOT NULL,
  total_price INT DEFAULT 0,
  date TIMESTAMP(6) NOT NULL,
  FOREIGN KEY (brochure_id)
  REFERENCES brochures(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (receiver_id)
  REFERENCES employees(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (warehouse_id)
  REFERENCES warehouse(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);
         
CREATE TABLE
logs (
   id SERIAL PRIMARY KEY,
   brochure_id INT NOT NULL,
   prev_amount INT NOT NULL,
   changed_on TIMESTAMP(6) NOT NULL
);
         
INSERT INTO
    providers(name, address, phone)
VALUES
         ('Аркана', 'Москва, улица Нагорная, дом 1, стр 1', '74952278731'),
         ('Театралис', 'Санкт-Петербург, улица Миллионная, дом 8', '79215956238'),
         ('Арт-пати', 'Санкт-Петербург, улица Рубинштейна, дом 46, стр 3', '79284415950'),
         ('Рассвет', 'Самара, улица Садовая, дом 32, стр 8', '79636621785'),
         ('ЭмЭйчАрт', 'Москва, улица Большая Лубянка, дом 15', '74953456170');     

INSERT INTO 
    brochures(vendor_code, name, provider_id, price)
VALUES
    ('O000340', 'Садко', 1, 183),
    ('O000341', 'Свадьба Фигаро', 2, 193),
    ('B000342', 'Искатели жемчуга', 3, 181),
    ('O000343', 'Спящая красавица', 4, 185),
    ('O000344', 'Щелкунчик', 1, 190),
    ('B000345', 'Травиата', 3, 199),
    ('B000346', 'Манон Леско', 5, 199),
    ('O000347', 'Жизель', 5, 200);  

INSERT INTO
     warehouse(name, manager_name, brochure_id, brochure_amount)
VALUES
         ('Основной', 'Любимова Наталья Владимировна', 1, 1000),
         ('Основной', 'Любимова Наталья Владимировна', 2, 1500),
         ('Вспомогательный', 'Козлова Мария Дмитриевна', 3, 1000),
         ('Основной', 'Любимова Наталья Владимировна', 4, 2000),
         ('Основной', 'Любимова Наталья Владимировна', 5, 2000),
         ('Вспомогательный', 'Козлова Мария Дмитриевна', 6, 1800),
         ('Вспомогательный', 'Козлова Мария Дмитриевна', 7, 1500),
         ('Основной', 'Любимова Наталья Владимировна', 8, 1000);

INSERT INTO
         employees(name, position, dep_name)
VALUES
      ('Воробьева Ирина Олеговна', 'Старший капельдинер', 'Служба главного администратора'),
      ('Семиречанский Иван Павлович', 'Заместитель начальника отдела', 'Пресс-служба'),
      ('Заболдина Алина Николаевна', 'Товаровед',  'Отдел продаж сувенирной продукции'),
      ('Тимофеева Ольга Петровна', 'Главный специалист',  'Пресс-служба'),
      ('Терлецкая Анна Николаевна', 'Редактор', 'Литературно-издательский цех'),
      ('Красин Владислав Алексеевич', 'Помощник генерального директора', 'Аппарат управления'),
      ('Меськова Любовь Константиновна', 'Старший капельдинер', 'Служба главного администратора Новой сцены'),
      ('Улитина Инга Вадимовна', 'Директор музея', 'Музей'),
      ('Алдошин Игорь Дмитриевич', 'Старший капельдинер', 'Гастрольный отдел');  

INSERT INTO
         invoice(receiver_id, warehouse_id, brochure_id, amount, date)
VALUES
         (1, 1, 1, 500, '2018-04-10'),
         (2, 2, 2, 600, '2019-05-22'),
         (7, 3, 3, 350, '2020-01-28'),
         (4, 4, 4, 500, '2019-11-02'),
         (6, 5, 5, 410, '2020-05-26'),
         (3, 6, 6, 285, '2019-09-16'),
         (8, 7, 7, 300, '2020-06-04'),
         (5, 8, 8, 260, '2018-02-15'),
         (1, 4, 4, 320, '2019-12-11'),
         (2, 5, 5, 540, '2020-11-10'),
         (3, 2, 2, 245, '2019-09-07'),
         (7, 6, 6, 570, '2019-10-21');

----Оконные функции
---Определить, сколько брошюр поставил каждый поставщик не из Москвы
SELECT DISTINCT
v.provider_name,
v.address,
v.phone,
SUM(v.brochure_amount) OVER (PARTITION BY v.provider_name) as max_amount 
FROM (
  SELECT p.name as provider_name, p.address, p.phone, w.brochure_amount
  FROM providers p
  INNER JOIN brochures b
  ON b.provider_id = p.id
  INNER JOIN warehouse w
  ON w.brochure_id = b.id
  ) v
WHERE v.address NOT LIKE 'Москва%'
ORDER BY max_amount DESC;

---Определить наиболее часто встречающуюся должность у работников
SELECT DISTINCT
    position,
    COUNT(name) OVER (PARTITION BY position)
FROM employees
ORDER BY count DESC
LIMIT 1;

---Определить, с какого склада чаще всего осуществлялся отпуск буклетов
SELECT DISTINCT
v.name as warehouse_name,
COUNT(v.id) OVER (PARTITION BY v.name) as times_count
FROM (
  SELECT i.id, i.warehouse_id, w.name
  FROM invoice i
  INNER JOIN warehouse w
  ON w.id = i.warehouse_id) v
ORDER BY times_count DESC 
LIMIT 1;

-----Триггеры
----сделать триггер, что если stock_id брошюры содержит букву В в начале, 
----то изменить release year на рандомный от 2017 до 2019, а если O - то 2020
  CREATE OR REPLACE FUNCTION change_year()
    RETURNS trigger AS
    $$
    BEGIN
      IF NEW.vendor_code LIKE 'O%' THEN
        NEW.release_year = '2020';

      ELSIF NEW.vendor_code LIKE 'B%' THEN
        NEW.release_year = (SELECT FLOOR(random() * 2 + 2017)::int)::varchar(4);
      END IF;
    RETURN NEW;
    END;
    $$
    LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS change_year ON brochures;

CREATE TRIGGER change_year BEFORE INSERT OR UPDATE ON brochures
    FOR EACH ROW
    EXECUTE PROCEDURE change_year();
    
UPDATE brochures SET price = (SELECT FLOOR(random() * 100 + 100)::int) WHERE vendor_code LIKE 'O%' RETURNING *;
UPDATE brochures SET price = (SELECT FLOOR(random() * 100 + 100)::int) WHERE vendor_code LIKE 'B%' RETURNING *;
    
---логирование изменений названия товара.
    CREATE OR REPLACE FUNCTION log_brochure_changes()
    RETURNS TRIGGER AS
    $$
    BEGIN
    IF NEW.brochure_amount <> OLD.brochure_amount THEN
      INSERT INTO logs(brochure_id, prev_amount, changed_on)
      VALUES(OLD.brochure_id, OLD.brochure_amount, now());
    END IF;

    RETURN NEW;
    END;
    $$
    LANGUAGE plpgsql;
  
  CREATE TRIGGER brochure_changes BEFORE UPDATE ON warehouse
  FOR EACH ROW
  EXECUTE PROCEDURE log_brochure_changes();    

UPDATE warehouse SET brochure_amount = 1001 WHERE ID = 1 RETURNING *;
SELECT * FROM logs;


----CTE
---Определить количество и наименования всех буклетов, отпущенных за годы ранее 2020
WITH tmp_t AS (
  SELECT b.name as brochure_name, w.brochure_amount, b.release_year
  FROM warehouse w
  INNER JOIN brochures b
  ON b.id = w.brochure_id
  WHERE release_year < '2020'
  )
SELECT * FROM tmp_t;

----Хранимые Функции(процедуры) pl/pgsql    
--Функция поиска буклетов и их цен по поставщику.
  CREATE OR REPLACE FUNCTION search_items_of(v_name text) RETURNS TABLE(f1 character varying, f2 character varying, f3 integer)
  AS $$  
    BEGIN
    Return QUERY(SELECT p.name, b.name as brochure_name, b.price
    FROM providers p
    INNER JOIN brochures b
    ON b.provider_id = p.id
    WHERE p.name = v_name);
    END;
$$
LANGUAGE plpgsql;

SELECT search_items_of('Рассвет');   

--если входной параметр - 0 -  функция возвращает список поставщиков
--если входной параметр - 1 -  функция возвращает список буклетов
--иначе выводит ошибку
CREATE OR REPLACE FUNCTION foo(integer) RETURNS record AS 
$$
 DECLARE
    ref refcursor;
    lv_curs record;
BEGIN

   IF   $1 = 0   THEN
        OPEN ref FOR SELECT * FROM providers;
	FETCH FROM ref INTO lv_curs;
   ELSIF $1 = 1 THEN
        OPEN ref FOR SELECT * FROM brochures;
	FETCH FROM ref INTO lv_curs;
   ELSE
   		raise exception 'Некорректное значение параметра';
   END IF;

    RETURN lv_curs;

END;
$$
LANGUAGE plpgsql; 

SELECT foo(0);
SELECT foo(1);
SELECT foo(2);

--Функция заполнения поля total_price в invoice
  CREATE or replace FUNCTION count_total() returns VOID AS
$$
DECLARE v_cursor record;
BEGIN
   FOR v_cursor IN
        SELECT b.price, b.id as brochure_id, i.id as invoice_id, i.amount, i.total_price
        FROM invoice i
        INNER JOIN brochures b
        ON b.id = i.brochure_id
   LOOP 
       UPDATE invoice
           SET total_price = v_cursor.price * amount
         WHERE brochure_id = v_cursor.brochure_id;
   END LOOP;
END;
$$
LANGUAGE plpgsql;

SELECT count_total();
SELECT * FROM invoice;