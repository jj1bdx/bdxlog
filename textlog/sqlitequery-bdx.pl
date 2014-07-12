#!/usr/local/bin/perl
# originally by OK1FOU modified by Kenji Rikitake, JJ1BDX
# $Id: sqlitequery-bdx.pl,v 1.1 2009/05/01 00:28:01 kenji Exp $
# converting textdata to minimal SQLite QSO table queries
# usage: sqlitequery-bdx.pl -c mycall -q my_qth
#   stdin: textlog file

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

# MAIN PROGRAM: initialization

# parse command line options
my ($my_call, $my_qth);
getopts("c:q:");
# set filename
# (hey, this is really strict, huh?)
if ($Getopt::Std::opt_c) {
        $my_call = "$Getopt::Std::opt_c";
}
if ($Getopt::Std::opt_q) {
        $my_qth = "$Getopt::Std::opt_q";
}

if (not (defined($my_call) and
         defined($my_qth))) {
	 die "usage: sqlite-bdx.pl -c mycall -q my_qth\n".
	     "stdin: textlog file\n";
}

# connect database
my $dbname = "/home/kenji/txt/hamradio/LOGS/SQLite-log/hamradio_log.sqlite";
my $dsn = "DBI:SQLite:dbname=".$dbname;
# disable automatic termination on error
my $dbh = DBI->connect($dsn, "", "",
                       { RaiseError => 0, 
			 AutoCommit => 1,
			 PrintError => 0 });
print STDERR "Connected to SQLite\n";

# data structures

# mandatory/minimum QSO data
# ADIF required: call, band, mode, qso_date, time_on, qsl_sent
# locally required: qsl_sent, qsl_rcvd
my %Basic = (
    call     => '',
    band     => '',
    mode     => '',
    qso_date => '',
    time_on  => '',
    rst_sent => '',
    qsl_sent => '',
    qsl_rcvd => ''
);

my %AddOns ;   # constants assigned by code=VALUE
my %Notes ;    # additional data from QSO line

# subroutines/functions

sub get_generals {
    my $what = shift ;
    my ($status, $sent, $rcvd);

    # mode: (cw)
    if( $what =~ /^\((.+)\)$/) {
        $Basic{mode} = uc $1 ;
        return 1 ;
    }
    # date: 2003-12-12
    elsif($what =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
        $Basic{qso_date} = "$1$2$3";
        return 1 ;
    }
    # band: 20m
    elsif($what =~ /^\d+(c|m)?m$/i) {
        $Basic{band} = uc $what;
        return 1 ;
    }
    # utc: 1234
    elsif($what =~ /^\d{4}$/) {
        $Basic{time_on} = $what ;
        return 1 ;
    }
    # rst_rcvd: <439
    elsif($what =~ /^<(.+)$/) {
        $Basic{rst_rcvd} = uc $1 ;
        return 1 ;
    }
    # rst_sent: >599
    elsif($what =~ /^>(.+)$/) {
        $Basic{rst_sent} = uc $1 ;
        return 1 ;
    }
    # qsl_stat: ^d (to be deprecated, but supported)
    elsif($what =~ /^\^(\S)$/) {
	$status = uc $1;
	if ($status eq "B") { 
	    $sent = "Y"; $rcvd = "N";
	}
	elsif ($status eq "C") { 
	    $sent = "Y"; $rcvd = "Y";
	}
	elsif ($status eq "D") { 
	    $sent = "Y"; $rcvd = "N";
	}
	elsif ($status eq "N") { 
	    $sent = "I"; $rcvd = "N";
	}
	elsif ($status eq  "R") { 
	    $sent = "I"; $rcvd = "I"; 
	}
	elsif ($status eq  "T") { 
	    $sent = "N"; $rcvd = "Y";
	}
	elsif ($status eq  "W") { 
	    $sent = "I"; $rcvd = "N";
	}
	else {
	    $sent = "N"; $rcvd = "N"; 
	}
        $Basic{qsl_sent} = $sent ;
        $Basic{qsl_rcvd} = $rcvd ;
        return 1 ;
    }
    # qsl_via: @viacall
    elsif($what =~ /^\@(.+)$/) {
        $Notes{qsl_via} = uc $1 ;
        return 1 ;
    }
    # qsl_rcvd: [y
    elsif($what =~ /^\133(\S)$/) {
        $Basic{qsl_rcvd} = uc $1 ;
	# DEBUG: print STDERR "qsl_rcvd ", uc $1, "\n";
        return 1 ;
    }
    # qsl_sent: ]n
    elsif($what =~ /^\135(\S)$/) {
        $Basic{qsl_sent} = uc $1 ;
	# DEBUG: print STDERR "qsl_sent ", uc $1, "\n";
        return 1 ;
    }
    # call : all else
    else { $Basic{call} = uc $what; return 1 }
    return 0 ;
}

sub defvar {
    my $line = shift ;
    if($line =~ /^(\w+)=(.+)?/) {
        if( defined $2 ) {
            $AddOns{$1} = $2 ;
        }
        else {
            delete $AddOns{$1};
        }
        return 1 ;
    }
    return 0 ;
}

sub query_output {
    for (qw/call qso_date time_on band mode rst_sent qsl_sent qsl_rcvd/) {
        return unless $Basic{$_} ;
    }
    my $out ;
    my ($year, $month, $day);
    my ($hour, $min);
    my $stmt;
    my ($qso_date, $time_on);
    my ($qslmsg, $qsl_via, $comment);

    # unpack time;
    ($year, $month, $day) = unpack("A4A2A2", $Basic{qso_date});
    ($hour, $min) = unpack("A2A2", $Basic{time_on});
    $qso_date = $year.'-'.$month.'-'.$day;
    $time_on = $hour.':'.$min.':00';

    $qslmsg = "";
    if (exists $AddOns{qslmsg}) {
    	$qslmsg = $AddOns{qslmsg};
    }
    $qsl_via = "";
    if (exists $Notes{qsl_via}) {
    	$qsl_via = $Notes{qsl_via};
    }
    $comment = "";
    if (exists $Notes{comment}) {
    	$comment = $Notes{comment};
    }

    # create SQL statement
    # use REPLACE here for allowing updates of existing QSOs
    $stmt = sprintf (
            "REPLACE INTO qso 
	    (`my_call`, `my_qth`, `qso_date`, `time_on`, `time_off`,
	    `call`, `rst_sent`, `rst_rcvd`, `qsl_sent`, `qsl_rcvd`,
	    `mode`, `band`, `qslmsg`, `qsl_via`, 
	    `comment`)
	    VALUES(%s, %s, %s, %s, %s,
	    %s, %s, %s, %s, %s, 
	    %s, %s, %s, %s, 
	    %s)",
	    $dbh->quote ($my_call), 
	    $dbh->quote ($my_qth), 
	    $dbh->quote ($qso_date), 
	    $dbh->quote ($time_on), 
	    $dbh->quote ($time_on),
	    $dbh->quote ($Basic{call}), 
	    $dbh->quote ($Basic{rst_sent}), 
	    $dbh->quote ($Basic{rst_rcvd}), 
	    $dbh->quote ($Basic{qsl_sent}), 
	    $dbh->quote ($Basic{qsl_rcvd}), 
	    $dbh->quote ($Basic{mode}), 
	    $dbh->quote ($Basic{band}), 
	    $dbh->quote ($qslmsg), 
	    $dbh->quote ($qsl_via), 
	    $dbh->quote ($comment)
	    );

    # delete per-qso Notes and Basic entries here

    for (keys %Notes)  {
         delete $Notes{$_} ;
    }
    for (qw/call time_on rst_sent rst_rcvd qsl_send qsl_rcvd/) {
        delete $Basic{$_}
    }

    # submit processing query to SQLite
    print $stmt."\n";
    return $dbh->do ($stmt) or
	    warn "Query failed: $DBI::errstr ($DBI::err)\en";
}

# MAIN PROGRAM: execution

my $line = <> ;
unless( $line =~ /^#TEXTLOG\s+\d+\.\d+/ ) { 
print STDERR "This file is not TEXTLOG file\n"; 
$dbh->disconnect();
die "Disconnected from SQLite and terminated\n";
}

while ($line = <>) {
    # skip comment lines
    unless ($line =~ /^(#|(\/\/)).*/ ) {
        # pick up comments
        my $what = $line;
    	if($what =~ /\".*\"/) {
	    chop $what;
    	    $what =~ s{^[^"]*\"}{} ;
	    $what =~ s{\".*$}{} ;
            $Notes{comment} = $what ;
        }
        $line =~ s{\".*\"}{} ;

	$Basic{qsl_sent} = "N";
	$Basic{qsl_rcvd} = "N";

        unless (defvar($line)) {
            while( $line =~ s/\s*(\S+)// ) {
                my $word = $1 ;
                get_generals($word) ;
            }

        query_output();
        }
    }
}

# enable automatic termination on error
$dbh->{RaiseError} = 1;
# disconnect from database
$dbh->disconnect;
print STDERR "Disconnected from SQLite \n";
# exit
exit (0);

