#!/usr/bin/perl

use warnings;
use strict;

open(STDERR, ">errors.txt");

my @files = `cvs -z3 -nq up | fgrep -v ?`;

#my @files = split($file, "\n");

for (my $i = 0; $i < @files; $i++) {
    my $filename = $files[$i];
    
    chomp($filename);
    $filename =~ s/^. *//;
    $filename = $filename . ".log";

    unlink $filename;
}
