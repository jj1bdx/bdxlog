#!/usr/local/bin/python
#$Id: logs.py,v 1.9 2013/11/15 15:07:06 kenji Exp $

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
  # enable extension loading
  con.enable_load_extension(True)
  # load regexp extension
  con.load_extension("/home/kenji/txt/hamradio/LOGS/scripts/sqlite3-pcre/pcre.so")
  # disable extension loading after loading necessary extensions
  con.enable_load_extension(False)

  cur = con.cursor()

  for arg in sys.argv[1:]:
    t = (arg,)
    # use "(?i)" (case insensitive) internal option prefix for PCRE
    cur.execute("""
      select `qso_date`, `time_on`, `my_call`, `call`, `band`, `mode`,
      `my_qso_id` from qso where `call` regexp \'(?i)\' || ? and `qsl_rcvd` <> \'I\'
      order by `qso_date` || `time_on`
      """, t)
    for row in cur.fetchall():
      print '|'.join(map(int2str, list(row)))

  cur.close()
