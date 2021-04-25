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
-- Name: test; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA test;


ALTER SCHEMA test OWNER TO postgres;

--
-- Name: change_availability(); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION test.change_availability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      IF NEW.free_amount = 0 THEN
        NEW.is_available = False;

      ELSIF NEW.free_amount > 0 THEN
        NEW.is_available = True;
      END IF;
    RETURN NEW;
    END;
    $$;


ALTER FUNCTION test.change_availability() OWNER TO postgres;

--
-- Name: count_total(); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION test.count_total() RETURNS void
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION test.count_total() OWNER TO postgres;

--
-- Name: log_item_name_changes(); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION test.log_item_name_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
    IF NEW.item_name <> OLD.item_name THEN
      INSERT INTO item_audits(item_id, previous_name, changed_on)
      VALUES(OLD.id, OLD.item_name, now());
    END IF;

    RETURN NEW;
    END;
    $$;


ALTER FUNCTION test.log_item_name_changes() OWNER TO postgres;

--
-- Name: search_items_of(text); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION test.search_items_of(p_name text) RETURNS TABLE(f1 character varying, f2 character varying, f3 character varying, f4 jsonb)
    LANGUAGE plpgsql
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
$$;


ALTER FUNCTION test.search_items_of(p_name text) OWNER TO postgres;

--
-- Name: set_zero(); Type: FUNCTION; Schema: test; Owner: postgres
--

CREATE FUNCTION test.set_zero() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
      IF OLD.total_price IS NULL THEN
        NEW.total_price = 0;
      END IF;

    RETURN NEW;
    END;
    $$;


ALTER FUNCTION test.set_zero() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.categories (
    id integer NOT NULL,
    category character varying(11) NOT NULL,
    specification jsonb NOT NULL,
    CONSTRAINT check_category CHECK (((category)::text = ANY ((ARRAY['Snowboard'::character varying, 'Ski'::character varying, 'Ice skates'::character varying])::text[])))
);


ALTER TABLE test.categories OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE test.categories_id_seq OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE test.categories_id_seq OWNED BY test.categories.id;


--
-- Name: cust_shopping_bag; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.cust_shopping_bag (
    id integer NOT NULL,
    item_id integer NOT NULL,
    customer_id integer NOT NULL,
    amount_chosen integer DEFAULT 1 NOT NULL,
    days_amount integer DEFAULT 1,
    total_price integer,
    CONSTRAINT cust_shopping_bag_amount_chosen_check CHECK ((amount_chosen >= 0)),
    CONSTRAINT cust_shopping_bag_days_amount_check CHECK ((days_amount >= 0))
);


ALTER TABLE test.cust_shopping_bag OWNER TO postgres;

--
-- Name: cust_shopping_bag_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.cust_shopping_bag_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE test.cust_shopping_bag_id_seq OWNER TO postgres;

--
-- Name: cust_shopping_bag_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE test.cust_shopping_bag_id_seq OWNED BY test.cust_shopping_bag.id;


--
-- Name: customer; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.customer (
    id integer NOT NULL,
    email character varying NOT NULL,
    full_name character varying NOT NULL,
    phone character varying(11) NOT NULL,
    age integer NOT NULL,
    country character varying NOT NULL,
    CONSTRAINT customer_age_check CHECK ((age > 13)),
    CONSTRAINT customer_country_check CHECK (((country)::text = 'Russia'::text))
);


ALTER TABLE test.customer OWNER TO postgres;

--
-- Name: customer_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE test.customer_id_seq OWNER TO postgres;

--
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE test.customer_id_seq OWNED BY test.customer.id;


--
-- Name: item_audits; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.item_audits (
    id integer NOT NULL,
    item_id integer NOT NULL,
    previous_name character varying NOT NULL,
    changed_on timestamp(6) without time zone NOT NULL
);


ALTER TABLE test.item_audits OWNER TO postgres;

--
-- Name: item_audits_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.item_audits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE test.item_audits_id_seq OWNER TO postgres;

--
-- Name: item_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE test.item_audits_id_seq OWNED BY test.item_audits.id;


--
-- Name: items; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.items (
    id integer NOT NULL,
    manufacture_id integer NOT NULL,
    item_name character varying NOT NULL,
    category_id integer NOT NULL,
    item_size integer NOT NULL,
    release_year character varying(4) NOT NULL,
    rent_price numeric(6,2) NOT NULL,
    CONSTRAINT items_item_size_check CHECK (((item_size >= 34) AND (item_size < 48)))
);


ALTER TABLE test.items OWNER TO postgres;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE test.items_id_seq OWNER TO postgres;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE test.items_id_seq OWNED BY test.items.id;


--
-- Name: manufactures; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.manufactures (
    id integer NOT NULL,
    manufacture_name character varying(20) NOT NULL,
    country character varying(20) DEFAULT 'Russia'::character varying NOT NULL,
    city character varying NOT NULL,
    phone character varying(11) NOT NULL
);


ALTER TABLE test.manufactures OWNER TO postgres;

--
-- Name: manufactures_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.manufactures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE test.manufactures_id_seq OWNER TO postgres;

--
-- Name: manufactures_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE test.manufactures_id_seq OWNED BY test.manufactures.id;


--
-- Name: store; Type: TABLE; Schema: test; Owner: postgres
--

CREATE TABLE test.store (
    id integer NOT NULL,
    item_id integer NOT NULL,
    free_amount integer NOT NULL,
    is_available boolean DEFAULT true,
    address character varying NOT NULL,
    phone character varying(11) NOT NULL,
    CONSTRAINT store_free_amount_check CHECK ((free_amount >= 0))
);


ALTER TABLE test.store OWNER TO postgres;

--
-- Name: store_id_seq; Type: SEQUENCE; Schema: test; Owner: postgres
--

CREATE SEQUENCE test.store_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE test.store_id_seq OWNER TO postgres;

--
-- Name: store_id_seq; Type: SEQUENCE OWNED BY; Schema: test; Owner: postgres
--

ALTER SEQUENCE test.store_id_seq OWNED BY test.store.id;


--
-- Name: categories id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.categories ALTER COLUMN id SET DEFAULT nextval('test.categories_id_seq'::regclass);


--
-- Name: cust_shopping_bag id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.cust_shopping_bag ALTER COLUMN id SET DEFAULT nextval('test.cust_shopping_bag_id_seq'::regclass);


--
-- Name: customer id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.customer ALTER COLUMN id SET DEFAULT nextval('test.customer_id_seq'::regclass);


--
-- Name: item_audits id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.item_audits ALTER COLUMN id SET DEFAULT nextval('test.item_audits_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.items ALTER COLUMN id SET DEFAULT nextval('test.items_id_seq'::regclass);


--
-- Name: manufactures id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.manufactures ALTER COLUMN id SET DEFAULT nextval('test.manufactures_id_seq'::regclass);


--
-- Name: store id; Type: DEFAULT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.store ALTER COLUMN id SET DEFAULT nextval('test.store_id_seq'::regclass);


--
-- Data for Name: categories; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.categories (id, category, specification) FROM stdin;
1	Snowboard	{"num": 1, "type": "mountain snowboard", "shape": "twin-tip"}
2	Snowboard	{"num": 1, "type": "trainee`s snowboard", "shape": "directional"}
3	Ice skates	{"num": 2, "type": "figure skates"}
4	Ski	{"num": 2, "type": "all-mountain ski", "width mm": 90}
\.


--
-- Data for Name: cust_shopping_bag; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.cust_shopping_bag (id, item_id, customer_id, amount_chosen, days_amount, total_price) FROM stdin;
1	1	1	2	2	4000
3	9	3	1	1	2000
2	5	1	1	2	3400
4	5	2	2	1	3400
5	2	3	1	5	6000
\.


--
-- Data for Name: customer; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.customer (id, email, full_name, phone, age, country) FROM stdin;
1	peter@mail.ru	Peter Basmannov	79137846756	23	Russia
2	lev@test.ru	Lev Merkulov	79145558944	22	Russia
3	vlad_k@mail.ru	Vlad Kutashov	79523536789	21	Russia
\.


--
-- Data for Name: item_audits; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.item_audits (id, item_id, previous_name, changed_on) FROM stdin;
1	1	Riders season boys	2020-12-10 02:12:27.493028
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.items (id, manufacture_id, item_name, category_id, item_size, release_year, rent_price) FROM stdin;
2	1	Riders season boys	1	40	2015	1199.99
3	1	Riders season boys	1	41	2015	1299.99
4	9	Best ice skates	3	42	2020	499.99
5	3	Ski premium class	4	44	2020	1699.99
6	4	Girls snowboard	2	37	2019	1599.99
7	4	Girls snowboard	2	36	2019	1499.99
8	4	Girls snowboard	2	35	2019	1399.99
9	5	Basic snowboard	1	40	2018	1999.99
1	1	Smallest boys size	1	39	2015	999.99
\.


--
-- Data for Name: manufactures; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.manufactures (id, manufacture_name, country, city, phone) FROM stdin;
1	Vostok	Russia	Irkutsk	79124446730
2	Sputnik	Russia	Moscow	79054446767
3	Fischer	Austria	Vienna	79054449999
4	Roxy	Australia	Sidney	79054445589
5	Burton	USA	Berlingthon	79054446887
6	Salomon	France	Paris	79153346567
7	Lib Tech	USA	Washington	79059956877
8	Volki	Germany	Strassburg	79058896767
9	Graf	Switzerland	Geneva	79155556767
\.


--
-- Data for Name: store; Type: TABLE DATA; Schema: test; Owner: postgres
--

COPY test.store (id, item_id, free_amount, is_available, address, phone) FROM stdin;
2	2	3	t	12, Morskaya str, Sochi	79157846731
3	3	5	t	12, Morskaya str, Sochi	79157846731
4	4	1	t	12, Morskaya str, Sochi	79157846731
5	5	4	t	12, Morskaya str, Sochi	79157846731
6	6	5	t	1, Gornaya str, Kemerovo	79139946744
7	7	5	t	1, Gornaya str, Kemerovo	79139946744
8	8	5	t	1, Gornaya str, Kemerovo	79139946744
9	9	1	t	1, Gornaya str, Kemerovo	79139946744
1	1	2	t	12, Morskaya str, Sochi	79157846731
\.


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.categories_id_seq', 4, true);


--
-- Name: cust_shopping_bag_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.cust_shopping_bag_id_seq', 5, true);


--
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.customer_id_seq', 3, true);


--
-- Name: item_audits_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.item_audits_id_seq', 1, true);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.items_id_seq', 9, true);


--
-- Name: manufactures_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.manufactures_id_seq', 9, true);


--
-- Name: store_id_seq; Type: SEQUENCE SET; Schema: test; Owner: postgres
--

SELECT pg_catalog.setval('test.store_id_seq', 9, true);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: cust_shopping_bag cust_shopping_bag_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.cust_shopping_bag
    ADD CONSTRAINT cust_shopping_bag_pkey PRIMARY KEY (id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: item_audits item_audits_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.item_audits
    ADD CONSTRAINT item_audits_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: manufactures manufactures_manufacture_name_key; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.manufactures
    ADD CONSTRAINT manufactures_manufacture_name_key UNIQUE (manufacture_name);


--
-- Name: manufactures manufactures_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.manufactures
    ADD CONSTRAINT manufactures_pkey PRIMARY KEY (id);


--
-- Name: store store_pkey; Type: CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.store
    ADD CONSTRAINT store_pkey PRIMARY KEY (id);


--
-- Name: store change_availability; Type: TRIGGER; Schema: test; Owner: postgres
--

CREATE TRIGGER change_availability BEFORE INSERT OR UPDATE ON test.store FOR EACH ROW EXECUTE FUNCTION test.change_availability();


--
-- Name: items item_name_changes; Type: TRIGGER; Schema: test; Owner: postgres
--

CREATE TRIGGER item_name_changes BEFORE UPDATE ON test.items FOR EACH ROW EXECUTE FUNCTION test.log_item_name_changes();


--
-- Name: cust_shopping_bag set_zero; Type: TRIGGER; Schema: test; Owner: postgres
--

CREATE TRIGGER set_zero BEFORE INSERT OR UPDATE ON test.cust_shopping_bag FOR EACH ROW EXECUTE FUNCTION test.set_zero();


--
-- Name: cust_shopping_bag cust_shopping_bag_customer_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.cust_shopping_bag
    ADD CONSTRAINT cust_shopping_bag_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES test.customer(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cust_shopping_bag cust_shopping_bag_item_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.cust_shopping_bag
    ADD CONSTRAINT cust_shopping_bag_item_id_fkey FOREIGN KEY (item_id) REFERENCES test.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: items items_category_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.items
    ADD CONSTRAINT items_category_id_fkey FOREIGN KEY (category_id) REFERENCES test.categories(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: items items_manufacture_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.items
    ADD CONSTRAINT items_manufacture_id_fkey FOREIGN KEY (manufacture_id) REFERENCES test.manufactures(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: store store_item_id_fkey; Type: FK CONSTRAINT; Schema: test; Owner: postgres
--

ALTER TABLE ONLY test.store
    ADD CONSTRAINT store_item_id_fkey FOREIGN KEY (item_id) REFERENCES test.items(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

