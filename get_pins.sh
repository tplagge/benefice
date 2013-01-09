#!/bin/bash

dropdb edifice
createdb -T base_postgis edifice
psql -d edifice -f sql_init_scripts/pins_master.sql
psql -d edifice -f sql_init_scripts/assessed.sql

if [ -f pins.dump ]
then
echo "pins.dump exists"
else
curl -o pins.dump http://dl.dropbox.com/u/14915791/pins.dump
fi
echo "restoring pins.dump"
pg_restore -O -c -d edifice pins.dump
