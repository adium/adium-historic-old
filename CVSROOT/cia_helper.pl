#!/usr/bin/perl -w

use strict;

my $input;
while(<STDIN>) {
    $input .= $_;
}
print @ARGV;

print "Running CIA\n";
my $output = `/usr/bin/perl /cvsroot/adium/CVSROOT/ciabot.pl < "$input"`;
print $output;

print "Mailing RSS\n";

$output = `/usr/bin/perl /cvsroot/adium/CVSROOT/cia_mailbucket.pl < "$input"`;

print $output;
