/* CPFVersionChecker */


@interface CPFVersionChecker : AIPlugin {
    NSMenuItem 	*versionCheckerMenuItem;
}

- (void)checkForNewVersion:(id)sender;
- (NSDate *)dateOfThisBuild;
- (NSDate *)dateOfLatestBuild;
- (NSString *)intervalBetweenDate:(NSDate *)firstDate andDate:(NSDate *)secondDate;

@end
