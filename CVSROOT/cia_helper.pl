#!/usr/bin/perl -w

use strict;
use IO::Handle;


PIPEHANDLE->autoflush(1);

my $input;

while(<STDIN>) {
    $input .= $_;
}

print $input;
print @ARGV;

print "Running CIA\n";
open(CIA,  "| /usr/bin/perl /cvsroot/adium/CVSROOT/ciabot.pl @ARGV") or die "shit: $!";
print CIA $input;
close CIA;

print "Mailing RSS\n";

open(RSS, "| /usr/bin/perl /cvsroot/adium/CVSROOT/cia_mailbucket.pl @ARGV") or die "fuck $!";
print RSS $input;
close RSS;
