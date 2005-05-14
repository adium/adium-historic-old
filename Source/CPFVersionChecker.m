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
#import "ESVersionCheckerWindowController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIHostReachabilityMonitor.h>

#define VERSION_CHECKER_TITLE		AILocalizedString(@"Check for Updates...",nil)
#define VERSION_PLIST_URL			@"http://www.adiumx.com/version.plist"
#define VERSION_PLIST_HOST			@"www.adiumx.com"
#define VERSION_PLIST_KEY			@"adium-version"
#define VERSION_BETA_PLIST_KEY		@"adium-beta-version"

#define VERSION_CHECK_INTERVAL		24		//24 hours
#define BETA_VERSION_CHECK_INTERVAL	4		//4 hours - Beta releases have a nice annoying refresh >:D

#define VERSION_CHECKER_DEFAULTS	@"VersionChecker Defaults"

@interface CPFVersionChecker (PRIVATE)
- (void)_requestVersionDict;
- (void)_versionReceived:(NSDictionary *)versionDict;
- (NSDate *)dateOfThisBuild;
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
	
	//Observe connectivity changes
	[[AIHostReachabilityMonitor defaultMonitor] addObserver:self forHost:VERSION_PLIST_HOST];
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

//AIHostReachabilityObserver conformance -------------------------------------------------------------------------------------------------
#pragma mark AIHostReachabilityObserver conformance

- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsReachable:(NSString *)host {
	NSLog(@"CPFVersionChecker: %@ is reachable", host);
	if(!timer) {

		//Check for an update now
		[self automaticCheckForNewVersion:nil];

		//Check for updates again every X hours (60 seconds * 60 minutes * X hours)
		timer = [[NSTimer scheduledTimerWithTimeInterval:(60 * 60 * (BETA_RELEASE ? BETA_VERSION_CHECK_INTERVAL : VERSION_CHECK_INTERVAL))
												  target:self
												selector:@selector(automaticCheckForNewVersion:)
												userInfo:nil
												 repeats:YES] retain];
	}
}
- (void)hostReachabilityMonitor:(AIHostReachabilityMonitor *)monitor hostIsNotReachable:(NSString *)host {
	NSLog(@"CPFVersionChecker: %@ is not reachable", host);

	[timer invalidate];
	[timer release]; timer = nil;
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
	[self _requestVersionDict];
	checkingManually = YES;
}

/*!
 * @brief Check for a new release of Adium (Silent on failure)
 *
 * Check for a new release of Adium without notifying the user on a false result.
 * Call this method when the user has not explicitly requested the version check.
 */
- (void)automaticCheckForNewVersion:(id)sender
{
	BOOL updateAutomatically = [[[adium preferenceController] preferenceForKey:KEY_CHECK_AUTOMATICALLY
																		 group:PREF_GROUP_UPDATING] boolValue];

	if(BETA_RELEASE || updateAutomatically) {
		[self _requestVersionDict];
		checkingManually = NO;
	}
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
	NSString	*number = [versionDict objectForKey:VERSION_PLIST_KEY];
	NSDate		*newestDate = nil;

	//Get the newest version date from the passed version dict
	if(versionDict && number){
		newestDate = [NSDate dateWithTimeIntervalSince1970:[number doubleValue]];
	}
		
	//Load relevant dates which we weren't passed
	NSDate	*thisDate = [self dateOfThisBuild];
	NSDate	*lastDateDisplayedToUser = [[adium preferenceController] preferenceForKey:KEY_LAST_UPDATE_ASKED
																				group:PREF_GROUP_UPDATING];
	
	//If the user has already been informed of this update previously, don't bother them
	if(checkingManually || !lastDateDisplayedToUser || (![lastDateDisplayedToUser isEqualToDate:newestDate])){
		if(!newestDate){
			//Display connection error message
			if(checkingManually) [ESVersionCheckerWindowController showCannotConnectWindow];
		}else if([thisDate isEqualToDate:newestDate] || [thisDate isEqualToDate:[thisDate laterDate:newestDate]]){
			//Display the 'up to date' message if the user checked for updates manually
			if(checkingManually) [ESVersionCheckerWindowController showUpToDateWindow];
		}else{
			//Display 'update' message always
			[ESVersionCheckerWindowController showUpdateWindowFromBuild:thisDate toBuild:newestDate];
			
			//Remember that the user has been prompted for this version so we don't bug them about it again
			[[adium preferenceController] setPreference:newestDate forKey:KEY_LAST_UPDATE_ASKED 
												  group:PREF_GROUP_UPDATING];
		}
	}
	
	//Beta Expiration (Designed to be annoying)
	//Beta expiration checking is performed in addition to regular version checking
	if(BETA_RELEASE){
		NSString	*betaNumber = [versionDict objectForKey:VERSION_BETA_PLIST_KEY];
		NSDate		*betaDate = nil;
		
		if(versionDict && number) betaDate = [NSDate dateWithTimeIntervalSince1970:[betaNumber doubleValue]];
		if(!betaDate){
			[ESVersionCheckerWindowController showCannotConnectWindow];
		}else if(![thisDate isEqualToDate:betaDate] && ![thisDate isEqualToDate:[thisDate laterDate:betaDate]]){
			[ESVersionCheckerWindowController showUpdateWindowFromBuild:thisDate toBuild:betaDate];
		}
	}

	checking = NO;
}


//Build Dates ----------------------------------------------------------------------------------------------------------
#pragma mark Build Dates
/*!
 * @brief Returns the date of this build
 */
- (NSDate *)dateOfThisBuild
{
	NSDate *date = nil;

	NSString *path = [[NSBundle mainBundle] pathForResource:@"buildnum" ofType:nil];
	NSMutableData *data = [NSMutableData dataWithContentsOfFile:path];
	if(data) {
		[data increaseLengthBy:1]; //nul-terminates.

		const char *ptr = [data bytes];
		char *nextptr;
		unsigned len    = [data length];
		unsigned i      = 0;

		//first character: 'r'. skip it.
		++i;
		if(i >= len) goto end;

		//grab the build number.
		unsigned long buildnum = strtoul(ptr+i, &nextptr, 10);
#		pragma unused(buildnum)
		i = nextptr - ptr;

		//skip the '|' (with a space on each side of it).
		i += 3;
		if(i >= len) goto end;

		//grab the date number. this is a UNIX date (seconds since 1970-1-1).
		NSTimeInterval unixDate = strtod(ptr+i, &nextptr);
		date = [NSDate dateWithTimeIntervalSince1970:unixDate];

		/*we actually don't need any more information here. if we did, here's what we'd do...
		i = nextptr - ptr;

		//skip the '|'.
		i += 3;
		if(i >= len) goto end;

		//grab the author.
		NSRange range = { i, len - i };
		[data replaceBytesInRange:NSMakeRange(0, i) withBytes:NULL length:0];
		NSString *username = [NSString stringWithData:data encoding:NSUTF8StringEncoding];
		 */
	}

end:
	return date;
}

/*!
 * @brief Returns the date of the most recent Adium build (contacts adiumx.com asynchronously)
 */
- (void)_requestVersionDict
{
	if(!checking) {
		checking = YES;
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
	NSData			*data = [sender resourceDataUsingCache:YES];
	
	if(data){
		NSDictionary	*versionDict;

		versionDict = [NSPropertyListSerialization propertyListFromData:data
													   mutabilityOption:NSPropertyListImmutable
																 format:nil
													   errorDescription:nil];
		
		[self _versionReceived:versionDict];
	}
}

/*!
 * @brief Invoked when the versionDict could not be loaded
 */
- (void)URLResourceDidCancelLoading:(NSURL *)sender
{
	[self _versionReceived:nil];
}
@end
