//
//  CPFVersionChecker.m
//  Adium
//
//  Created by Christopher Forsythe on Sat Mar 20 2004.
//

#import "CPFVersionChecker.h"

#define VERSION_CHECKER_TITLE 	@"Check for UpdatesÉ"
#define VERSION_PLIST_URL		@"http://www.adiumx.com/version.plist"
#define ADIUM_UPDATE_URL		@"http://download.adiumx.com/"
#define VERSION_PLIST_KEY		@"adium-version"

@interface CPFVersionChecker (PRIVATE)
- (void)_requestVersionThread;
- (void)_versionReceived:(NSDate *)newestDate;
@end

@implementation CPFVersionChecker

//Install
- (void)installPlugin
{
    versionCheckerMenuItem = [[[NSMenuItem alloc] initWithTitle:VERSION_CHECKER_TITLE 
														 target:self 
														 action:@selector(checkForNewVersion:)
												  keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:versionCheckerMenuItem toLocation:LOC_Adium_About];
}


//New version checking -------------------------------------------------------------------------------------------------
#pragma mark New version checking
//Check for a new release of Adium
//The URL load (dateOfLatestBuild) can block, so we do it in a separate thread.  Once the URL load is finished we pass
//control back to the main thread and display the appropriate panel
- (void)checkForNewVersion:(id)sender{   
	[NSThread detachNewThreadSelector:@selector(_requestVersionThread) toTarget:self withObject:nil];
}
- (void)_requestVersionThread
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	[self performSelectorOnMainThread:@selector(_versionReceived:)
						   withObject:[self dateOfLatestBuild]
						waitUntilDone:YES];
	[pool release];
}
- (void)_versionReceived:(NSDate *)newestDate
{
	NSDate	*thisDate = [self dateOfThisBuild]; //Date of this build
	
    if([thisDate isEqualToDate:newestDate]){
		NSRunAlertPanel(AILocalizedString(@"Up to Date",nil),
						AILocalizedString(@"You have the most recent version of Adium.",nil),
						@"Okay", nil, nil);
		
    }else{
		//Formatted version of the newest release's date
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" allowNaturalLanguage:NO] autorelease];
		NSString   		*newestDateString = [dateFormatter stringForObjectValue:newestDate];
		
		//Time since last update
		NSString *interval = [self intervalBetweenDate:thisDate andDate:newestDate];
		
        int button = NSRunAlertPanel(AILocalizedString(@"Update Available",nil),
									 [NSString stringWithFormat:AILocalizedString(@"A new Adium was released on %@. Your current copy is %@ old.  Would you like to update?", nil), newestDateString, interval],
									 AILocalizedString(@"Update",nil),
									 AILocalizedString(@"Cancel",nil),
									 nil);
		
		if(button == NSAlertDefaultReturn){
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_UPDATE_URL]];
		}
		
	}
}


//Build Dates ----------------------------------------------------------------------------------------------------------
#pragma mark Build Dates
//Returns the date of this build
- (NSDate *)dateOfThisBuild
{
	char *path, unixDate[256], num[256], whoami[256];

    //Grab the current buildDate from our buildnum script
	if(path = (char *)[[[NSBundle mainBundle] pathForResource:@"buildnum" ofType:nil] fileSystemRepresentation]){
		FILE *f = fopen(path, "r");
		fscanf(f, "%s | %s | %s", num, unixDate, whoami);
		fclose(f);
		if(*unixDate){
			return([NSDate dateWithTimeIntervalSince1970:[[NSString stringWithCString:unixDate] doubleValue]]);
		}
	}
	
	return(nil);
}

//Returns the date of the most recent Adium build (contacts adiumx.com, may block)
- (NSDate *)dateOfLatestBuild
{
	NSURL			*versionURL = [NSURL URLWithString:VERSION_PLIST_URL];
	NSDictionary 	*productVersionDict = [NSDictionary dictionaryWithContentsOfURL:versionURL];
	
	return([NSDate dateWithTimeIntervalSince1970:[[productVersionDict objectForKey:VERSION_PLIST_KEY] doubleValue]]);
}

//Returns a string representation of the interval between two dates
- (NSString *)intervalBetweenDate:(NSDate *)firstDate andDate:(NSDate *)secondDate
{
	int 	hours = [firstDate timeIntervalSinceDate:secondDate] / 60.0 / 60.0;
	int 	days = hours / 24.0;
	int		weeks = days / 7.0;
	
	if(days >= 1){
		return([NSString stringWithFormat:AILocalizedString(days == 1 ? @"%i day" : @"%i days", nil), days]);
	}else if(weeks >= 1){
		return([NSString stringWithFormat:AILocalizedString(weeks == 1 ? @"%i week" : @"%i weeks", nil), weeks]);
	}else{
		return([NSString stringWithFormat:AILocalizedString(days == 1 ? @"%i hour" : @"%i hours", nil), hours]);
	}
}

@end
