#!/bin/sh
# $Id: sqlite-logdump.sh,v 1.1 2009/04/30 10:26:13 kenji Exp $
LOGFILEDIR=/home/kenji/txt/hamradio/LOGS/SQLite-log
DBFILE=hamradio_log.sqlite
DUMPFILE=sqlite-log-dump.txt
#
~/bin/savelog ${LOGFILEDIR}/${DUMPFILE}
chmod 0400 ${LOGFILEDIR}/OLD/${DUMPFILE}.*
#
echo ".dump qso" | \
  /usr/local/bin/sqlite3 ${LOGFILEDIR}/${DBFILE} > ${LOGFILEDIR}/${DUMPFILE}
chmod 0600 ${LOGFILEDIR}/${DUMPFILE}
#
