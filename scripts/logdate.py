#!/usr/local/bin/python
#$Id: logdate.py,v 1.4 2013/11/15 15:07:06 kenji Exp $

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

  t = (sys.argv[1], sys.argv[2])
  cur.execute("""
    select `qso_date`, `time_on`, `my_call`, `call`, `band`, `mode`,
    `my_qso_id` from qso where `qso_date` >= ? and `qso_date` <= ?
    and `qsl_rcvd` <> 'I'
    order by `qso_date` || `time_on`
    """, t)
  for row in cur.fetchall():
    print '|'.join(map(int2str, list(row)))

  cur.close()
