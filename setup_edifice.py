# coding: utf-8
import os

def import_zip (file_name, url):
  os.system("wget -O %s %s" % (file_name, url))
  os.system("unzip %s" % (file_name,))
  print "finding shp file in folder"
  # os.system("shp2pgsql -s 3435 -g the_geom -I | psql -d edifice -f %s" % (file_name,))

  

# os.system("dropdb edifice")
# os.system("createdb -T base_postgis edifice")
# os.system("psql -d edifice -f sql_init_scripts/pins_master.sql")
# os.system("psql -d edifice -f sql_init_scripts/assessed.sql")

# if os.path.exists("import/pins.dump"):
#   print "pins.dump exists"
# else:
#   os.system("curl -o import/pins.dump http://dl.dropbox.com/u/14915791/pins.dump")

# print "loading property pins"
# os.system("pg_restore -O -c -d edifice import/pins.dump")

print "pulling datasets from data.cityofchicago.org"

print "importing census blocks"
import_zip("CensusBlocks2010.zip", "https://data.cityofchicago.org/download/3jmu-7ijz/application/zip")