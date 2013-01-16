#!/usr/bin/env python2.7

import psycopg2
import sys
import csv

#################################################################

def get_edifice_conn():
  "Gets a psycopg2 connection to edifice"
  try:
    return psycopg2.connect(\
      database='edifice', user='opengov', \
      password='hacknightchi312', \
      host='ec2-23-22-87-229.compute-1.amazonaws.com')
  except:
    raise IOError('Cannot connect to Edifice')

#################################################################

def levenshtein(a,b):
  "Calculates the Levenshtein distance between a and b."
  n, m = len(a), len(b)
  if n > m:
    # Make sure n <= m, to use O(min(n,m)) space
    a,b = b,a
    n,m = m,n
    
  current = range(n+1)
  for i in range(1,m+1):
    previous, current = current, [i]+[0]*n
    for j in range(1,n+1):
      add, delete = previous[j]+1, current[j-1]+1
      change = previous[j-1]
      if a[j-1] != b[i-1]:
          change = change + 1
      current[j] = min(add, delete, change)
        
  return current[n]

#################################################################

def fetch_street_database(conn=None):
  "Fetches the street name database from edifice"
  if conn==None:
    conn=get_edifice_conn()
  cur=conn.cursor()
  cur.execute('SELECT * FROM names_streets;')
  return cur.fetchall()

#################################################################

def string_to_addr(addr_str,street_database=None,conn=None):
  "Converts an address string into an address tuple."
  if street_database==None: street_database=fetch_street_database(conn=conn)
  addr_split=addr.split()

  # Check for dash in number, such as 4447-4449 N Malden St.  
  # If it exists, use just the address before the dash.
  if '-' in addr_split[0]: 
    addr_split[0]=addr_split[0].split('-')[0]

  # Make sure the street number converts to an int.
  try:
    street_num=int(addr_split[0])
  except: 
    raise IOError('Invalid street number '+str(street_num))

  # Check street direction.
  street_dir=addr_split[1].upper()
  if street_dir not in ['N','E','S','W']:
    raise IOError('Invalid street direction '+str(street_dir))
  
  # Find the street name, or the best match.
  full_street=' '.join(addr_split[1:]).upper()
  try:
    idx=[i[0] for i in street_database].index(full_street)
  except:
    idx,mindist=0,9e9
    for istreet,street in enumerate(street_database):
      dist=levenshtein(street[0],full_street)
      if dist < mindist: 
        idx,mindist=istreet,dist
  street_dir =street_database[idx][1]
  street_name=street_database[idx][2]
  street_type=street_database[idx][3]
  street_suf =street_database[idx][4]

  # Check that the street number is valid.
  if (street_num > street_database[idx][6]) or \
     (street_num < street_database[idx][5]):
    raise IOError('Invalid street number '+str(street_num))
  
  # Return address tuple.
  return (street_num,street_dir,street_name,street_type,street_suf)

#################################################################

def addr2gid(addr, conn=None):
  "Converts an address tuple into a building GID, if possible."
  if type(addr)==type(''):
    addr=string_to_addr(addr)
  if conn==None:
    conn=get_edifice_conn()
  cur=conn.cursor()
  cur.execute('SELECT * FROM address WHERE '+\
                'ST_NAME1 = %s AND '+\
                'PRE_DIR1 = %s AND '+\
                'ST_TYPE1 = %s AND '+\
                'F_ADD1  <= %s AND '+\
                'T_ADD1  >= %s ;' ,\
                (addr[2],addr[1],addr[3],addr[0],addr[0]))
  res=cur.fetchall()
  retval=None
  if len(res)==0:
    raise IOError('No match in database')
  for bldg in res:
    if (int(bldg[1]) % 2) == (int(addr[0]) % 2): 
      retval=bldg[0]
  if retval==None:
    raise IOError('No match in database')

  return retval

#################################################################

if __name__=='__main__':
  addr=' '.join(sys.argv[1:])
  print(addr2gid(addr))
