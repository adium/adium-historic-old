#!/usr/bin/perl

# $Id: make_logfile.pl,v 1.2 2003/12/08 04:15:55 jmelloy Exp $

use warnings;
use strict;

use File::List;

my $search = new File::List("/Users/jmelloy/clean-adium");
my @filelist = @{ $search->find(".") };

foreach my $file (@filelist) {
    $file =~ s/\/Users\/jmelloy\/clean-adium\///;

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
