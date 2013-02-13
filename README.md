# edifice

A database of the built environment in Chicago using open data

## Requirements

* PostgreSQL (9.0.x or later; 9.1.x+ preferred)
* PostGIS (2.0.x or later)
* Python (2.7.x or later)
* wget
* psycopg2

## Using setup_edifice.py

setup_edifice.py is used to recreate the edifice database on a system
with a PostgreSQL database installed (with PostGIS 2.0.x+ support).

Drop and recreate from scratch a `base_postgis` template database, using the 'postgres' admin user.

<pre>
python setup_edifice.py --create_template
</pre>

Drop and recreate from scratch an `edifice` database struture, using the 'edifice' user.
<pre>
python setup_edifice.py --create
</pre>

Download (~165mb), unzip, and import City of Chicago data into the `edifice` database. [NOTE: WORK IN PROGRESS]
<pre>
python setup_edifice.py --data
</pre>

Optional flags:

* `--bindir [DIRNAME]`: specify the location of PostgreSQL binaries such as pg_config, psql, etc.
* `--user [USERNAME]`: use a username other than 'edifice' as the owner of the main database.
* `--database [DBNAME]`: use a name other than 'edifice' for the main database.
* `--delete_downloads`: delete downloaded zip and csv files after import
* `--help`: provide usage info

## Data Sources

[Google Doc of data sources we are using](https://docs.google.com/spreadsheet/ccc?key=0AtbqcVh3dkAqdGdlcWd5MzRYcGJkS1RoQTM3Qzd4dUE)

## QGIS and TileMill

Once you are done setting up your Edifice database, you can use the following tools (including psql) to explore the datasets.

[QGIS](http://qgis.org) is a free, open-source [GIS](http://en.wikipedia.org/wiki/Geographic_information_system) application that can connect directly to a PostGIS database and display and analyze geographic data.

[TileMill](http://mapbox.com/tilemill) is a map-design studio that can also connect directly to a PostGIS datastore and create interactive web maps using [OpenStreetMap](http://openstreetmap.org) as the base layer.