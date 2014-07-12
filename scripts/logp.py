#!/usr/local/bin/python
#$Id: logp.py,v 1.3 2013/11/15 14:41:43 kenji Exp $

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
      `my_qso_id` from qso where `call` glob ? and `qsl_rcvd` <> \'I\'
      order by `qso_date` || `time_on`
      """, (q,))
    for row in cur.fetchall():
      print '|'.join(map(int2str, list(row)))

  cur.close()
