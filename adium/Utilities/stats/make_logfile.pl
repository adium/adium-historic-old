#!/usr/bin/perl -I/home/jmelloy/lib/perl5/site_perl/5.6.1/

# $Id: make_logfile.pl,v 1.9 2003/12/22 22:01:05 jmelloy Exp $

use warnings;
use strict;

use File::List;

my $search = new File::List("/Users/jmelloy/clean-adium");
my @filelist = @{ $search->find(".") };
my %directories;

foreach my $file (@filelist) {
    
    $file =~ s/\/Users\/jmelloy\/clean-adium\/(.*\/).*/$1/;

    print $file . "\n";

    if($file =~ m/\// && !($file =~ m/CVS/)) {
        $directories{$file} = 1;
    } else {
        $directories{"."} = 1;
    }
}

foreach my $key (keys %directories) {
    my $logfile = $key . "directory.log";
    

    if(!-e $logfile) {
        warn $key . "\n";

        open(STDOUT, ">$logfile");

        system('cvs', '-z3', 'log', '-l', $key);

        close STDOUT;
    }

}
