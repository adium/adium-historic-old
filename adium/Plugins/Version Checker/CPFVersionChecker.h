/* CPFVersionChecker */


@interface CPFVersionChecker : AIPlugin <AIListObjectObserver> {
    NSMenuItem 	*versionCheckerMenuItem;
	BOOL		observingListUpdates;
	BOOL		checkingManually;
}

- (void)checkForNewVersion:(id)sender;
- (NSDate *)dateOfThisBuild;
- (NSDate *)dateOfLatestBuild;
- (NSString *)intervalBetweenDate:(NSDate *)firstDate andDate:(NSDate *)secondDate;

@end
