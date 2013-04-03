import yaml

def read_setup(filename):
  default_conf = {\
    'BENEFICE_USER':           'benefice',
    'BENEFICE_DB':             'benefice',
    'POSTGRES_BINDIRNAME':     None,
    'POSTGRES_SUPERUSER':      'postgres',
    'POSTGRES_HOST':           'localhost',
    'DELETE_DOWNLOADS':        False
  }

  try:
    config = yaml.load(open(filename,'r'))
  except IOError:
    print('Local config file not found, assuming defaults.')
    config={}

  for k,v in default_conf.iteritems():
    if k not in config.keys():
      config[k]=v

  return config
