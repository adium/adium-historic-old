#!/usr/local/bin/perl

# Jeffrey Melloy <jmelloy@visualdistortion.org>
# $URL: http://svn.visualdistortion.org/repos/projects/adium/parser-2.pl $
# $Rev: 348 $ $Date: 2003/07/19 00:03:29 $
#
# Script will parse Adium logs >= 2.0 and put them in postgresql table.
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

my $path = "$ENV{HOME}/Library/Application Support/Adium 2.0/Users/Default/Logs";
chdir "$path" or die qq{Path does not exist.};

my $dbh = DBI->connect("DBI:Pg:dbname=$username", '', '', {RaiseError=>1})
    or die qq{Cannot connect to server: $DBI::errstr\n};

my $sth = $dbh->prepare("insert into adium.message_v
    (sender_sn, recipient_sn, message, message_date, 
    sender_service, recipient_service) 
    values (?,?,?,?,?,?)");

foreach my $service_user (glob '*') {
    my $service;
    my $user;
    chdir "$service_user";
    print($service_user . "\n");
    $_ = $service_user;
    ($service, $user) = /(\w*).(\w*)/;
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
                ($recdName, $date) = /([\w\@.]*)\s.*(\d\d\d\d\|\d\d\|\d\d)/
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
                 
                    $sth->execute($sender, $receiver, $message, $timestamp, $service, $service);
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
        chdir "$path/$service_user" or die;
    }
    chdir $path;
}

if ($vacuum) {
    $| = 1;
    !$quiet && print "Vacuuming . .";
    $dbh->do('vacuum analyze adium.messages');
    !$quiet && print " . done.\n";
}
$dbh->disconnect;
