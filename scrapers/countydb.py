# coding: utf-8
from bs4 import BeautifulSoup
import urllib2
import psycopg2
import cPickle
import time

pinsExisting = cPickle.load(open('pinsExisting'))
search_url = 'http://cookcountypropertyinfo.com/Pages/Pin-Results.aspx?pin='
county = cPickle.load(open('county.pickle'))
conn = psycopg2.connect(dbname='chicago')
cur = conn.cursor()
pinsChecked = []

cur.execute("SELECT sent_pin FROM county;")
for i in cur:
	pinsChecked.append(i[0])

def getPinData():
	for pin in pinsExisting:
		if not pin in pinsChecked:
			time.sleep(3)

			try:
				cook = BeautifulSoup(urllib2.urlopen(search_url+pin))
				cur.execute("INSERT INTO county VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", (cook.find('span', {'id': county['pin']}).text, cook.find('span', {'id': county['address']}).text, cook.find('span', {'id': county['city']}).text, cook.find('span', {'id': county['zip']}).text, cook.find('span', {'id': county['township']}).text, cook.find('span', {'id': county['assessment_tax_year']}).text, cook.find('span', {'id': county['est_value']}).text, cook.find('span', {'id': county['assessed_value']}).text, cook.find('span', {'id': county['lotsize']}).text, cook.find('span', {'id': county['bldg_size']}).text, cook.find('span', {'id': county['property_class']}).text, cook.find('span', {'id': county['bldg_age']}).text, cook.find('span', {'id': county['tax_rate_year']}).text, cook.find('span', {'id': county['tax_code_year']}).text, cook.find('span', {'id': county['taxcode']}).text, cook.find('span', {'id': county['mailing_tax_year']}).text, cook.find('span', {'id': county['mailing_name']}).text, cook.find('span', {'id': county['mailing_address']}).text, cook.find('span', {'id': county['mailing_city_state_zip']}).text, cook.find('span', {'id': county['tax_bill_2012']}).text, cook.find('span', {'id': county['tax_bill_2011']}).text, cook.find('span', {'id': county['tax_bill_2010']}).text, cook.find('span', {'id': county['tax_bill_2009']}).text, cook.find('span', {'id': county['tax_bill_2008']}).text, cook.find('span', {'id': county['tax_bill_2007']}).text, cook.find('span', {'id': county['tax_bill_2006']}).text, cook.find('span', {'id': county['tax_rate']}).text, pin))
				conn.commit()

			except urllib2.URLError:
				time.sleep(10)

			except AttributeError:
				cur.execute("INSERT INTO county (sent_pin) VALUES (%s)", (pin,))
				conn.commit()
			
getPinData()


cur.close()
conn.close()

