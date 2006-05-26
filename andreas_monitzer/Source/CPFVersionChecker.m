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

#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "CPFVersionChecker.h"
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIHostReachabilityMonitor.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

//
#define VERSION_CHECKER_TITLE			[AILocalizedString(@"Check for Updates",nil) stringByAppendingEllipsis]
#define VERSION_CHECKER_DEFAULTS		@"VersionChecker Defaults"

//Host and location of version information file
#define VERSION_PLIST_URL				@"http://www.adiumx.com/version.plist"
#define VERSION_PLIST_HOST				@"www.adiumx.com"

//The strings of these keys are confusing to maintain support for legacy clients
#define KEY_ADIUM_DATE					@"adium-version"
#define KEY_ADIUM_VERSION				@"adium-version-num"
#define KEY_ADIUM_BETA_DATE				@"adium-beta-version"
#define KEY_ADIUM_BETA_VERSION			@"adium-beta-version-num"

//"More Information" sites for regular and beta releases
#define ADIUM_UPDATE_URL				@"http://download.adiumx.com/"
#define ADIUM_UPDATE_BETA_URL			@"http://beta.adiumx.com/"

//Intervals to re-check for updates after a successful check
#define VERSION_CHECK_INTERVAL			24		//24 hours
#define BETA_VERSION_CHECK_INTERVAL 	1		//1 hours - Beta releases have a nice annoying refresh >:D

@interface CPFVersionChecker (PRIVATE)
- (void)_checkForNewVersionNotifyingUserOnFailure:(BOOL)notify;
- (void)_versionReceived:(NSDictionary *)versionDict;
@end

/*!
 * @class CPFVersionChecker
 * @brief Checks for new releases of Adium
 *
 * The version checker checks for new releases of Adium and notifies the user when one is available.
 *
 * When the beta flag is set, we will version check from the beta key.  This allows beta releases to receive update
 * notifications separately from regular releases.  Version updates will also be more frequent and cannot be disabled.
 * This is to discourage the use of beta releases after a regular release is made without completely preventing the
 * program from launching.
 */
@implementation CPFVersionChecker

/*!
 * @brief Install the version checker
 */
- (void)installPlugin
{
	//Configure our default preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:VERSION_CHECKER_DEFAULTS 
																		forClass:[self class]]
										  forGroup:PREF_GROUP_UPDATING];
	
	//Menu item for checking manually
    versionCheckerMenuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:VERSION_CHECKER_TITLE 
																				   target:self 
																				   action:@selector(manualCheckForNewVersion:)
																			keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:versionCheckerMenuItem toLocation:LOC_Adium_About];
	
	//Check for updates as soon as we have a network connection
	networkIsAvailable = NO;
	checkWhenNetworkBecomesAvailable = YES;
	[[AIHostReachabilityMonitor defaultMonitor] addObserver:self forHost:VERSION_PLIST_HOST];

	//Check for updates again every X hours (60 seconds * 60 minutes * X hours)
	timer = [[NSTimer scheduledTimerWithTimeInterval:(60 * 60 * (BETA_RELEASE ?
																 BETA_VERSION_CHECK_INTERVAL :
																 VERSION_CHECK_INTERVAL))
											  target:self
											selector:@selector(automaticCheckForNewVersion:)
											userInfo:nil
											 repeats:YES] retain];
}

/*!
 * @brief Uninstall the version checker
 */
- (void)uninstallPlugin
{
	[timer invalidate];
	[timer release]; timer = nil;

	[[AIHostReachabilityMonitor defaultMonitor] removeObserver:self forHost:VERSION_PLIST_HOST];
}


//AIHostReachabilityObserver conformance -------------------------------------------------------------------------------
#pragma mark AIHostReachabilityObserver conformance
/*!
 * @brief When our update host becomes available, check for updates if necessary
 */
- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsReachable:(NSString *)host
{
	networkIsAvailable = YES;
	
	if (checkWhenNetworkBecomesAvailable) {
		[self automaticCheckForNewVersion:nil];
	}
}

/*!
 * @brief Update host is unavailable
 */
- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsNotReachable:(NSString *)host
{
	networkIsAvailable = NO;
}


//New version checking -------------------------------------------------------------------------------------------------
#pragma mark New version checking
/*!
 * @brief Check for a new release of Adium (Notify on failure)
 *
 * Checks for a new release of Adium.  The user will be notified when checking has completed, either with a new
 * release or a message that their current release is up to date.
 */
- (void)manualCheckForNewVersion:(id)sender
{
	[self _checkForNewVersionNotifyingUserOnFailure:YES];
}

/*!
 * @brief Check for a new release of Adium (Silent on failure)
 *
 * Check for a new release of Adium without notifying the user on a false result.  Call this method when the user has
 * not explicitly requested the version check.
 *
 * If a network connection is not available, the check will be performed when one becomes available.
 */
- (void)automaticCheckForNewVersion:(id)sender
{
	if (networkIsAvailable) {
		BOOL updateAutomatically = [[[adium preferenceController] preferenceForKey:KEY_CHECK_AUTOMATICALLY
																			 group:PREF_GROUP_UPDATING] boolValue];

		if (BETA_RELEASE || updateAutomatically) {
			[self _checkForNewVersionNotifyingUserOnFailure:NO];
		}
		
		checkWhenNetworkBecomesAvailable = NO;
	} else {
		checkWhenNetworkBecomesAvailable = YES;
	}
}

/*!
 * @brief Begin checking for a new Adium version (contacts adiumx.com asynchronously)
 *
 * @param notify YES if the user should be notified in the case of no updates or a connection error
 */
- (void)_checkForNewVersionNotifyingUserOnFailure:(BOOL)notify
{
	if (!checking) {
		checking = YES;
		notifyUserOnFailure = notify;
		[[NSURL URLWithString:VERSION_PLIST_URL] loadResourceDataNotifyingClient:self usingCache:NO];
	}
}

/*!
 * @brief Invoked when the versionDict was downloaded succesfully
 *
 * In response, we parse the received version information.
 */
- (void)URLResourceDidFinishLoading:(NSURL *)sender
{
	NSData	*data = [sender resourceDataUsingCache:YES];
	
	if (data) {
		[self _versionReceived:[NSPropertyListSerialization propertyListFromData:data
																mutabilityOption:NSPropertyListImmutable
																		  format:nil
																errorDescription:nil]];
	}
}

/*!
 * @brief Invoked when the versionDict could not be loaded
 */
- (void)URLResourceDidCancelLoading:(NSURL *)sender
{
	[self _versionReceived:nil];
}

/*!
 * @brief Invoked when version information is received
 *
 * Parse the version dictionary and notify the user (if necessary) of a new release or that their current
 * version is the newest.
 * @param versionDict Dictionary from the web containing version numbers of the most recent releases
 */
- (void)_versionReceived:(NSDictionary *)versionDict
{
	NSDate		*thisDate = [AIAdium buildDate];
	NSDate		*lastDateDisplayedToUser = [[adium preferenceController] preferenceForKey:KEY_LAST_UPDATE_ASKED
																					group:PREF_GROUP_UPDATING];
	NSDate		*newestDate = nil;
	NSString	*newestURL = nil;
	NSString	*newestVersion = nil;
	
	if (versionDict) {
		NSString	*dateNumber;

		//Get the newest release version
		if ((dateNumber = [versionDict objectForKey:KEY_ADIUM_DATE])) {
			newestDate = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
			newestURL = ADIUM_UPDATE_URL;
			newestVersion = [versionDict objectForKey:KEY_ADIUM_VERSION];
		}
		
		//Get the newest beta version
		if (BETA_RELEASE) {
			if ((dateNumber = [versionDict objectForKey:KEY_ADIUM_BETA_DATE])) {
				NSDate	*betaDate = [NSDate dateWithTimeIntervalSince1970:[dateNumber doubleValue]];
				if ([betaDate compare:newestDate] == NSOrderedDescending){
					newestDate = betaDate;
					newestURL = ADIUM_UPDATE_BETA_URL;
					newestVersion = [versionDict objectForKey:KEY_ADIUM_BETA_VERSION];
				}
			}
			lastDateDisplayedToUser = nil; //Ignore previous display of this version
		}
	}

	//If the user has already been informed of this update previously, don't bother them
	if (notifyUserOnFailure || !lastDateDisplayedToUser || (![lastDateDisplayedToUser isEqualToDate:newestDate])) {
		if (!newestDate) {
			if (notifyUserOnFailure) {
				//Display connection error message
				NSRunAlertPanel(AILocalizedString(@"Unable to check version",nil),
								AILocalizedString(@"Please check your network settings or try again later.",nil),
								AILocalizedString(@"OK",nil),
								nil,
								nil);
			}

		} else if ([thisDate isEqualToDate:newestDate] || [thisDate isEqualToDate:[thisDate laterDate:newestDate]]) {
			if (notifyUserOnFailure) {
				//Display the 'up to date' message if the user checked for updates manually
				NSRunInformationalAlertPanel(AILocalizedString(@"Up to Date",nil),
											 AILocalizedString(@"No Adium updates are available at this time.",nil),
											 AILocalizedString(@"OK",nil),
											 nil,
											 nil);
			}
			
		} else {
			NSString	*updateMessage;
			
			//Update message varies for beta releases
			if (BETA_RELEASE) {
				updateMessage = AILocalizedString(@"Adium version %@ is available for download.  Please update your beta release of Adium as soon as possible.", nil);
			} else {
				updateMessage = AILocalizedString(@"Adium version %@ is available for download.  Would you like more information on this update?", nil);
			}
			
			//Display 'update' message always
			if (NSRunInformationalAlertPanel(AILocalizedString(@"Update Available",nil),
											 [NSString stringWithFormat:updateMessage, newestVersion],
											 [AILocalizedString(@"More Information",nil) stringByAppendingEllipsis],
											 (BETA_RELEASE ? nil : AILocalizedString(@"No Thanks",nil)),
											 nil) == NSAlertDefaultReturn) {
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:newestURL]];
			}

			//Remember that the user has been prompted for this version so we don't bug them about it again
			[[adium preferenceController] setPreference:newestDate forKey:KEY_LAST_UPDATE_ASKED 
												  group:PREF_GROUP_UPDATING];
		}
	}

	checking = NO;
}

@end
