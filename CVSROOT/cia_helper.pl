#!/usr/bin/perl -w

use strict;

my $input;
while(<STDIN>) {
    $input .= $_;
}

system('/usr/bin/perl', '/cvsroot/adium/CVSROOT/ciabot.pl', @ARGV);
print $input;

system('/usr/bin/perl', '/cvsroot/adium/CVSROOT/cia_mailbucket.pl', @ARGV);
print $input;
