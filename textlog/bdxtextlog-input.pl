#!/usr/local/bin/perl
# $Id: bdxtextlog-input.pl,v 2.1 2013/10/14 07:21:32 kenji Exp kenji $

# event logger for textlog format
# by Kenji Rikitake, JJ1BDX/3

# this program performs no dupe check

# NOTE: all time is in UTC

# Command syntax:
# 	bdxtextlog-input.pl -f filename

# Usage:
# Type in the callsign then the time is recorded 
# Type in other entries for the QSO as well
# Commit a qso or discard the 

# Terminal input syntax: (case insensitive)
#   if the first letter of prompt 
#   [0-9A-Z]: callsign 
#             for the first entry, time is logged also
#   [/]: parse as changing band in MHz and mode 
#        (e.g., "/21 CW" or "/40M SSB")
#   [>]: enter sent RST ">599" (default: 599 or 59)
#   [<]: enter received RST "<559" (default: 599 or 59)
#   [^]: enter UTC QSO time "^0437" (default: set when callsign is entered)
#   ["]: enter comment such as "comment text" (default: no comment)
#   [@]: enter QSL_VIA such as @jb1cde (default: no qsl manager)
#   [!]: commit a QSO and reinitialize the temporary buffer
#   [-]: DISCARD a QSO with confirmation
#   [?]: answers current entry
#   [$] or quit or exit: terminate and exit
#   others: error and return to the input loop

# strict checking

use strict;

# libraries
use FileHandle;
use Getopt::Std;
use Term::ReadLine;
# for using UTC
use Time::gmtime;

my %mhztobands = (
        "1.8" => "160M",
        "1.9" => "160M",
	"3.5" => "80M", 
	"3.8" => "75M", 
	"5" => "60M", 
	"7" => "40M", 
	"10" => "30M", 
	"14" => "20M", 
	"18" => "17M", 
	"21" => "15M", 
	"24" => "12M", 
	"28" => "10M",
	"50" => "6M", 
	"144" => "2M", 
	"430" => "70CM" 
);

my %modetorst = (
	"AM" => "59",
	"CW" => "599",
	"FAX" => "595",
	"FM" => "59",
	"FSK31" => "599",
	"HELL" => "599",
	"JT65" => "599",
	"JT9" => "599",
	"MFSK16" => "599" ,
	"MT63" => "599",
	"PSK31" => "599",
	"PSK63" => "599",
	"RTTY" => "599",
	"SSB" => "59",
	"SSTV" => "595"
);


# Term::ReadLine object here
my $term = Term::ReadLine->new("bdxtextlog-input");
my $OUT = $term->OUT() || *STDOUT;
my $prompt;

# default filename
my $logfile = "bdxtextlog.txt";

# current band in MHz and mode
my $logtime_tm;
my $qso_year;
my $qso_month;
my $qso_mday;
my $qso_hour;
my $qso_min;
my $hour_min;
my $callsign;
my $band;
my $mode;
my $rst_sent;
my $rst_sent_def;
my $rst_rcvd;
my $rst_rcvd_def;
my $qsl_via;
my $comment;
my $textlog_output;
my $newband;
my $newmode;

# actual running code begins here

sub init_qso {
	$logtime_tm = Time::gmtime::gmtime(0);
	$callsign = "";
	$rst_sent = $rst_sent_def;
	$rst_rcvd = $rst_rcvd_def;
	$qsl_via = "";
	$comment = "";
}

sub generate_textlog {
	# create output entry
	$textlog_output = sprintf
		"%4d-%2.2d-%2.2d %s (%s)\n%2.2d%2.2d %s <%s >%s",
		$qso_year,
		$qso_month,
		$qso_mday,
		$band, $mode,
		$qso_hour,
		$qso_min,
		$callsign,
		$rst_rcvd, $rst_sent;
	if (length $qsl_via > 0) {
		$textlog_output .= " \@$qsl_via";
	}
	if (length $comment > 0) {
		$textlog_output .= " \"$comment\"";
	}
	$textlog_output .= "\n";
}

# initial process

# parse command line options
getopts("f:");
# set filename
if ($Getopt::Std::opt_f) {
	$logfile = "$Getopt::Std::opt_f";
}

# initial prompts

print "bdxtextlog-input\n";
print '$Id: bdxtextlog-input.pl,v 2.1 2013/10/14 07:21:32 kenji Exp kenji $', "\n\n";
print "all time in UTC, appended to $logfile\n";

# reopen log file in append mode, always flushing
open BDXLOG_FILE, ">>" . $logfile or
	die "Unable to append to $logfile: $!\n";
BDXLOG_FILE->autoflush(1);

# set default values
$band = "20M";
$mode = "CW";
$rst_sent_def = "599";
$rst_rcvd_def = "599";
init_qso;

print "band = $band, mode = $mode\n";

# command loop begins

$prompt = $callsign . " ->";
while (defined ($_ = $term->readline($prompt))) {
	# / BAND MODE 
	if (/^\/\s*(\S+)\s+(\S+)\s*$/) {
		$newband = uc $1; 
		$newmode = uc $2;

		if (defined $modetorst{$newmode}) {
			$mode = $newmode;
			$rst_sent_def = $modetorst{$newmode};
			$rst_rcvd_def = $rst_sent_def;
			print "changed mode to $mode\n";
		} else {
			print "invalid mode, no change\n";
		}
		
		if (defined $mhztobands{$newband}) {
			$band = $mhztobands{$newband};
			print "set band to $band\n";
		} else {
			my @bands = values %mhztobands;
			my $found = 0;
			while (@bands) {
				if (pop(@bands) eq $newband) {
					$band = $newband;
				        print "set band to $band\n";
					$found = 1;
					last;
				}	
			}
			if ($found == 0) {
				print "invalid band, no change\n";
			}	
		}

		print "new band = $band, new mode = $mode\n";
	}	
	# > rst_sent
	elsif (/^\>\s*(\S+)\s*$/) {
		$rst_sent = $1;
		generate_textlog; print $textlog_output;
	}
	# < rst_rcvd
	elsif (/^\<\s*(\S+)\s*$/) {
		$rst_rcvd = $1;
		generate_textlog; print $textlog_output;
	}
	# ^ qso_hour/qso_min
	elsif (/^\^\s*(\S+)\s*$/) {
		$hour_min = $1;
		$qso_hour = substr($hour_min, 0, 2) + 0;
		$qso_min = substr($hour_min, 2, 2) + 0;
		generate_textlog; print $textlog_output;
	}
	# @ qsl_via
	elsif (/^\@\s*(\S+)\s*$/) {
		$qsl_via = uc $1;
		generate_textlog; print $textlog_output;
	}
	# "comment" (the second doublequote terminates the comment)
	elsif (/^\"([^\"]+)\"/) {
		$comment = $1;
		generate_textlog; print $textlog_output;
	}
	# ?
	elsif (/^\?\s*$/) {
		generate_textlog; print $textlog_output;
	}
	# $ or quit or exit
	elsif (/^\$\s*$/ || 
		/^\s*[qQ][uU][iI][tT]\s*$/ || 
		/^\s*[eE][xX][iI][tT]\s*$/ ) {
		# exiting the program
		die "bdxtextlog-input terminated at ", 
		    gmctime(), " UTC\n";
	}
	# - discard entry with confirmation
	elsif (/^\-\s*$/) {
		$prompt = "Discard QSO for $callsign, GO or no (keep)? ->";
		$_ = $term->readline($prompt);
		if (/^\s*[Gg][Oo]\s*$/) {
		# reset the values to default if GO
			init_qso;
			print "Log entry cleared\n";
		} else {
		# Do nothing if not
			print "QSO retained\n";
			generate_textlog; print $textlog_output;
		}
	}
	# ! commit entry without question
	elsif (/^\!\s*$/) {
		# append the output to the file
		generate_textlog;
		print BDXLOG_FILE $textlog_output, "\n";
		# and the output to the console
		print "Following entry committed with a blank line:\n";
		print $textlog_output;
		# reset the values to default if GO
		init_qso;
		print "Log entry cleared\n";
	}
	elsif (/^([0-9A-Za-z]\S*)\s*$/) {
		# register time of callsign input
		# recording time in UTC here
		# 1970-01-01 is a blank value
		if ($logtime_tm->year == 70) {
			init_qso;
   			$logtime_tm = Time::gmtime::gmtime;
			# set each field of QSO date/time here
			$qso_year = $logtime_tm->year + 1900;
			$qso_month = $logtime_tm->mon + 1;
			$qso_mday = $logtime_tm->mday + 0;
			$qso_hour = $logtime_tm->hour + 0;
			$qso_min = $logtime_tm->min + 0;
			print "Time recorded\n";
		}
		# processing callsign and received contest number
		$callsign = uc $1;
		generate_textlog; print $textlog_output;
	}
	else {
		# report usage
		print "Terminal input syntax: \n";
		print "if the first letter after the prompt\n"; 
		print "[0-9A-Z]: callsign\n"; 
		print "          for the first entry, time is logged also\n";
		print "[/]: parse as changing band in MHz and mode\n"; 
		print "[>]: enter sent RST\n"; 
		print "[<]: enter received RST\n";
		print "[^]: enter UTC QSO time\n";
		print "[\"]: enter comment\n";
		print "[@]: enter QSL_VIA\n";
		print "[!]: commit a QSO and reinitialize the temporary buffer\n";
		print "[-]: DISCARD a QSO with confirmation\n";
		print "[?]: answers current entry\n";
		print "[\$] or quit or exit: terminate and exit\n";
		print "Current entry:\n";
		generate_textlog; print $textlog_output;
	}
	# reset prompt
	$prompt = $callsign . " ->";
}

die "Abnormal exit";
