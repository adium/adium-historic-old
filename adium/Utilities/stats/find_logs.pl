#!/usr/bin/perl

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
