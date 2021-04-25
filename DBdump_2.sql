--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4
-- Dumped by pg_dump version 12.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: demo; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA demo;


ALTER SCHEMA demo OWNER TO postgres;

--
-- Name: change_year(); Type: FUNCTION; Schema: demo; Owner: postgres
--

CREATE FUNCTION demo.change_year() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      IF NEW.vendor_code LIKE 'O%' THEN
        NEW.release_year = '2020';

      ELSIF NEW.vendor_code LIKE 'B%' THEN
        NEW.release_year = (SELECT FLOOR(random() * 2 + 2017)::int)::varchar(4);
      END IF;
    RETURN NEW;
    END;
    $$;


ALTER FUNCTION demo.change_year() OWNER TO postgres;

--
-- Name: count_total(); Type: FUNCTION; Schema: demo; Owner: postgres
--

CREATE FUNCTION demo.count_total() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION demo.count_total() OWNER TO postgres;

--
-- Name: foo(integer); Type: FUNCTION; Schema: demo; Owner: postgres
--

CREATE FUNCTION demo.foo(integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION demo.foo(integer) OWNER TO postgres;

--
-- Name: log_brochure_changes(); Type: FUNCTION; Schema: demo; Owner: postgres
--

CREATE FUNCTION demo.log_brochure_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
    IF NEW.brochure_amount <> OLD.brochure_amount THEN
      INSERT INTO logs(brochure_id, prev_amount, changed_on)
      VALUES(OLD.brochure_id, OLD.brochure_amount, now());
    END IF;

    RETURN NEW;
    END;
    $$;


ALTER FUNCTION demo.log_brochure_changes() OWNER TO postgres;

--
-- Name: search_items_of(text); Type: FUNCTION; Schema: demo; Owner: postgres
--

CREATE FUNCTION demo.search_items_of(v_name text) RETURNS TABLE(f1 character varying, f2 character varying, f3 integer)
    LANGUAGE plpgsql
    AS $$  
    BEGIN
    Return QUERY(SELECT p.name, b.name as brochure_name, b.price
    FROM providers p
    INNER JOIN brochures b
    ON b.provider_id = p.id
    WHERE p.name = v_name);
    END;
$$;


ALTER FUNCTION demo.search_items_of(v_name text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: brochures; Type: TABLE; Schema: demo; Owner: postgres
--

CREATE TABLE demo.brochures (
    id integer NOT NULL,
    vendor_code character varying(7) NOT NULL,
    name character varying NOT NULL,
    release_year character varying(4) DEFAULT '0000'::character varying,
    provider_id integer NOT NULL,
    price integer NOT NULL,
    CONSTRAINT check_code CHECK (((length((vendor_code)::text) = 7) AND (((vendor_code)::text ~~ 'B%'::text) OR ((vendor_code)::text ~~ 'O%'::text))))
);


ALTER TABLE demo.brochures OWNER TO postgres;

--
-- Name: brochures_id_seq; Type: SEQUENCE; Schema: demo; Owner: postgres
--

CREATE SEQUENCE demo.brochures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE demo.brochures_id_seq OWNER TO postgres;

--
-- Name: brochures_id_seq; Type: SEQUENCE OWNED BY; Schema: demo; Owner: postgres
--

ALTER SEQUENCE demo.brochures_id_seq OWNED BY demo.brochures.id;


--
-- Name: employees; Type: TABLE; Schema: demo; Owner: postgres
--

CREATE TABLE demo.employees (
    id integer NOT NULL,
    name character varying NOT NULL,
    "position" character varying NOT NULL,
    dep_name character varying NOT NULL
);


ALTER TABLE demo.employees OWNER TO postgres;

--
-- Name: employees_id_seq; Type: SEQUENCE; Schema: demo; Owner: postgres
--

CREATE SEQUENCE demo.employees_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE demo.employees_id_seq OWNER TO postgres;

--
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: demo; Owner: postgres
--

ALTER SEQUENCE demo.employees_id_seq OWNED BY demo.employees.id;


--
-- Name: invoice; Type: TABLE; Schema: demo; Owner: postgres
--

CREATE TABLE demo.invoice (
    id integer NOT NULL,
    receiver_id integer NOT NULL,
    warehouse_id integer NOT NULL,
    brochure_id integer NOT NULL,
    amount integer NOT NULL,
    total_price integer DEFAULT 0,
    date timestamp(6) without time zone NOT NULL
);


ALTER TABLE demo.invoice OWNER TO postgres;

--
-- Name: invoice_id_seq; Type: SEQUENCE; Schema: demo; Owner: postgres
--

CREATE SEQUENCE demo.invoice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE demo.invoice_id_seq OWNER TO postgres;

--
-- Name: invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: demo; Owner: postgres
--

ALTER SEQUENCE demo.invoice_id_seq OWNED BY demo.invoice.id;


--
-- Name: logs; Type: TABLE; Schema: demo; Owner: postgres
--

CREATE TABLE demo.logs (
    id integer NOT NULL,
    brochure_id integer NOT NULL,
    prev_amount integer NOT NULL,
    changed_on timestamp(6) without time zone NOT NULL
);


ALTER TABLE demo.logs OWNER TO postgres;

--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: demo; Owner: postgres
--

CREATE SEQUENCE demo.logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE demo.logs_id_seq OWNER TO postgres;

--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: demo; Owner: postgres
--

ALTER SEQUENCE demo.logs_id_seq OWNED BY demo.logs.id;


--
-- Name: providers; Type: TABLE; Schema: demo; Owner: postgres
--

CREATE TABLE demo.providers (
    id integer NOT NULL,
    name character varying NOT NULL,
    address character varying NOT NULL,
    phone character varying(11) NOT NULL
);


ALTER TABLE demo.providers OWNER TO postgres;

--
-- Name: providers_id_seq; Type: SEQUENCE; Schema: demo; Owner: postgres
--

CREATE SEQUENCE demo.providers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE demo.providers_id_seq OWNER TO postgres;

--
-- Name: providers_id_seq; Type: SEQUENCE OWNED BY; Schema: demo; Owner: postgres
--

ALTER SEQUENCE demo.providers_id_seq OWNED BY demo.providers.id;


--
-- Name: warehouse; Type: TABLE; Schema: demo; Owner: postgres
--

CREATE TABLE demo.warehouse (
    id integer NOT NULL,
    name character varying NOT NULL,
    brochure_id integer NOT NULL,
    manager_name character varying NOT NULL,
    brochure_amount integer NOT NULL,
    CONSTRAINT check_name CHECK (((name)::text = ANY ((ARRAY['Основной'::character varying, 'Вспомогательный'::character varying])::text[])))
);


ALTER TABLE demo.warehouse OWNER TO postgres;

--
-- Name: warehouse_id_seq; Type: SEQUENCE; Schema: demo; Owner: postgres
--

CREATE SEQUENCE demo.warehouse_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE demo.warehouse_id_seq OWNER TO postgres;

--
-- Name: warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: demo; Owner: postgres
--

ALTER SEQUENCE demo.warehouse_id_seq OWNED BY demo.warehouse.id;


--
-- Name: brochures id; Type: DEFAULT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.brochures ALTER COLUMN id SET DEFAULT nextval('demo.brochures_id_seq'::regclass);


--
-- Name: employees id; Type: DEFAULT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.employees ALTER COLUMN id SET DEFAULT nextval('demo.employees_id_seq'::regclass);


--
-- Name: invoice id; Type: DEFAULT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.invoice ALTER COLUMN id SET DEFAULT nextval('demo.invoice_id_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.logs ALTER COLUMN id SET DEFAULT nextval('demo.logs_id_seq'::regclass);


--
-- Name: providers id; Type: DEFAULT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.providers ALTER COLUMN id SET DEFAULT nextval('demo.providers_id_seq'::regclass);


--
-- Name: warehouse id; Type: DEFAULT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.warehouse ALTER COLUMN id SET DEFAULT nextval('demo.warehouse_id_seq'::regclass);


--
-- Data for Name: brochures; Type: TABLE DATA; Schema: demo; Owner: postgres
--

COPY demo.brochures (id, vendor_code, name, release_year, provider_id, price) FROM stdin;
1	O000340	Садко	2020	1	179
2	O000341	Свадьба Фигаро	2020	2	179
4	O000343	Спящая красавица	2020	4	179
5	O000344	Щелкунчик	2020	1	179
8	O000347	Жизель	2020	5	179
3	B000342	Искатели жемчуга	2018	3	196
6	B000345	Травиата	2018	3	196
7	B000346	Манон Леско	2017	5	196
\.


--
-- Data for Name: employees; Type: TABLE DATA; Schema: demo; Owner: postgres
--

COPY demo.employees (id, name, "position", dep_name) FROM stdin;
1	Воробьева Ирина Олеговна	Старший капельдинер	Служба главного администратора
2	Семиречанский Иван Павлович	Заместитель начальника отдела	Пресс-служба
3	Заболдина Алина Николаевна	Товаровед	Отдел продаж сувенирной продукции
4	Тимофеева Ольга Петровна	Главный специалист	Пресс-служба
5	Терлецкая Анна Николаевна	Редактор	Литературно-издательский цех
6	Красин Владислав Алексеевич	Помощник генерального директора	Аппарат управления
7	Меськова Любовь Константиновна	Старший капельдинер	Служба главного администратора Новой сцены
8	Улитина Инга Вадимовна	Директор музея	Музей
9	Алдошин Игорь Дмитриевич	Старший капельдинер	Гастрольный отдел
\.


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: demo; Owner: postgres
--

COPY demo.invoice (id, receiver_id, warehouse_id, brochure_id, amount, total_price, date) FROM stdin;
1	1	1	1	500	89500	2018-04-10 00:00:00
3	7	3	3	350	68600	2020-01-28 00:00:00
7	8	7	7	300	58800	2020-06-04 00:00:00
8	5	8	8	260	46540	2018-02-15 00:00:00
4	4	4	4	500	89500	2019-11-02 00:00:00
9	1	4	4	320	57280	2019-12-11 00:00:00
5	6	5	5	410	73390	2020-05-26 00:00:00
10	2	5	5	540	96660	2020-11-10 00:00:00
2	2	2	2	600	107400	2019-05-22 00:00:00
11	3	2	2	245	43855	2019-09-07 00:00:00
6	3	6	6	285	55860	2019-09-16 00:00:00
12	7	6	6	570	111720	2019-10-21 00:00:00
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: demo; Owner: postgres
--

COPY demo.logs (id, brochure_id, prev_amount, changed_on) FROM stdin;
1	1	1000	2020-12-18 14:39:26.220626
\.


--
-- Data for Name: providers; Type: TABLE DATA; Schema: demo; Owner: postgres
--

COPY demo.providers (id, name, address, phone) FROM stdin;
1	Аркана	Москва, улица Нагорная, дом 1, стр 1	74952278731
2	Театралис	Санкт-Петербург, улица Миллионная, дом 8	79215956238
3	Арт-пати	Санкт-Петербург, улица Рубинштейна, дом 46, стр 3	79284415950
4	Рассвет	Самара, улица Садовая, дом 32, стр 8	79636621785
5	ЭмЭйчАрт	Москва, улица Большая Лубянка, дом 15	74953456170
\.


--
-- Data for Name: warehouse; Type: TABLE DATA; Schema: demo; Owner: postgres
--

COPY demo.warehouse (id, name, brochure_id, manager_name, brochure_amount) FROM stdin;
2	Основной	2	Любимова Наталья Владимировна	1500
3	Вспомогательный	3	Козлова Мария Дмитриевна	1000
4	Основной	4	Любимова Наталья Владимировна	2000
5	Основной	5	Любимова Наталья Владимировна	2000
6	Вспомогательный	6	Козлова Мария Дмитриевна	1800
7	Вспомогательный	7	Козлова Мария Дмитриевна	1500
8	Основной	8	Любимова Наталья Владимировна	1000
1	Основной	1	Любимова Наталья Владимировна	1001
\.


--
-- Name: brochures_id_seq; Type: SEQUENCE SET; Schema: demo; Owner: postgres
--

SELECT pg_catalog.setval('demo.brochures_id_seq', 8, true);


--
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: demo; Owner: postgres
--

SELECT pg_catalog.setval('demo.employees_id_seq', 9, true);


--
-- Name: invoice_id_seq; Type: SEQUENCE SET; Schema: demo; Owner: postgres
--

SELECT pg_catalog.setval('demo.invoice_id_seq', 12, true);


--
-- Name: logs_id_seq; Type: SEQUENCE SET; Schema: demo; Owner: postgres
--

SELECT pg_catalog.setval('demo.logs_id_seq', 1, true);


--
-- Name: providers_id_seq; Type: SEQUENCE SET; Schema: demo; Owner: postgres
--

SELECT pg_catalog.setval('demo.providers_id_seq', 5, true);


--
-- Name: warehouse_id_seq; Type: SEQUENCE SET; Schema: demo; Owner: postgres
--

SELECT pg_catalog.setval('demo.warehouse_id_seq', 8, true);


--
-- Name: brochures brochures_name_key; Type: CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.brochures
    ADD CONSTRAINT brochures_name_key UNIQUE (name);


--
-- Name: brochures brochures_pkey; Type: CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.brochures
    ADD CONSTRAINT brochures_pkey PRIMARY KEY (id);


--
-- Name: brochures brochures_vendor_code_key; Type: CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.brochures
    ADD CONSTRAINT brochures_vendor_code_key UNIQUE (vendor_code);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- Name: invoice invoice_pkey; Type: CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.invoice
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: providers providers_pkey; Type: CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.providers
    ADD CONSTRAINT providers_pkey PRIMARY KEY (id);


--
-- Name: warehouse warehouse_pkey; Type: CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.warehouse
    ADD CONSTRAINT warehouse_pkey PRIMARY KEY (id);


--
-- Name: warehouse brochure_changes; Type: TRIGGER; Schema: demo; Owner: postgres
--

CREATE TRIGGER brochure_changes BEFORE UPDATE ON demo.warehouse FOR EACH ROW EXECUTE FUNCTION demo.log_brochure_changes();


--
-- Name: brochures change_year; Type: TRIGGER; Schema: demo; Owner: postgres
--

CREATE TRIGGER change_year BEFORE INSERT OR UPDATE ON demo.brochures FOR EACH ROW EXECUTE FUNCTION demo.change_year();


--
-- Name: brochures brochures_provider_id_fkey; Type: FK CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.brochures
    ADD CONSTRAINT brochures_provider_id_fkey FOREIGN KEY (provider_id) REFERENCES demo.providers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invoice invoice_brochure_id_fkey; Type: FK CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.invoice
    ADD CONSTRAINT invoice_brochure_id_fkey FOREIGN KEY (brochure_id) REFERENCES demo.brochures(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invoice invoice_receiver_id_fkey; Type: FK CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.invoice
    ADD CONSTRAINT invoice_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES demo.employees(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invoice invoice_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.invoice
    ADD CONSTRAINT invoice_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES demo.warehouse(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: warehouse warehouse_brochure_id_fkey; Type: FK CONSTRAINT; Schema: demo; Owner: postgres
--

ALTER TABLE ONLY demo.warehouse
    ADD CONSTRAINT warehouse_brochure_id_fkey FOREIGN KEY (brochure_id) REFERENCES demo.brochures(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

