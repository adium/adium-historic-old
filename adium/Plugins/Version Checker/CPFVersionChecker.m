//
//  CPFVersionChecker.m
//  Adium
//
//  Created by Christopher Forsythe on Sat Mar 20 2004.
//

#import "CPFVersionChecker.h"

#define VERSION_CHECKER_TITLE @"Check for Updates..."

@interface CPFVersionChecker (PRIVATE)
- (void)adiumIsUpToDate:(BOOL)upToDate;
@end

@implementation CPFVersionChecker
- (void)installPlugin{
    
	currentBuildUnixDate = 0;
	
    //Install Menu item
    versionCheckerMenuItem = [[[NSMenuItem alloc] initWithTitle:VERSION_CHECKER_TITLE 
														 target:self 
														 action:@selector(checkForNewVersion:)
												  keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:versionCheckerMenuItem toLocation:LOC_Adium_About];
}


- (void)checkForNewVersion:(id)sender
{   
    //Grab the current buildDate from our buildnum script
	char *path, unixDate[256], num[256], whoami[256];
	if(path = (char *)[[[NSBundle mainBundle] pathForResource:@"buildnum" ofType:nil] fileSystemRepresentation]){
		FILE *f = fopen(path, "r");
		fscanf(f, "%s | %s | %s", num, unixDate, whoami);
		fclose(f);
		if(*unixDate){
			   currentBuildUnixDate = [[NSString stringWithCString:unixDate] doubleValue];
		}
	       
		NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://adium.sourceforge.net/version.plist"]];
	       
		latestBuildUnixDate = [[productVersionDict objectForKey:@"adium-version"] doubleValue];
	       
		[self adiumIsUpToDate:(currentBuildUnixDate==latestBuildUnixDate)];
	}
}

- (void)adiumIsUpToDate:(BOOL)upToDate
{
    if(upToDate) {
		NSRunAlertPanel(AILocalizedString(@"Adium is up to date",
										  @"Adium up to date."),
						AILocalizedString(@"You have the most recent version of Adium.",
										  @"Adium is "),
						AILocalizedString(@"OK", @"OK"), nil, nil);
    } else {
        NSDate *latestDate = [NSDate dateWithTimeIntervalSince1970:latestBuildUnixDate];
        NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:currentBuildUnixDate];
        
        //Date of the most recent release
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" allowNaturalLanguage:NO] autorelease];
		NSString   *latestDateString = [dateFormatter stringForObjectValue:[NSDate dateWithTimeIntervalSince1970:latestBuildUnixDate]];
		
		//Number of days or weeks old the current version is
		int daysOld = [latestDate timeIntervalSinceDate:currentDate]/60/60/24;
		int interval;
		NSString   *intervalIndicator;
		if (daysOld >= 7){
			interval = daysOld / 7;
			if (interval > 1){
				intervalIndicator = AILocalizedString(@"weeks",nil);
			}else{
				intervalIndicator = AILocalizedString(@"week",nil);
			}
		}else{
			interval = daysOld;
			if (interval > 1){
				intervalIndicator = AILocalizedString(@"days",nil);
			}else{
				intervalIndicator = AILocalizedString(@"day",nil);
			}
		}
		
        int button = NSRunAlertPanel(AILocalizedString(@"A New Version is Available",nil),
									 [NSString stringWithFormat:AILocalizedString(@"The latest version of Adium was released on %@. Your current copy is %i %@ old.  Would you like to visit the Adium download page now?",nil), latestDateString, interval, intervalIndicator],
									 AILocalizedString(@"Yes",nil),
									 AILocalizedString(@"No",nil),
									 nil);
		
		if(button == NSAlertDefaultReturn) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.adiumx.com"]];
		}
    }
}
@end