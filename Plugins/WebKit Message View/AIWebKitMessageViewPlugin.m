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

#import "AIInterfaceController.h"
#import "AIWebKitMessageViewController.h"
#import "AIWebKitMessageViewPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/CBApplicationAdditions.h>
#import <AIUtilities/ESBundleAdditions.h>

#define WEBKIT_DEFAULT_STYLE	@"Mockie"		//Style used if we cannot find the preferred style

@interface AIWebKitMessageViewPlugin (PRIVATE)
- (void)_scanAvailableWebkitStyles;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_loadPreferencesForWebView:(ESWebView *)webView withStyleNamed:(NSString *)styleName;
@end

@implementation AIWebKitMessageViewPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{	
	//This plugin will ONLY work in 10.3 or newer
	if([NSApp isOnPantherOrBetter]){
		styleDictionary = nil;
		[adium createResourcePathForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT];
		
		//Setup our preferences
		[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]]
											  forGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
		preferences = [[ESWebKitMessageViewPreferences preferencePaneForPlugin:self] retain];
		
		//Observe for installation of new styles
		[[adium notificationCenter] addObserver:self
									   selector:@selector(xtrasChanged:)
										   name:Adium_Xtras_Changed
										 object:nil];
		
		//Register ourself as a message view plugin
		[[adium interfaceController] registerMessageViewPlugin:self];
	}
}

/*!
 * @brief Returns a new webkit message view controller
 */
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AIWebKitMessageViewController messageViewControllerForChat:inChat withPlugin:self]);
}

/*!
 * @brief Returns a dictionary of the available message styles
 */
- (NSDictionary *)availableMessageStyles
{
	if(!styleDictionary){
		NSString		*AdiumMessageStyle = @"AdiumMessageStyle";
		NSEnumerator	*enumerator, *fileEnumerator;
		NSString		*filePath, *resourcePath;
		NSBundle		*style;
		
		//Clear the current dictionary of styles and ready a new mutable dictionary
		styleDictionary = [[NSMutableDictionary alloc] init];
		
		//Get all resource paths to search
		enumerator = [[adium resourcePathsForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT] objectEnumerator];
		while(resourcePath = [enumerator nextObject]) {
			fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:resourcePath] objectEnumerator];
			
			//Find all the message styles
			while((filePath = [fileEnumerator nextObject])){
				if([[filePath pathExtension] caseInsensitiveCompare:AdiumMessageStyle] == 0){
					if(style = [NSBundle bundleWithPath:[resourcePath stringByAppendingPathComponent:filePath]]){
						NSString	*styleName = [style name];
						if(styleName && [styleName length]) [styleDictionary setObject:style forKey:styleName];
					}
				}
			}
		}

		NSParameterAssert([styleDictionary count]); //Abort if we have no message styles
	}
	
	return(styleDictionary);
}

/*!
 * @brief Returns a message style bundle's bundle
 * @param name Name of the message style
 */
- (NSBundle *)messageStyleBundleWithName:(NSString *)name
{	
	NSDictionary	*styles = [self availableMessageStyles];
	NSBundle		*bundle = [styles objectForKey:name];
	
	//If the style isn't available, use our default.  Or, failing that, any available style
	if(!bundle) bundle = [styles objectForKey:WEBKIT_DEFAULT_STYLE];
	if(!bundle){
		bundle = [[styles allValues] lastObject];
	}

	return(bundle);
}

/*!
 * @brief Rebuild our list of available styles when the installed xtras change
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	if([[notification object] caseInsensitiveCompare:@"AdiumMessageStyle"] == 0){		
		[styleDictionary release]; styleDictionary = nil;
		[preferences messageStyleXtrasDidChange];
	}
}

/*!
 * @brief Returns a preference key which is style specific
 * @param key The preference key
 * @param style The style name it will be specific to
 */
- (NSString *)styleSpecificKey:(NSString *)key forStyle:(NSString *)style
{
	return([NSString stringWithFormat:@"%@:%@", style, key]);
}

@end
