#!/usr/bin/perl

use warnings;
use strict;

my $proteus_log_file = "$ENV{HOME}/Library/Application Support/Instant Messaging/Profile/History.db";

my $aim_user;
for(my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq "--aim") {
        $aim_user = $ARGV[$i + 1];
    }
}

my $base_out = "AIM.$aim_user";

my @messages;

# The proteus tables are dumb.
# the schema for each is:
# identifier TEXT, (the username)
# date text,
# message text,
# incoming int,
# type int,
# url text
#
# I'm not actually sure what type and URL are for.
# Type seems to always be 1, and URL seems to always be empty.

my $query = "select substr(date, 0, 10), identifier, \'<div class=\\\"\' || case when incoming=1 then \'receive\' else \'send\' end || \'\\\"><span class=\\\"timestamp\\\">\' || substr(date, 12, 8) || \'</span><span class=\\\"sender\\\">\' || case when incoming = 1 then identifier else \'$aim_user\' end || \': </span><pre class=\\\"message\\\">\' || message || \'</pre></div>\' from \\\"aim-oscar\\\"";

@messages = `./sqlite "$proteus_log_file" "$query"`;

umask(000);

mkdir($base_out, 0777) unless (-d $base_out); 

foreach (@messages) {
    my $year;
    my $month;
    my $day;
    my $message;
    my $ident;
    my $outfile;

    ($year, $month, $day, $ident, $message) =
    /(\d*)\-(\d*)\-(\d*)\|(.*)\|(\<div.*\<\/div\>)/;

    mkdir("$base_out/$ident/", 0777) unless (-d "$base_out/$ident");

    $outfile = "$base_out/$ident/$ident ($year|$month|$day).html";

    open(OUT, ">>$outfile") or die;
    print OUT "$message\n";
    close OUT;
}
