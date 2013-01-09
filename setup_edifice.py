# coding: utf-8
import os

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

# # pull datasets from data.cityofchicago.org
# echo "downloading census blocks"
# curl -o import/census_blocks https://data.cityofchicago.org/download/3jmu-7ijz/application/zip