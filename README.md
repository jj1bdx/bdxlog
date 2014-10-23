# bdxlog

Ham radio station logging system for JJ1BDX (all based on CUI, running on FreeBSD)

## Requirements

FreeBSD Port or pkg kits of:

* Perl 5.18.x
* Python 2.7.x
* SQLite 3

## Notes

* Example callsign of JO3FUO was once assigned to Kenji Rikitake from 2005 to 2014, currently deactivated.

## TODO, or bdxlog-ng plan

* Pathname fix for each scripts
* Documentation
* Remove `savelog` (GPLv2)
* Make use of git
   * Version control of the log files
   * Getting the most out of the append-only characteristics
* Backing up sqlite DB (is git suitable with this?)
* Integration with LoTW / tqsllib tools
* Migration from old set of files
