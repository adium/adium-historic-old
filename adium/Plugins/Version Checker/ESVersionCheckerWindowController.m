//
//  ESVersionCheckerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 29 2004.

#import "ESVersionCheckerWindowController.h"
#import "CPFVersionChecker.h"

#define ADIUM_UPDATE_URL			@"http://download.adiumx.com/"
#define UPDATE_PROMPT				AILocalizedString(@"Adium was updated on %@. Your copy is %@old.  Would you like to update?", nil)

#define VERSION_AVAILABLE_NIB		@"VersionAvailable"
#define VERSION_UPTODATE_NIB		@"VersionUpToDate"

@interface ESVersionCheckerWindowController (PRIVATE)
- (void)showWindowFromBuild:(NSDate *)currentDate toBuild:(NSDate *)newestDate;
@end

@implementation ESVersionCheckerWindowController

static ESVersionCheckerWindowController *sharedVersionCheckerInstance = nil;

//Display the 'Up to date' panel
+ (void)showUpToDateWindow
{
	if(sharedVersionCheckerInstance) [sharedVersionCheckerInstance release];
	sharedVersionCheckerInstance = [[self alloc] initWithWindowNibName:VERSION_UPTODATE_NIB];
	[sharedVersionCheckerInstance showWindowFromBuild:nil toBuild:nil];
}

//Display the 'Update available' panel
+ (void)showUpdateWindowFromBuild:(NSDate *)currentBuildDate toBuild:(NSDate *)latestBuildDate
{
	if(sharedVersionCheckerInstance) [sharedVersionCheckerInstance release];
	sharedVersionCheckerInstance = [[self alloc] initWithWindowNibName:VERSION_AVAILABLE_NIB];
	[sharedVersionCheckerInstance showWindowFromBuild:currentBuildDate toBuild:latestBuildDate];
}

//Called as the window closes, release the shared window controller
- (BOOL)windowShouldClose:(id)sender
{    
    [sharedVersionCheckerInstance autorelease];
    sharedVersionCheckerInstance = nil;
    return(YES);
}


//Window Display -------------------------------------------------------------------------------------------------------
#pragma mark Window display
- (void)showWindowFromBuild:(NSDate *)currentDate toBuild:(NSDate *)newestDate
{
	//Ensure the window is loaded
	[[self window] center];
	
	//'Check automatically' checkbox
	[checkBox_checkAutomatically setState:[[[adium preferenceController] preferenceForKey:KEY_CHECK_AUTOMATICALLY
																					group:PREF_GROUP_UPDATING] boolValue]];

	//Set our panel to display the build date and age of the running copy
	if(currentDate && newestDate){
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" 
																 allowNaturalLanguage:NO] autorelease];
		NSString   		*newestDateString = [dateFormatter stringForObjectValue:newestDate];
		
		//Time since last update (contains a trailing space)
		NSString *interval = [NSDateFormatter stringForApproximateTimeIntervalBetweenDate:currentDate
																				  andDate:newestDate];
		[textField_updateAvailable setStringValue:[NSString stringWithFormat:UPDATE_PROMPT, newestDateString, interval]];
	}
	
	[self showWindow:nil];
}

//Closes this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Update
- (IBAction)update:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_UPDATE_URL]];
	[self closeWindow:nil];
}

//Toggle auto-check
- (IBAction)changePreference:(id)sender
{
	if(sender == checkBox_checkAutomatically){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_CHECK_AUTOMATICALLY
											  group:PREF_GROUP_UPDATING];
	}
}

@end
