#!/usr/local/bin/python
#$Id: logid.py,v 1.4 2013/11/15 15:07:06 kenji Exp $

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
    t = (arg,)
    cur.execute("""
      select `my_call`, `my_qth`, `qso_date`, `time_on`, `time_off`,
      `call`, `rst_sent`, `rst_rcvd`, `qsl_sent`, `qsl_rcvd`,
      `mode`, `band`, `qslmsg`, `qsl_via`, 
      `contest_id`, `srx`, `stx`, `my_qso_id`, `comment`
      from qso 
      where `my_qso_id` = ? 
      order by `qso_date` || `time_on`
      """, t)
    for row in cur.fetchall():
      print "------------"
      print "my_call:    ", row[0]
      print "my_qth:     ", row[1]
      print "qso_date:   ", row[2]
      print "time_on:    ", row[3]
      print "time_off:   ", row[4]
      print "call:       ", row[5]
      print "rst_sent:   ", row[6]
      print "rst_rcvd:   ", row[7]
      print "qsl_sent:   ", row[8]
      print "qsl_rcvd:   ", row[9]
      print "mode:       ", row[10]
      print "band:       ", row[11]
      print "qslmsg:     ", row[12]
      print "qsl_via:    ", row[13]
      print "contest_id: ", row[14]
      print "srx:        ", row[15]
      print "stx:        ", row[16]
      print "my_qso_id:  ", row[17]
      print "comment:    ", row[18]

  cur.close()
