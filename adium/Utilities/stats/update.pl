#!/usr/bin/perl

# $Id: update.pl,v 1.3 2003/12/09 17:50:55 jmelloy Exp $

use warnings;
use strict;

open(STDERR, ">errors.txt");

my @files = `cvs -z3 -nq up | fgrep -v ?`;

for (my $i = 0; $i < @files; $i++) {
    my $filename = $files[$i];
    
    chomp($filename);
    $filename =~ s/^. *//;
    $filename = $filename . ".log";

    unlink $filename;
}

if(@files > 0) {
    system('touch', 'changes');
}
