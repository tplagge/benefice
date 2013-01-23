# coding: utf-8
from optparse import OptionParser
import os
import glob

def import_zip (url, encoding):
  os.chdir("import")
  os.system("wget -O shapefile.zip %s" % (url,))
  print "unziping..."
  os.system("unzip shapefile.zip")
  
  shapefile = ''
  for f in glob.glob("*.shp"):
      shapefile = f
      print 'importing ', shapefile

  os.system("shp2pgsql -d -s 3435 -W LATIN1 -g the_geom -I %s | psql -d edifice" % (shapefile,))
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


print "pulling datasets from data.cityofchicago.org"

print "importing census blocks"
import_zip("https://data.cityofchicago.org/download/3jmu-7ijz/application/zip", 'LATIN1')