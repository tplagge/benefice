--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: assessed; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA assessed;


SET search_path = assessed, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: apts; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE apts (
    pin character varying(20),
    address character varying(100),
    lav_2011 character varying(20),
    lav_2012 character varying(20),
    bav_2011 character varying(20),
    bav_2012 character varying(20),
    bldg_age character varying(4),
    bldg_sqft character varying(20),
    bldg_units character varying(10)
);


--
-- Name: assessed_sent_pins; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE assessed_sent_pins (
    pin character varying(20),
    nodash character varying(20)
);


--
-- Name: condos; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE condos (
    pin character varying(20),
    address character varying(150),
    lav_2011 character varying(50),
    lav_2012 character varying(50),
    mkt_val_2011 character varying(100),
    mkt_val_2012 character varying(100),
    bav_2011 character varying(100),
    bav_2012 character varying(100),
    bldg_age character varying(20),
    cur_year character varying(10),
    last_year character varying(10)
);


--
-- Name: exempt; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE exempt (
    pin character varying(20)
);


--
-- Name: res202; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE res202 (
    pin character varying(20),
    address character varying(100),
    lav_2011 character varying(20),
    lav_2012 character varying(20),
    bav_2011 character varying(20),
    bav_2012 character varying(20),
    bldg_age character varying(4),
    mkt_val_2011 character varying(50),
    mkt_val_2012 character varying(50),
    res_type character varying(100),
    res_use character varying(100),
    res_apts character varying(100),
    ext_const character varying(100),
    full_bath character varying(100),
    half_bath character varying(100),
    basement character varying(200),
    attic character varying(100),
    central_air character varying(100),
    fireplace character varying(100),
    garage character varying(100),
    cur_year character varying(10),
    last_year character varying(10)
);


--
-- Name: vacant; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE vacant (
    pin character varying(20),
    address character varying(150),
    lav_2011 character varying(50),
    lav_2012 character varying(50)
);


--
-- Name: vacant_adjacent; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE vacant_adjacent (
    pin character varying(20),
    address character varying(150),
    lav_2011 character varying(50),
    lav_2012 character varying(50),
    mkt_val_2011 character varying(100),
    mkt_val_2012 character varying(100)
);


--
-- Name: vacant_improved; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE vacant_improved (
    pin character varying(20),
    address character varying(100),
    lav_last character varying(20),
    lav_current character varying(20),
    bav_last character varying(20),
    bav_current character varying(20),
    bldg_age character varying(4),
    current_year character varying(10),
    last_year character varying(10)
);

--
-- Name: garage; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE garage (
    pin character varying(20),
    address character varying(100),
    lav_2011 character varying(20),
    lav_2012 character varying(20),
    bav_2011 character varying(20),
    bav_2012 character varying(20),
    bldg_age character varying(4)
);


--
-- Name: invalid_pins; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE invalid_pins (
    pin character varying(20)
);


--
-- Name: pins_propclass_tocheck; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE pins_propclass_tocheck (
    sent_pin character varying(20),
    property_class character varying(200)
);


--
-- Name: propclass; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE propclass (
    property_class character varying(5),
    description character varying(200),
    shortdesc character varying(200),
    tilemill_display character varying(100)
);


--
-- Name: retry; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE retry (
    pin character varying(20),
    propclass character varying(5)
);


--
-- Name: sent_pins; Type: TABLE; Schema: assessed; Owner: -; Tablespace: 
--

CREATE TABLE sent_pins (
    pin character varying(20)
);


--
-- PostgreSQL database dump complete
--

