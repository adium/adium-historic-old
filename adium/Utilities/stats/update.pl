#!/usr/bin/perl

# $Id: update.pl,v 1.6 2003/12/22 21:12:57 jmelloy Exp $

use warnings;
use strict;

open(STDERR, ">errors.txt");

my @files = `cvs -z3 -q up -d | fgrep -v ?`;

my %directories;

foreach my $filename (@files) {

    $filename =~ s/. (.*\/).*?$/$1/g;

    if($filename =~ m/\//) {
        $directories{$filename} = 1;
    } else {
        $directories{"."} = 1;
    }

}

foreach my $key (keys %directories) {
    warn $key;

    chomp ($key);

    my $filename = $key . "/" . "directory.log";

    unlink $filename;

    open(STDOUT, ">$filename");

    system('cvs', '-z3', 'log', '-l', $key);

    close STDOUT;

}

if(@files > 0) {
    system('touch', 'changes');
}
