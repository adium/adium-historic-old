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
my $skip = 0;
my $foundLogs = 0;
my $help = 0;

my %Protocols = (		#Map gaim protocol IDs to Adium ones
				"aim"	=>	"AIM",
				"icq"	=>	"ICQ",
				"yahoo"	=>	"Yahoo!",
				"msn"	=>	"MSN",
				"jabber"=>      "Jabber",  # both jabber and gtalk
				#Add the rest here, or tell me what they are, someone who uses other protocols
				);

sub usage
{
	my $msg = shift;
	print 	"Error: $msg\n\n" if $msg;
	print	"Usage: gaim2adium.pl [--adiumUser <user> | --outDir <output dir>] [--inDir <input dir>] [--yes]\n";
	print	"Options: (defaults)\n\n";
	print	"\tinDir:\t\t\tDirectory to import logs from (~/.gaim/logs)\n";
	print	"\toutDir:\t\t\tDirectory to import logs to (./Logs)\n";
	print	"\tadiumUser:\t\tAttempt to automatically import logs to the specified Adium user\n";
	print	"\tforce\t\t\tOverwrite existing logs\n";
	print	"\tskip\t\t\tSkip existing logs\n";
	print	"\thelp:\t\t\tDisplay this help.\n";
	print	"\nOnce the logs have been imported, the contents of outDir can be dragged to your Adium log folder\n\n";
	exit(defined $msg);
}

sub process_log
{
	-r or return;
	#gaim logs are LOG_BASE/Protocol/Account/Contact/YYYY-MM-DD-TIME.(html|txt)
	if($File::Find::name =~ m! ^ $inDir              # top level dir
				      (?:/)?             # optional /
				      ([^/]+)/           # 1 - protocol
				      ([^/]+)/           # 2 - account
				      ([^/]+)/           # 3 - contact
				      (\d{4})-           # 4 - year
				      (\d{2})-           # 5 - month
				      (\d{2})\.          # 6 - day
				      (\d{2})            # 7 - hour
				      (\d{2})            # 8 - minute
				      (\d{2})            # 9 - second
				      (?:-(\d{4})\w{3})? # 10 - optional timezone
				      \.(html|txt)       # 11 - extension
				!x)
	{
		my ($proto,$acct,$contact,$year,$month,$day,$hour,$min,$seconds,$tz,$ext) = ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11);
		return unless defined ($proto = $Protocols{lc $proto});
		if ($proto eq 'Jabber' and $acct =~ /gmail\.com/) {
			$proto = "GTalk";
		}

		$foundLogs = 1;		#Set the logs found flag
		my $outFN = defined($tz) ? "$contact ($year-$month-${day}T$hour.$min.$seconds-$tz)." : "$contact ($year|$month|$day).";
		$outFN .= ((lc $ext) eq "html") ? "html" : "adiumLog";
		unless (-d "$outDir/$proto.$acct/$contact") {
			unless (-d "$outDir/$proto.$acct") {
				mkdir("$outDir/$proto.$acct") or die "Can't mkdir $outDir/$proto.$acct: $!";
			}
			mkdir("$outDir/$proto.$acct/$contact") or die "Can't mkdir $outDir/$proto.$acct/$contact: $!";
		}
		my $file = "$outDir/$proto.$acct/$contact/$outFN";
		return if(-e $file && $skip);
		if(-e $file && !$force)
		{
			#print(($adiumUser?"$adiumUser already has":"There already exists"),
			#" a log from $proto.$acct to $contact on $day/$month/$year.\n");
			`cat '$_' >> '$file'`;
		} else {
			copy($_,$file) or die "Failed to copy $_ to $file: $!";
		}
		`touch -t $year$month$day$hour$min.$seconds '$file'`;
	}
}

#Sort a list of log files by time
sub sort_logs
{
	my @files = @_;
	return sort logcmp @files;
}

sub logcmp
{
	my ($t1,$t2);
	$t1 = $& if $a =~ /\d{6}/;
	$t2 = $& if $b =~ /\d{6}/;
	return 0 unless defined($t1) && defined($t2);
	return $t1 <=> $t2;
}


GetOptions(	"adiumUser=s"	=>	\$adiumUser,
			"inDir=s"		=>	\$inDir,
			"outDir=s"		=>	\$outDir,
			"yes"			=>	\$force,
			"force"			=>	\$force,
			"skip"			=>	\$skip,
			"help"			=>	\$help)
	or usage();
usage() if $help;
usage("You must supply at most one of adiumUser and outDir") if defined($outDir) && defined($adiumUser);

$outDir ||= "$ENV{HOME}/Library/Application Support/Adium 2.0/Users/$adiumUser/Logs" if defined $adiumUser;
$outDir ||= "$ENV{PWD}/Logs";

$outDir = "$ENV{PWD}/$outDir" unless $outDir =~ m!^/!;

$inDir ||= shift;
$inDir ||= "$ENV{HOME}/.gaim/logs";

print "NOTE: Output directory exists, existing logs will be appended to.\n" if(-d $outDir);

mkdir($outDir) unless -e $outDir;
usage("Output dir must be a directory") unless -d $outDir;
usage("Output dir must be writeable") unless -w $outDir;

usage("Input directory '$inDir' does not exist") unless -d $inDir;
usage("Input directory '$inDir' is not readable") unless -r $inDir;

#Spider the logs dir
find({wanted => \&process_log,
		preprocess => \&sort_logs}, $inDir);

#Warn if we didn't find any logs
unless($foundLogs)
{
	print "Warning: No recognized logs found.\n";
	print "Note:\tThis script only supports logs generated by gaim 0.73 and above.\n";
	print "\tYou may be able to update older gaim logs to the new format using the script from\n";
	print "\thttp://sourceforge.net/forum/message.php?msg_id=2392758\n";
	exit(1);
}

exit(0);

