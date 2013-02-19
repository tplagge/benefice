CREATE OR REPLACE FUNCTION geocode(tbl text, pkey int, addrfield text)
RETURNS VOID AS
$$

-- geocode: function to geocode addresses, either to a building (not currently
-- implemented), or an interpolated point along the street centerline file.
-- Takes three arguments, the name of the table to geocode, that table's 
-- integer primary key, and the address field.

CREATE TABLE IF NOT EXISTS addrmatch (id int, address text, str_num text, str_dir text, str_name text, str_typ text, str_pos char(1), bldg_gid int, the_geom geometry);

DELETE FROM addrmatch;

INSERT INTO addrmatch (id, address) SELECT $2, $3 FROM $1;

 
UPDATE addrmatch SET
  str_num = split_part(address, ' ', 1),
  str_dir = split_part(address, ' ', 2),
  str_name = split_part(address, ' ', 3),
  str_typ = split_part(address, ' ', 4);

-- TODO: regex match on fields to test if they look
-- like they're supposed to, then loop through
-- names_streets table until street names are correct

UPDATE addrmatch SET
  str_pos = CASE WHEN
    MOD(streets.l_f_add, 2) = MOD(addrmatch.str_num, 2)
    THEN 'L' ELSE 'R' END,

    the_geom = ST_Line_Interpolate_Point(
      ST_LineMerge(streets.the_geom),
      (addrmatch.str_num::int - least(streets.l_f_add, streets.r_f_add)) /
      (greatest(streets.l_f_add, streets.r_t_add) - least(streets.l_f_add, streets.r_f_add) ) )

    FROM streets WHERE
      streets.street_nam = addrmatch.str_name
      AND
      streets.pre_dir = addrmatch.str_dir
      AND
      (addrmatch.str_num::int BETWEEN streets.l_f_add AND streets.l_t_add
        OR
      addrmatch.str_num::int BETWEEN streets.r_f_add AND streets.r_t_add)
      AND
      -- ensure that addresses matched to buildings don't get overwritten
      addrmatch.the_geom IS NULL;
      AND addrmatch.str_num ~ '\d{1,6}$';

$$
LANGUAGE 'sql' IMMUTABLE STRICT;
