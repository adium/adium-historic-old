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
	if ((self = [super initWithWindowNibName:windowNibName])) {
		adium = [AIObject sharedAdiumInstance];
	}
	
    return self;
}

/*!
 * @brief Configure the window after it loads
 *
 * Here we restore the window's saved position and size before it's displayed on screen.
 */
- (void)windowDidLoad
{
	NSString	*key = [self adiumFrameAutosaveName];

	if (key) {
		NSString	*frameString;
		int			numberOfScreens;

		//Unique key for each number of screens
		numberOfScreens = [[NSScreen screens] count];
		
		frameString = [[adium preferenceController] preferenceForKey:((numberOfScreens == 1) ? 
																	  key :
																	  [NSString stringWithFormat:@"%@-%i",key,numberOfScreens])
															   group:PREF_GROUP_WINDOW_POSITIONS];

		if (!frameString && (numberOfScreens > 1)) {
			//Fall back on the single screen preference if necessary (this is effectively a preference upgrade).
			frameString = [[adium preferenceController] preferenceForKey:key
																   group:PREF_GROUP_WINDOW_POSITIONS];
		}

		if (frameString) {
			NSRect		windowFrame = NSRectFromString(frameString);
			NSSize		minSize = [[self window] minSize];
			NSSize		maxSize = [[self window] maxSize];
			
			//Respect the min and max sizes
			if (windowFrame.size.width < minSize.width) windowFrame.size.width = minSize.width;
			if (windowFrame.size.height < minSize.height) windowFrame.size.height = minSize.height;
			if (windowFrame.size.width > maxSize.width) windowFrame.size.width = maxSize.width;
			if (windowFrame.size.height > maxSize.height) windowFrame.size.height = maxSize.height;

			//Don't allow the window to shrink smaller than its toolbar
			NSRect 		contentFrame = [NSWindow contentRectForFrameRect:windowFrame
															   styleMask:[[self window] styleMask]];
			if (contentFrame.size.height < [[self window] toolbarHeight]) {
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
    if ([self windowShouldClose:nil]) {
		if ([[self window] isSheet]) {
			[NSApp endSheet:[self window]];
		} else {
			[[self window] close];
		}
	}
}

/*!
 * @brief Called before the window closes. This will not be called when the application quits.
 *
 * This is called before the window closes.  By default we always allow closing of our window, so YES is always
 * returned from this method.
 */
- (BOOL)windowShouldClose:(id)sender
{
	return YES;
}

/*!
 * @brief Called immediately before the window closes.
 * 
 * We take the opportunity to save the current window position and size here.
 * When subclassing be sure to call super in this method, or window frames will not save.
 */
- (void)windowWillClose:(id)sender
{
	NSString	*key = [self adiumFrameAutosaveName];

 	if (key) {
		//Unique key for each number of screens
		int	numberOfScreens = [[NSScreen screens] count];

		[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
											 forKey:((numberOfScreens == 1) ? 
													 key :
													 [NSString stringWithFormat:@"%@-%i",key,numberOfScreens])
											  group:PREF_GROUP_WINDOW_POSITIONS];
		
	}
}

/*!
 * Prevent the system from cascading our windows, since it interferes with window position memory
 */
- (BOOL)shouldCascadeWindows
{
    return NO;
}

/*!
 * @brief Auto-saving window frame key
 *
 * This is the string used for saving this window's frame.  It should be unique to this window.
 */
- (NSString *)adiumFrameAutosaveName
{
	return nil;
}
	
@end
