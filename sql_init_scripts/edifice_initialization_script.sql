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


--
-- Name: boundaries; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA boundaries;


--
-- Name: buildings; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA buildings;


--
-- Name: business; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA business;


--
-- Name: civic; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA civic;


--
-- Name: cta; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cta;


--
-- Name: demographics; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA demographics;


--
-- Name: education; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA education;


--
-- Name: environment; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA environment;


--
-- Name: health; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA health;


--
-- Name: history; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA history;


--
-- Name: safety; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA safety;


--
-- Name: tif; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tif;


--
-- Name: transportation; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA transportation;


SET search_path = public, pg_catalog;

--
-- Name: count_words(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION count_words(character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  tempString VARCHAR;
  tempInt INTEGER;
  count INTEGER := 1;
  lastSpace BOOLEAN := FALSE;
BEGIN
  IF $1 IS NULL THEN
    return -1;
  END IF;
  tempInt := length($1);
  IF tempInt = 0 THEN
    return 0;
  END IF;
  FOR i IN 1..tempInt LOOP
    tempString := substring($1 from i for 1);
    IF tempString = ' ' THEN
      IF NOT lastSpace THEN
        count := count + 1;
      END IF;
      lastSpace := TRUE;
    ELSE
      lastSpace := FALSE;
    END IF;
  END LOOP;
  return count;
END;
$_$;


--
-- Name: countdown(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION countdown() RETURNS void
    LANGUAGE sql
    AS $$
delete from assessed.pins_propclass_tocheck where sent_pin in ((select split_part(pin, '-', 1) || split_part(pin, '-', 2) || split_part(pin, '-', 3) || split_part(pin, '-', 4) || split_part(pin, '-', 5) from assessed.apts ));
delete from assessed.pins_propclass_tocheck where sent_pin in ((select split_part(pin, '-', 1) || split_part(pin, '-', 2) || split_part(pin, '-', 3) || split_part(pin, '-', 4) || split_part(pin, '-', 5) from assessed.condos ));
delete from assessed.pins_propclass_tocheck where sent_pin in ((select split_part(pin, '-', 1) || split_part(pin, '-', 2) || split_part(pin, '-', 3) || split_part(pin, '-', 4) || split_part(pin, '-', 5) from assessed.exempt ));
delete from assessed.pins_propclass_tocheck where sent_pin in ((select split_part(pin, '-', 1) || split_part(pin, '-', 2) || split_part(pin, '-', 3) || split_part(pin, '-', 4) || split_part(pin, '-', 5) from assessed.garage ));
delete from assessed.pins_propclass_tocheck where sent_pin in ((select split_part(pin, '-', 1) || split_part(pin, '-', 2) || split_part(pin, '-', 3) || split_part(pin, '-', 4) || split_part(pin, '-', 5) from assessed.res202 ));
delete from assessed.pins_propclass_tocheck where sent_pin in ((select split_part(pin, '-', 1) || split_part(pin, '-', 2) || split_part(pin, '-', 3) || split_part(pin, '-', 4) || split_part(pin, '-', 5) from assessed.vacant ));
delete from assessed.pins_propclass_tocheck where sent_pin in ((select split_part(pin, '-', 1) || split_part(pin, '-', 2) || split_part(pin, '-', 3) || split_part(pin, '-', 4) || split_part(pin, '-', 5) from assessed.vacant_adjacent ));
delete from assessed.pins_propclass_tocheck where sent_pin in ((select split_part(pin, '-', 1) || split_part(pin, '-', 2) || split_part(pin, '-', 3) || split_part(pin, '-', 4) || split_part(pin, '-', 5) from assessed.vacant_improved ));
$$;


--
-- Name: cull_null(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION cull_null(character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN coalesce($1,'');
END;
$_$;


--
-- Name: end_soundex(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION end_soundex(character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  tempString VARCHAR;
BEGIN
  tempString := substring($1, E'[ ,.\n\t\f]([a-zA-Z0-9]*)$');
  IF tempString IS NOT NULL THEN
    tempString := soundex(tempString);
  ELSE
    tempString := soundex($1);
  END IF;
  return tempString;
END;
$_$;


--
-- Name: geocode(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION geocode() RETURNS void
    LANGUAGE sql
    AS $$UPDATE user_address_input SET str_pos = CASE WHEN MOD(streets.l_f_add,2)=MOD(user_address_input.str_num,2) THEN 'L' ELSE 'R' END, the_geom = ST_Line_interpolate_point(ST_LineMerge(streets.the_geom), (user_address_input.str_num - least(streets.l_f_add, streets.r_f_add)) / (greatest(streets.l_t_add, streets.r_t_add) - least(streets.l_f_add, streets.r_f_add) ) ) FROM streets WHERE streets.street_nam = user_address_input.str_name AND streets.pre_dir = user_address_input.str_dir and (user_address_input.str_num BETWEEN streets.l_f_add AND streets.l_t_add OR user_address_input.str_num BETWEEN streets.r_f_add AND streets.r_t_add) AND user_address_input.the_geom IS NULL;$$;


--
-- Name: get_last_words(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_last_words(inputstring character varying, count integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  tempString VARCHAR;
  result VARCHAR := '';
BEGIN
  FOR i IN 1..count LOOP
    tempString := substring(inputString from '((?: )+[a-zA-Z0-9_]*)' || result || '$');

    IF tempString IS NULL THEN
      RETURN inputString;
    END IF;

    result := tempString || result;
  END LOOP;

  result := trim(both from result);

  RETURN result;
END;
$_$;


--
-- Name: includes_address(integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION includes_address(given_address integer, addr1 integer, addr2 integer, addr3 integer, addr4 integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  lmaxaddr INTEGER := -1;
  rmaxaddr INTEGER := -1;
  lminaddr INTEGER := -1;
  rminaddr INTEGER := -1;
  maxaddr INTEGER := -1;
  minaddr INTEGER := -1;
  verbose BOOLEAN := false;
BEGIN
  IF addr1 IS NOT NULL THEN
    maxaddr := addr1;
    minaddr := addr1;
    lmaxaddr := addr1;
    lminaddr := addr1;
  END IF;

  IF addr2 IS NOT NULL THEN
    IF addr2 < minaddr OR minaddr = -1 THEN
      minaddr := addr2;
    END IF;
    IF addr2 > maxaddr OR maxaddr = -1 THEN
      maxaddr := addr2;
    END IF;
    IF addr2 > lmaxaddr OR lmaxaddr = -1 THEN
      lmaxaddr := addr2;
    END IF;
    IF addr2 < lminaddr OR lminaddr = -1 THEN
      lminaddr := addr2;
    END IF;
  END IF;

  IF addr3 IS NOT NULL THEN
    IF addr3 < minaddr OR minaddr = -1 THEN
      minaddr := addr3;
    END IF;
    IF addr3 > maxaddr OR maxaddr = -1 THEN
      maxaddr := addr3;
    END IF;
    rmaxaddr := addr3;
    rminaddr := addr3;
  END IF;

  IF addr4 IS NOT NULL THEN
    IF addr4 < minaddr OR minaddr = -1 THEN
      minaddr := addr4;
    END IF;
    IF addr4 > maxaddr OR maxaddr = -1 THEN
      maxaddr := addr4;
    END IF;
    IF addr4 > rmaxaddr OR rmaxaddr = -1 THEN
      rmaxaddr := addr4;
    END IF;
    IF addr4 < rminaddr OR rminaddr = -1 THEN
      rminaddr := addr4;
    END IF;
  END IF;

  IF minaddr = -1 OR maxaddr = -1 THEN
    RETURN FALSE;
  ELSIF given_address >= minaddr AND given_address <= maxaddr THEN
    IF given_address >= lminaddr AND given_address <= lmaxaddr THEN
      IF (given_address % 2) = (lminaddr % 2)
          OR (given_address % 2) = (lmaxaddr % 2) THEN
        RETURN TRUE;
      END IF;
    END IF;
    IF given_address >= rminaddr AND given_address <= rmaxaddr THEN
      IF (given_address % 2) = (rminaddr % 2)
          OR (given_address % 2) = (rmaxaddr % 2) THEN
        RETURN TRUE;
      END IF;
    END IF;
  END IF;
  RETURN FALSE;
END;
$$;


--
-- Name: interpolate_from_address(integer, character varying, character varying, geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION interpolate_from_address(given_address integer, in_addr1 character varying, in_addr2 character varying, road geometry) RETURNS geometry
    LANGUAGE plpgsql
    AS $$
DECLARE
  addr1 INTEGER;
  addr2 INTEGER;
  result GEOMETRY;
BEGIN
  addr1 := to_number(in_addr1, '999999');
  addr2 := to_number(in_addr2, '999999');
  result = interpolate_from_address(given_address, addr1, addr2, road);
  RETURN result;
END
$$;


--
-- Name: interpolate_from_address(integer, integer, integer, geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION interpolate_from_address(given_address integer, addr1 integer, addr2 integer, in_road geometry) RETURNS geometry
    LANGUAGE plpgsql
    AS $$
DECLARE
  addrwidth INTEGER;
  part DOUBLE PRECISION;
  road GEOMETRY;
  result GEOMETRY;
BEGIN
    IF in_road IS NULL THEN
        RETURN NULL;
    END IF;

    IF geometrytype(in_road) = 'LINESTRING' THEN
      road := in_road;
    ELSIF geometrytype(in_road) = 'MULTILINESTRING' THEN
      road := geometryn(in_road,1);
    ELSE
      RETURN NULL;
    END IF;

    addrwidth := greatest(addr1,addr2) - least(addr1,addr2);
    part := (given_address - least(addr1,addr2)) / trunc(addrwidth, 1);

    IF addr1 > addr2 THEN
        part := 1 - part;
    END IF;

    IF part < 0 OR part > 1 OR part IS NULL THEN
        part := 0.5;
    END IF;

    result = line_interpolate_point(road, part);
    RETURN result;
END;
$$;


--
-- Name: levenshtein_ignore_case(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION levenshtein_ignore_case(character varying, character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  result INTEGER;
BEGIN
  result := levenshtein(upper($1), upper($2));
  RETURN result;
END
$_$;


--
-- Name: loader_generate_script(text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION loader_generate_script(param_states text[], os text) RETURNS SETOF text
    LANGUAGE sql
    AS $_$
SELECT 
	loader_macro_replace(
		replace(
			loader_macro_replace(declare_sect
				, ARRAY['staging_fold', 'state_fold','website_root', 'psql', 'state_abbrev', 'data_schema', 'state_fips'], 
				ARRAY[variables.staging_fold, s.state_fold, variables.website_root, platform.psql, s.state_abbrev, variables.data_schema, s.state_fips::text]
			), '/', platform.path_sep) || '
	' || platform.wget || ' http://' || variables.website_root  || '/'
	|| state_fold || 
			'/ --no-parent --relative --recursive --level=2 --accept=zip,txt --mirror --reject=html
		' || platform.unzip_command ||
	'	
	' ||
	-- State level files
	array_to_string( ARRAY(SELECT loader_macro_replace(COALESCE(lu.pre_load_process || E'\r', '') || platform.loader || ' -' ||  lu.insert_mode || ' -s 4269 -g the_geom ' 
		|| CASE WHEN lu.single_geom_mode THEN ' -S ' ELSE ' ' END::text || ' -W "latin1" tl_' || variables.tiger_year || '_' || s.state_fips 
	|| '_' || lu.table_name || '.dbf ' || variables.data_schema || '.'::text || lower(s.state_abbrev) || '_' || lu.table_name || ' | '::text || platform.psql 
		|| COALESCE(E'\r' || 
			lu.post_load_process , '') , ARRAY['loader','table_name'], ARRAY[platform.loader, lu.table_name ])
				FROM loader_lookuptables AS lu
				WHERE level_state = true
				ORDER BY process_order, lookup_name), E'\r') ::text 
	-- County Level files
	|| E'\r' ||
		array_to_string( ARRAY(SELECT loader_macro_replace(COALESCE(lu.pre_load_process || E'\r', '') || COALESCE(county_process_command || E'\r','')
				|| COALESCE(E'\r' ||lu.post_load_process , '') , ARRAY['loader','table_name'], ARRAY[platform.loader, lu.table_name ]) 
				FROM loader_lookuptables AS lu
				WHERE level_county = true
				ORDER BY process_order, lookup_name), E'\r') ::text 
	, ARRAY['psql', 'data_schema','staging_fold', 'state_fold', 'website_root', 'state_abbrev','state_fips'], 
	ARRAY[platform.psql,  variables.data_schema, variables.staging_fold, s.state_fold,variables.website_root, s.state_abbrev, s.state_fips::text])
			AS shell_code
FROM loader_variables As variables
		CROSS JOIN (SELECT name As state, abbrev As state_abbrev, st_code As state_fips, 
			 st_code || '_' 
	|| upper(replace(name, ' ', '_')) As state_fold
FROM state_lookup) As s CROSS JOIN loader_platform As platform
WHERE $1 @> ARRAY[state_abbrev::text]      -- If state is contained in list of states input generate script for it
AND platform.os = $2  -- generate script for selected platform
;
$_$;


--
-- Name: loader_macro_replace(text, text[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION loader_macro_replace(param_input text, param_keys text[], param_values text[]) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
	DECLARE var_result text = param_input;
	DECLARE var_count integer = array_upper(param_keys,1);
	BEGIN
		FOR i IN 1..var_count LOOP
			var_result := replace(var_result, '${' || param_keys[i] || '}', param_values[i]);
		END LOOP;
		return var_result;
	END;
$_$;


--
-- Name: location_extract(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION location_extract(fullstreet character varying, stateabbrev character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  ws VARCHAR;
  location VARCHAR;
  lstate VARCHAR;
  stmt VARCHAR;
  street_array text[];
  word_count INTEGER;
  rec RECORD;
  best INTEGER := 0;
  tempString VARCHAR;
BEGIN
  IF fullStreet IS NULL THEN
    RETURN NULL;
  END IF;

  ws := E'[ ,.\n\f\t]';

  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE state.stusps = stateAbbrev;
  END IF;

  street_array := regexp_split_to_array(fullStreet,ws);
  word_count := array_upper(street_array,1);

  tempString := '';
  FOR i IN 1..word_count LOOP
    CONTINUE WHEN street_array[word_count-i+1] IS NULL OR street_array[word_count-i+1] = '';

    tempString := street_array[word_count-i+1] || tempString;

    stmt := ' SELECT'
         || '   1,'
         || '   name,'
         || '   levenshtein_ignore_case(' || quote_literal(tempString) || ',name) as rating,'
         || '   length(name) as len'
         || ' FROM place'
         || ' WHERE ' || CASE WHEN stateAbbrev IS NOT NULL THEN 'statefp = ' || quote_literal(lstate) || ' AND ' ELSE '' END
         || '   soundex(' || quote_literal(tempString) || ') = soundex(name)'
         || '   AND levenshtein_ignore_case(' || quote_literal(tempString) || ',name) <= 2 '
         || ' UNION ALL SELECT'
         || '   2,'
         || '   name,'
         || '   levenshtein_ignore_case(' || quote_literal(tempString) || ',name) as rating,'
         || '   length(name) as len'
         || ' FROM cousub'
         || ' WHERE ' || CASE WHEN stateAbbrev IS NOT NULL THEN 'statefp = ' || quote_literal(lstate) || ' AND ' ELSE '' END
         || '   soundex(' || quote_literal(tempString) || ') = soundex(name)'
         || '   AND levenshtein_ignore_case(' || quote_literal(tempString) || ',name) <= 2 '
         || ' ORDER BY '
         || '   3 ASC, 1 ASC, 4 DESC'
         || ' LIMIT 1;'
         ;

    EXECUTE stmt INTO rec;

    IF rec.rating >= best THEN
      location := tempString;
      best := rec.rating;
    END IF;

    tempString := ' ' || tempString;
  END LOOP;

  location := replace(location,' ',ws || '+');
  location := substring(fullStreet,'(?i)' || location || '$');

  RETURN location;
END;
$_$;


--
-- Name: location_extract_countysub_exact(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION location_extract_countysub_exact(fullstreet character varying, stateabbrev character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  ws VARCHAR;
  location VARCHAR;
  tempInt INTEGER;
  lstate VARCHAR;
  rec RECORD;
BEGIN
  ws := E'[ ,.\n\f\t]';

  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE stusps = stateAbbrev;
    SELECT INTO tempInt count(*) FROM cousub
        WHERE cousub.statefp = lstate
        AND texticregexeq(fullStreet, '(?i)' || name || '$');
  ELSE
    SELECT INTO tempInt count(*) FROM cousub
        WHERE texticregexeq(fullStreet, '(?i)' || name || '$');
  END IF;

  IF tempInt > 0 THEN
    IF stateAbbrev IS NOT NULL THEN
      FOR rec IN SELECT substring(fullStreet, '(?i)('
          || name || ')$') AS value, name FROM cousub
          WHERE cousub.statefp = lstate
          AND texticregexeq(fullStreet, '(?i)' || ws || name ||
          '$') ORDER BY length(name) DESC LOOP
        location := rec.value;
        EXIT;
      END LOOP;
    ELSE
      FOR rec IN SELECT substring(fullStreet, '(?i)('
          || name || ')$') AS value, name FROM cousub
          WHERE texticregexeq(fullStreet, '(?i)' || ws || name ||
          '$') ORDER BY length(name) DESC LOOP
        location := rec.value;
        EXIT;
      END LOOP;
    END IF;
  END IF;

  RETURN location;
END;
$_$;


--
-- Name: location_extract_countysub_fuzzy(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION location_extract_countysub_fuzzy(fullstreet character varying, stateabbrev character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  ws VARCHAR;
  tempString VARCHAR;
  location VARCHAR;
  tempInt INTEGER;
  word_count INTEGER;
  rec RECORD;
  test BOOLEAN;
  lstate VARCHAR;
BEGIN
  ws := E'[ ,.\n\f\t]';

  tempString := substring(fullStreet, '(?i)' || ws ||
      '([a-zA-Z0-9]+)$');
  IF tempString IS NULL THEN
    tempString := fullStreet;
  END IF;

  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE stusps = stateAbbrev;
    SELECT INTO tempInt count(*) FROM cousub
        WHERE cousub.statefp = lstate
        AND soundex(tempString) = end_soundex(name);
  ELSE
    SELECT INTO tempInt count(*) FROM cousub
        WHERE soundex(tempString) = end_soundex(name);
  END IF;

  IF tempInt > 0 THEN
    tempInt := 50;
    IF stateAbbrev IS NOT NULL THEN
      FOR rec IN SELECT name FROM cousub
          WHERE cousub.statefp = lstate
          AND soundex(tempString) = end_soundex(name) LOOP
        word_count := count_words(rec.name);
        test := TRUE;
        tempString := get_last_words(fullStreet, word_count);
        FOR i IN 1..word_count LOOP
          IF soundex(split_part(tempString, ' ', i)) !=
            soundex(split_part(rec.name, ' ', i)) THEN
            test := FALSE;
          END IF;
        END LOOP;
        IF test THEN
          IF levenshtein_ignore_case(rec.name, tempString) < tempInt THEN
                location := tempString;
            tempInt := levenshtein_ignore_case(rec.name, tempString);
          END IF;
        END IF;
      END LOOP;
    ELSE
      FOR rec IN SELECT name FROM cousub
          WHERE soundex(tempString) = end_soundex(name) LOOP
        word_count := count_words(rec.name);
        test := TRUE;
        tempString := get_last_words(fullStreet, word_count);
        FOR i IN 1..word_count LOOP
          IF soundex(split_part(tempString, ' ', i)) !=
            soundex(split_part(rec.name, ' ', i)) THEN
            test := FALSE;
          END IF;
        END LOOP;
        IF test THEN
          IF levenshtein_ignore_case(rec.name, tempString) < tempInt THEN
                location := tempString;
            tempInt := levenshtein_ignore_case(rec.name, tempString);
          END IF;
        END IF;
      END LOOP;
    END IF;
  END IF; -- If no fuzzys were found, leave location null.

  RETURN location;
END;
$_$;


--
-- Name: location_extract_place_exact(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION location_extract_place_exact(fullstreet character varying, stateabbrev character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  ws VARCHAR;
  location VARCHAR;
  tempInt INTEGER;
  lstate VARCHAR;
  rec RECORD;
BEGIN
  ws := E'[ ,.\n\f\t]';

  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE stusps = stateAbbrev;
    SELECT INTO tempInt count(*) FROM place
        WHERE place.statefp = lstate
        AND texticregexeq(fullStreet, '(?i)' || name || '$');
  ELSE
    SELECT INTO tempInt count(*) FROM place
        WHERE texticregexeq(fullStreet, '(?i)' || name || '$');
  END IF;

  IF tempInt > 0 THEN
    IF stateAbbrev IS NOT NULL THEN
      FOR rec IN SELECT substring(fullStreet, '(?i)('
          || name || ')$') AS value, name FROM place
          WHERE place.statefp = lstate
          AND texticregexeq(fullStreet, '(?i)'
          || name || '$') ORDER BY length(name) DESC LOOP
        location := rec.value;
        EXIT;
      END LOOP;
    ELSE
      FOR rec IN SELECT substring(fullStreet, '(?i)('
          || name || ')$') AS value, name FROM place
          WHERE texticregexeq(fullStreet, '(?i)'
          || name || '$') ORDER BY length(name) DESC LOOP
        location := rec.value;
        EXIT;
      END LOOP;
    END IF;
  END IF;

  RETURN location;
END;
$_$;


--
-- Name: location_extract_place_fuzzy(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION location_extract_place_fuzzy(fullstreet character varying, stateabbrev character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  ws VARCHAR;
  tempString VARCHAR;
  location VARCHAR;
  tempInt INTEGER;
  word_count INTEGER;
  rec RECORD;
  test BOOLEAN;
  lstate VARCHAR;
BEGIN
  ws := E'[ ,.\n\f\t]';

  tempString := substring(fullStreet, '(?i)' || ws
      || '([a-zA-Z0-9]+)$');
  IF tempString IS NULL THEN
      tempString := fullStreet;
  END IF;

  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE stusps = stateAbbrev;
    SELECT into tempInt count(*) FROM place
        WHERE place.statefp = lstate
        AND soundex(tempString) = end_soundex(name);
  ELSE
    SELECT into tempInt count(*) FROM place
        WHERE soundex(tempString) = end_soundex(name);
  END IF;

  IF tempInt > 0 THEN
    tempInt := 50;
    IF stateAbbrev IS NOT NULL THEN
      FOR rec IN SELECT name FROM place
          WHERE place.statefp = lstate
          AND soundex(tempString) = end_soundex(name) LOOP
        word_count := count_words(rec.name);
        test := TRUE;
        tempString := get_last_words(fullStreet, word_count);
        FOR i IN 1..word_count LOOP
          IF soundex(split_part(tempString, ' ', i)) !=
            soundex(split_part(rec.name, ' ', i)) THEN
            test := FALSE;
          END IF;
        END LOOP;
          IF test THEN
            IF levenshtein_ignore_case(rec.name, tempString) < tempInt THEN
              location := tempString;
              tempInt := levenshtein_ignore_case(rec.name, tempString);
            END IF;
          END IF;
      END LOOP;
    ELSE
      FOR rec IN SELECT name FROM place
          WHERE soundex(tempString) = end_soundex(name) LOOP
        word_count := count_words(rec.name);
        test := TRUE;
        tempString := get_last_words(fullStreet, word_count);
        FOR i IN 1..word_count LOOP
          IF soundex(split_part(tempString, ' ', i)) !=
            soundex(split_part(rec.name, ' ', i)) THEN
            test := FALSE;
          END IF;
        END LOOP;
          IF test THEN
            IF levenshtein_ignore_case(rec.name, tempString) < tempInt THEN
              location := tempString;
            tempInt := levenshtein_ignore_case(rec.name, tempString);
          END IF;
        END IF;
      END LOOP;
    END IF;
  END IF;

  RETURN location;
END;
$_$;


--
-- Name: nullable_levenshtein(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION nullable_levenshtein(character varying, character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  given_string VARCHAR;
  result INTEGER := 3;
  var_verbose BOOLEAN := FALSE; /**change from verbose to param_verbose since its a keyword and get compile error in 9.0 **/
BEGIN
  IF $1 IS NULL THEN
    IF var_verbose THEN
      RAISE NOTICE 'nullable_levenshtein - given string is NULL!';
    END IF;
    RETURN NULL;
  ELSE
    given_string := $1;
  END IF;

  IF $2 IS NOT NULL AND $2 != '' THEN
    result := levenshtein_ignore_case(given_string, $2);
  END IF;

  RETURN result;
END
$_$;


--
-- Name: rate_attributes(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION rate_attributes(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  result INTEGER := 0;
  directionWeight INTEGER := 2;
  nameWeight INTEGER := 10;
  typeWeight INTEGER := 5;
  var_verbose BOOLEAN := FALSE;
BEGIN
  result := result + levenshtein_ignore_case(cull_null($1), cull_null($2)) *
      directionWeight;
  IF $3 IS NOT NULL AND $4 IS NOT NULL THEN
    result := result + levenshtein_ignore_case($3, $4) * nameWeight;
  ELSE
    IF var_verbose THEN
      RAISE NOTICE 'rate_attributes() - Street names cannot be null!';
    END IF;
    RETURN NULL;
  END IF;
  result := result + levenshtein_ignore_case(cull_null($5), cull_null($6)) *
      typeWeight;
  result := result + levenshtein_ignore_case(cull_null($7), cull_null($7)) *
      directionWeight;
  return result;
END;
$_$;


--
-- Name: rate_attributes(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION rate_attributes(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  result INTEGER := 0;
  locationWeight INTEGER := 14;
  var_verbose BOOLEAN := FALSE;
BEGIN
  IF $9 IS NOT NULL AND $10 IS NOT NULL THEN
    result := levenshtein_ignore_case($9, $10);
  ELSE
    IF var_verbose THEN
      RAISE NOTICE 'rate_attributes() - Location names cannot be null!';
    END IF;
    RETURN NULL;
  END IF;
  result := result + rate_attributes($1, $2, $3, $4, $5, $6, $7, $8);
  RETURN result;
END;
$_$;


--
-- Name: st_area(geography); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION st_area(geography) RETURNS double precision
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT ST_Area($1, true)$_$;


--
-- Name: st_length(geography); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION st_length(geography) RETURNS double precision
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT ST_Length($1, true)$_$;


--
-- Name: state_extract(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION state_extract(rawinput character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$
DECLARE
  tempInt INTEGER;
  tempString VARCHAR;
  state VARCHAR;
  stateAbbrev VARCHAR;
  result VARCHAR;
  rec RECORD;
  test BOOLEAN;
  ws VARCHAR;
BEGIN
  ws := E'[ ,.\t\n\f\r]';

  tempString := substring(rawInput from ws || E'+([^ ,.\t\n\f\r0-9]*?)$');
  SELECT INTO tempInt count(*) FROM (select distinct abbrev from state_lookup
      WHERE upper(abbrev) = upper(tempString)) as blah;
  IF tempInt = 1 THEN
    state := tempString;
    SELECT INTO stateAbbrev abbrev FROM (select distinct abbrev from
        state_lookup WHERE upper(abbrev) = upper(tempString)) as blah;
  ELSE
    SELECT INTO tempInt count(*) FROM state_lookup WHERE upper(name)
        like upper('%' || tempString);
    IF tempInt >= 1 THEN
      FOR rec IN SELECT name from state_lookup WHERE upper(name)
          like upper('%' || tempString) LOOP
        SELECT INTO test texticregexeq(rawInput, name) FROM state_lookup
            WHERE rec.name = name;
        IF test THEN
          SELECT INTO stateAbbrev abbrev FROM state_lookup
              WHERE rec.name = name;
          state := substring(rawInput, '(?i)' || rec.name);
          EXIT;
        END IF;
      END LOOP;
    ELSE
      SELECT INTO tempInt count(*) FROM state_lookup
          WHERE soundex(tempString) = end_soundex(name);
      IF tempInt >= 1 THEN
        FOR rec IN SELECT name, abbrev FROM state_lookup
            WHERE soundex(tempString) = end_soundex(name) LOOP
          tempInt := count_words(rec.name);
          tempString := get_last_words(rawInput, tempInt);
          test := TRUE;
          FOR i IN 1..tempInt LOOP
            IF soundex(split_part(tempString, ' ', i)) !=
               soundex(split_part(rec.name, ' ', i)) THEN
              test := FALSE;
            END IF;
          END LOOP;
          IF test THEN
            state := tempString;
            stateAbbrev := rec.abbrev;
            EXIT;
          END IF;
        END LOOP;
      END IF;
    END IF;
  END IF;

  IF state IS NOT NULL AND stateAbbrev IS NOT NULL THEN
    result := state || ':' || stateAbbrev;
  END IF;

  RETURN result;
END;
$_$;


--
-- Name: utmzone(geometry); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION utmzone(geometry) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
DECLARE
    geomgeog geometry;
    zone int;
    pref int;
BEGIN
    geomgeog:=transform($1,4326);
    IF (y(geomgeog))>0 THEN
        pref:=32600;
    ELSE
        pref:=32700;
    END IF;
    zone:=floor((x(geomgeog)+180)/6)+1;
    RETURN zone+pref;
END;
$_$;


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


-- SET search_path = tif, pg_catalog;

--
-- Name: property_values; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE property_values (
    pin character varying(200),
    address character varying(100),
    city character varying(50),
    zip character varying(10),
    township character varying(50),
    assessment_tax_year character varying(200),
    est_value character varying(200),
    assessed_value character varying(200),
    lotsize character varying(200),
    bldg_size character varying(200),
    property_class character varying(200),
    bldg_age character varying(10),
    tax_rate_year character varying(200),
    tax_code_year character varying(200),
    taxcode character varying(10),
    mailing_tax_year character varying(200),
    mailing_name character varying(100),
    mailing_address character varying(250),
    mailing_city_state_zip character varying(250),
    tax_bill_2012 character varying(200),
    tax_bill_2011 character varying(200),
    tax_bill_2010 character varying(200),
    tax_bill_2009 character varying(200),
    tax_bill_2008 character varying(200),
    tax_bill_2007 character varying(200),
    tax_bill_2006 character varying(200),
    tax_rate character varying(10),
    sent_pin character varying(20),
    bldg_gid integer,
    est_value_calc money,
    str_num character varying(10),
    str_dir character varying(10),
    str_name character varying(75),
    str_typ character varying(50),
    full_address character varying(200),
    the_geom public.geometry(Point,3435)
);


SET search_path = assessed, pg_catalog;

--
-- Name: countdown; Type: VIEW; Schema: assessed; Owner: -
--

CREATE VIEW countdown AS
    SELECT ((((((((SELECT count(property_values.pin) AS count FROM tif.property_values) - (SELECT count(*) AS count FROM apts)) - (SELECT count(*) AS count FROM condos)) - (SELECT count(*) AS count FROM exempt)) - (SELECT count(*) AS count FROM res202)) - (SELECT count(*) AS count FROM vacant)) - (SELECT count(*) AS count FROM vacant_adjacent)) - (SELECT count(*) AS count FROM vacant_improved));


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


SET search_path = boundaries, pg_catalog;

--
-- Name: census_blocks; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE census_blocks (
    gid integer NOT NULL,
    statefp10 character varying(2),
    countyfp10 character varying(3),
    tractce10 character varying(6),
    blockce10 character varying(4),
    geoid10 character varying(15),
    name10 character varying(10),
    tract_bloc character varying(10),
    the_geom public.geometry,
    isometric public.geometry(MultiPolygon,3435),
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: blocks2010_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE blocks2010_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blocks2010_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE blocks2010_gid_seq OWNED BY census_blocks.gid;


--
-- Name: census_block_groups; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE census_block_groups (
    gid integer NOT NULL,
    statefp10 character varying(2),
    countyfp10 character varying(3),
    tractce10 character varying(6),
    blkgrpce10 character varying(1),
    geoid10 character varying(12),
    namelsad10 character varying(13),
    mtfcc10 character varying(5),
    funcstat10 character varying(1),
    aland10 double precision,
    awater10 double precision,
    intptlat10 character varying(11),
    intptlon10 character varying(12),
    the_geom public.geometry(MultiPolygon,4326)
);


--
-- Name: census_tracts; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts (
    gid integer NOT NULL,
    statefp10 character varying(2),
    countyfp10 character varying(3),
    tractce10 character varying(6),
    geoid10 character varying(11),
    name10 character varying(7),
    namelsad10 character varying(20),
    commarea character varying(2),
    commarea_n integer,
    notes character varying(80),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: central_business_district; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE central_business_district (
    gid integer NOT NULL,
    name character varying(30),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: central_business_district_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE central_business_district_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: central_business_district_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE central_business_district_gid_seq OWNED BY central_business_district.gid;


--
-- Name: city_boundary; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE city_boundary (
    gid integer NOT NULL,
    name character varying(25),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: city_boundary_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE city_boundary_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: city_boundary_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE city_boundary_gid_seq OWNED BY city_boundary.gid;


--
-- Name: comm_areas; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE comm_areas (
    gid1 integer NOT NULL,
    area_num character varying(2),
    community character varying(80),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: comm_areas_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE comm_areas_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comm_areas_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE comm_areas_gid_seq OWNED BY comm_areas.gid1;


--
-- Name: congress; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE congress (
    gid integer NOT NULL,
    objectid numeric(10,0),
    data_admin numeric,
    perimeter numeric,
    name character varying(30),
    district character varying(5),
    edit_date character varying(10),
    shape_area numeric,
    shape_len numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: conservation_areas; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE conservation_areas (
    gid integer NOT NULL,
    objectid numeric(10,0),
    type character varying(25),
    name character varying(25),
    source character varying(5),
    ref character varying(5),
    status character varying(15),
    date date,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: conservation_areas_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE conservation_areas_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conservation_areas_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE conservation_areas_gid_seq OWNED BY conservation_areas.gid;


--
-- Name: new_wards; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE new_wards (
    gid integer NOT NULL,
    objectid integer,
    ward smallint,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: councilpassedwards_11192012_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE councilpassedwards_11192012_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: councilpassedwards_11192012_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE councilpassedwards_11192012_gid_seq OWNED BY new_wards.gid;


--
-- Name: empowerment_zones; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE empowerment_zones (
    gid integer NOT NULL,
    objectid numeric(10,0),
    name character varying(254),
    section character varying(20),
    type character varying(35),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: empowerment_zones_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE empowerment_zones_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: empowerment_zones_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE empowerment_zones_gid_seq OWNED BY empowerment_zones.gid;


--
-- Name: enterprise_communities; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE enterprise_communities (
    gid integer NOT NULL,
    type character varying(35),
    name character varying(20),
    section character varying(20),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: enterprise_communities_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE enterprise_communities_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enterprise_communities_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE enterprise_communities_gid_seq OWNED BY enterprise_communities.gid;


--
-- Name: enterprise_zones; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE enterprise_zones (
    gid integer NOT NULL,
    objectid numeric(10,0),
    enterprise integer,
    name character varying(2),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: enterprise_zones_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE enterprise_zones_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enterprise_zones_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE enterprise_zones_gid_seq OWNED BY enterprise_zones.gid;


--
-- Name: il_congress_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE il_congress_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: il_congress_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE il_congress_gid_seq OWNED BY congress.gid;


--
-- Name: il_house_districts; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE il_house_districts (
    gid integer NOT NULL,
    objectid integer,
    district_n character varying(50),
    district_1 smallint,
    area numeric,
    perimeter numeric,
    compactnes numeric,
    population integer,
    voting_age integer,
    analysis1 numeric,
    analysis2 numeric,
    analysis3 numeric,
    rgb integer,
    countyspli smallint,
    precinctsp integer,
    remainingb integer,
    totalblock integer,
    locked character varying(50),
    lockedby character varying(50),
    labelvalue numeric,
    originlaye character varying(20),
    originstfi character varying(50),
    originla_1 smallint,
    timedate character varying(25),
    sid character varying(20),
    shape_leng numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon)
);


--
-- Name: il_house_districts_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE il_house_districts_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: il_house_districts_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE il_house_districts_gid_seq OWNED BY il_house_districts.gid;


--
-- Name: ilhouse2000; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE ilhouse2000 (
    gid integer NOT NULL,
    district character varying(3),
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: ilhouse2000_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE ilhouse2000_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ilhouse2000_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE ilhouse2000_gid_seq OWNED BY ilhouse2000.gid;


--
-- Name: ilsenate2000; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE ilsenate2000 (
    gid integer NOT NULL,
    district character varying(3),
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: ilsenate2000_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE ilsenate2000_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ilsenate2000_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE ilsenate2000_gid_seq OWNED BY ilsenate2000.gid;


--
-- Name: industrial_corridors; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE industrial_corridors (
    gid integer NOT NULL,
    objectid numeric(10,0),
    no numeric(10,0),
    name character varying(20),
    region character varying(6),
    hud_qualif character varying(8),
    region_num numeric(10,0),
    miles double precision,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: industrial_corridors_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE industrial_corridors_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: industrial_corridors_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE industrial_corridors_gid_seq OWNED BY industrial_corridors.gid;


--
-- Name: municipalities; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE municipalities (
    gid integer NOT NULL,
    objectid numeric(10,0),
    name character varying(50),
    type character varying(30),
    st character varying(2),
    stfips character varying(2),
    fips_place character varying(5),
    display smallint,
    shape_area numeric,
    shape_len numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: municipalities_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE municipalities_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: municipalities_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE municipalities_gid_seq OWNED BY municipalities.gid;


--
-- Name: neighborhoods; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE neighborhoods (
    gid integer NOT NULL,
    objectid numeric(10,0),
    pri_neigh_num character varying(3),
    pri_neigh character varying(50),
    sec_neigh_num character varying(3),
    sec_neigh character varying(50),
    the_geom public.geometry,
    isometric public.geometry(MultiPolygon,3435),
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: neighboorhoods_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE neighboorhoods_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: neighboorhoods_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE neighboorhoods_gid_seq OWNED BY neighborhoods.gid;


SET search_path = public, pg_catalog;

--
-- Name: county; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE county (
    pin character varying(200),
    address character varying(100),
    city character varying(50),
    zip character varying(10),
    township character varying(50),
    assessment_tax_year character varying(200),
    est_value character varying(200),
    assessed_value character varying(200),
    lotsize character varying(200),
    bldg_size character varying(200),
    property_class character varying(200),
    bldg_age character varying(10),
    tax_rate_year character varying(200),
    tax_code_year character varying(200),
    taxcode character varying(10),
    mailing_tax_year character varying(200),
    mailing_name character varying(100),
    mailing_address character varying(250),
    mailing_city_state_zip character varying(250),
    tax_bill_2012 character varying(200),
    tax_bill_2011 character varying(200),
    tax_bill_2010 character varying(200),
    tax_bill_2009 character varying(200),
    tax_bill_2008 character varying(200),
    tax_bill_2007 character varying(200),
    tax_bill_2006 character varying(200),
    tax_rate character varying(10),
    sent_pin character varying(20)
);


SET search_path = boundaries, pg_catalog;

--
-- Name: pin_countdown; Type: VIEW; Schema: boundaries; Owner: -
--

CREATE VIEW pin_countdown AS
    SELECT (668436 - (SELECT count(*) AS count FROM public.county));


--
-- Name: pins_propclass; Type: VIEW; Schema: boundaries; Owner: -
--

CREATE VIEW pins_propclass AS
    SELECT county_temp_distinct.sent_pin, county_temp_distinct.property_class FROM tif.property_values county_temp_distinct;


--
-- Name: pins_propclass_tbl; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE pins_propclass_tbl (
    sent_pin character varying(20),
    property_class character varying(200)
);


--
-- Name: planning_districts; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE planning_districts (
    gid integer NOT NULL,
    plandst1_i integer,
    name character varying(15),
    num numeric(10,0),
    district character varying(2),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: planning_districts_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE planning_districts_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planning_districts_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE planning_districts_gid_seq OWNED BY planning_districts.gid;


--
-- Name: planning_regions; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE planning_regions (
    gid integer NOT NULL,
    plandst1_i integer,
    name character varying(15),
    num numeric(10,0),
    district character varying(2),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: planning_regions_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE planning_regions_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: planning_regions_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE planning_regions_gid_seq OWNED BY planning_regions.gid;


--
-- Name: police_districts; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE police_districts (
    gid integer NOT NULL,
    dist_label character varying(16),
    dist_num character varying(2),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: police_districts_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE police_districts_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: police_districts_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE police_districts_gid_seq OWNED BY police_districts.gid;


--
-- Name: precincts; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE precincts (
    gid integer NOT NULL,
    ward smallint,
    precinct smallint,
    ward_preci character varying(6),
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: snow_parking; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE snow_parking (
    gid integer NOT NULL,
    objectid numeric(10,0),
    on_street character varying(60),
    from_stree character varying(60),
    to_street character varying(60),
    restrict_t character varying(15),
    shape_len numeric,
    the_geom public.geometry(MultiLineString,3435)
);


--
-- Name: snowparkingrestrict2inch_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE snowparkingrestrict2inch_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: snowparkingrestrict2inch_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE snowparkingrestrict2inch_gid_seq OWNED BY snow_parking.gid;


--
-- Name: special_service_areas; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE special_service_areas (
    gid integer NOT NULL,
    ref_no character varying(254),
    name character varying(25),
    status character varying(8),
    ward character varying(25),
    comm_area character varying(25),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: special_service_areas_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE special_service_areas_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: special_service_areas_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE special_service_areas_gid_seq OWNED BY special_service_areas.gid;


--
-- Name: sweeping; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE sweeping (
    gid integer NOT NULL,
    ward character varying(2),
    ward_num integer,
    sweep integer,
    wardsweep character varying(5),
    ward_secti character varying(254),
    month_4 character varying(254),
    month_5 character varying(254),
    month_6 character varying(254),
    month_7 character varying(254),
    month_8 character varying(254),
    month_9 character varying(254),
    month_10 character varying(254),
    month_11 character varying(254),
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: streetsweeping2012_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE streetsweeping2012_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: streetsweeping2012_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE streetsweeping2012_gid_seq OWNED BY sweeping.gid;


--
-- Name: tracts2010_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE tracts2010_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracts2010_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE tracts2010_gid_seq OWNED BY census_tracts.gid;


--
-- Name: wardprecincts_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE wardprecincts_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wardprecincts_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE wardprecincts_gid_seq OWNED BY precincts.gid;


--
-- Name: wards; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE wards (
    gid integer NOT NULL,
    data_admin integer,
    ward character varying(4),
    alderman character varying(60),
    class character varying(2),
    ward_phone character varying(12),
    hall_phone character varying(12),
    hall_offic character varying(45),
    address character varying(39),
    edit_date1 character varying(10),
    the_geom public.geometry,
    bldg_gid integer,
    str_num character varying,
    str_dir character(1),
    str_nam character varying(50),
    str_typ character varying(10),
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: wards_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE wards_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wards_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE wards_gid_seq OWNED BY wards.gid;


--
-- Name: winterovernightparkingrestrictions; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE winterovernightparkingrestrictions (
    gid integer NOT NULL,
    objectid numeric(10,0),
    on_street character varying(60),
    from_stree character varying(60),
    to_street character varying(60),
    restrict_t character varying(15),
    shape_len numeric,
    the_geom public.geometry(MultiLineString,3435)
);


--
-- Name: winterovernightparkingrestrictions_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE winterovernightparkingrestrictions_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: winterovernightparkingrestrictions_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE winterovernightparkingrestrictions_gid_seq OWNED BY winterovernightparkingrestrictions.gid;


--
-- Name: zip_codes; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE zip_codes (
    gid integer NOT NULL,
    objectid numeric(10,0),
    zip character varying(5),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: zip_codes_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE zip_codes_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zip_codes_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE zip_codes_gid_seq OWNED BY zip_codes.gid;


--
-- Name: zoning_aug2012; Type: TABLE; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE TABLE zoning_aug2012 (
    gid integer NOT NULL,
    zone_type smallint,
    zone_class character varying(10),
    edit_statu character varying(8),
    edit_date date,
    pd_prefix character varying(10),
    pd_num smallint,
    ordinance_ character varying(11),
    ordinance1 date,
    the_geom public.geometry(MultiPolygon,3435),
    geom_rotated public.geometry(MultiPolygon,3435),
    zone_class_simple character varying(15)
);


--
-- Name: zoning_aug2012_gid_seq; Type: SEQUENCE; Schema: boundaries; Owner: -
--

CREATE SEQUENCE zoning_aug2012_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zoning_aug2012_gid_seq; Type: SEQUENCE OWNED BY; Schema: boundaries; Owner: -
--

ALTER SEQUENCE zoning_aug2012_gid_seq OWNED BY zoning_aug2012.gid;


SET search_path = buildings, pg_catalog;

--
-- Name: address; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE address (
    bldg_gid integer,
    f_add1 integer,
    t_add1 integer,
    pre_dir1 character varying(1),
    st_name1 character varying(35),
    st_type1 character varying(5)
);


--
-- Name: alternate_addresses; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE alternate_addresses (
    bldg_gid integer,
    address character varying(200) NOT NULL,
    id integer NOT NULL
);


--
-- Name: alternate_addresses_id_seq; Type: SEQUENCE; Schema: buildings; Owner: -
--

CREATE SEQUENCE alternate_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alternate_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: buildings; Owner: -
--

ALTER SEQUENCE alternate_addresses_id_seq OWNED BY alternate_addresses.id;


--
-- Name: building_permits_pruned; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE building_permits_pruned (
    id integer,
    bldg_gid integer,
    str_num integer,
    str_dir character(1),
    str_name character varying(75),
    str_typ character varying(10),
    permit_num character varying(50),
    permit_type character varying(200),
    issue_date date,
    est_cost character varying(25),
    work text
);


--
-- Name: building_violations_pruned; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE building_violations_pruned (
    bldg_gid integer,
    v_last_mod_date character varying,
    v_date character varying,
    v_status character varying(100),
    v_status_date character varying(100),
    v_desc text,
    v_loc text,
    v_insp_comments text,
    insp_status character varying(100),
    insp_cat character varying(100),
    dept character varying(100)
);


--
-- Name: buildings; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE buildings (
    bldg_gid integer NOT NULL,
    the_geom public.geometry,
    centroid public.geometry(Point,3435),
    isometric public.geometry(MultiPolygon,3435),
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: buildings_bldg_name; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE buildings_bldg_name (
    bldg_gid integer,
    name character varying(100),
    name2 character varying(100),
    id integer NOT NULL
);


--
-- Name: buildings_bldg_name_id_seq; Type: SEQUENCE; Schema: buildings; Owner: -
--

CREATE SEQUENCE buildings_bldg_name_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: buildings_bldg_name_id_seq; Type: SEQUENCE OWNED BY; Schema: buildings; Owner: -
--

ALTER SEQUENCE buildings_bldg_name_id_seq OWNED BY buildings_bldg_name.id;


--
-- Name: buildings_gid_seq; Type: SEQUENCE; Schema: buildings; Owner: -
--

CREATE SEQUENCE buildings_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: buildings_gid_seq; Type: SEQUENCE OWNED BY; Schema: buildings; Owner: -
--

ALTER SEQUENCE buildings_gid_seq OWNED BY buildings.bldg_gid;


--
-- Name: buildings_nonstandard; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE buildings_nonstandard (
    bldg_gid integer,
    type character varying(100)
);


--
-- Name: cbd_bldg_names; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE cbd_bldg_names (
    bldg_gid integer,
    name character varying(100),
    name2 character varying(100),
    id integer
);


--
-- Name: city_owned; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE city_owned (
    pin character varying(25),
    str_num integer,
    str_dir character(1),
    str_name character varying(100),
    str_typ character varying(20),
    ward character varying(5),
    comm_area character varying(50),
    tif_name character varying(100),
    zoning character varying(10),
    sqft integer,
    bldg_gid integer
);


--
-- Name: curbs; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE curbs (
    gid integer NOT NULL,
    fnode double precision,
    tnode double precision,
    curbs double precision,
    curbs_id double precision,
    type integer,
    display integer,
    scale smallint,
    standard smallint,
    method smallint,
    source smallint,
    the_geom public.geometry,
    isometric public.geometry(MultiLineString,3435),
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: curbs_gid_seq; Type: SEQUENCE; Schema: buildings; Owner: -
--

CREATE SEQUENCE curbs_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: curbs_gid_seq; Type: SEQUENCE OWNED BY; Schema: buildings; Owner: -
--

ALTER SEQUENCE curbs_gid_seq OWNED BY curbs.gid;


--
-- Name: full_address; Type: VIEW; Schema: buildings; Owner: -
--

CREATE VIEW full_address AS
    SELECT address.bldg_gid, CASE WHEN (address.st_type1 IS NULL) THEN ((((address.f_add1 || ' '::text) || (address.pre_dir1)::text) || ' '::text) || (address.st_name1)::text) ELSE ((((((address.f_add1 || ' '::text) || (address.pre_dir1)::text) || ' '::text) || (address.st_name1)::text) || ' '::text) || (address.st_type1)::text) END AS address FROM address;


--
-- Name: landuse; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE landuse (
    gid integer NOT NULL,
    landuse character varying(4),
    landuse2 character varying(4),
    facname character varying(75),
    watname character varying(40),
    osowncode character varying(4),
    shape_leng numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435),
    longdesc text,
    shortdesc character varying(255),
    tilemill_display character varying(100)
);


--
-- Name: landuse2005_cmap_v1_gid_seq; Type: SEQUENCE; Schema: buildings; Owner: -
--

CREATE SEQUENCE landuse2005_cmap_v1_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landuse2005_cmap_v1_gid_seq; Type: SEQUENCE OWNED BY; Schema: buildings; Owner: -
--

ALTER SEQUENCE landuse2005_cmap_v1_gid_seq OWNED BY landuse.gid;


--
-- Name: ohare_bldg_names; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE ohare_bldg_names (
    bldg_gid integer,
    name character varying(100),
    name2 character varying(100),
    id integer
);


--
-- Name: roofs; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE roofs (
    bldg_gid integer,
    roof public.geometry(MultiPolygon,3435)
);


--
-- Name: roofs_sorted; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE roofs_sorted (
    bldg_gid integer,
    roof public.geometry(MultiPolygon,3435)
);


--
-- Name: sqft; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE sqft (
    bldg_gid integer,
    sqft real
);


--
-- Name: stories; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE stories (
    bldg_gid integer,
    stories integer
);


--
-- Name: university_bldg_names; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE university_bldg_names (
    bldg_gid integer,
    name character varying(100),
    name2 character varying(100),
    uni_name character varying(50)
);


--
-- Name: walls; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE walls (
    bldg_gid integer,
    stories integer,
    wall public.geometry(Polygon,3435)
);


--
-- Name: walls_sorted; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE walls_sorted (
    bldg_gid integer,
    wall public.geometry(Polygon,3435)
);


--
-- Name: year_built; Type: TABLE; Schema: buildings; Owner: -; Tablespace: 
--

CREATE TABLE year_built (
    bldg_gid integer,
    year_built smallint
);


SET search_path = business, pg_catalog;

--
-- Name: bid_seq; Type: SEQUENCE; Schema: business; Owner: -
--

CREATE SEQUENCE bid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boid; Type: SEQUENCE; Schema: business; Owner: -
--

CREATE SEQUENCE boid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: twitter; Type: TABLE; Schema: business; Owner: -; Tablespace: 
--

CREATE TABLE twitter (
    bldg_gid integer,
    twitter_id integer,
    name character varying(100),
    id integer NOT NULL,
    account_num integer
);


--
-- Name: buildings_twitter_ids_primary_id_seq; Type: SEQUENCE; Schema: business; Owner: -
--

CREATE SEQUENCE buildings_twitter_ids_primary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: buildings_twitter_ids_primary_id_seq; Type: SEQUENCE OWNED BY; Schema: business; Owner: -
--

ALTER SEQUENCE buildings_twitter_ids_primary_id_seq OWNED BY twitter.id;


--
-- Name: business_licenses; Type: TABLE; Schema: business; Owner: -; Tablespace: 
--

CREATE TABLE business_licenses (
    account_num integer,
    site_num integer,
    legal_name character varying(200),
    dba_name character varying(200),
    address character varying(100),
    city character varying(50),
    state character(2),
    zip character varying(10),
    ward integer,
    precinct integer,
    police_dist integer,
    license_code integer,
    license_desc character varying(200),
    license_num integer,
    app_type character varying(50),
    pmt_date date,
    lic_start date,
    lic_exp date,
    date_issued date,
    license_status character varying(50),
    lat double precision,
    lon double precision,
    location text,
    bldg_gid integer,
    str_num character varying(50),
    str_dir character varying(20),
    str_name character varying(150),
    str_type character varying(100),
    floor character varying(50),
    suite character varying(50),
    sec_address character varying(75),
    bldg_address character varying(150),
    id integer NOT NULL
);


--
-- Name: business_owners; Type: TABLE; Schema: business; Owner: -; Tablespace: 
--

CREATE TABLE business_owners (
    acct_num integer,
    legal_name character varying(150),
    owner_first_name character varying(75),
    owner_middle_name character varying(20),
    owner_last_name character varying(75),
    suffix character varying(5),
    legal_entity_owner character varying(100),
    title character varying(25),
    id integer DEFAULT nextval('boid'::regclass) NOT NULL
);


--
-- Name: fun_lics; Type: TABLE; Schema: business; Owner: -; Tablespace: 
--

CREATE TABLE fun_lics (
    license_desc character varying(200)
);


--
-- Name: licenses_historical; Type: TABLE; Schema: business; Owner: -; Tablespace: 
--

CREATE TABLE licenses_historical (
    acct_num character varying(50),
    site_num character varying(50),
    legal_name character varying(200),
    dba_name character varying(200),
    address character varying(200),
    city character varying(50),
    state character(2),
    zip character varying(10),
    license_id character varying(50),
    license_code character varying(50),
    license_desc character varying(200),
    pmt_date character varying(20),
    license_term_start_date character varying(20),
    license_term_end_date character varying(20)
);


--
-- Name: sep14bldg_id_seq; Type: SEQUENCE; Schema: business; Owner: -
--

CREATE SEQUENCE sep14bldg_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sep14bldg_id_seq; Type: SEQUENCE OWNED BY; Schema: business; Owner: -
--

ALTER SEQUENCE sep14bldg_id_seq OWNED BY business_licenses.id;


SET search_path = civic, pg_catalog;

--
-- Name: cemeteries; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE cemeteries (
    gid integer NOT NULL,
    objectid numeric(10,0),
    name character varying(100),
    township character varying(100),
    owner_addr character varying(100),
    owner_name character varying(100),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: chi_idhs_offices; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE chi_idhs_offices (
    resource character varying(100),
    type character varying(75),
    address character varying(100),
    address2 character varying(100),
    phone character varying(20),
    tty character varying(20),
    fax character varying(20),
    toll_free_phone character varying(20),
    website character varying(200),
    additional_information text,
    id integer NOT NULL,
    bldg_gid integer
);


--
-- Name: chi_idhs_offices_id_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE chi_idhs_offices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chi_idhs_offices_id_seq; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE chi_idhs_offices_id_seq OWNED BY chi_idhs_offices.id;


--
-- Name: chicago_cemeteries_gid_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE chicago_cemeteries_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chicago_cemeteries_gid_seq; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE chicago_cemeteries_gid_seq OWNED BY cemeteries.gid;


--
-- Name: circuit_court_cook_cnty_judges; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE circuit_court_cook_cnty_judges (
    dept character varying(100),
    division character varying(75),
    judge_first character varying(30),
    judge_middle character varying(2),
    judge_last character varying(30),
    judge_title character varying(30),
    address character varying(100),
    suite character varying(100),
    building character varying(100),
    phone character varying(20),
    fax character varying(20),
    tty character varying(20),
    lat double precision,
    lon double precision,
    the_geom public.geometry,
    id integer NOT NULL,
    bldg_gid bigint,
    str_num integer,
    str_dir character varying(10),
    str_name character varying(50),
    str_typ character varying(25),
    full_address character varying(75),
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: circuit_court_cook_cnty_judges_id_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE circuit_court_cook_cnty_judges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: circuit_court_cook_cnty_judges_id_seq; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE circuit_court_cook_cnty_judges_id_seq OWNED BY circuit_court_cook_cnty_judges.id;


--
-- Name: commcen_idseq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE commcen_idseq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: community_centers; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE community_centers (
    name character varying(100),
    hours character varying(100),
    phone character varying(12),
    str_num integer,
    str_dir character varying(1),
    str_nam character varying(20),
    str_typ character varying(3),
    id integer DEFAULT nextval('commcen_idseq'::regclass) NOT NULL,
    bldg_gid integer,
    address character varying(75)
);


--
-- Name: contracts; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts (
    po_num character varying(15),
    rev_num character varying(100),
    award_amt numeric(12,2),
    id integer NOT NULL
);


--
-- Name: contracts_approval_date; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_approval_date (
    cid integer NOT NULL,
    approval_date timestamp without time zone
);


--
-- Name: contracts_city_depts; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_city_depts (
    cid integer NOT NULL,
    dept_name character varying(100)
);


--
-- Name: contracts_contract_type; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_contract_type (
    cid integer NOT NULL,
    type character varying(35)
);


--
-- Name: contracts_descriptions; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_descriptions (
    cid integer NOT NULL,
    description character varying(240)
);


--
-- Name: contracts_end_date; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_end_date (
    cid integer NOT NULL,
    end_date timestamp without time zone
);


--
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE contracts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE contracts_id_seq OWNED BY contracts.id;


--
-- Name: contracts_proc_type; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_proc_type (
    cid integer NOT NULL,
    proc_type character varying(25)
);


--
-- Name: contracts_spec_num; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_spec_num (
    cid integer NOT NULL,
    spec_num character varying(11)
);


--
-- Name: contracts_start_date; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_start_date (
    cid integer NOT NULL,
    start_date timestamp without time zone
);


--
-- Name: contracts_vendors; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE contracts_vendors (
    cid integer NOT NULL,
    vendor_id character varying(15),
    name character varying(68),
    address character varying(51),
    city character varying(21),
    state character varying(10),
    zip character varying(10)
);


--
-- Name: cook_co_facilities_in_chicago; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE cook_co_facilities_in_chicago (
    gid integer NOT NULL,
    address character varying(254),
    bldg_code character varying(254),
    node_name character varying(254),
    number character varying(254),
    pin10 character varying(10),
    anno_name character varying(100),
    factype character varying(20),
    pin14 character varying(14),
    bldg_gid integer
);


--
-- Name: cook_co_facilities_in_chicago_gid_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE cook_co_facilities_in_chicago_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cook_co_facilities_in_chicago_gid_seq; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE cook_co_facilities_in_chicago_gid_seq OWNED BY cook_co_facilities_in_chicago.gid;


--
-- Name: debarred; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE debarred (
    entity_or_individual character varying(100),
    address character varying(75),
    city character varying(20),
    state character varying(2),
    zip character varying(5),
    debar_date date,
    length_of_debarment character varying(25),
    reason text,
    type character varying(150)
);


--
-- Name: elevation_benchmarks; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE elevation_benchmarks (
    benchmark_num integer,
    northing real,
    easting real,
    elevation real,
    location_desc text,
    loc_desc2 text,
    mark_desc text,
    year_fixed integer,
    book_num integer,
    latitude double precision,
    longitude double precision,
    est_loc text,
    id integer NOT NULL,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: elevation_benchmarks_id_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE elevation_benchmarks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ewaste_collection_sites; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE ewaste_collection_sites (
    name character varying(100),
    address character varying(50),
    phone character varying(15),
    lat double precision,
    lon double precision,
    id integer NOT NULL,
    bldg_gid integer
);


--
-- Name: ewaste_collection_sites_id_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE ewaste_collection_sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ewaste_collection_sites_id_seq; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE ewaste_collection_sites_id_seq OWNED BY ewaste_collection_sites.id;


--
-- Name: farmers_markets_idseq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE farmers_markets_idseq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lobbyist_2011_agency_report; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE lobbyist_2011_agency_report (
    last_name character varying(20),
    first_name character varying(20),
    mid_init character varying(1),
    agency character varying(100),
    admin_action boolean NOT NULL,
    legislative_action boolean NOT NULL,
    action_sought text,
    client character varying(100)
);


--
-- Name: lobbyist_2011_compensation; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE lobbyist_2011_compensation (
    last_name character varying(20),
    first_name character varying(20),
    mid_int character varying(1),
    client text,
    compensation numeric(12,2)
);


--
-- Name: lobbyist_2011_major_expenditures; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE lobbyist_2011_major_expenditures (
    last_name character varying(20),
    first_name character varying(20),
    mid_int character varying(1),
    expense_date date,
    recipient_name text,
    prupose text,
    amount numeric(12,2),
    action text,
    client text
);


--
-- Name: public_tech_resources; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE public_tech_resources (
    type character varying(100),
    facility character varying(100),
    address character varying(100),
    phone character varying(200),
    website character varying(150),
    hours text,
    appt character varying(10),
    internet boolean,
    wifi boolean,
    training boolean,
    bldg_gid integer,
    id integer NOT NULL
);


--
-- Name: ptr_updated_id_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE ptr_updated_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ptr_updated_id_seq; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE ptr_updated_id_seq OWNED BY public_tech_resources.id;


--
-- Name: public_plazas; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE public_plazas (
    gid integer NOT NULL,
    name character varying(100),
    addr_no numeric(10,0),
    dir character varying(1),
    street_nam character varying(40),
    street_typ character varying(5),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: public_plazas_gid_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE public_plazas_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_plazas_gid_seq; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE public_plazas_gid_seq OWNED BY public_plazas.gid;


--
-- Name: senior_centers_id_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE senior_centers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: senior_centers; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE senior_centers (
    program character varying(100),
    name character varying(25),
    hours text,
    address character varying(100),
    phone character varying(15),
    id integer DEFAULT nextval('senior_centers_id_seq'::regclass) NOT NULL,
    full_name character varying(100),
    bldg_gid integer
);


SET search_path = health, pg_catalog;

--
-- Name: wfctrid; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE wfctrid
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET search_path = civic, pg_catalog;

--
-- Name: workforce_centers; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE workforce_centers (
    name character varying(100),
    hours text,
    address character varying(100),
    phone character varying(20),
    id integer DEFAULT nextval('health.wfctrid'::regclass) NOT NULL,
    bldg_gid integer
);


--
-- Name: youth_centers; Type: TABLE; Schema: civic; Owner: -; Tablespace: 
--

CREATE TABLE youth_centers (
    agency_name character varying(100),
    project character varying(75),
    str_num integer,
    str_dir character varying(1),
    str_nam character varying(100),
    str_typ character varying(6),
    address character varying(75),
    zip character varying(5),
    phone character varying(25),
    fax character varying(100),
    alt_phone character varying(100),
    id integer NOT NULL,
    bldg_gid integer
);


--
-- Name: youth_centers_id_seq; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE youth_centers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: youth_centers_id_seq1; Type: SEQUENCE; Schema: civic; Owner: -
--

CREATE SEQUENCE youth_centers_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: youth_centers_id_seq1; Type: SEQUENCE OWNED BY; Schema: civic; Owner: -
--

ALTER SEQUENCE youth_centers_id_seq1 OWNED BY youth_centers.id;


SET search_path = cta, pg_catalog;

--
-- Name: bus_routes; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE bus_routes (
    gid integer NOT NULL,
    route character varying(4),
    name character varying(32),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: bus_routes_gid_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE bus_routes_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bus_routes_gid_seq; Type: SEQUENCE OWNED BY; Schema: cta; Owner: -
--

ALTER SEQUENCE bus_routes_gid_seq OWNED BY bus_routes.gid;


--
-- Name: bus_stops; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE bus_stops (
    gid integer NOT NULL,
    systemstop integer,
    street character varying(75),
    cross_st character varying(75),
    dir character varying(3),
    pos character varying(4),
    routesstpg character varying(75),
    owlroutes character varying(20),
    city character varying(20),
    status numeric(10,0),
    public_nam character varying(75),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: bus_stops_gid_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE bus_stops_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bus_stops_gid_seq; Type: SEQUENCE OWNED BY; Schema: cta; Owner: -
--

ALTER SEQUENCE bus_stops_gid_seq OWNED BY bus_stops.gid;


--
-- Name: cta_bus_garages; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_bus_garages (
    gid integer NOT NULL,
    name character varying(100),
    address character varying(150),
    use character varying(75),
    area integer,
    bldg_area integer,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: cta_bus_garages_gid_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE cta_bus_garages_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cta_bus_garages_gid_seq; Type: SEQUENCE OWNED BY; Schema: cta; Owner: -
--

ALTER SEQUENCE cta_bus_garages_gid_seq OWNED BY cta_bus_garages.gid;


--
-- Name: cta_bus_owl; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_bus_owl (
    stopid integer,
    routeid integer
);


--
-- Name: cta_bus_ridership_id_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE cta_bus_ridership_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cta_bus_ridership; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_bus_ridership (
    route character varying(6),
    date date,
    daytype character varying(1),
    rides integer,
    id integer DEFAULT nextval('cta_bus_ridership_id_seq'::regclass) NOT NULL
);


--
-- Name: cta_bus_stops_routes; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_bus_stops_routes (
    stopid integer,
    routeid integer
);


--
-- Name: cta_digital_signs_id_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE cta_digital_signs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cta_digital_signs; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_digital_signs (
    stopid integer,
    stop_name character varying(100),
    direction character varying(3),
    routes character varying(100),
    regional_connections character varying(100),
    longitude double precision,
    latitude double precision,
    id integer DEFAULT nextval('cta_digital_signs_id_seq'::regclass) NOT NULL,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: cta_el_ridership_id_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE cta_el_ridership_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cta_el_ridership; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_el_ridership (
    station_id integer,
    station_name character varying(100),
    date date,
    daytype character varying(1),
    rides integer,
    id integer DEFAULT nextval('cta_el_ridership_id_seq'::regclass) NOT NULL
);


--
-- Name: cta_fare_media_retail_outlets; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_fare_media_retail_outlets (
    gid integer NOT NULL,
    name character varying(254),
    outlet_typ character varying(254),
    address character varying(254),
    outletfare character varying(254),
    payment character varying(254),
    description character varying(100),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: cta_fare_media_retail_outlets_faretypes; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_fare_media_retail_outlets_faretypes (
    gid integer NOT NULL,
    fare_type character varying(15)
);


--
-- Name: cta_rail_lines_iso; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_rail_lines_iso (
    id integer NOT NULL,
    line character varying(20)
);


--
-- Name: cta_rail_lines_iso_id_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE cta_rail_lines_iso_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cta_rail_lines_iso_id_seq; Type: SEQUENCE OWNED BY; Schema: cta; Owner: -
--

ALTER SEQUENCE cta_rail_lines_iso_id_seq OWNED BY cta_rail_lines_iso.id;


--
-- Name: cta_rail_stations_lines; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE cta_rail_stations_lines (
    stationid integer,
    lineid integer
);


--
-- Name: ctafaremedia_gid_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE ctafaremedia_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ctafaremedia_gid_seq; Type: SEQUENCE OWNED BY; Schema: cta; Owner: -
--

ALTER SEQUENCE ctafaremedia_gid_seq OWNED BY cta_fare_media_retail_outlets.gid;


--
-- Name: owlroutes; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE owlroutes (
    owl character varying(6),
    route character varying(75),
    id integer NOT NULL
);


--
-- Name: owlroutes_id_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE owlroutes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: owlroutes_id_seq; Type: SEQUENCE OWNED BY; Schema: cta; Owner: -
--

ALTER SEQUENCE owlroutes_id_seq OWNED BY owlroutes.id;


--
-- Name: rail_lines; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE rail_lines (
    gid integer NOT NULL,
    segment_id numeric(10,0),
    asset_id numeric(10,0),
    lines character varying(100),
    descriptio character varying(100),
    type numeric(10,0),
    legend character varying(5),
    alt_legend character varying(5),
    branch character varying(100),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: rail_lines_gid_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE rail_lines_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rail_lines_gid_seq; Type: SEQUENCE OWNED BY; Schema: cta; Owner: -
--

ALTER SEQUENCE rail_lines_gid_seq OWNED BY rail_lines.gid;


--
-- Name: rail_lines_prejct; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE rail_lines_prejct (
    gid integer,
    lineid integer
);


--
-- Name: rail_stations; Type: TABLE; Schema: cta; Owner: -; Tablespace: 
--

CREATE TABLE rail_stations (
    gid integer NOT NULL,
    station_id numeric(10,0),
    name character varying(100),
    lines character varying(100),
    address character varying(100),
    ada smallint,
    pknrd smallint,
    gtfs numeric(10,0),
    the_geom public.geometry,
    bldg_gid integer,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: rail_stations_gid_seq; Type: SEQUENCE; Schema: cta; Owner: -
--

CREATE SEQUENCE rail_stations_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rail_stations_gid_seq; Type: SEQUENCE OWNED BY; Schema: cta; Owner: -
--

ALTER SEQUENCE rail_stations_gid_seq OWNED BY rail_stations.gid;


SET search_path = demographics, pg_catalog;

--
-- Name: births_and_birth_rates; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE births_and_birth_rates (
    ca_num integer NOT NULL,
    ca character varying(50),
    births_1999 integer,
    birth_rate_1999 numeric(4,1),
    birth_rate_1999_lower_ci numeric(4,1),
    birth_rate_1999_upper_ci numeric(4,1),
    births_2000 integer,
    birth_rate_2000 numeric(4,1),
    birth_rate_2000_lower_ci numeric(4,1),
    birth_rate_2000_upper_ci numeric(4,1),
    births_2001 integer,
    birth_rate_2001 numeric(4,1),
    birth_rate_2001_lower_ci numeric(4,1),
    birth_rate_2001_upper_ci numeric(4,1),
    births_2002 integer,
    birth_rate_2002 numeric(4,1),
    birth_rate_2002_lower_ci numeric(4,1),
    birth_rate_2002_upper_ci numeric(4,1),
    births_2003 integer,
    birth_rate_2003 numeric(4,1),
    birth_rate_2003_lower_ci numeric(4,1),
    birth_rate_2003_upper_ci numeric(4,1),
    births_2004 integer,
    birth_rate_2004 numeric(4,1),
    birth_rate_2004_lower_ci numeric(4,1),
    birth_rate_2004_upper_ci numeric(4,1),
    births_2005 integer,
    birth_rate_2005 numeric(4,1),
    birth_rate_2005_lower_ci numeric(4,1),
    birth_rate_2005_upper_ci numeric(4,1),
    births_2006 integer,
    birth_rate_2006 numeric(4,1),
    birth_rate_2006_lower_ci numeric(4,1),
    birth_rate_2006_upper_ci numeric(4,1),
    births_2007 integer,
    birth_rate_2007 numeric(4,1),
    birth_rate_2007_lower_ci numeric(4,1),
    birth_rate_2007_upper_ci numeric(4,1),
    births_2008 integer,
    birth_rate_2008 numeric(4,1),
    birth_rate_2008_lower_ci numeric(4,1),
    birth_rate_2008_upper_ci numeric(4,1),
    births_2009 integer,
    birth_rate_2009 numeric(4,1),
    birth_rate_2009_lower_ci numeric(4,1),
    birth_rate_2009_upper_ci numeric(4,1)
);


--
-- Name: census_blocks_families_husband_and_wife; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_blocks_families_husband_and_wife (
    gid integer NOT NULL,
    total numeric,
    related_child_under_18 numeric,
    related_own_child_under_18 numeric,
    related_own_child_under_6 numeric,
    related_own_child_under_6_and_btw_6_17 numeric,
    related_own_child_btw_6_17 numeric
);


--
-- Name: census_blocks_families_single_mother; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_blocks_families_single_mother (
    gid integer NOT NULL,
    total numeric,
    related_child_under_18 numeric,
    related_own_child_under_18 numeric,
    related_own_child_under_6 numeric,
    related_own_child_under_6_and_btw_6_17 numeric,
    related_own_child_btw_6_17 numeric
);


--
-- Name: census_blocks_families_total; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_blocks_families_total (
    gid integer NOT NULL,
    avgsize numeric,
    related_child_under_18 numeric,
    related_own_child_under_18 numeric,
    related_own_child_under_6 numeric,
    related_own_child_under_6_and_btw_6_17 numeric,
    related_own_child_btw_6_17 numeric
);


--
-- Name: census_blocks_households; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_blocks_households (
    gid integer NOT NULL,
    total numeric,
    occupied numeric,
    vacant numeric,
    family numeric,
    male_householder numeric,
    female_householder numeric,
    nonfamily numeric,
    nonfamily_male_householder numeric,
    nonfamily_male_householder_lives_alone numeric,
    nonfamily_female_householder numeric,
    nonfamily_female_householder_lives_alone numeric,
    one_person numeric,
    two_person numeric,
    three_person numeric,
    four_person numeric,
    five_person numeric,
    six_person numeric,
    seven_plus_person numeric,
    avg_size numeric
);


--
-- Name: census_blocks_population_by_race; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_blocks_population_by_race (
    gid integer NOT NULL,
    total numeric,
    white numeric,
    latino numeric,
    black numeric,
    native_american numeric,
    asian numeric,
    hawaii_pac_isl numeric,
    other_race numeric,
    two_plus_races numeric
);


--
-- Name: census_blocks_sex_by_age; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_blocks_sex_by_age (
    gid integer NOT NULL,
    male numeric,
    male_under_5 numeric,
    male_5_9 numeric,
    male_10_14 numeric,
    male_15_17 numeric,
    male_18_19 numeric,
    male_20 numeric,
    male_21 numeric,
    male_22_24 numeric,
    male_25_29 numeric,
    male_30_34 numeric,
    male_35_39 numeric,
    male_40_44 numeric,
    male_45_49 numeric,
    male_50_54 numeric,
    male_55_59 numeric,
    male_60_61 numeric,
    male_62_64 numeric,
    male_65_66 numeric,
    male_67_69 numeric,
    male_70_74 numeric,
    male_75_79 numeric,
    male_80_84 numeric,
    male_85plus numeric,
    female numeric,
    female_under_5 numeric,
    female_5_9 numeric,
    female_10_14 numeric,
    female_15_17 numeric,
    female_18_19 numeric,
    female_20 numeric,
    female_21 numeric,
    female_22_24 numeric,
    female_25_29 numeric,
    female_30_34 numeric,
    female_35_39 numeric,
    female_40_44 numeric,
    female_45_49 numeric,
    female_50_54 numeric,
    female_55_59 numeric,
    female_60_61 numeric,
    female_62_64 numeric,
    female_65_66 numeric,
    female_67_69 numeric,
    female_70_74 numeric,
    female_75_79 numeric,
    female_80_84 numeric,
    female_85plus numeric
);


--
-- Name: census_tracts_ancestry; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_ancestry (
    gid integer NOT NULL,
    american numeric,
    arab numeric,
    czech numeric,
    danish numeric,
    dutch numeric,
    english numeric,
    french numeric,
    french_canadian numeric,
    german numeric,
    greek numeric,
    hungarian numeric,
    irish numeric,
    italian numeric,
    lithuanian numeric,
    norwegian numeric,
    polish numeric,
    portuguese numeric,
    russian numeric,
    scotch_irish numeric,
    scottish numeric,
    slovak numeric,
    sub_saharan_africa numeric,
    swedish numeric,
    swiss numeric,
    ukrainian numeric,
    welsh numeric,
    west_indies numeric
);


--
-- Name: census_tracts_education; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_education (
    gid integer NOT NULL,
    total numeric,
    no_high_school_diploma numeric,
    high_school_diploma numeric,
    associates_degree numeric,
    bachelors_degree numeric,
    graduate_degree numeric
);


--
-- Name: census_tracts_fertility; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_fertility (
    gid integer NOT NULL,
    total_female_btw_15_50 numeric,
    unmarried numeric,
    unmarried_per_thousand numeric,
    btw_15_50_per_thousand numeric,
    btw_15_19_per_thousand numeric,
    btw_20_34_per_thousand numeric,
    btw_35_50_per_thousand numeric
);


--
-- Name: census_tracts_grandparents; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_grandparents (
    gid integer NOT NULL,
    live_with_own_grandchild_under18 numeric,
    responsible_for_grandchild_total numeric,
    responsible_for_grandchild_for_less_than_1yr numeric,
    responsible_for_grandchild_btw_1_and_2_yrs numeric,
    responsible_for_grandchild_btw_3_and_4_yrs numeric,
    responsible_for_grandchild_for_5plus_yrs numeric,
    female numeric,
    married numeric
);


--
-- Name: census_tracts_household_income; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_household_income (
    gid integer NOT NULL,
    median_family numeric,
    under_10 numeric,
    btw_10_15 numeric,
    btw_15_25 numeric,
    btw_25_35 numeric,
    btw_35_50 numeric,
    btw_50_75 numeric,
    btw_75_100 numeric,
    btw_100_150 numeric,
    btw_150_200 numeric,
    more_than_200 numeric,
    tot_with_social_security numeric,
    mean_social_security numeric,
    tot_with_retirement numeric,
    mean_retirement numeric,
    tot_with_supplementary_security numeric,
    mean_supplementary_security numeric,
    tot_with_cash_public_assistance numeric,
    mean_cash_public_assistance numeric,
    tot_with_snap_past_12_months numeric,
    per_capita numeric,
    median_earnings numeric,
    median_male_earnings numeric,
    median_female_earnings numeric
);


--
-- Name: census_tracts_households; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_households (
    gid integer NOT NULL,
    total numeric,
    families numeric,
    familes_own_child_under18 numeric,
    married_couple numeric,
    married_couple_own_child_under_18 numeric,
    families_male_householder_no_wife_present numeric,
    families_mholder_no_wife_related_own_child_under18 numeric,
    families_female_householder_no_husband_presetn numeric,
    families_fholder_no_husband_related_own_child_under18 numeric,
    nonfamily numeric,
    nonfamily_lives_alone numeric,
    nonfamily_lives_alone_65_plus numeric,
    at_least_one_under18 numeric,
    at_least_one_over65 numeric,
    average_household_size numeric,
    average_family_size numeric,
    total_population_in_households numeric,
    relationship_householder numeric,
    relationship_spouse numeric,
    relationship_child numeric,
    relationship_other_relative numeric,
    relationship_nonrelative numeric,
    relationship_unmarried_partner numeric
);


--
-- Name: census_tracts_housing; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing (
    gid integer NOT NULL,
    total numeric,
    occupied numeric,
    vacant numeric,
    homeowner_vacancy_rate numeric,
    rental_vacancy_rate numeric
);


--
-- Name: census_tracts_housing_bedrooms; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_bedrooms (
    gid integer NOT NULL,
    "none" numeric,
    one numeric,
    two numeric,
    three numeric,
    four numeric,
    five_plus numeric
);


--
-- Name: census_tracts_housing_gross_rent; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_gross_rent (
    gid integer NOT NULL,
    under_200 numeric,
    btw_200_299 numeric,
    btw_300_499 numeric,
    btw_500_749 numeric,
    btw_750_999 numeric,
    btw_1000_1499 numeric,
    more_than_1500 numeric,
    median numeric,
    no_rent_paid numeric,
    pct_hhinc_under_15 numeric,
    pct_hhinc_btw_15_199 numeric,
    pct_hhinc_btw_20_249 numeric,
    pct_hhinc_btw_25_299 numeric,
    pct_hhinc_btw30_349 numeric,
    pct_hhinc_35plus numeric,
    pct_hhinc_not_computed numeric
);


--
-- Name: census_tracts_housing_heating; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_heating (
    gid integer NOT NULL,
    utility_gas numeric,
    bottle_tank_or_lp numeric,
    electric numeric,
    fuel_oil_or_kerosene numeric,
    coal_or_coke numeric,
    wood numeric,
    solar numeric,
    other numeric,
    no_fuel numeric
);


--
-- Name: census_tracts_housing_mortgage_smoc; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_mortgage_smoc (
    gid integer NOT NULL,
    total numeric,
    under_300 numeric,
    btw_300_499 numeric,
    btw_500_699 numeric,
    btw_700_999 numeric,
    btw_1000_1499 numeric,
    btw_1500_1999 numeric,
    more_than_2000 numeric,
    median numeric,
    pct_hhinc_under_20 numeric,
    pct_hhinc_btw_20_249 numeric,
    pct_hhinc_btw_25_299 numeric,
    pct_hhinc_btw_30_349 numeric,
    pct_hhinc_35plus numeric,
    pct_hhinc_not_computed numeric
);


--
-- Name: census_tracts_housing_no_mortgage_smoc; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_no_mortgage_smoc (
    gid integer NOT NULL,
    total numeric,
    under_100 numeric,
    btw_100_199 numeric,
    btw_200_299 numeric,
    btw_300_399 numeric,
    more_than_400 numeric,
    median numeric,
    pct_hhinc_under_10 numeric,
    pct_hhinc_btw_10_149 numeric,
    pct_hhinc_btw_15_199 numeric,
    pct_hhinc_btw_20_249 numeric,
    pct_hhinc_btw_25_299 numeric,
    pct_hhinc_btw_30_349 numeric,
    pct_hhinc_35plus numeric,
    pct_hhinc_not_computed numeric
);


--
-- Name: census_tracts_housing_occupants_per_room; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_occupants_per_room (
    gid integer NOT NULL,
    less_than_1 numeric,
    btw_1_1andhalf numeric,
    more_than_1_and_half numeric
);


--
-- Name: census_tracts_housing_rooms; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_rooms (
    gid integer NOT NULL,
    one numeric,
    two numeric,
    three numeric,
    four numeric,
    five numeric,
    six numeric,
    seven numeric,
    eight numeric,
    nine_or_more numeric,
    median numeric
);


--
-- Name: census_tracts_housing_selected_characteristics; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_selected_characteristics (
    gid integer NOT NULL,
    incomplete_plumbing numeric,
    incomplete_kitchen numeric,
    no_phone numeric
);


--
-- Name: census_tracts_housing_tenure; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_tenure (
    gid integer NOT NULL,
    owner_occupied numeric,
    renter_occupied numeric,
    owner_occupied_avg_household_size numeric,
    renter_occupied_avg_household_size numeric
);


--
-- Name: census_tracts_housing_units; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_units (
    gid integer NOT NULL,
    one_detached numeric,
    one_attached numeric,
    two numeric,
    btw_3_4 numeric,
    btw_5_9 numeric,
    btw_10_19 numeric,
    more_than_20 numeric,
    mobile_home numeric,
    boat_rv_van numeric
);


--
-- Name: census_tracts_housing_value; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_value (
    gid integer NOT NULL,
    under_50 numeric,
    btw_50_99 numeric,
    btw_100_149 numeric,
    btw_150_199 numeric,
    btw_200_299 numeric,
    btw_300_499 numeric,
    btw_500_999 numeric,
    over_1mil numeric,
    median numeric
);


--
-- Name: census_tracts_housing_year_moved_in; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_housing_year_moved_in (
    gid integer NOT NULL,
    after_2004 numeric,
    btw_2000_04 numeric,
    btw_1990_99 numeric,
    btw_1980_89 numeric,
    btw_1970_79 numeric,
    before_1969 numeric
);


--
-- Name: census_tracts_languages_spoken_at_home; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_languages_spoken_at_home (
    gid integer NOT NULL,
    total_pop_5plus numeric,
    english_only numeric,
    not_english numeric,
    english_less_than_very_well numeric,
    spanish numeric,
    spanish_and_english_less_than_very_well numeric,
    other_indo_european numeric,
    other_indo_european_and_english_less_than_very_well numeric,
    asian_or_pacific_island numeric,
    asia_or_pacific_island_and_english_less_than_very_well numeric,
    other numeric,
    other_and_english_less_than_very_well numeric
);


--
-- Name: census_tracts_marital_status; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_marital_status (
    gid integer NOT NULL,
    total_males_15plus numeric,
    male_never_married numeric,
    male_married_now_but_separated numeric,
    male_separated numeric,
    male_widowed numeric,
    male_divorced numeric,
    total_females_15plus numeric,
    female_never_married numeric,
    female_married_now_but_separated numeric,
    female_separated numeric,
    female_widowed numeric,
    female_divorced numeric
);


--
-- Name: census_tracts_mobility; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_mobility (
    gid integer NOT NULL,
    same_house_1yr_ago numeric,
    dif_house_in_us_1yr_ago numeric,
    dif_house_same_county_1yr_ago numeric,
    dif_county_1yr_ago numeric,
    dif_county_same_state_1yr_ago numeric,
    dif_state_1yr_ago numeric,
    resided_abroad_1yr_ago numeric
);


--
-- Name: census_tracts_nativity; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_nativity (
    gid integer NOT NULL,
    native_born numeric,
    native_born_in_us numeric,
    native_born_in_residing_state numeric,
    native_born_in_different_state numeric,
    native_born_pr_usvi_or_abroad numeric,
    foreign_born_total numeric,
    naturalized_total numeric,
    not_us_citizen numeric,
    native_born_entered_2000_or_later numeric,
    native_born_entered_before_2000 numeric,
    foreign_born_entered_2000_or_later numeric,
    foreign_born_entered_before_2000 numeric,
    foreign_born_europe numeric,
    foreign_born_asia numeric,
    foreign_born_africa numeric,
    foreign_born_oceania numeric,
    foreign_born_latin_america numeric,
    foreign_born_northern_america numeric
);


--
-- Name: census_tracts_population; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_population (
    gid integer NOT NULL,
    tractid character varying(11),
    total numeric
);


--
-- Name: census_tracts_poverty; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_poverty (
    gid integer NOT NULL,
    pct_below numeric,
    pct_below_with_child_under_18 numeric
);


--
-- Name: census_tracts_school_enrollment; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_school_enrollment (
    gid integer NOT NULL,
    total_3_yrs_plus_enrolled numeric,
    preschool numeric,
    kindergarten numeric,
    elementary_grades_1_thru_8 numeric,
    high_school numeric,
    college_or_graduate_school numeric
);


--
-- Name: census_tracts_transportation_to_work; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_transportation_to_work (
    gid integer NOT NULL,
    total numeric,
    drove_alone numeric,
    carpooled numeric,
    public_transportation numeric,
    walked numeric,
    other numeric,
    worked_at_home numeric,
    avg_transit_time_mins numeric
);


--
-- Name: census_tracts_vehicles_available; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_vehicles_available (
    gid integer NOT NULL,
    "none" numeric,
    one numeric,
    two numeric,
    three_plus numeric
);


--
-- Name: census_tracts_veterans; Type: TABLE; Schema: demographics; Owner: -; Tablespace: 
--

CREATE TABLE census_tracts_veterans (
    gid integer NOT NULL,
    total numeric
);


SET search_path = education, pg_catalog;

--
-- Name: boundarygrades1; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades1 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades10; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades10 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(50),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades10_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades10_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades10_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades10_gid_seq OWNED BY boundarygrades10.gid;


--
-- Name: boundarygrades11; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades11 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(50),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades11_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades11_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades11_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades11_gid_seq OWNED BY boundarygrades11.gid;


--
-- Name: boundarygrades12; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades12 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(50),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades12_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades12_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades12_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades12_gid_seq OWNED BY boundarygrades12.gid;


--
-- Name: boundarygrades1_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades1_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades1_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades1_gid_seq OWNED BY boundarygrades1.gid;


--
-- Name: boundarygrades2; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades2 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades2_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades2_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades2_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades2_gid_seq OWNED BY boundarygrades2.gid;


--
-- Name: boundarygrades3; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades3 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades3_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades3_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades3_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades3_gid_seq OWNED BY boundarygrades3.gid;


--
-- Name: boundarygrades4; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades4 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades4_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades4_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades4_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades4_gid_seq OWNED BY boundarygrades4.gid;


--
-- Name: boundarygrades5; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades5 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades5_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades5_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades5_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades5_gid_seq OWNED BY boundarygrades5.gid;


--
-- Name: boundarygrades6; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades6 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades6_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades6_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades6_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades6_gid_seq OWNED BY boundarygrades6.gid;


--
-- Name: boundarygrades7; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades7 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades7_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades7_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades7_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades7_gid_seq OWNED BY boundarygrades7.gid;


--
-- Name: boundarygrades8; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades8 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades8_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades8_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades8_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades8_gid_seq OWNED BY boundarygrades8.gid;


--
-- Name: boundarygrades9; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygrades9 (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(50),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygrades9_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygrades9_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygrades9_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygrades9_gid_seq OWNED BY boundarygrades9.gid;


--
-- Name: boundarygradesk; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE boundarygradesk (
    gid integer NOT NULL,
    objectid integer,
    label character varying(254),
    unitc character varying(4),
    address character varying(24),
    grades character varying(35),
    schoolid character varying(6),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_le_2 numeric,
    shape_area numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boundarygradesk_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE boundarygradesk_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boundarygradesk_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE boundarygradesk_gid_seq OWNED BY boundarygradesk.gid;


--
-- Name: campus_parks; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE campus_parks (
    gid integer NOT NULL,
    cps_school character varying(53),
    proj_name character varying(36),
    year_built character varying(18),
    address character varying(26),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: campus_parks2_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE campus_parks2_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: campus_parks2_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE campus_parks2_gid_seq OWNED BY campus_parks.gid;


--
-- Name: libraries; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE libraries (
    name character varying(75),
    hours character varying(100),
    cybernavigator boolean NOT NULL,
    teacher_in_library boolean NOT NULL,
    address character varying(75),
    id integer NOT NULL,
    bldg_gid integer,
    str_num integer,
    str_dir character(1),
    str_name character varying(50),
    str_type character varying(10),
    full_address character varying(100)
);


--
-- Name: libraries_locations_hours_id_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE libraries_locations_hours_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: libraries_locations_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE libraries_locations_hours_id_seq OWNED BY libraries.id;


--
-- Name: private_schools; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE private_schools (
    gid integer NOT NULL,
    side character varying(1),
    region_2_c character varying(9),
    type character varying(5),
    name character varying(33),
    administrator character varying(24),
    address character varying(20),
    zip_code character varying(9),
    enrollment character varying(9),
    grades_served character varying(12),
    state_rep character varying(5),
    state_sena character varying(6),
    federal_co character varying(9),
    registered character varying(9),
    bldg_gid integer
);


--
-- Name: private_schools_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE private_schools_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: private_schools_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE private_schools_gid_seq OWNED BY private_schools.gid;


--
-- Name: public_schools; Type: TABLE; Schema: education; Owner: -; Tablespace: 
--

CREATE TABLE public_schools (
    gid integer NOT NULL,
    status character varying(1),
    score numeric,
    match_type character varying(2),
    match_addr character varying(120),
    pct_along numeric,
    side character varying(1),
    ref_id integer,
    x numeric,
    y numeric,
    user_fld character varying(120),
    addr_type character varying(20),
    arc_street character varying(100),
    arc_zip character varying(10),
    schoolid character varying(254),
    facilityid numeric,
    school character varying(254),
    label character varying(254),
    address character varying(254),
    grades character varying(254),
    cps_type character varying(254),
    zip character varying(254),
    mr character varying(254),
    phone character varying(254),
    fax character varying(254),
    type_ character varying(254),
    boundary character varying(254),
    schooltrac character varying(254),
    str_num character varying(20),
    str_dir character varying(10),
    str_name character varying(100),
    str_type character varying(100),
    bldg_gid integer,
    full_address character varying(200)
);


--
-- Name: schoollocations2012_13_gid_seq; Type: SEQUENCE; Schema: education; Owner: -
--

CREATE SEQUENCE schoollocations2012_13_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schoollocations2012_13_gid_seq; Type: SEQUENCE OWNED BY; Schema: education; Owner: -
--

ALTER SEQUENCE schoollocations2012_13_gid_seq OWNED BY public_schools.gid;


SET search_path = environment, pg_catalog;

--
-- Name: farmers_markets_2012; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE farmers_markets_2012 (
    gid integer NOT NULL,
    location character varying(50),
    intersecti character varying(60),
    day_ character varying(12),
    start_time character varying(8),
    end_time character varying(8),
    start_date date,
    end_date date,
    website character varying(50),
    type character varying(30),
    link_accep character varying(10),
    the_geom public.geometry(Point,3435)
);


--
-- Name: farmers_markets_2012_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE farmers_markets_2012_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: farmers_markets_2012_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE farmers_markets_2012_gid_seq OWNED BY farmers_markets_2012.gid;


--
-- Name: fishing_lake_bathymetry; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE fishing_lake_bathymetry (
    gid integer NOT NULL,
    lakename character varying(100),
    depth_ft double precision,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 4)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: fishing_lake_bathymetry_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE fishing_lake_bathymetry_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fishing_lake_bathymetry_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE fishing_lake_bathymetry_gid_seq OWNED BY fishing_lake_bathymetry.gid;


--
-- Name: forest_preserve_groves; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE forest_preserve_groves (
    gid integer NOT NULL,
    name character varying(100),
    division character varying(100),
    groveno integer,
    people integer,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: forest_preserve_groves_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE forest_preserve_groves_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forest_preserve_groves_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE forest_preserve_groves_gid_seq OWNED BY forest_preserve_groves.gid;


--
-- Name: forest_preserve_shelters; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE forest_preserve_shelters (
    gid integer NOT NULL,
    name character varying(100),
    division character varying(100),
    the_geom public.geometry,
    bldg_gid integer,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: forest_preserve_shelters_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE forest_preserve_shelters_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forest_preserve_shelters_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE forest_preserve_shelters_gid_seq OWNED BY forest_preserve_shelters.gid;


--
-- Name: forest_preserve_trails; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE forest_preserve_trails (
    gid integer NOT NULL,
    name character varying(20),
    comments character varying(100),
    gps character varying(5),
    paved character varying(15),
    name2 character varying(100),
    largemap character varying(5),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: forestry; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE forestry (
    gid integer NOT NULL,
    forest_id double precision,
    name character varying(30),
    edit_date1 character varying(10),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: forestry_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE forestry_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: forestry_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE forestry_gid_seq OWNED BY forestry.gid;


--
-- Name: waterways; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE waterways (
    gid integer NOT NULL,
    display double precision,
    name character varying(35),
    edit_date1 character varying(10),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: hydro_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE hydro_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hydro_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE hydro_gid_seq OWNED BY waterways.gid;


--
-- Name: natural_habitats; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE natural_habitats (
    gid integer NOT NULL,
    address character varying(30),
    ownership character varying(40),
    features character varying(60),
    name character varying(100),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: natural_habitats_comments; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE natural_habitats_comments (
    gid integer NOT NULL,
    comment character varying(67)
);


--
-- Name: natural_habitats_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE natural_habitats_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: natural_habitats_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE natural_habitats_gid_seq OWNED BY natural_habitats.gid;


--
-- Name: neighborspace_gardens; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE neighborspace_gardens (
    gid integer NOT NULL,
    match_addr character varying(70),
    site_name character varying(100),
    site_addre character varying(70),
    sq_ft numeric(10,0),
    acres double precision,
    owned_or_l character varying(20),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: neighborspace_gardens_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE neighborspace_gardens_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: neighborspace_gardens_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE neighborspace_gardens_gid_seq OWNED BY neighborspace_gardens.gid;


--
-- Name: park_events; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE park_events (
    requestor character varying(100),
    org character varying(100),
    park character varying(100),
    start_date date,
    end_date date,
    event_type character varying(100),
    event_desc text,
    permit_status character varying(100)
);


--
-- Name: parkbuildings_aug2012; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE parkbuildings_aug2012 (
    gid integer NOT NULL,
    park character varying(254),
    park_no integer,
    bldg_type character varying(254),
    bldg_statu character varying(254),
    ward numeric,
    comm_area numeric,
    region character varying(254),
    address character varying(254),
    bldg_name character varying(254),
    demolished character varying(254),
    year_built numeric,
    the_geom public.geometry(Point,3435)
);


--
-- Name: parkbuildings_aug2012_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE parkbuildings_aug2012_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parkbuildings_aug2012_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE parkbuildings_aug2012_gid_seq OWNED BY parkbuildings_aug2012.gid;


--
-- Name: parkfacilities_aug2012; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE parkfacilities_aug2012 (
    gid integer NOT NULL,
    park character varying(254),
    park_no integer,
    facility_n character varying(254),
    facility_t character varying(254),
    the_geom public.geometry(Point,3435)
);


--
-- Name: parkfacilities_aug2012_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE parkfacilities_aug2012_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parkfacilities_aug2012_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE parkfacilities_aug2012_gid_seq OWNED BY parkfacilities_aug2012.gid;


--
-- Name: parks; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE parks (
    gid integer NOT NULL,
    park_no numeric,
    park character varying(35),
    location character varying(30),
    zip character varying(5),
    acres numeric,
    ward numeric,
    park_class character varying(254),
    label character varying(50),
    wheelchr_a integer,
    alfred_cal integer,
    archery_ra integer,
    artificial integer,
    band_shell integer,
    baseball_b integer,
    basketball integer,
    basketba_1 integer,
    beach integer,
    boat_launc integer,
    boat_lau_1 integer,
    boat_slips integer,
    bocce_cour integer,
    bowling_gr integer,
    casting_pi integer,
    chess_pavi integer,
    football_s integer,
    community_ integer,
    conservato integer,
    cultural_c integer,
    dog_friend integer,
    fitness_ce integer,
    fitness_co integer,
    gallery integer,
    garden integer,
    golf_cours integer,
    golf_drivi integer,
    golf_putti integer,
    gymnasium integer,
    gymnastic_ integer,
    handball_r integer,
    handball_1 character varying(254),
    horseshoe_ integer,
    iceskating integer,
    pool_indoo integer,
    baseball_j integer,
    mountain_b integer,
    nature_cen integer,
    pool_outdo integer,
    pavillion integer,
    zoo integer,
    playground integer,
    playgrou_1 integer,
    rowing_clu integer,
    volleyball integer,
    senior_cen integer,
    shuffleboa integer,
    skate_park integer,
    sled_hill integer,
    sport_roll integer,
    spray_feat integer,
    baseball_s integer,
    tennis_cou integer,
    track integer,
    volleyba_1 integer,
    water_play integer,
    water_slid integer,
    boxing_cen integer,
    wetland_ar integer,
    lagoon integer,
    carousel character varying(254),
    croquet character varying(254),
    golf_cou_1 character varying(254),
    harbor character varying(254),
    model_trai character varying(254),
    model_yach character varying(254),
    nature_bir character varying(254),
    cricket_fi integer,
    the_geom public.geometry(MultiPolygon,3435),
    geom_rotated public.geometry(MultiPolygon,3435),
    isometric public.geometry(MultiPolygon,3435)
);


--
-- Name: parks_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE parks_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parks_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE parks_gid_seq OWNED BY parks.gid;


--
-- Name: parks_public_art; Type: TABLE; Schema: environment; Owner: -; Tablespace: 
--

CREATE TABLE parks_public_art (
    park character varying(100),
    park_num integer,
    art character varying(200),
    artist character varying(200),
    owner character varying(200),
    x double precision,
    y double precision,
    lat double precision,
    lon double precision,
    location character varying(200)
);


--
-- Name: trails_gid_seq; Type: SEQUENCE; Schema: environment; Owner: -
--

CREATE SEQUENCE trails_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trails_gid_seq; Type: SEQUENCE OWNED BY; Schema: environment; Owner: -
--

ALTER SEQUENCE trails_gid_seq OWNED BY forest_preserve_trails.gid;


SET search_path = health, pg_catalog;

--
-- Name: asthma_hospitalizations; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE asthma_hospitalizations (
    zip character varying(50),
    cases_2000 integer,
    cr_2000 numeric(4,1),
    cr_2000_lci numeric(4,1),
    cr_2000_uci numeric(4,1),
    ar_2000 numeric(4,1),
    ar_2000_lci numeric(4,1),
    ar_2000_uci numeric(4,1),
    num_2001 integer,
    crude_rate_2001 numeric(4,1),
    crude_rate_2001_lower_ci numeric(4,1),
    crude_rate_2001_upper_ci numeric(4,1),
    adjusted_rate_2001 numeric(4,1),
    adjusted_rate_lower_ci numeric(4,1),
    adjusted_rate_upper_ci_2001 numeric(4,1),
    cases_2002 integer,
    crude_rate_2002 numeric(4,1),
    cr_2002_lci numeric(4,1),
    cr_2002_uci numeric(4,1),
    ar_2002 numeric(4,1),
    ar_2002_lci numeric(4,1),
    ar_2002_uci numeric(4,1),
    cases_2003 integer,
    cr_2003 numeric(4,1),
    cr_2003_lci numeric(4,1),
    cr_2003_uci numeric(4,1),
    ar_2003 numeric(4,1),
    ar_2003_lci numeric(4,1),
    ar_2003_uci numeric(4,1),
    cases_2004 integer,
    cr_2004 numeric(4,1),
    cr_2004_lci numeric(4,1),
    cr_2004_uci numeric(4,1),
    ar_2004 numeric(4,1),
    ar_2004_lci numeric(4,1),
    ar_2004_uci numeric(4,1),
    cases_2005 integer,
    cr_2005 numeric(4,1),
    cr_2005_lci numeric(4,1),
    cr_2005_uci numeric(4,1),
    ar_2005 numeric(4,1),
    ar_2005_lci numeric(4,1),
    ar_2005_uci numeric(4,1),
    cases_2006 integer,
    cr_2006 numeric(4,1),
    cr_2006_lci numeric(4,1),
    cr_2006_uci numeric(4,1),
    ar_2006 numeric(4,1),
    ar_2006_lci numeric(4,1),
    ar_2006_uci numeric(4,1),
    cases_2007 integer,
    cr_2007 numeric(4,1),
    cr_2007_lci numeric(4,1),
    cr_2007_uci numeric(4,1),
    ar_2007 numeric(4,1),
    ar_2007_lci numeric(4,1),
    ar_2007_uci numeric(4,1),
    cases_2008 integer,
    cr_2008 numeric(4,1),
    cr_2008_lci numeric(4,1),
    cr_2008_uci numeric(4,1),
    ar_2008 numeric(4,1),
    ar_2008_lci numeric(4,1),
    ar_2008_uci numeric(4,1),
    cases_2009 integer,
    cr_2009 numeric(4,1),
    cr_2009_lci numeric(4,1),
    cr_2009_uci numeric(4,1),
    ar_2009 numeric(4,1),
    ar_2009_lci numeric(4,1),
    ar_2009_uci numeric(4,1),
    cases_2010 integer,
    cr_2010 numeric(4,1),
    cr_2010_lci numeric(4,1),
    cr_2010_uci numeric(4,1),
    ar_2010 numeric(4,1),
    ar_2010_lci numeric(4,1),
    ar_2010_uci numeric(4,1)
);


--
-- Name: chlamydia_females_15_44; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE chlamydia_females_15_44 (
    ca_num integer NOT NULL,
    ca character varying(50),
    cases_2000 integer,
    rate_2000 numeric(5,1),
    rate_2000_lower_ci numeric(5,1),
    rate_2000_upper_ci numeric(5,1),
    cases_2001 integer,
    rate_2001 numeric(5,1),
    rate_2001_lower_ci numeric(5,1),
    rate_2001_upper_ci numeric(5,1),
    cases_2002 integer,
    rate_2002 numeric(5,1),
    rate_2002_lower_ci numeric(5,1),
    rate_2002_upper_ci numeric(5,1),
    cases_2003 integer,
    rate_2003 numeric(5,1),
    rate_2003_lower_ci numeric(5,1),
    rate_2003_upper_ci numeric(5,1),
    cases_2004 integer,
    rate_2004 numeric(5,1),
    rate_2004_lower_ci numeric(5,1),
    rate_2004_upper_ci numeric(5,1),
    cases_2005 integer,
    rate_2005 numeric(5,1),
    rate_2005_lower_ci numeric(5,1),
    rate_2005_upper_ci numeric(5,1),
    cases_2006 integer,
    rate_2006 numeric(5,1),
    rate_2006_lower_ci numeric(5,1),
    rate_2006_upper_ci numeric(5,1),
    cases_2007 integer,
    rate_2007 numeric(5,1),
    rate_2007_lower_ci numeric(5,1),
    rate_2007_upper_ci numeric(6,1),
    cases_2008 integer,
    rate_2008 numeric(5,1),
    rate_2008_lower_ci numeric(5,1),
    rate_2008_upper_ci numeric(6,1),
    cases_2009 integer,
    rate_2009 numeric(5,1),
    rate_2009_lower_ci numeric(5,1),
    rate_2009_upper_ci numeric(6,1),
    cases_2010 integer,
    rate_2010 numeric(5,1),
    rate_2010_lower_ci numeric(5,1),
    rate_2010_upper_ci numeric(6,1),
    warning character varying(255)
);


--
-- Name: condom_distribution_sites; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE condom_distribution_sites (
    venue_type character varying(100),
    name character varying(75),
    address character varying(100),
    city character varying(15),
    state character(2),
    zip character varying(10),
    str_num character varying(10),
    str_dir character varying(50),
    str_name character varying(50),
    str_typ character varying(50),
    id integer NOT NULL,
    bldg_gid integer
);


--
-- Name: condoms2_id_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE condoms2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: condoms2_id_seq; Type: SEQUENCE OWNED BY; Schema: health; Owner: -
--

ALTER SEQUENCE condoms2_id_seq OWNED BY condom_distribution_sites.id;


--
-- Name: deaths; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE deaths (
    cause character varying(200),
    ca_num integer,
    ca character varying(50),
    cumulative_deaths_2004_2008 integer,
    cumulative_deaths_rank integer,
    avg_annual_deaths_2004_2008 integer,
    avg_crude_rate_2004_2008 numeric(6,1),
    crude_rate_lower_ci numeric(6,1),
    crude_rate_upper_ci numeric(6,1),
    crude_rate_rank integer,
    avg_adjusted_rate_2004_2008 numeric(6,1),
    adjusted_rate_lower_ci numeric(6,1),
    adjusted_rate_upper_ci numeric(6,1),
    adjusted_rate_rank integer,
    avg_annual_ypll_2004_2008 integer,
    ypll_rate_rank integer,
    warning character varying(255)
);


--
-- Name: dentists; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE dentists (
    admin character varying(200),
    facility character varying(200),
    category character varying(100),
    address character varying(200),
    county character varying(50),
    email character varying(200),
    eqpt_register_date timestamp without time zone,
    eqpt_app_class character varying(200),
    eqpt_mfgtr character varying(200),
    eqpt_model_num character varying(100),
    eqpt_serial_num character varying(100),
    lso_name character varying(100),
    eqpt_acquire_date timestamp without time zone,
    trim_address character varying(200),
    the_geom public.geometry(Point,3435),
    lon character varying(50),
    lat character varying(50),
    bldg_gid integer,
    id integer NOT NULL,
    str_num character varying(20),
    str_name character varying(100),
    str_type character varying(50),
    str_dir character(1),
    full_address character varying(100)
);


--
-- Name: dentists_id_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE dentists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dentists_id_seq; Type: SEQUENCE OWNED BY; Schema: health; Owner: -
--

ALTER SEQUENCE dentists_id_seq OWNED BY dentists.id;


--
-- Name: diabetes_hospitalizations; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE diabetes_hospitalizations (
    zip character varying(50),
    num_2001 integer,
    crude_rate_2001 numeric(4,1),
    crude_rate_2001_lower_ci numeric(4,1),
    crude_rate_2001_upper_ci numeric(4,1),
    adjusted_rate_2001 numeric(4,1),
    adjusted_rate_lower_ci numeric(4,1),
    adjusted_rate_upper_ci_2001 numeric(4,1),
    cases_2002 integer,
    crude_rate_2002 numeric(4,1),
    cr_2002_lci numeric(4,1),
    cr_2002_uci numeric(4,1),
    ar_2002 numeric(4,1),
    ar_2002_lci numeric(4,1),
    ar_2002_uci numeric(4,1),
    cases_2003 integer,
    cr_2003 numeric(4,1),
    cr_2003_lci numeric(4,1),
    cr_2003_uci numeric(4,1),
    ar_2003 numeric(4,1),
    ar_2003_lci numeric(4,1),
    ar_2003_uci numeric(4,1),
    cases_2004 integer,
    cr_2004 numeric(4,1),
    cr_2004_lci numeric(4,1),
    cr_2004_uci numeric(4,1),
    ar_2004 numeric(4,1),
    ar_2004_lci numeric(4,1),
    ar_2004_uci numeric(4,1),
    cases_2005 integer,
    cr_2005 numeric(4,1),
    cr_2005_lci numeric(4,1),
    cr_2005_uci numeric(4,1),
    ar_2005 numeric(4,1),
    ar_2005_lci numeric(4,1),
    ar_2005_uci numeric(4,1),
    cases_2006 integer,
    cr_2006 numeric(4,1),
    cr_2006_lci numeric(4,1),
    cr_2006_uci numeric(4,1),
    ar_2006 numeric(4,1),
    ar_2006_lci numeric(4,1),
    ar_2006_uci numeric(4,1),
    cases_2007 integer,
    cr_2007 numeric(4,1),
    cr_2007_lci numeric(4,1),
    cr_2007_uci numeric(4,1),
    ar_2007 numeric(4,1),
    ar_2007_lci numeric(4,1),
    ar_2007_uci numeric(4,1),
    cases_2008 integer,
    cr_2008 numeric(4,1),
    cr_2008_lci numeric(4,1),
    cr_2008_uci numeric(4,1),
    ar_2008 numeric(4,1),
    ar_2008_lci numeric(4,1),
    ar_2008_uci numeric(4,1),
    cases_2009 integer,
    cr_2009 numeric(4,1),
    cr_2009_lci numeric(4,1),
    cr_2009_uci numeric(4,1),
    ar_2009 numeric(4,1),
    ar_2009_lci numeric(4,1),
    ar_2009_uci numeric(4,1),
    cases_2010 integer,
    cr_2010 numeric(4,1),
    cr_2010_lci numeric(4,1),
    cr_2010_uci numeric(4,1),
    ar_2010 numeric(4,1),
    ar_2010_lci numeric(4,1),
    ar_2010_uci numeric(4,1)
);


--
-- Name: facilities_master; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE facilities_master (
    original_dataset text,
    operated_by text,
    dataset_description text,
    program character varying(200),
    site_name character varying(200),
    hours character varying(200),
    phone character varying(50),
    location text,
    fax character varying(50),
    fax2 character varying(50),
    phone2 character varying(50),
    phone3 character varying(50),
    phone4 character varying(50),
    phone5 character varying(50),
    admin character varying(200),
    county character varying(50),
    email character varying(100),
    category character varying(100),
    website character varying(100),
    additional_info text,
    additional_info2 text
);


--
-- Name: food_inspection; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE food_inspection (
    insp_id character varying(10),
    dba character varying(100),
    aka_name character varying(100),
    license_num character varying(12),
    facility_type character varying(100),
    risk character varying(20),
    address character varying(75),
    city character varying(20),
    state character varying(2),
    zip character varying(10),
    insp_date date,
    insp_type character varying(100),
    results character varying(35),
    violations text,
    x_coord double precision,
    y_coord double precision,
    latitude double precision,
    longitude double precision,
    id integer NOT NULL,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: food_inspection_id_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE food_inspection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: food_inspection_id_seq; Type: SEQUENCE OWNED BY; Schema: health; Owner: -
--

ALTER SEQUENCE food_inspection_id_seq OWNED BY food_inspection.id;


--
-- Name: gonorrhea_females_15_44; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE gonorrhea_females_15_44 (
    ca_num integer NOT NULL,
    ca character varying(50),
    cases_2000 integer,
    rate_2000 numeric(5,1),
    rate_2000_lower_ci numeric(5,1),
    rate_2000_upper_ci numeric(5,1),
    cases_2001 integer,
    rate_2001 numeric(5,1),
    rate_2001_lower_ci numeric(5,1),
    rate_2001_upper_ci numeric(5,1),
    cases_2002 integer,
    rate_2002 numeric(5,1),
    rate_2002_lower_ci numeric(5,1),
    rate_2002_upper_ci numeric(5,1),
    cases_2003 integer,
    rate_2003 numeric(5,1),
    rate_2003_lower_ci numeric(5,1),
    rate_2003_upper_ci numeric(5,1),
    cases_2004 integer,
    rate_2004 numeric(5,1),
    rate_2004_lower_ci numeric(5,1),
    rate_2004_upper_ci numeric(5,1),
    cases_2005 integer,
    rate_2005 numeric(5,1),
    rate_2005_lower_ci numeric(5,1),
    rate_2005_upper_ci numeric(5,1),
    cases_2006 integer,
    rate_2006 numeric(5,1),
    rate_2006_lower_ci numeric(5,1),
    rate_2006_upper_ci numeric(5,1),
    cases_2007 integer,
    rate_2007 numeric(5,1),
    rate_2007_lower_ci numeric(5,1),
    rate_2007_upper_ci numeric(5,1),
    cases_2008 integer,
    rate_2008 numeric(5,1),
    rate_2008_lower_ci numeric(5,1),
    rate_2008_upper_ci numeric(5,1),
    cases_2009 integer,
    rate_2009 numeric(5,1),
    rate_2009_lower_ci numeric(5,1),
    rate_2009_upper_ci numeric(5,1),
    cases_2010 integer,
    rate_2010 numeric(5,1),
    rate_2010_lower_ci numeric(5,1),
    rate_2010_upper_ci numeric(5,1),
    warning character varying(255)
);


--
-- Name: gonorrhea_males_15_44; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE gonorrhea_males_15_44 (
    ca_num integer NOT NULL,
    ca character varying(50),
    cases_2000 integer,
    rate_2000 numeric(5,1),
    rate_2000_lower_ci numeric(5,1),
    rate_2000_upper_ci numeric(5,1),
    cases_2001 integer,
    rate_2001 numeric(5,1),
    rate_2001_lower_ci numeric(5,1),
    rate_2001_upper_ci numeric(5,1),
    cases_2002 integer,
    rate_2002 numeric(5,1),
    rate_2002_lower_ci numeric(5,1),
    rate_2002_upper_ci numeric(5,1),
    cases_2003 integer,
    rate_2003 numeric(5,1),
    rate_2003_lower_ci numeric(5,1),
    rate_2003_upper_ci numeric(5,1),
    cases_2004 integer,
    rate_2004 numeric(5,1),
    rate_2004_lower_ci numeric(5,1),
    rate_2004_upper_ci numeric(5,1),
    cases_2005 integer,
    rate_2005 numeric(5,1),
    rate_2005_lower_ci numeric(5,1),
    rate_2005_upper_ci numeric(5,1),
    cases_2006 integer,
    rate_2006 numeric(5,1),
    rate_2006_lower_ci numeric(5,1),
    rate_2006_upper_ci numeric(5,1),
    cases_2007 integer,
    rate_2007 numeric(5,1),
    rate_2007_lower_ci numeric(5,1),
    rate_2007_upper_ci numeric(5,1),
    cases_2008 integer,
    rate_2008 numeric(5,1),
    rate_2008_lower_ci numeric(5,1),
    rate_2008_upper_ci numeric(5,1),
    cases_2009 integer,
    rate_2009 numeric(5,1),
    rate_2009_lower_ci numeric(5,1),
    rate_2009_upper_ci numeric(5,1),
    cases_2010 integer,
    rate_2010 numeric(5,1),
    rate_2010_lower_ci numeric(5,1),
    rate_2010_upper_ci numeric(5,1),
    warning character varying(255)
);


--
-- Name: hospitals; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE hospitals (
    gid integer NOT NULL,
    facility character varying(254),
    city character varying(254),
    address character varying(254),
    type1 character varying(254),
    parentorg character varying(254),
    zip character varying(5),
    type2 character varying(50),
    bldg_gid integer
);


--
-- Name: hosp_gid_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE hosp_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hosp_gid_seq; Type: SEQUENCE OWNED BY; Schema: health; Owner: -
--

ALTER SEQUENCE hosp_gid_seq OWNED BY hospitals.gid;


--
-- Name: infant_mortality; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE infant_mortality (
    ca_num integer NOT NULL,
    ca character varying(50),
    deaths_2004 integer,
    deaths_2005 integer,
    deaths_2006 integer,
    deaths_2007 integer,
    deaths_2008 integer,
    cumulative_deaths_2004_2008 integer,
    avg_annual_deaths_2004_2008 integer,
    avg_rate_2004_2008 numeric(3,1),
    rate_lower_ci numeric(3,1),
    rate_upper_ci numeric(3,1),
    warning character varying(255)
);


--
-- Name: lead_screening_children; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE lead_screening_children (
    ca_num integer,
    ca character varying(50),
    screened_1999 integer,
    rate_1999 numeric(4,1),
    rate_1999_lower_ci numeric(4,1),
    rate_1999_upper_ci numeric(4,1),
    elevated_1999 integer,
    pct_elevated_1999 numeric(3,1),
    pct_elevated_1999_lower_ci numeric(3,1),
    pct_elevated_1999_upper_ci numeric(3,1),
    screened_2000 integer,
    rate_2000 numeric(4,1),
    rate_2000_lower_ci numeric(4,1),
    rate_2000_upper_ci numeric(4,1),
    elevated_2000 integer,
    pct_elevated_2000 numeric(3,1),
    pct_elevated_2000_lower_ci numeric(3,1),
    pct_elevated_2000_upper_ci numeric(3,1),
    screened_2001 integer,
    rate_2001 numeric(4,1),
    rate_2001_lower_ci numeric(4,1),
    rate_2001_upper_ci numeric(4,1),
    elevated_2001 integer,
    pct_elevated_2001 numeric(3,1),
    pct_elevated_2001_lower_ci numeric(3,1),
    pct_elevated_2001_upper_ci numeric(3,1),
    screened_2002 integer,
    rate_2002 numeric(4,1),
    rate_2002_lower_ci numeric(4,1),
    rate_2002_upper_ci numeric(4,1),
    elevated_2002 integer,
    pct_elevated_2002 numeric(3,1),
    pct_elevated_2002_lower_ci numeric(3,1),
    pct_elevated_2002_upper_ci numeric(3,1),
    screened_2003 integer,
    rate_2003 numeric(4,1),
    rate_2003_lower_ci numeric(4,1),
    rate_2003_upper_ci numeric(4,1),
    elevated_2003 integer,
    pct_elevated_2003 numeric(3,1),
    pct_elevated_2003_lower_ci numeric(3,1),
    pct_elevated_2003_upper_ci numeric(3,1),
    screened_2004 integer,
    rate_2004 numeric(4,1),
    rate_2004_lower_ci numeric(4,1),
    rate_2004_upper_ci numeric(4,1),
    elevated_2004 integer,
    pct_elevated_2004 numeric(3,1),
    pct_elevated_2004_lower_ci numeric(3,1),
    pct_elevated_2004_upper_ci numeric(3,1),
    screened_2005 integer,
    rate_2005 numeric(4,1),
    rate_2005_lower_ci numeric(4,1),
    rate_2005_upper_ci numeric(4,1),
    elevated_2005 integer,
    pct_elevated_2005 numeric(3,1),
    pct_elevated_2005_lower_ci numeric(3,1),
    pct_elevated_2005_upper_ci numeric(3,1),
    screened_2006 integer,
    rate_2006 numeric(4,1),
    rate_2006_lower_ci numeric(4,1),
    rate_2006_upper_ci numeric(4,1),
    elevated_2006 integer,
    pct_elevated_2006 numeric(3,1),
    pct_elevated_2006_lower_ci numeric(3,1),
    pct_elevated_2006_upper_ci numeric(3,1),
    screened_2007 integer,
    rate_2007 numeric(4,1),
    rate_2007_lower_ci numeric(4,1),
    rate_2007_upper_ci numeric(4,1),
    elevated_2007 integer,
    pct_elevated_2007 numeric(3,1),
    pct_elevated_2007_lower_ci numeric(3,1),
    pct_elevated_2007_upper_ci numeric,
    screened_2008 integer,
    rate_2008 numeric(4,1),
    rate_2008_lower_ci numeric(4,1),
    rate_2008_upper_ci numeric(4,1),
    elevated_2008 integer,
    pct_elevated_2008 numeric(3,1),
    pct_elevated_2008_lower_ci numeric(3,1),
    pct_elevated_2008_upper_ci numeric(3,1),
    screened_2009 integer,
    rate_2009 numeric(4,1),
    rate_2009_lower_ci numeric(4,1),
    rate_2009_upper_ci numeric(4,1),
    elevated_2009 integer,
    pct_elevated_2009 numeric(3,1),
    pct_elevated_2009_lower_ci numeric(3,1),
    pct_elevated_2009_upper_ci numeric(3,1),
    screened_2010 integer,
    rate_2010 numeric(4,1),
    rate_2010_lower_ci numeric(4,1),
    rate_2010_upper_ci numeric(4,1),
    elevated_2010 integer,
    pct_elevated numeric(3,1),
    pct_elevated_lower_ci numeric(3,1),
    pct_elevated_upper_ci numeric(3,1)
);


--
-- Name: low_birth_weight; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE low_birth_weight (
    ca_num integer NOT NULL,
    ca character varying(50),
    births_1999 integer,
    pct_1999 numeric(4,1),
    pct_1999_lower_ci numeric(4,1),
    pct_1999_upper_ci numeric(4,1),
    births_2000 integer,
    pct_2000 numeric(4,1),
    pct_2000_lower_ci numeric(4,1),
    pct_2000_upper_ci numeric(4,1),
    births_2001 integer,
    pct_2001 numeric(4,1),
    pct_2001_lower_ci numeric(4,1),
    pct_2001_upper_ci numeric(4,1),
    births_2002 integer,
    pct_2002 numeric(4,1),
    pct_2002_lower_ci numeric(4,1),
    pct_2002_upper_ci numeric(4,1),
    births_2003 integer,
    pct_2003 numeric(4,1),
    pct_2003_lower_ci numeric(4,1),
    pct_2003_upper_ci numeric(4,1),
    births_2004 integer,
    pct_2004 numeric(4,1),
    pct_2004_lower_ci numeric(4,1),
    pct_2004_upper_ci numeric(4,1),
    births_2005 integer,
    pct_2005 numeric(4,1),
    pct_2005_lower_ci numeric(4,1),
    pct_2005_upper_ci numeric(4,1),
    births_2006 integer,
    pct_2006 numeric(4,1),
    pct_2006_lower_ci numeric(4,1),
    pct_2006_upper_ci numeric(4,1),
    births_2007 integer,
    pct_2007 numeric(4,1),
    pct_2007_lower_ci numeric(4,1),
    pct_2007_upper_ci numeric(4,1),
    births_2008 integer,
    pct_2008 numeric(4,1),
    pct_2008_lower_ci numeric(4,1),
    pct_2008_upper_ci numeric(4,1),
    births_2009 integer,
    pct_2009 numeric(4,1),
    pct_2009_lower_ci numeric(4,1),
    pct_2009_upper_ci numeric(4,1),
    warning character varying(255)
);


--
-- Name: mental_health_clinics_id_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE mental_health_clinics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mental_health_clinics; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE mental_health_clinics (
    name character varying(100),
    hours text,
    address character varying(100),
    city character varying(7),
    zip character varying(5),
    phone character varying(15),
    id integer DEFAULT nextval('mental_health_clinics_id_seq'::regclass) NOT NULL,
    bldg_gid integer
);


--
-- Name: neighborhood_health_clinics_id_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE neighborhood_health_clinics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: neighborhood_health_clinics; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE neighborhood_health_clinics (
    name character varying(75),
    hours text,
    address character varying(100),
    city character varying(7),
    state character varying(2),
    phone character varying(15),
    website text,
    id integer DEFAULT nextval('neighborhood_health_clinics_id_seq'::regclass) NOT NULL,
    adult boolean NOT NULL,
    children boolean NOT NULL,
    family_case_mgmt boolean NOT NULL,
    immigration_physical boolean NOT NULL,
    medication_assistance boolean NOT NULL,
    pregnancy_testing boolean NOT NULL,
    pregnant_women boolean NOT NULL,
    refugee boolean NOT NULL,
    women_seeking_birth_control boolean NOT NULL,
    bldg_gid integer
);


--
-- Name: outpatient_registrations_by_zip_by_month_by_hospital; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE outpatient_registrations_by_zip_by_month_by_hospital (
    facility character varying(100),
    zip character varying(5),
    "dec" integer,
    jan integer,
    feb integer,
    mar integer,
    apr integer,
    may integer,
    jun integer,
    jul integer,
    aug integer,
    sep integer,
    oct integer,
    nov integer,
    total integer,
    id integer NOT NULL
);


--
-- Name: outpatient_registrations_by_zip_by_month_by_hospital_id_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE outpatient_registrations_by_zip_by_month_by_hospital_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outpatient_registrations_by_zip_by_month_by_hospital_id_seq; Type: SEQUENCE OWNED BY; Schema: health; Owner: -
--

ALTER SEQUENCE outpatient_registrations_by_zip_by_month_by_hospital_id_seq OWNED BY outpatient_registrations_by_zip_by_month_by_hospital.id;


--
-- Name: pre_term_births; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE pre_term_births (
    ca_num integer NOT NULL,
    ca character varying(50),
    pre_term_births_1999 integer,
    pct_1999 numeric(4,1),
    pct_1999_lower_ci numeric(4,1),
    pct_1999_upper_ci numeric(4,1),
    pre_term_births_2000 integer,
    pct_2000 numeric(4,1),
    pct_2000_lower_ci numeric(4,1),
    pct_2000_upper_ci numeric(4,1),
    pre_term_births_2001 integer,
    pct_2001 numeric(4,1),
    pct_2001_lower_ci numeric(4,1),
    pct_2001_upper_ci numeric(4,1),
    pre_term_births_2002 integer,
    pct_2002 numeric(4,1),
    pct_2002_lower_ci numeric(4,1),
    pct_2002_upper_ci numeric(4,1),
    pre_term_births_2003 integer,
    pct_2003 numeric(4,1),
    pct_2003_lower_ci numeric(4,1),
    pct_2003_upper_ci numeric(4,1),
    pre_term_births_2004 integer,
    pct_2004 numeric(4,1),
    pct_2004_lower_ci numeric(4,1),
    pct_2004_upper_ci numeric(4,1),
    pre_term_births_2005 integer,
    pct_2005 numeric(4,1),
    pct_2005_lower_ci numeric(4,1),
    pct_2005_upper_ci numeric(4,1),
    pre_term_births_2006 integer,
    pct_2006 numeric(4,1),
    pct_2006_lower_ci numeric(4,1),
    pct_2006_upper_ci numeric(4,1),
    pre_term_births_2007 integer,
    pct_2007 numeric(4,1),
    pct_2007_lower_ci numeric(4,1),
    pct_2007_upper_ci numeric(4,1),
    pre_term_births_2008 integer,
    pct_2008 numeric(4,1),
    pct_2008_lower_ci numeric(4,1),
    pct_2008_upper_ci numeric(4,1),
    pre_term_births_2009 integer,
    pct_2009 numeric(4,1),
    pct_2009_lower_ci numeric(4,1),
    pct_2009_upper_ci numeric(4,1),
    warning character varying(255)
);


--
-- Name: prenatal_care; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE prenatal_care (
    ca_num integer,
    ca character varying(50),
    trimester_prenatal_care_began character varying(50),
    births_1999 integer,
    pct_1999 numeric(4,1),
    pct_1999_lower_ci numeric(4,1),
    pct_1999_upper_ci numeric(4,1),
    births_2000 integer,
    pct_2000 numeric(4,1),
    pct_2000_lower_ci numeric(4,1),
    pct_2000_upper_ci numeric(4,1),
    births_2001 integer,
    pct_2001 numeric(4,1),
    pct_2001_lower_ci numeric(4,1),
    pct_2001_upper_ci numeric(4,1),
    births_2002 integer,
    pct_2002 numeric(4,1),
    pct_2002_lower_ci numeric(4,1),
    pct_2002_upper_ci numeric(4,1),
    births_2003 integer,
    pct_2003 numeric(4,1),
    pct_2003_lower_ci numeric(4,1),
    pct_2003_upper_ci numeric(4,1),
    births_2004 integer,
    pct_2004 numeric(4,1),
    pct_2004_lower_ci numeric(4,1),
    pct_2004_upper_ci numeric(4,1),
    births_2005 integer,
    pct_2005 numeric(4,1),
    pct_2005_lower_ci numeric(4,1),
    pct_2005_upper_ci numeric(4,1),
    births_2006 integer,
    pct_2006 numeric(4,1),
    pct_2006_lower_ci numeric(4,1),
    pct_2006_upper_ci numeric(4,1),
    births_2007 integer,
    pct_2007 numeric(4,1),
    pct_2007_lower_ci numeric(4,1),
    pct_2007_upper_ci numeric(4,1),
    births_2008 integer,
    pct_2008 numeric(4,1),
    pct_2008_lower_ci numeric(4,1),
    pct_2008_upper_ci numeric(4,1),
    births_2009 integer,
    pct_2009 numeric(4,1),
    pct_2009_lower_ci numeric(4,1),
    pct_2009_upper_ci numeric(4,1),
    warning character varying(255)
);


--
-- Name: sti_specialty_clinics_id_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE sti_specialty_clinics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sti_specialty_clinics; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE sti_specialty_clinics (
    name character varying(75),
    hours text,
    address character varying(100),
    phone character varying(15),
    fax character varying(15),
    id integer DEFAULT nextval('sti_specialty_clinics_id_seq'::regclass) NOT NULL,
    bldg_gid integer
);


--
-- Name: tuberculosis; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE tuberculosis (
    ca_num integer NOT NULL,
    ca character varying(50),
    cases_2006 integer,
    cases_2007 integer,
    cases_2008 integer,
    cases_2009 integer,
    cases_2010 integer,
    cases_2006_2010 integer,
    avg_annual_rate_2006_2010 numeric(3,1),
    rate_lower_ci numeric(3,1),
    rate_upper_ci numeric(3,1),
    warning character varying(255)
);


--
-- Name: wic_offices; Type: TABLE; Schema: health; Owner: -; Tablespace: 
--

CREATE TABLE wic_offices (
    name character varying(100),
    hours text,
    address character varying(100),
    phone1 character varying(30),
    fax1 character varying(20),
    id integer,
    bldg_gid integer
);


--
-- Name: wic_offices_seq; Type: SEQUENCE; Schema: health; Owner: -
--

CREATE SEQUENCE wic_offices_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET search_path = history, pg_catalog;

--
-- Name: historic_districts; Type: TABLE; Schema: history; Owner: -; Tablespace: 
--

CREATE TABLE historic_districts (
    gid integer NOT NULL,
    objectid numeric(10,0),
    number character varying(5),
    name character varying(36),
    date date,
    register character varying(1),
    landmark character varying(1),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: historic_districtst_gid_seq; Type: SEQUENCE; Schema: history; Owner: -
--

CREATE SEQUENCE historic_districtst_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historic_districtst_gid_seq; Type: SEQUENCE OWNED BY; Schema: history; Owner: -
--

ALTER SEQUENCE historic_districtst_gid_seq OWNED BY historic_districts.gid;


--
-- Name: historic_resources; Type: TABLE; Schema: history; Owner: -; Tablespace: 
--

CREATE TABLE historic_resources (
    gid integer NOT NULL,
    landmark_i numeric,
    landmarkna character varying(100),
    addressdes character varying(200),
    startyear character varying(4),
    endyear character varying(4),
    decade integer,
    yearnotes character varying(150),
    designatio date,
    low_addr numeric(10,0),
    high_addr numeric(10,0),
    direction character varying(1),
    street_nam character varying(35),
    street_typ character varying(8),
    secdir character varying(4),
    color_id numeric(10,0),
    class_id numeric(10,0),
    form_numbe numeric,
    deleted character varying(1),
    the_geom public.geometry(MultiPolygon,3435),
    bldg_gid integer
);


--
-- Name: landmarks; Type: TABLE; Schema: history; Owner: -; Tablespace: 
--

CREATE TABLE landmarks (
    name character varying(200),
    id character varying(20),
    address character varying(200),
    date_built character varying(10),
    architect character varying(200),
    designation_date date,
    lat double precision,
    lon double precision,
    location text,
    bldg_gid integer,
    gid integer NOT NULL,
    str_num character varying(50),
    str_dir character varying(50),
    str_name character varying(50),
    str_type character varying(50),
    full_address character varying(200)
);


--
-- Name: landmarks_no_bldg; Type: TABLE; Schema: history; Owner: -; Tablespace: 
--

CREATE TABLE landmarks_no_bldg (
    name character varying(200),
    id character varying(20),
    address character varying(200),
    date_built character varying(10),
    architect character varying(200),
    designation_date date,
    lat double precision,
    lon double precision,
    location text,
    bldg_gid integer,
    the_geom public.geometry(Point,3435),
    gid integer,
    str_num character varying(50),
    str_dir character varying(50),
    str_name character varying(50),
    str_type character varying(50)
);


--
-- Name: landmarks_updated_gid_seq; Type: SEQUENCE; Schema: history; Owner: -
--

CREATE SEQUENCE landmarks_updated_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landmarks_updated_gid_seq; Type: SEQUENCE OWNED BY; Schema: history; Owner: -
--

ALTER SEQUENCE landmarks_updated_gid_seq OWNED BY landmarks.gid;


--
-- Name: landmarkshistrsrcesurvey_gid_seq; Type: SEQUENCE; Schema: history; Owner: -
--

CREATE SEQUENCE landmarkshistrsrcesurvey_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landmarkshistrsrcesurvey_gid_seq; Type: SEQUENCE OWNED BY; Schema: history; Owner: -
--

ALTER SEQUENCE landmarkshistrsrcesurvey_gid_seq OWNED BY historic_resources.gid;


SET search_path = public, pg_catalog;

--
-- Name: bl_daily; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bl_daily (
    id character varying(50),
    lic_id character varying(20),
    acct_num character varying(25),
    site_num character varying(25),
    legal_name character varying(200),
    dba_name character varying(200),
    address character varying(200),
    city character varying(100),
    state character varying(20),
    zip character varying(20),
    ward character varying(10),
    precinct character varying(10),
    police_district character varying(20),
    lic_code character varying(20),
    lic_desc character varying(200),
    lic_num character varying(25),
    app_type character varying(50),
    pmt_dt character varying(50),
    lic_term_start_dt character varying(50),
    lic_term_expiration_dt character varying(50),
    dt_issued character varying(50),
    lic_status character varying(20),
    lic_status_change_dt character varying(50),
    lat double precision,
    lon double precision,
    location text
);


--
-- Name: bldbound_ssa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW bldbound_ssa AS
    SELECT b.bldg_gid, s.gid FROM (buildings.buildings b JOIN boundaries.special_service_areas s ON (st_intersects(b.the_geom, s.the_geom)));


--
-- Name: bp_daily; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bp_daily (
    id integer,
    permit_num character varying(50),
    permit_type character varying(200),
    issue_date date,
    est_cost character varying(25),
    amt_waived character varying(25),
    amt_paid character varying(25),
    tot_permit_fee character varying(25),
    str_num integer,
    str_dir character(1),
    str_name character varying(75),
    str_typ character varying(10),
    work text,
    pin1 character varying(20),
    pin2 character varying(20),
    pin3 character varying(20),
    pin4 character varying(20),
    pin5 character varying(20),
    pin6 character varying(20),
    pin7 character varying(20),
    pin8 character varying(20),
    pin9 character varying(20),
    pin10 character varying(20),
    con1_type character varying(100),
    con1_name character varying(100),
    con1_address character varying(100),
    con1_city character varying(100),
    con1_state character varying(100),
    con1_zip character varying(100),
    con1_phone character varying(100),
    con2_type character varying(100),
    con2_name character varying(100),
    con2_address character varying(100),
    con2_city character varying(100),
    con2_state character varying(100),
    con2_zip character varying(100),
    con2_phone character varying(100),
    con3_type character varying(100),
    con3_name character varying(100),
    con3_address character varying(100),
    con3_city character varying(100),
    con3_state character varying(100),
    con3_zip character varying(100),
    con3_phone character varying(100),
    con4_type character varying(100),
    con4_name character varying(100),
    con4_address character varying(100),
    con4_city character varying(100),
    con4_state character varying(100),
    con4_zip character varying(100),
    con4_phone character varying(100),
    con5_type character varying(100),
    con5_name character varying(100),
    con5_address character varying(100),
    con5_city character varying(100),
    con5_state character varying(100),
    con5_zip character varying(100),
    con5_phone character varying(100),
    con6_type character varying(100),
    con6_name character varying(100),
    con6_address character varying(100),
    con6_city character varying(100),
    con6_state character varying(100),
    con6_zip character varying(100),
    con6_phone character varying(100),
    con7_type character varying(100),
    con7_name character varying(100),
    con7_address character varying(100),
    con7_city character varying(100),
    con7_state character varying(100),
    con7_zip character varying(100),
    con7_phone character varying(100),
    con8_type character varying(100),
    con8_name character varying(100),
    con8_address character varying(100),
    con8_city character varying(100),
    con8_state character varying(100),
    con8_zip character varying(100),
    con8_phone character varying(100),
    con9_type character varying(100),
    con9_name character varying(100),
    con9_address character varying(100),
    con9_city character varying(100),
    con9_state character varying(100),
    con9_zip character varying(100),
    con9_phone character varying(100),
    con10_type character varying(100),
    con10_name character varying(100),
    con10_address character varying(100),
    con10_city character varying(100),
    con10_state character varying(100),
    con10_zip character varying(100),
    con10_phone character varying(100),
    con11_type character varying(100),
    con11_name character varying(100),
    con11_address character varying(100),
    con11_city character varying(100),
    con11_state character varying(100),
    con11_zip character varying(100),
    con11_phone character varying(100),
    con12_type character varying(100),
    con12_name character varying(100),
    con12_address character varying(100),
    con12_city character varying(100),
    con12_state character varying(100),
    con12_zip character varying(100),
    con12_phone character varying(100),
    con13_type character varying(100),
    con13_name character varying(100),
    con13_address character varying(100),
    con13_city character varying(100),
    con13_state character varying(100),
    con13_zip character varying(100),
    con13_phone character varying(100),
    con14_type character varying(100),
    con14_name character varying(100),
    con14_address character varying(100),
    con14_city character varying(100),
    con14_state character varying(100),
    con14_zip character varying(100),
    con14_phone character varying(100),
    con15_type character varying(100),
    con15_name character varying(100),
    con15_address character varying(100),
    con15_city character varying(100),
    con15_state character varying(100),
    con15_zip character varying(100),
    con15_phone character varying(100),
    lat double precision,
    lon double precision,
    location text
);


--
-- Name: budget_2011_appropriations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE budget_2011_appropriations (
    fund_type character varying(20),
    fund_code character varying(8),
    fund_desc character varying(100),
    dept_num integer,
    dept character varying(100),
    dept_desc character varying(150),
    appropriation_authority integer,
    appropriation_authority_desc character varying(200),
    appropriation_acct integer,
    appropriation_acct_desc character varying(200),
    amount numeric(12,2)
);


--
-- Name: budget_2012_recommendations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE budget_2012_recommendations (
    fund_type character varying(20),
    fund_code character varying(10),
    fund_desc character varying(100),
    dept_num integer,
    dept_desc character varying(100),
    appr_auth integer,
    appr_auth_desc character varying(200),
    appr_acct integer,
    appr_acct_desc character varying(200),
    appr_2011 numeric(12,2),
    appr_rev_2011 numeric(12,2),
    rec_2012 numeric(12,2)
);


--
-- Name: building_penalties; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE building_penalties (
    ordinance_num character varying(50),
    first_min money,
    first_max money,
    second_min money,
    second_max money,
    third_min money,
    third_max money,
    id integer NOT NULL,
    description character varying(100)
);


--
-- Name: building_penalties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE building_penalties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: building_penalties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE building_penalties_id_seq OWNED BY building_penalties.id;


--
-- Name: building_permits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE building_permits (
    id integer,
    permit_num character varying(50),
    permit_type character varying(200),
    issue_date date,
    est_cost character varying(25),
    amt_waived character varying(25),
    amt_paid character varying(25),
    tot_permit_fee character varying(25),
    str_num integer,
    str_dir character(1),
    str_name character varying(75),
    str_typ character varying(10),
    work text,
    pin1 character varying(20),
    pin2 character varying(20),
    pin3 character varying(20),
    pin4 character varying(20),
    pin5 character varying(20),
    pin6 character varying(20),
    pin7 character varying(20),
    pin8 character varying(20),
    pin9 character varying(20),
    pin10 character varying(20),
    con1_type character varying(100),
    con1_name character varying(100),
    con1_address character varying(100),
    con1_city character varying(100),
    con1_state character varying(100),
    con1_zip character varying(100),
    con1_phone character varying(100),
    con2_type character varying(100),
    con2_name character varying(100),
    con2_address character varying(100),
    con2_city character varying(100),
    con2_state character varying(100),
    con2_zip character varying(100),
    con2_phone character varying(100),
    con3_type character varying(100),
    con3_name character varying(100),
    con3_address character varying(100),
    con3_city character varying(100),
    con3_state character varying(100),
    con3_zip character varying(100),
    con3_phone character varying(100),
    con4_type character varying(100),
    con4_name character varying(100),
    con4_address character varying(100),
    con4_city character varying(100),
    con4_state character varying(100),
    con4_zip character varying(100),
    con4_phone character varying(100),
    con5_type character varying(100),
    con5_name character varying(100),
    con5_address character varying(100),
    con5_city character varying(100),
    con5_state character varying(100),
    con5_zip character varying(100),
    con5_phone character varying(100),
    con6_type character varying(100),
    con6_name character varying(100),
    con6_address character varying(100),
    con6_city character varying(100),
    con6_state character varying(100),
    con6_zip character varying(100),
    con6_phone character varying(100),
    con7_type character varying(100),
    con7_name character varying(100),
    con7_address character varying(100),
    con7_city character varying(100),
    con7_state character varying(100),
    con7_zip character varying(100),
    con7_phone character varying(100),
    con8_type character varying(100),
    con8_name character varying(100),
    con8_address character varying(100),
    con8_city character varying(100),
    con8_state character varying(100),
    con8_zip character varying(100),
    con8_phone character varying(100),
    con9_type character varying(100),
    con9_name character varying(100),
    con9_address character varying(100),
    con9_city character varying(100),
    con9_state character varying(100),
    con9_zip character varying(100),
    con9_phone character varying(100),
    con10_type character varying(100),
    con10_name character varying(100),
    con10_address character varying(100),
    con10_city character varying(100),
    con10_state character varying(100),
    con10_zip character varying(100),
    con10_phone character varying(100),
    con11_type character varying(100),
    con11_name character varying(100),
    con11_address character varying(100),
    con11_city character varying(100),
    con11_state character varying(100),
    con11_zip character varying(100),
    con11_phone character varying(100),
    con12_type character varying(100),
    con12_name character varying(100),
    con12_address character varying(100),
    con12_city character varying(100),
    con12_state character varying(100),
    con12_zip character varying(100),
    con12_phone character varying(100),
    con13_type character varying(100),
    con13_name character varying(100),
    con13_address character varying(100),
    con13_city character varying(100),
    con13_state character varying(100),
    con13_zip character varying(100),
    con13_phone character varying(100),
    con14_type character varying(100),
    con14_name character varying(100),
    con14_address character varying(100),
    con14_city character varying(100),
    con14_state character varying(100),
    con14_zip character varying(100),
    con14_phone character varying(100),
    con15_type character varying(100),
    con15_name character varying(100),
    con15_address character varying(100),
    con15_city character varying(100),
    con15_state character varying(100),
    con15_zip character varying(100),
    con15_phone character varying(100),
    lat double precision,
    lon double precision,
    location text,
    full_address character varying(200),
    bldg_gid integer
);


--
-- Name: building_permits2_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE building_permits2_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: building_violations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE building_violations (
    id character varying(100) NOT NULL,
    v_last_mod_date date,
    v_date date,
    v_code character varying(100),
    v_status character varying(100),
    v_status_date character varying(100),
    v_desc text,
    v_loc text,
    v_insp_comments text,
    v_ordinance text,
    insp_id character varying(100),
    insp_num character varying(100),
    insp_status character varying(100),
    insp_waived character varying(100),
    insp_cat character varying(100),
    dept character varying(100),
    address character varying(100),
    prop_group character varying(100),
    lat double precision,
    lon double precision,
    location text,
    bldg_gid integer,
    str_num character varying(10),
    str_dir character varying(50),
    str_name character varying(100),
    str_type character varying(50),
    ordinance_num character varying(500)
);


--
-- Name: buildings_propvalue; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE buildings_propvalue (
    bldg_gid integer,
    the_geom geometry(MultiPolygon,3435),
    centroid geometry(Point,3435),
    isometric geometry(MultiPolygon,3435),
    est_value_calc numeric
);


--
-- Name: buildings_tilemill; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE buildings_tilemill (
    bldg_gid integer NOT NULL,
    the_geom geometry(MultiPolygon,3435),
    lat double precision,
    lon double precision,
    stories integer,
    year_built integer,
    sqft integer,
    prop_value money,
    zoning character varying(20),
    landuse character varying(255),
    landuse_shortdesc character varying(100),
    lu_cmap_short character varying(255),
    lu_cmap_long text
);


--
-- Name: buildings_tilemill_geojson; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE buildings_tilemill_geojson (
    bldg_gid integer NOT NULL,
    lat double precision,
    lon double precision,
    stories integer,
    year_built integer,
    sqft integer,
    prop_value money,
    zoning character varying(20),
    geojson text,
    landuse character varying(255),
    landuse_shortdesc character varying(50)
);


--
-- Name: bv_count; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bv_count (
    bldg_gid integer,
    count bigint
);


--
-- Name: bv_daily; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bv_daily (
    id character varying(100),
    v_last_mod_date date,
    v_date date,
    v_code character varying(100),
    v_status character varying(100),
    v_status_date character varying(100),
    v_desc text,
    v_loc text,
    v_insp_comments text,
    v_ordinance text,
    insp_id character varying(100),
    insp_num character varying(100),
    insp_status character varying(100),
    insp_waived character varying(100),
    insp_cat character varying(100),
    dept character varying(100),
    address character varying(100),
    prop_group character varying(100),
    lat double precision,
    lon double precision,
    location text
);


--
-- Name: cbd_permits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cbd_permits (
    id integer,
    permit_num character varying(50),
    permit_type character varying(200),
    issue_date date,
    est_cost character varying(25),
    amt_waived character varying(25),
    amt_paid character varying(25),
    tot_permit_fee character varying(25),
    str_num integer,
    str_dir character(1),
    str_name character varying(75),
    str_typ character varying(10),
    work text,
    pin1 character varying(20),
    pin2 character varying(20),
    pin3 character varying(20),
    pin4 character varying(20),
    pin5 character varying(20),
    pin6 character varying(20),
    pin7 character varying(20),
    pin8 character varying(20),
    pin9 character varying(20),
    pin10 character varying(20),
    con1_type character varying(100),
    con1_name character varying(100),
    con1_address character varying(100),
    con1_city character varying(100),
    con1_state character varying(100),
    con1_zip character varying(100),
    con1_phone character varying(100),
    con2_type character varying(100),
    con2_name character varying(100),
    con2_address character varying(100),
    con2_city character varying(100),
    con2_state character varying(100),
    con2_zip character varying(100),
    con2_phone character varying(100),
    con3_type character varying(100),
    con3_name character varying(100),
    con3_address character varying(100),
    con3_city character varying(100),
    con3_state character varying(100),
    con3_zip character varying(100),
    con3_phone character varying(100),
    con4_type character varying(100),
    con4_name character varying(100),
    con4_address character varying(100),
    con4_city character varying(100),
    con4_state character varying(100),
    con4_zip character varying(100),
    con4_phone character varying(100),
    con5_type character varying(100),
    con5_name character varying(100),
    con5_address character varying(100),
    con5_city character varying(100),
    con5_state character varying(100),
    con5_zip character varying(100),
    con5_phone character varying(100),
    con6_type character varying(100),
    con6_name character varying(100),
    con6_address character varying(100),
    con6_city character varying(100),
    con6_state character varying(100),
    con6_zip character varying(100),
    con6_phone character varying(100),
    con7_type character varying(100),
    con7_name character varying(100),
    con7_address character varying(100),
    con7_city character varying(100),
    con7_state character varying(100),
    con7_zip character varying(100),
    con7_phone character varying(100),
    con8_type character varying(100),
    con8_name character varying(100),
    con8_address character varying(100),
    con8_city character varying(100),
    con8_state character varying(100),
    con8_zip character varying(100),
    con8_phone character varying(100),
    con9_type character varying(100),
    con9_name character varying(100),
    con9_address character varying(100),
    con9_city character varying(100),
    con9_state character varying(100),
    con9_zip character varying(100),
    con9_phone character varying(100),
    con10_type character varying(100),
    con10_name character varying(100),
    con10_address character varying(100),
    con10_city character varying(100),
    con10_state character varying(100),
    con10_zip character varying(100),
    con10_phone character varying(100),
    con11_type character varying(100),
    con11_name character varying(100),
    con11_address character varying(100),
    con11_city character varying(100),
    con11_state character varying(100),
    con11_zip character varying(100),
    con11_phone character varying(100),
    con12_type character varying(100),
    con12_name character varying(100),
    con12_address character varying(100),
    con12_city character varying(100),
    con12_state character varying(100),
    con12_zip character varying(100),
    con12_phone character varying(100),
    con13_type character varying(100),
    con13_name character varying(100),
    con13_address character varying(100),
    con13_city character varying(100),
    con13_state character varying(100),
    con13_zip character varying(100),
    con13_phone character varying(100),
    con14_type character varying(100),
    con14_name character varying(100),
    con14_address character varying(100),
    con14_city character varying(100),
    con14_state character varying(100),
    con14_zip character varying(100),
    con14_phone character varying(100),
    con15_type character varying(100),
    con15_name character varying(100),
    con15_address character varying(100),
    con15_city character varying(100),
    con15_state character varying(100),
    con15_zip character varying(100),
    con15_phone character varying(100),
    lat double precision,
    lon double precision,
    location text,
    full_address character varying(200),
    bldg_gid integer
);


--
-- Name: cbd_violations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cbd_violations (
    id character varying(100),
    v_last_mod_date date,
    v_date date,
    v_code character varying(100),
    v_status character varying(100),
    v_status_date character varying(100),
    v_desc text,
    v_loc text,
    v_insp_comments text,
    v_ordinance text,
    insp_id character varying(100),
    insp_num character varying(100),
    insp_status character varying(100),
    insp_waived character varying(100),
    insp_cat character varying(100),
    dept character varying(100),
    address character varying(100),
    prop_group character varying(100),
    lat double precision,
    lon double precision,
    location text,
    bldg_gid integer,
    str_num character varying(10),
    str_dir character varying(2),
    str_name character varying(100),
    str_type character varying(50)
);


--
-- Name: county_backup; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE county_backup (
    pin character varying(200),
    address character varying(100),
    city character varying(50),
    zip character varying(10),
    township character varying(50),
    assessment_tax_year character varying(200),
    est_value character varying(200),
    assessed_value character varying(200),
    lotsize character varying(200),
    bldg_size character varying(200),
    property_class character varying(200),
    bldg_age character varying(10),
    tax_rate_year character varying(200),
    tax_code_year character varying(200),
    taxcode character varying(10),
    mailing_tax_year character varying(200),
    mailing_name character varying(100),
    mailing_address character varying(250),
    mailing_city_state_zip character varying(250),
    tax_bill_2012 character varying(200),
    tax_bill_2011 character varying(200),
    tax_bill_2010 character varying(200),
    tax_bill_2009 character varying(200),
    tax_bill_2008 character varying(200),
    tax_bill_2007 character varying(200),
    tax_bill_2006 character varying(200),
    tax_rate character varying(10),
    sent_pin character varying(20)
);


--
-- Name: county_bldgtype_override; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE county_bldgtype_override (
    bldg_gid integer
);


--
-- Name: county_donpin; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE county_donpin (
    pin character varying(200),
    address character varying(100),
    city character varying(50),
    zip character varying(10),
    township character varying(50),
    assessment_tax_year character varying(200),
    est_value character varying(200),
    assessed_value character varying(200),
    lotsize character varying(200),
    bldg_size character varying(200),
    property_class character varying(200),
    bldg_age character varying(10),
    tax_rate_year character varying(200),
    tax_code_year character varying(200),
    taxcode character varying(10),
    mailing_tax_year character varying(200),
    mailing_name character varying(100),
    mailing_address character varying(250),
    mailing_city_state_zip character varying(250),
    tax_bill_2012 character varying(200),
    tax_bill_2011 character varying(200),
    tax_bill_2010 character varying(200),
    tax_bill_2009 character varying(200),
    tax_bill_2008 character varying(200),
    tax_bill_2007 character varying(200),
    tax_bill_2006 character varying(200),
    tax_rate character varying(10),
    sent_pin character varying(20),
    bldg_gid integer,
    est_value_calc money,
    str_num character varying(10),
    str_dir character varying(10),
    str_name character varying(75),
    str_typ character varying(50),
    full_address character varying(200),
    the_geom geometry
);


--
-- Name: crimes_2001_2011; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE crimes_2001_2011 (
    case_id integer,
    case_num character varying(20),
    date timestamp without time zone,
    block character varying(50),
    iucr character varying(10),
    primary_type character varying(50),
    description character varying(255),
    loc_desc character varying(255),
    arrest boolean,
    domestic boolean,
    beat character varying(10),
    ward integer,
    fbi_code character varying(8),
    x double precision,
    y double precision,
    updated timestamp without time zone,
    year integer,
    lat double precision,
    lon double precision,
    location text,
    id integer,
    the_geom geometry(Point,3435)
);


--
-- Name: dup_buildings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dup_buildings (
    bldg_gid integer,
    full_address character varying(100),
    the_geom geometry(MultiPolygon,3435)
);


--
-- Name: elementarynetworks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE elementarynetworks (
    gid integer NOT NULL,
    objectid_1 integer,
    network character varying(50),
    collaborat character varying(50),
    address character varying(50),
    phone character varying(50),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_area numeric,
    the_geom geometry(MultiPolygon,3435)
);


--
-- Name: elementarynetworks_gid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE elementarynetworks_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: elementarynetworks_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE elementarynetworks_gid_seq OWNED BY elementarynetworks.gid;


--
-- Name: foreclosures; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE foreclosures (
    pin character varying(20),
    doc_num integer,
    doc_type character varying(100),
    recorded_date date,
    execution_date date,
    consideration_amt money,
    location character varying(200),
    bldg_gid integer,
    lat double precision,
    lon double precision,
    coords character varying(100)
);


--
-- Name: greenroofs2012; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE greenroofs2012 (
    gid integer NOT NULL,
    objectid numeric(10,0),
    id numeric(10,0),
    address character varying(50),
    x_coord numeric(10,0),
    y_coord numeric(10,0),
    latitude numeric,
    longitude numeric,
    house_numb numeric(10,0),
    pre_dir character varying(5),
    street_nam character varying(50),
    street_typ character varying(5),
    full_addre character varying(70),
    building_n character varying(50),
    building_1 character varying(50),
    month_view character varying(25),
    total_roof numeric,
    vegetated_ numeric,
    the_geom geometry(Point,3435)
);


--
-- Name: greenroofs2012_gid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE greenroofs2012_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: greenroofs2012_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE greenroofs2012_gid_seq OWNED BY greenroofs2012.gid;


--
-- Name: highschoolnetworks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE highschoolnetworks (
    gid integer NOT NULL,
    objectid_1 integer,
    network character varying(50),
    collaborat character varying(50),
    address character varying(50),
    phone character varying(50),
    shape_leng numeric,
    shape_le_1 numeric,
    shape_area numeric,
    the_geom geometry(MultiPolygon,3435)
);


--
-- Name: highschoolnetworks_gid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE highschoolnetworks_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: highschoolnetworks_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE highschoolnetworks_gid_seq OWNED BY highschoolnetworks.gid;


--
-- Name: new_const_heatmap; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_const_heatmap (
    gid integer,
    sum numeric(15,2),
    the_geom geometry(MultiPolygon,4326),
    bldg_density numeric,
    area_acres numeric,
    dollars_per_acre money
);


--
-- Name: new_const_permits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_const_permits (
    bldg_gid integer,
    the_geom geometry(MultiPolygon,4326),
    count bigint,
    date date,
    cost money,
    centroid geometry(Point,4326),
    gid integer
);


--
-- Name: new_permits_2006; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_permits_2006 (
    count bigint,
    pri_neigh character varying(50)
);


--
-- Name: new_permits_2007; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_permits_2007 (
    count bigint,
    pri_neigh character varying(50)
);


--
-- Name: new_permits_2008; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_permits_2008 (
    count bigint,
    pri_neigh character varying(50)
);


--
-- Name: new_permits_2009; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_permits_2009 (
    count bigint,
    pri_neigh character varying(50)
);


--
-- Name: new_permits_2010; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_permits_2010 (
    count bigint,
    pri_neigh character varying(50)
);


--
-- Name: new_permits_2011; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE new_permits_2011 (
    count bigint,
    pri_neigh character varying(50)
);


--
-- Name: permits_temp; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE permits_temp (
    id integer,
    permit_num character varying(50),
    permit_type character varying(200),
    issue_date date,
    est_cost character varying(25),
    amt_waived character varying(25),
    amt_paid character varying(25),
    tot_permit_fee character varying(25),
    str_num integer,
    str_dir character(1),
    str_name character varying(75),
    str_typ character varying(10),
    work text,
    pin1 character varying(20),
    pin2 character varying(20),
    pin3 character varying(20),
    pin4 character varying(20),
    pin5 character varying(20),
    pin6 character varying(20),
    pin7 character varying(20),
    pin8 character varying(20),
    pin9 character varying(20),
    pin10 character varying(20),
    con1_type character varying(100),
    con1_name character varying(100),
    con1_address character varying(100),
    con1_city character varying(100),
    con1_state character varying(100),
    con1_zip character varying(100),
    con1_phone character varying(100),
    con2_type character varying(100),
    con2_name character varying(100),
    con2_address character varying(100),
    con2_city character varying(100),
    con2_state character varying(100),
    con2_zip character varying(100),
    con2_phone character varying(100),
    con3_type character varying(100),
    con3_name character varying(100),
    con3_address character varying(100),
    con3_city character varying(100),
    con3_state character varying(100),
    con3_zip character varying(100),
    con3_phone character varying(100),
    con4_type character varying(100),
    con4_name character varying(100),
    con4_address character varying(100),
    con4_city character varying(100),
    con4_state character varying(100),
    con4_zip character varying(100),
    con4_phone character varying(100),
    con5_type character varying(100),
    con5_name character varying(100),
    con5_address character varying(100),
    con5_city character varying(100),
    con5_state character varying(100),
    con5_zip character varying(100),
    con5_phone character varying(100),
    con6_type character varying(100),
    con6_name character varying(100),
    con6_address character varying(100),
    con6_city character varying(100),
    con6_state character varying(100),
    con6_zip character varying(100),
    con6_phone character varying(100),
    con7_type character varying(100),
    con7_name character varying(100),
    con7_address character varying(100),
    con7_city character varying(100),
    con7_state character varying(100),
    con7_zip character varying(100),
    con7_phone character varying(100),
    con8_type character varying(100),
    con8_name character varying(100),
    con8_address character varying(100),
    con8_city character varying(100),
    con8_state character varying(100),
    con8_zip character varying(100),
    con8_phone character varying(100),
    con9_type character varying(100),
    con9_name character varying(100),
    con9_address character varying(100),
    con9_city character varying(100),
    con9_state character varying(100),
    con9_zip character varying(100),
    con9_phone character varying(100),
    con10_type character varying(100),
    con10_name character varying(100),
    con10_address character varying(100),
    con10_city character varying(100),
    con10_state character varying(100),
    con10_zip character varying(100),
    con10_phone character varying(100),
    con11_type character varying(100),
    con11_name character varying(100),
    con11_address character varying(100),
    con11_city character varying(100),
    con11_state character varying(100),
    con11_zip character varying(100),
    con11_phone character varying(100),
    con12_type character varying(100),
    con12_name character varying(100),
    con12_address character varying(100),
    con12_city character varying(100),
    con12_state character varying(100),
    con12_zip character varying(100),
    con12_phone character varying(100),
    con13_type character varying(100),
    con13_name character varying(100),
    con13_address character varying(100),
    con13_city character varying(100),
    con13_state character varying(100),
    con13_zip character varying(100),
    con13_phone character varying(100),
    con14_type character varying(100),
    con14_name character varying(100),
    con14_address character varying(100),
    con14_city character varying(100),
    con14_state character varying(100),
    con14_zip character varying(100),
    con14_phone character varying(100),
    con15_type character varying(100),
    con15_name character varying(100),
    con15_address character varying(100),
    con15_city character varying(100),
    con15_state character varying(100),
    con15_zip character varying(100),
    con15_phone character varying(100),
    lat double precision,
    lon double precision,
    location text,
    full_address character varying(200),
    bldg_gid integer
);


--
-- Name: pins_backup; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pins_backup (
    bldg_gid integer,
    pin character varying(20),
    nodash character varying(20)
);


--
-- Name: pins_master_ass; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pins_master_ass (
    pin character varying(30),
    id integer
);


--
-- Name: pins_tocheck; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pins_tocheck (
    pin character varying(30)
);


--
-- Name: public_housing_hud_scores; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE public_housing_hud_scores (
    prop_id character varying(25),
    prop_name character varying(255),
    address character varying(150),
    city character varying(100),
    cbsa_name character varying(200),
    cbsa_code character varying(50),
    county_name character varying(100),
    county_code character varying(100),
    state_name character varying(50),
    state_code character varying(50),
    zip character varying(10),
    lat double precision,
    lon double precision,
    pha_code character varying(100),
    pha_name character varying(150),
    insp_score numeric(5,2),
    insp_date date
);


--
-- Name: rda_byward_sum; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE rda_byward_sum (
    gid integer NOT NULL,
    ward_1 character varying(254),
    cnt_ward_1 integer
);


--
-- Name: rda_byward_sum_gid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE rda_byward_sum_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rda_byward_sum_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE rda_byward_sum_gid_seq OWNED BY rda_byward_sum.gid;


--
-- Name: renovation_heatmap; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE renovation_heatmap (
    gid integer,
    sum numeric(15,2),
    the_geom geometry(MultiPolygon,4326)
);


--
-- Name: roof_height; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roof_height (
    bldg_gid integer,
    height integer
);


--
-- Name: test_json; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE test_json (
    test json
);


--
-- Name: tif_projectsfinal; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tif_projectsfinal (
    gid integer NOT NULL,
    status character varying(1),
    score smallint,
    side character varying(1),
    x numeric,
    y numeric,
    stan_addr character varying(79),
    ref_id integer,
    pct_along double precision,
    match_addr character varying(63),
    arc_street character varying(60),
    name character varying(35),
    address character varying(30),
    region character varying(15)
);


--
-- Name: tif_projectsfinal_gid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tif_projectsfinal_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tif_projectsfinal_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tif_projectsfinal_gid_seq OWNED BY tif_projectsfinal.gid;


--
-- Name: tifs_unioned; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tifs_unioned (
    st_union geometry(MultiPolygon,3435)
);


--
-- Name: tifs_wards_90pct; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW tifs_wards_90pct AS
    SELECT tifs_in_wards_sig2.ward, tifs_in_wards_sig2.alderman, tifs_in_wards_sig2.tif_ref, tifs_in_wards_sig2.tif_name, tifs_in_wards_sig2.tot_area FROM ward27.tifs_in_wards_significant tifs_in_wards_sig2 WHERE (tifs_in_wards_sig2.tot_area >= (90)::numeric);


--
-- Name: user_address_input; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_address_input (
    gid integer NOT NULL,
    str_num integer,
    str_dir character(1),
    str_name character varying(75),
    str_typ character varying(10),
    str_pos character(1),
    the_geom geometry(Point,3435),
    pin character varying(20)
);


--
-- Name: user_address_input_gid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_address_input_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_address_input_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_address_input_gid_seq OWNED BY user_address_input.gid;


--
-- Name: wards_unioned; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE wards_unioned (
    st_union geometry(MultiPolygon,3435)
);


--
-- Name: wicker_park_free_wifi; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE wicker_park_free_wifi (
    gid integer NOT NULL,
    id character varying(80),
    name character varying(80),
    address character varying(80),
    add_upper character varying(80),
    city character varying(80),
    state character varying(80),
    zip character varying(80),
    rating integer,
    lon double precision,
    lat double precision,
    the_geom geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((geometrytype(the_geom) = 'POINT'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((st_srid(the_geom) = 3435))
);


--
-- Name: wicker_park_free_wifi_gid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wicker_park_free_wifi_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wicker_park_free_wifi_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wicker_park_free_wifi_gid_seq OWNED BY wicker_park_free_wifi.gid;


SET search_path = safety, pg_catalog;

--
-- Name: crimes; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE crimes (
    case_id integer,
    case_num character varying(20),
    date timestamp without time zone,
    block character varying(50),
    iucr character varying(10),
    primary_type character varying(50),
    description character varying(255),
    loc_desc character varying(255),
    arrest boolean,
    domestic boolean,
    beat character varying(10),
    ward integer,
    fbi_code character varying(8),
    x double precision,
    y double precision,
    updated timestamp without time zone,
    year integer,
    lat double precision,
    lon double precision,
    location text,
    id integer NOT NULL,
    the_geom public.geometry(Point,3435)
);


--
-- Name: crimes_2012; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE crimes_2012 (
    case_id integer,
    case_num character varying(20),
    date timestamp without time zone,
    block character varying(50),
    iucr character varying(10),
    primary_type character varying(50),
    description character varying(255),
    loc_desc character varying(255),
    arrest boolean,
    domestic boolean,
    beat character varying(10),
    ward integer,
    fbi_code character varying(8),
    x double precision,
    y double precision,
    updated timestamp without time zone,
    year integer,
    lat double precision,
    lon double precision,
    location text,
    id integer,
    the_geom public.geometry(Point,3435)
);


--
-- Name: crimes_id_seq; Type: SEQUENCE; Schema: safety; Owner: -
--

CREATE SEQUENCE crimes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: crimes_id_seq; Type: SEQUENCE OWNED BY; Schema: safety; Owner: -
--

ALTER SEQUENCE crimes_id_seq OWNED BY crimes.id;


--
-- Name: crimes_in_buildings; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE crimes_in_buildings (
    case_id integer,
    case_num character varying(20),
    date timestamp without time zone,
    block character varying(50),
    iucr character varying(10),
    primary_type character varying(50),
    description character varying(255),
    loc_desc character varying(255),
    arrest boolean,
    domestic boolean,
    beat character varying(10),
    ward integer,
    fbi_code character varying(8),
    x double precision,
    y double precision,
    updated timestamp without time zone,
    year integer,
    lat double precision,
    lon double precision,
    location text,
    id integer,
    the_geom public.geometry(Point,3435)
);


--
-- Name: fbi_codes; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE fbi_codes (
    id integer NOT NULL,
    code character varying(3)
);


--
-- Name: fire_stations; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE fire_stations (
    address character varying(75),
    zip character(5),
    engine character varying(75),
    lat double precision,
    lon double precision,
    bldg_gid integer,
    id integer NOT NULL
);


--
-- Name: fire_stations_id_seq; Type: SEQUENCE; Schema: safety; Owner: -
--

CREATE SEQUENCE fire_stations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fire_stations_id_seq1; Type: SEQUENCE; Schema: safety; Owner: -
--

CREATE SEQUENCE fire_stations_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fire_stations_id_seq1; Type: SEQUENCE OWNED BY; Schema: safety; Owner: -
--

ALTER SEQUENCE fire_stations_id_seq1 OWNED BY fire_stations.id;


--
-- Name: iucr_codes; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE iucr_codes (
    iucr character varying(4) NOT NULL,
    primary_desc character varying(32),
    secondary_desc character varying(59),
    index_code character varying(1)
);


--
-- Name: life_safety_evaluations; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE life_safety_evaluations (
    str_num character varying(12),
    str_dir character varying(2),
    str_name character varying(100),
    str_type character varying(20),
    orig_report_approved character varying(50),
    report_resubmitted character varying(50),
    resubmitted_approved character varying(50),
    construction_status character varying(100),
    installing_sprinkler character varying(100),
    insp_status character varying(100),
    insp_date_passed date,
    scheduled_insp_date date,
    indp_date date,
    bldg_gid integer,
    id integer NOT NULL,
    full_address character varying(200),
    stt boolean
);


--
-- Name: life_safety_evaluations_id_seq; Type: SEQUENCE; Schema: safety; Owner: -
--

CREATE SEQUENCE life_safety_evaluations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: life_safety_evaluations_id_seq; Type: SEQUENCE OWNED BY; Schema: safety; Owner: -
--

ALTER SEQUENCE life_safety_evaluations_id_seq OWNED BY life_safety_evaluations.id;


--
-- Name: police_beats; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE police_beats (
    gid integer NOT NULL,
    district character varying(2),
    sector character varying(1),
    beat character varying(1),
    beat_num character varying(4),
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: police_stations; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE police_stations (
    district character varying(15),
    address character varying(75),
    zip character(5),
    website text,
    phone character varying(20),
    fax character varying(20),
    tty character varying(20),
    lat double precision,
    lon double precision,
    id integer NOT NULL,
    bldg_gid integer,
    dist_suffix character varying(10),
    label character varying(100)
);


--
-- Name: police_stations_id_seq; Type: SEQUENCE; Schema: safety; Owner: -
--

CREATE SEQUENCE police_stations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: police_stations_id_seq1; Type: SEQUENCE; Schema: safety; Owner: -
--

CREATE SEQUENCE police_stations_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: police_stations_id_seq1; Type: SEQUENCE OWNED BY; Schema: safety; Owner: -
--

ALTER SEQUENCE police_stations_id_seq1 OWNED BY police_stations.id;


--
-- Name: policebeat_gid_seq; Type: SEQUENCE; Schema: safety; Owner: -
--

CREATE SEQUENCE policebeat_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: policebeat_gid_seq; Type: SEQUENCE OWNED BY; Schema: safety; Owner: -
--

ALTER SEQUENCE policebeat_gid_seq OWNED BY police_beats.gid;


--
-- Name: sex_offenders; Type: TABLE; Schema: safety; Owner: -; Tablespace: 
--

CREATE TABLE sex_offenders (
    last_name character varying(20),
    first_name character varying(20),
    block character varying(50),
    gender character varying(6),
    race character varying(28),
    birth_date date,
    age integer,
    height integer,
    weight integer,
    victim_minor boolean
);


SET search_path = tif, pg_catalog;

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
-- Name: sbif_grant_agreements; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE sbif_grant_agreements (
    company character varying(150),
    address character varying(150),
    tif_id character varying(10),
    tif_name character varying(150),
    completion_date date,
    actual_cost numeric(12,2),
    actual_grant_work numeric(12,2),
    work_items text,
    id integer NOT NULL,
    bldg_gid integer,
    str_num character varying(50),
    str_dir character varying(10),
    str_name character varying(75),
    the_geom public.geometry(Point,4326)
);


--
-- Name: sbif_grant_agreements_id_seq; Type: SEQUENCE; Schema: tif; Owner: -
--

CREATE SEQUENCE sbif_grant_agreements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sbif_grant_agreements_id_seq; Type: SEQUENCE OWNED BY; Schema: tif; Owner: -
--

ALTER SEQUENCE sbif_grant_agreements_id_seq OWNED BY sbif_grant_agreements.id;


--
-- Name: taxcode; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE taxcode (
    entity character varying(100),
    taxcode character varying(10),
    agency character varying(25),
    tax_rate character varying(50),
    percent character varying(50),
    year character varying(50),
    tif_id character varying(6)
);


--
-- Name: tif_balance_sheets; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE tif_balance_sheets (
    tif_id character varying(10),
    tif_name character varying(100),
    reporting_category character varying(150),
    description text,
    amount money,
    id integer NOT NULL
);


--
-- Name: tif_balance_sheets_id_seq; Type: SEQUENCE; Schema: tif; Owner: -
--

CREATE SEQUENCE tif_balance_sheets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tif_balance_sheets_id_seq; Type: SEQUENCE OWNED BY; Schema: tif; Owner: -
--

ALTER SEQUENCE tif_balance_sheets_id_seq OWNED BY tif_balance_sheets.id;


--
-- Name: tif_balance_sheets_inactive; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE tif_balance_sheets_inactive (
    tif_id character varying(10),
    tif_name character varying(100),
    reporting_category character varying(150),
    description text,
    amount money,
    id integer
);


--
-- Name: tif_districts; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE tif_districts (
    gid integer NOT NULL,
    tif_name character varying(50),
    ind character varying(20),
    type character varying(15),
    use character varying(50),
    repealed_d character varying(10),
    approval_d character varying(10),
    expiration character varying(10),
    the_geom public.geometry(MultiPolygon,3435),
    tif_id character varying(5)
);


--
-- Name: tif_districts_gid_seq; Type: SEQUENCE; Schema: tif; Owner: -
--

CREATE SEQUENCE tif_districts_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tif_districts_gid_seq; Type: SEQUENCE OWNED BY; Schema: tif; Owner: -
--

ALTER SEQUENCE tif_districts_gid_seq OWNED BY tif_districts.gid;


--
-- Name: tif_projection_reports; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE tif_projection_reports (
    tif_id character varying(10),
    tif_name character varying(100),
    reporting_category character varying(100),
    item text,
    year integer,
    amount money,
    end_date date,
    id integer NOT NULL
);


--
-- Name: tif_projection_reports_id_seq; Type: SEQUENCE; Schema: tif; Owner: -
--

CREATE SEQUENCE tif_projection_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tif_projection_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: tif; Owner: -
--

ALTER SEQUENCE tif_projection_reports_id_seq OWNED BY tif_projection_reports.id;


--
-- Name: tif_status_eligibility; Type: TABLE; Schema: tif; Owner: -; Tablespace: 
--

CREATE TABLE tif_status_eligibility (
    status character varying(25),
    tif_id character varying(10),
    tif_name character varying(100),
    designation_date date,
    designation_year smallint,
    end_date date,
    final_year smallint,
    blighting boolean,
    conservation boolean,
    redevelopment_plan text
);


SET search_path = transportation, pg_catalog;

--
-- Name: bike_racks; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE bike_racks (
    id integer NOT NULL,
    address character varying(75),
    str_num integer,
    str_dir character(1),
    str_nam character varying(50),
    str_typ character varying(10),
    ward integer,
    ca_num integer,
    ca character varying(100),
    totinstall integer,
    lat double precision,
    lon double precision,
    historical boolean,
    loc character varying(500),
    the_geom public.geometry(Point,3435)
);


--
-- Name: bike_racks_id_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE bike_racks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bike_routes; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE bike_routes (
    gid integer NOT NULL,
    street character varying(50),
    type character varying(2),
    bikeroute character varying(30),
    l_f_addr character varying(5),
    r_f_addr character varying(5),
    f_street character varying(50),
    l_t_addr character varying(5),
    r_t_addr character varying(5),
    t_street character varying(50),
    the_geom public.geometry(MultiLineString,3435),
    geom_rotated public.geometry(MultiLineString,3435)
);


--
-- Name: bike_routes_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE bike_routes_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bike_routes_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE bike_routes_gid_seq OWNED BY bike_routes.gid;


--
-- Name: boulevards; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE boulevards (
    gid integer NOT NULL,
    id integer,
    sq_footage numeric,
    acreage numeric,
    ca smallint,
    shape_area numeric,
    shape_len numeric,
    the_geom public.geometry(MultiPolygon,3435)
);


--
-- Name: boulevards_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE boulevards_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: boulevards_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE boulevards_gid_seq OWNED BY boulevards.gid;


--
-- Name: sidewalks; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE sidewalks (
    gid integer NOT NULL,
    l_addr integer,
    h_addr integer,
    pre_dir character varying(1),
    st_name character varying(50),
    st_type character varying(5),
    suf_dir character varying(10),
    shape_leng numeric,
    shape_area numeric,
    address character varying(60),
    the_geom public.geometry(MultiPolygon,3435),
    isometric public.geometry(MultiPolygon,3435)
);


--
-- Name: chicagosidewalks_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE chicagosidewalks_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chicagosidewalks_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE chicagosidewalks_gid_seq OWNED BY sidewalks.gid;


--
-- Name: cook_co_hwy_juris; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE cook_co_hwy_juris (
    gid integer NOT NULL,
    uniqid numeric(10,0),
    anno_name character varying(40),
    system character varying(4),
    chs_no character varying(4),
    district integer,
    patrol integer,
    from_st character varying(100),
    to_st character varying(100),
    prewet integer,
    lanes integer,
    section_id character varying(15),
    plow_id integer,
    road_type integer,
    sec_num character varying(2),
    spdlimit integer,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: cook_co_hwy_juris_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE cook_co_hwy_juris_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cook_co_hwy_juris_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE cook_co_hwy_juris_gid_seq OWNED BY cook_co_hwy_juris.gid;


--
-- Name: major_streets; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE major_streets (
    gid integer NOT NULL,
    objectid numeric(10,0),
    fnode_ numeric(10,0),
    tnode_ numeric(10,0),
    lpoly_ numeric(10,0),
    rpoly_ numeric(10,0),
    length numeric,
    trans_ numeric(10,0),
    trans_id numeric(10,0),
    source_id numeric(10,0),
    old_trans_ numeric(10,0),
    street_nam character varying(35),
    street character varying(35),
    edit_date numeric(10,0),
    edit_type character varying(20),
    l_f_add numeric(10,0),
    l_t_add numeric(10,0),
    l_parity character varying(1),
    r_f_add numeric(10,0),
    r_t_add numeric(10,0),
    r_parity character varying(1),
    pre_type character varying(10),
    pre_dir character varying(3),
    direction character varying(1),
    street_typ character varying(5),
    sttype character varying(5),
    suf_dir character varying(3),
    sufdir character varying(3),
    logiclf numeric(10,0),
    logiclt numeric(10,0),
    logicrf numeric(10,0),
    logicrt numeric(10,0),
    ewns numeric(10,0),
    lfhund numeric(10,0),
    lthund numeric(10,0),
    rfhund numeric(10,0),
    rthund numeric(10,0),
    flag_strin character varying(10),
    class character varying(4),
    status character varying(4),
    f_zlev numeric(10,0),
    t_zlev numeric(10,0),
    l_fips numeric(10,0),
    r_fips numeric(10,0),
    l_ward character varying(4),
    r_ward character varying(4),
    l_ward1990 character varying(4),
    r_ward1990 character varying(4),
    l_ilsenate character varying(3),
    r_ilsenate character varying(3),
    l_ilhouse character varying(3),
    r_ilhouse character varying(3),
    l_beat character varying(16),
    r_beat character varying(16),
    l_district character varying(16),
    r_district character varying(16),
    l_atom character varying(8),
    r_atom character varying(8),
    l_comarea character varying(2),
    r_comarea character varying(2),
    l_sect_nam character varying(8),
    r_sect_nam character varying(8),
    f_cross character varying(75),
    t_cross character varying(75),
    streetname numeric(10,0),
    shape_len numeric,
    the_geom public.geometry(MultiLineString,3435),
    geom_rotated public.geometry(MultiLineString,3435)
);


--
-- Name: major_streets_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE major_streets_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: major_streets_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE major_streets_gid_seq OWNED BY major_streets.gid;


--
-- Name: metra_lines; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE metra_lines (
    gid integer NOT NULL,
    asset_id numeric,
    lines character varying(50),
    descriptio character varying(100),
    edit_init character varying(5),
    edit_date date,
    the_geom public.geometry(MultiLineString,3435)
);


--
-- Name: metra_lines_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE metra_lines_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: metra_lines_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE metra_lines_gid_seq OWNED BY metra_lines.gid;


--
-- Name: metra_stations; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE metra_stations (
    gid integer NOT NULL,
    objectid numeric(10,0),
    station_id numeric,
    asset_id numeric,
    name character varying(20),
    longname character varying(50),
    lines character varying(50),
    branch_id smallint,
    status smallint,
    milepost numeric,
    farezone character varying(1),
    ada smallint,
    ada2 character varying(1),
    pknrd smallint,
    bikepkng smallint,
    ticket_ava character varying(50),
    address character varying(75),
    municipali character varying(50),
    telephone character varying(50),
    weblink character varying(250),
    labelangle smallint,
    edit_init character varying(5),
    edit_date date,
    year_open character varying(12),
    the_geom public.geometry(MultiPoint,3435),
    bldg_gid integer
);


--
-- Name: metra_stations_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE metra_stations_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: metra_stations_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE metra_stations_gid_seq OWNED BY metra_stations.gid;


--
-- Name: names_streets; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE names_streets (
    full_name character varying(100),
    str_dir character(1),
    str_name character varying(100),
    str_typ character varying(10),
    sufdir character varying(10),
    minadd integer,
    maxadd integer
);


--
-- Name: pedway; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE pedway (
    gid integer NOT NULL,
    objectid numeric(10,0),
    ped_route character varying(50),
    shape_len numeric,
    the_geom public.geometry(MultiLineString,3435)
);


--
-- Name: pedway_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE pedway_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pedway_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE pedway_gid_seq OWNED BY pedway.gid;


--
-- Name: pedway_routes; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE pedway_routes (
    gid integer NOT NULL,
    objectid numeric(10,0),
    ped_route character varying(100),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 3435))
);


--
-- Name: pedway_routes_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE pedway_routes_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pedway_routes_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE pedway_routes_gid_seq OWNED BY pedway_routes.gid;


--
-- Name: riverwalk; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE riverwalk (
    gid integer NOT NULL,
    objectid numeric(10,0),
    id numeric(10,0),
    status smallint,
    shape_len numeric,
    the_geom public.geometry(MultiLineString,3435)
);


--
-- Name: riverwalk_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE riverwalk_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: riverwalk_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE riverwalk_gid_seq OWNED BY riverwalk.gid;


--
-- Name: streets; Type: TABLE; Schema: transportation; Owner: -; Tablespace: 
--

CREATE TABLE streets (
    gid integer NOT NULL,
    fnode_id numeric(10,0),
    tnode_id numeric(10,0),
    trans_id numeric(10,0),
    pre_dir character varying(1),
    street_nam character varying(50),
    street_typ character varying(5),
    suf_dir character varying(5),
    streetname numeric(10,0),
    l_f_add numeric(10,0),
    l_t_add numeric(10,0),
    r_f_add numeric(10,0),
    r_t_add numeric(10,0),
    logiclf numeric(10,0),
    logiclt numeric(10,0),
    logicrf numeric(10,0),
    logicrt numeric(10,0),
    class character varying(4),
    status character varying(4),
    status_dat date,
    tiered character varying(1),
    oneway_dir character varying(1),
    dir_travel character varying(1),
    ewns numeric(10,0),
    l_parity character varying(1),
    r_parity character varying(1),
    f_zlev numeric(10,0),
    t_zlev numeric(10,0),
    l_fips numeric(10,0),
    r_fips numeric(10,0),
    r_zip character varying(5),
    l_zip character varying(5),
    r_censusbl character varying(15),
    l_censusbl character varying(15),
    f_cross character varying(75),
    f_cross_st numeric(10,0),
    t_cross character varying(75),
    t_cross_st numeric(10,0),
    length numeric,
    edit_date numeric(10,0),
    edit_type character varying(20),
    flag_strin character varying(10),
    ewns_dir character varying(1),
    ewns_coord numeric(10,0),
    create_use character varying(10),
    create_tim date,
    update_use character varying(10),
    update_tim date,
    shape_len numeric,
    the_geom public.geometry(MultiLineString,3435),
    full_name character varying(75),
    isometric public.geometry(MultiLineString,3435)
);


--
-- Name: streets2_gid_seq; Type: SEQUENCE; Schema: transportation; Owner: -
--

CREATE SEQUENCE streets2_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: streets2_gid_seq; Type: SEQUENCE OWNED BY; Schema: transportation; Owner: -
--

ALTER SEQUENCE streets2_gid_seq OWNED BY streets.gid;


SET search_path = boundaries, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY census_blocks ALTER COLUMN gid SET DEFAULT nextval('blocks2010_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY census_tracts ALTER COLUMN gid SET DEFAULT nextval('tracts2010_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY central_business_district ALTER COLUMN gid SET DEFAULT nextval('central_business_district_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY city_boundary ALTER COLUMN gid SET DEFAULT nextval('city_boundary_gid_seq'::regclass);


--
-- Name: gid1; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY comm_areas ALTER COLUMN gid1 SET DEFAULT nextval('comm_areas_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY congress ALTER COLUMN gid SET DEFAULT nextval('il_congress_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY conservation_areas ALTER COLUMN gid SET DEFAULT nextval('conservation_areas_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY empowerment_zones ALTER COLUMN gid SET DEFAULT nextval('empowerment_zones_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY enterprise_communities ALTER COLUMN gid SET DEFAULT nextval('enterprise_communities_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY enterprise_zones ALTER COLUMN gid SET DEFAULT nextval('enterprise_zones_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY il_house_districts ALTER COLUMN gid SET DEFAULT nextval('il_house_districts_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY ilhouse2000 ALTER COLUMN gid SET DEFAULT nextval('ilhouse2000_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY ilsenate2000 ALTER COLUMN gid SET DEFAULT nextval('ilsenate2000_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY industrial_corridors ALTER COLUMN gid SET DEFAULT nextval('industrial_corridors_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY municipalities ALTER COLUMN gid SET DEFAULT nextval('municipalities_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY neighborhoods ALTER COLUMN gid SET DEFAULT nextval('neighboorhoods_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY new_wards ALTER COLUMN gid SET DEFAULT nextval('councilpassedwards_11192012_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY planning_districts ALTER COLUMN gid SET DEFAULT nextval('planning_districts_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY planning_regions ALTER COLUMN gid SET DEFAULT nextval('planning_regions_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY police_districts ALTER COLUMN gid SET DEFAULT nextval('police_districts_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY precincts ALTER COLUMN gid SET DEFAULT nextval('wardprecincts_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY snow_parking ALTER COLUMN gid SET DEFAULT nextval('snowparkingrestrict2inch_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY special_service_areas ALTER COLUMN gid SET DEFAULT nextval('special_service_areas_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY sweeping ALTER COLUMN gid SET DEFAULT nextval('streetsweeping2012_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY wards ALTER COLUMN gid SET DEFAULT nextval('wards_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY winterovernightparkingrestrictions ALTER COLUMN gid SET DEFAULT nextval('winterovernightparkingrestrictions_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY zip_codes ALTER COLUMN gid SET DEFAULT nextval('zip_codes_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY zoning_aug2012 ALTER COLUMN gid SET DEFAULT nextval('zoning_aug2012_gid_seq'::regclass);


SET search_path = buildings, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY alternate_addresses ALTER COLUMN id SET DEFAULT nextval('alternate_addresses_id_seq'::regclass);


--
-- Name: bldg_gid; Type: DEFAULT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY buildings ALTER COLUMN bldg_gid SET DEFAULT nextval('buildings_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY buildings_bldg_name ALTER COLUMN id SET DEFAULT nextval('buildings_bldg_name_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY curbs ALTER COLUMN gid SET DEFAULT nextval('curbs_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY landuse ALTER COLUMN gid SET DEFAULT nextval('landuse2005_cmap_v1_gid_seq'::regclass);


SET search_path = business, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: business; Owner: -
--

ALTER TABLE ONLY business_licenses ALTER COLUMN id SET DEFAULT nextval('sep14bldg_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: business; Owner: -
--

ALTER TABLE ONLY twitter ALTER COLUMN id SET DEFAULT nextval('buildings_twitter_ids_primary_id_seq'::regclass);


SET search_path = civic, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY cemeteries ALTER COLUMN gid SET DEFAULT nextval('chicago_cemeteries_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY chi_idhs_offices ALTER COLUMN id SET DEFAULT nextval('chi_idhs_offices_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY circuit_court_cook_cnty_judges ALTER COLUMN id SET DEFAULT nextval('circuit_court_cook_cnty_judges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY contracts ALTER COLUMN id SET DEFAULT nextval('contracts_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY cook_co_facilities_in_chicago ALTER COLUMN gid SET DEFAULT nextval('cook_co_facilities_in_chicago_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY ewaste_collection_sites ALTER COLUMN id SET DEFAULT nextval('ewaste_collection_sites_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY public_plazas ALTER COLUMN gid SET DEFAULT nextval('public_plazas_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY public_tech_resources ALTER COLUMN id SET DEFAULT nextval('ptr_updated_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: civic; Owner: -
--

ALTER TABLE ONLY youth_centers ALTER COLUMN id SET DEFAULT nextval('youth_centers_id_seq1'::regclass);


SET search_path = cta, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: cta; Owner: -
--

ALTER TABLE ONLY bus_routes ALTER COLUMN gid SET DEFAULT nextval('bus_routes_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: cta; Owner: -
--

ALTER TABLE ONLY bus_stops ALTER COLUMN gid SET DEFAULT nextval('bus_stops_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: cta; Owner: -
--

ALTER TABLE ONLY cta_bus_garages ALTER COLUMN gid SET DEFAULT nextval('cta_bus_garages_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: cta; Owner: -
--

ALTER TABLE ONLY cta_fare_media_retail_outlets ALTER COLUMN gid SET DEFAULT nextval('ctafaremedia_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: cta; Owner: -
--

ALTER TABLE ONLY cta_rail_lines_iso ALTER COLUMN id SET DEFAULT nextval('cta_rail_lines_iso_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: cta; Owner: -
--

ALTER TABLE ONLY owlroutes ALTER COLUMN id SET DEFAULT nextval('owlroutes_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: cta; Owner: -
--

ALTER TABLE ONLY rail_lines ALTER COLUMN gid SET DEFAULT nextval('rail_lines_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: cta; Owner: -
--

ALTER TABLE ONLY rail_stations ALTER COLUMN gid SET DEFAULT nextval('rail_stations_gid_seq'::regclass);


SET search_path = education, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades1 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades1_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades10 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades10_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades11 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades11_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades12 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades12_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades2 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades2_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades3 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades3_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades4 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades4_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades5 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades5_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades6 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades6_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades7 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades7_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades8 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades8_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygrades9 ALTER COLUMN gid SET DEFAULT nextval('boundarygrades9_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY boundarygradesk ALTER COLUMN gid SET DEFAULT nextval('boundarygradesk_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY campus_parks ALTER COLUMN gid SET DEFAULT nextval('campus_parks2_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY libraries ALTER COLUMN id SET DEFAULT nextval('libraries_locations_hours_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY private_schools ALTER COLUMN gid SET DEFAULT nextval('private_schools_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: education; Owner: -
--

ALTER TABLE ONLY public_schools ALTER COLUMN gid SET DEFAULT nextval('schoollocations2012_13_gid_seq'::regclass);


SET search_path = environment, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY farmers_markets_2012 ALTER COLUMN gid SET DEFAULT nextval('farmers_markets_2012_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY fishing_lake_bathymetry ALTER COLUMN gid SET DEFAULT nextval('fishing_lake_bathymetry_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY forest_preserve_groves ALTER COLUMN gid SET DEFAULT nextval('forest_preserve_groves_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY forest_preserve_shelters ALTER COLUMN gid SET DEFAULT nextval('forest_preserve_shelters_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY forest_preserve_trails ALTER COLUMN gid SET DEFAULT nextval('trails_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY forestry ALTER COLUMN gid SET DEFAULT nextval('forestry_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY natural_habitats ALTER COLUMN gid SET DEFAULT nextval('natural_habitats_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY neighborspace_gardens ALTER COLUMN gid SET DEFAULT nextval('neighborspace_gardens_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY parkbuildings_aug2012 ALTER COLUMN gid SET DEFAULT nextval('parkbuildings_aug2012_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY parkfacilities_aug2012 ALTER COLUMN gid SET DEFAULT nextval('parkfacilities_aug2012_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY parks ALTER COLUMN gid SET DEFAULT nextval('parks_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: environment; Owner: -
--

ALTER TABLE ONLY waterways ALTER COLUMN gid SET DEFAULT nextval('hydro_gid_seq'::regclass);


SET search_path = health, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: health; Owner: -
--

ALTER TABLE ONLY condom_distribution_sites ALTER COLUMN id SET DEFAULT nextval('condoms2_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: health; Owner: -
--

ALTER TABLE ONLY dentists ALTER COLUMN id SET DEFAULT nextval('dentists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: health; Owner: -
--

ALTER TABLE ONLY food_inspection ALTER COLUMN id SET DEFAULT nextval('food_inspection_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: health; Owner: -
--

ALTER TABLE ONLY hospitals ALTER COLUMN gid SET DEFAULT nextval('hosp_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: health; Owner: -
--

ALTER TABLE ONLY outpatient_registrations_by_zip_by_month_by_hospital ALTER COLUMN id SET DEFAULT nextval('outpatient_registrations_by_zip_by_month_by_hospital_id_seq'::regclass);


SET search_path = history, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: history; Owner: -
--

ALTER TABLE ONLY historic_districts ALTER COLUMN gid SET DEFAULT nextval('historic_districtst_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: history; Owner: -
--

ALTER TABLE ONLY historic_resources ALTER COLUMN gid SET DEFAULT nextval('landmarkshistrsrcesurvey_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: history; Owner: -
--

ALTER TABLE ONLY landmarks ALTER COLUMN gid SET DEFAULT nextval('landmarks_updated_gid_seq'::regclass);


SET search_path = public, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY building_penalties ALTER COLUMN id SET DEFAULT nextval('building_penalties_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY elementarynetworks ALTER COLUMN gid SET DEFAULT nextval('elementarynetworks_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY greenroofs2012 ALTER COLUMN gid SET DEFAULT nextval('greenroofs2012_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY highschoolnetworks ALTER COLUMN gid SET DEFAULT nextval('highschoolnetworks_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY rda_byward_sum ALTER COLUMN gid SET DEFAULT nextval('rda_byward_sum_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tif_projectsfinal ALTER COLUMN gid SET DEFAULT nextval('tif_projectsfinal_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_address_input ALTER COLUMN gid SET DEFAULT nextval('user_address_input_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wicker_park_free_wifi ALTER COLUMN gid SET DEFAULT nextval('wicker_park_free_wifi_gid_seq'::regclass);


SET search_path = safety, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: safety; Owner: -
--

ALTER TABLE ONLY crimes ALTER COLUMN id SET DEFAULT nextval('crimes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: safety; Owner: -
--

ALTER TABLE ONLY fire_stations ALTER COLUMN id SET DEFAULT nextval('fire_stations_id_seq1'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: safety; Owner: -
--

ALTER TABLE ONLY life_safety_evaluations ALTER COLUMN id SET DEFAULT nextval('life_safety_evaluations_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: safety; Owner: -
--

ALTER TABLE ONLY police_beats ALTER COLUMN gid SET DEFAULT nextval('policebeat_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: safety; Owner: -
--

ALTER TABLE ONLY police_stations ALTER COLUMN id SET DEFAULT nextval('police_stations_id_seq1'::regclass);


SET search_path = tif, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: tif; Owner: -
--

ALTER TABLE ONLY pins_master ALTER COLUMN id SET DEFAULT nextval('pins_master_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: tif; Owner: -
--

ALTER TABLE ONLY sbif_grant_agreements ALTER COLUMN id SET DEFAULT nextval('sbif_grant_agreements_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: tif; Owner: -
--

ALTER TABLE ONLY tif_balance_sheets ALTER COLUMN id SET DEFAULT nextval('tif_balance_sheets_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: tif; Owner: -
--

ALTER TABLE ONLY tif_districts ALTER COLUMN gid SET DEFAULT nextval('tif_districts_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: tif; Owner: -
--

ALTER TABLE ONLY tif_projection_reports ALTER COLUMN id SET DEFAULT nextval('tif_projection_reports_id_seq'::regclass);


SET search_path = transportation, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY bike_routes ALTER COLUMN gid SET DEFAULT nextval('bike_routes_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY boulevards ALTER COLUMN gid SET DEFAULT nextval('boulevards_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY cook_co_hwy_juris ALTER COLUMN gid SET DEFAULT nextval('cook_co_hwy_juris_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY major_streets ALTER COLUMN gid SET DEFAULT nextval('major_streets_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY metra_lines ALTER COLUMN gid SET DEFAULT nextval('metra_lines_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY metra_stations ALTER COLUMN gid SET DEFAULT nextval('metra_stations_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY pedway ALTER COLUMN gid SET DEFAULT nextval('pedway_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY pedway_routes ALTER COLUMN gid SET DEFAULT nextval('pedway_routes_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY riverwalk ALTER COLUMN gid SET DEFAULT nextval('riverwalk_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY sidewalks ALTER COLUMN gid SET DEFAULT nextval('chicagosidewalks_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY streets ALTER COLUMN gid SET DEFAULT nextval('streets2_gid_seq'::regclass);


SET search_path = boundaries, pg_catalog;

--
-- Name: census_block_groups_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY census_block_groups
    ADD CONSTRAINT census_block_groups_pkey PRIMARY KEY (gid);


--
-- Name: il_congress_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY congress
    ADD CONSTRAINT il_congress_pkey PRIMARY KEY (gid);


--
-- Name: il_house_districts_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY il_house_districts
    ADD CONSTRAINT il_house_districts_pkey PRIMARY KEY (gid);


--
-- Name: ilhouse2000_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ilhouse2000
    ADD CONSTRAINT ilhouse2000_pkey PRIMARY KEY (gid);


--
-- Name: ilsenate2000_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ilsenate2000
    ADD CONSTRAINT ilsenate2000_pkey PRIMARY KEY (gid);


--
-- Name: municipalities_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY municipalities
    ADD CONSTRAINT municipalities_pkey PRIMARY KEY (gid);


--
-- Name: snowparkingrestrict2inch_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY snow_parking
    ADD CONSTRAINT snowparkingrestrict2inch_pkey PRIMARY KEY (gid);


--
-- Name: streetsweeping2012_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sweeping
    ADD CONSTRAINT streetsweeping2012_pkey PRIMARY KEY (gid);


--
-- Name: wardprecincts_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY precincts
    ADD CONSTRAINT wardprecincts_pkey PRIMARY KEY (gid);


--
-- Name: winterovernightparkingrestrictions_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY winterovernightparkingrestrictions
    ADD CONSTRAINT winterovernightparkingrestrictions_pkey PRIMARY KEY (gid);


--
-- Name: zoning_aug2012_pkey; Type: CONSTRAINT; Schema: boundaries; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zoning_aug2012
    ADD CONSTRAINT zoning_aug2012_pkey PRIMARY KEY (gid);


SET search_path = buildings, pg_catalog;

--
-- Name: address_bldg_gid_key; Type: CONSTRAINT; Schema: buildings; Owner: -; Tablespace: 
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_bldg_gid_key UNIQUE (bldg_gid);


--
-- Name: alternate_addresses_address_key; Type: CONSTRAINT; Schema: buildings; Owner: -; Tablespace: 
--

ALTER TABLE ONLY alternate_addresses
    ADD CONSTRAINT alternate_addresses_address_key UNIQUE (address);


--
-- Name: alternate_addresses_pkey; Type: CONSTRAINT; Schema: buildings; Owner: -; Tablespace: 
--

ALTER TABLE ONLY alternate_addresses
    ADD CONSTRAINT alternate_addresses_pkey PRIMARY KEY (address);


--
-- Name: buildings_bldg_name_pkey; Type: CONSTRAINT; Schema: buildings; Owner: -; Tablespace: 
--

ALTER TABLE ONLY buildings_bldg_name
    ADD CONSTRAINT buildings_bldg_name_pkey PRIMARY KEY (id);


--
-- Name: buildings_pkey; Type: CONSTRAINT; Schema: buildings; Owner: -; Tablespace: 
--

ALTER TABLE ONLY buildings
    ADD CONSTRAINT buildings_pkey PRIMARY KEY (bldg_gid);


--
-- Name: landuse2005_cmap_v1_pkey; Type: CONSTRAINT; Schema: buildings; Owner: -; Tablespace: 
--

ALTER TABLE ONLY landuse
    ADD CONSTRAINT landuse2005_cmap_v1_pkey PRIMARY KEY (gid);


--
-- Name: stories_bldg_gid_key; Type: CONSTRAINT; Schema: buildings; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stories
    ADD CONSTRAINT stories_bldg_gid_key UNIQUE (bldg_gid);


SET search_path = civic, pg_catalog;

--
-- Name: ptr_updated_pkey; Type: CONSTRAINT; Schema: civic; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public_tech_resources
    ADD CONSTRAINT ptr_updated_pkey PRIMARY KEY (id);


SET search_path = education, pg_catalog;

--
-- Name: boundarygrades10_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades10
    ADD CONSTRAINT boundarygrades10_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades11_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades11
    ADD CONSTRAINT boundarygrades11_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades12_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades12
    ADD CONSTRAINT boundarygrades12_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades1_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades1
    ADD CONSTRAINT boundarygrades1_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades2_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades2
    ADD CONSTRAINT boundarygrades2_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades3_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades3
    ADD CONSTRAINT boundarygrades3_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades4_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades4
    ADD CONSTRAINT boundarygrades4_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades5_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades5
    ADD CONSTRAINT boundarygrades5_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades6_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades6
    ADD CONSTRAINT boundarygrades6_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades7_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades7
    ADD CONSTRAINT boundarygrades7_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades8_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades8
    ADD CONSTRAINT boundarygrades8_pkey PRIMARY KEY (gid);


--
-- Name: boundarygrades9_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygrades9
    ADD CONSTRAINT boundarygrades9_pkey PRIMARY KEY (gid);


--
-- Name: boundarygradesk_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boundarygradesk
    ADD CONSTRAINT boundarygradesk_pkey PRIMARY KEY (gid);


--
-- Name: schoollocations2012_13_pkey; Type: CONSTRAINT; Schema: education; Owner: -; Tablespace: 
--

ALTER TABLE ONLY public_schools
    ADD CONSTRAINT schoollocations2012_13_pkey PRIMARY KEY (gid);


SET search_path = environment, pg_catalog;

--
-- Name: farmers_markets_2012_pkey; Type: CONSTRAINT; Schema: environment; Owner: -; Tablespace: 
--

ALTER TABLE ONLY farmers_markets_2012
    ADD CONSTRAINT farmers_markets_2012_pkey PRIMARY KEY (gid);


--
-- Name: parkbuildings_aug2012_pkey; Type: CONSTRAINT; Schema: environment; Owner: -; Tablespace: 
--

ALTER TABLE ONLY parkbuildings_aug2012
    ADD CONSTRAINT parkbuildings_aug2012_pkey PRIMARY KEY (gid);


--
-- Name: parkfacilities_aug2012_pkey; Type: CONSTRAINT; Schema: environment; Owner: -; Tablespace: 
--

ALTER TABLE ONLY parkfacilities_aug2012
    ADD CONSTRAINT parkfacilities_aug2012_pkey PRIMARY KEY (gid);


--
-- Name: parks_pkey; Type: CONSTRAINT; Schema: environment; Owner: -; Tablespace: 
--

ALTER TABLE ONLY parks
    ADD CONSTRAINT parks_pkey PRIMARY KEY (gid);


SET search_path = health, pg_catalog;

--
-- Name: condom_distribution_sites_pkey; Type: CONSTRAINT; Schema: health; Owner: -; Tablespace: 
--

ALTER TABLE ONLY condom_distribution_sites
    ADD CONSTRAINT condom_distribution_sites_pkey PRIMARY KEY (id);


--
-- Name: dentists_pkey; Type: CONSTRAINT; Schema: health; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dentists
    ADD CONSTRAINT dentists_pkey PRIMARY KEY (id);


SET search_path = history, pg_catalog;

--
-- Name: landmarks_updated_pkey; Type: CONSTRAINT; Schema: history; Owner: -; Tablespace: 
--

ALTER TABLE ONLY landmarks
    ADD CONSTRAINT landmarks_updated_pkey PRIMARY KEY (gid);


--
-- Name: landmarkshistrsrcesurvey_pkey; Type: CONSTRAINT; Schema: history; Owner: -; Tablespace: 
--

ALTER TABLE ONLY historic_resources
    ADD CONSTRAINT landmarkshistrsrcesurvey_pkey PRIMARY KEY (gid);


SET search_path = public, pg_catalog;

--
-- Name: building_penalties_ordinance_num_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY building_penalties
    ADD CONSTRAINT building_penalties_ordinance_num_key UNIQUE (ordinance_num);


--
-- Name: building_penalties_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY building_penalties
    ADD CONSTRAINT building_penalties_pkey PRIMARY KEY (id);


--
-- Name: building_permits_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY building_permits
    ADD CONSTRAINT building_permits_id_key UNIQUE (id);


--
-- Name: building_violations_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY building_violations
    ADD CONSTRAINT building_violations_id_key UNIQUE (id);


--
-- Name: building_violations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY building_violations
    ADD CONSTRAINT building_violations_pkey PRIMARY KEY (id);


--
-- Name: buildings_tilemill_geojson_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY buildings_tilemill_geojson
    ADD CONSTRAINT buildings_tilemill_geojson_pkey PRIMARY KEY (bldg_gid);


--
-- Name: buildings_tilemill_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY buildings_tilemill
    ADD CONSTRAINT buildings_tilemill_pkey PRIMARY KEY (bldg_gid);


--
-- Name: elementarynetworks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY elementarynetworks
    ADD CONSTRAINT elementarynetworks_pkey PRIMARY KEY (gid);


--
-- Name: greenroofs2012_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY greenroofs2012
    ADD CONSTRAINT greenroofs2012_pkey PRIMARY KEY (gid);


--
-- Name: highschoolnetworks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY highschoolnetworks
    ADD CONSTRAINT highschoolnetworks_pkey PRIMARY KEY (gid);


--
-- Name: rda_byward_sum_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rda_byward_sum
    ADD CONSTRAINT rda_byward_sum_pkey PRIMARY KEY (gid);


--
-- Name: tif_projectsfinal_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tif_projectsfinal
    ADD CONSTRAINT tif_projectsfinal_pkey PRIMARY KEY (gid);


--
-- Name: user_address_input_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_address_input
    ADD CONSTRAINT user_address_input_pkey PRIMARY KEY (gid);


SET search_path = safety, pg_catalog;

--
-- Name: crimes_pkey; Type: CONSTRAINT; Schema: safety; Owner: -; Tablespace: 
--

ALTER TABLE ONLY crimes
    ADD CONSTRAINT crimes_pkey PRIMARY KEY (id);


--
-- Name: fire_stations_pkey; Type: CONSTRAINT; Schema: safety; Owner: -; Tablespace: 
--

ALTER TABLE ONLY fire_stations
    ADD CONSTRAINT fire_stations_pkey PRIMARY KEY (id);


--
-- Name: iucr_codes_pkey; Type: CONSTRAINT; Schema: safety; Owner: -; Tablespace: 
--

ALTER TABLE ONLY iucr_codes
    ADD CONSTRAINT iucr_codes_pkey PRIMARY KEY (iucr);


--
-- Name: life_safety_evaluations_pkey; Type: CONSTRAINT; Schema: safety; Owner: -; Tablespace: 
--

ALTER TABLE ONLY life_safety_evaluations
    ADD CONSTRAINT life_safety_evaluations_pkey PRIMARY KEY (id);


--
-- Name: police_stations_pkey; Type: CONSTRAINT; Schema: safety; Owner: -; Tablespace: 
--

ALTER TABLE ONLY police_stations
    ADD CONSTRAINT police_stations_pkey PRIMARY KEY (id);


--
-- Name: policebeat_pkey; Type: CONSTRAINT; Schema: safety; Owner: -; Tablespace: 
--

ALTER TABLE ONLY police_beats
    ADD CONSTRAINT policebeat_pkey PRIMARY KEY (gid);


SET search_path = tif, pg_catalog;

--
-- Name: pins_master_pkey; Type: CONSTRAINT; Schema: tif; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pins_master
    ADD CONSTRAINT pins_master_pkey PRIMARY KEY (id);


--
-- Name: tif_districts_pkey; Type: CONSTRAINT; Schema: tif; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tif_districts
    ADD CONSTRAINT tif_districts_pkey PRIMARY KEY (gid);


--
-- Name: tif_districts_tif_id_key; Type: CONSTRAINT; Schema: tif; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tif_districts
    ADD CONSTRAINT tif_districts_tif_id_key UNIQUE (tif_id);


--
-- Name: tif_status_eligibility_tif_id_key; Type: CONSTRAINT; Schema: tif; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tif_status_eligibility
    ADD CONSTRAINT tif_status_eligibility_tif_id_key UNIQUE (tif_id);


SET search_path = transportation, pg_catalog;

--
-- Name: bike_racks_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bike_racks
    ADD CONSTRAINT bike_racks_pkey PRIMARY KEY (id);


--
-- Name: bike_routes_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bike_routes
    ADD CONSTRAINT bike_routes_pkey PRIMARY KEY (gid);


--
-- Name: boulevards_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY boulevards
    ADD CONSTRAINT boulevards_pkey PRIMARY KEY (gid);


--
-- Name: chicagosidewalks_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sidewalks
    ADD CONSTRAINT chicagosidewalks_pkey PRIMARY KEY (gid);


--
-- Name: major_streets_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY major_streets
    ADD CONSTRAINT major_streets_pkey PRIMARY KEY (gid);


--
-- Name: metra_lines_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY metra_lines
    ADD CONSTRAINT metra_lines_pkey PRIMARY KEY (gid);


--
-- Name: metra_stations_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY metra_stations
    ADD CONSTRAINT metra_stations_pkey PRIMARY KEY (gid);


--
-- Name: pedway_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pedway
    ADD CONSTRAINT pedway_pkey PRIMARY KEY (gid);


--
-- Name: riverwalk_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY riverwalk
    ADD CONSTRAINT riverwalk_pkey PRIMARY KEY (gid);


--
-- Name: streets2_pkey; Type: CONSTRAINT; Schema: transportation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY streets
    ADD CONSTRAINT streets2_pkey PRIMARY KEY (gid);


SET search_path = boundaries, pg_catalog;

--
-- Name: il_congress_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX il_congress_the_geom_gist ON congress USING gist (the_geom);


--
-- Name: il_house_districts_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX il_house_districts_the_geom_gist ON il_house_districts USING gist (the_geom);


--
-- Name: ilhouse2000_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX ilhouse2000_the_geom_gist ON ilhouse2000 USING gist (the_geom);


--
-- Name: ilsenate2000_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX ilsenate2000_the_geom_gist ON ilsenate2000 USING gist (the_geom);


--
-- Name: municipalities_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX municipalities_the_geom_gist ON municipalities USING gist (the_geom);


--
-- Name: neighborhood_names_idx; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX neighborhood_names_idx ON neighborhoods USING btree (pri_neigh);


--
-- Name: planning_region_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX planning_region_geom_gist ON planning_regions USING gist (the_geom);


--
-- Name: snowparkingrestrict2inch_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX snowparkingrestrict2inch_the_geom_gist ON snow_parking USING gist (the_geom);


--
-- Name: streetsweeping2012_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX streetsweeping2012_the_geom_gist ON sweeping USING gist (the_geom);


--
-- Name: wardprecincts_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX wardprecincts_the_geom_gist ON precincts USING gist (the_geom);


--
-- Name: winterovernightparkingrestrictions_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX winterovernightparkingrestrictions_the_geom_gist ON winterovernightparkingrestrictions USING gist (the_geom);


--
-- Name: zoning_aug2012_the_geom_gist; Type: INDEX; Schema: boundaries; Owner: -; Tablespace: 
--

CREATE INDEX zoning_aug2012_the_geom_gist ON zoning_aug2012 USING gist (the_geom);


SET search_path = buildings, pg_catalog;

--
-- Name: alternate_addresses_address_idx; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX alternate_addresses_address_idx ON alternate_addresses USING btree (address);


--
-- Name: buildings_address_idx; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX buildings_address_idx ON address USING btree (bldg_gid);


--
-- Name: buildings_geom_gist_idx; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX buildings_geom_gist_idx ON buildings USING gist (the_geom);


--
-- Name: landuse2005_cmap_v1_the_geom_gist; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX landuse2005_cmap_v1_the_geom_gist ON landuse USING gist (the_geom);


--
-- Name: roofs_bldg_gid_idx; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX roofs_bldg_gid_idx ON roofs USING btree (bldg_gid);


--
-- Name: roofs_geom_gist; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX roofs_geom_gist ON roofs USING gist (roof);


--
-- Name: sqft_idx; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX sqft_idx ON sqft USING btree (bldg_gid);


--
-- Name: stories_idx; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX stories_idx ON stories USING btree (bldg_gid);


--
-- Name: walls_bldg_gid_idx; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX walls_bldg_gid_idx ON walls USING btree (bldg_gid);


--
-- Name: walls_geom_gist; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX walls_geom_gist ON walls USING gist (wall);


--
-- Name: year_built_idx; Type: INDEX; Schema: buildings; Owner: -; Tablespace: 
--

CREATE INDEX year_built_idx ON year_built USING btree (bldg_gid);


SET search_path = education, pg_catalog;

--
-- Name: boundarygrades10_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades10_the_geom_gist ON boundarygrades10 USING gist (the_geom);


--
-- Name: boundarygrades11_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades11_the_geom_gist ON boundarygrades11 USING gist (the_geom);


--
-- Name: boundarygrades12_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades12_the_geom_gist ON boundarygrades12 USING gist (the_geom);


--
-- Name: boundarygrades1_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades1_the_geom_gist ON boundarygrades1 USING gist (the_geom);


--
-- Name: boundarygrades2_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades2_the_geom_gist ON boundarygrades2 USING gist (the_geom);


--
-- Name: boundarygrades3_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades3_the_geom_gist ON boundarygrades3 USING gist (the_geom);


--
-- Name: boundarygrades4_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades4_the_geom_gist ON boundarygrades4 USING gist (the_geom);


--
-- Name: boundarygrades5_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades5_the_geom_gist ON boundarygrades5 USING gist (the_geom);


--
-- Name: boundarygrades6_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades6_the_geom_gist ON boundarygrades6 USING gist (the_geom);


--
-- Name: boundarygrades7_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades7_the_geom_gist ON boundarygrades7 USING gist (the_geom);


--
-- Name: boundarygrades8_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades8_the_geom_gist ON boundarygrades8 USING gist (the_geom);


--
-- Name: boundarygrades9_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygrades9_the_geom_gist ON boundarygrades9 USING gist (the_geom);


--
-- Name: boundarygradesk_the_geom_gist; Type: INDEX; Schema: education; Owner: -; Tablespace: 
--

CREATE INDEX boundarygradesk_the_geom_gist ON boundarygradesk USING gist (the_geom);


SET search_path = environment, pg_catalog;

--
-- Name: farmers_markets_2012_the_geom_gist; Type: INDEX; Schema: environment; Owner: -; Tablespace: 
--

CREATE INDEX farmers_markets_2012_the_geom_gist ON farmers_markets_2012 USING gist (the_geom);


--
-- Name: parkbuildings_aug2012_the_geom_gist; Type: INDEX; Schema: environment; Owner: -; Tablespace: 
--

CREATE INDEX parkbuildings_aug2012_the_geom_gist ON parkbuildings_aug2012 USING gist (the_geom);


--
-- Name: parkfacilities_aug2012_the_geom_gist; Type: INDEX; Schema: environment; Owner: -; Tablespace: 
--

CREATE INDEX parkfacilities_aug2012_the_geom_gist ON parkfacilities_aug2012 USING gist (the_geom);


--
-- Name: parks_the_geom_gist; Type: INDEX; Schema: environment; Owner: -; Tablespace: 
--

CREATE INDEX parks_the_geom_gist ON parks USING gist (the_geom);


SET search_path = history, pg_catalog;

--
-- Name: landmarkshistrsrcesurvey_the_geom_gist; Type: INDEX; Schema: history; Owner: -; Tablespace: 
--

CREATE INDEX landmarkshistrsrcesurvey_the_geom_gist ON historic_resources USING gist (the_geom);


SET search_path = public, pg_catalog;

--
-- Name: elementarynetworks_the_geom_gist; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX elementarynetworks_the_geom_gist ON elementarynetworks USING gist (the_geom);


--
-- Name: greenroofs2012_the_geom_gist; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX greenroofs2012_the_geom_gist ON greenroofs2012 USING gist (the_geom);


--
-- Name: highschoolnetworks_the_geom_gist; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX highschoolnetworks_the_geom_gist ON highschoolnetworks USING gist (the_geom);


--
-- Name: pma_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX pma_idx ON pins_master_ass USING btree (pin);


SET search_path = safety, pg_catalog;

--
-- Name: crimes_idx_geom_gist; Type: INDEX; Schema: safety; Owner: -; Tablespace: 
--

CREATE INDEX crimes_idx_geom_gist ON crimes USING gist (the_geom);


--
-- Name: policebeat_the_geom_gist; Type: INDEX; Schema: safety; Owner: -; Tablespace: 
--

CREATE INDEX policebeat_the_geom_gist ON police_beats USING gist (the_geom);


SET search_path = tif, pg_catalog;

--
-- Name: county_temp_distinct_geom_gist; Type: INDEX; Schema: tif; Owner: -; Tablespace: 
--

CREATE INDEX county_temp_distinct_geom_gist ON property_values USING gist (the_geom);


--
-- Name: property_values_pin_idx; Type: INDEX; Schema: tif; Owner: -; Tablespace: 
--

CREATE INDEX property_values_pin_idx ON property_values USING btree (pin);


--
-- Name: tif_districts_the_geom_gist; Type: INDEX; Schema: tif; Owner: -; Tablespace: 
--

CREATE INDEX tif_districts_the_geom_gist ON tif_districts USING gist (the_geom);


SET search_path = transportation, pg_catalog;

--
-- Name: bike_routes_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX bike_routes_the_geom_gist ON bike_routes USING gist (the_geom);


--
-- Name: boulevards_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX boulevards_the_geom_gist ON boulevards USING gist (the_geom);


--
-- Name: chicagosidewalks_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX chicagosidewalks_the_geom_gist ON sidewalks USING gist (the_geom);


--
-- Name: major_streets_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX major_streets_the_geom_gist ON major_streets USING gist (the_geom);


--
-- Name: metra_lines_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX metra_lines_the_geom_gist ON metra_lines USING gist (the_geom);


--
-- Name: metra_stations_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX metra_stations_the_geom_gist ON metra_stations USING gist (the_geom);


--
-- Name: pedway_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX pedway_the_geom_gist ON pedway USING gist (the_geom);


--
-- Name: riverwalk_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX riverwalk_the_geom_gist ON riverwalk USING gist (the_geom);


--
-- Name: sidewalks_iso_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX sidewalks_iso_gist ON sidewalks USING gist (isometric);


--
-- Name: streets2_the_geom_gist; Type: INDEX; Schema: transportation; Owner: -; Tablespace: 
--

CREATE INDEX streets2_the_geom_gist ON streets USING gist (the_geom);


SET search_path = public, pg_catalog;

--
-- Name: geometry_columns_delete; Type: RULE; Schema: public; Owner: -
--

CREATE RULE geometry_columns_delete AS ON DELETE TO geometry_columns DO INSTEAD NOTHING;


--
-- Name: geometry_columns_insert; Type: RULE; Schema: public; Owner: -
--

CREATE RULE geometry_columns_insert AS ON INSERT TO geometry_columns DO INSTEAD NOTHING;


--
-- Name: geometry_columns_update; Type: RULE; Schema: public; Owner: -
--

CREATE RULE geometry_columns_update AS ON UPDATE TO geometry_columns DO INSTEAD NOTHING;


SET search_path = boundaries, pg_catalog;

--
-- Name: wards_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: boundaries; Owner: -
--

ALTER TABLE ONLY wards
    ADD CONSTRAINT wards_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = buildings, pg_catalog;

--
-- Name: address_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY address
    ADD CONSTRAINT address_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: building_permits_pruned_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY building_permits_pruned
    ADD CONSTRAINT building_permits_pruned_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: building_violations_pruned_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY building_violations_pruned
    ADD CONSTRAINT building_violations_pruned_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: buildings_bldg_name_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY buildings_bldg_name
    ADD CONSTRAINT buildings_bldg_name_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: buildings_nonstandard_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY buildings_nonstandard
    ADD CONSTRAINT buildings_nonstandard_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: city_owned_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY city_owned
    ADD CONSTRAINT city_owned_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: ohare_bldg_names_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY ohare_bldg_names
    ADD CONSTRAINT ohare_bldg_names_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: sqft_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY sqft
    ADD CONSTRAINT sqft_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: stories_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY stories
    ADD CONSTRAINT stories_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: university_bldg_names_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY university_bldg_names
    ADD CONSTRAINT university_bldg_names_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


--
-- Name: year_built_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: buildings; Owner: -
--

ALTER TABLE ONLY year_built
    ADD CONSTRAINT year_built_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings(bldg_gid);


SET search_path = business, pg_catalog;

--
-- Name: business_licenses_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: business; Owner: -
--

ALTER TABLE ONLY business_licenses
    ADD CONSTRAINT business_licenses_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: twitter_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: business; Owner: -
--

ALTER TABLE ONLY twitter
    ADD CONSTRAINT twitter_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = civic, pg_catalog;

--
-- Name: chi_idhs_offices_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: civic; Owner: -
--

ALTER TABLE ONLY chi_idhs_offices
    ADD CONSTRAINT chi_idhs_offices_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: circuit_court_cook_cnty_judges_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: civic; Owner: -
--

ALTER TABLE ONLY circuit_court_cook_cnty_judges
    ADD CONSTRAINT circuit_court_cook_cnty_judges_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: community_centers_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: civic; Owner: -
--

ALTER TABLE ONLY community_centers
    ADD CONSTRAINT community_centers_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: cook_co_facilities_in_chicago_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: civic; Owner: -
--

ALTER TABLE ONLY cook_co_facilities_in_chicago
    ADD CONSTRAINT cook_co_facilities_in_chicago_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: public_tech_resources_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: civic; Owner: -
--

ALTER TABLE ONLY public_tech_resources
    ADD CONSTRAINT public_tech_resources_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: senior_centers_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: civic; Owner: -
--

ALTER TABLE ONLY senior_centers
    ADD CONSTRAINT senior_centers_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: workforce_centers_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: civic; Owner: -
--

ALTER TABLE ONLY workforce_centers
    ADD CONSTRAINT workforce_centers_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: youth_centers_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: civic; Owner: -
--

ALTER TABLE ONLY youth_centers
    ADD CONSTRAINT youth_centers_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = cta, pg_catalog;

--
-- Name: rail_stations_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: cta; Owner: -
--

ALTER TABLE ONLY rail_stations
    ADD CONSTRAINT rail_stations_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = education, pg_catalog;

--
-- Name: libraries_locations_hours_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: education; Owner: -
--

ALTER TABLE ONLY libraries
    ADD CONSTRAINT libraries_locations_hours_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: private_schools_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: education; Owner: -
--

ALTER TABLE ONLY private_schools
    ADD CONSTRAINT private_schools_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: public_schools_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: education; Owner: -
--

ALTER TABLE ONLY public_schools
    ADD CONSTRAINT public_schools_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = health, pg_catalog;

--
-- Name: condom_distribution_sites_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: health; Owner: -
--

ALTER TABLE ONLY condom_distribution_sites
    ADD CONSTRAINT condom_distribution_sites_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: dentists_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: health; Owner: -
--

ALTER TABLE ONLY dentists
    ADD CONSTRAINT dentists_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: hospitals_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: health; Owner: -
--

ALTER TABLE ONLY hospitals
    ADD CONSTRAINT hospitals_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: mental_health_clinics_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: health; Owner: -
--

ALTER TABLE ONLY mental_health_clinics
    ADD CONSTRAINT mental_health_clinics_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: neighborhood_health_clinics_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: health; Owner: -
--

ALTER TABLE ONLY neighborhood_health_clinics
    ADD CONSTRAINT neighborhood_health_clinics_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: sti_specialty_clinics_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: health; Owner: -
--

ALTER TABLE ONLY sti_specialty_clinics
    ADD CONSTRAINT sti_specialty_clinics_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = history, pg_catalog;

--
-- Name: historic_resources_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: history; Owner: -
--

ALTER TABLE ONLY historic_resources
    ADD CONSTRAINT historic_resources_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: landmarks_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: history; Owner: -
--

ALTER TABLE ONLY landmarks
    ADD CONSTRAINT landmarks_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = public, pg_catalog;

--
-- Name: height_ft_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roof_height
    ADD CONSTRAINT height_ft_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = safety, pg_catalog;

--
-- Name: fire_stations_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: safety; Owner: -
--

ALTER TABLE ONLY fire_stations
    ADD CONSTRAINT fire_stations_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: life_safety_evaluations_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: safety; Owner: -
--

ALTER TABLE ONLY life_safety_evaluations
    ADD CONSTRAINT life_safety_evaluations_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: police_stations_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: safety; Owner: -
--

ALTER TABLE ONLY police_stations
    ADD CONSTRAINT police_stations_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


SET search_path = tif, pg_catalog;

--
-- Name: sbif_grant_agreements_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: tif; Owner: -
--

ALTER TABLE ONLY sbif_grant_agreements
    ADD CONSTRAINT sbif_grant_agreements_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: sbif_grant_agreements_tif_id_fkey; Type: FK CONSTRAINT; Schema: tif; Owner: -
--

ALTER TABLE ONLY sbif_grant_agreements
    ADD CONSTRAINT sbif_grant_agreements_tif_id_fkey FOREIGN KEY (tif_id) REFERENCES tif_districts(tif_id);


--
-- Name: taxcode_tif_id_fkey; Type: FK CONSTRAINT; Schema: tif; Owner: -
--

ALTER TABLE ONLY taxcode
    ADD CONSTRAINT taxcode_tif_id_fkey FOREIGN KEY (tif_id) REFERENCES tif_status_eligibility(tif_id);


--
-- Name: tif_balance_sheets_tif_id_fkey; Type: FK CONSTRAINT; Schema: tif; Owner: -
--

ALTER TABLE ONLY tif_balance_sheets
    ADD CONSTRAINT tif_balance_sheets_tif_id_fkey FOREIGN KEY (tif_id) REFERENCES tif_districts(tif_id);


--
-- Name: tif_projection_reports_tif_id_fkey; Type: FK CONSTRAINT; Schema: tif; Owner: -
--

ALTER TABLE ONLY tif_projection_reports
    ADD CONSTRAINT tif_projection_reports_tif_id_fkey FOREIGN KEY (tif_id) REFERENCES tif_districts(tif_id);


SET search_path = transportation, pg_catalog;

--
-- Name: metra_stations_bldg_gid_fkey; Type: FK CONSTRAINT; Schema: transportation; Owner: -
--

ALTER TABLE ONLY metra_stations
    ADD CONSTRAINT metra_stations_bldg_gid_fkey FOREIGN KEY (bldg_gid) REFERENCES buildings.buildings(bldg_gid);


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

