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

#import "AIAdium.h"
#import "AdiumURLHandling.h"
#import "AIAccountController.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AICoreComponentLoader.h"
#import "AICorePluginLoader.h"
#import "AICrashController.h"
#import "AIDockController.h"
#import "AIEmoticonController.h"
#import "AIExceptionController.h"
#import "AIInterfaceController.h"
#import "AILoginController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "AISoundController.h"
#import "AIStatusController.h"
#import "AIToolbarController.h"
#import "ESApplescriptabilityController.h"
#import "ESContactAlertsController.h"
#import "ESDebugController.h"
#import "ESFileTransferController.h"
#import "LNAboutBoxController.h"
#import "AIXtrasManager.h"
#import "AdiumSetupWizard.h"
#import "ESTextAndButtonsWindowController.h"
#import "AIAppearancePreferences.h"
#import <Adium/AIAdiumProtocol.h>
#import <Adium/AIPathUtilities.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AICalendarDateAdditions.h>
#import <Sparkle/SUConstants.h>
#import <Sparkle/SUUtilities.h>

#define ADIUM_TRAC_PAGE						@"http://trac.adiumx.com/"
#define ADIUM_FORUM_PAGE					AILocalizedString(@"http://forum.adiumx.com/","Adium forums page. Localized only if a translated version exists.")
#define ADIUM_FEEDBACK_PAGE					@"mailto:feedback@adiumx.com"

//Portable Adium prefs key
#define PORTABLE_ADIUM_KEY					@"Preference Folder Location"

#define ALWAYS_RUN_SETUP_WIZARD FALSE

static NSString	*prefsCategory;

enum {
    kNumberType,
    kStringType,
    kPeriodType
};

// The version comparison code here is courtesy of Kevin Ballard, adapted from MacPAD. Thanks, Kevin!

int SUGetCharType(NSString *character)
{
    if ([character isEqualToString:@"."]) {
        return kPeriodType;
    } else if ([character isEqualToString:@"0"] || [character intValue] != 0) {
        return kNumberType;
    } else {
        return kStringType;
    }	
}

NSArray *SUSplitVersionString(NSString *version)
{
    NSString *character;
    NSMutableString *s;
    int i, n, oldType, newType;
    NSMutableArray *parts = [NSMutableArray array];
    if ([version length] == 0) {
        // Nothing to do here
        return parts;
    }
    s = [[[version substringToIndex:1] mutableCopy] autorelease];
    oldType = SUGetCharType(s);
    n = [version length] - 1;
    for (i = 1; i <= n; ++i) {
        character = [version substringWithRange:NSMakeRange(i, 1)];
        newType = SUGetCharType(character);
        if (oldType != newType || oldType == kPeriodType) {
            // We've reached a new segment
			NSString *aPart = [[NSString alloc] initWithString:s];
            [parts addObject:aPart];
			[aPart release];
            [s setString:character];
        } else {
            // Add character to string and continue
            [s appendString:character];
        }
        oldType = newType;
    }
    
    // Add the last part onto the array
    [parts addObject:[NSString stringWithString:s]];
    return parts;
}

NSComparisonResult AICustomVersionComparison(NSString *versionA, NSString *versionB)
{
	NSArray *partsA = SUSplitVersionString(versionA);
    NSArray *partsB = SUSplitVersionString(versionB);
    
    NSString *partA, *partB;
    int i, n, typeA, typeB, intA, intB;
    
    n = MIN([partsA count], [partsB count]);
    for (i = 0; i < n; ++i) {
        partA = [partsA objectAtIndex:i];
        partB = [partsB objectAtIndex:i];
        
        typeA = SUGetCharType(partA);
        typeB = SUGetCharType(partB);
        
        // Compare types
        if (typeA == typeB) {
            // Same type; we can compare
            if (typeA == kNumberType) {
                intA = [partA intValue];
                intB = [partB intValue];
                if (intA > intB) {
                    return NSOrderedAscending;
                } else if (intA < intB) {
                    return NSOrderedDescending;
                }
            } else if (typeA == kStringType) {
                NSComparisonResult result = [partA compare:partB];
                if (result != NSOrderedSame) {
					if ([partA isEqualToString:@"rc"])
						return NSOrderedAscending;
					if ([partB isEqualToString:@"rc"])
						return NSOrderedDescending;
					if ([partA isEqualToString:@"b"])
						return NSOrderedAscending;
					if ([partB isEqualToString:@"b"])
						return NSOrderedDescending;
					if ([partA isEqualToString:@"a"])
						return NSOrderedAscending;
					if ([partB isEqualToString:@"a"])
						return NSOrderedDescending;
                }
				return result;
            }
        } else {
            // Not the same type? Now we have to do some validity checking
            if (typeA != kStringType && typeB == kStringType) {
                // typeA wins
                return NSOrderedAscending;
            } else if (typeA == kStringType && typeB != kStringType) {
                // typeB wins
                return NSOrderedDescending;
            } else {
                // One is a number and the other is a period. The period is invalid
                if (typeA == kNumberType) {
                    return NSOrderedAscending;
                } else {
                    return NSOrderedDescending;
                }
            }
        }
    }
    // The versions are equal up to the point where they both still have parts
    // Lets check to see if one is larger than the other
    if ([partsA count] != [partsB count]) {
        // Yep. Lets get the next part of the larger
        // n holds the value we want
        NSString *missingPart;
        int missingType, shorterResult, largerResult;
        
        if ([partsA count] > [partsB count]) {
            missingPart = [partsA objectAtIndex:n];
            shorterResult = NSOrderedDescending;
            largerResult = NSOrderedAscending;
        } else {
            missingPart = [partsB objectAtIndex:n];
            shorterResult = NSOrderedAscending;
            largerResult = NSOrderedDescending;
        }
        
        missingType = SUGetCharType(missingPart);
        // Check the type
        if (missingType == kStringType) {
            // It's a string. Shorter version wins
            return shorterResult;
        } else {
            // It's a number/period. Larger version wins
            return largerResult;
        }
    }
    
    // The 2 strings are identical
    return NSOrderedSame;
}

@interface AIAdium (PRIVATE)
- (void)configureCrashReporter;
- (void)completeLogin;
- (void)openAppropriatePreferencesIfNeeded;

- (void)deleteTemporaryFiles;
@end

@interface NSObject (JavaObject)
+ (NSString *)getProperty:(NSString *)propertyName;
@end

@implementation AIAdium

//Init
- (id)init
{
	if ((self = [super init])) {
		[AIObject _setSharedAdiumInstance:self];
	}

	return self;
}

//Core Controllers -----------------------------------------------------------------------------------------------------
#pragma mark Core Controllers
- (NSObject <AILoginController> *)loginController{
    return loginController;
}
- (NSObject <AIMenuController> *)menuController{
    return menuController;
}
- (NSObject <AIAccountController> *)accountController{
    return accountController;
}
- (NSObject <AIChatController> *)chatController{
	return chatController;
}
- (NSObject <AIContentController> *)contentController{
    return contentController;
}
- (NSObject <AIContactController> *)contactController{
    return contactController;
}
- (NSObject <AIEmoticonController> *)emoticonController{
    return emoticonController;
}
- (NSObject <AISoundController> *)soundController{
    return soundController;
}
- (NSObject <AIInterfaceController> *)interfaceController{
    return interfaceController;
}
- (NSObject <AIPreferenceController> *)preferenceController{
    return preferenceController;
}
- (NSObject <AIToolbarController> *)toolbarController{
    return toolbarController;
}
- (NSObject <AIDockController> *)dockController{
    return dockController;
}
- (NSObject <AIFileTransferController> *)fileTransferController{
    return fileTransferController;    
}
- (NSObject <AIContactAlertsController> *)contactAlertsController{
    return contactAlertsController;
}
- (NSObject <AIApplescriptabilityController> *)applescriptabilityController{
	return applescriptabilityController;
}
- (NSObject <AIDebugController> *)debugController{
	return debugController;
}
- (NSObject <AIStatusController> *)statusController{
    return statusController;
}

//Loaders --------------------------------------------------------------------------------------------------------
#pragma mark Loaders

- (AICoreComponentLoader *)componentLoader
{
	return componentLoader;
}

//Notifications --------------------------------------------------------------------------------------------------------
#pragma mark Notifications
//Return the shared Adium notification center
- (NSNotificationCenter *)notificationCenter
{
    if (notificationCenter == nil) {
        notificationCenter = [[NSNotificationCenter alloc] init];
    }
            
    return notificationCenter;
}


//Startup and Shutdown -------------------------------------------------------------------------------------------------
#pragma mark Startup and Shutdown
//Adium is almost done launching, init
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    notificationCenter = nil;
    completedApplicationLoad = NO;
	advancedPrefsName = nil;
	prefsCategory = nil;
	queuedURLEvents = nil;
	
	//Load the crash reporter
#ifdef CRASH_REPORTER
#warning Crash reporter enabled.
    [AICrashController enableCrashCatching];
    [AIExceptionController enableExceptionCatching];
#endif
    //Ignore SIGPIPE, which is a harmless error signal
    //sent when write() or similar function calls fail due to a broken pipe in the network connection
    signal(SIGPIPE, SIG_IGN);
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
												   andSelector:@selector(handleURLEvent:withReplyEvent:)
												 forEventClass:kInternetEventClass
													andEventID:kAEGetURL];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	if (!completedApplicationLoad) {
		if (!queuedURLEvents) {
			queuedURLEvents = [[NSMutableArray alloc] init];
		}
		[queuedURLEvents addObject:[[event descriptorAtIndex:1] stringValue]];
	} else {
		[AdiumURLHandling handleURLEvent:[[event descriptorAtIndex:1] stringValue]];
	}
}

//Adium has finished launching
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	//Begin loading and initing the components
	loginController = [[AILoginController alloc] init];
    
    //Begin Login
    [loginController requestUserNotifyingTarget:self selector:@selector(completeLogin)];
}

//Forward a re-open message to the interface controller
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    return [interfaceController handleReopenWithVisibleWindows:flag];
}

//Called by the login controller when a user has been selected, continue logging in
- (void)completeLogin
{
	NSAutoreleasePool *pool;

	pool = [[NSAutoreleasePool alloc] init];

	/* Init the controllers.
	 * Menu and interface controllers are created by MainMenu.nib when it loads.
	 */
	preferenceController = [[AIPreferenceController alloc] init];
	toolbarController = [[AIToolbarController alloc] init];

#ifdef DEBUG_BUILD
	debugController = [[ESDebugController alloc] init];
#else
	debugController = nil;
#endif

	contactAlertsController = [[ESContactAlertsController alloc] init];
	soundController = [[AISoundController alloc] init];
	emoticonController = [[AIEmoticonController alloc] init];
	accountController = [[AIAccountController alloc] init];
	contactController = [[AIContactController alloc] init];
	chatController = [[AIChatController alloc] init];
	contentController = [[AIContentController alloc] init];
	dockController = [[AIDockController alloc] init];
	fileTransferController = [[ESFileTransferController alloc] init];
	applescriptabilityController = [[ESApplescriptabilityController alloc] init];
	statusController = [[AIStatusController alloc] init];

	//Finish setting up the preference controller before the components and plugins load so they can read prefs 
	[preferenceController controllerDidLoad];
	[debugController controllerDidLoad];
	//Safety for when we remove previously included list xtras
	[AIAppearancePreferences migrateOldListSettingsIfNeeded];
	[pool release];

	//Plugins and components should always init last, since they rely on everything else.
	pool = [[NSAutoreleasePool alloc] init];
	componentLoader = [[AICoreComponentLoader alloc] init];
	pluginLoader = [[AICorePluginLoader alloc] init];
	[pool release];

	//Finish initing
	pool = [[NSAutoreleasePool alloc] init];
	[AdiumURLHandling registerURLTypes];		//Asks the user questions so must load after components
	[menuController controllerDidLoad];			//Loaded by nib
	[accountController controllerDidLoad];		//** Before contactController so accounts and services are available for contact creation
	[contactController controllerDidLoad];		//** Before interfaceController so the contact list is available to the interface
	[interfaceController controllerDidLoad];	//Loaded by nib
	[pool release];

	pool = [[NSAutoreleasePool alloc] init];
	[toolbarController controllerDidLoad];
	[contactAlertsController controllerDidLoad];
	[soundController controllerDidLoad];
	[emoticonController controllerDidLoad];
	[chatController controllerDidLoad];
	[contentController controllerDidLoad];
	[dockController controllerDidLoad];
	[fileTransferController controllerDidLoad];
	[pool release];

	pool = [[NSAutoreleasePool alloc] init];
	[applescriptabilityController controllerDidLoad];
	[statusController controllerDidLoad];

	//Open the preferences if we were unable to because application:openFile: was called before we got here
	[self openAppropriatePreferencesIfNeeded];

	//If no accounts are setup, run the setup wizard
	if (([[accountController accounts] count] == 0) || ALWAYS_RUN_SETUP_WIZARD) {
		[AdiumSetupWizard runWizard];
	}

	//Process any delayed URL events 
	if (queuedURLEvents) {
		NSString *eventString = nil;
		NSEnumerator *e  = [queuedURLEvents objectEnumerator];
		while ((eventString = [e nextObject])) {
			[AdiumURLHandling handleURLEvent:eventString];
		}
		[queuedURLEvents release]; queuedURLEvents = nil;
	}
	
	//If we were asked to open a log at launch, do it now
	if (queuedLogPathToShow) {
		[[self notificationCenter] postNotificationName:Adium_ShowLogAtPath
												 object:queuedLogPathToShow];
		[queuedLogPathToShow release];
	}
	
	completedApplicationLoad = YES;

	[[self notificationCenter] postNotificationName:Adium_CompletedApplicationLoad object:nil];
	[pool release];
}

//Give all the controllers a chance to close down
- (void)applicationWillTerminate:(NSNotification *)notification
{
	//Take no action if we didn't complete the application load
	if (!completedApplicationLoad) return;

	[[self notificationCenter] postNotificationName:Adium_WillTerminate object:nil];
	
	//Close the preference window before we shut down the plugins that compose it
	[preferenceController closePreferenceWindow:nil];

    //Close the controllers in reverse order
	[pluginLoader controllerWillClose]; 				//** First because plugins rely on all the controllers
	[componentLoader controllerWillClose];				//** First because components rely on all the controllers
	[statusController controllerWillClose];				//** Before accountController so account states are saved before being set to offline
    [chatController controllerWillClose];				//** Before interfaceController so chats can be correctly closed
	[contactAlertsController controllerWillClose];
    [fileTransferController controllerWillClose];
    [dockController controllerWillClose];
    [interfaceController controllerWillClose];
    [contentController controllerWillClose];
    [contactController controllerWillClose];
    [accountController controllerWillClose];
	[emoticonController controllerWillClose];
    [soundController controllerWillClose];
    [menuController controllerWillClose];
    [applescriptabilityController controllerWillClose];
	[debugController controllerWillClose];
	[toolbarController controllerWillClose];
    [preferenceController controllerWillClose];			//** Last since other controllers may want to write preferences as they close
	
	[self deleteTemporaryFiles];
}

- (void)deleteTemporaryFiles
{
	[[NSFileManager defaultManager] removeFilesInDirectory:[self cachesPath]
												withPrefix:@"TEMP"
											 movingToTrash:NO];
}


//Menu Item Hooks ------------------------------------------------------------------------------------------------------
#pragma mark Menu Item Hooks
//Show the about box
- (IBAction)showAboutBox:(id)sender
{
    [[LNAboutBoxController aboutBoxController] showWindow:nil];
}

//Show our help
- (IBAction)showHelp:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_TRAC_PAGE]];
}
- (IBAction)reportABug:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_TRAC_PAGE]];
}
- (IBAction)sendFeedback:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_FEEDBACK_PAGE]];
}
- (IBAction)showForums:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_FORUM_PAGE]];
}
- (IBAction)showXtras:(id)sender{
	[[AIXtrasManager sharedManager] showXtras];
}

- (IBAction)contibutingToAdium:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://trac.adiumx.com/wiki/ContributingToAdium"]];
}
- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&submit.x=57&submit.y=8&encrypted=-----BEGIN+PKCS7-----%0D%0AMIIHFgYJKoZIhvcNAQcEoIIHBzCCBwMCAQExggEwMIIBLAIBADCBlDCBjjELMAkG%0D%0AA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQw%0D%0AEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UE%0D%0AAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20CAQAwDQYJ%0D%0AKoZIhvcNAQEBBQAEgYAFR5tF%2BRKUV3BS49vJraDG%2BIoWDoZMieUT%2FJJ1Fzjsr511%0D%0Au7hS1F2piJuHuqmm%2F0r8Kf8oaycOo74K3zLmUQ6T6hUS6%2Bh6lZAoIlhI3A1YmqIP%0D%0AdrdY%2FtfKRbWfolDumJ9Mdv%2FzJxPnpdQiTN5K1PMrPYE6GgPWE9WC4V9lqstSmTEL%0D%0AMAkGBSsOAwIaBQAwgZMGCSqGSIb3DQEHATAUBggqhkiG9w0DBwQIjtd%2BN9o4ZB6A%0D%0AcIbH8ZjOLmE35xBQ%2F93chtzIcRXHhIQJVpBRCkyJkdTD3libP3F7TgkrLij1DBxg%0D%0AfFlE0V%2FGTk29Ys%2FwsPO7hNs3YSNuSz0HT5F6sa8aXwFtMCE%2FgB1Ha4qdtYY%2BNETJ%0D%0AEETwNMLefjhaBfI%2BnRxl2K2gggOHMIIDgzCCAuygAwIBAgIBADANBgkqhkiG9w0B%0D%0AAQUFADCBjjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3Vu%0D%0AdGFpbiBWaWV3MRQwEgYDVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9j%0D%0AZXJ0czERMA8GA1UEAxQIbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBh%0D%0AbC5jb20wHhcNMDQwMjEzMTAxMzE1WhcNMzUwMjEzMTAxMzE1WjCBjjELMAkGA1UE%0D%0ABhMCVVMxCzAJBgNVBAgTAkNBMRYwFAYDVQQHEw1Nb3VudGFpbiBWaWV3MRQwEgYD%0D%0AVQQKEwtQYXlQYWwgSW5jLjETMBEGA1UECxQKbGl2ZV9jZXJ0czERMA8GA1UEAxQI%0D%0AbGl2ZV9hcGkxHDAaBgkqhkiG9w0BCQEWDXJlQHBheXBhbC5jb20wgZ8wDQYJKoZI%0D%0AhvcNAQEBBQADgY0AMIGJAoGBAMFHTt38RMxLXJyO2SmS%2BNdl72T7oKJ4u4uw%2B6aw%0D%0AntALWh03PewmIJuzbALScsTS4sZoS1fKciBGoh11gIfHzylvkdNe%2FhJl66%2FRGqrj%0D%0A5rFb08sAABNTzDTiqqNpJeBsYs%2Fc2aiGozptX2RlnBktH%2BSUNpAajW724Nv2Wvhi%0D%0Af6sFAgMBAAGjge4wgeswHQYDVR0OBBYEFJaffLvGbxe9WT9S1wob7BDWZJRrMIG7%0D%0ABgNVHSMEgbMwgbCAFJaffLvGbxe9WT9S1wob7BDWZJRroYGUpIGRMIGOMQswCQYD%0D%0AVQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDU1vdW50YWluIFZpZXcxFDAS%0D%0ABgNVBAoTC1BheVBhbCBJbmMuMRMwEQYDVQQLFApsaXZlX2NlcnRzMREwDwYDVQQD%0D%0AFAhsaXZlX2FwaTEcMBoGCSqGSIb3DQEJARYNcmVAcGF5cGFsLmNvbYIBADAMBgNV%0D%0AHRMEBTADAQH%2FMA0GCSqGSIb3DQEBBQUAA4GBAIFfOlaagFrl71%2Bjq6OKidbWFSE%2B%0D%0AQ4FqROvdgIONth%2B8kSK%2F%2FY%2F4ihuE4Ymvzn5ceE3S%2FiBSQQMjyvb%2Bs2TWbQYDwcp1%0D%0A29OPIbD9epdr4tJOUNiSojw7BHwYRiPh58S1xGlFgHFXwrEBb3dgNbMUa%2Bu4qect%0D%0AsMAXpVHnD9wIyfmHMYIBmjCCAZYCAQEwgZQwgY4xCzAJBgNVBAYTAlVTMQswCQYD%0D%0AVQQIEwJDQTEWMBQGA1UEBxMNTW91bnRhaW4gVmlldzEUMBIGA1UEChMLUGF5UGFs%0D%0AIEluYy4xEzARBgNVBAsUCmxpdmVfY2VydHMxETAPBgNVBAMUCGxpdmVfYXBpMRww%0D%0AGgYJKoZIhvcNAQkBFg1yZUBwYXlwYWwuY29tAgEAMAkGBSsOAwIaBQCgXTAYBgkq%0D%0AhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0wNDAzMjUwNDQ0%0D%0AMzRaMCMGCSqGSIb3DQEJBDEWBBRzTAS6zk5cmMeC49IorY8CM%2BkX0TANBgkqhkiG%0D%0A9w0BAQEFAASBgBsyRfMv9mSyoYq00wIB7BmUHFGq5x%2Ffnr8M24XbKjhkyeULk2NC%0D%0As4jbCgaWNg6grvccJtjbvmDskMKt%2BdS%2BEAkeWwm1Zf%2F%2B5u1fMyb5vo1NNcRIs5oq%0D%0A7SvXiLTPRzVqzQdhVs7PoZG0i0RRIb0tMeo1IssZeB2GE5Nsg0D8PwpB%0D%0A-----END+PKCS7-----"]];
}

- (void)unreadQuitQuestion:(NSNumber *)number userInfo:(id)info
{
	AITextAndButtonsReturnCode result = [number intValue];
	switch(result)
	{
		case AITextAndButtonsDefaultReturn:
			//Quit
			//Should we ask about File Transfers here?????
			[NSApp terminate:nil];
			break;
		case AITextAndButtonsOtherReturn:
			//Don't Ask Again
			[[self preferenceController] setPreference:[NSNumber numberWithBool:YES]
												 forKey:@"Suppress Quit Confirmation for Unread Messages"
												  group:@"Confirmations"];
			[NSApp terminate:nil];
			break;
		default:
			//Cancel
			break;
	}
}

- (void)fileTransferQuitQuestion:(NSNumber *)number userInfo:(id)info
{
	AITextAndButtonsReturnCode result = [number intValue];
	switch(result)
	{
		case AITextAndButtonsDefaultReturn:
			//Quit
			[NSApp terminate:nil];
			break;
		case AITextAndButtonsOtherReturn:
			//Don't Ask Again
			[[self preferenceController] setPreference:[NSNumber numberWithBool:YES]
												 forKey:@"Suppress Quit Confirmation for File Transfers"
												  group:@"Confirmations"];
			[NSApp terminate:nil];
			break;
		default:
			//Cancel
			break;
	}
}

//Last call to perform actions before the app shuffles off its mortal coil and joins the bleeding choir invisible
- (IBAction)confirmQuit:(id)sender
{
	BOOL allowQuit = YES;
	if (([chatController unviewedContentCount] > 0) &&
		(![[preferenceController preferenceForKey:@"Suppress Quit Confirmation for Unread Messages"
											group:@"Confirmations"] boolValue])) {
		[[self interfaceController] displayQuestion:AILocalizedString(@"Confirm Quit", nil)
									withDescription:AILocalizedString(@"You have unread messages.\nAre you sure you want to quit?", nil)
									withWindowTitle:nil
									  defaultButton:AILocalizedString(@"Quit", nil)
									alternateButton:AILocalizedString(@"Cancel", nil)
										otherButton:AILocalizedString(@"Don't ask again", nil)
											 target:self
										   selector:@selector(unreadQuitQuestion:userInfo:)
										   userInfo:nil];
		allowQuit = NO;
	} 
	
	if (allowQuit &&
		([fileTransferController activeTransferCount] > 0) &&
		(![[preferenceController preferenceForKey:@"Suppress Quit Confirmation for File Transfers"
											group:@"Confirmations"]  boolValue])) {
		[[self interfaceController] displayQuestion:AILocalizedString(@"Confirm Quit", nil)
									withDescription:AILocalizedString(@"You have file transfers in progress.\nAre you sure you want to quit?", nil)
									withWindowTitle:nil
									  defaultButton:AILocalizedString(@"Quit", nil)
									alternateButton:AILocalizedString(@"Cancel", nil)
										otherButton:AILocalizedString(@"Don't ask again", nil)
											 target:self
										   selector:@selector(fileTransferQuitQuestion:userInfo:)
										   userInfo:nil];
		allowQuit = NO;
	}
	
	if (allowQuit) {
		[NSApp terminate:nil];
	}
}

//Other -------------------------------------------------------------------------------------------------------
#pragma mark Other
//If Adium was launched by double-clicking an associated file, we get this call after willFinishLaunching but before
//didFinishLaunching
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSString			*extension = [filename pathExtension];
    NSString			*destination = nil;
	NSString			*errorMessage = nil;
    NSString			*fileDescription = nil, *prefsButton = nil;
	BOOL				success = NO, requiresRestart = NO;
	int					buttonPressed;
	
	if (([extension caseInsensitiveCompare:@"AdiumLog"] == NSOrderedSame) ||
		([extension caseInsensitiveCompare:@"AdiumHtmlLog"] == NSOrderedSame) ||
		([extension caseInsensitiveCompare:@"chatlog"] == NSOrderedSame)) {
		if (completedApplicationLoad) {
			//Request display of the log immediately if Adium is ready
			[[self notificationCenter] postNotificationName:Adium_ShowLogAtPath
													 object:filename];
		} else {
			//Queue the request until Adium is done launching if Adium is not ready
			[queuedLogPathToShow release]; queuedLogPathToShow = [filename retain];
		}
		
		//Don't continue to the xtras installation code. Return YES because we handled the open.
		return YES;
	}	
	
	/* Installation of Xtras below this point */

	[prefsCategory release]; prefsCategory = nil;
    [advancedPrefsName release]; advancedPrefsName = nil;

    //Specify a file extension and a human-readable description of what the files of this type do
    if (([extension caseInsensitiveCompare:@"AdiumPlugin"] == NSOrderedSame) ||
		([extension caseInsensitiveCompare:@"AdiumLibgaimPlugin"] == NSOrderedSame)) {
        destination = [AISearchPathForDirectoriesInDomains(AIPluginsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
        //Plugins haven't been loaded yet if the application isn't done loading, so only request a restart if it has finished loading already 
        requiresRestart = completedApplicationLoad;
        fileDescription = AILocalizedString(@"Adium plugin",nil);

    } else if ([extension caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIDockIconsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
        fileDescription = AILocalizedString(@"dock icon set",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";

	} else if ([extension caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AISoundsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"sound set",nil);
		prefsButton = AILocalizedString(@"Open Event Prefs",nil);
		prefsCategory = @"events";

	} else if ([extension caseInsensitiveCompare:@"AdiumEmoticonset"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIEmoticonsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"emoticon set",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
		
	} else if ([extension caseInsensitiveCompare:@"AdiumScripts"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIScriptsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"AppleScript set",nil);
		
	} else if ([extension caseInsensitiveCompare:@"AdiumMessageStyle"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIMessageStylesDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"message style",nil);
		prefsButton = AILocalizedString(@"Open Message Prefs",nil);
		prefsCategory = @"messages";
	} else if ([extension caseInsensitiveCompare:@"ListLayout"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIContactListDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"contact list layout",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
		
	} else if ([extension caseInsensitiveCompare:@"ListTheme"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIContactListDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"contact list theme",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
		
	} else if ([extension caseInsensitiveCompare:@"AdiumServiceIcons"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIServiceIconsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"service icons",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
		
	} else if ([extension caseInsensitiveCompare:@"AdiumStatusIcons"] == NSOrderedSame) {
		NSString	*packName = [[filename lastPathComponent] stringByDeletingPathExtension];
/*
 //Can't do this because the preferenceController isn't ready yet
 NSString	*defaultPackName = [[self preferenceController] defaultPreferenceForKey:@"Status Icon Pack"
																			  group:@"Appearance"
																			 object:nil];
*/
		NSString	*defaultPackName = @"iBubble Status";

		if (![packName isEqualToString:defaultPackName]) {
			destination = [AISearchPathForDirectoriesInDomains(AIStatusIconsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
			fileDescription = AILocalizedString(@"status icons",nil);
			prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
			prefsCategory = @"appearance";
		} else {
			errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ is the name of the default status icon pack; this pack therefore can not be installed.",nil),
				packName];
		}
	}

    if (destination) {
        NSString    *destinationFilePath = [destination stringByAppendingPathComponent:[filename lastPathComponent]];
        
        NSString	*alertTitle = nil;
        NSString	*alertMsg = nil;
		NSString	*format;
		
		if ([filename isEqualToString:destinationFilePath]) {
			// Don't copy the file if it's already in the right place!!
			alertTitle= AILocalizedString(@"Installation Successful","Title of installation successful window");
			
			format = AILocalizedString(@"Installation of the %@ %@ was successful because the file was already in the correct location.",
									   "Installation introduction, like 'Installation of the message style Fiat was successful...'.");
			
			alertMsg = [NSString stringWithFormat:format,
				fileDescription,
				[[filename lastPathComponent] stringByDeletingPathExtension]];
			
		} else {
			//Trash the old file if one exists (since we know it isn't ourself)
			[[NSFileManager defaultManager] trashFileAtPath:destinationFilePath];
			
			//Ensure the directory exists
			[[NSFileManager defaultManager] createDirectoryAtPath:destination attributes:nil];
			
			//Perform the copy and display an alert informing the user of its success or failure
			if ([[NSFileManager defaultManager] copyPath:filename 
												  toPath:destinationFilePath 
												 handler:nil]) {
				
				alertTitle = AILocalizedString(@"Installation Successful","Title of installation successful window");
				alertMsg = [NSString stringWithFormat:AILocalizedString(@"Installation of the %@ %@ was successful.",
																		   "Installation sentence, like 'Installation of the message style Fiat was successful.'."),
					fileDescription,
					[[filename lastPathComponent] stringByDeletingPathExtension]];
				
				if (requiresRestart) {
					alertMsg = [alertMsg stringByAppendingString:AILocalizedString(@" Please restart Adium.",nil)];
				}
				
				success = YES;
			} else {
				alertTitle = AILocalizedString(@"Installation Failed","Title of installation failed window");
				alertMsg = [NSString stringWithFormat:AILocalizedString(@"Installation of the %@ %@ was unsuccessful.",
																		"Installation failed sentence, like 'Installation of the message style Fiat was unsuccessful.'."),
					fileDescription,
					[[filename lastPathComponent] stringByDeletingPathExtension]];
			}
		}
		
		[[self notificationCenter] postNotificationName:Adium_Xtras_Changed
												 object:[[filename lastPathComponent] pathExtension]];
		
        buttonPressed = NSRunInformationalAlertPanel(alertTitle,alertMsg,nil,prefsButton,nil);
		
		// User clicked the "open prefs" button
		if (buttonPressed == NSAlertAlternateReturn) {
			//If we're done loading the app, open the prefs now; if not, it'll be done once the load is finished
			//so the controllers and plugins have had a chance to initialize
			if (completedApplicationLoad) {
				[self openAppropriatePreferencesIfNeeded];
			}
		} else {
			//If the user didn't press the "open prefs" button, clear the pref opening information
			[prefsCategory release]; prefsCategory = nil;
			[advancedPrefsName release]; advancedPrefsName = nil;
		}
		
    } else {
		if (!errorMessage) {
			errorMessage = AILocalizedString(@"An error occurred while installing the X(tra).",nil);
		}
		
		NSRunAlertPanel(AILocalizedString(@"Installation Failed","Title of installation failed window"),
						errorMessage,
						nil,nil,nil);
	}

    return success;
}

- (BOOL)application:(NSApplication *)theApplication openTempFile:(NSString *)filename
{
	BOOL success;
	
	success = [self application:theApplication openFile:filename];
	[[NSFileManager defaultManager] removeFileAtPath:filename handler:nil];
	
	return success;
}

- (void)openAppropriatePreferencesIfNeeded
{
	if (prefsCategory) {
		if ([prefsCategory isEqualToString:@"advanced"]) {
			[preferenceController openPreferencesToAdvancedPane:advancedPrefsName];
		} else {
			[preferenceController openPreferencesToCategoryWithIdentifier:prefsCategory];
		}
		
		[prefsCategory release]; prefsCategory = nil;
	}
}

/*!
 * @brief Returns the location of Adium's preference folder
 * 
 * This may be specified in our bundle's info dictionary keyed as PORTABLE_ADIUM_KEY
 * or, by default, be within the system's 'application support' directory.
 */
- (NSString *)applicationSupportDirectory
{
	//Path to the preferences folder
	static NSString *_preferencesFolderPath = nil;
	
    //Determine the preferences path if neccessary
	if (!_preferencesFolderPath) {
		_preferencesFolderPath = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:PORTABLE_ADIUM_KEY] stringByExpandingTildeInPath] retain];
		if (!_preferencesFolderPath)
			_preferencesFolderPath = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"] retain];
	}
	
	return _preferencesFolderPath;
}

/*!
 * @brief Create a resource folder in the Library/Application\ Support/Adium\ 2.0 folder.
 *
 * Pass it the name of the folder (e.g. @"Scripts").
 * If it is found to already in a library folder, return that pathname, using the same order of preference as
 * -[AIAdium resourcePathsForName:]. Otherwise, create it in the user library and return the pathname to it.
 */
- (NSString *)createResourcePathForName:(NSString *)name
{
    NSString		*targetPath;    //This is the subfolder for the user domain (i.e. ~/L/AS/Adium\ 2.0).
    NSFileManager	*defaultManager;
    NSArray			*existingResourcePaths;

	defaultManager = [NSFileManager defaultManager];
	existingResourcePaths = [self resourcePathsForName:name];
	targetPath = [[self applicationSupportDirectory] stringByAppendingPathComponent:name];	
	
    /*
	 If the targetPath doesn't exist, create it, as this method was called to ensure that it exists
	 for creating files in the user domain.
	 */
    if ([existingResourcePaths indexOfObject:targetPath] == NSNotFound) {
        if (![defaultManager createDirectoryAtPath:targetPath attributes:nil]) {
			BOOL error;
			
			//If the directory could not be created, there may be a file in the way. Death to file.
			error = ![defaultManager trashFileAtPath:targetPath];

			if (!error) error = ![defaultManager createDirectoryAtPath:targetPath attributes:nil];

			if (error) {
				targetPath = nil;
				
				int result;
				result = NSRunCriticalAlertPanel([NSString stringWithFormat:AILocalizedString(@"Could not create the %@ folder.",nil), name],
												 AILocalizedString(@"Try running Repair Permissions from Disk Utility.",nil),
												 AILocalizedString(@"OK",nil), 
												 AILocalizedString(@"Launch Disk Utility",nil), 
												 nil);
				if (result == NSAlertAlternateReturn) {
					[[NSWorkspace sharedWorkspace] launchApplication:@"Disk Utility"];
				}
			}
		}
    } else {
        targetPath = [existingResourcePaths objectAtIndex:0];
    }

    return targetPath;
}

/*!
 * @brief Return zero or more resource pathnames to an filename 
 *
 * Searches in the Application Support folders and the Resources/ folder of the Adium.app bundle.
 * Only those pathnames that exist are returned.  The Adium bundle's resource path will be the last item in the array,
 * so precedence is given to the user and system Application Support folders.
 * 
 * Pass nil to receive an array of paths to existing Adium Application Support folders (plus the Resouces folder).
 *
 * Example: If you call[adium resourcePathsForName:@"Scripts"], and there's a
 * Scripts folder in ~/Library/Application Support/Adium\ 2.0 and in /Library/Application Support/Adium\ 2.0, but not
 * in /System/Library/ApplicationSupport/Adium\ 2.0 or /Network/Library/Application Support/Adium\ 2.0.
 * The array you get back will be { @"/Users/username/Library/Application Support/Adium 2.0/Scripts",
 * @"/Library/Application Support/Adium 2.0/Scripts" }.
 *
 * @param name The full name (including extension as appropriate) of the resource for which to search
 */
- (NSArray *)resourcePathsForName:(NSString *)name
{
	NSArray			*librarySearchPaths;
	NSEnumerator	*searchPathEnumerator;
	NSString		*adiumFolderName, *path;
	NSMutableArray  *pathArray = [NSMutableArray arrayWithCapacity:4];
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	BOOL			isDir;
			
	adiumFolderName = (name ?
					   [[@"Application Support" stringByAppendingPathComponent:@"Adium 2.0"] stringByAppendingPathComponent:name] :
					   [@"Application Support" stringByAppendingPathComponent:@"Adium 2.0"]);

	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
	searchPathEnumerator = [librarySearchPaths objectEnumerator];

	//Copy each discovered path into the pathArray after adding our subfolder path
	while ((path = [searchPathEnumerator nextObject])) {
		NSString	*fullPath;
		
		fullPath = [path stringByAppendingPathComponent:adiumFolderName];
		if (([defaultManager fileExistsAtPath:fullPath isDirectory:&isDir]) &&
			(isDir)) {
			
			[pathArray addObject:fullPath];
		}
	}
	
	/* Check our application support directory directly. It may have been covered by the NSSearchPathForDirectoriesInDomains() search,
	 * or it may be distinct via the Portable Adium preference.
	 */
	path = (name ?
			[[self applicationSupportDirectory] stringByAppendingPathComponent:name] :
			[self applicationSupportDirectory]);
	if (![pathArray containsObject:path] &&
		([defaultManager fileExistsAtPath:path isDirectory:&isDir]) &&
		(isDir)) {
		//Our application support directory should always be first
		if ([pathArray count]) {
			[pathArray insertObject:path atIndex:0];
		} else {
			[pathArray addObject:path];			
		}
	}

	//Add the path to the resource in Adium's bundle
	if (name) {
		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name] stringByExpandingTildeInPath];
		if (([defaultManager fileExistsAtPath:path isDirectory:&isDir]) &&
		   (isDir)) {
			[pathArray addObject:path];
		}
	}
    
	return pathArray;
}


/*!
 * @brief Returns an array of the paths to all of the resources for a given name, filtering out those without a certain extension
 * @param name The full name (including extension as appropriate) of the resource for which to search
 * @param extensions The extension(s) of the resources for which to search, either an NSString or an NSArray
 */
- (NSArray *)allResourcesForName:(NSString *)name withExtensions:(id)extensions {
	NSMutableArray *resources = [NSMutableArray array];
	NSEnumerator *pathEnumerator;
	NSEnumerator *resourceEnumerator;
	NSString *resourceDir;
	NSString *resourcePath;
	BOOL extensionsArray = [extensions isKindOfClass:[NSArray class]];
	NSEnumerator *extensionsEnumerator;
	NSString *extension;
	
	// Get every path that can contain these resources
	pathEnumerator = [[self resourcePathsForName:name] objectEnumerator];
	
	while ((resourceDir = [pathEnumerator nextObject])) {
		resourceEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:resourceDir] objectEnumerator];
		
		while ((resourcePath = [resourceEnumerator nextObject])) {
			// Add each resource to the array
			if (extensionsArray) {
				extensionsEnumerator = [extensions objectEnumerator];
				while ((extension = [extensionsEnumerator nextObject])) {
					if ([[resourcePath pathExtension] caseInsensitiveCompare:extension] == NSOrderedSame)
						[resources addObject:[resourceDir stringByAppendingPathComponent:resourcePath]];
				}
			}
			else {
				if ([[resourcePath pathExtension] caseInsensitiveCompare:extensions] == NSOrderedSame)
					[resources addObject:[resourceDir stringByAppendingPathComponent:resourcePath]];
			}
		}
	}

	return resources;
}

/*!
 * @brief Return the path to be used for caching files for this user.
 *
 * @result A cached, tilde-expanded full path.
 */
- (NSString *)cachesPath
{
	static NSString *cachesPath = nil;

	if (!cachesPath) {
		NSString		*generalAdiumCachesPath;
		NSFileManager	*defaultManager = [NSFileManager defaultManager];

		generalAdiumCachesPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"] stringByAppendingPathComponent:@"Adium"];
		cachesPath = [[generalAdiumCachesPath stringByAppendingPathComponent:[[self loginController] currentUser]] retain];

		//Ensure our cache path exists
		if ([defaultManager createDirectoriesForPath:cachesPath]) {
			//If we have to make directories, try to move old cache files into the new directory
			NSEnumerator	*enumerator;
			NSString		*filename;
			BOOL			isDir;

			enumerator = [[defaultManager directoryContentsAtPath:generalAdiumCachesPath] objectEnumerator];
			while ((filename = [enumerator nextObject])) {
				NSString	*fullPath = [generalAdiumCachesPath stringByAppendingPathComponent:filename];
				
				if (([defaultManager fileExistsAtPath:fullPath isDirectory:&isDir]) &&
				   (!isDir)) {
					[defaultManager movePath:fullPath
									  toPath:[cachesPath stringByAppendingPathComponent:filename]
									 handler:nil];
				}
			}
		}
	}
	
	return cachesPath;
}

- (NSString *)pathOfPackWithName:(NSString *)name extension:(NSString *)extension resourceFolderName:(NSString *)folderName
{
	NSFileManager	*fileManager = [NSFileManager defaultManager];
    NSString		*packFileName = [name stringByAppendingPathExtension:extension];
    NSEnumerator	*enumerator = [[self resourcePathsForName:folderName] objectEnumerator];
    NSString		*resourcePath;

	//Search all our resource paths for the requested pack
    while ((resourcePath = [enumerator nextObject])) {
		NSString *packPath = [resourcePath stringByAppendingPathComponent:packFileName];
		if ([fileManager fileExistsAtPath:packPath]) return [packPath stringByExpandingTildeInPath];
	}

    return nil;	
}

#pragma mark Scripting
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	BOOL handleKey = NO;
	
	if ([key isEqualToString:@"applescriptabilityController"] || 
	   [key isEqualToString:@"interfaceController"] ) {
		handleKey = YES;
		
	}
	
	return handleKey;
}

#pragma mark Sparkle Delegate Methods

/* This method gives the delegate the opportunity to customize the information that will
 * be included with update checks.  Add or remove items from the dictionary as desired.
 * Each entry in profileInfo is an NSDictionary with the following keys:
 *		key: 		The key to be used  when reporting data to the server
 *		visibleKey:	Alternate version of key to be used in UI displays of profile information
 *		value:		Value to be used when reporting data to the server
 *		visibleValue:	Alternate version of value to be used in UI displays of profile information.
 */
- (NSMutableArray *)updaterCustomizeProfileInfo:(NSMutableArray *)profileInfo
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (![[defaults objectForKey:SUSendProfileInfoKey] boolValue])
		return [NSArray array]; 
	
	int now = [[NSCalendarDate date] dayOfCommonEra];

	if (abs([defaults integerForKey:@"AILastSubmittedProfileDate2"] - now) >= 7) {
		[defaults setInteger:now forKey:@"AILastSubmittedProfileDate2"];
		
		NSString *value = ([defaults boolForKey:@"AIHasSentSparkleProfileInfo"]) ? @"no" : @"yes";

		NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
			@"FirstSubmission", @"key", 
			@"First Time Submitting Profile Information", @"visibleKey",
			value, @"value",
			value, @"visibleValue",
			nil];
		
		[profileInfo addObject:entry];
		
		[defaults setBool:YES forKey:@"AIHasSentSparkleProfileInfo"];
		
		/*************** Include info about what IM services are used ************/
		NSMutableString *accountInfo = [NSMutableString string];
		NSCountedSet *condensedAccountInfo = [NSCountedSet set];
		NSEnumerator *accountEnu = [[[self accountController] accounts] objectEnumerator];
		AIAccount *account = nil;
		while ((account = [accountEnu nextObject])) {
			NSString *serviceID = [account serviceID];
			[accountInfo appendFormat:@"%@, ", serviceID];
			if([serviceID isEqualToString:@"Yahoo! Japan"]) serviceID = @"YJ";
			[condensedAccountInfo addObject:[NSString stringWithFormat:@"%@", [serviceID substringToIndex:2]]]; 
		}
		
		NSMutableString *accountInfoString = [NSMutableString string];
		NSEnumerator *infoEnu = [[[condensedAccountInfo allObjects] sortedArrayUsingSelector:@selector(compare:)] objectEnumerator];
		while ((value = [infoEnu nextObject]))
			[accountInfoString appendFormat:@"%@%d", value, [condensedAccountInfo countForObject:value]];
		
		entry = [NSDictionary dictionaryWithObjectsAndKeys:
									@"IMServices", @"key", 
									@"IM Services Used", @"visibleKey",
									accountInfoString, @"value",
									accountInfo, @"visibleValue",
									nil];
		[profileInfo addObject:entry];
		return profileInfo;
	}
	return [NSMutableArray array];
}

- (NSComparisonResult) compareVersion:(NSString *)newVersion toVersion:(NSString *)currentVersion
{
	//Allow updating from betas to anything, and anything to non-betas
	//Careful! a15 is fine, but A15 is not, because it would hit the A in Adium.
	NSCharacterSet *guardCharacters = [NSCharacterSet characterSetWithCharactersInString:@"abBrcRC"];
	if([currentVersion rangeOfCharacterFromSet:guardCharacters].location != NSNotFound || !([newVersion rangeOfCharacterFromSet:guardCharacters].location != NSNotFound))
		return AICustomVersionComparison(newVersion, currentVersion); //handles rc > b > a properly
	else 
		return NSOrderedSame;
}

@end
