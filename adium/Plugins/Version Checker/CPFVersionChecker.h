/* CPFVersionChecker */


@interface CPFVersionChecker : AIPlugin
{
    IBOutlet id textWithInformation;
    NSMenuItem *versionCheckerMenuItem;
    NSMenuItem *Version_Checker;
    
	double currentBuildUnixDate;
	double latestBuildUnixDate;
}

@end
