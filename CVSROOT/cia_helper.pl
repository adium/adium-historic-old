#!/usr/bin/perl -w

use strict;

my $input;
my $args;

while(<STDIN>) {
    $input .= $_;
}

for(my $i = 0; $i < @ARGV; $i++) {
    $args .= @ARGV[$i] . " ";
}

open(CIA,  "| /usr/bin/perl /cvsroot/adium/CVSROOT/ciabot.pl $args") or die "shit: $!";
print CIA $input;
close CIA;


open(RSS, "| /usr/bin/perl /cvsroot/adium/CVSROOT/cia_mailbucket.pl $args") or die "fuck $!";
print RSS $input;
close RSS;
