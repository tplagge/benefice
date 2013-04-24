# coding: utf-8
# Testing the table-populating code.  This might
# be best moved elsewhere.

# system libraries
import argparse
import sys
import re
import string
import csv
import httplib
import json

# third party libraries
import psycopg2

# our stuff
import benefice_setup
import util.import_helpers as import_helpers

def populate_benefice_table(source_table, dest_table, mapping):
  # Helper function that takes in table names and a sequence of
  # tuples (source_column, destination_column).
  #with benefice_setup.DB_CONN.cursor() as cur, \
  #     benefice_setup.DB_CONN.cursor() as cur_insert:
  cur=benefice_setup.DB_CONN.cursor()
  cur_insert=benefice_setup.DB_CONN.cursor()
  if True:
    # First, do a select from the source table.
    select_sql  = 'SELECT '
    for item in [i[0] for i in mapping]:
      select_sql += item+', '
    select_sql = select_sql[:-2] + ' FROM '+source_table
    try:
      cur.execute(select_sql)
    except psycopg2.OperationalError as e:
      print(e)
      return False
      
    # Now prepare the insert sql
    insert_sql  = 'INSERT INTO '+dest_table+' (' 
    for item in [i[1] for i in mapping]:
      insert_sql  += item+', '
    insert_sql = insert_sql[:-2] +') VALUES ('
    for item in [i[1] for i in mapping]:
      insert_sql  += '%s, '
    insert_sql = insert_sql[:-2]+')'
    
    # Now do the insert
    for row in cur:
      try:
        cur_insert.execute(insert_sql,row)
      except psycopg2.ProgrammingError as e:
        print(e)
        benefice_setup.DB_CONN.rollback()
        return False
      else:
        benefice_setup.DB_CONN.commit()

    return True

def populate_footprints():
  source_table = 'dataportal.building_footprints'
  dest_table   = 'benefice.building_footprints'
  mapping      = [\
    ('no_stories' , 'num_stories'),\
    ('bldg_sq_fo' , 'sqft'       ),\
    ('year_built' , 'year_built' ),\
    ('no_of_unit' , 'num_units'  ),\
    ('f_add1',      'start_addr' ),\
    ('t_add1',      'end_addr'   ),\
    ('pre_dir1',    'direction'  ),\
    ('st_name1',    'street_name'),\
    ('st_type1',    'street_type'),\
    ('the_geom',    'the_geom'   ),\
    ('ST_Centroid(the_geom)', 'centroid')]
  print('Populating building footprints table')
  populate_benefice_table(source_table,dest_table,mapping)

if __name__ == '__main__':
  print "Connecting to database '%s' with user '%s'" % \
    (benefice_setup.BENEFICE_DB, benefice_setup.BENEFICE_USER)
  try:
    benefice_setup.DB_CONN=psycopg2.connect(\
      database=benefice_setup.BENEFICE_DB, user=benefice_setup.BENEFICE_USER)
    # This is crucial so that we don't have really long-running transaction sequences
    benefice_setup.DB_CONN.set_session(autocommit=True)
  except psycopg2.OperationalError as e:
    print e
    sys.exit(1)
  populate_footprints()
