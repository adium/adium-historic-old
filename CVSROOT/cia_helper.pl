#!/usr/bin/perl -w

use strict;

my $input;
while(<STDIN>) {
    $input .= $_;
}

system('/usr/bin/perl', '/cvsroot/adium/CVSROOT/ciabot.pl', @ARGV, "< $input");

system('/usr/bin/perl', '/cvsroot/adium/CVSROOT/cia_mailbucket.pl', @ARGV, "< $input");
