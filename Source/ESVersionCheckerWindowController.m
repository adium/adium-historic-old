/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIPreferenceController.h"
#import "CPFVersionChecker.h"
#import "ESVersionCheckerWindowController.h"
#import <AIUtilities/ESDateFormatterAdditions.h>

#define ADIUM_UPDATE_URL			@"http://download.adiumx.com/"
#define ADIUM_UPDATE_BETA_URL		@"http://beta.adiumx.com/"
#define UPDATE_PROMPT				AILocalizedString(@"Adium was updated on %@. Your copy is %@old.  Would you like to update?", nil)

#define VERSION_AVAILABLE_NIB		@"VersionAvailable"
#define VERSION_UPTODATE_NIB		@"VersionUpToDate"
#define CONNECT_ERROR_NIB           @"VersionCannotConnect"

@interface ESVersionCheckerWindowController (PRIVATE)
- (void)showWindowFromBuild:(NSDate *)currentDate toBuild:(NSDate *)newestDate;
@end

/*!
 * @class ESVersionCheckerWindowController
 * @brief A window that notifies the user of new Adium releases
 *
 * This window can either notify the user of a new Adium release, or that their current release is the newest
 * available.
 */
@implementation ESVersionCheckerWindowController

static ESVersionCheckerWindowController *sharedVersionCheckerInstance = nil;

/*!
 * @brief Display the 'Up to date' panel
 *
 * This panel tells the user that their release of Adium is the newest available
 */
+ (void)showUpToDateWindow
{
	if(sharedVersionCheckerInstance) [sharedVersionCheckerInstance release];
	sharedVersionCheckerInstance = [[self alloc] initWithWindowNibName:VERSION_UPTODATE_NIB];
	[sharedVersionCheckerInstance showWindowFromBuild:nil toBuild:nil];
}

/*!
 * @brief Display the 'Update available' panel
 *
 * This panel tells the user that a newer release of Adium is available.
 * @param currentBuildDate Date of the release they're running
 * @param latestBuildDate Date of the newest release
 */
+ (void)showUpdateWindowFromBuild:(NSDate *)currentBuildDate toBuild:(NSDate *)latestBuildDate
{
	if(sharedVersionCheckerInstance) [sharedVersionCheckerInstance release];
	sharedVersionCheckerInstance = [[self alloc] initWithWindowNibName:VERSION_AVAILABLE_NIB];
	[sharedVersionCheckerInstance showWindowFromBuild:currentBuildDate toBuild:latestBuildDate];
}

/*!
 * @brief Display the 'Connection error' panel
 *
 * This panel tells the user that we were unable to retrieve version information
 */
+ (void)showCannotConnectWindow
{
    if(sharedVersionCheckerInstance) [sharedVersionCheckerInstance release];
    sharedVersionCheckerInstance = [[self alloc] initWithWindowNibName:CONNECT_ERROR_NIB];
    [sharedVersionCheckerInstance showWindowFromBuild:nil toBuild:nil];
}

/*!
 * @brief Configure the window
 */
- (void)windowDidLoad
{
	[super windowDidLoad];

	//Disable the 'check automatically' button if we are in a beta build
	if(BETA_RELEASE){
		[checkBox_checkAutomatically setState:YES];
		[checkBox_checkAutomatically setEnabled:NO];
	}	
}

/*!
 * @brief Called as the window closes, release the shared window controller
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
    [sharedVersionCheckerInstance autorelease];
    sharedVersionCheckerInstance = nil;
}


//Window Display -------------------------------------------------------------------------------------------------------
#pragma mark Window display
/*!
 * @brief Display the new version available window for the passed build dates
 *
 * Displays a panel that tells the user that a newer release of Adium is available.  Build dates aren't required for
 * up-to-date and error window nibs.
 * @param currentDate Date of the release they're running
 * @param newestDate Date of the newest release
 */
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

/*!
 * @brief Update to the new release of Adium
 *
 * Called when the user presses the download button, this method opens the Adium download site.
 */
- (IBAction)update:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(BETA_RELEASE ? ADIUM_UPDATE_BETA_URL : ADIUM_UPDATE_URL)]];
	[self closeWindow:nil];
}

/*!
 * @brief Invoked when a preference is changed
 *
 * Toggle auto-checking for new releases.  This option is unavailable for beta releases.
 */
- (IBAction)changePreference:(id)sender
{
	if(sender == checkBox_checkAutomatically){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_CHECK_AUTOMATICALLY
											  group:PREF_GROUP_UPDATING];
	}
}

@end
