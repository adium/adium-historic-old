/* 
Adium, Copyright 2001-2004, Adam Iser
 
 This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 General Public License as published by the Free Software Foundation; either version 2 of the License,
 or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 Public License for more details.
 
 You should have received a copy of the GNU General Public License along with this program; if not,
 write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

/*
 Core - Plugin Loader
 
 Loads external plugins (Including plugins stored within our application bundle).  Also responsible for warning the
 user of old or incompatable plugins.

 */

#import "AICorePluginLoader.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/PlugIns"	//Path to the internal plugins
#define EXTERNAL_PLUGIN_FOLDER			@"PlugIns"				//Folder name of external plugins
#define EXTENSION_ADIUM_PLUGIN			@"AdiumPlugin"			//File extension of a plugin

#define WEBKIT_PLUGIN					@"Webkit Message View.AdiumPlugin"
#define SMV_PLUGIN						@"Standard Message View.AdiumPlugin"
#define CONFIRMED_PLUGINS				@"Confirmed Plugins"

@interface AICorePluginLoader (PRIVATE)
- (void)loadPluginsFromPath:(NSString *)pluginPath confirmLoading:(BOOL)confirmLoading;
@end

@implementation AIPluginController

//init
- (void)initController
{
    pluginArray = [[NSMutableArray alloc] init];

	[[owner notificationCenter] addObserver:self 
								   selector:@selector(adiumVersionWillBeUpgraded:) 
									   name:Adium_VersionWillBeUpgraded
									 object:nil];
	[owner createResourcePathForName:EXTERNAL_PLUGIN_FOLDER];
}

//
- (void)finishIniting
{
	NSEnumerator	*enumerator = [[owner resourcePathsForName:EXTERNAL_PLUGIN_FOLDER] objectEnumerator];
	NSString		*path;
	
	//Load the plugins in our bundle
	[self loadPluginsFromPath:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByExpandingTildeInPath]
			   confirmLoading:NO];

	//Load any external plugins the user has installed
	while(path = [enumerator nextObject]){
		[self loadPluginsFromPath:path confirmLoading:YES];
	}
}

//Give all external plugins a chance to close
- (void)closeController
{
    NSEnumerator	*enumerator = [pluginArray objectEnumerator];
    AIPlugin		*plugin;
	
    while((plugin = [enumerator nextObject])){
        [plugin uninstallPlugin];
    }
	
    [pluginArray release];
	pluginArray = nil;
}

//Load all the plugins
- (void)loadPluginsFromPath:(NSString *)pluginPath confirmLoading:(BOOL)confirmLoading
{
    NSArray		*pluginList = [[NSFileManager defaultManager] directoryContentsAtPath:pluginPath];
    int			loop;

	for(loop = 0;loop < [pluginList count];loop++){
	    NSString 		*pluginName;
	    NSBundle		*pluginBundle;
	    AIPlugin		*plugin = nil;

	    pluginName = [pluginList objectAtIndex:loop];

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


// Returns YES if the named plugin exists. Does not imply that the plugin actually loaded or is functioning.
- (BOOL)pluginEnabled:(NSString *)pluginName
{
//	BOOL inBundle = NO;
//	BOOL inExternal = NO;
//	
//	inBundle = [[NSFileManager defaultManager] fileExistsAtPath:[[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByAppendingPathComponent:pluginName] stringByExpandingTildeInPath]];
//	if(!inBundle)
//		inExternal = [[NSFileManager defaultManager] fileExistsAtPath:[[[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:DIRECTORY_EXTERNAL_PLUGINS] stringByAppendingPathComponent:pluginName] stringByExpandingTildeInPath]];
//	
//	AILog(@"#### %@ enabled: in %d, out %d",pluginName,inBundle,inExternal);
	return(YES/*inBundle || inExternal*/);	
}

//When the user upgrades to a new version, re-request confirmation of external plugins.
- (void)adiumVersionWillBeUpgraded:(NSNotification *)notification
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIRMED_PLUGINS];
}

@end
