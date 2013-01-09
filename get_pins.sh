#!/bin/bash

createdb edifice
psql -d edifice -c "CREATE EXTENSION postgis;"
psql -d edifice -f pins_master.sql
psql -d edifice -f assessed.sql

wget https://s3.amazonaws.com/edifice/pins.dump
pg_restore -d edifice pins.dump
