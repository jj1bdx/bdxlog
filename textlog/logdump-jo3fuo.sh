#!/bin/sh
datetime=`env TZ="UTC" date "+%Y%m%d%H%M%S"`
newfilename=jo3fuo-${datetime}.txt
#
mv jo3fuo-now.txt ${newfilename}
./sqlitequery-bdx.pl -c JO3FUO -q JCC#2504 < ${newfilename}
mv ${newfilename} registered/jo3fuo/
chmod 400 registered/jo3fuo/*.txt
/home/kenji/txt/hamradio/LOGS/scripts/sqlite-logdump.sh
