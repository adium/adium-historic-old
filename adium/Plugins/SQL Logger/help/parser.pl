#!/usr/bin/perl

# Jeffrey Melloy <jmelloy@visualdistortion.org>
# $URL: http://svn.visualdistortion.org/repos/projects/adium/parser.pl $
# $Rev: 754 $ $Date: 2004/05/14 00:40:37 $
#
# Script will parse Adium logs <= 1.6.x and put them in postgresql table.
# Table is created with "adium.sql"
#
# If --verbose is passed, will print out name of every log file.
# If --no-vacuum, will not vacuum table at end (not recommended).
# if --quiet, will print nothing.
#
# Requires perl modules "DBI" and "DBD-Pg".
# Are available through CPAN or fink.
# Fink packages: "dbi-pm" and "dbd-pg-pm" (unstable).

use warnings;
use strict;
use DBI;
use CGI qw(-no_debug escapeHTML);

my $vacuum = 1;
my $verbose = 0;
my $quiet = 0;

my $username = $ENV{USER};

for (my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq "--verbose") {
        $verbose = 1;
    }
    if ($ARGV[$i] eq "--no-vacuum") {
        $vacuum = 0;
    }
    if ($ARGV[$i] eq "--quiet") {
        $quiet = 1;
    }
}

my $path = "$ENV{HOME}/Library/Application Support/Adium/Users/";
chdir "$path" or die qq{Path does not exist.};

my $dbh = DBI->connect("DBI:Pg:dbname=$username", '', '', {RaiseError=>1})
    or die qq{Cannot connect to server: $DBI::errstr\n};

my $sth = $dbh->prepare("insert into adium.message_v 
    (sender_sn, recipient_sn, message, message_date) 
    values (?,?,?,?)");

foreach my $user (glob '*') {
    chdir "$user/Logs";
    print($user . "\n");
    foreach my $folder (glob '*') {
        !$quiet && print "\t" . $folder . "\n";
        chdir $folder;
        foreach my $file (glob '*adiumLog') {
            $verbose && print "\t\t" . $file . "\n";
            
            my $date;
            my $recdName;
            my $sentName = $user;
            my $time;
            my $sender;
            my $receiver;
            my $message;
           
            eval {
                $_ = $file;
                ($recdName, $date) = /(\w*)\s.*(\d\d\d\d\|\d\d\|\d\d)/
                    or die "$!";
                
                undef $/;
                open (FILE, $file) or die qq{Unable to open file "$file": $!};
                my $content = <FILE>;
                close(FILE);

                $content = escapeHTML($content);
                $content =~ s/\n((?!\(\d\d\:\d\d\:\d\d\)\w*|(\&lt\;\w*\s.*\d\d\:\d\d\:\d\d.*\&gt\;)))/<br>$1/g or die $!;

                $dbh->begin_work;

                my @filecontents = split(/\n/, $content);

                for (my $i = 1; $i < @filecontents; $i++) {

                    $_ = $filecontents[$i];

                    ($time, $sender) = /^\((\d\d\:\d\d\:\d\d)\)(\w*)\:/
                       or ($time) = /^\&lt\;.*(\d\d\:\d\d\:\d\d)/
                       or die "$file:$_\n$!";

                    if (/^\&lt\;.*\&gt\;/) {
                        $sender = $recdName;
                    }
    
                    if ($folder =~ /Chat Logs/) {
                        $receiver = $recdName;
                    } elsif ($sender eq $sentName) {
                        $receiver = $recdName;
                    }
                    else {
                        $receiver = $sentName;
                    }
            
                    if(/\)\w*\:(.*)/) {
                        $message = $1;
                    } else {
                        $message = $_;
                    }
            
                    my $timestamp = $date . " " . $time;
                 
                    $sth->execute($sender, $receiver, $message, $timestamp);
                }
                $dbh->commit;
                my $backup = $file . ".bak";
                system('mv',$file,$backup);
            }; if ($@) {
               $dbh->rollback;
               $dbh->disconnect;
               die;
            }
        }
        chdir "$path/$user/Logs";
    }
    chdir $path;
}
$dbh->begin_work;
$sth = $dbh->prepare("insert into adium.user_display_name (user_id, display_name, effdate) select user_id, username, '-infinity' from users where not exists (select 'x' from user_display_name where user_display_name.user_id = users.user_id and user_display_name.effdate = '-infinity')");
$sth->execute();
$dbh->commit;
if ($vacuum) {
    $| = 1;
    !$quiet && print "Vacuuming . .";
    $dbh->do('vacuum analyze adium.messages');
    !$quiet && print " . done.\n";
}
$dbh->disconnect;
