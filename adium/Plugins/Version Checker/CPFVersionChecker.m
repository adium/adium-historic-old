//
//  CPFVersionChecker.m
//  Adium
//
//  Created by Christopher Forsythe on Sat Mar 20 2004.
//

#import "CPFVersionChecker.h"
#import "ESVersionCheckerWindowController.h"

#define VERSION_CHECKER_TITLE		@"Check for Updates…"
#define VERSION_PLIST_URL			@"http://www.adiumx.com/version.plist"
#define VERSION_PLIST_KEY			@"adium-version"

#define VERSION_CHECKER_DEFAULTS	@"VersionChecker Defaults"

@interface CPFVersionChecker (PRIVATE)
- (void)_requestVersionThread;
- (void)_versionReceived:(NSDate *)newestDate;
@end

@implementation CPFVersionChecker

//Install
- (void)installPlugin
{
	observingListUpdates = NO;
	
	//Register our defaults
	//Setup Preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:VERSION_CHECKER_DEFAULTS 
																		forClass:[self class]]
										  forGroup:PREF_GROUP_UPDATING];
	
	//Menu item for checking manually
    versionCheckerMenuItem = [[[NSMenuItem alloc] initWithTitle:VERSION_CHECKER_TITLE 
														 target:self 
														 action:@selector(checkForNewVersion:)
												  keyEquivalent:@""] autorelease];
    [[adium menuController] addMenuItem:versionCheckerMenuItem toLocation:LOC_Adium_About];
	
    //Observe preference changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(preferencesChanged:)
									   name:Preference_GroupChanged
									 object:nil];
	[self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
	if(observingListUpdates) [[adium contactController] unregisterListObjectObserver:self];
}

- (void)preferencesChanged:(NSNotification *)notification
{
	if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_UPDATING] == 0){
		BOOL updateAutomatically = [[[adium preferenceController] preferenceForKey:KEY_CHECK_AUTOMATICALLY
																			 group:PREF_GROUP_UPDATING] boolValue];
        if (updateAutomatically){
			if (!observingListUpdates){
				//Listen to accounts for automatic update checking
				[[adium contactController] registerListObjectObserver:self];
				observingListUpdates = YES;
			}
		}else{
			if(observingListUpdates){
				[[adium contactController] unregisterListObjectObserver:self];				
				observingListUpdates = NO;
			}
		}
	}
}

//
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
	if([inObject isKindOfClass:[AIAccount class]]){
		if([inModifiedKeys containsObject:@"Online"] && [[inObject statusObjectForKey:@"Online"] boolValue] == YES){
			//Check for updates
			[self performSelector:@selector(checkForNewVersion:) withObject:nil afterDelay:10.0];

			//Don't check again during this session
			if(observingListUpdates){
				[[adium contactController] unregisterListObjectObserver:self];
				observingListUpdates = NO;
			}
		}
	}
	
	return(nil);
}	


//New version checking -------------------------------------------------------------------------------------------------
#pragma mark New version checking
//Check for a new release of Adium
//The URL load (dateOfLatestBuild) can block, so we do it in a separate thread.  Once the URL load is finished we pass
//control back to the main thread and display the appropriate panel
- (void)checkForNewVersion:(id)sender{
	checkingManually = (sender != nil);
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



//Build Dates ----------------------------------------------------------------------------------------------------------
#pragma mark Build Dates
- (void)_versionReceived:(NSDate *)dateOfLatestBuild
{
	[ESVersionCheckerWindowController showVersionCheckerWindowWithLatestBuildDate:dateOfLatestBuild 
																 checkingManually:checkingManually];
}

//Returns the date of the most recent Adium build (contacts adiumx.com, may block)
- (NSDate *)dateOfLatestBuild
{
	NSURL			*versionURL = [NSURL URLWithString:VERSION_PLIST_URL];
	NSDictionary 	*productVersionDict = [NSDictionary dictionaryWithContentsOfURL:versionURL];
	
	return([NSDate dateWithTimeIntervalSince1970:[[productVersionDict objectForKey:VERSION_PLIST_KEY] doubleValue]]);
}

@end
