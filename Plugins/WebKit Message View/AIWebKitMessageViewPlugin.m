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

@interface AIWebKitMessageViewPlugin (PRIVATE)
- (void)_scanAvailableWebkitStyles;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_loadPreferencesForWebView:(ESWebView *)webView withStyleNamed:(NSString *)styleName;
@end

@implementation AIWebKitMessageViewPlugin

- (void)installPlugin
{	
	//This plugin will ONLY work in 10.3 or newer
	if([NSApp isOnPantherOrBetter]){
		styleDictionary = nil;
		[self _scanAvailableWebkitStyles];
		
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
		
		//Register our observers
//		[[adium contactController] registerListObjectObserver:self];
	}

	[adium createResourcePathForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT];
}

//Return a message view controller
- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return([AIWebKitMessageViewController messageViewControllerForChat:inChat withPlugin:self]);
}

//Available Webkit Styles ----------------------------------------------------------------------------------------------
#pragma mark Available Webkit Styles
//Scan for available webkit styles (Call before trying to load/access a style)
- (void)_scanAvailableWebkitStyles
{	
	NSEnumerator	*enumerator, *fileEnumerator;
	NSString		*filePath, *resourcePath;
	NSArray			*resourcePaths;
	
	//Clear the current dictionary of styles and ready a new mutable dictionary
	[styleDictionary release];
	styleDictionary = [[NSMutableDictionary alloc] init];
	
	//Get all resource paths to search
	resourcePaths = [adium resourcePathsForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT];
	enumerator = [resourcePaths objectEnumerator];
	
	NSString	*AdiumMessageStyle = @"AdiumMessageStyle";
    while(resourcePath = [enumerator nextObject]) {
        fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:resourcePath] objectEnumerator];
        
        //Find all the message styles
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:AdiumMessageStyle] == 0){
                NSBundle		*style;

				//Load the style and add it to our dictionary
				style = [NSBundle bundleWithPath:[resourcePath stringByAppendingPathComponent:filePath]];
				if(style){
					NSString	*styleName = [style name];
					if(styleName && [styleName length]) [styleDictionary setObject:style forKey:styleName];
				}
            }
        }
    }
}

//Returns a dictionary of available style identifiers and their paths
//- (NSDictionary *)availableStyles
- (NSDictionary *)availableStyleDictionary
{
	return(styleDictionary);
}

//Fetch the bundle for a message style by its bundle identifier
//- (NSBundle *)messageStyleBundleWithIdentifier:(NSString *)name
//{
//	return([NSBundle bundleWithPath:[styleDictionary objectForKey:name]]);
//}
- (NSBundle *)messageStyleBundleWithName:(NSString *)name
{
	return([styleDictionary objectForKey:name]);
}

//The default message style bundle
//- (NSBundle *)defaultMessageStyleBundle
//{
//	return([self messageStyleBundleWithIdentifier:MESSAGE_DEFAULT_STYLE]);
//}

//If the styles have changed, rebuild our list of available styles
- (void)xtrasChanged:(NSNotification *)notification
{
	if ([[notification object] caseInsensitiveCompare:@"AdiumMessageStyle"] == 0){		
		[self _scanAvailableWebkitStyles];
		[preferences messageStyleXtrasDidChange];
	}
}

#pragma mark Available Webkit Styles

- (NSString *)variantKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Variant",desiredStyle];
}
- (NSString *)cachedBackgroundKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:CachedBackground",desiredStyle];
}
- (NSString *)backgroundKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Background",desiredStyle];	
}
- (NSString *)backgroundColorKeyForStyle:(NSString *)desiredStyle
{
	return [NSString stringWithFormat:@"%@:Background Color",desiredStyle];
}

- (BOOL)boolForKey:(NSString *)key style:(NSBundle *)style variant:(NSString *)variant boolDefault:(BOOL)defaultValue
{
	NSNumber	*value = (NSNumber *)[self valueForKey:key style:style variant:variant];
	return (value ? [value boolValue] : defaultValue);
}

- (id)valueForKey:(NSString *)key style:(NSBundle *)style variant:(NSString *)variant
{
	id  value = [style objectForInfoDictionaryKey:[NSString stringWithFormat:@"%@:%@",key,variant]];
	if (!value){
		value = [style objectForInfoDictionaryKey:key];
	}
	return value;
}
@end
