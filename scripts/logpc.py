#!/usr/local/bin/python
#$Id: logpc.py,v 1.3 2013/11/15 14:41:43 kenji Exp $

from sqlite3 import dbapi2 as sqlite
import sys

# change integer to string if found
def int2str(p):
  if type(p) == int:
    return str(p)
  else:
    return p

if __name__ == '__main__':
  con = sqlite.connect("/home/kenji/txt/hamradio/LOGS/SQLite-log/hamradio_log.sqlite")

  cur = con.cursor()

  for arg in sys.argv[1:]:
    t = str(arg)
    q = "*" + t.upper() + "*"
    cur.execute("""
      select `qso_date`, `time_on`, `my_call`, `call`, `band`, `mode`,
      `rst_sent`, `qsl_sent`, `qsl_via`, `comment`, `my_qso_id` from qso
      where `call` glob ? and `qsl_rcvd` <> \'I\'
      order by `qso_date` || `time_on`
      """, (q,))
    for row in cur.fetchall():
      print "-----------"
      print "qso_date:  ", row[0]
      print "time_on:   ", row[1]
      print "my_call:   ", row[2]
      print "call:      ", row[3]
      print "band:      ", row[4]
      print "mode:      ", row[5]
      print "rst_sent:  ", row[6]
      print "qsl_sent:  ", row[7]
      print "qsl_via:   ", row[8]
      print "comment:   ", row[9]
      print "my_qso_id: ", row[10]

  cur.close()
