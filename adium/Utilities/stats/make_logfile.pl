#!/usr/bin/perl -I/home/jmelloy/lib/perl5/site_perl/5.6.1/

# $Id: make_logfile.pl,v 1.3 2003/12/08 17:06:46 jmelloy Exp $

use warnings;
use strict;

use File::List;

my $search = new File::List("/home/jmelloy/adium");
my @filelist = @{ $search->find(".") };

foreach my $file (@filelist) {
    $file =~ s/\/home\/jmelloy\/adium\///;

    $_ = $file;

    my $contains_cvs  = /CVS/;
    my $contains_log = /\.log$/;

    if(!$contains_cvs && !$contains_log) {

        my $logfile = $file . ".log";
        $logfile =~ s/^ *//;

        if (!-e $logfile) {

            warn $file . "\n";

            open(STDOUT, ">$logfile");

            system('cvs', '-z3', 'log', $file);

            close STDOUT;
        }
    }
}
