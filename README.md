# bdxlog

Ham radio station logging system for JJ1BDX (all based on CUI, running on FreeBSD)

## requirements

FreeBSD Port utilities as:

* Perl 5.18.2
* Python 2.7.x
* SQLite 3

## TODO, or bdxlog-ng plan

* Pathname fix for each scripts
* Documentation
* Remove `savelog` (GPLv2)
* Make use of git
   * Version control of the log files
   * Getting the most out of the append-only characteristics
* Backing up sqlite DB (is git suitable with this?)
* Integration with LoTW / tqsllib tools
