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

//$Id: AIPluginController.m,v 1.17 2004/02/07 22:33:18 evands Exp $
#import "AIPluginController.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/Plugins"	//Path to the internal plugins
#define DIRECTORY_EXTERNAL_PLUGINS		@"/Plugins"				//Path to the external plugins
#define EXTENSION_ADIUM_PLUGIN			@"AdiumPlugin"			//File extension of a plugin

@interface AIPluginController (PRIVATE)
- (void)loadPlugins;
- (void)unloadPlugins;
@end

@implementation AIPluginController
//init
- (void)initController
{
    pluginArray = [[NSMutableArray alloc] init];

    [self loadPlugins];
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
- (void)loadPlugins
{
    NSArray	*pluginList;
    NSString	*pluginPath;
    int		loop, counter;

    NSParameterAssert(owner != nil);
    NSParameterAssert(pluginArray != nil);

    for(counter=0 ; counter < 2 ; counter++)
    {
	//Get the plugin path
	if (counter == 0) { //bundle
	    pluginPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByExpandingTildeInPath];
	}else {  //user's folder, creating if necessary
	    pluginPath = [[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:DIRECTORY_EXTERNAL_PLUGINS] stringByExpandingTildeInPath];
	    [AIFileUtilities createDirectory:pluginPath];
	}
	
	//Get the directory listing of plugins
	pluginList = [[NSFileManager defaultManager] directoryContentsAtPath:pluginPath];

	for(loop = 0;loop < [pluginList count];loop++){
	    NSString 		*pluginName;
	    NSBundle		*pluginBundle;
	    AIPlugin		*plugin = nil;

	    pluginName = [pluginList objectAtIndex:loop];
	    //NSLog (@"Loading plugin: \"%@\"", pluginName);
	    if([[pluginName pathExtension] caseInsensitiveCompare:EXTENSION_ADIUM_PLUGIN] == 0){
			NS_DURING
				//Load the plugin
				pluginBundle = [NSBundle bundleWithPath:[pluginPath stringByAppendingPathComponent:pluginName]];
				if(pluginBundle != nil){
					//Create an instance of the plugin
					plugin = [[pluginBundle principalClass] newInstanceOfPlugin];
					
					if(plugin != nil){
						//Add the instance to our list
						[pluginArray addObject:plugin];
					}else{
						NSLog(@"Failed to initialize Plugin \"%@\"!",pluginName);
					}
				}else{
					NSLog(@"Failed to open Plugin \"%@\"!",pluginName);
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
				[[owner interfaceController] handleErrorMessage:@"Plugin load error" withDescription:[NSString stringWithFormat:@"The \"%@\" plugin failed to load properly.  It may be partially loaded.  If strange behavior ensues, remove it from Adium 2's plugin directory (\"%@\"), then quit and relaunch Adium.", [pluginName stringByDeletingPathExtension], pluginPath]];
				// It would probably be unsafe to call the plugin's uninstall
			NS_ENDHANDLER
	    }
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
