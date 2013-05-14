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
  cur=benefice_setup.DB_CONN.cursor()
  cur_insert=benefice_setup.DB_CONN.cursor()
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
    ('pre_dir1',    'street_dir' ),\
    ('st_name1',    'street_name'),\
    ('st_type1',    'street_type'),\
    ('unit_name',   'unit_name'  ),\
    ('the_geom',    'the_geom'   ),\
    ('ST_Centroid(the_geom)', 'centroid')]
  print('Populating building footprints table')
  populate_benefice_table(source_table,dest_table,mapping)

def populate_building_addresses():
  print('Populating building addresses table')
  cur=benefice_setup.DB_CONN.cursor()
  cur_insert=benefice_setup.DB_CONN.cursor()
  # First, do a select from the footprints table
  select_sql  = 'SELECT bldg_gid, start_addr, end_addr, '+\
    'street_dir, street_name, street_type, unit_name '+\
    'FROM benefice.building_footprints'
  try:
    cur.execute(select_sql)
  except psycopg2.OperationalError as e:
    print(e)
    return False

  # Now loop through buildings and add all addresses.
  insert_sql = 'INSERT INTO benefice.building_addresses VALUES ('+\
    '%s, %s, %s, %s, %s, %s)'
  for row in cur:
    for addr in range(row[1],row[2]+1,2):
      try:
        cur_insert.execute(insert_sql,(row[0],addr,row[3],row[4],row[5],row[6]))
      except psycopg2.ProgrammingError as e:
        print(e)
        benefice_setup.DB_CONN.rollback()
        return False
  benefice_setup.DB_CONN.commit()
  return True

def populate_addresses():
  print('Populating addresses table')
  cur=benefice_setup.DB_CONN.cursor()
  cur_gis=benefice_setup.DB_CONN.cursor()
  cur_insert=benefice_setup.DB_CONN.cursor()
  # Add some temporary columns
  geo_sql    = "SELECT AddGeometryColumn('benefice',"+\
               "'addresses','temp_geom',3435,'LINESTRING',2);"
  try:
    cur.execute(geo_sql)
  except psycopg2.OperationalError as e:
    print(e)
    return False
  col_sql    = 'ALTER TABLE benefice.addresses ADD COLUMN '+\
               'lbegin INTEGER, ADD COLUMN lend INTEGER, '+\
               'ADD COLUMN rbegin INTEGER, ADD COLUMN rend INTEGER'
  try:
    cur.execute(col_sql)
  except psycopg2.OperationalError as e:
    print(e)
    return False

  # First, do a select from the centerlines table.
  select_sql   = 'SELECT pre_dir, street_nam, street_typ, l_f_add, l_t_add, '+\
                 'r_f_add, r_t_add, the_geom FROM dataportal.street_centerlines'
  try:
    cur.execute(select_sql)
  except psycopg2.OperationalError as e:
    print(e)
    return False


  # Now loop through street centerlines and add all addresses.
  insert_sql = 'INSERT INTO benefice.addresses ('+\
               'addr_number,street_dir,street_name,street_type,'+\
               'lbegin,lend,rbegin,rend,temp_geom) '+\
               'VALUES (%s, %s, %s, %s, %s, %s, %s, %s, ST_LineMerge(%s))'
  for row in cur:
    laddr_begin=float(row[3])
    laddr_end  =float(row[4])
    raddr_begin=float(row[5])
    raddr_end  =float(row[6])
    if (laddr_begin != laddr_end) and (laddr_begin != 0):
      for addr in range(laddr_begin,laddr_end+1,2):
        try:
          cur_insert.execute(insert_sql,(addr,row[0],row[1],row[2],\
                                         row[3],row[4],row[5],row[6],row[7]))
        except psycopg2.ProgrammingError as e:
          print(e)
          benefice_setup.DB_CONN.rollback()
          return False
    if (raddr_begin != raddr_end) and (raddr_begin != 0):
      for addr in range(raddr_begin,raddr_end+1,2):
        try:
          if addr < raddr_begin: print row
          if addr > raddr_end: print row
          cur_insert.execute(insert_sql,(addr,row[0],row[1],row[2],\
                                         row[3],row[4],row[5],row[6],row[7]))
        except psycopg2.ProgrammingError as e:
          print(e)
          benefice_setup.DB_CONN.rollback()
          return False

  # Set the_geom
  update_sql    = 'UPDATE benefice.addresses SET the_geom = '+\
                  '(ST_Line_Interpolate_Point(ST_AsEWKT(temp_geom),'+\
                  '(rend-addr_number)/(rend-rbegin))) WHERE (addr_number % 2 = rbegin % 2) '+\
                  'AND (rend != rbegin)'
  update_sql_zd = 'UPDATE benefice.addresses SET the_geom = '+\
                  '(ST_Line_Interpolate_Point(ST_AsEWKT(temp_geom),'+\
                  '0.0)) WHERE (addr_number % 2 = rbegin % 2) AND (rend = rbegin)'
  try:
    cur.execute(update_sql)
    cur.execute(update_sql_zd)
  except psycopg2.OperationalError as e:
    print(e)
    return False
  update_sql    = 'UPDATE benefice.addresses SET the_geom = '+\
                  '(ST_Line_Interpolate_Point(ST_AsEWKT(temp_geom),'+\
                  '(lend-addr_number)/(lend-lbegin))) WHERE (addr_number % 2 = lbegin % 2) '+\
                  'AND (lend != lbegin)'
  update_sql_zd = 'UPDATE benefice.addresses SET the_geom = '+\
                  '(ST_Line_Interpolate_Point(ST_AsEWKT(temp_geom),'+\
                  '0)) WHERE (addr_number % 2 = lbegin % 2) AND (lend = lbegin)'
  try:
    cur.execute(update_sql)
    cur.execute(update_sql_zd)
  except psycopg2.OperationalError as e:
    print(e)
    return False

  # Drop the temporary columns
  col_sql    = 'ALTER TABLE benefice.addresses DROP COLUMN'+\
               'lbegin, DROP COLUMN lend, DROP COLUMN rbegin,'+\
               'DROP COLUMN rend, DROP COLUMN temp_geom'
  try:
    cur.execute(col_sql)
  except psycopg2.OperationalError as e:
    print(e)
    return False

  benefice_setup.DB_CONN.commit()
  return True


def get_gid_from_addr(cur, street_number, street_direction, street_name, suffix):
  # This should be much, much smarter.
  cur.execute('SELECT bldg_gid FROM benefice.building_addresses WHERE '+\
                'addr_number =    %s AND '+\
                'street_dir  =    %s AND '+\
                'street_name LIKE %s AND '+\
                'street_type LIKE %s',\
                (street_number,street_direction,street_name,suffix))
  res=cur.fetchall()
  if len(res) == 0: return None
  if len(res) == 1: return res[0][0]
  if len(res) >  1:
    print('Multiple matches: ')
    for i in res: print(i)
    return(res[0])

def populate_construction_permits():
  cur        = benefice_setup.DB_CONN.cursor()
  cur_insert = benefice_setup.DB_CONN.cursor()  
  select_sql = 'SELECT street_number, street_direction, street_name, suffix, '+\
    'issue_date, permit_no, permit_type, work_description '+\
    'FROM dataportal.building_permits'
  try:
    cur.execute(select_sql)
  except psycopg2.OperationalError as e:
    print(e)
    return False
  insert_sql_nogid = 'INSERT INTO benefice.construction_permits '+\
    '(issue_date, permit_num, permit_type, work_desc) VALUES ('+\
    '%s, %s, %s, %s)'
  insert_sql_gid   = 'INSERT INTO benefice.construction_permits '+\
    '(bldg_gid, issue_date, permit_num, permit_type, work_desc) VALUES ('+\
    '%s, %s, %s, %s, %s)'
  for row in cur:
    bldg_gid=get_gid_from_addr(cur_insert, row[0],row[1],row[2],row[3])
    if bldg_gid is not None:
      cur_insert.execute(insert_sql_gid,(bldg_gid,row[4],row[5],row[6],row[7]))
    else:
      cur_insert.execute(insert_sql_nogid,(row[4],row[5],row[6],row[7]))
  return True

if __name__ == '__main__':
  print "Connecting to database '%s' with user '%s'" % \
    (benefice_setup.BENEFICE_DB, benefice_setup.BENEFICE_USER)
  try:
    benefice_setup.DB_CONN=psycopg2.connect(\
      database=benefice_setup.BENEFICE_DB, user=benefice_setup.BENEFICE_USER)
    benefice_setup.DB_CONN.set_session(autocommit=False)
  except psycopg2.OperationalError as e:
    print e
    sys.exit(1)
  #populate_footprints()
  #populate_building_addresses()
  populate_addresses()
  #populate_construction_permits()
