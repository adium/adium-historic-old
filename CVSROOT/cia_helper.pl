#!/usr/bin/perl -w

use strict;

my $input;
while(<STDIN>) {
    $input .= $_;
}

print "Running CIA";
my $output = `/usr/bin/perl /cvsroot/adium/CVSROOT/ciabot.pl < $input`;
print $output;

print "Mailing RSS";
$output = `/usr/bin/perl /cvsroot/adium/CVSROOT/cia_mailbucket.pl < $input`;

print $output;
