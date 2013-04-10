# coding: utf-8

# third party libraries
import psycopg2

# our stuff
import benefice_setup
import util.import_helpers as import_helpers
from datasets_core import datasets_core
from datasets_secondary import datasets_secondary

# Handle --create_template [reconstruction of base_postgis template using the postgres superuser account]
def create_template():
  try:
    (major_version, minor_version) = import_helpers.get_postgres_version()
  except OSError as e:
    print "Cannot find pg_config. Please include the location of your pg_config binary in the flag --bindir."
    sys.exit(1)

  print 'Initializing postgres with a basic PostGIS template using the postgres superuser.'
  # See if database base_postgis exists
  db_names = import_helpers.get_postgres_database_list()
  print "db_names is ", db_names
  print "BENEFICE_DB is ", benefice_setup.BENEFICE_DB
  if (benefice_setup.BENEFICE_DB in db_names):
    print("Deleting the MAIN benefice database in '%s'!" % benefice_setup.BENEFICE_DB)
    import_helpers.call_or_fail("dropdb",user=benefice_setup.POSTGRES_SUPERUSER, interactive=True, argument=benefice_setup.BENEFICE_DB)

  # We should drop the benefice user (we will be recreating it and its roles).
  #if (BENEFICE_USER != 'postgres'):
  #  # XXX: this could be potentially uncool if the client has a superuser not called 'postgres'?
  #  import_helpers.call_or_fail("dropuser", user=POSTGRES_SUPERUSER, interactive=True, argument=BENEFICE_USER)
  
  if('base_postgis' in db_names):
    # Make base_postgis deleteable
    import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER, database="postgres", sql_command="UPDATE pg_database SET datistemplate='false' WHERE datname='base_postgis';")
    import_helpers.call_or_fail("dropdb", user=benefice_setup.POSTGRES_SUPERUSER, interactive=True, argument="base_postgis")

  # This could be template1, except I was having problems with my template1 being in ASCII explictly on a 9.0 install
  import_helpers.call_or_fail("createdb", user=benefice_setup.POSTGRES_SUPERUSER, template="template0", encoding="UTF8", argument= "base_postgis")

  # Note: This doesn't seem necessary, as the templates in 9.0 and 9.2 seem to have this included.
  # import_helpers.call_or_fail("createlang plpgsql base_postgis")

  if (minor_version == 0):
    # Get the sharedir from pg_config and verify the existence of postgis.sql and spatial_ref_sys.sql
    share_dirname = import_helpers.get_postgres_sharedir()
    print "share_dirname is " , share_dirname

    postgis_fnames = []
    postgis_basenames = ['postgis.sql', 'postgis_comments.sql', 'spatial_ref_sys.sql']
    # Optional postgis scripts not currently included in base install:
    # raster_comments.sql, rtpostgis.sql, topology.sql, topology_comments.sql
    for postgis_basename in postgis_basenames:
      fname = os.path.join(share_dirname, 'contrib/postgis-2.0/%s' % postgis_basename)
      if (not os.path.isfile(fname)):
        print "Can't find contrib/postgis-2.0/%s in %s: is PostGIS 2.0.x+ installed?" % (postgis_basename, share_dirname)
        sys.exit(1)
      else:
        postgis_fnames.append(fname)

    for fname in postgis_fnames:
      import_helpers.call_or_fail('psql', user=benefice_setup.POSTGRES_SUPERUSER, database="base_postgis", fname=fname)

    import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER, database="postgres", sql_command ="UPDATE pg_database SET datistemplate='true' WHERE datname='base_postgis';")

  elif (minor_version >= 1):
    # Instead of the above, just do 'CREATE EXTENSION postgis' if we are using 9.1 or later
    import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER,database="base_postgis", sql_command= "CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;")
    import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER, database="postgres", sql_command="UPDATE pg_database SET datistemplate='true' WHERE datname='base_postgis';")
                      
  # Allow non-superusers to alter spatial tables
  import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER, database="base_postgis", sql_command="GRANT ALL ON geometry_columns TO PUBLIC;")
  import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER, database="base_postgis", sql_command="GRANT ALL ON geography_columns TO PUBLIC;")
  import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER, database="base_postgis", sql_command="GRANT ALL ON spatial_ref_sys TO PUBLIC;")

  # Finally, give a user 'benefice' permission to alter the database with 'createdb' permission
  # Note: This does not check to see if a 'benefice' user already exists.
  import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER, database="base_postgis", sql_command="CREATE USER %s;" % benefice_setup.BENEFICE_USER)
  import_helpers.call_or_fail("psql", user=benefice_setup.POSTGRES_SUPERUSER, database="base_postgis", sql_command="ALTER USER %s createdb;" % benefice_setup.BENEFICE_USER)

# Handle --create [reconstruction of benefice database using the benefice user account]  
def create():
  print 'Setting up benefice database from scratch.'

  import_helpers.call_or_fail("dropdb", user=benefice_setup.BENEFICE_USER, interactive=True, argument=benefice_setup.BENEFICE_DB)
  import_helpers.call_or_fail("createdb", user=benefice_setup.BENEFICE_USER, template="base_postgis", argument=benefice_setup.BENEFICE_DB)

  # XXX: Is it not necessary to make benefice the owner of these tables inherited from base_postgis?
  #import_helpers.call_or_fail("psql", user=POSTGRES_SUPERUSER, database=BENEFICE_DB, sql_command="ALTER TABLE geometry_columns OWNER TO benefice;")
  #import_helpers.call_or_fail("psql", user=POSTGRES_SUPERUSER, database=BENEFICE_DB, sql_command="ALTER TABLE geography_columns OWNER TO benefice;")
  #import_helpers.call_or_fail("psql", user=POSTGRES_SUPERUSER, database=BENEFICE_DB, sql_command="ALTER TABLE spatial_ref_sys OWNER TO benefice;")
  
  import_helpers.call_or_fail("psql", user=benefice_setup.BENEFICE_USER, database=benefice_setup.BENEFICE_DB, fname="sql_init_scripts/pins_master.sql")
  # Not sure why we were creating these specific tables from benefice_initialization_script in advance.
  # import_helpers.call_or_fail("psql", user=BENEFICE_USER,database=BENEFICE_DB, fname="sql_init_scripts/assessed.sql")
  #import_helpers.call_or_fail("psql", user=BENEFICE_USER, database=BENEFICE_DB, fname="sql_init_scripts/edifice_initialization_script.sql")

  import_helpers.call_or_fail("psql", user=benefice_setup.BENEFICE_USER, database=benefice_setup.BENEFICE_DB, sql_command="CREATE SCHEMA dataportal;")
  
def data():
  # Connect to the db
  print "Connecting to database '%s' with user '%s'" % (benefice_setup.BENEFICE_DB, benefice_setup.BENEFICE_USER)
  try:
    benefice_setup.DB_CONN=psycopg2.connect(database=benefice_setup.BENEFICE_DB, user=benefice_setup.BENEFICE_USER)
    benefice_setup.DB_CONN.set_session(autocommit=True) # Crucial so that we don't have really long-running transaction sequences
  except psycopg2.OperationalError as e:
    print e
    sys.exit(1)
  
  print "Importing core datasets from open data portals. this will take a while..."
  for d in datasets_core:
    import_helpers.process_data(d)

  # disabling this until we get our core buildings datasets loaded
  # print "Importing secondary datasets from open data portals. this will take a while..."
  # for d in datasets_secondary:
  #   process_data(d)

  benefice_setup.DB_CONN.close()
  print '======= Done! Happy Beneficing! ======='
  print "To get started, type 'psql benefice'"