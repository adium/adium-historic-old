//
//  CPFVersionChecker.m
//  Adium
//
//  Created by Christopher Forsythe on Sat Mar 20 2004.
//

#import "CPFVersionChecker.h"
#import "ESVersionCheckerWindowController.h"

#define VERSION_CHECKER_TITLE		AILocalizedString(@"Check for Updates...",nil)
#define VERSION_PLIST_URL			@"http://www.adiumx.com/version.plist"
#define VERSION_PLIST_KEY			@"adium-version"
#define VERSION_BETA_PLIST_KEY		@"adium-beta-version"

#define VERSION_CHECK_INTERVAL		24		//24 hours
#define BETA_VERSION_CHECK_INTERVAL	4		//4 hours - Beta releases have a nice annoying refresh >:D

#define VERSION_CHECKER_DEFAULTS	@"VersionChecker Defaults"

@interface CPFVersionChecker (PRIVATE)
- (void)_requestVersionThread;
- (void)_versionReceived:(NSDictionary *)versionDict;
- (NSDate *)dateOfThisBuild;
- (NSDate *)dateOfLatestBuild;
@end

@implementation CPFVersionChecker

//Install
- (void)installPlugin
{
	//Configure our default preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:VERSION_CHECKER_DEFAULTS 
																		forClass:[self class]]
																		forGroup:PREF_GROUP_UPDATING];

	//Menu item for checking manually
    versionCheckerMenuItem = [[[NSMenuItem alloc] initWithTitle:VERSION_CHECKER_TITLE 
														 target:self 
														 action:@selector(manualCheckForNewVersion:)
												  keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:versionCheckerMenuItem toLocation:LOC_Adium_About];
	
	//Observe connectivity changes
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(networkConnectivityChanged:)
												 name:AINetwork_ConnectivityChanged
											   object:nil];
	
	//Check for an update now
	[self automaticCheckForNewVersion:nil];
	
	//Check for updates again every 24 hours (60 seconds * 60 minutes * 24 hours)
	timer = [[NSTimer scheduledTimerWithTimeInterval:(60 * 60 * (BETA_RELEASE_EXPIRATION ? BETA_VERSION_CHECK_INTERVAL : VERSION_CHECK_INTERVAL))
											  target:self
											selector:@selector(automaticCheckForNewVersion:)
											userInfo:nil
											 repeats:YES] retain];
}

- (void)uninstallPlugin
{
	[timer invalidate]; [timer release];
}


//New version checking -------------------------------------------------------------------------------------------------
#pragma mark New version checking
//Check for a new release of Adium.
- (void)manualCheckForNewVersion:(id)sender
{
	checkingManually = YES;
	checkWhenConnectionBecomesAvailable = NO;
	[NSThread detachNewThreadSelector:@selector(_requestVersionThread) toTarget:self withObject:nil];
}

//Check for a new release of Adium without notifying the user on a false result.
//Call this method when the user has not explicitely requested the version check.
- (void)automaticCheckForNewVersion:(id)sender
{
	BOOL updateAutomatically = [[[adium preferenceController] preferenceForKey:KEY_CHECK_AUTOMATICALLY
																		 group:PREF_GROUP_UPDATING] boolValue];

	if(BETA_RELEASE_EXPIRATION || updateAutomatically){
		if([AINetworkConnectivity networkIsReachable]){
			//If the network is available, check for updates now
			checkingManually = NO;
			checkWhenConnectionBecomesAvailable = NO;
			[NSThread detachNewThreadSelector:@selector(_requestVersionThread) toTarget:self withObject:nil];
		}else{
			//If the network is not available, check when it becomes available
			checkWhenConnectionBecomesAvailable = YES;
		}
	}
}

//When a network connection becomes available, check for an update if we haven't already
- (void)networkConnectivityChanged:(NSNotification *)notification
{
	if(checkWhenConnectionBecomesAvailable && [[notification object] intValue]){
		[self automaticCheckForNewVersion:nil];
	}
}

//Thread Request a version
//The URL load (dateOfLatestBuild) can block, so we do it in a separate thread.  Once the URL load is finished we pass
//control back to the main thread and display the appropriate panel
- (void)_requestVersionThread
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];

	[self performSelectorOnMainThread:@selector(_versionReceived:)
						   withObject:[self dateOfLatestBuild]
						waitUntilDone:YES];
	[pool release];
}

//Version received
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
	if(BETA_RELEASE_EXPIRATION){
		NSString	*betaNumber = [versionDict objectForKey:VERSION_BETA_PLIST_KEY];
		NSDate		*betaDate = nil;
		
		if(versionDict && number) betaDate = [NSDate dateWithTimeIntervalSince1970:[betaNumber doubleValue]];
		if(!betaDate){
			[ESVersionCheckerWindowController showCannotConnectWindow];
		}else if(![thisDate isEqualToDate:betaDate] && ![thisDate isEqualToDate:[thisDate laterDate:betaDate]]){
			[ESVersionCheckerWindowController showUpdateWindowFromBuild:thisDate toBuild:betaDate];
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
	return([NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:VERSION_PLIST_URL]]);
}

@end
