#!/usr/bin/perl -I/home/jmelloy/lib/perl5/site_perl/5.6.1/

# $Id: make_logfile.pl,v 1.10 2004/01/05 15:37:42 jmelloy Exp $

use warnings;
use strict;

use File::List;

my $search = new File::List("/home/jmelloy/adium");
my @filelist = @{ $search->find(".") };
my %directories;

foreach my $file (@filelist) {
    
    $file =~ s/\/home\/jmelloy\/adium\/(.*\/).*/$1/;

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
