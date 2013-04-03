# coding: utf-8
import argparse
import os
import subprocess
from subprocess import call, check_call, Popen, CalledProcessError
import glob
from datasets_core import datasets_core
from datasets_secondary import datasets_secondary
import sys
import re
import string
import zipfile
import csv
import httplib, json, psycopg2
import data_portal
from util.import_table import get_csv_column_types, get_create_table
from util.setup import read_setup

config = read_setup('setup.cfg')

try:
  BENEFICE_USER       = config['BENEFICE_USER']
  BENEFICE_DB         = config['BENEFICE_DB'] 
  POSTGRES_BINDIRNAME = config['POSTGRES_BINDIRNAME'] 
  POSTGRES_SUPERUSER  = config['POSTGRES_SUPERUSER'] 
  POSTGRES_HOST       = config['POSTGRES_HOST'] 
  DELETE_DOWNLOADS    = config['DELETE_DOWNLOADS']
except KeyError:
  print('Invalid config database')
  sys.exit(1)

# Start out with no psycopg2 connection, make it during data import ('--data')
DB_CONN = None

# Optional argument for directory location of pg_config
def get_postgres_version(bindir=None):
  pgconfig_str = 'pg_config'
  try:
    if (bindir):
      pgconfig = os.path.join(bindir, pgconfig_str)
    cmd = '%s --version' % pgconfig_str
    pg_config_out = Popen(cmd.split(), stdout=subprocess.PIPE)
    line = pg_config_out.stdout.readline()
    line = line.rstrip()
    # regex match for, e.g., "PostgresSQL 9.0.11"
    m= re.match('PostgreSQL (\d+)\\.?(\d+)\\.?(\\*|\d+)$', line)
    try:
      major_version = int(m.group(1))
      minor_version = int(m.group(2))
      if (major_version < 9):
        print "PostgreSQL version 9.0.x or greater is required."
        sys.exit(1)
      else:
        return (major_version, minor_version)
    except IndexError as index_error:
      print "Can't parse version string:", l
      sys.exit(1)
  except OSError as os_error:
      raise
  except CalledProcessError as e:
    print e.output
    sys.exit(1)

def get_postgres_database_list():
  db_names = []
  cmd = Popen('psql --list'.split(), stdout=subprocess.PIPE)
  lines = cmd.stdout.readlines()[3:]
  for line in lines:
    line = line.strip()
    line_split = line.split()
    if (line_split[0] == '|' and (len(line_split[0]) == 1)): # assume there is no database titled '|'
      return db_names
    curr_db_name = line_split[0]
    db_names.append(curr_db_name)
  return db_names
  
def get_postgres_sharedir():
  cmd = Popen('pg_config --sharedir', shell=True, stdout=subprocess.PIPE)
  line = cmd.stdout.readline()
  return line.rstrip()

def call_args_or_fail(cmd_args_list):
  print ' '.join(cmd_args_list)
  try:
    retval = call(cmd_args_list,stderr=subprocess.STDOUT)
  except CalledProcessError as e:
    print e.output
    sys.exit(1)
  except KeyboardInterrupt:
    print "\n" + "Ctrl-C'd by user"
    sys.exit(1)
    
def call_or_fail(cmd, user=None, interactive=False, template=None, encoding=None, database=None, fname=None, sql_command=None, argument=None):
    global POSTGRES_HOST
  
    psql_split = cmd.split()
    if (user):
      psql_split.extend(["-U",user])

    # add host flag automatically
    psql_split.extend(["-h", POSTGRES_HOST])

    if (interactive):
      psql_split.append("--interactive")

    if (template):
      psql_split.extend(["-T",template])

    if (encoding):
      psql_split.extend(["-E",encoding])

    if (database):
        psql_split.extend(["-d",database])

    if (fname):
      psql_split.extend(["-f",fname])
      
    if (sql_command):
      psql_split.extend(["-c","%s" % sql_command])

    if ((cmd == 'dropdb') or (cmd == 'createdb') or (cmd=='dropuser')):
      if not argument:
        print "Argument not specified in call to %s" % cmd
        sys.exit(1)
      else:
        psql_split.append(argument)

    call_args_or_fail(psql_split)

# This just takes a command without wrapping the args as in call_or_fail() above.
def call_raw_or_fail(cmd):
  call_args_or_fail(cmd.split())

def process_data(dataset):
  name =        dataset[0]
  domain =      dataset[1]
  data_type =   dataset[2]
  socrata_id =  dataset[3]
  options =     dataset[4]

  url = ''

  data_portal_url = 'data.cityofchicago.org'
  if (domain == 'Cook County'):
    data_portal_url = 'data.cookcountyil.gov'
  elif (domain == 'Illinois'):
    data_portal_url = 'data.illinois.gov'

  if data_type == 'pgdump':
    import_pgdump(name)
  elif data_type == 'shp':
    url = "http://%s/download/%s/application/zip" % (data_portal_url, socrata_id)
    if 'platform' in options and options['platform'] == 'mondara':
      url = "https://%s/api/geospatial/%s?method=export&format=Shapefile" % (data_portal_url, socrata_id)
    
    import_shp(name, url, options.setdefault('encoding',''))
  elif data_type == 'csv':
    import_csv(name, data_portal_url, socrata_id, options.setdefault('encoding',''))
  elif data_type == 'json':
    import_json(name, data_portal_url, socrata_id, options.setdefault('encoding',''))
  else:
    print 'ERROR: unknown domain or data type', data_type, 'for', name

def import_pgdump (name):
  download_name = "%s.dump" % os.path.join('downloads', name)

  if os.path.exists(download_name):
    print "Note: %s already exists. Not fetching it." % name
  else:
    print 'Fetching %s ...' % name
    call_args_or_fail("wget -O %s https://s3.amazonaws.com/edifice/%s".split() % (download_name, name))
  print "Loading..."
  call_raw_or_fail("pg_restore -U %s --role=%s -h %s -O -d %s %s" % (BENEFICE_USER, BENEFICE_USER, POSTGRES_HOST, BENEFICE_DB, download_name))

  if (DELETE_DOWNLOADS):
    os.remove(download_name)

def import_csv(name, hostname, socrata_id, options):
  dbname = 'dataportal' # import csvs directly to the intermediary 'dataportal' table
  
  #https://data.cityofchicago.org/api/ydr8-5enu.json
  #columntypes_json_url = "http://%s/api/%s.json" %(hostname, socrata_id)
  #create_csvtable_via_json(name, columntypes_json_url)
  #import_json(name, hostname, socrata_id, options)
  #https://data.cityofchicago.org/api/views/ydr8-5enu/rows.csv?accessType=DOWNLOAD

  url = "http://%s/api/views/%s/rows.csv" % (hostname, socrata_id)

  name_csv = "%s.csv" % os.path.join('downloads', name)
  if not os.path.exists(name_csv) :
    cmd_split = "wget --no-check-certificate -O".split()
    cmd_split.append(name_csv)
    cmd_split.append(url)
    call_args_or_fail(cmd_split)
  else :
    print '%s exists, skipping download' % name_csv

  print "TODO: csv import using column types"
  csv_col_types =  get_csv_column_types(name_csv)
  create_table_sql = get_create_table(dbname, name, csv_col_types)

  drop_table_sql = "DROP TABLE %s.%s" % (dbname, name)
  print drop_table_sql
  cur=DB_CONN.cursor()
  try:    
    cur.execute(drop_table_sql)
  except psycopg2.ProgrammingError: 
    DB_CONN.rollback()
  else:   
    DB_CONN.commit()

  print "create table command: ", create_table_sql
  cur=DB_CONN.cursor()
  cur.execute(create_table_sql)

  # hack to use 'psql -c' to insert the rows
  #sql_cmd = "\copy street_gazetteer FROM 'downloads/street_gazetteer.csv' WITH CSV HEADER"
  sql_cmd = "\copy %s.%s FROM '%s' WITH CSV HEADER" % (dbname, name, name_csv)
  print "calling '%s'" % sql_cmd
  call_or_fail("psql", user=BENEFICE_USER, database=BENEFICE_DB, sql_command=sql_cmd)




def import_json (name, hostname, socrata_id, options):
  # Get the header information
  conn = httplib.HTTPConnection(hostname)
  conn.request('GET','/api/views/%s.json' % (socrata_id,))
  r1 = conn.getresponse()
  # Make sure it succeeded
  assert r1.status==200
  resp=json.loads(r1.read())
  # Make sure it has columns
  assert u'columns' in resp.keys()

  # Start building the db command
  db_command_args=[name]
  db_command='CREATE TABLE %s ( '

  # Loop through columns, adding appropriate arguments to db command.
  for column in resp[u'columns']:
    db_command=db_command+'%s %s,'
    db_command_args.append(column[u'fieldName'])
    field_type=column[u'dataTypeName']
    if field_type==u'number':
      if ('.' not in column[u'cachedContents'][u'smallest']) and \
         ('.' not in column[u'cachedContents'][u'largest'])  and \
         ('.' not in column[u'cachedContents'][u'sum']):
        db_command_args.append('integer')
      else:
        db_command_args.append('double precision')
    elif field_type==u'calendar_date':
      db_command_args.append('date')
    elif field_type==u'checkbox':
      db_command_args.append('boolean')
    else:
      db_command_args.append('text')

  # Cut off the last comma and close off the command.
  db_command=db_command[:-1]+');'

  cur=DB_CONN.cursor()
  cur.execute(db_command,db_command_args)

# Function to wget, unzip, shp2pgsql | psql, and rm in the subdirectory 'import/'
def import_shp (name, url, encoding):
  global BENEFICE_USER
  global BENEFICE_DB
  global DELETE_DOWNLOADS
  global DB_CONN
  
  name_zip = "%s.zip" % os.path.join('downloads', name)
  
  if not os.path.exists(name_zip) :
    cmd_split = "wget --no-check-certificate -O".split()
    cmd_split.append(name_zip)
    cmd_split.append(url)
    call_args_or_fail(cmd_split)
  else :
    print '%s exists, skipping download' % name_zip

  zip_file = None
  try:
    zip_file = zipfile.ZipFile(name_zip, 'r')
  except zipfile.BadZipfile as e:
    print "ERROR:", str(e)
    print "Try removing file %s and running --data again." % name_zip
    sys.exit(1)
  first_bad_file = zip_file.testzip()
  if (first_bad_file):
    print "Error in %s: first bad file is %s" % name_zip, first_bad_file
    sys.exit(1)
  inside_zip_fnames = zip_file.namelist()
  files_exist = True
  for inside_zip_fname in inside_zip_fnames:
    if not os.path.exists(os.path.join('downloads',inside_zip_fname)):
      files_exist = False
      break
  
  if (files_exist):
    # don't go through with unzipping / inserting if the contents of the zip file already exist in the downloads/ directory.
    print "not unzipping, files already exist"
    return
    
  print 'extracting %s' % name_zip
  zip_file_contents = zip_file.namelist()
  for f in zip_file_contents:
    zip_file.extract(f, 'import')
  zip_file.close()

  shapefile = None
  for fname in glob.glob("import/*.shp"):
      shapefile_name = fname
      print 'Importing ', shapefile_name
      if encoding:
        encoding = '-W ' + encoding

      shp2pgsql_cmd= 'shp2pgsql -d -s 3435 %s -g the_geom -I %s dataportal.%s' % (encoding, shapefile_name, name)
      shp2pgsql_cmd_list = shp2pgsql_cmd.split()
      psql_cmd = "psql -q -U %s -d %s" % (BENEFICE_USER, BENEFICE_DB)
      p1 = Popen(shp2pgsql_cmd_list, stdout=subprocess.PIPE)
      print shp2pgsql_cmd, "|", psql_cmd
      p2 = Popen(psql_cmd.split(), stdin=p1.stdout, stdout=subprocess.PIPE)
      stdout = p2.communicate()[0]

  # Now do the specialized import for the given dataset
  # data_portal.do_import(name, DB_CONN)

  # Great. Now delete all the files in zip_file_contents
  if DELETE_DOWNLOADS:
    for fname in glob.glob('import/*'):
      print "Deleting:", fname
      os.remove(fname)

    print "deleting %s" % name_zip
    os.remove(name_zip)

def main():
  global BENEFICE_USER 
  global BENEFICE_DB
  global POSTGRES_BINDIRNAME
  global POSTGRES_SUPERUSER
  global POSTGRES_HOST
  global DELETE_DOWNLOADS
  global DB_CONN

  parser = argparse.ArgumentParser(description='Setup the PostGIS Benefice database and populate it with open datasets.')
  parser.add_argument('--create_template', action='store_true',
                      help="Run only once to create a base postgis template ('base_postgis') as the postgres superuser")
  parser.add_argument('--create', action='store_true',
                      help='Drop existing benefice database and create from scratch based on the base_postgis database created with --create_template')
  parser.add_argument('--data', action='store_true',
                      help='Download and import City of Chicago data to benefice database (as listed in datasets.py)')
  parser.add_argument('--bindir', nargs='?', type=str,
                      help='Directory location of PostgreSQL binaries (e.g. pg_config, psql)')
  parser.add_argument('--user', nargs='?', type=str, 
                      help="Postgres username for accessing benefice database (e.g. during --create or --data) [default: 'benefice']")
  parser.add_argument('--superuser', nargs='?', type=str, 
                      help="Postgres superuser name for creating benefice database (e.g. during --create_template) [default: 'postgres']")
  parser.add_argument('--host', nargs='?', type=str, 
                      help="Postgres host [default: 'localhost']")
  parser.add_argument('--database', nargs='?', type=str,
                      help="Name for benefice database [default: 'benefice']")
  parser.add_argument('--delete_downloads', action='store_true',
                      help="Keep files downloaded from the various data portals after they have been imported [default: False]")
  args = parser.parse_args()

  # Handle --bindir [directory w/ postgres binaries]
  if args.bindir:
    POSTGRES_BINDIRNAME = args.bindir

    # Check if we can find pg_config in this directory. If this fails, we can't find it.
    try:
      (major_version, minor_version) = get_postgres_version(POSTGRES_BINDIRNAME)
    except OSError as e:
      print "Cannot find pg_config in specified directory: %s" % POSTGRES_BINDIRNAME
      sys.exit(1)
      
    # We know we have the right directory, let's just modify this process' PATH to have this directory first.
    # Not exactly kosher but more straightforward than pasting POSTGRES_BINDIRNAME everywhere we exec 'psql'
    os.environ['PATH'] = POSTGRES_BINDIRNAME + ":" + os.environ['PATH']

  if args.user:
    BENEFICE_USER = args.user

  if args.superuser:
    POSTGRES_SUPERUSER = args.superuser

  if args.database:
    BENEFICE_DB = args.database

  if args.delete_downloads:
    DELETE_DOWNLOADS = args.delete_downloads

  # Handle --create_template [reconstruction of base_postgis template using the postgres superuser account]
  if args.create_template:
    try:
      (major_version, minor_version) = get_postgres_version()
    except OSError as e:
      print "Cannot find pg_config. Please include the location of your pg_config binary in the flag --bindir."
      sys.exit(1)

    print 'Initializing postgres with a basic PostGIS template using the postgres superuser.'
    # See if database base_postgis exists
    db_names = get_postgres_database_list()
    print "db_names is ", db_names
    print "BENEFICE_DB is " ,BENEFICE_DB
    if (BENEFICE_DB in db_names):
      print("Deleting the MAIN benefice database in '%s'!" % BENEFICE_DB)
      call_or_fail("dropdb",user=POSTGRES_SUPERUSER, interactive=True, argument=BENEFICE_DB)

    # We should drop the benefice user (we will be recreating it and its roles).
    #if (BENEFICE_USER != 'postgres'):
    #  # XXX: this could be potentially uncool if the client has a superuser not called 'postgres'?
    #  call_or_fail("dropuser", user=POSTGRES_SUPERUSER, interactive=True, argument=BENEFICE_USER)
    
    if('base_postgis' in db_names):
      # Make base_postgis deleteable
      call_or_fail("psql", user=POSTGRES_SUPERUSER, database="postgres", sql_command="UPDATE pg_database SET datistemplate='false' WHERE datname='base_postgis';")
      call_or_fail("dropdb", user=POSTGRES_SUPERUSER, interactive=True, argument="base_postgis")

    # This could be template1, except I was having problems with my template1 being in ASCII explictly on a 9.0 install
    call_or_fail("createdb", user=POSTGRES_SUPERUSER, template="template0", encoding="UTF8", argument= "base_postgis")

    # Note: This doesn't seem necessary, as the templates in 9.0 and 9.2 seem to have this included.
    # call_or_fail("createlang plpgsql base_postgis")

    if (minor_version == 0):
      # Get the sharedir from pg_config and verify the existence of postgis.sql and spatial_ref_sys.sql
      share_dirname = get_postgres_sharedir()
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
        call_or_fail('psql', user=POSTGRES_SUPERUSER, database="base_postgis", fname=fname)

      call_or_fail("psql", user=POSTGRES_SUPERUSER, database="postgres", sql_command ="UPDATE pg_database SET datistemplate='true' WHERE datname='base_postgis';")

    elif (minor_version >= 1):
      # Instead of the above, just do 'CREATE EXTENSION postgis' if we are using 9.1 or later
      call_or_fail("psql", user=POSTGRES_SUPERUSER,database="base_postgis", sql_command= "CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;")
      call_or_fail("psql", user=POSTGRES_SUPERUSER, database="postgres", sql_command="UPDATE pg_database SET datistemplate='true' WHERE datname='base_postgis';")
                        
    # Allow non-superusers to alter spatial tables
    call_or_fail("psql", user=POSTGRES_SUPERUSER, database="base_postgis", sql_command="GRANT ALL ON geometry_columns TO PUBLIC;")
    call_or_fail("psql", user=POSTGRES_SUPERUSER, database="base_postgis", sql_command="GRANT ALL ON geography_columns TO PUBLIC;")
    call_or_fail("psql", user=POSTGRES_SUPERUSER, database="base_postgis", sql_command="GRANT ALL ON spatial_ref_sys TO PUBLIC;")

    # Finally, give a user 'benefice' permission to alter the database with 'createdb' permission
    # Note: This does not check to see if a 'benefice' user already exists.
    call_or_fail("psql", user=POSTGRES_SUPERUSER, database="base_postgis", sql_command="CREATE USER %s;" % BENEFICE_USER)
    call_or_fail("psql", user=POSTGRES_SUPERUSER, database="base_postgis", sql_command="ALTER USER %s createdb;" % BENEFICE_USER)

  # Handle --create [reconstruction of benefice database using the benefice user account]
  if args.create :
    print 'Setting up benefice database from scratch.'

    call_or_fail("dropdb", user=BENEFICE_USER, interactive=True, argument=BENEFICE_DB)
    call_or_fail("createdb", user=BENEFICE_USER, template="base_postgis", argument=BENEFICE_DB)

    # XXX: Is it not necessary to make benefice the owner of these tables inherited from base_postgis?
    #call_or_fail("psql", user=POSTGRES_SUPERUSER, database=BENEFICE_DB, sql_command="ALTER TABLE geometry_columns OWNER TO benefice;")
    #call_or_fail("psql", user=POSTGRES_SUPERUSER, database=BENEFICE_DB, sql_command="ALTER TABLE geography_columns OWNER TO benefice;")
    #call_or_fail("psql", user=POSTGRES_SUPERUSER, database=BENEFICE_DB, sql_command="ALTER TABLE spatial_ref_sys OWNER TO benefice;")
  
    call_or_fail("psql", user=BENEFICE_USER, database=BENEFICE_DB, fname="sql_init_scripts/pins_master.sql")
    # Not sure why we were creating these specific tables from benefice_initialization_script in advance.
    # call_or_fail("psql", user=BENEFICE_USER,database=BENEFICE_DB, fname="sql_init_scripts/assessed.sql")
    #call_or_fail("psql", user=BENEFICE_USER, database=BENEFICE_DB, fname="sql_init_scripts/edifice_initialization_script.sql")

    call_or_fail("psql", user=BENEFICE_USER, database=BENEFICE_DB, sql_command="CREATE SCHEMA dataportal;")
  
  if args.data:
    # Connect to the db
    print "Connecting to database '%s' with user '%s'" % (BENEFICE_DB, BENEFICE_USER)
    try:
      DB_CONN=psycopg2.connect(database=BENEFICE_DB, user=BENEFICE_USER)
      DB_CONN.set_session(autocommit=True) # Crucial so that we don't have really long-running transaction sequences
    except psycopg2.OperationalError as e:
      print e
      sys.exit(1)
  
    print "Importing core datasets from open data portals. this will take a while..."
    for d in datasets_core:
      process_data(d)

    # disabling this until we get our core buildings datasets loaded
    # print "Importing secondary datasets from open data portals. this will take a while..."
    # for d in datasets_secondary:
    #   process_data(d)

    DB_CONN.close()
    print '======= Done! Happy Beneficing! ======='
    print "To get started, type 'psql benefice'"

  # if no actionable args, print out help message!
  if ((not args.create_template) and (not args.create) and (not args.data)):
    parser.print_help()

if __name__ == "__main__":
    main()
