#!/usr/bin/env python

import csv, re, sys

def get_csv_column_types(infile):
 # Auto-detect column types in a csv file
 columns=[]
 with open(infile,'r') as f:
  csvfile=csv.reader(f)
  coordmatch=re.compile(r'(\"\')?\(\d+\.\d*, +(\-)?\d+\.\d*\)(\"\')?$')
  intmatch=re.compile(r'(\-)?\d+$')
  floatmatch=re.compile(r'(\-)?\d+\.\d*$')
  for col in csvfile.next():
    columns.append({'name':col,'type':None})
  for row in csvfile:
    for icol,col in enumerate(row):
      if col=='': continue
      # Check for lat/long
      if columns[icol]['type'] in [None,'latlong']:
        try:
          assert coordmatch.match(col)!=None
          columns[icol]['type']='latlong'
        except:
          columns[icol]['type']=None
      # Check for int
      if columns[icol]['type'] in [None,'int']:
        try: 
          assert intmatch.match(col)
          columns[icol]['type']='int'
        except: 
          columns[icol]['type']=None
      # Check for float
      if columns[icol]['type'] in [None,'float']:
        try: 
          assert floatmatch.match(col)
          columns[icol]['type']='float'
        except:
          columns[icol]['type']=None
      # OK, fall back to string
      if columns[icol]['type'] is None:
        columns[icol]['type']='string'
 return columns


if __name__ == "__main__":
  get_csv_column_types(sys.argv[1])
