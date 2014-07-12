#!/usr/local/bin/perl
# originally by OK1FOU modified by Kenji Rikitake, JJ1BDX
# $Id: sqliteadif-bdx.pl,v 1.3 2013/11/17 14:30:03 kenji Exp $
# converting SQLite data to ADIF
# usage: sqliteadif-bdx.pl -c mycall -b begin_date -e end_date 
# default end_date: yesterday

# tab-separated contents:
#  create table qso (
#  my_call         varchar(20),
#  my_qth          varchar(40),
#  qso_date        date      ,
#  time_on         time     ,
#  time_off        time    ,
#  call            varchar(20),
#  rst_sent        varchar(4),
#  rst_rcvd        varchar(4),
#  qsl_sent        char(1)  ,
#  qsl_rcvd        char(1)   ,
#  mode            varchar(12),
#  band            varchar(8),
#  qslmsg          varchar(64),
#  qsl_via         varchar(20),
#  contest_id      varchar(64),
#  srx             varchar(16),
#  stx             varchar(16),
#  my_qso_id       int(11),
#  comment         text      
#  );

# declarations

use strict;

# libraries
use Getopt::Std;
use DBI;
use Time::gmtime;
# CPAN Date::Calc from port devel/p5-Date-Calc
use Date::Calc qw(Add_Delta_Days);

# ADIF element string

sub elem {
    my ($tag, $data) = @_ ;
        return sprintf( '<%s:%d>%s', $tag, length($data), $data) ;
}

# MAIN PROGRAM: initialization

# parse command line options
my ($my_call, $begin_date, $end_date);
my ($end_year, $end_month, $end_day);
my ($qso_date, $time_on, $call, $band, $mode, $qslmsg, $rst_sent);

$begin_date="1976-03-10";
my $ytm = gmtime();
($end_year, $end_month, $end_day) =
	Add_Delta_Days($ytm->year+1900, ($ytm->mon)+1, $ytm->mday, -1);
$end_date = sprintf ("%04d-%02d-%02d", $end_year, $end_month, $end_day);

getopts("c:b:e:");
# set filename
# (hey, this is really strict, huh?)
if ($Getopt::Std::opt_c) {
        $my_call = "$Getopt::Std::opt_c";
}
if ($Getopt::Std::opt_b) {
        $begin_date = "$Getopt::Std::opt_b";
}
if ($Getopt::Std::opt_e) {
        $end_date = "$Getopt::Std::opt_e";
}

if (not (defined($my_call))) {
	 die "usage: sqliteadif-bdx.pl -c mycall -b begin_date -e end_date\n";
}

# connect database
my $dbname = "/home/kenji/txt/hamradio/LOGS/SQLite-log/hamradio_log.sqlite";
my $dsn = "DBI:SQLite:dbname=".$dbname;
my $dbh = DBI->connect($dsn, "", "",
                       { RaiseError => 1, PrintError => 0 });
# disable automatic termination on error
$dbh->{RaiseError} = 0;
print STDERR "Connected from SQLite\n";

my $stmt = sprintf(
          "SELECT strftime('%%Y%%m%%d',`qso_date`), ".
	  "strftime('%%H%%M', `time_on`), ".
	  "`call`, `band`, `mode`, `rst_sent`, `qslmsg` ".
	  "FROM `qso` WHERE `my_call` = %s AND ".
	  "`qso_date` >= %s AND `qso_date` <= %s ",
	  $dbh->quote($my_call),
	  $dbh->quote($begin_date),
	  $dbh->quote($end_date));
print STDERR "$stmt\n";

my $sth = $dbh->prepare($stmt);
$sth->execute();
my $count = 0;
while (my $ref = $sth->fetchrow_arrayref()) {
	my $out = "";
	$out .= elem("qso_date", $ref->[0]);
	$out .= elem("time_on", $ref->[1]);
	$out .= elem("call", $ref->[2]);
	$out .= elem("band", $ref->[3]);
	$out .= elem("mode", $ref->[4]);
	$out .= elem("rst_sent", $ref->[5]);
	$out .= elem("qslmsg", $ref->[6]);
	print $out . "<eor>\n";
	++$count;
}
print STDERR "rows returned: $count\n";

# enable automatic termination on error
$dbh->{RaiseError} = 1;
# disconnect from database
$dbh->disconnect();
print STDERR "Disconnected from SQLite\n";
# exit
exit (0);

