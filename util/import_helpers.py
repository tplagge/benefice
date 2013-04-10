# coding: utf-8

# system libraries
import os
import glob
import subprocess
import zipfile
import util.import_table as import_table
import benefice_setup
import re

# third party libraries
import psycopg2

from subprocess import call, check_call, Popen, CalledProcessError

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
  
    psql_split = cmd.split()
    if (user):
      psql_split.extend(["-U",user])

    # add host flag automatically
    psql_split.extend(["-h", benefice_setup.POSTGRES_HOST])

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
  call_raw_or_fail("pg_restore -U %s --role=%s -h %s -O -d %s %s" % (benefice_setup.BENEFICE_USER, benefice_setup.BENEFICE_USER, benefice_setup.POSTGRES_HOST, benefice_setup.BENEFICE_DB, download_name))

  if (benefice_setup.DELETE_DOWNLOADS):
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
  csv_col_types =  import_table.get_csv_column_types(name_csv)
  create_table_sql = import_table.get_create_table(dbname, name, csv_col_types)

  drop_table_sql = "DROP TABLE %s.%s" % (dbname, name)
  print drop_table_sql
  cur=benefice_setup.DB_CONN.cursor()
  try:    
    cur.execute(drop_table_sql)
  except psycopg2.ProgrammingError: 
    benefice_setup.DB_CONN.rollback()
  else:   
    benefice_setup.DB_CONN.commit()

  print "create table command: ", create_table_sql
  cur=benefice_setup.DB_CONN.cursor()
  cur.execute(create_table_sql)

  # hack to use 'psql -c' to insert the rows
  #sql_cmd = "\copy street_gazetteer FROM 'downloads/street_gazetteer.csv' WITH CSV HEADER"
  sql_cmd = "\copy %s.%s FROM '%s' WITH CSV HEADER" % (dbname, name, name_csv)
  print "calling '%s'" % sql_cmd
  call_or_fail("psql", user=benefice_setup.BENEFICE_USER, database=benefice_setup.BENEFICE_DB, sql_command=sql_cmd)


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
      psql_cmd = "psql -q -U %s -d %s" % (benefice_setup.BENEFICE_USER, benefice_setup.BENEFICE_DB)
      p1 = Popen(shp2pgsql_cmd_list, stdout=subprocess.PIPE)
      print shp2pgsql_cmd, "|", psql_cmd
      p2 = Popen(psql_cmd.split(), stdin=p1.stdout, stdout=subprocess.PIPE)
      stdout = p2.communicate()[0]

  # Now do the specialized import for the given dataset
  # data_portal.do_import(name, DB_CONN)

  # Great. Now delete all the files in zip_file_contents
  if benefice_setup.DELETE_DOWNLOADS:
    for fname in glob.glob('import/*'):
      print "Deleting:", fname
      os.remove(fname)

    print "deleting %s" % name_zip
    os.remove(name_zip)