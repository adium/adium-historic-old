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
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>

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

#define ADIUM_TRAC_PAGE						@"http://trac.adiumx.com/"
#define ADIUM_FORUM_PAGE					AILocalizedString(@"http://forum.adiumx.com/","Adium forums page. Localize only if a translated version exists.")
#define ADIUM_XTRAS_PAGE					AILocalizedString(@"http://www.adiumxtras.com/","Adium xtras page. Localized only if a translated version exists.")
#define ADIUM_FEEDBACK_PAGE					@"mailto:feedback@adiumx.com"

//Portable Adium prefs key
#define PORTABLE_ADIUM_KEY					@"Preference Folder Location"

static NSString	*prefsCategory;

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
	if ((self = [super init])) {
		[AIObject _setSharedAdiumInstance:self];
	}

	return self;
}

/*!
 * @brief Returns the location of Adium's preference folder
 * 
 * This may be specified in our bundle's info dictionary keyed as PORTABLE_ADIUM_KEY
 * or, by default, be within the system's 'application support' directory.
 */
+ (NSString *)applicationSupportDirectory
{
	//Path to the preferences folder
	static NSString *_preferencesFolderPath = nil;

    //Determine the preferences path if neccessary
	if (!_preferencesFolderPath) {
		_preferencesFolderPath = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:PORTABLE_ADIUM_KEY] stringByExpandingTildeInPath] retain];
		if (!_preferencesFolderPath)
			_preferencesFolderPath = [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] retain];
	}

	return _preferencesFolderPath;
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
- (AIChatController *)chatController{
	return(chatController);
}
- (AIContentController *)contentController{
    return(contentController);
}
- (AIContactController *)contactController{
    return(contactController);
}
- (AIEmoticonController *)emoticonController{
    return(emoticonController);
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
- (AIStatusController *)statusController{
    return(statusController);
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
	prefsCategory = nil;

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
	loginController = [[AILoginController alloc] init];
    
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

	//Plugins and components should always init last, since they rely on everything else.
	componentLoader = [[AICoreComponentLoader alloc] init];
	pluginLoader = [[AICorePluginLoader alloc] init];
	
	//Finish initing
	[menuController controllerDidLoad];			//Loaded by nib
	[accountController controllerDidLoad];		//** Before contactController so accounts and services are available for contact creation
	[contactController controllerDidLoad];		//** Before interfaceController so the contact list is available to the interface
	[interfaceController controllerDidLoad];	//Loaded by nib
	[toolbarController controllerDidLoad];
	[debugController controllerDidLoad];
	[contactAlertsController controllerDidLoad];
	[soundController controllerDidLoad];
	[emoticonController controllerDidLoad];
	[chatController controllerDidLoad];
	[contentController controllerDidLoad];
	[dockController controllerDidLoad];
	[fileTransferController controllerDidLoad];
	[applescriptabilityController controllerDidLoad];
	[statusController controllerDidLoad];

	//Open the preferences if we were unable to because application:openFile: was called before we got here
	[self openAppropriatePreferencesIfNeeded];

	//If no accounts are setup, open the account prefs
	if ([[accountController accounts] count] == 0) {
		[preferenceController openPreferencesToCategoryWithIdentifier:@"accounts"];
	}

	completedApplicationLoad = YES;

	[[self notificationCenter] postNotificationName:Adium_CompletedApplicationLoad object:nil];
}

//Give all the controllers a chance to close down
- (void)applicationWillTerminate:(NSNotification *)notification
{
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
	
	[prefsCategory release]; prefsCategory = nil;
    [advancedPrefsName release]; advancedPrefsName = nil;
	
    //Specify a file extension and a human-readable description of what the files of this type do
    if ([extension caseInsensitiveCompare:@"AdiumPlugin"] == NSOrderedSame) {
        destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Plugins"];
        //Plugins haven't been loaded yet if the application isn't done loading, so only request a restart if it has finished loading already 
        requiresRestart = completedApplicationLoad;
        fileDescription = AILocalizedString(@"Adium plugin",nil);

    } else if ([extension caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Dock Icons"];
        fileDescription = AILocalizedString(@"dock icon set",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";

	} else if ([extension caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Sounds"];
		fileDescription = AILocalizedString(@"sound set",nil);
		prefsButton = AILocalizedString(@"Open Event Prefs",nil);
		prefsCategory = @"events";

	} else if ([extension caseInsensitiveCompare:@"AdiumEmoticonset"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Emoticons"];
		fileDescription = AILocalizedString(@"emoticon set",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
		
	} else if ([extension caseInsensitiveCompare:@"AdiumScripts"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Scripts"];
		fileDescription = AILocalizedString(@"AppleScript set",nil);
		
	} else if ([extension caseInsensitiveCompare:@"AdiumMessageStyle"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Message Styles"];
		fileDescription = AILocalizedString(@"message style",nil);
		prefsButton = AILocalizedString(@"Open Message Prefs",nil);
		prefsCategory = @"messages";
	} else if ([extension caseInsensitiveCompare:@"ListLayout"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Contact List"];
		fileDescription = AILocalizedString(@"contact list layout",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
		
	} else if ([extension caseInsensitiveCompare:@"ListTheme"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Contact List"];
		fileDescription = AILocalizedString(@"contact list theme",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
		
	} else if ([extension caseInsensitiveCompare:@"AdiumServiceIcons"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Service Icons"];
		fileDescription = AILocalizedString(@"service icons",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
		
	} else if ([extension caseInsensitiveCompare:@"AdiumStatusIcons"] == NSOrderedSame) {
		destination = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:@"Status Icons"];
		fileDescription = AILocalizedString(@"status icons",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"appearance";
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
	
	return(success);
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
	targetPath = [ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByAppendingPathComponent:name];	
	
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
			
	adiumFolderName = (name ? [ADIUM_SUBFOLDER_OF_LIBRARY stringByAppendingPathComponent:name] : ADIUM_SUBFOLDER_OF_LIBRARY);

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
	
	//Add the path to the resource in Adium's bundle
	if (name) {
		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name] stringByExpandingTildeInPath];
		if (([defaultManager fileExistsAtPath:path isDirectory:&isDir]) &&
		   (isDir)) {
			[pathArray addObject:path];
		}
	}
    
	return(pathArray);
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
		if ([fileManager fileExistsAtPath:packPath]) return([packPath stringByExpandingTildeInPath]);
	}

    return(nil);	
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

@end
