#!/usr/bin/perl

# $Id: ichat2adium.pl,v 1.3 2003/11/29 18:17:41 jmelloy Exp $
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
my $users = 0;
my @usernames;
my @chatnames;

if(@ARGV > 0) {
    $file = $ARGV[0];
} else {
    $file = "iChat Export.txt";
}

if ($ARGV[1] eq "--usernames") {
    $users = 1;
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

    if($users && $chatname && $sender) {
        my $userfound = 0;
        for(my $j = 0; $j < @chatnames; $j++) {
            if ($chatnames[$j] eq $chatname) {
                $userfound = 1;
                $chatname = $usernames[$j];
            }
        }
        if($userfound == 0) {
            push(@chatnames, $chatname);
            print "What username is associated with $chatname [$sender]:";
            $/ = "\n";
            my $input = <STDIN>;
            chomp($input);
            if(length($input) == 0) {
                push(@usernames, $sender);
                $chatname = $sender;
            } else {
                push(@usernames, $input);
                $chatname = $input;
            }
        }
    }

    $chatname =~ s/ //g;

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
