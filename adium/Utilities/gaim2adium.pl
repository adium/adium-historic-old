#!/usr/bin/perl
use warnings;
use strict;
use File::Find;
use File::Copy;
use Getopt::Long;

my $inDir = undef;
my $outDir = undef ;
my $adiumUser = undef;
my $force = 0;

my %Protocols = (		#Map gaim protocol IDs to Adium ones
				"aim"	=>	"AIM",
				"yahoo"	=>	"Yahoo!"
				"msn"	=>	"MSN"
				#Add the rest here, or tell me what they are, someone who uses other protocols
				);

sub usage
{
	print	"Usage: gaim2adium.pl (--adiumUser <user> | --outDir <output dir>) [--inDir <input dir>] [--yes]\n";
	print	"Options: (defaults)\n\n";
	print	"\tadiumUser:\t\tAdium user to import logs to\n";
	print	"\tinDir:\t\t\tDirectory to import logs from (~/.gaim/logs)\n";
	print	"\toutDir:\t\t\tDirectory to import logs to (Adium log directory for adiumUser)\n";
	print	"\tyes:\t\t\tDon't prompt before overwriting existing logs\n";
	exit(1);
}

sub process_log
{
	-f or return;
	#gaim logs are LOG_BASE/Protocol/Account/Contact/YYYY-MM-DD-<JUNK>.(html|txt)
	if($File::Find::name =~ m!^$inDir/(.*?)/(.*?)/(.*?)/(\d{4})-(\d{2})-(\d{2})\.\d+\.(html|txt)!)
	{
		my ($proto,$acct,$contact,$year,$month,$day,$ext) = ($1,$2,$3,$4,$5,$6,$7);
		return unless defined ($proto = $Protocols{lc $proto});
		my $outFN = "$contact ($year|$month|$day).";
		$outFN .= ((lc $ext) eq "html") ? "html" : "adiumLog";
		mkdir("$outDir/$proto.$acct");
		mkdir("$outDir/$proto.$acct/$contact");
		my $file = "$outDir/$proto.$acct/$contact/$outFN";
		if(-e $file && !$force)
		{
			print "$adiumUser already has a log from $proto.$acct to $contact on $day/$month/$year. Overwrite[Y/n/a]?";
			my $line = <>;
			if(lc substr($line,0,1) eq "a")
			{
				$force = 1;
			}
			elsif(lc substr($line,0,1) ne "y")
			{
				return;
			}
		}
		copy($File::Find::name,$file);
	}
}


GetOptions(	"adiumUser=s"	=>	\$adiumUser,
			"inDir=s"		=>	\$inDir,
			"outDir=s"		=>	\$outDir,
			"yes"			=>	\$force)
	or usage();
			
usage() unless defined($adiumUser) || defined($outDir);

$outDir ||= "$ENV{HOME}/Library/Application Support/Adium 2.0/Users/$adiumUser/Logs";
$inDir ||= "$ENV{HOME}/.gaim/logs";

mkdir($outDir) unless -e $outDir;
die("Output dir must be a directory") unless -d $outDir;
die("Output dir must be writeable") unless -w $outDir;

die("Bad input directory") unless -d $inDir && -r $inDir;

find(\&process_log,$inDir);

