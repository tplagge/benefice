--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = tif, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: pins_master; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE pins_master (
    pin character varying(30),
    taxcode integer,
    city character varying(20),
    amt_billed money,
    year integer,
    id integer NOT NULL
);


--
-- Name: pins_master_id_seq; Type: SEQUENCE; Schema: tif; Owner: -
--

CREATE SEQUENCE pins_master_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pins_master_id_seq; Type: SEQUENCE OWNED BY; Schema: tif; Owner: -
--

ALTER SEQUENCE pins_master_id_seq OWNED BY pins_master.id;


--
-- Name: id; Type: DEFAULT; Schema: tif; Owner: -
--

ALTER TABLE ONLY pins_master ALTER COLUMN id SET DEFAULT nextval('pins_master_id_seq'::regclass);


--
-- Name: pins_master_pkey; Type: CONSTRAINT; Schema: tif; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pins_master
    ADD CONSTRAINT pins_master_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

