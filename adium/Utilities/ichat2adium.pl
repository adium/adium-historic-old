#!/usr/bin/perl

# $Id: ichat2adium.pl,v 1.1 2003/11/29 07:12:34 jmelloy Exp $
#
# This program imports iChat logs using the program Logorrhea.  Get it from
# http://spiny.com/logorrhea/
#
# Using Logorrhea, export all of your chats.
#
# Then run this script with "ichat2adium.pl filename"  or run from the same
# directory as the exported contents.
#
# Records that make no sense will be sent to "adiumLogs/bad".
#
# You should be able to drop the adiumLogs folder into ~/Library/Application
# Support/Users/YOU/Logs/.

use warnings;
use strict;

system('mkdir', 'adiumLogs');

my $file;
if(@ARGV > 0) {
    $file = $ARGV[0];
} else {
    $file = "iChat Export.txt";
}

open(FILE, $file) or die qq{Unable to open "$file": $!};

$/ = "\r";

my @input = <FILE>;
my $outfile = "adiumLogs/bad";

close(FILE);

for (my $i = 0; $i < @input; $i++) {
    my ($chatname, $sender, $date, $time, $message);
    my ($day, $month, $year);
    
    $_ = $input[$i];
    
    ($chatname, $sender, $date, $time, $message) =
    /(.*?)\t(.*?)\t(.*?)\t(.*?)\t.*?\t(.*)\r/s;

    $_ = $date;
    
    if($date) {
        ($month, $day, $year) = /(\d\d)\/(\d\d)\/(\d\d\d\d)/;
    }
    
    if($chatname && $sender && $date && $month && $day && $year && $message) {
        $outfile = "adiumLogs/$chatname ($year|$month|$day).adiumLog";

        open(OUT, ">>$outfile");
        print OUT "$time $sender: $message\n";
    } else {
        $outfile = "adiumLogs/bad";
        open(OUT, ">>$outfile");
        print OUT "$input[$i]";
        print "Bad record found at line $i.  Logged in adiumLogs/bad.\n";
    }
    close OUT;
}
