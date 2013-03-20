#!/usr/bin/env python

import csv, re, sys, string

# columns returned from get_csv_column_types, below
def get_create_table(dbname, name, columns):
  # Start building the db command
  db_command_args=[dbname, name]
  db_command='CREATE TABLE %s.%s ( '

  # Loop through columns, adding appropriate arguments to db command.
  first = True
  for column in columns:
    print column

    # convert the field/column name: spaces->underscores, tolower()
    # XXX: this probably needs to be a more elaborate regexp to filter out any weird (or
    # possibly nonexistent) field names
    fieldname = column[u'fieldName'].strip()
    fieldname = fieldname.lower()
    fieldname = string.replace(fieldname,' ','_')
    fieldname = string.replace(fieldname,'#','_no')

    #if (not first):
    #  db_command += ', '
    
    db_command=db_command+'%s %s,'
    db_command_args.append(fieldname)
    field_type=column[u'dataType']
    db_command_args.append(field_type)

    #if (first):
    #  first = False

  # Cut off the last comma and close off the command.
  db_command=db_command[:-1]+');'


  print '"%s"' % db_command
  print tuple(db_command_args), len(db_command_args)
  return (db_command % tuple(db_command_args))




def get_csv_column_types(infile):
 # Auto-detect column types in a csv file
 columns=[]
 with open(infile,'r') as f:
  csvfile=csv.reader(f)
  coordmatch=re.compile(r'(\"\')?\(\d+\.\d*, +(\-)?\d+\.\d*\)(\"\')?$')
  intmatch=re.compile(r'(\-)?\d+$')
  floatmatch=re.compile(r'(\-)?\d+\.\d*$')
  for col in csvfile.next():
    columns.append({'fieldName':col,'dataType':None})
  for row in csvfile:
    for icol,col in enumerate(row):
      if col=='': continue
      # Check for lat/long
      if columns[icol]['dataType'] in [None,'latlong']:
        try:
          assert coordmatch.match(col)!=None
          columns[icol]['dataType']='latlong'
        except:
          columns[icol]['dataType']=None
      # Check for int
      if columns[icol]['dataType'] in [None,'int']:
        try: 
          assert intmatch.match(col)
          columns[icol]['dataType']='int'
        except: 
          columns[icol]['dataType']=None
      # Check for float
      if columns[icol]['dataType'] in [None,'float']:
        try: 
          assert floatmatch.match(col)
          columns[icol]['dataType']='float'
        except:
          columns[icol]['dataType']=None
      # OK, fall back to string
      if columns[icol]['dataType'] is None:
        #columns[icol]['dataType']='string'
        columns[icol]['dataType']='varchar'
 return columns


if __name__ == "__main__":
  get_csv_column_types(sys.argv[1])
