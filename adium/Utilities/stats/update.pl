#!/usr/bin/perl

# $Id: update.pl,v 1.2 2003/12/08 04:31:00 jmelloy Exp $

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
