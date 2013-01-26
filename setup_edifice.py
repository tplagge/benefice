# coding: utf-8
import argparse
import os
import subprocess
from subprocess import call, check_call, Popen, CalledProcessError
import glob
from datasets import datasets
import sys
import re
import string
import zipfile

EDIFICE_USER = 'edifice'
EDIFICE_DB = 'edifice'
POSTGRES_BINDIRNAME = None

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
    call(cmd_args_list,stderr=subprocess.STDOUT)
  except CalledProcessError as e:
    print e.output
    sys.exit(1)
  except KeyboardInterrupt:
    print "\n" + "Ctrl-C'd by user"
    sys.exit(1)
    
def call_or_fail(cmd):
  call_args_or_fail(cmd.split())

# For running SQL commands via psql -c
def call_psql_or_fail(psql_cmd, sql_cmd):
    psql_split = psql_cmd.split()
    psql_split.append("-c " + sql_cmd)
    call_args_or_fail(psql_split)

def process_data(dataset):
  name =        dataset[0]
  domain =      dataset[1]
  data_type =   dataset[2]
  socrata_id =  dataset[3]
  options =     dataset[4]

  url = ''
  # format: https://data.cityofchicago.org/download/5gv8-ktcg/application/zip
  if (domain == 'Chicago' and data_type == 'shp'):
    url = "http://data.cityofchicago.org/download/%s/application/zip" % (socrata_id,)

  import_shp(name, url, options)

# Function to wget, unzip, shp2pgsql | psql, and rm in the subdirectory 'import/'
def import_shp (name, url, encoding):
  name_zip = "%s.zip" % name

  if not os.path.exists('import'):
    os.makedirs('import')
  
  cmd_split = "wget --no-check-certificate -O".split()
  cmd_split.append(name_zip)
  cmd_split.append(url)
  call_args_or_fail(cmd_split)
  
  try:
    zip_file = zipfile.ZipFile(name_zip, 'r')
  except zipfile.BadZipfile as e:
    print "ERROR:", str(e)
    sys.exit(1)
  first_bad_file = zip_file.testzip()
  if (first_bad_file):
    print "Error in %s: first bad file is %s" % name_zip, first_bad_file
    sys.exit(1)
  
  zip_file_contents = zip_file.namelist()
  for f in zip_file_contents:
    zip_file.extract(f, 'import')
  zip_file.close()
  
  shapefile = None
  for fname in glob.glob("import/*.shp"):
      shapefile_name = fname
      print 'importing ', shapefile_name
      print type(shapefile_name)
      shp2pgsql_cmd= 'shp2pgsql -d -s 3435 -W LATIN1 -g the_geom -I %s' % shapefile_name
      shp2pgsql_cmd_list = shp2pgsql_cmd.split()
      psql_cmd = "psql -q -U %s -d %s" % (EDIFICE_USER, EDIFICE_DB)
      p1 = Popen(shp2pgsql_cmd_list, stdout=subprocess.PIPE)
      print shp2pgsql_cmd, "|", psql_cmd
      p2 = Popen(psql_cmd.split(), stdin=p1.stdout, stdout=subprocess.PIPE)
      stdout = p2.communicate()[0]

  # Great. Now delete all the files in zip_file_contents
  for fname in glob.glob('import/*'):
    print "Deleting:", fname
    os.remove(fname)


parser = argparse.ArgumentParser(description='Setup the PostGIS Edifice database and populate it with open datasets.')
parser.add_argument('--init', action='store_true',
                   help="Run only once to create a base postgis template ('base_postgis') as the postgres superuser")
parser.add_argument('--create', action='store_true',
                   help='Drop existing edifice database and create from scratch based on the base_postgis database created with --init')
parser.add_argument('--data', action='store_true',
                   help='Download and import City of Chicago data to edifice database (as listed in datasets.py)')
parser.add_argument('--bindir', nargs='?', type=str,
                    help='Directory location of PostgreSQL binaries (e.g. pg_config, psql)')
parser.add_argument('--user', nargs='?', type=str, 
                   help="Postgres username for creating/accessing edifice database (e.g. during --create or --data) [default: 'edifice']")
parser.add_argument('--database', nargs='?', type=str,
                   help="Name for edifice database [default: 'edifice']")
args = parser.parse_args()

# Handle --bindir [directory w/ postgres binaries]
if args.bindir:
  print "args.bindir=", args.bindir
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
  EDIFICE_USER = args.user

if args.database:
  EDIFICE_DB = args.database

# Handle --init [reconstruction of base_postgis template using the postgres superuser account]
if args.init:
  try:
    (major_version, minor_version) = get_postgres_version()
  except OSError as e:
    print "Cannot find pg_config. Please include the location of your pg_config binary in the flag --bindir."
    sys.exit(1)

  print 'Initializing postgres with a basic PostGIS template using the postgres superuser.'
  # See if database base_postgis exists
  db_names = get_postgres_database_list()
  if ('%s' % EDIFICE_DB in db_names):
    print("Deleting the MAIN edifice database in '%s'!" % EDIFICE_DB)
    call_or_fail("dropdb -U postgres --interactive %s" % EDIFICE_DB)
    
  if('base_postgis' in db_names):
    # Make base_postgis deleteable
    call_psql_or_fail("psql -U postgres -d postgres", "UPDATE pg_database SET datistemplate='false' WHERE datname='base_postgis';")
    call_or_fail("dropdb -U postgres --interactive base_postgis")

  # This could be template1, except I was having problems with my
  # template1 being in ASCII explictly on my 9.0 install
  call_or_fail("createdb -U postgres -T template0 -E UTF8 base_postgis" )

  # Note: This doesn't seem necessary as the templates in 9.0 and 9.2 seem to have this included.
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
        print "Can't find contrib/postgis-2.0/%s in %s: is PostGIS 2.0.x+ installed?" % (fname, share_dirname)
        sys.exit(1)
      else:
        postgis_fnames.append(fname)

    postgis_sql_cmds = []
    for fname in postgis_fnames:  
      postgis_sql_cmds.append('psql -U postgres -d base_postgis -f %s' % fname)

    for cmd in postgis_sql_cmds:
      call_or_fail(cmd)

    call_psql_or_fail("psql -U postgres -d postgres", "UPDATE pg_database SET datistemplate='true' WHERE datname='base_postgis';")

  elif (minor_version >= 1):
    # Instead of the above, just do 'CREATE EXTENSION postgis' if we are using 9.1 or later
    call_psql_or_fail("psql -U postgres -d base_postgis", "CREATE EXTENSION postgis;")
    call_psql_or_fail("psql -U postgres -d postgres", "UPDATE pg_database SET datistemplate='true' WHERE datname='base_postgis';")
                      
  # Allow non-superusers to alter spatial tables
  call_psql_or_fail("psql -U postgres -d base_postgis","GRANT ALL ON geometry_columns TO PUBLIC;")
  call_psql_or_fail("psql -U postgres -d base_postgis", "GRANT ALL ON geography_columns TO PUBLIC;")
  call_psql_or_fail("psql -U postgres -d base_postgis", "GRANT ALL ON spatial_ref_sys TO PUBLIC;")

  # Finally, give a user 'edifice' permission to alter the database with 'createdb' permission
  # Note: This does not check to see if a 'edifice' user already exists.
  call_psql_or_fail("psql -U postgres -d base_postgis", "CREATE USER %s;" % EDIFICE_USER)
  call_psql_or_fail("psql -U postgres -d base_postgis", "ALTER USER %s createdb;" % EDIFICE_USER)

# Handle --create [reconstruction of edifice database using the edifice user account]
if args.create :
  print 'setting up edifice database from scratch'

  cmd = "dropdb -U %s --interactive %s" % (EDIFICE_USER, EDIFICE_DB)
  call_or_fail(cmd)

  cmd = "createdb -U %s -T base_postgis %s" % (EDIFICE_USER, EDIFICE_DB)
  call_or_fail(cmd)
  
  call_or_fail("psql -U %s -d %s -f sql_init_scripts/pins_master.sql" % (EDIFICE_USER, EDIFICE_DB))
  call_or_fail("psql -U %s -d %s -f sql_init_scripts/assessed.sql" % (EDIFICE_USER, EDIFICE_DB))
  #call_or_fail("psql -U %s -d %s -f sql_init_scripts/edifice_initialization_script.sql" % (EDIFICE_USER, EDIFICE_DB))

  if os.path.exists("import/pins.dump"):
    print "Note: pins.dump already exists. Not fetching it."
  else:
    print 'Fetching pins.dump...'
    call_or_fail("curl -o import/pins.dump http://dl.dropbox.com/u/14915791/pins.dump")
  print "Loading property pins..."
  call_or_fail("pg_restore -U %s -O -c -d %s import/pins.dump" % (EDIFICE_USER, EDIFICE_DB))

if args.data:
  print "Importing datasets from open data portals. this will take a while..."
  for d in datasets:
    process_data(d)
