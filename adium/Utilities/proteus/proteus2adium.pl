#!/usr/bin/perl

# This script converts Proteus logs to Adium ones.
#
# It will create a folder with your username that you can drop into Adium's
# log folder or copy the contents.
#
# Run it by doing "./proteus2adium.pl --aim AIM_USER_NAME"
#
# Updated 31jan2004 by William Knop <w_knop@hotmail.com>
#   - added support for icq logs
#   - added usage statement
#   - changed the behavior if usage is incorrect (it now exits when required
#     args are not given)
# Updated 24jan2004 by Seth Dillingham <seth@macrobyte.net>
#   - pipe the input from the sqlite script, rather than running 
#     it in backticks (more memory efficient for large histories)
#   - correctly handles multi-line history records
#     (Proteus uses \n whereas Adium uses <BR>)

use warnings;
use strict;

my $proteus_log_file = "$ENV{HOME}/Library/Application Support/Instant Messaging/Profile/History.db";

my $user_name;
my $service_type;
my $base_out;
for(my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq "--aim") {
        $user_name = $ARGV[$i + 1];
        $service_type = "aim-oscar";
        $base_out = "AIM.$user_name";
    } elsif ($ARGV[$i] eq "--icq") {
    	$user_name = $ARGV[$i + 1];
    	$service_type = "icq";
    	$base_out = "ICQ.$user_name";
    } elsif ($ARGV[$i] eq "--msn") {
        $user_name = $ARGV[$i + 1];
        $service_type= "msn";
        $base_out = "MSN.$user_name";
    }
}

if (($service_type eq "") || ($user_name eq "")) {
	print "Usage: proteus2adium [--aim]|[--icq]|[--msn] <your screen name>\n";
	exit;
}

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


my $query = "select substr(date, 0, 10), identifier, \'<div class=\\\"\' || case when incoming=1 then \'receive\' else \'send\' end || \'\\\"><span class=\\\"timestamp\\\">\' || substr(date, 12, 8) || \'</span><span class=\\\"sender\\\">\' || case when incoming = 1 then identifier else \'$user_name\' end || \': </span><pre class=\\\"message\\\">\' || message || \'</pre></div>\' from \\\"$service_type\\\"";

open( QUERYPIPE, './sqlite "' . $proteus_log_file . '" "' . $query . '" |' ) or die "Could not open the pipe: $!";

umask(000);

# make sure the basic output dir exists
mkdir($base_out, 0777) unless (-d $base_out); 

my $history_line = '';

while ( <QUERYPIPE> )
{
    chomp;
    
    # some of the records coming from the proteus logs are multi-line
    # so we build $history_line by appending the record to it
    $history_line .= $_;
    
    # if the pattern matches, we have the whole record
    if ( $history_line =~ /(\d*)-(\d*)-(\d*)\|(.*)\|(<div.*<\/div>)/s )
    {
        my ($year, $month, $day, $ident, $message) = ($1, $2, $3, $4, $5);
        
        #make sure the output dir exists for the current contact
        mkdir( "$base_out/$ident/", 0777 ) unless ( -d "$base_out/$ident" );
        
        my $output_file = "$base_out/$ident/$ident ($year|$month|$day).html";
        open( OUTFILE, ">>$output_file" ) or die( "Could not open output file $output_file: $!" );
        
        print OUTFILE "$message\n";
        
        close OUTFILE or warn( "Could not close the output file $output_file: $!" );
        
        # clear history_line in preparation for the next record
        $history_line = '';
    }
    else
    {
        # adium uses <BR> to separate lines instead of \n
        $history_line .= "<BR>";
    }
}
