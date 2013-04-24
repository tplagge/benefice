# coding: utf-8

# system libraries
import argparse
import sys
import os
import re
import string
import csv
import httplib
import json

# our stuff
import benefice_setup
import util.import_helpers as import_helpers
import import_actions
from util.import_table import get_csv_column_types, get_create_table
import data_portal

# Start out with no psycopg2 connection, make it during data import ('--data')
benefice_setup.DB_CONN = None

def main():

  # parse input arguments
  parser = argparse.ArgumentParser(description='Setup the PostGIS Benefice database and populate it with open datasets.')
  parser.add_argument('--create_template', action='store_true',
                      help="Run only once to create a base postgis template ('base_postgis') as the postgres superuser")
  parser.add_argument('--create', action='store_true',
                      help='Drop existing benefice database and create from scratch based on the base_postgis database created with --create_template')
  parser.add_argument('--data', action='store_true',
                      help='Download and import data from the City, etc. (as listed in datasets.py)')
  parser.add_argument('--populate', action='store_true',
                      help='Take raw data tables and populate benefice tables')

  parser.add_argument('--bindir', nargs='?', type=str,
                      help='Directory location of PostgreSQL binaries (e.g. pg_config, psql)')
  parser.add_argument('--user', nargs='?', type=str, 
                      help="Postgres username for accessing benefice database (e.g. during --create or --data) [default: 'benefice']")
  parser.add_argument('--superuser', nargs='?', type=str, 
                      help="Postgres superuser name for creating benefice database (e.g. during --create_template) [default: 'postgres']")
  parser.add_argument('--host', nargs='?', type=str, 
                      help="Postgres host [default: 'localhost']")
  parser.add_argument('--database', nargs='?', type=str,
                      help="Name for benefice database [default: 'benefice']")
  parser.add_argument('--delete_downloads', action='store_true',
                      help="Keep files downloaded from the various data portals after they have been imported [default: False]")
  args = parser.parse_args()

  # Handle --bindir [directory w/ postgres binaries]
  if args.bindir:
    benefice_setup.POSTGRES_BINDIRNAME = args.bindir

    # Check if we can find pg_config in this directory. If this fails, we can't find it.
    try:
      (major_version, minor_version) = import_helpers.get_postgres_version(benefice_setup.POSTGRES_BINDIRNAME)
    except OSError as e:
      print "Cannot find pg_config in specified directory: %s" % benefice_setup.POSTGRES_BINDIRNAME
      sys.exit(1)
      
    # We know we have the right directory, let's just modify this process' PATH to have this directory first.
    # Not exactly kosher but more straightforward than pasting POSTGRES_BINDIRNAME everywhere we exec 'psql'
    os.environ['PATH'] = benefice_setup.POSTGRES_BINDIRNAME + ":" + os.environ['PATH']

  if args.user:
    benefice_setup.BENEFICE_USER = args.user

  if args.superuser:
    benefice_setup.POSTGRES_SUPERUSER = args.superuser

  if args.database:
    benefice_setup.BENEFICE_DB = args.database

  if args.delete_downloads:
    benefice_setup.DELETE_DOWNLOADS = args.delete_downloads


  # primary functions
  if args.create_template:
    import_actions.create_template()

  if args.create :
    import_actions.create()

  if args.data:
    import_actions.data()

  if args.populate:
    import_actions.populate()

  # if no actionable args, print out help message!
  if ((not args.create_template) and (not args.create) and (not args.data) and (not args.populate)):
    parser.print_help()

if __name__ == "__main__":
    main()
