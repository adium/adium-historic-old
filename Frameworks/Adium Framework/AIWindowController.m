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

#import "AIPreferenceController.h"
#import "AIWindowController.h"
#import <AIUtilities/AIWindowAdditions.h>

/*!
 * @class AIWindowController
 * @brief Base class for window controllers
 *
 * This base class provides some essentials for window controllers to cut down on duplicate code.  It currently
 * handles window frame saving and restoration, establishes a local 'adium' references, and provides methods
 * which every good window controller cannot be without.
 */
@implementation AIWindowController

/*!
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    adium = [AIObject sharedAdiumInstance];
    return([super initWithWindowNibName:windowNibName]);
}

/*!
 * @brief Configure the window after it loads
 *
 * Here we restore the window's saved position and size before it's displayed on screen.
 */
- (void)windowDidLoad
{
	NSString	*key = [self adiumFrameAutosaveName];

	if(key){
		NSString	*frameString = [[adium preferenceController] preferenceForKey:key
																			group:PREF_GROUP_WINDOW_POSITIONS];
		
		if(frameString){
			NSRect		windowFrame = NSRectFromString(frameString);
			NSSize		minSize = [[self window] minSize];
			NSSize		maxSize = [[self window] maxSize];
			
			//Respect the min and max sizes
			if(windowFrame.size.width < minSize.width) windowFrame.size.width = minSize.width;
			if(windowFrame.size.height < minSize.height) windowFrame.size.height = minSize.height;
			if(windowFrame.size.width > maxSize.width) windowFrame.size.width = maxSize.width;
			if(windowFrame.size.height > maxSize.height) windowFrame.size.height = maxSize.height;

			//Don't allow the window to shrink smaller than its toolbar
			NSRect 		contentFrame = [NSWindow contentRectForFrameRect:windowFrame
															   styleMask:[[self window] styleMask]];
			if(contentFrame.size.height < [[self window] toolbarHeight]){
				windowFrame.size.height += [[self window] toolbarHeight] - contentFrame.size.height;
			}

			//
			[[self window] setFrame:windowFrame display:NO];
		}
	}
}

/*!
 * @brief Close the window
 */
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
		if([[self window] isSheet]){
			[NSApp endSheet:[self window]];
		}else{
			[[self window] close];
		}
	}
}

/*!
 * @brief Called before the window closes
 *
 * This is called before the window closes.  By default we always allow closing of our window, so YES is always
 * returned from this method.  Also we take the opportunity to save the current window position and size here.
 * When subclassing be sure to call super in this method, or window frames will not save.
 */
- (BOOL)windowShouldClose:(id)sender
{
	NSString	*key = [self adiumFrameAutosaveName];

 	if(key){
		[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
											 forKey:key
											  group:PREF_GROUP_WINDOW_POSITIONS];
	}
	
	return(YES);
}

/*!
 * @brief Auto-saving window frame key
 *
 * This is the string used for saving this window's frame.  It should be unique to this window.
 */
- (NSString *)adiumFrameAutosaveName
{
	return(nil);
}
	
@end
