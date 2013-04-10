CREATE SCHEMA benefice;

SET search_path to dataportal,benefice,public;

CREATE SEQUENCE benefice.bldg_gid_seq;

CREATE TABLE benefice.building_footprint (
  bldg_gid    INTEGER NOT NULL DEFAULT nextval('bldg_gid_seq'),
  num_stories INTEGER,
  sqft        FLOAT,
  year_built  INTEGER,
  num_units   INTEGER,
  start_addr  INTEGER,
  end_addr    INTEGER,
  direction   VARCHAR(1),
  street_name VARCHAR(35),
  street_type VARCHAR(5)
);
  
ALTER SEQUENCE benefice.bldg_gid_seq OWNED BY benefice.building_footprint.bldg_gid;
  
SELECT AddGeometryColumn('benefice','building_footprint','the_geom',3435,'MULTIPOLYGON',2);
SELECT AddGeometryColumn('benefice','building_footprint','centroid',3435,'POINT',2);

/* zero or more addresses correspond to each row in building_footprint */
/* addr_number's are inferred from the address range in the data portal building footprints */
CREATE TABLE benefice.building_address (
  bldg_gid    INTEGER DEFAULT NULL,
  addr_number INTEGER,
  end_addr    INTEGER DEFAULT NULL,
  direction   VARCHAR(1),
  street_name VARCHAR(35),
  street_type VARCHAR(5)
);

/* many-to-one relationship with building_footprint */
CREATE TABLE benefice.construction_permits (
  bldg_gid    INTEGER DEFAULT NULL,
  issue_date  DATE,
  permit_num  INTEGER,
  permit_type VARCHAR,
  work_desc   VARCHAR
);

/* many-to-one relationship with building_footprint */
CREATE TABLE benefice.building_violations (
  bldg_gid            INTEGER DEFAULT NULL,
  violation_date      DATE,
  violation_text      VARCHAR,
  inspection_category VARCHAR,
  inspection_result   VARCHAR
);

/* many-to-one relationship with building_footprint */
CREATE TABLE benefice.demolition_permits (
  bldg_gid               INTEGER DEFAULT NULL,
  demolition_permit_date DATE
);      


/* one-to-many relationship with building_footprint */
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


/* one-to-many relationship with building_footprint */
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
