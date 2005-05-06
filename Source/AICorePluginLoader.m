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

/*
 Core - Plugin Loader
 
 Loads external plugins (Including plugins stored within our application bundle).  Also responsible for warning the
 user of old or incompatible plugins.

 */

#import "AICorePluginLoader.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>
#import <Adium/AIPlugin.h>

#define DIRECTORY_INTERNAL_PLUGINS		@"/Contents/PlugIns"	//Path to the internal plugins
#define EXTERNAL_PLUGIN_FOLDER			@"PlugIns"				//Folder name of external plugins
#define EXTERNAL_DISABLED_PLUGIN_FOLDER	@"PlugIns (Disabled)"	//Folder name for disabled external plugins
#define EXTENSION_ADIUM_PLUGIN			@"AdiumPlugin"			//File extension of a plugin

#define WEBKIT_PLUGIN					@"Webkit Message View.AdiumPlugin"
#define SMV_PLUGIN						@"Standard Message View.AdiumPlugin"
#define CONFIRMED_PLUGINS				@"Confirmed Plugins"
#define CONFIRMED_PLUGINS_VERSION		@"Confirmed Plugin Version"

@interface AICorePluginLoader (PRIVATE)
- (void)loadPluginAtPath:(NSString *)pluginName confirmLoading:(BOOL)confirmLoading;
- (BOOL)confirmPluginAtPath:(NSString *)pluginPath;
- (void)disablePlugin:(NSString *)pluginPath;
@end

@implementation AICorePluginLoader

- (id)init
{
	if((self = [super init])){
		pluginArray = [[NSMutableArray alloc] init];
	}

	return self;
}

//init
- (void)initController
{
	//Init
	[adium createResourcePathForName:EXTERNAL_PLUGIN_FOLDER];

	//If the Adium version has changed since our last run, warn the user that their external plugins may no longer work
	NSString	*lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:CONFIRMED_PLUGINS_VERSION];
	if(![[NSApp applicationVersion] isEqualToString:lastVersion]){
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIRMED_PLUGINS];
		[[NSUserDefaults standardUserDefaults] setObject:[NSApp applicationVersion] forKey:CONFIRMED_PLUGINS_VERSION];
	}
	
	
	NSEnumerator	*enumerator = [[adium allResourcesForName:EXTERNAL_PLUGIN_FOLDER withExtensions:EXTENSION_ADIUM_PLUGIN] objectEnumerator];
	NSString		*path;
	
	//Load any external plugins the user has installed
	while((path = [enumerator nextObject])){
		[self loadPluginAtPath:path confirmLoading:YES];
	}
	
	NSString *internalPluginsPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByExpandingTildeInPath];
	//Load the plugins in our bundle
	enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:internalPluginsPath] objectEnumerator];
	while ((path = [enumerator nextObject])) {
		if([[path pathExtension] caseInsensitiveCompare:EXTENSION_ADIUM_PLUGIN] == 0)
			[self loadPluginAtPath:[internalPluginsPath stringByAppendingPathComponent:path] confirmLoading:NO];
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
}

- (void)dealloc
{
	[pluginArray release];
	pluginArray = nil;

	[super dealloc];
}

//Load plugins from the specified path
- (void)loadPluginAtPath:(NSString *)pluginPath confirmLoading:(BOOL)confirmLoading
{
	BOOL			loadPlugin = YES;

	//Confirm the presence of external plugins with the user
	if(confirmLoading){
		loadPlugin = [self confirmPluginAtPath:pluginPath];
	}

	//Special case for webkit.  Trying to load the webkit plugin on a 10.2 system will get us into trouble
	//with linking (because webkit may not be present).  This special case code recognizes the webkit plugin
	//and skips it if webkit is not available.
	if([[pluginPath lastPathComponent] isEqualToString:WEBKIT_PLUGIN] && ![NSApp isWebKitAvailable]){
		loadPlugin = NO;
	}
		
	//Load the plugin
	if(loadPlugin){
		NSBundle		*pluginBundle;
		AIPlugin		*plugin = nil;

		NS_DURING
		if(pluginBundle = [NSBundle bundleWithPath:pluginPath]){						
			Class principalClass = [pluginBundle principalClass];
			if(principalClass){
				plugin = [[principalClass alloc] init];
			}else{
				NSLog(@"Failed to obtain principal class from plugin \"%@\" (\"%@\")!",[pluginPath lastPathComponent],pluginPath);
			}
			
			if(plugin){
				[pluginArray addObject:plugin];
				[plugin release];
			}else{
				NSLog(@"Failed to initialize Plugin \"%@\" (\"%@\")!",[pluginPath lastPathComponent],pluginPath);
			}
		}else{
			NSLog(@"Failed to open Plugin \"%@\"!",[pluginPath lastPathComponent]);
		}
		
		NS_HANDLER	
		if(confirmLoading){
			//The plugin encountered an exception while it was loading.  There is no reason to leave this old
			//or poorly coded plugin enabled so that it can cause more problems, so disable it and inform
			//the user that they'll need to restart.
			[self disablePlugin:pluginPath];
			NSRunCriticalAlertPanel([NSString stringWithFormat:@"Error loading %@",[[pluginPath lastPathComponent] stringByDeletingPathExtension]],
									@"An external plugin failed to load and has been disabled.  Please relaunch Adium",
									@"Quit",
									nil,
									nil);
			[NSApp terminate:nil];					
		}
		NS_ENDHANDLER
	}
}

//Confirm the presence of an external plugin with the user.  Returns YES if the plugin should be loaded.
- (BOOL)confirmPluginAtPath:(NSString *)pluginPath
{
	BOOL	loadPlugin = YES;
	NSArray	*confirmed = [[NSUserDefaults standardUserDefaults] objectForKey:CONFIRMED_PLUGINS];

	if(!confirmed || ![confirmed containsObject:[pluginPath lastPathComponent]]){
		if(NSRunInformationalAlertPanel([NSString stringWithFormat:@"Disable %@?",[[pluginPath lastPathComponent] stringByDeletingPathExtension]],
										@"External plugins may cause crashes and odd behavior after updating Adium.  Disable this plugin if you experience any issues.",
										@"Disable", 
										@"Continue",
										nil) == NSAlertDefaultReturn){
			//Disable this plugin
			[self disablePlugin:pluginPath];
			loadPlugin = NO;
			
		}else{
			//Add this plugin to our confirmed list
			confirmed = (confirmed ? [confirmed arrayByAddingObject:[pluginPath lastPathComponent]] : [NSArray arrayWithObject:[pluginPath lastPathComponent]]);
			[[NSUserDefaults standardUserDefaults] setObject:confirmed forKey:CONFIRMED_PLUGINS];
		}
	}
	
	return(loadPlugin);
}

//Move a plugin to the disabled plugins folder
- (void)disablePlugin:(NSString *)pluginPath
{
	NSString	*pluginName = [pluginPath lastPathComponent];
	NSString	*basePath = [pluginPath stringByDeletingLastPathComponent];
	NSString	*disabledPath = [[basePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:EXTERNAL_DISABLED_PLUGIN_FOLDER];
	
	[[NSFileManager defaultManager] createDirectoriesForPath:disabledPath];
	[[NSFileManager defaultManager] movePath:[basePath stringByAppendingPathComponent:pluginName]
									  toPath:[disabledPath stringByAppendingPathComponent:pluginName]
									 handler:nil];
}

@end
