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

//$Id: AIPluginController.m,v 1.72 2004/06/04 19:20:36 evands Exp $
#import "AIPluginController.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/PlugIns"	//Path to the internal plugins
#define DIRECTORY_EXTERNAL_PLUGINS		@"/Plugins"				//Path to the external plugins
#define EXTENSION_ADIUM_PLUGIN			@"AdiumPlugin"			//File extension of a plugin

#define WEBKIT_PLUGIN					@"Webkit Message View.AdiumPlugin"
#define CONFIRMED_PLUGINS				@"Confirmed Plugins"

@interface AIPluginController (PRIVATE)
- (void)unloadPlugins;
- (void)loadPluginsFromPath:(NSString *)pluginPath confirmLoading:(BOOL)confirmLoading;
- (void)loadPluginWithClass:(Class)inClass;
@end

@class AIAccountListPreferencesPlugin, AIAccountMenuAccessPlugin, AIAliasSupportPlugin, AIAlphabeticalSortPlugin,
AIAutoLinkingPlugin, AIAwayMessagesPlugin, AIAwayStatusWindowPlugin, AIContactAwayPlugin, AIContactIdlePlugin,
/*AIContactInfoPlugin,*/ AIContactListEditorPlugin, AIContactOnlineSincePlugin, AIContactSortSelectionPlugin,
AIContactStatusColoringPlugin, AIContactStatusDockOverlaysPlugin, AIContactStatusTabColoringPlugin,
AIContactWarningLevelPlugin, AIDefaultFormattingPlugin, AIDockAccountStatusPlugin, AIDockBehaviorPlugin,
AIDockIconSelectionPlugin, AIDockUnviewedContentPlugin, AIDualWindowInterfacePlugin, AIEmoticonsPlugin,
AIEventSoundsPlugin, AIGroupedAwayByIdleSortPlugin, AIGroupedIdleAwaySortPlugin, AIIdleAwayManualSortPlugin,
AIIdleAwaySortPlugin, AIIdleSortPlugin, AIIdleTimeDisplayPlugin, AILaTeXPlugin, AILoggerPlugin,
AIManualSortPlugin, AIMessageAliasPlugin, AIMessageViewSelectionPlugin, AIOfflineContactHidingPlugin, AIPlugin,
AISCLViewPlugin, AISendingKeyPreferencesPlugin, AISpellCheckingPlugin,
AIStandardToolbarItemsPlugin, AIStatusChangedMessagesPlugin, AIStatusCirclesPlugin,
AITextForcingPlugin, AITextToolbarItemsPlugin, AITypingNotificationPlugin,
AIVolumeControlPlugin, BGThemesPlugin, CBActionSupportPlugin, CBContactCountingDisplayPlugin,
CBStatusMenuItemPlugin, CBURLHandlingPlugin, CSDisconnectAllPlugin, DCMessageContextDisplayPlugin, ESAddressBookIntegrationPlugin,
ESAnnouncerPlugin, ESContactAlertsPlugin, ESContactClientPlugin, ESContactListWindowHandlingPlugin,
ESFastUserSwitchingSupportPlugin, ESOpenMessageWindowContactAlertPlugin, ESSendMessageContactAlertPlugin,
ESUserIconHandlingPlugin, ErrorMessageHandlerPlugin, GBiTunerPlugin, IdleMessagePlugin, AIContactProfilePlugin,
JSCEventBezelPlugin, LNStatusIconsPlugin, SAContactOnlineForPlugin, ESStatusSortPlugin, AIContactSettingsPlugin,
AIIdleTimePlugin, ESContactServersideDisplayName, AIConnectPanelPlugin, CPFVersionChecker, AIContactStatusEventsPlugin,
SHOutputDeviceControlPlugin, SHLinkManagementPlugin, ESBlockingPlugin, BGEmoticonMenuPlugin, BGContactNotesPlugin, SHBookmarksImporterPlugin;

@implementation AIPluginController
//init
- (void)initController
{
    pluginArray = [[NSMutableArray alloc] init];

#ifdef ADIUM_COMPONENTS
	//Load integrated plugins
	[self loadPluginWithClass:[AIAccountListPreferencesPlugin class]];
	[self loadPluginWithClass:[AIAccountMenuAccessPlugin class]];
	[self loadPluginWithClass:[AIAliasSupportPlugin class]];
	[self loadPluginWithClass:[AIAlphabeticalSortPlugin class]];
	[self loadPluginWithClass:[AIAutoLinkingPlugin class]];
	[self loadPluginWithClass:[AIAwayMessagesPlugin class]];
	[self loadPluginWithClass:[AIAwayStatusWindowPlugin class]];
	[self loadPluginWithClass:[AIContactAwayPlugin class]];
	[self loadPluginWithClass:[AIContactIdlePlugin class]];
	[self loadPluginWithClass:[AIContactProfilePlugin class]];
	[self loadPluginWithClass:[AIContactListEditorPlugin class]];
	[self loadPluginWithClass:[AIContactOnlineSincePlugin class]];
	[self loadPluginWithClass:[AIContactSortSelectionPlugin class]];
	[self loadPluginWithClass:[AIContactStatusColoringPlugin class]];
	[self loadPluginWithClass:[AIContactStatusDockOverlaysPlugin class]];
	[self loadPluginWithClass:[AIContactStatusTabColoringPlugin class]];
	[self loadPluginWithClass:[AIContactSettingsPlugin class]];
	[self loadPluginWithClass:[AIContactWarningLevelPlugin class]];
	[self loadPluginWithClass:[AIDefaultFormattingPlugin class]];
	[self loadPluginWithClass:[AIDockAccountStatusPlugin class]];
	[self loadPluginWithClass:[AIDockBehaviorPlugin class]];
	[self loadPluginWithClass:[AIDockIconSelectionPlugin class]];
	[self loadPluginWithClass:[AIDockUnviewedContentPlugin class]];
	[self loadPluginWithClass:[AIDualWindowInterfacePlugin class]];
	[self loadPluginWithClass:[AIEmoticonsPlugin class]];
	[self loadPluginWithClass:[AIEventSoundsPlugin class]];
	[self loadPluginWithClass:[AIIdleTimeDisplayPlugin class]];
	[self loadPluginWithClass:[AIIdleTimePlugin class]];
	[self loadPluginWithClass:[AILoggerPlugin class]];
	[self loadPluginWithClass:[AIManualSortPlugin class]];
	[self loadPluginWithClass:[AIMessageAliasPlugin class]];
//	[self loadPluginWithClass:[AIMessageViewSelectionPlugin class]];
	[self loadPluginWithClass:[AIOfflineContactHidingPlugin class]];
	[self loadPluginWithClass:[AISCLViewPlugin class]];
	[self loadPluginWithClass:[AISendingKeyPreferencesPlugin class]];
	[self loadPluginWithClass:[AISpellCheckingPlugin class]];
	[self loadPluginWithClass:[AIStandardToolbarItemsPlugin class]];
	[self loadPluginWithClass:[AIStatusChangedMessagesPlugin class]];
	[self loadPluginWithClass:[AITextForcingPlugin class]];
	[self loadPluginWithClass:[AITextToolbarItemsPlugin class]];
	[self loadPluginWithClass:[AITypingNotificationPlugin class]];
	[self loadPluginWithClass:[AIVolumeControlPlugin class]];
	[self loadPluginWithClass:[BGContactNotesPlugin class]];
	[self loadPluginWithClass:[BGEmoticonMenuPlugin class]];
	[self loadPluginWithClass:[BGThemesPlugin class]];
	[self loadPluginWithClass:[CBActionSupportPlugin class]];
	[self loadPluginWithClass:[CBContactCountingDisplayPlugin class]];
    [self loadPluginWithClass:[CBURLHandlingPlugin class]];
    [self loadPluginWithClass:[CPFVersionChecker class]];
	[self loadPluginWithClass:[CSDisconnectAllPlugin class]];
	[self loadPluginWithClass:[DCMessageContextDisplayPlugin class]];
	[self loadPluginWithClass:[ErrorMessageHandlerPlugin class]];
	[self loadPluginWithClass:[ESAddressBookIntegrationPlugin class]];
	[self loadPluginWithClass:[ESAnnouncerPlugin class]];
    [self loadPluginWithClass:[ESBlockingPlugin class]];
	[self loadPluginWithClass:[ESContactAlertsPlugin class]];
	[self loadPluginWithClass:[ESContactClientPlugin class]];
	[self loadPluginWithClass:[ESContactListWindowHandlingPlugin class]];
	[self loadPluginWithClass:[ESFastUserSwitchingSupportPlugin class]];
	[self loadPluginWithClass:[ESOpenMessageWindowContactAlertPlugin class]];
	[self loadPluginWithClass:[ESSendMessageContactAlertPlugin class]];
	[self loadPluginWithClass:[ESContactServersideDisplayName class]];
	[self loadPluginWithClass:[ESStatusSortPlugin class]];
	[self loadPluginWithClass:[ESUserIconHandlingPlugin class]];
	[self loadPluginWithClass:[GBiTunerPlugin class]];
	[self loadPluginWithClass:[IdleMessagePlugin class]];
	[self loadPluginWithClass:[JSCEventBezelPlugin class]];
	[self loadPluginWithClass:[LNStatusIconsPlugin class]];
	[self loadPluginWithClass:[SAContactOnlineForPlugin class]];
	[self loadPluginWithClass:[AIContactStatusEventsPlugin class]];
//	[self loadPluginWithClass:[SHOutputDeviceControlPlugin class]];
        [self loadPluginWithClass:[SHLinkManagementPlugin class]];
        [self loadPluginWithClass:[SHBookmarksImporterPlugin class]];
//	[self loadPluginWithClass:[AISMViewPlugin class]];
//	[self loadPluginWithClass:[AIWebKitMessageViewPlugin class]];
#endif
	
	[self loadPluginsFromPath:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByExpandingTildeInPath] confirmLoading:NO];
	[self loadPluginsFromPath:[[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:DIRECTORY_EXTERNAL_PLUGINS] stringByExpandingTildeInPath] confirmLoading:YES];
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

//
- (void)loadPluginWithClass:(Class)inClass
{
	id	object = [inClass newInstanceOfPlugin];
	
	if (object){
		[pluginArray addObject:object];
	}else{
		NSString *failureNotice = [NSString stringWithFormat:@"Failed to load integrated component %@",NSStringFromClass(inClass)];
		NSAssert(object,failureNotice);
	}
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
					if(NSRunInformationalAlertPanel(@"Custom Plugin Detected",
													[NSString stringWithFormat:@"You have a custom plugin (%@) installed in ~/Library/Application Support/Adium 2.0/Plugins\r\rIf you experience any crashes or odd behavior, please disable or remove this plugin.", pluginName],
													@"Okay", 
													@"Disable",
													nil) == NSAlertAlternateReturn){
						
						//Disable the plugin
						NSString	*disabledPath = [[pluginPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Plugins (Disabled)"];
						NSString	*sourcePath = [pluginPath stringByAppendingPathComponent:pluginName];
						NSString	*destPath = [disabledPath stringByAppendingPathComponent:pluginName];
						
						[[NSFileManager defaultManager] createDirectoriesForPath:disabledPath];
						[[NSFileManager defaultManager] movePath:sourcePath toPath:destPath handler:nil];

					}else{
						//Add this plugin to our confirmed list
						NSMutableArray	*newConfirmed = [[confirmed mutableCopy] autorelease];
						if(!newConfirmed) newConfirmed = [NSMutableArray array];
						[newConfirmed addObject:pluginName];
						[[NSUserDefaults standardUserDefaults] setObject:newConfirmed forKey:CONFIRMED_PLUGINS];	

					}
				}
			}

			
			NS_DURING
				//Load the plugin; if the plugin is hte webkit plugin, verify webkit is available first
				if ((![pluginName isEqualToString:WEBKIT_PLUGIN] || [NSApp isWebKitAvailable])){
					pluginBundle = [NSBundle bundleWithPath:[pluginPath stringByAppendingPathComponent:pluginName]];
					if(pluginBundle != nil){
						
#if 1
						//Create an instance of the plugin
						plugin = [[pluginBundle principalClass] newInstanceOfPlugin];					
#else
						//Plugin load timing
						
						NSString	*compactedName = [pluginName compactedString];
						double		timeInterval;
						NSDate		*startTime = [NSDate date];
						
						plugin = [[pluginBundle principalClass] newInstanceOfPlugin];
						
						timeInterval = [[NSDate date] timeIntervalSinceDate:startTime];
						NSLog(@"%@ %f",compactedName, timeInterval);
#endif
						
						if(plugin != nil){
							//Add the instance to our list
							[pluginArray addObject:plugin];
						}else{
							NSLog(@"Failed to initialize Plugin \"%@\"!",pluginName);
						}
					}else{
						NSLog(@"Failed to open Plugin \"%@\"!",pluginName);
					}
				} else {
					NSLog(AILocalizedString(@"The WebKit Message View plugin failed to load because WebKit is not available.  Please install Safari to enable the WebKit plugin.",nil));
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
				NSString	*errorPartTwo = AILocalizedString(@"plugin failed to load properly.  It may be partially loaded.  If strange behavior ensues, remove it from Adium 2's plugin directory","part of the plugin error message");
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

@end
