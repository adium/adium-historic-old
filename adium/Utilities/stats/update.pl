#!/usr/bin/perl

# $Id: update.pl,v 1.4 2003/12/22 20:57:22 jmelloy Exp $

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

    chdir("$key");

    my $filename = "directory.log";

    unlink $filename;

    open(STDOUT, ">$filename");

    system('cvs', '-z3', 'log', '-l');

    close STDOUT;

    chdir("/Users/jmelloy/clean-adium");
}

if(@files > 0) {
    system('touch', 'changes');
}
