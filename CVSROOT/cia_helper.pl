#!/usr/bin/perl

use warnings;
use strict;

my $input;
while(<STDIN>) {
    $input .= $_;
}

system('/usr/bin/perl', 'ciabot.pl', @ARGV);
print $input;

system('/usr/bin/perl', 'cia_mailbucket.pl', @ARGV);
print $input;
