//
//  ESVersionCheckerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 29 2004.

#import "ESVersionCheckerWindowController.h"
#import "CPFVersionChecker.h"

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
	//Ensure the window is loaded
	[self window];
	
	//Load relevant dates which we weren't passed
	NSDate	*thisDate = [self dateOfThisBuild];
	NSDate	*lastDateDisplayedToUser = [[adium preferenceController] preferenceForKey:KEY_LAST_UPDATE_ASKED
																				group:PREF_GROUP_UPDATING];
	
	//If the user has already been informed of this update previously, don't bother them
	if(checkingManually /*|| !lastDateDisplayedToUser || ![lastDateDisplayedToUser isEqualToDate:newestDate]){
		if(([thisDate isEqualToDate:newestDate]) || ([thisDate laterDate:newestDate])){*/){if(0){
			//Display an 'up to date' message if the user checked for updates manually; otherwise we are done
			if(checkingManually){
				[[self window] setTitle:AILocalizedString(@"Up to Date",nil)];
				[textField_upToDate setStringValue:AILocalizedString(@"You have the most recent version of Adium.",nil)];
				
				//Select the proper hidden tabViewItem
				[tabView_hidden selectTabViewItemAtIndex:0];
				[self showWindow:nil];
			}else{
				[self closeWindow:nil];
			}
			
		}else{
			
			//'Check automatically' checkbox
			[checkBox_checkAutomatically setState:[[[adium preferenceController] preferenceForKey:KEY_CHECK_AUTOMATICALLY
																							group:PREF_GROUP_UPDATING] boolValue]];
			
			//Formatted version of the newest release's date
			NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] initWithDateFormat:@"%B %e, %Y" 
																	 allowNaturalLanguage:NO] autorelease];
			NSString   		*newestDateString = [dateFormatter stringForObjectValue:newestDate];
			
			//Time since last update (contains a trailing space)
			NSString *interval = [NSDateFormatter stringForApproximateTimeIntervalBetweenDate:thisDate
																					  andDate:newestDate];
			[[self window] setTitle:AILocalizedString(@"Update Available",nil)];
			[textField_updateAvailable setStringValue:[NSString stringWithFormat:AILocalizedString(@"The latest Adium was released on %@. Your current copy is %@old.  Would you like to update?", nil), newestDateString, interval]];
			
			//Select the proper hidden tabViewItem
			[tabView_hidden selectTabViewItemAtIndex:1];
			[self showWindow:nil];
			
			//Remember that the user has been prompted for this version so we don't bug them about it again
			[[adium preferenceController] setPreference:newestDate forKey:KEY_LAST_UPDATE_ASKED 
												  group:PREF_GROUP_UPDATING];
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

- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_checkAutomatically){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_CHECK_AUTOMATICALLY
											  group:PREF_GROUP_UPDATING];
	}
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
