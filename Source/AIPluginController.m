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

//$Id$
#import "AIPluginController.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/PlugIns"	//Path to the internal plugins
#define DIRECTORY_EXTERNAL_PLUGINS		@"/PlugIns"				//Path to the external plugins
#define EXTENSION_ADIUM_PLUGIN			@"AdiumPlugin"			//File extension of a plugin

#define WEBKIT_PLUGIN					@"Webkit Message View.AdiumPlugin"
#define SMV_PLUGIN						@"Standard Message View.AdiumPlugin"
#define CONFIRMED_PLUGINS				@"Confirmed Plugins"

@interface AIPluginController (PRIVATE)
- (void)unloadPlugins;
- (void)loadPluginsFromPath:(NSString *)pluginPath confirmLoading:(BOOL)confirmLoading;
- (void)loadPluginWithClass:(Class)inClass;
@end

@class AIAccountListPreferencesPlugin, AIAccountMenuAccessPlugin, AIAliasSupportPlugin, AIAlphabeticalSortPlugin,
AIAutoLinkingPlugin, AIAwayMessagesPlugin, AIAwayStatusWindowPlugin, AIContactAwayPlugin, AIContactIdlePlugin,
/*AIContactInfoPlugin,*/ AIContactListEditorPlugin, AIContactOnlineSincePlugin, AIContactSortSelectionPlugin,
AIContactStatusColoringPlugin, AIContactStatusDockOverlaysPlugin, AIContactStatusTabColoringPlugin, AIChatCyclingPlugin,
AIContactWarningLevelPlugin, AIDefaultFormattingPlugin, AIDockAccountStatusPlugin, AIDockBehaviorPlugin,
AIDockIconSelectionPlugin, AIDockUnviewedContentPlugin, AIDualWindowInterfacePlugin, AIEmoticonsPlugin,
AIEventSoundsPlugin, AIGroupedAwayByIdleSortPlugin, AIGroupedIdleAwaySortPlugin, AIIdleAwayManualSortPlugin,
AIIdleAwaySortPlugin, AIIdleSortPlugin, AILaTeXPlugin, AILoggerPlugin,
AIManualSortPlugin, AIMessageAliasPlugin, AIMessageViewSelectionPlugin, AIOfflineContactHidingPlugin, AIPlugin,
AISCLViewPlugin, AISendingKeyPreferencesPlugin, AISpellCheckingPlugin, AITabStatusIconsPlugin, AIChatConsolidationPlugin,
AIStandardToolbarItemsPlugin, AIStatusChangedMessagesPlugin, AIStatusCirclesPlugin, AINewMessagePanelPlugin,
AITextForcingPlugin, AITextToolbarItemsPlugin, AITypingNotificationPlugin, AIContactAccountsPlugin,
AIVolumeControlPlugin, BGThemesPlugin, CBActionSupportPlugin, CBContactCountingDisplayPlugin,
CBStatusMenuItemPlugin, CBURLHandlingPlugin, CSDisconnectAllPlugin, DCMessageContextDisplayPlugin, ESAddressBookIntegrationPlugin,
ESAnnouncerPlugin, ESContactAlertsPlugin, ESContactClientPlugin, ESContactListWindowHandlingPlugin, AIExtendedStatusPlugin,
ESFastUserSwitchingSupportPlugin, ESOpenMessageWindowContactAlertPlugin, ESSendMessageContactAlertPlugin,
ESUserIconHandlingPlugin, ErrorMessageHandlerPlugin, GBApplescriptFiltersPlugin, IdleMessagePlugin, AIContactProfilePlugin,
JSCEventBezelPlugin, SAContactOnlineForPlugin, ESStatusSortPlugin, AIContactSettingsPlugin,
AIIdleTimePlugin, ESContactServersideDisplayName, AIConnectPanelPlugin, CPFVersionChecker, AIContactStatusEventsPlugin,
SHOutputDeviceControlPlugin, SHLinkManagementPlugin, ESBlockingPlugin, BGEmoticonMenuPlugin, BGContactNotesPlugin, SHBookmarksImporterPlugin,
ESMessageEvents, ESAccountEvents, ESSafariLinkToolbarItemPlugin, DCJoinChatPanelPlugin, DCInviteToChatPlugin, AIServiceIconPreferencesPlugin,
ESAccountNetworkConnectivityPlugin, ESMetaContactContentsPlugin, ESApplescriptContactAlertPlugin, ESFileTransferMessagesPlugin;

#ifdef ALL_IN_ONE
@class AIWebKitMessageViewPlugin, CBGaimServicePlugin, NEHTicTacToePlugin;
#endif

@implementation AIPluginController
//init
- (void)initController
{
	
    pluginArray = [[NSMutableArray alloc] init];

#ifdef ADIUM_COMPONENTS
	
	//	[self loadPluginWithClass:[AISMViewPlugin class]];

	// Check for the preferred message view; bail if there is none
	[[owner interfaceController] preferredMessageView];
#endif
	
	[[owner notificationCenter] addObserver:self 
								   selector:@selector(adiumVersionWillBeUpgraded:) 
									   name:Adium_VersionWillBeUpgraded
									 object:nil];
}

- (void)finishIniting
{
#ifdef ADIUM_COMPONENTS
	#ifdef ALL_IN_ONE
		[self loadPluginWithClass:[AIWebKitMessageViewPlugin class]];
		[self loadPluginWithClass:[CBGaimServicePlugin class]];
		[self loadPluginWithClass:[NEHTicTacToePlugin class]];
	#endif
#endif
		
#ifndef ALL_IN_ONE
	[self loadPluginsFromPath:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByExpandingTildeInPath]
			   confirmLoading:NO];
	[self loadPluginsFromPath:[[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:DIRECTORY_EXTERNAL_PLUGINS] stringByExpandingTildeInPath] 
			   confirmLoading:YES];
#endif
}

- (void)adiumVersionWillBeUpgraded:(NSNotification *)notification
{
	//When the version is upgraded, re-request confirmation for external plugins.
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIRMED_PLUGINS];
	
	[[owner notificationCenter] removeObserver:self
										  name:Adium_VersionWillBeUpgraded
										object:nil];
}

//close
- (void)closeController
{
    [self unloadPlugins]; //Uninstall all the plugins
}

- (void)dealloc
{
    [pluginArray release]; pluginArray = nil;

    [super dealloc];
}

//Load all the plugins
- (void)loadPluginsFromPath:(NSString *)pluginPath confirmLoading:(BOOL)confirmLoading
{
    NSArray		*pluginList;
    int			loop;

	//Get the directory listing of plugins
    [[NSFileManager defaultManager] createDirectoriesForPath:pluginPath];
	pluginList = [[NSFileManager defaultManager] directoryContentsAtPath:pluginPath];

	for(loop = 0;loop < [pluginList count];loop++){
	    NSString 		*pluginName;
	    NSBundle		*pluginBundle;
	    AIPlugin		*plugin = nil;

	    pluginName = [pluginList objectAtIndex:loop];
	    //NSLog (@"Loading plugin: \"%@\"", pluginName);
	    if([[pluginName pathExtension] caseInsensitiveCompare:EXTENSION_ADIUM_PLUGIN] == 0){

			//
			if(confirmLoading){
				NSArray	*confirmed = [[NSUserDefaults standardUserDefaults] objectForKey:CONFIRMED_PLUGINS];
				
				if(![confirmed containsObject:pluginName]){
					//If we haven't prompted for this plugin yet
					if(NSRunInformationalAlertPanel([NSString stringWithFormat:@"Disable %@?",[pluginName stringByDeletingPathExtension]],
													@"External plugins may cause crashes and odd behavior after updating Adium.  Disable this plugin if you experience any issues.",
													@"Disable", 
													@"Cancel",
													nil) == NSAlertDefaultReturn){
						
						//Disable the plugin
						NSString	*disabledPath = [[pluginPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Plugins (Disabled)"];
						NSString	*sourcePath = [pluginPath stringByAppendingPathComponent:pluginName];
						NSString	*destPath = [disabledPath stringByAppendingPathComponent:pluginName];
						
						[[NSFileManager defaultManager] createDirectoriesForPath:disabledPath];
						[[NSFileManager defaultManager] movePath:sourcePath toPath:destPath handler:nil];

					}else{
						//Add this plugin to our confirmed list
						NSMutableArray	*newConfirmed;
						
						if(!(newConfirmed = [confirmed mutableCopy])) newConfirmed = [[NSMutableArray alloc] init];
						
						[newConfirmed addObject:pluginName];
						[[NSUserDefaults standardUserDefaults] setObject:newConfirmed forKey:CONFIRMED_PLUGINS];
						
						[newConfirmed release];
					}
				}
			}
			
			
			NS_DURING
				//Load the plugin if the user didn't tell us to disable it
				if( !confirmLoading || [[[NSUserDefaults standardUserDefaults] objectForKey:CONFIRMED_PLUGINS] containsObject:pluginName] ) {

					//...unless it's the WebKit plugin, in which case we test for WebKit first
					if ((![pluginName isEqualToString:WEBKIT_PLUGIN] || [NSApp isWebKitAvailable])){
						pluginBundle = [NSBundle bundleWithPath:[pluginPath stringByAppendingPathComponent:pluginName]];
						if(pluginBundle != nil){						
#if 1
							//Create an instance of the plugin
							Class principalClass = [pluginBundle principalClass];
							if (principalClass != nil){
								plugin = [principalClass newInstanceOfPlugin];
							}else{
								NSLog(@"Failed to obtain principal class from plugin \"%@\" (\"%@\")!",pluginName,[pluginPath stringByAppendingPathComponent:pluginName]);
							}
#else
							//Plugin load timing
							
							NSString	*compactedName = [pluginName compactedString];
							double		timeInterval;
							NSDate		*startTime = [NSDate date];
							
							plugin = [[pluginBundle principalClass] newInstanceOfPlugin];
							
							timeInterval = [[NSDate date] timeIntervalSinceDate:startTime];
							NSLog(@"Plugin Timing: %@ %f",compactedName, timeInterval);
#endif
							
							if(plugin != nil){
								//Add the instance to our list
								[pluginArray addObject:plugin];
							}else{
								NSLog(@"Failed to initialize Plugin \"%@\" (\"%@\")!",pluginName,[pluginPath stringByAppendingPathComponent:pluginName]);
							}
						}else{
							NSLog(@"Failed to open Plugin \"%@\"!",pluginName);
						}
					} else {
						NSLog(AILocalizedString(@"The WebKit Message View plugin failed to load because WebKit is not available.  Please install Safari to enable the WebKit plugin.",nil));
					}
				}
				
				NS_HANDLER	// Handle a raised exception
					NSLog(@"The plugin \"%@\" suffered a fatal assertion!",pluginName);
					if (plugin != nil) {
						NSLog (@"Cleaning up using plugin's pointer");
						// Make sure the plugin was not stored in the pluginArray, since it failed to successfully initialize
						long index = [pluginArray indexOfObject:plugin];
						if (index != NSNotFound) {
							[pluginArray removeObjectAtIndex:index];
						}
						
						//Remove observers
						[[owner notificationCenter] removeObserver:plugin];
						[[NSNotificationCenter defaultCenter] removeObserver:plugin];
					}
					NSString	*errorPartOne = AILocalizedString(@"The","definite article");
					NSString	*errorPartTwo = AILocalizedString(@"plugin failed to load properly.  It may be partially loaded.  If strange behavior ensues, remove it from Adium's plugin directory","part of the plugin error message");
					NSString	*errorPartThree = AILocalizedString(@", then quit and relaunch Adium","end of the plugin error message");
					[[owner interfaceController] handleErrorMessage:(AILocalizedString(@"Plugin load error",nil))
													withDescription:[NSString stringWithFormat:@"%@ \"%@\" %@ (\"%@\")%@.", errorPartOne,
														[pluginName stringByDeletingPathExtension],
														errorPartTwo,
														pluginPath,
														errorPartThree]];
					// It would probably be unsafe to call the plugin's uninstall
				NS_ENDHANDLER
	    }
	}
}

//Unload all the plugins
- (void)unloadPlugins
{
    NSEnumerator	*enumerator;
    AIPlugin		*plugin;
	
    enumerator = [pluginArray objectEnumerator];
    while((plugin = [enumerator nextObject])){
        [plugin uninstallPlugin];
    }
	
}

// Returns YES if the named plugin exists. Does not imply that the plugin actually loaded or is functioning.
- (BOOL)pluginEnabled:(NSString *)pluginName
{
	BOOL inBundle = NO;
	BOOL inExternal = NO;
	
	inBundle = [[NSFileManager defaultManager] fileExistsAtPath:[[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByAppendingPathComponent:pluginName] stringByExpandingTildeInPath]];
	if(!inBundle)
		inExternal = [[NSFileManager defaultManager] fileExistsAtPath:[[[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:DIRECTORY_EXTERNAL_PLUGINS] stringByAppendingPathComponent:pluginName] stringByExpandingTildeInPath]];
	
	AILog(@"#### %@ enabled: in %d, out %d",pluginName,inBundle,inExternal);
	return(inBundle || inExternal);	
}

@end
