#!/usr/local/bin/python
#$Id: logunsent.py,v 1.3 2013/11/15 15:07:06 kenji Exp $

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

  cur.execute("""
    select `qso_date`, `time_on`, `my_call`, `call`, `band`, `mode`,
    `rst_sent`,`qsl_via`,`comment`,
    `my_qso_id` from qso where `qsl_sent` == \'N\'
     order by call
      """)
  for row in cur.fetchall():
    print '|'.join(map(int2str, list(row)))

  cur.close()
