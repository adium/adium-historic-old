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

#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AIPluginController.h"

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/Plugins"	//Path to the internal plugins
#define EXTENSION_ADIUM_PLUGIN			@"AdiumPlugin"		//File extension of a plugin

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
    int		loop;

    NSParameterAssert(owner != nil);
    NSParameterAssert(pluginArray != nil);
    
    //Get the plugin path
    pluginPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByExpandingTildeInPath];

    //Get the directory listing of plugins
    pluginList = [[NSFileManager defaultManager] directoryContentsAtPath:pluginPath];

    for(loop = 0;loop < [pluginList count];loop++){
        NSString 		*pluginName;
        NSBundle		*pluginBundle;
        AIPlugin		*plugin;

        pluginName = [pluginList objectAtIndex:loop];
        if([[pluginName pathExtension] compare:EXTENSION_ADIUM_PLUGIN] == 0){
            //Load the plugin
            pluginBundle = [NSBundle bundleWithPath:[pluginPath stringByAppendingPathComponent:pluginName]];
            if(pluginBundle != nil){
                //Create an instance of the plugin
                plugin = [[pluginBundle principalClass] newInstanceOfPluginWithOwner:owner];
    
                if(plugin != nil){
                    //Add the instance to our list
                    [pluginArray addObject:plugin];
                }else{
                    NSLog(@"Failed to initialize Plugin \"%@\"!",pluginName);
                }
            }else{
                NSLog(@"Failed to open Plugin \"%@\"!",pluginName);
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
