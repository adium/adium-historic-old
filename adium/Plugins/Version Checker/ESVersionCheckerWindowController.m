//
//  ESVersionCheckerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 29 2004.

#import "ESVersionCheckerWindowController.h"

#define PREF_GROUP_UPDATING		@"Updating"
#define KEY_LAST_UPDATE_ASKED	@"LastUpdateAsked"
#define ADIUM_UPDATE_URL		@"http://download.adiumx.com/"

#define VERSION_CHECKER_NIB		@"VersionChecker"

@interface ESVersionCheckerWindowController (PRIVATE)
- (NSDate *)dateOfThisBuild;
@end

@implementation ESVersionCheckerWindowController

static ESVersionCheckerWindowController *sharedVersionCheckerInstance = nil;
+ (void)showVersionCheckerWindowWithLatestBuildDate:(NSDate *)latestBuildDate checkingManually:(BOOL)checkingManually
{
    if(!sharedVersionCheckerInstance){
        sharedVersionCheckerInstance = [[self alloc] initWithWindowNibName:VERSION_CHECKER_NIB];
    }
	
	[sharedVersionCheckerInstance showWindowWithLatestBuildDate:latestBuildDate checkingManually:checkingManually];
}

+ (void)closeSharedInstance
{
    if(sharedVersionCheckerInstance){
        [sharedVersionCheckerInstance closeWindow:nil];
    }
}

// closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

// called as the window closes
- (BOOL)windowShouldClose:(id)sender
{    
    //release the window controller (ourself)
    sharedVersionCheckerInstance = nil;
    [self autorelease];
	
    return(YES);
}

// Window Display --------------------------------------------------------------------------------
#pragma mark Window display
- (void)showWindowWithLatestBuildDate:(NSDate *)newestDate checkingManually:(BOOL)checkingManually
{
	NSDate	*thisDate = [self dateOfThisBuild]; //Date of this build
	NSDate	*lastDateDisplayedToUser = [[adium preferenceController] preferenceForKey:KEY_LAST_UPDATE_ASKED group:PREF_GROUP_UPDATING];
	
	//If the user has already been informed of this update previously, don't bother them
	if(checkingManually || !lastDateDisplayedToUser || ![lastDateDisplayedToUser isEqualToDate:newestDate]){
		if(([thisDate isEqualToDate:newestDate]) || ([thisDate laterDate:newestDate])){
			//Display an 'up to date' message if the user checked for updates manually, otherwise we are done
			if(checkingManually){

				
				[[self window] setTitle:AILocalizedString(@"Up to Date",nil)];
				[textField_upToDate setStringValue:AILocalizedString(@"You have the most recent version of Adium.",nil)];
				[self showWindow:nil];
								[tabView_hidden selectTabViewItemAtIndex:0];				
			}else{
				[self closeWindow:nil];
			}
			
		}else{
			[tabView_hidden selectTabViewItemAtIndex:1];
			
			//Formatted version of the newest release's date
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" allowNaturalLanguage:NO] autorelease];
			NSString   		*newestDateString = [dateFormatter stringForObjectValue:newestDate];
			
			//Time since last update
			NSString *interval = [NSDateFormatter stringForApproximateTimeIntervalBetweenDate:thisDate
																					  andDate:newestDate];
			[[self window] setTitle:AILocalizedString(@"Update Available",nil)];
			[textField_updateAvailable setStringValue:[NSString stringWithFormat:AILocalizedString(@"A new Adium was released on %@. Your current copy is %@old.  Would you like to update?", nil), newestDateString, interval]];
			
			//Remember that the user has been prompted for this version, so we don't bug them again
			[[adium preferenceController] setPreference:newestDate forKey:KEY_LAST_UPDATE_ASKED group:PREF_GROUP_UPDATING];
			[self showWindow:nil];
		}
	}
}

-(IBAction)pressedButton:(id)sender
{
	if (sender == button_updateAvailable_downloadPage){
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_UPDATE_URL]];
	}
	
	[self closeWindow:nil];
}

#pragma mark Date methods
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

@end
