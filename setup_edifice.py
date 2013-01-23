# coding: utf-8
from optparse import OptionParser
import os
import glob
from datasets import datasets

def process_data(dataset):
  name =        dataset[0]
  domain =      dataset[1]
  data_type =   dataset[2]
  socrata_id =  dataset[3]
  options =     dataset[4]

  url = ''
  # format: https://data.cityofchicago.org/download/5gv8-ktcg/application/zip
  if (domain == 'Chicago' and data_type == 'shp'):
    url = "https://data.cityofchicago.org/download/%s/application/zip" % (socrata_id,)

  print 'importing', name
  import_shp(url, options)

def import_shp (url, encoding):
  os.chdir("import")
  os.system("wget -O shapefile.zip %s" % (url,))
  print "unziping..."
  os.system("unzip shapefile.zip")
  
  shapefile = ''
  for f in glob.glob("*.shp"):
      shapefile = f
      print 'importing ', shapefile

  os.system("shp2pgsql -d -s 3435 -W LATIN1 -g the_geom -I %s | psql -q -d edifice" % (shapefile,))
  os.system("rm *")
  os.chdir("../")


parser = OptionParser()
parser.add_option("-c", "--create", default=False, action="store_false",
                  help="drop existing edifice database and create from scratch")

(options, args) = parser.parse_args()
if options.create :
  os.system("dropdb edifice")
  os.system("createdb -T base_postgis edifice")
  os.system("psql -d edifice -f sql_init_scripts/pins_master.sql")
  os.system("psql -d edifice -f sql_init_scripts/assessed.sql")

  if os.path.exists("import/pins.dump"):
    print "pins.dump exists"
  else:
    os.system("curl -o import/pins.dump http://dl.dropbox.com/u/14915791/pins.dump")

  print "loading property pins"
  os.system("pg_restore -O -c -d edifice import/pins.dump")

print "pulling shapefile datasets from data.cityofchicago.org"

for d in datasets:
  process_data(d)
