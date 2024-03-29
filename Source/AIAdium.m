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
//#import "AICrashController.h"
#import "AIDockController.h"
#import "AIEmoticonController.h"
//#import "AIExceptionController.h"
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
#import "DiskImageUtilities.h"
#import <Adium/AIAdiumProtocol.h>
#import <Adium/AIPathUtilities.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <Sparkle/SUConstants.h>
#import <Sparkle/SUUtilities.h>

//For Apple Help
#import <Carbon/Carbon.h>

#define ADIUM_TRAC_PAGE						@"http://trac.adiumx.com/"
#define ADIUM_REPORT_BUG_PAGE				@"http://trac.adiumx.com/wiki/ReportingBugs"
#define ADIUM_FORUM_PAGE					AILocalizedString(@"http://forum.adiumx.com/","Adium forums page. Localized only if a translated version exists.")
#define ADIUM_FEEDBACK_PAGE					@"mailto:feedback@adiumx.com"

//Portable Adium prefs key
#define PORTABLE_ADIUM_KEY					@"Preference Folder Location"

#define ALWAYS_RUN_SETUP_WIZARD FALSE

static NSString	*prefsCategory;

@interface AIAdium (PRIVATE)
- (void)completeLogin;
- (void)openAppropriatePreferencesIfNeeded;
- (void)configureHelp;
- (void)deleteTemporaryFiles;
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

- (AICorePluginLoader *)pluginLoader
{
	return pluginLoader;
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
/*
#ifdef CRASH_REPORTER
#warning Crash reporter enabled.
    [AICrashController enableCrashCatching];
    [AIExceptionController enableExceptionCatching];
#endif
 */
    //Ignore SIGPIPE, which is a harmless error signal
    //sent when write() or similar function calls fail due to a broken pipe in the network connection
    signal(SIGPIPE, SIG_IGN);
	
	//Check if we're running from the disk image; if we are, offer to copy to /Applications
	[DiskImageUtilities handleApplicationLaunchFromReadOnlyDiskImage];
	
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
		[[self notificationCenter] postNotificationName:AIShowLogAtPathNotification
												 object:queuedLogPathToShow];
		[queuedLogPathToShow release];
	}
	
	completedApplicationLoad = YES;

	[self configureHelp];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(systemTimeZoneDidChange:)
															name:@"NSSystemTimeZoneDidChangeDistributedNotification"
														  object:nil];
	
	//Broadcast our presence
	NSConnection *connection = [NSConnection defaultConnection];
	[connection setRootObject:self];
	[connection registerName:@"com.adiumX.adiumX"];

	[[self notificationCenter] postNotificationName:AIApplicationDidFinishLoadingNotification object:nil];
	[[NSDistributedNotificationCenter defaultCenter]  postNotificationName:AIApplicationDidFinishLoadingNotification object:nil];

	[pool release];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if (![[preferenceController preferenceForKey:@"Confirm Quit"
										   group:@"Confirmations"] boolValue]) {
		return NSTerminateNow;
	}
	
	AIQuitConfirmationType		confirmationType = [[preferenceController preferenceForKey:@"Confirm Quit Type"
																							group:@"Confirmations"] intValue];
	BOOL confirmUnreadMessages	= ![[preferenceController preferenceForKey:@"Suppress Quit Confirmation for Unread Messages"
																	group:@"Confirmations"] boolValue];
	BOOL confirmFileTransfers	= ![[preferenceController preferenceForKey:@"Suppress Quit Confirmation for File Transfers"
																	group:@"Confirmations"] boolValue];
	BOOL confirmOpenChats		= ![[preferenceController preferenceForKey:@"Suppress Quit Confirmation for Open Chats"
																	group:@"Confirmations"] boolValue];
	
	NSString	*questionToAsk = [NSString string];
	SEL			questionSelector = nil;

	NSApplicationTerminateReply allowQuit = NSTerminateNow;
	
	switch (confirmationType) {
		case AIQuitConfirmAlways:
			questionSelector = @selector(confirmQuitQuestion:userInfo:);
			
			allowQuit = NSTerminateLater;
			break;
			
		case AIQuitConfirmSelective:
			if ([chatController unviewedContentCount] > 0 && confirmUnreadMessages) {
				questionToAsk = AILocalizedString(@"You have unread messages.",@"Quit Confirmation");
				questionSelector = @selector(unreadQuitQuestion:userInfo:);
				allowQuit = NSTerminateLater;
			} else if ([fileTransferController activeTransferCount] > 0 && confirmFileTransfers) {
				questionToAsk = AILocalizedString(@"You have file transfers in progress.",@"Quit Confirmation");
				questionSelector = @selector(fileTransferQuitQuestion:userInfo:);
				allowQuit = NSTerminateLater;
			} else if ([[chatController openChats] count] > 0 && confirmOpenChats) {
				questionToAsk = AILocalizedString(@"You have open chats.",@"Quit Confirmation");
				questionSelector = @selector(openChatQuitQuestion:userInfo:);
				allowQuit = NSTerminateLater;
			}

			break;
	}
	
	if (allowQuit == NSTerminateLater) {
		[[self interfaceController] displayQuestion:AILocalizedString(@"Confirm Quit", nil)
									withDescription:[questionToAsk stringByAppendingFormat:@"%@%@",
														([questionToAsk length] > 0 ? @"\n" : @""),
														AILocalizedString(@"Are you sure you want to quit Adium?",@"Quit Confirmation")]
									withWindowTitle:nil
									  defaultButton:AILocalizedString(@"Quit", nil)
									alternateButton:AILocalizedString(@"Cancel", nil)
										otherButton:AILocalizedString(@"Don't ask again", nil)
											 target:self
										   selector:questionSelector
										   userInfo:nil];
	}

	return allowQuit;
}

//Give all the controllers a chance to close down
- (void)applicationWillTerminate:(NSNotification *)notification
{
	//Take no action if we didn't complete the application load
	if (!completedApplicationLoad) return;

	isQuitting = YES;

	[[self notificationCenter] postNotificationName:AIAppWillTerminateNotification object:nil];
	
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

- (BOOL)isQuitting
{
	return isQuitting;
}

//Menu Item Hooks ------------------------------------------------------------------------------------------------------
#pragma mark Menu Item Hooks
//Show the about box
- (IBAction)showAboutBox:(id)sender
{
    [[LNAboutBoxController aboutBoxController] showWindow:nil];
}

- (IBAction)reportABug:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_REPORT_BUG_PAGE]];
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
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		case AITextAndButtonsOtherReturn:
			//Don't Ask Again
			[[self preferenceController] setPreference:[NSNumber numberWithBool:YES]
												 forKey:@"Suppress Quit Confirmation for Unread Messages"
												  group:@"Confirmations"];
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		default:
			//Cancel
			[NSApp replyToApplicationShouldTerminate:NSTerminateCancel];
			break;
	}
}

- (void)openChatQuitQuestion:(NSNumber *)number userInfo:(id)info
{
	AITextAndButtonsReturnCode result = [number intValue];
	switch(result)
	{
		case AITextAndButtonsDefaultReturn:
			//Quit
			//Should we ask about File Transfers here?????
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		case AITextAndButtonsOtherReturn:
			//Don't Ask Again
			[[self preferenceController] setPreference:[NSNumber numberWithBool:YES]
												forKey:@"Suppress Quit Confirmation for Open Chats"
												 group:@"Confirmations"];
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		default:
			//Cancel
			[NSApp replyToApplicationShouldTerminate:NSTerminateCancel];
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
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		case AITextAndButtonsOtherReturn:
			//Don't Ask Again
			[[self preferenceController] setPreference:[NSNumber numberWithBool:YES]
												 forKey:@"Suppress Quit Confirmation for File Transfers"
												  group:@"Confirmations"];
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		default:
			//Cancel
			[NSApp replyToApplicationShouldTerminate:NSTerminateCancel];
			break;
	}
}

- (void)confirmQuitQuestion:(NSNumber *)number userInfo:(id)info
{
	AITextAndButtonsReturnCode result = [number intValue];
	switch(result)
	{
		case AITextAndButtonsDefaultReturn:
			//Quit
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		case AITextAndButtonsOtherReturn:
			//Don't Ask Again
			[[self preferenceController] setPreference:[NSNumber numberWithBool:NO]
												forKey:@"Confirm Quit"
												 group:@"Confirmations"];
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		default:
			//Cancel
			[NSApp replyToApplicationShouldTerminate:NSTerminateCancel];
			break;
	}
}


//Last call to perform actions before the app shuffles off its mortal coil and joins the bleeding choir invisible
- (IBAction)confirmQuit:(id)sender
{
	/* We may have received a message or begun a file transfer while the menu was open, if this is reached via a menu item.
	 * Wait one last run loop before beginning to quit so that activity can be registered, since menus run in
	 * a different run loop mode, NSEventTrackingRunLoopMode.
	 */
	[NSObject cancelPreviousPerformRequestsWithTarget:NSApp
											 selector:@selector(terminate:)
											   object:nil];
	[NSApp performSelector:@selector(terminate:)
			   withObject:nil
			   afterDelay:0];
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
			[[self notificationCenter] postNotificationName:AIShowLogAtPathNotification
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

    /* Specify a file extension and a human-readable description of what the files of this type do
	 * We reassign the extension so that regardless of its original case we end up with the case we want; this allows installation of
	 * xtras to proceed properly on case-sensitive file systems.
	 */
    if ([extension caseInsensitiveCompare:@"AdiumPlugin"] == NSOrderedSame) {
        destination = [AISearchPathForDirectoriesInDomains(AIPluginsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
        //Plugins haven't been loaded yet if the application isn't done loading, so only request a restart if it has finished loading already 
        requiresRestart = completedApplicationLoad;
        fileDescription = AILocalizedString(@"Adium plugin",nil);
		extension = @"AdiumPlugin";

    } else if ([extension caseInsensitiveCompare:@"AdiumLibpurplePlugin"] == NSOrderedSame) {
        destination = [AISearchPathForDirectoriesInDomains(AIPluginsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
        //Plugins haven't been loaded yet if the application isn't done loading, so only request a restart if it has finished loading already 
        requiresRestart = completedApplicationLoad;
        fileDescription = AILocalizedString(@"Adium plugin",nil);
		extension = @"AdiumLibpurplePlugin";

	} else if ([extension caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIDockIconsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
        fileDescription = AILocalizedString(@"dock icon set",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"AdiumIcon";

	} else if ([extension caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AISoundsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"sound set",nil);
		prefsButton = AILocalizedString(@"Open Event Prefs",nil);
		prefsCategory = @"Events";
		extension = @"AdiumSoundset";

	} else if ([extension caseInsensitiveCompare:@"AdiumEmoticonset"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIEmoticonsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"emoticon set",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"AdiumEmoticonset";

	} else if ([extension caseInsensitiveCompare:@"AdiumScripts"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIScriptsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"AppleScript set",nil);
		extension = @"AdiumScripts";

	} else if ([extension caseInsensitiveCompare:@"AdiumMessageStyle"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIMessageStylesDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"message style",nil);
		prefsButton = AILocalizedString(@"Open Message Prefs",nil);
		prefsCategory = @"Messages";
		extension = @"AdiumMessageStyle";

	} else if ([extension caseInsensitiveCompare:@"ListLayout"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIContactListDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"contact list layout",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"ListLayout";

	} else if ([extension caseInsensitiveCompare:@"ListTheme"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIContactListDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"contact list theme",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"ListTheme";

	} else if ([extension caseInsensitiveCompare:@"AdiumServiceIcons"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIServiceIconsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"service icons",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"AdiumServiceIcons";

	} else if ([extension caseInsensitiveCompare:@"AdiumMenuBarIcons"] == NSOrderedSame) {
		destination = [AISearchPathForDirectoriesInDomains(AIMenuBarIconsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
		fileDescription = AILocalizedString(@"menu bar icons",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"AdiumMenuBarIcons";

	} else if ([extension caseInsensitiveCompare:@"AdiumStatusIcons"] == NSOrderedSame) {
		NSString	*packName = [[filename lastPathComponent] stringByDeletingPathExtension];
/*
 //Can't do this because the preferenceController isn't ready yet
 NSString	*defaultPackName = [[self preferenceController] defaultPreferenceForKey:@"Status Icon Pack"
																			  group:@"Appearance"
																			 object:nil];
*/
		NSString	*defaultPackName = @"Gems";

		if (![packName isEqualToString:defaultPackName]) {
			destination = [AISearchPathForDirectoriesInDomains(AIStatusIconsDirectory, NSUserDomainMask, /*expandTilde*/ YES) objectAtIndex:0];
			fileDescription = AILocalizedString(@"status icons",nil);
			prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
			prefsCategory = @"Appearance";
			extension = @"AdiumStatusIcons";

		} else {
			errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ is the name of the default status icon pack; this pack therefore can not be installed.",nil),
				packName];
		}
	}

    if (destination) {
        NSString    *destinationFilePath;
		destinationFilePath = [destination stringByAppendingPathComponent:[[filename lastPathComponent] stringByDeletingPathExtension]];
		destinationFilePath = [destinationFilePath stringByAppendingPathExtension:extension];

        NSString	*alertTitle = nil;
        NSString	*alertMsg = nil;
		NSString	*format;
		
		if ([filename caseInsensitiveCompare:destinationFilePath] == NSOrderedSame) {
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
		
		[[self notificationCenter] postNotificationName:AIXtrasDidChangeNotification
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
		[preferenceController openPreferencesToCategoryWithIdentifier:prefsCategory];
		
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

- (void)systemTimeZoneDidChange:(NSNotification *)inNotification
{
	[NSTimeZone resetSystemTimeZone];
}

- (NSApplication *)application
{
	return [NSApplication sharedApplication];
}

- (NSComparisonResult)compareVersionString:(NSString *)versionA toVersionString:(NSString *)versionB
{
	return SUStandardVersionComparison(versionA, versionB);
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

#pragma mark Help
- (void)configureHelp
{
	CFBundleRef myApplicationBundle;
	CFURLRef myBundleURL;
	FSRef myBundleRef;

	if ((myApplicationBundle = CFBundleGetMainBundle())) {
		myBundleURL = CFBundleCopyBundleURL(myApplicationBundle);

		if (CFURLGetFSRef(myBundleURL, &myBundleRef)) {
			AHRegisterHelpBook(&myBundleRef);
		}
	}
}

#pragma mark Sparkle Delegate Methods

#define NIGHTLY_UPDATE_DICT [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"key", @"Update Type", @"visibleKey", @"nightly", @"value", @"Nightly Versions Only", @"visibleValue", nil]
#define BETA_UPDATE_DICT [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"key", @"Update Type", @"visibleKey", @"beta", @"value", @"Beta or Release Versions", @"visibleValue", nil]
#define RELEASE_UPDATE_DICT [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"key", @"Update Type", @"visibleKey", @"release", @"value", @"Release Versions Only", @"visibleValue", nil]

//Nightlies should update to other nightlies
#if defined(NIGHTLY_RELEASE)
#define UPDATE_TYPE_DICT NIGHTLY_UPDATE_DICT
//For a beta release, always use the beta appcast
#elif defined(BETA_RELEASE)
#define UPDATE_TYPE_DICT BETA_UPDATE_DICT
//For a release, use the beta appcast if AIAlwaysUpdateToBetas is enabled; otherwise, use the release appcast
#else
#define UPDATE_TYPE_DICT ([[NSUserDefaults standardUserDefaults] boolForKey:@"AIAlwaysUpdateToBetas"] ? BETA_UPDATE_DICT : RELEASE_UPDATE_DICT)
#endif

//The first generation ended with 1.0.5 and 1.1. Our Sparkle Plus up to that point had a bug that left it unable to properly handle the sparkle:minimumSystemVersion element.
//The second generation began with 1.0.6 and 1.1.1, with a Sparkle Plus that can handle that element.
#define UPDATE_GENERATION_DICT [NSDictionary dictionaryWithObjectsAndKeys:@"generation", @"key", @"Appcast generation number", @"visibleKey", @"2", @"value", @"2", @"visibleValue", nil]

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
	
	//If we're not sending profile information, or if it hasn't been long enough since the last profile submission, return just the type of update we're looking for and the generation number.
	BOOL sendProfileInfo = [[defaults objectForKey:SUSendProfileInfoKey] boolValue];
	int now = [[NSCalendarDate date] dayOfCommonEra];
	BOOL lastSubmissionWasLongEnoughAgo = (abs([defaults integerForKey:@"AILastSubmittedProfileDate2"] - now) >= 7);
	if (!(sendProfileInfo && lastSubmissionWasLongEnoughAgo)) {
		[profileInfo removeAllObjects];
	} else {
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
	}

	[profileInfo addObject:UPDATE_GENERATION_DICT];
	[profileInfo addObject:UPDATE_TYPE_DICT];
#ifdef NIGHTLY_RELEASE
    NSString *buildId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AIBuildIdentifier"];
    [profileInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"revision", @"key", @"Revision", @"visibleKey", buildId, @"value", buildId, @"visibleValue", nil]];
#endif
	return profileInfo;
}

- (NSArray *)updaterInfoWithoutProfile
{
	return [NSArray arrayWithObjects:UPDATE_GENERATION_DICT, UPDATE_TYPE_DICT, nil];
}

//Treat debug builds as being the same as their corresponding version
- (NSComparisonResult)compareVersion:(NSString *)appcastVersion toVersion:(NSString *)appVersion;
{
	NSRange debugRange;
	if ((debugRange = [appVersion rangeOfString:@"-debug"]).location != NSNotFound)
		appcastVersion = [appVersion substringToIndex:debugRange.location];

	return SUStandardVersionComparison(appcastVersion, appVersion);
}

@end
