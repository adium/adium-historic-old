/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AILoginController.h"
#import "AISoundController.h"
#import "AIAccountController.h"
#import "AIToolbarController.h"
#import "AIInterfaceController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIPluginController.h"
#import "AIPreferenceController.h"
#import "AIMenuController.h"
#import "AIDockController.h"
#import "ESFileTransferController.h"
#import "ESContactAlertsController.h"
#import "LNAboutBoxController.h"
#import "AILicenseWindowController.h"

#import <ExceptionHandling/NSExceptionHandler.h>

#import <limits.h> //for PATH_MAX

//#define NEW_APPLICATION_SUPPORT_DIRECTORY

//Path to Adium's application support preferences
#ifdef NEW_APPLICATION_SUPPORT_DIRECTORY
#   define ADIUM_APPLICATION_SUPPORT_DIRECTORY	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium X"]
#   define ADIUM_SUBFOLDER_OF_APP_SUPPORT      @"Adium X"
#else
#   define ADIUM_APPLICATION_SUPPORT_DIRECTORY	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"]
#   define ADIUM_SUBFOLDER_OF_APP_SUPPORT      @"Adium 2.0"
#endif
#define ADIUM_FAQ_PAGE						@"http://faq.adiumx.com/"
#define ADIUM_FORUM_PAGE					@"http://forum.adiumx.com"
#define ADIUM_BUG_PAGE						@"mailto:bugs@adiumx.com"
#define ADIUM_FEEDBACK_PAGE					@"mailto:feedback@adiumx.com"
#define KEY_USER_VIEWED_LICENSE				@"AdiumUserLicenseViewed"

@interface AIAdium (PRIVATE)
- (void)configureCrashReporter;
- (void)completeLogin;
@end

@implementation AIAdium

//Init
- (id)init{
    [AIObject _setSharedAdiumInstance:self];
    return([super init]);
}

//Returns the location of Adium's preference folder (within the system's 'application support' directory)
+ (NSString *)applicationSupportDirectory
{
    return([ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath]);
}


//Core Controllers -----------------------------------------------------------------------------------------------------
#pragma mark Core Controllers
- (AILoginController *)loginController{
    return(loginController);
}
- (AIMenuController *)menuController{
    return(menuController);
}
- (AIAccountController *)accountController{
    return(accountController);
}
- (AIContentController *)contentController{
    return(contentController);
}
- (AIContactController *)contactController{
    return(contactController);
}
- (AISoundController *)soundController{
    return(soundController);
}
- (AIInterfaceController *)interfaceController{
    return(interfaceController);
}
- (AIPreferenceController *)preferenceController{
    return(preferenceController);
}
- (AIToolbarController *)toolbarController{
    return(toolbarController);
}
- (AIDockController *)dockController{
    return(dockController);
}
- (ESFileTransferController *)fileTransferController{
    return(fileTransferController);    
}
- (ESContactAlertsController *)contactAlertsController{
    return(contactAlertsController);
}
//- (BZActivityWindowController *)activityWindowController {
//	return activityWindowController;
//}

//Notifications --------------------------------------------------------------------------------------------------------
#pragma mark Notifications
//Return the shared Adium notification center
- (NSNotificationCenter *)notificationCenter
{
    if(notificationCenter == nil){
        notificationCenter = [[NSNotificationCenter alloc] init];
    }
            
    return(notificationCenter);
}

//Specific notifications can be given a human-readable name and registered as events, which can be used to trigger
//various actions.  This is a bad idea though, because it's combining the internal workings with interface.  This
//should be removed or modified in the future
- (void)registerEventNotification:(NSString *)inNotification displayName:(NSString *)displayName
{
    [eventNotifications setObject:[NSDictionary dictionaryWithObjectsAndKeys:
										inNotification, KEY_EVENT_NOTIFICATION, 
										displayName, KEY_EVENT_DISPLAY_NAME, nil]
						   forKey:inNotification];
}

//Return the current registered event notifications
- (NSDictionary *)eventNotifications
{
    return(eventNotifications);
}


//Startup and Shutdown -------------------------------------------------------------------------------------------------
#pragma mark Startup and Shutdown
//Adium is almost done launching, init
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    notificationCenter = nil;
    eventNotifications = [[NSMutableDictionary alloc] init];
    completedApplicationLoad = NO;

/*
}

//Adium has finished launching
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	*/
	//Display the license agreement
//	NSNumber	*viewedLicense = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_USER_VIEWED_LICENSE];
//	if(!viewedLicense || [viewedLicense intValue] < 1){
//		if([AILicenseWindowController displayLicenseAgreement]){
//			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:KEY_USER_VIEWED_LICENSE];
//		}else{
//			[NSApp terminate:nil];
//		}
//	}

#ifdef NEW_APPLICATION_SUPPORT_DIRECTORY
#warning Using ~/Library/Application Support/Adium X
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *oldPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"];
    NSString *newPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium X"];
    BOOL isDir = NO;
    BOOL oldExists = ([manager fileExistsAtPath:[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"] 
                                    isDirectory:&isDir] && isDir);
    BOOL newExists = ([manager fileExistsAtPath:[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium X"] 
                                    isDirectory:&isDir] && isDir);
                                                           
    //Move that directory!
    if(oldExists & !newExists){
        [manager movePath:oldPath toPath:newPath handler:nil];
    }
#endif
	//Load the crash reporter
#ifdef CRASH_REPORTER
#warning Crash reporter enabled.
    [self configureCrashReporter];
#endif
    //Ignore SIGPIPE, which is a harmless error signal
    //sent when write() or similar function calls fail due to a broken pipe in the network connection
    signal(SIGPIPE, SIG_IGN);

    //Load and init the components
    [loginController initController];
    
    //Begin Login
    [loginController requestUserNotifyingTarget:self selector:@selector(completeLogin)];
    
    completedApplicationLoad = YES;
}

//Forward a re-open message to the interface controller
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    return([interfaceController handleReopenWithVisibleWindows:flag]);
}

//Called by the login controller when a user has been selected, continue logging in
- (void)completeLogin
{
    //Init the controllers.
    [preferenceController initController]; //should init first to allow other controllers access to their prefs
    [toolbarController initController];
    [menuController initController];
    [soundController initController];
    [accountController initController];
    [contactController initController];
    [contentController initController];
    [interfaceController initController];
    [dockController initController];
    [fileTransferController initController];
    [contactAlertsController initController];
//	[NSBundle loadNibNamed:@"ActivityWindow" owner:self];
//    [activityWindowController initController];
	
    [pluginController initController]; //should always load last.  Plugins rely on all the controllers.
	
	//
    [contactController finishIniting];
    [preferenceController finishIniting];
    [interfaceController finishIniting];
    [accountController finishIniting];
}

//Give all the controllers a chance to close down
- (void)applicationWillTerminate:(NSNotification *)notification
{
	//Preference controller needs to close the prefs window before the plugins that control it are unloaded
	[preferenceController beginClosing];

    //Close the controllers in reverse order
    [pluginController closeController]; //should always unload first.  Plugins rely on all the controllers.
    [contactAlertsController closeController];
    [fileTransferController closeController];
    [dockController closeController];
    [interfaceController closeController];
    [contentController closeController];
    [contactController closeController];
    [accountController closeController];
    [soundController closeController];
    [menuController closeController];
    [toolbarController closeController];
    [preferenceController closeController];
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
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_FAQ_PAGE]];
}
- (IBAction)reportABug:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_BUG_PAGE]];
}
- (IBAction)sendFeedback:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_FEEDBACK_PAGE]];
}
- (IBAction)showForums:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_FORUM_PAGE]];
}

//Last call to perform actions before the app shuffles off its mortal coil and joins the bleeding choir invisible
- (IBAction)confirmQuit:(id)sender
{
	//Disconnect all the accounts before quitting
    [accountController disconnectAllAccounts];
	
	[NSApp terminate:nil];
}


//Crash Reporter -------------------------------------------------------------------------------------------------------
#pragma mark Crash Reporter
//Handle a singal by loading the crash reporter and closing Adium down
void Adium_HandleSignal(int i){
    [[NSWorkspace sharedWorkspace] launchApplication:PATH_TO_CRASH_REPORTER];
    exit(-1);
}

//Setup the crash reporter
- (void)configureCrashReporter
{
    //Remove any existing crash logs
    [[NSFileManager defaultManager] trashFileAtPath:EXCEPTIONS_PATH];
    [[NSFileManager defaultManager] trashFileAtPath:CRASHES_PATH];
    
    //Log and Handle all exceptions
    [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:NSLogAndHandleEveryExceptionMask];

    //Install custom handlers which properly terminate Adium if one is received
    signal(SIGILL, Adium_HandleSignal);		/* 4:   illegal instruction (not reset when caught) */
    signal(SIGTRAP, Adium_HandleSignal);	/* 5:   trace trap (not reset when caught) */
    signal(SIGEMT, Adium_HandleSignal);		/* 7:   EMT instruction */
    signal(SIGFPE, Adium_HandleSignal);		/* 8:   floating point exception */
    signal(SIGBUS, Adium_HandleSignal);		/* 10:  bus error */
    signal(SIGSEGV, Adium_HandleSignal);	/* 11:  segmentation violation */
    signal(SIGSYS, Adium_HandleSignal);		/* 12:  bad argument to system call */
    signal(SIGXCPU, Adium_HandleSignal);	/* 24:  exceeded CPU time limit */
    signal(SIGXFSZ, Adium_HandleSignal);	/* 25:  exceeded file size limit */    
	
	//I think SIGABRT is an exception... maybe we should ignore it? I'm really not sure.
	signal(SIGABRT, SIG_IGN);
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
    NSString			*fileDescription = nil, *prefsButton = nil, *advancedPrefsName = nil;
	BOOL				success = NO, requiresRestart = NO;
	int					buttonPressed;
	PREFERENCE_CATEGORY prefsCategory = -1;
    
    //Specify a file extension and a human-readable description of what the files of this type do
    if ([extension caseInsensitiveCompare:@"AdiumPlugin"] == NSOrderedSame){
        destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Plugins"];
        //Plugins haven't been loaded yet if the application isn't done loading, so only request a restart if it has finished loading already 
        requiresRestart = completedApplicationLoad;
        fileDescription = AILocalizedString(@"Adium plugin",nil);
		
    } else if ([extension caseInsensitiveCompare:@"AdiumTheme"] == NSOrderedSame){
        destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Themes"];
        requiresRestart = NO;
        fileDescription = AILocalizedString(@"Adium theme",nil);
		prefsButton = AILocalizedString(@"Open Theme Prefs",nil);
		prefsCategory = AIPref_Advanced_Other;
		advancedPrefsName = @"Themes";
		
    } else if ([extension caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Dock Icons"];
        requiresRestart = NO;
        fileDescription = AILocalizedString(@"dock icon set",nil);
		prefsButton = AILocalizedString(@"Open Dock Prefs",nil);
		prefsCategory = AIPref_Dock;

	} else if ([extension caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Sounds"];
		requiresRestart = NO;
		fileDescription = AILocalizedString(@"sound set",nil);
		prefsButton = AILocalizedString(@"Open Sound Prefs",nil);
		prefsCategory = AIPref_Sound;

	} else if ([extension caseInsensitiveCompare:@"AdiumEmoticonset"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Emoticons"];
		requiresRestart = NO;
		fileDescription = AILocalizedString(@"emoticon set",nil);
		prefsButton = AILocalizedString(@"Open Emoticon Prefs",nil);
		prefsCategory = AIPref_Emoticons;

	} else if ([extension caseInsensitiveCompare:@"AdiumMessageStyle"] == NSOrderedSame){
		if ([NSApp isOnPantherOrBetter]){
			destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Message Styles"];
			requiresRestart = NO;
			fileDescription = AILocalizedString(@"message style",nil);
			prefsButton = AILocalizedString(@"Open Message Prefs",nil);
			prefsCategory = AIPref_Messages;
		}else{
			errorMessage = AILocalizedString(@"Sorry, but Adium Message Styles are not supported in OS X 10.2 (Jaguar) at this time.",nil);
		}
	}

    if (destination){
        NSString    *destinationFilePath = [destination stringByAppendingPathComponent:[filename lastPathComponent]];
        
        NSString	*alertTitle = nil;
        NSString	*alertMsg = nil;
		NSString	*format;
		
		if([filename isEqualToString:destinationFilePath]) {
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
												 handler:nil]){
				
				alertTitle = AILocalizedString(@"Installation Successful","Title of installation successful window");
				alertMsg = [NSString stringWithFormat:AILocalizedString(@"Installation of the %@ %@ was successful.",
																		   "Installation sentence, like 'Installation of the message style Fiat was successful.'."),
					fileDescription,
					[[filename lastPathComponent] stringByDeletingPathExtension]];
				
				if (requiresRestart){
					alertMsg = [alertMsg stringByAppendingString:AILocalizedString(@" Please restart Adium.",nil)];
				}
				
				success = YES;
			}else{
				alertTitle = AILocalizedString(@"Installation Failed","Title of installation failed window");
				alertMsg = [NSString stringWithFormat:AILocalizedString(@"Installation of the %@ %@ was unsuccessful.",
																		"Installation failed sentence, like 'Installation of the message style Fiat was unsuccessful.'."),
					fileDescription,
					[[filename lastPathComponent] stringByDeletingPathExtension]];
			}
		}
		
		[[self notificationCenter] postNotificationName:Adium_Xtras_Changed
												 object:nil];
		
        buttonPressed = NSRunInformationalAlertPanel(alertTitle,alertMsg,nil,prefsButton,nil);
		
		// User clicked the "open prefs" button
		if( buttonPressed == NSAlertAlternateReturn ) {
			switch( prefsCategory ) {
				case AIPref_Advanced_Messages:
				case AIPref_Advanced_ContactList:
				case AIPref_Advanced_Status:
				case AIPref_Advanced_Other:
					[preferenceController openPreferencesToAdvancedPane:advancedPrefsName inCategory:prefsCategory];
					break;
				default:
					[preferenceController openPreferencesToCategory:prefsCategory];
			}
		}
    }else{
		if (!errorMessage){
			errorMessage = AILocalizedString(@"An error occurred while installing the X(tra).",nil);
		}
		
		NSRunAlertPanel(AILocalizedString(@"Installation Failed","Title of installation failed window"),
						errorMessage,
						nil,nil,nil);
	}

    return success;
}

//create a resource folder in the Library/Application\ Support/Adium\ 2.0 folder.
//pass it the name of the folder (e.g. @"Scripts").
//if it is found to already in a library folder, returns that pathname (using
//  the same order of preference as resourcePathsForName:).
//otherwise, creates it in the user library and returns the pathname to it.
- (NSString *)createResourcePathForName:(NSString *)name
{
    BOOL             createIt;
    //this is the subfolder for the user domain (i.e. ~/L/AS/Adium\ 2.0).
    NSString        *targetPath            = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:name];
    NSFileManager   *mgr                   = [NSFileManager defaultManager];
    static NSString *bundleResourcesFolder = nil;
    NSArray         *existing              = [self resourcePathsForName:name];

    if(bundleResourcesFolder == nil) bundleResourcesFolder = [[NSBundle mainBundle] resourcePath];

    //if any resource paths exist *besides* the one in the application bundle,
    //  then we create the one in ~/L/AS/Adium\ 2.0.
    createIt = !([existing count] - ([existing indexOfObject:[bundleResourcesFolder stringByAppendingPathComponent:name]] != NSNotFound));
    if(createIt) {
        NSLog(@"Creating directory %@ for resource folder name %@\n", [targetPath stringByAbbreviatingWithTildeInPath], name);
        if(![mgr createDirectoryAtPath:targetPath attributes:nil]) {
			NSLog(@"\tFAILED!\n");
			targetPath = nil;
#warning localise these
			//future expansion: provide a button to launch Disk Utility --boredzo
			NSRunAlertPanel(/*title*/ [NSString stringWithFormat:@"Could not create the %@ folder\n", name], /*msg*/ @"Try running Repair Permissions from Disk Utility.", /*defaultButton*/ @"OK", /*alternateButton*/ nil, /*otherButton*/ nil);
		}
    } else {
        targetPath = [existing objectAtIndex:0];
    }

    return targetPath;
}

//return zero or more pathnames to objects in the Application Support folders
//  and the resources folder of the application bundle.
//only those pathnames that exist are returned.
- (NSArray *)resourcePathsForName:(NSString *)name
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = NULL;
	NSMutableArray *pathArray = [NSMutableArray arrayWithCapacity:4];

	NSString *adiumFolderName = ADIUM_SUBFOLDER_OF_APP_SUPPORT;
	if(name) {
		adiumFolderName = [adiumFolderName stringByAppendingPathComponent:name];
	}

	FSRef ref;
	OSStatus err = noErr;
	
	// ~/Library/Application\ Support
	err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &ref);
	if(err == noErr) {
		path = [NSString pathForFSRef:&ref];
		if(path) {
			path = [path stringByAppendingPathComponent:adiumFolderName];
		}
		if(path && [manager fileExistsAtPath:path]) {
			[pathArray addObject:path];
		}
	}

	// /Library/Application\ Support
	err = FSFindFolder(kLocalDomain, kApplicationSupportFolderType, kDontCreateFolder, &ref);
	if(err == noErr) {
		path = [NSString pathForFSRef:&ref];
		if(path) {
			path = [path stringByAppendingPathComponent:adiumFolderName];
		}
		if(path && [manager fileExistsAtPath:path]) {
			[pathArray addObject:path];
		}
	}

	// /Network/Library/Application\ Support
	err = FSFindFolder(kNetworkDomain, kApplicationSupportFolderType, kDontCreateFolder, &ref);
	if(err == noErr) {
		path = [NSString pathForFSRef:&ref];
		if(path) {
			path = [path stringByAppendingPathComponent:adiumFolderName];
		}
		if(path && [manager fileExistsAtPath:path]) {
			[pathArray addObject:path];
		}
	}

	//Adium bundle
	if(name) {
		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name] stringByExpandingTildeInPath];
		if([manager fileExistsAtPath:path]) {
			[pathArray addObject:path];
		}
	}
    
	return pathArray;
}

@end
