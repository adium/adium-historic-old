//
//  ESVersionCheckerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 29 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESVersionCheckerWindowController.h"
#import "CPFVersionChecker.h"

#define ADIUM_UPDATE_URL			@"http://download.adiumx.com/"
#define ADIUM_UPDATE_BETA_URL		@"http://beta.adiumx.com/"
#define UPDATE_PROMPT				AILocalizedString(@"Adium was updated on %@. Your copy is %@old.  Would you like to update?", nil)

#define VERSION_AVAILABLE_NIB		@"VersionAvailable"
#define VERSION_UPTODATE_NIB		@"VersionUpToDate"
#define CONNECT_ERROR_NIB              @"VersionCannotConnect"

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

//Display the 'Connection error' panel
+ (void)showCannotConnectWindow
{
    if(sharedVersionCheckerInstance) [sharedVersionCheckerInstance release];
    sharedVersionCheckerInstance = [[self alloc] initWithWindowNibName:CONNECT_ERROR_NIB];
    [sharedVersionCheckerInstance showWindowFromBuild:nil toBuild:nil];
}

//
- (void)windowDidLoad
{
	[super windowDidLoad];

	//Disable the 'check automatically' button if we are in a beta build
	if(BETA_RELEASE){
		[checkBox_checkAutomatically setState:YES];
		[checkBox_checkAutomatically setEnabled:NO];
	}	
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
		NSDateFormatter *dateFormatter;
		NSString   		*newestDateString;
		NSString		*interval;
		
		dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" 
											   allowNaturalLanguage:NO];
		newestDateString = [dateFormatter stringForObjectValue:newestDate];
		
		//Time since last update (contains a trailing space)
		interval = [NSDateFormatter stringForApproximateTimeIntervalBetweenDate:newestDate
																		andDate:currentDate];
		[textField_updateAvailable setStringValue:[NSString stringWithFormat:UPDATE_PROMPT, newestDateString, interval]];
		
		[dateFormatter release];
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
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(BETA_RELEASE ? ADIUM_UPDATE_BETA_URL : ADIUM_UPDATE_URL)]];
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
