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
#import "AIPreferenceController.h"
#import "AIWebKitMessageViewController.h"
#import "AIWebKitMessageViewPlugin.h"
#import "ESWebKitMessageViewPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIBundleAdditions.h>

#define NEW_CONTENT_RETRY_DELAY					0.01
#define MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT @"Message Styles"

@interface AIWebKitMessageViewPlugin (PRIVATE)
- (void)_scanAvailableWebkitStyles;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_loadPreferencesForWebView:(ESWebView *)webView withStyleNamed:(NSString *)styleName;
- (void) preloadMessageStyles;
@end

@implementation AIWebKitMessageViewPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
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
	
	[NSThread detachNewThreadSelector:@selector(preloadMessageStyles)
							 toTarget:self
						   withObject:nil];
}

- (id <AIMessageViewController>)messageViewControllerForChat:(AIChat *)inChat
{
    return [AIWebKitMessageViewController messageViewControllerForChat:inChat withPlugin:self];
}

/*!
 * @brief Runs on a background thread at launch to load message styles
 */
- (void) preloadMessageStyles
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc]init];
	[self availableMessageStyles];
	[pool release];
}

- (NSDictionary *)availableMessageStyles
{
	@synchronized(self) {
		if (!styleDictionary) {
			NSArray			*stylesArray = [adium allResourcesForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT 
													   withExtensions:@"AdiumMessageStyle"];
			NSEnumerator	*stylesEnumerator;
			NSBundle		*style;
			NSString		*resourcePath;
			
			//Clear the current dictionary of styles and ready a new mutable dictionary
			styleDictionary = [[NSMutableDictionary alloc] init];
			
			//Get all resource paths to search
			stylesEnumerator = [stylesArray objectEnumerator];
			while ((resourcePath = [stylesEnumerator nextObject])) {
				if ((style = [NSBundle bundleWithPath:resourcePath])) {
					NSString	*styleIdentifier = [style bundleIdentifier];
					if (styleIdentifier && [styleIdentifier length]) {
						[styleDictionary setObject:style forKey:styleIdentifier];
					}
				}
			}
			
			NSAssert([styleDictionary count] > 0, @"No message styles available"); //Abort if we have no message styles
		}
		
		return [NSDictionary dictionaryWithDictionary:styleDictionary]; //returning mutable private variables == nuh uh
	}
	return nil; //keep the compiler happy
}

- (NSBundle *)messageStyleBundleWithIdentifier:(NSString *)identifier
{	
	NSDictionary	*styles = [self availableMessageStyles];
	NSBundle		*bundle = [styles objectForKey:identifier];
	
	//If the style isn't available, use our default.  Or, failing that, any available style
	if (!bundle) {
		bundle = [styles objectForKey:WEBKIT_DEFAULT_STYLE];
		if (!bundle)
			bundle = [[styles allValues] lastObject];
	} 

	return bundle;
}

/*!
 * @brief Rebuild our list of available styles when the installed xtras change
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	if ([[notification object] caseInsensitiveCompare:@"AdiumMessageStyle"] == 0) {	
		@synchronized(self) {
			[styleDictionary release]; styleDictionary = nil;
		}
		[preferences messageStyleXtrasDidChange];
	}
}

- (NSString *)styleSpecificKey:(NSString *)key forStyle:(NSString *)style
{
	return [NSString stringWithFormat:@"%@:%@", style, key];
}

@end
