#!/usr/bin/perl -I/home/jmelloy/lib/perl5/site_perl/5.6.1/

# $Id: find_logs.pl,v 1.3 2003/12/08 17:06:46 jmelloy Exp $

use warnings;
use strict;

use File::List;

my $search = new File::List("/home/jmelloy/adium");
my @filelist = @{ $search->find("\.log") };

my $outfile = "master.log";
open(OUT, ">$outfile");

foreach my $file (@filelist) {

    open(FILE, "<$file");

    print OUT <FILE>;

    close FILE;
}
