#!/usr/bin/perl -w

use strict;

my $input;
while(<STDIN>) {
    $input .= $_;
}

print "Running CIA\n";
my $output = `/usr/bin/perl /cvsroot/adium/CVSROOT/ciabot.pl @ARGV \n$input`;
print $output;

print "Mailing RSS\n";

$output = `/usr/bin/perl /cvsroot/adium/CVSROOT/cia_mailbucket.pl @ARGV \n$input`;

print $output;
