import yaml

# configurable globals
BENEFICE_USER       = 'benefice'
BENEFICE_DB         = 'benefice'
POSTGRES_BINDIRNAME = None
POSTGRES_SUPERUSER  = 'postgres'
POSTGRES_HOST       = 'localhost'
DELETE_DOWNLOADS    = False

# internal globals
DB_CONN = None

setup_filename      = 'setup.cfg'

config={}
try:
  config = yaml.load(open(setup_filename,'r'))
except IOError:
  print('Local config file not found, assuming defaults.')

if 'BENEFICE_USER'       in config.keys():
  BENEFICE_USER           = config['BENEFICE_USER']
if 'BENEFICE_DB'         in config.keys():
  BENEFICE_DB             = config['BENEFICE_DB']
if 'POSTGRES_BINDIRNAME' in config.keys():
  POSTGRES_BINDIRNAME     = config['POSTGRES_BINDIRNAME']
if 'POSTGRES_SUPERUSER'  in config.keys():
  POSTGRES_SUPERUSER      = config['POSTGRES_SUPERUSER']
if 'POSTGRES_HOST'       in config.keys():
  POSTGRES_HOST           = config['POSTGRES_HOST']
if 'DELETE_DOWNLOADS'    in config.keys():
  DELETE_DOWNLOADS        = config['DELETE_DOWNLOADS']

