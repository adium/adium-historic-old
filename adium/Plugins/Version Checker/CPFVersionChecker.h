/* CPFVersionChecker */


@interface CPFVersionChecker : AIPlugin <AIListObjectObserver> {
    NSMenuItem 	*versionCheckerMenuItem;
	BOOL		observingListUpdates;
	BOOL		checkingManually;
}

- (void)checkForNewVersion:(id)sender;
- (NSDate *)dateOfLatestBuild;

@end
