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
#import "AIPreferenceController.h"
#import "AIMenuController.h"
#import "AIDockController.h"
#import "ESFileTransferController.h"
#import "ESContactAlertsController.h"
#import "LNAboutBoxController.h"
#import "AICorePluginLoader.h"
#import "AICoreComponentLoader.h"
#import "AICrashController.h"
#import "AIExceptionController.h"


//#define NEW_APPLICATION_SUPPORT_DIRECTORY

//Path to Adium's application support preferences
#ifdef NEW_APPLICATION_SUPPORT_DIRECTORY
#   define ADIUM_APPLICATION_SUPPORT_DIRECTORY	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium X"]
#   define ADIUM_SUBFOLDER_OF_APP_SUPPORT		@"Adium X"
#   define ADIUM_SUBFOLDER_OF_LIBRARY			@"Application Support/Adium X"
#else
#   define ADIUM_APPLICATION_SUPPORT_DIRECTORY	[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"]
#   define ADIUM_SUBFOLDER_OF_APP_SUPPORT		@"Adium 2.0"
#   define ADIUM_SUBFOLDER_OF_LIBRARY			@"Application Support/Adium 2.0"
#endif
#define ADIUM_FAQ_PAGE						@"http://faq.adiumx.com/"
#define ADIUM_FORUM_PAGE					@"http://forum.adiumx.com"
#define ADIUM_XTRAS_PAGE					@"http://www.adiumxtras.com/"
#define ADIUM_BUG_PAGE						@"mailto:bugs@adiumx.com"
#define ADIUM_FEEDBACK_PAGE					@"mailto:feedback@adiumx.com"

//#define KEY_USER_VIEWED_LICENSE				@"AdiumUserLicenseViewed"
//#define KEY_LAST_VERSION_LAUNCHED			@"Last Version Launched"

@interface AIAdium (PRIVATE)
- (void)configureCrashReporter;
- (void)completeLogin;
- (void)openAppropriatePreferencesIfNeeded;
- (NSDictionary *)versionUpgradeDict;

- (NSString *)processBetaVersionString:(NSString *)inString;
- (void)deleteTemporaryFiles;

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
@end

@implementation AIAdium

//Init
- (id)init
{
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
- (ESApplescriptabilityController *)applescriptabilityController{
	return(applescriptabilityController);
}
- (ESDebugController *)debugController{
	return(debugController);
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


//Startup and Shutdown -------------------------------------------------------------------------------------------------
#pragma mark Startup and Shutdown
//Adium is almost done launching, init
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    notificationCenter = nil;
    completedApplicationLoad = NO;
	advancedPrefsName = nil;
	prefsCategory = -1;

#ifdef NEW_APPLICATION_SUPPORT_DIRECTORY
	[self upgradePreferenceFolderFromAdium2ToAdium];
#endif
	//Load the crash reporter
#ifdef CRASH_REPORTER
#warning Crash reporter enabled.
    [AICrashController enableCrashCatching];
    [AIExceptionController enableExceptionCatching];
#endif
    //Ignore SIGPIPE, which is a harmless error signal
    //sent when write() or similar function calls fail due to a broken pipe in the network connection
    signal(SIGPIPE, SIG_IGN);
}

//Adium has finished launching
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	//Begin loading and initing the components
    [loginController initController];
    
    //Begin Login
    [loginController requestUserNotifyingTarget:self selector:@selector(completeLogin)];
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
	[debugController initController]; //should init after the menuController to add its menu item if needed
	[contactAlertsController initController];
    [soundController initController];
    [accountController initController];
	[contactController initController];
    [contentController initController];
    [interfaceController initController];
    [dockController initController];
    [fileTransferController initController];
	[applescriptabilityController initController];
	
//    [activityWindowController initController];
	[componentLoader initController];

	
	[preferenceController willFinishIniting];
	

    [pluginLoader initController]; //should always init last.  Plugins rely on everything else.
	
	
	
	
	
	/*
	 Account controller should finish initing before the contact controller so accounts and services are available
	 for contact creation
	 */
    [accountController finishIniting];
	[contactController finishIniting];
    [interfaceController finishIniting];
	
	
	//Open the preferences if we were unable to because application:openFile: was called before we got here
	[self openAppropriatePreferencesIfNeeded];
	
    completedApplicationLoad = YES;
	
	
	[[self notificationCenter] postNotificationName:Adium_CompletedApplicationLoad object:nil];
}

//Give all the controllers a chance to close down
- (void)applicationWillTerminate:(NSNotification *)notification
{
	//Preference controller needs to close the prefs window before the plugins that control it are unloaded
	[preferenceController beginClosing];

    //Close the controllers in reverse order
    [pluginLoader closeController]; //should always unload first.  Plugins rely on all the controllers.
	[componentLoader closeController];
    [contactAlertsController closeController];
    [fileTransferController closeController];
    [dockController closeController];
    [interfaceController closeController];
    [contentController closeController];
    [contactController closeController];
    [accountController closeController];
    [soundController closeController];
    [menuController closeController];
    [applescriptabilityController closeController];
	[debugController closeController];
	[toolbarController closeController];
    [preferenceController closeController];
	
	[self deleteTemporaryFiles];
}

- (void)deleteTemporaryFiles
{
	[[NSFileManager defaultManager] removeFilesInDirectory:@"~/Library/Caches/Adium"
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
- (IBAction)showXtras:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_XTRAS_PAGE]];
}

//Last call to perform actions before the app shuffles off its mortal coil and joins the bleeding choir invisible
- (IBAction)confirmQuit:(id)sender
{
	[NSApp terminate:nil];
}

- (IBAction)launchJeeves:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:PATH_TO_IMPORTER];
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
	
	prefsCategory = -1;
    [advancedPrefsName release]; advancedPrefsName = nil;
	
    //Specify a file extension and a human-readable description of what the files of this type do
    if ([extension caseInsensitiveCompare:@"AdiumPlugin"] == NSOrderedSame){
        destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Plugins"];
        //Plugins haven't been loaded yet if the application isn't done loading, so only request a restart if it has finished loading already 
        requiresRestart = completedApplicationLoad;
        fileDescription = AILocalizedString(@"Adium plugin",nil);
		
    } else if ([extension caseInsensitiveCompare:@"AdiumTheme"] == NSOrderedSame){
        destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Themes"];
        fileDescription = AILocalizedString(@"Adium theme",nil);
		prefsButton = AILocalizedString(@"Open Theme Prefs",nil);
		prefsCategory = AIPref_Advanced_Other;
		advancedPrefsName = [@"Themes" retain];
		
    } else if ([extension caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Dock Icons"];
        fileDescription = AILocalizedString(@"dock icon set",nil);
		prefsButton = AILocalizedString(@"Open Dock Prefs",nil);
		prefsCategory = AIPref_Dock;

	} else if ([extension caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Sounds"];
		fileDescription = AILocalizedString(@"sound set",nil);
		prefsButton = AILocalizedString(@"Open Sound Prefs",nil);
		prefsCategory = AIPref_Sound;

	} else if ([extension caseInsensitiveCompare:@"AdiumEmoticonset"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Emoticons"];
		fileDescription = AILocalizedString(@"emoticon set",nil);
		prefsButton = AILocalizedString(@"Open Emoticon Prefs",nil);
		prefsCategory = AIPref_Emoticons;
		
	} else if ([extension caseInsensitiveCompare:@"AdiumScripts"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Scripts"];
		fileDescription = AILocalizedString(@"AppleScript set",nil);
		
	} else if ([extension caseInsensitiveCompare:@"AdiumMessageStyle"] == NSOrderedSame){
		if ([NSApp isOnPantherOrBetter]){
			destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Message Styles"];
			fileDescription = AILocalizedString(@"message style",nil);
			prefsButton = AILocalizedString(@"Open Message Prefs",nil);
			prefsCategory = AIPref_Messages;
		}else{
			errorMessage = AILocalizedString(@"Sorry, but Adium Message Styles are not supported in OS X 10.2 (Jaguar).",nil);
		}
	} else if ([extension caseInsensitiveCompare:@"ListLayout"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Contact List"];
		fileDescription = AILocalizedString(@"contact list layout",nil);
		prefsButton = AILocalizedString(@"Open Contact List Prefs",nil);
		prefsCategory = AIPref_ContactList;
	} else if ([extension caseInsensitiveCompare:@"ListTheme"] == NSOrderedSame){
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Contact List"];
		fileDescription = AILocalizedString(@"contact list theme",nil);
		prefsButton = AILocalizedString(@"Open Contact List Prefs",nil);
		prefsCategory = AIPref_ContactList;
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
												 object:[[filename lastPathComponent] pathExtension]];
		
        buttonPressed = NSRunInformationalAlertPanel(alertTitle,alertMsg,nil,prefsButton,nil);
		
		// User clicked the "open prefs" button
		if(buttonPressed == NSAlertAlternateReturn){
			//If we're done loading the app, open the prefs now; if not, it'll be done once the load is finished
			//so the controllers and plugins have had a chance to initialize
			if(completedApplicationLoad) {
				[self openAppropriatePreferencesIfNeeded];
			}
		}else{
			//If the user didn't press the "open prefs" button, clear the pref opening information
			prefsCategory = -1;
			[advancedPrefsName release]; advancedPrefsName = nil;
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

- (BOOL)application:(NSApplication *)theApplication openTempFile:(NSString *)filename
{
	BOOL success;
	
	success = [self application:theApplication openFile:filename];
	[[NSFileManager defaultManager] removeFileAtPath:filename handler:nil];
	
	return(success);
}

- (void)openAppropriatePreferencesIfNeeded
{
	if (prefsCategory != -1){
		switch( prefsCategory ) {
			case AIPref_Advanced_Messages:
			case AIPref_Advanced_ContactList:
			case AIPref_Advanced_Status:
			case AIPref_Advanced_Service:
			case AIPref_Advanced_Other:
				[preferenceController openPreferencesToAdvancedPane:advancedPrefsName inCategory:prefsCategory];
				[advancedPrefsName release]; advancedPrefsName = nil;
				break;
			default:
				[preferenceController openPreferencesToCategory:prefsCategory];
		}
		
		prefsCategory = -1;
	}
}

//Create a resource folder in the Library/Application\ Support/Adium\ 2.0 folder.
//Pass it the name of the folder (e.g. @"Scripts").
//If it is found to already in a library folder, return that pathname (using
//  the same order of preference as resourcePathsForName:).
//Otherwise, create it in the user library and return the pathname to it.
- (NSString *)createResourcePathForName:(NSString *)name
{
    NSString		*targetPath;    //This is the subfolder for the user domain (i.e. ~/L/AS/Adium\ 2.0).
    NSFileManager	*defaultManager;
    NSArray			*existingResourcePaths;

	defaultManager = [NSFileManager defaultManager];
	existingResourcePaths = [self resourcePathsForName:name];
	targetPath = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:name];	
	
    /*
	 If the targetPath doesn't exist, create it, as this method was called to ensure that it exists
	 for creating files in the user domain.
	 */
    if([existingResourcePaths indexOfObject:targetPath] == NSNotFound) {
        if(![defaultManager createDirectoryAtPath:targetPath attributes:nil]) {
			BOOL error;
			
			//If the directory could not be created, there may be a file in the way. Death to file.
			error = ![defaultManager trashFileAtPath:targetPath];

			if (!error) error = ![defaultManager createDirectoryAtPath:targetPath attributes:nil];

			if (error){
				targetPath = nil;
				
				int result;
				result = NSRunCriticalAlertPanel([NSString stringWithFormat:AILocalizedString(@"Could not create the %@ folder.",nil), name],
												 AILocalizedString(@"Try running Repair Permissions from Disk Utility.",nil),
												 AILocalizedString(@"OK",nil), 
												 AILocalizedString(@"Launch Disk Utility",nil), 
												 nil);
				if (result == NSAlertAlternateReturn){
					[[NSWorkspace sharedWorkspace] launchApplication:@"Disk Utility"];
				}
			}
		}
    } else {
        targetPath = [existingResourcePaths objectAtIndex:0];
    }

    return targetPath;
}

//return zero or more pathnames to objects in the Application Support folders
//  and the resources folder of the application bundle.
//only those pathnames that exist are returned.  The Adium bundle's resource path should be the last item in the array.
- (NSArray *)resourcePathsForName:(NSString *)name
{
	NSArray			*librarySearchPaths;
	NSEnumerator	*searchPathEnumerator;
	NSString		*adiumFolderName, *path;
	NSMutableArray  *pathArray = [NSMutableArray arrayWithCapacity:4];
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	BOOL			isDir;
			
	adiumFolderName = (name ? [ADIUM_SUBFOLDER_OF_LIBRARY stringByAppendingPathComponent:name] : ADIUM_SUBFOLDER_OF_LIBRARY);

	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
	searchPathEnumerator = [librarySearchPaths objectEnumerator];

	//Copy each discovered path into the pathArray after adding our subfolder path
	while(path = [searchPathEnumerator nextObject]){
		NSString	*fullPath;
		
		fullPath = [path stringByAppendingPathComponent:adiumFolderName];
		if(([defaultManager fileExistsAtPath:fullPath isDirectory:&isDir]) &&
		   (isDir)){
			
			[pathArray addObject:fullPath];
		}
	}
	
	//Add the path to the resource in Adium's bundle
	if(name){
		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name] stringByExpandingTildeInPath];
		if(([defaultManager fileExistsAtPath:path isDirectory:&isDir]) &&
		   (isDir)){
			[pathArray addObject:path];
		}
	}
    
	return(pathArray);
}

//If this is the first time running a version, post Adium_versionUpgraded with information about the old and new versions.
/*- (NSDictionary *)versionUpgradeDict
{
	NSString	*currentVersionString, *lastLaunchedVersionString;
	float	    currentVersion, lastLaunchedVersion;
	NSNumber	*currentVersionNumber;
	NSDictionary	*versionUpgradeDict = nil;
	
	currentVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	lastLaunchedVersionString = [[self preferenceController] preferenceForKey:KEY_LAST_VERSION_LAUNCHED
																		group:PREF_GROUP_GENERAL];	
	// ##### BETA ONLY
#if BETA_RELEASE
	//Friendly reminder that we are running with the beta flag on
	NSString	*spaces1, *spaces2;
	unsigned	length = [currentVersionString length];
	
	spaces1 = [@"" stringByPaddingToLength:(length / 2)
								withString:@" "
						   startingAtIndex:0];	
	if (length % 2 == 0){
		//An even length is one space too much
		spaces2 = [@"" stringByPaddingToLength:(length / 2) - 1
									withString:@" "
							   startingAtIndex:0];			
	}else{
		//An odd length is okay
		spaces2 = spaces1;
	}
	
	NSLog(@"####     %@THIS IS A BETA RELEASE!%@     ####",spaces1,spaces2);
	NSLog(@"#### Loading Adium X BETA Release v%@ ####",currentVersionString);

	AILog(@"####     %@THIS IS A BETA RELEASE!%@     ####",spaces1,spaces2);
	AILog(@"#### Loading Adium X BETA Release v%@ ####",currentVersionString);

	currentVersionString = [self processBetaVersionString:currentVersionString];
	lastLaunchedVersionString = [self processBetaVersionString:lastLaunchedVersionString];
#endif	
	
	currentVersion = [currentVersionString floatValue];
	currentVersionNumber = [NSNumber numberWithFloat:currentVersion];
	
	lastLaunchedVersion = [lastLaunchedVersionString floatValue];	

	if (!lastLaunchedVersion || !currentVersion || currentVersion > lastLaunchedVersion){
		
		if (lastLaunchedVersion){
			
			NSNumber		*lastLaunchedVersionNumber = [NSNumber numberWithFloat:lastLaunchedVersion];
			
			versionUpgradeDict = [NSDictionary dictionaryWithObjectsAndKeys:lastLaunchedVersionNumber, @"lastLaunchedVersion",
				currentVersionNumber,@"currentVersion",
				nil];
		}else{
			versionUpgradeDict = [NSDictionary dictionaryWithObject:currentVersionNumber
															 forKey:@"currentVersion"];			
		}
	}
	
	//Remember that we have now run in this version.
	if(versionUpgradeDict){
		[[self preferenceController] setPreference:currentVersionString
											forKey:KEY_LAST_VERSION_LAUNCHED
											 group:PREF_GROUP_GENERAL];
	 }
	
	return(versionUpgradeDict);
}

- (NSString *)processBetaVersionString:(NSString *)inString
{
	NSString	*returnString = nil;
	
	if ([inString isEqualToString:@"0.7b1"]){
		returnString = @"0.68";
	}else if ([inString isEqualToString:@"0.7b2"]){
		returnString = @"0.681";
	}else if ([inString isEqualToString:@"0.7b3"]){
		returnString = @"0.682";
	}else if ([inString isEqualToString:@"0.7b4"]){
		returnString = @"0.683";
	}else if ([inString isEqualToString:@"0.7b5"]){
		returnString = @"0.684";
	}else if ([inString isEqualToString:@"0.7b6"]){
		returnString = @"0.685";
	}else if ([inString isEqualToString:@"0.7b7"]){
		returnString = @"0.686";
	}else if ([inString isEqualToString:@"0.7b8"]){
		returnString = @"0.687";
	}
	
	return(returnString ? returnString : inString);
}*/

#pragma mark Scripting
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	BOOL handleKey = NO;
	
	if([key isEqualToString:@"applescriptabilityController"] || 
	   [key isEqualToString:@"interfaceController"] ){
		handleKey = YES;
		
	}
	
	return handleKey;
}

@end
