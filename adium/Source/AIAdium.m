/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <ExceptionHandling/NSExceptionHandler.h>

#import <limits.h> //for PATH_MAX

//Path to Adium's application support preferences
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"]
#define ADIUM_SUBFOLDER_OF_APP_SUPPORT      @"Adium 2.0"
#define ADIUM_FAQ_PAGE						@"http://faq.adiumx.com/"
#define ADIUM_FORUM_PAGE					@"http://forum.adiumx.com"
#define ADIUM_BUG_PAGE						@"mailto:bugs@adiumx.com"
#define ADIUM_FEEDBACK_PAGE					@"mailto:feedback@adiumx.com"

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
}

//Adium has finished launching
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	//Load the crash reporter
#ifdef CRASH_REPORTER
#warning Crash reporter enabled.
    [self configureCrashReporter];
#endif

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
    [pluginController initController]; //should always load last.  Plugins rely on all the controllers.

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

//A hook for guaring the quit menu item... not really necessary anymore, but it's not hurting anything being here
- (IBAction)confirmQuit:(id)sender
{
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
    
    //Ignore SIGPIPE, which is a harmless error signal
    //sent when write() or similar function calls fail due to a broken pipe in the network connection
    signal(SIGPIPE, SIG_IGN);
	
	//I think SIGABRT is an exception... maybe we should ignore it? I'm really not sure.
	signal(SIGABRT, SIG_IGN);
}

//If Adium was launched by double-clicking an associated file, we get this call after willFinishLaunching but before
//didFinishLaunching
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSString    *extension = [filename pathExtension];
    NSString    *destination = nil;
    BOOL        success = NO;
    NSString    *fileDescription = nil;
    BOOL        requiresRestart = NO;
    
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
    } else if ([extension caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame){
        destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Dock Icons"];
        requiresRestart = NO;
        fileDescription = AILocalizedString(@"dock icon set",nil);
	} else if ([extension caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Sounds"];
		requiresRestart = NO;
		fileDescription = AILocalizedString(@"sound set",nil);
	} else if ([extension caseInsensitiveCompare:@"AdiumEmoticonset"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Emoticons"];
		requiresRestart = NO;
		fileDescription = AILocalizedString(@"emoticon set",nil);
	}

    if (destination){
        NSString    *destinationFilePath = [destination stringByAppendingPathComponent:[filename lastPathComponent]];
        
        NSString *alertTitle = nil;
        //For example: "Installation of the Adium plugin MakeToast"
        NSString *alertMsg = [NSString stringWithFormat:@"%@ %@ %@",
            AILocalizedString(@"Installation of the","Beginning of installation sentence"),
            fileDescription,
            [[filename lastPathComponent] stringByDeletingPathExtension]];
        
        //Trash the old file if one exists AND it isn't ourself
		if([filename isEqualToString:destinationFilePath]) {
			// Don't copy the file if it's already in the right place!!
			alertTitle= AILocalizedString(@"Installation Successful","Title of installation successful window");
			alertMsg = [alertMsg stringByAppendingString:AILocalizedString(@" was successful because the file was already in the correct location.",nil)];
		} else {
			[[NSFileManager defaultManager] trashFileAtPath:destinationFilePath];
			
			//Perform the copy and display an alert informing the user of its success or failure
			if ([[NSFileManager defaultManager] copyPath:filename 
												  toPath:destinationFilePath 
												 handler:nil]){
				
				alertTitle = AILocalizedString(@"Installation Successful","Title of installation successful window");
				alertMsg = [alertMsg stringByAppendingString:AILocalizedString(@" was successful.","End of installation succesful sentence")];
				if (requiresRestart){
					alertMsg = [alertMsg stringByAppendingString:AILocalizedString(@" Please restart Adium.",nil)];
				}
				
				success = YES;
			}else{
				alertTitle = AILocalizedString(@"Installation Failed","Title of installation failed window");
				alertMsg = [alertMsg stringByAppendingString:AILocalizedString(@" was unsuccessful.","End of installation failed sentence")];
			}
		}
        NSRunInformationalAlertPanel(alertTitle,alertMsg,nil,nil,nil);
    }

    return success;
}

//return zero or more pathnames to objects in the Application Support folders.
//only those pathnames that exist are returned.
- (NSArray *)applicationSupportPathsForName:(NSString *)name
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *path = NULL;
	NSMutableArray *pathArray = [NSMutableArray arrayWithCapacity:3];

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

	return pathArray;
}
@end
