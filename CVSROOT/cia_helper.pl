#!/usr/bin/perl -w

use strict;

my $input;
while(<STDIN>) {
    $input .= $_;
}

print "Running CIA\n";
open(CIA,  "| /usr/bin/perl /cvsroot/adium/CVSROOT/ciabot.pl @ARGV");
print CIA $input;
close CIA;

print "Mailing RSS\n";

open(RSS, "| /usr/bin/perl /cvsroot/adium/CVSROOT/cia_mailbucket.pl @ARGV");
print RSS $input;
close RSS;
