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

//Path to Adium's application support preferences
#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"]

#define ADIUM_FAQ_PAGE                          @"http://adium.sourceforge.net/faq/"

@interface AIAdium (PRIVATE)
- (void)configureCrashReporter;
- (void)completeLogin;
@end

void Adium_HandleSignal(int i){
    NSLog(@"Launching the Adium Crash Reporter because Adium went *boom* (Signal %i)",i);
    [[NSWorkspace sharedWorkspace] launchApplication:PATH_TO_CRASH_REPORTER];
    //Move along, citizen, nothing more to see here.
    exit(-1);
}

@implementation AIAdium

//Returns the shared AIAdium instance
//static AIAdium *sharedInstance = nil;
/*+ (AIAdium *)sharedInstance{
    return(sharedInstance);
}*/
- (id)init{
    [AIObject _setSharedAdiumInstance:self];
    return([super init]);
}

//Returns the location of Adium's preference folder (within the system's 'application support' directory)
+ (NSString *)applicationSupportDirectory
{
    return([ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath]);
}

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

// Notifications --
- (NSNotificationCenter *)notificationCenter
{
    if(notificationCenter == nil){
        notificationCenter = [[NSNotificationCenter alloc] init];
    }
            
    return(notificationCenter);
}

// Specific notifications can be given a human-readable name and registered as events - which can be used to trigger various actions
- (void)registerEventNotification:(NSString *)inNotification displayName:(NSString *)displayName
{
    [eventNotifications setObject:[NSDictionary dictionaryWithObjectsAndKeys:
										inNotification, KEY_EVENT_NOTIFICATION, 
										displayName, KEY_EVENT_DISPLAY_NAME, nil]
						   forKey:inNotification];
}


- (NSDictionary *)eventNotifications
{
    return(eventNotifications);
}


// Internal --------------------------------------------------------------------------------


- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    return([interfaceController handleReopenWithVisibleWindows:flag]);
}

// Called by the login controller when a user has been selected
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

- (void)applicationWillTerminate:(NSNotification *)notification
{
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
    
    // Clear out old event notifications
    //[eventNotifications removeAllObjects];
}

- (IBAction)showAboutBox:(id)sender
{
    [[LNAboutBoxController aboutBoxController] showWindow:nil];
}
- (IBAction)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_FAQ_PAGE]];
}


- (IBAction)confirmQuit:(id)sender
{
/*    if([[contentController chatArray] count] > 0)
    {
        if(NSRunCriticalAlertPanel(@"Quit Adium?", @"You have open conversations, do you want to quit Adium? ", @"Quit", @"Cancel", nil) == NSAlertDefaultReturn)
        {
            [NSApp terminate:nil];
        }
    }
    else
    {*/
        [NSApp terminate:nil];
//    }
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    //init
    notificationCenter = nil;
    eventNotifications = [[NSMutableDictionary alloc] init];
    completedApplicationLoad = NO;
    //play a sound to prevent a delay later when quicktime loads
    //    [AISoundController playSoundNamed:@"Beep"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	
//#ifdef CRASH_REPORTER
#warning Crash reporter active!
    [self configureCrashReporter];
//#endif
	
    //Load and init the components
    [loginController initController];
    
    //Begin Login
    [loginController requestUserNotifyingTarget:self selector:@selector(completeLogin)];
    
    completedApplicationLoad = YES;
}
- (void)configureCrashReporter
{
    // Remove any existing crash logs
    [[NSFileManager defaultManager] trashFileAtPath:EXCEPTIONS_PATH];
    [[NSFileManager defaultManager] trashFileAtPath:CRASHES_PATH];
    
    // Log and Handle all exceptions
    [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:NSLogAndHandleEveryExceptionMask];
    
    // NSExceptionHandler messes up crash signals - install a custom handler which properly terminates Adium if one is received
    signal(SIGILL, Adium_HandleSignal);		/* 4:   illegal instruction (not reset when caught) */
    signal(SIGTRAP, Adium_HandleSignal);	/* 5:   trace trap (not reset when caught) */
    signal(SIGEMT, Adium_HandleSignal);		/* 7:   EMT instruction */
    signal(SIGFPE, Adium_HandleSignal);		/* 8:   floating point exception */
    signal(SIGBUS, Adium_HandleSignal);		/* 10:  bus error */
    signal(SIGSEGV, Adium_HandleSignal);	/* 11:  segmentation violation */
    signal(SIGSYS, Adium_HandleSignal);		/* 12:  bad argument to system call */
    signal(SIGXCPU, Adium_HandleSignal);	/* 24:  exceeded CPU time limit */
    signal(SIGXFSZ, Adium_HandleSignal);	/* 25:  exceeded file size limit */    
    
    // Ignore SIGPIPE, which is a harmless error signal
    // sent when write() or similar function calls fail due to a broken pipe in the network connection
    signal(SIGPIPE, SIG_IGN);
	
	// I think SIGABRT is an exception... maybe we should ignore it? I'm really not sure.
	signal(SIGABRT, SIG_IGN);
}

//If Adium was launched by double-clicking an associated file, we get this call after willFinishLaunching but before didFinishLaunching
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
	}
	
    if (destination){
        NSString    *destinationFilePath = [destination stringByAppendingPathComponent:[filename lastPathComponent]];
        
        NSString *alertTitle = nil;
        //For example: "Installation of the Adium plugin MakeToast"
        NSString *alertMsg = [NSString stringWithFormat:@"%@ %@ %@",
            AILocalizedString(@"Installation of the","Beginning of installation sentence"),
            fileDescription,
            [[filename lastPathComponent] stringByDeletingPathExtension]];
        
        //Trash the old file if one exists
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
        NSRunInformationalAlertPanel(alertTitle,alertMsg,nil,nil,nil);
    }

    return success;
}

@end

