from bs4 import BeautifulSoup
import urllib2
import psycopg2
import cPickle
import time
import socket

search_url = 'http://cookcountyassessor.com/Property_Search/Property_Details.aspx?Pin='
conn = psycopg2.connect(dbname='chicago')
cur = conn.cursor()
vacant = cPickle.load(open('assessor.pickle'))
        # Remeber to re-save your updated dict
pinClasses = {}
pinsExisting = []

#cur.execute("SELECT countdown();")
#conn.commit()
#cur.execute("DELETE FROM assessed.pins_propclass_tocheck WHERE sent_pin IN ((SELECT pin FROM assessed.invalid_pins));")
#conn.commit()
cur.execute("SELECT sent_pin, property_class FROM assessed.pins_propclass_tocheck;")
for i in cur:
  pinClasses[i[0]] = i[1]
  pinsExisting.append(i[0])

for pin in pinsExisting:
  try:
    time.sleep(2)
    cook = BeautifulSoup(urllib2.urlopen(search_url+pin))
    if pinClasses[pin] in ['100', '200', '501']:
      cur.execute("INSERT INTO assessed.vacant VALUES (%s, %s, %s, %s)", (
        cook.find('span', {'id': vacant['pin']}).text, 
        cook.find('span', {'id': vacant['address']}).text, 
        cook.find('span', {'id': vacant['land_assessed_val_2011']}).text, 
        cook.find('span', {'id': vacant['land_assessed_val_2012']}).text))
      cur.execute("INSERT INTO assessed.sent_pins VALUES (%s)", (pin,))
      conn.commit()

    elif pinClasses[pin] in ['202', '203', '204', '205', '206', '207', '208', '209', '210', '211', '212', '234', '278', '295']:
      cur.execute("INSERT INTO assessed.res202 VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", (
        cook.find('span', {'id': vacant['pin']}).text, 
        cook.find('span', {'id': vacant['address']}).text, 
        cook.find('span', {'id': vacant['land_assessed_val_2011']}).text, 
        cook.find('span', {'id': vacant['land_assessed_val_2012']}).text, 
        cook.find('span', {'id': vacant['bldg_av_2011']}).text, 
        cook.find('span', {'id': vacant['bldg_av_2012']}).text, 
        cook.find('span', {'id': vacant['bldg_age']}).text, 
        cook.find('span', {'id': vacant['mkt_val_2011']}).text, 
        cook.find('span', {'id': vacant['mkt_val_2012']}).text, 
        cook.find('span', {'id': vacant['res_type']}).text, 
        cook.find('span', {'id': vacant['res_use']}).text, 
        cook.find('span', {'id': vacant['res_apts']}).text, 
        cook.find('span', {'id': vacant['ext_const']}).text, 
        cook.find('span', {'id': vacant['full_bath']}).text, 
        cook.find('span', {'id': vacant['half_bath']}).text, 
        cook.find('span', {'id': vacant['basement']}).text, 
        cook.find('span', {'id': vacant['attic']}).text, 
        cook.find('span', {'id': vacant['central_air']}).text, 
        cook.find('span', {'id': vacant['fireplace']}).text, 
        cook.find('span', {'id': vacant['garage']}).text,
        cook.find('span', {'id': vacant['cur_year']}).text,
        cook.find('span', {'id': vacant['last_year']}).text))
      cur.execute("INSERT INTO assessed.sent_pins VALUES (%s)", (pin,))
      conn.commit()

    elif pinClasses[pin] == '241':
      cur.execute("INSERT INTO assessed.vacant_adjacent VALUES (%s, %s, %s, %s, %s, %s)", (
          cook.find('span', {'id': vacant['pin']}).text, 
          cook.find('span', {'id': vacant['address']}).text, 
          cook.find('span', {'id': vacant['land_assessed_val_2011']}).text, 
          cook.find('span', {'id': vacant['land_assessed_val_2012']}).text, 
          cook.find('span', {'id': vacant['mkt_val_2011']}).text, 
          cook.find('span', {'id': vacant['mkt_val_2012']}).text))
      cur.execute("INSERT INTO assessed.sent_pins VALUES (%s)", (pin,))
      conn.commit()

    elif pinClasses[pin] == '299':
      cur.execute("INSERT INTO assessed.condos VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)", (
          cook.find('span', {'id': vacant['pin']}).text, 
          cook.find('span', {'id': vacant['address']}).text, 
          cook.find('span', {'id': vacant['land_assessed_val_2011']}).text, 
          cook.find('span', {'id': vacant['land_assessed_val_2012']}).text, 
          cook.find('span', {'id': vacant['mkt_val_2011']}).text, 
          cook.find('span', {'id': vacant['mkt_val_2012']}).text,
          cook.find('span', {'id': vacant['bldg_av_2011']}).text,
          cook.find('span', {'id': vacant['bldg_av_2012']}).text,
          cook.find('span', {'id': vacant['bldg_age']}).text,
          cook.find('span', {'id': vacant['cur_year']}).text,
          cook.find('span', {'id': vacant['last_year']}).text))
      cur.execute("INSERT INTO assessed.sent_pins VALUES (%s)", (pin,))
      conn.commit()

    elif pinClasses[pin] in ['313', '318', '314', '315']:
      cur.execute("INSERT INTO assessed.apts VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)", (
          cook.find('span', {'id': vacant['pin']}).text, 
          cook.find('span', {'id': vacant['address']}).text, 
          cook.find('span', {'id': vacant['land_assessed_val_2011']}).text,
          cook.find('span', {'id': vacant['land_assessed_val_2012']}).text, 
          cook.find('span', {'id': vacant['bldg_av_2011']}).text, 
          cook.find('span', {'id': vacant['bldg_av_2012']}).text, 
          cook.find('span', {'id': vacant['bldg_age']}).text,
          cook.find('span', {'id': vacant['bldg_sqft']}).text,
          cook.find('span', {'id': vacant['bldg_units']}).text))
      cur.execute("INSERT INTO assessed.sent_pins VALUES (%s)", (pin,))
      conn.commit()

    elif pinClasses[pin] == '0':
      cur.execute("INSERT INTO assessed.exempt VALUES (%s)", (pin,))
      conn.commit()

    else:
      cur.execute("INSERT INTO assessed.vacant_improved VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)", (
          cook.find('span', {'id': vacant['pin']}).text, 
          cook.find('span', {'id': vacant['address']}).text, 
          cook.find('span', {'id': vacant['land_assessed_val_2011']}).text,
          cook.find('span', {'id': vacant['land_assessed_val_2012']}).text, 
          cook.find('span', {'id': vacant['bldg_av_2011']}).text, 
          cook.find('span', {'id': vacant['bldg_av_2012']}).text, 
          cook.find('span', {'id': vacant['bldg_age']}).text,
          cook.find('span', {'id': vacant['cur_year']}).text,
          cook.find('span', {'id': vacant['last_year']}).text))
      cur.execute("INSERT INTO assessed.sent_pins VALUES (%s)", (pin,))
      conn.commit()

  except urllib2.URLError:
    cur.execute("INSERT INTO assessed.retry VALUES (%s)", (pin,))
    conn.commit()

  except urllib2.HTTPError:
    cur.execute("INSERT INTO assessed.retry VALUES (%s)", (pin,))
    conn.commit()

  except urllib2.httplib.HTTPException:
    cur.execute("INSERT INTO assessed.retry VALUES (%s)", (pin,))
    conn.commit()

  except AttributeError:
    cur.execute("INSERT INTO assessed.invalid_pins VALUES (%s)", (pin,))
    conn.commit()

  except socket.error:
    cur.execute("INSERT INTO assessed.retry VALUES (%s)", (pin,))
    conn.commit()
cur.close()
conn.close()

