/* CPFVersionChecker */

#define PREF_GROUP_UPDATING		@"Updating"
#define KEY_CHECK_AUTOMATICALLY @"Check Automatically"

@interface CPFVersionChecker : AIPlugin <AIListObjectObserver> {
    NSMenuItem 	*versionCheckerMenuItem;
	BOOL		observingListUpdates;
	BOOL		checkingManually;
}

- (void)checkForNewVersion:(id)sender;
- (NSDate *)dateOfLatestBuild;

@end
