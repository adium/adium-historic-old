#!/usr/bin/perl

# $Id: find_logs.pl,v 1.2 2003/12/08 03:53:26 jmelloy Exp $

use warnings;
use strict;

use File::List;

my $search = new File::List("/Users/jmelloy/clean-adium");
my @filelist = @{ $search->find("\.log") };

my $outfile = "master.log";
open(OUT, ">$outfile");

foreach my $file (@filelist) {

    open(FILE, "<$file");

    print OUT <FILE>;

    close FILE;
}
