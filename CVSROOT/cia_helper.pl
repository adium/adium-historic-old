#!/usr/bin/perl -w

use strict;

my $input = join("", <STDIN>);

my $args = "\"" . $ARGV[0] . "\" " . $ARGV[1];

open(CIA,  "| /usr/bin/perl /Users/jmelloy/adium/CVSROOT/ciabot.pl $args") or die "shit:  $!\n";
print CIA $input;
close CIA;


open(RSS, "| /usr/bin/perl /Users/jmelloy/adium/CVSROOT/cia_mailbucket.pl $args") or die "fuck: $!\n";
print RSS $input;
close RSS;
