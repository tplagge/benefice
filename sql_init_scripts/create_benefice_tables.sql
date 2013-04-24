DROP SCHEMA benefice CASCADE;

CREATE SCHEMA benefice;

SET search_path TO benefice,public;

/* BUILDINGS AND ADDRESSES ***************************************************/

CREATE SEQUENCE benefice.bldg_gid_seq;

CREATE TABLE benefice.building_footprints (
  bldg_gid    INTEGER NOT NULL DEFAULT nextval('bldg_gid_seq'),
  num_stories INTEGER,
  sqft        FLOAT,
  year_built  INTEGER,
  num_units   INTEGER,
  start_addr  INTEGER,
  end_addr    INTEGER,
  street_dir  VARCHAR(1),
  street_name VARCHAR(35),
  street_type VARCHAR(5),
  unit_name   VARCHAR(8)
);
  
ALTER SEQUENCE benefice.bldg_gid_seq 
  OWNED BY benefice.building_footprints.bldg_gid;
ALTER TABLE ONLY benefice.building_footprints
  ADD CONSTRAINT building_footprints_pkey PRIMARY KEY (bldg_gid);
ALTER TABLE ONLY benefice.building_footprints
  ADD CONSTRAINT building_footprints_unique UNIQUE (bldg_gid);
  
SELECT AddGeometryColumn('benefice','building_footprints','the_geom',3435,'MULTIPOLYGON',2);
SELECT AddGeometryColumn('benefice','building_footprints','centroid',3435,'POINT',2);

/* zero or more addresses correspond to each row in building_footprints */
/* addr_numbers are inferred from the address range in the data portal building footprints */
CREATE TABLE benefice.building_addresses (
  bldg_gid    INTEGER DEFAULT NULL,
  addr_number INTEGER,
  street_dir  VARCHAR(1),
  street_name VARCHAR(35),
  street_type VARCHAR(5),
  unit_name   VARCHAR(8)
);

ALTER TABLE ONLY benefice.building_addresses
  ADD CONSTRAINT building_addresses_bldg_gid_fkey FOREIGN KEY (bldg_gid)
  REFERENCES benefice.building_footprints(bldg_gid);

/* PERMITS AND VIOLATIONS ****************************************************/
/* many-to-one relationship with building_footprints */
CREATE SEQUENCE benefice.construction_permits_id_seq;
CREATE TABLE benefice.construction_permits (
  id          INTEGER NOT NULL DEFAULT nextval('construction_permits_id_seq'),
  bldg_gid    INTEGER DEFAULT NULL,
  issue_date  DATE,
  permit_num  INTEGER,
  permit_type VARCHAR,
  work_desc   VARCHAR
);

ALTER SEQUENCE benefice.construction_permits_id_seq 
  OWNED BY benefice.construction_permits.id;
ALTER TABLE ONLY benefice.building_footprints
ALTER TABLE ONLY benefice.construction_permits
  ADD CONSTRAINT construction_permits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY benefice.construction_permits
  ADD CONSTRAINT construction_permits_unique UNIQUE (id);
ALTER TABLE ONLY benefice.construction_permits
  ADD CONSTRAINT construction_permits_bldg_gid_fkey FOREIGN KEY (bldg_gid)
  REFERENCES benefice.building_footprints(bldg_gid);

/* many-to-one relationship with building_footprints */
CREATE SEQUENCE benefice.building_violations_id_seq;
CREATE TABLE benefice.building_violations (
  id                  INTEGER NOT NULL DEFAULT nextval('building_violations_id_seq'),
  bldg_gid            INTEGER DEFAULT NULL,
  violation_date      DATE,
  violation_text      VARCHAR,
  inspection_category VARCHAR,
  inspection_result   VARCHAR
);

ALTER SEQUENCE benefice.building_violations_id_seq 
  OWNED BY benefice.building_violations.id;
ALTER TABLE ONLY benefice.building_violations
  ADD CONSTRAINT building_violations_pkey PRIMARY KEY (id);
ALTER TABLE ONLY benefice.building_violations
  ADD CONSTRAINT building_violations_unique UNIQUE (id);
ALTER TABLE ONLY benefice.building_violations
  ADD CONSTRAINT building_violations_bldg_gid_fkey FOREIGN KEY (bldg_gid)
  REFERENCES benefice.building_footprints(bldg_gid);

/* many-to-one relationship with building_footprints */
CREATE SEQUENCE benefice.demolition_permits_id_seq;
CREATE TABLE benefice.demolition_permits (
  id                     INTEGER NOT NULL DEFAULT nextval('demolition_permits_id_seq'),
  bldg_gid               INTEGER DEFAULT NULL,
  demolition_permit_date DATE
);      
ALTER SEQUENCE benefice.demolition_permits_id_seq 
  OWNED BY benefice.demolition_permits.id;
ALTER TABLE ONLY benefice.demolition_permits
  ADD CONSTRAINT demolition_permits_pkey PRIMARY KEY (id);
ALTER TABLE ONLY benefice.demolition_permits
  ADD CONSTRAINT demolition_permits_unique UNIQUE (id);
ALTER TABLE ONLY benefice.demolition_permits
  ADD CONSTRAINT demolition_permits_bldg_gid_fkey FOREIGN KEY (bldg_gid)
  REFERENCES benefice.building_footprints(bldg_gid);

/* CENSUS ********************************************************************/
/* Census block groups (bg) */
/* one-to-many relationship with building_footprints */
CREATE TABLE benefice.census_bg_2010 (
  state_id   INTEGER NOT NULL,
  county_id  INTEGER NOT NULL,
  tract_id   INTEGER NOT NULL,
  bg_num     INTEGER NOT NULL
);

SELECT AddGeometryColumn('benefice','census_bg_2010','the_geom',3435,'MULTIPOLYGON',2);
SELECT AddGeometryColumn('benefice','census_bg_2010','centroid',3435,'POINT',2);

CREATE TABLE benefice.census_bg_2000 (
  state_id   INTEGER NOT NULL,
  county_id  INTEGER NOT NULL,
  tract_id   INTEGER NOT NULL,
  bg_num     INTEGER NOT NULL
);

SELECT AddGeometryColumn('benefice','census_bg_2000','the_geom',3435,'MULTIPOLYGON',2);
SELECT AddGeometryColumn('benefice','census_bg_2000','centroid',3435,'POINT',2);

/* ZONING ********************************************************************/
/* one-to-many relationship with building_footprints */
CREATE TABLE benefice.zoning_poly (
  zone_id    INTEGER NOT NULL,
  zone_type  VARCHAR(20)
);

SELECT AddGeometryColumn('benefice','zoning_poly','the_geom',3435,'MULTIPOLYGON',2);
SELECT AddGeometryColumn('benefice','zoning_poly','centroid',3435,'POINT',2);

CREATE TABLE benefice.zone_type (
  zone_type   VARCHAR(20),
  description VARCHAR
);


