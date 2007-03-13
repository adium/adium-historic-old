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

#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIWindowController.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIWindowControllerAdditions.h>

@interface AIWindowController (PRIVATE)
+ (void)updateScreenBoundariesRect:(id)sender;
@end

/*!
 * @class AIWindowController
 * @brief Base class for window controllers
 *
 * This base class provides some essentials for window controllers to cut down on duplicate code.  It currently
 * handles window frame saving and restoration, establishes a local 'adium' references, and provides methods
 * which every good window controller cannot be without.
 */
@implementation AIWindowController

+ (void)initialize
{
	if ([self isEqual:[AIWindowController class]]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateScreenBoundariesRect:) 
													 name:NSApplicationDidChangeScreenParametersNotification 
												   object:nil];
		
		[self updateScreenBoundariesRect:nil];
	}
}

static NSRect screenBoundariesRect = { {0.0f, 0.0f}, {0.0f, 0.0f} };
+ (void)updateScreenBoundariesRect:(id)sender
{
	NSArray *screens = [NSScreen screens];
	int numScreens = [screens count];
	
	if (numScreens > 0) {
		//The menubar screen is a special case - the menubar is not a part of the rect we're interested in
		NSScreen *menubarScreen = [screens objectAtIndex:0];
		screenBoundariesRect = [menubarScreen frame];
		screenBoundariesRect.size.height = NSMaxY([menubarScreen visibleFrame]) - NSMinY([menubarScreen frame]);
		for (int i = 1; i < numScreens; i++) {
			screenBoundariesRect = NSUnionRect(screenBoundariesRect, [[screens objectAtIndex:i] frame]);
		}
	}
}

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
 * @brief Create a frame from a saved string, taking into account the window's properties
 *
 * Maximum and minimum sizes are respected, the toolbar is taken into account, and the result has all integer values.
 *
 * @result The rect. If frameString would create an invalid rect (width <= 0 or height <= 0), NSZeroRect is returned.
 */
- (NSRect)savedFrameFromString:(NSString *)frameString
{
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
	
	//Make sure the window is visible on-screen
	if (NSMaxX(windowFrame) < NSMinX(screenBoundariesRect)) windowFrame.origin.x = NSMinX(screenBoundariesRect);
	if (NSMinX(windowFrame) > NSMaxX(screenBoundariesRect)) windowFrame.origin.x = NSMaxX(screenBoundariesRect) - NSWidth(windowFrame);
	if (NSMaxY(windowFrame) < NSMinY(screenBoundariesRect)) windowFrame.origin.y = NSMinY(screenBoundariesRect);
	if (NSMinY(windowFrame) > NSMaxY(screenBoundariesRect)) windowFrame.origin.y = NSMaxY(screenBoundariesRect) - NSHeight(windowFrame);
	
	
	return NSIntegralRect(windowFrame);
}

/*!
 * @brief Create a key which is specific for our current screen configuration
 *
 * The resulting key includes the starting key plus the size/orientation layout of all screens.
 * This allows saving a separate, unique saved frame for each new combination of monitor resolutions and relative positions.
 */
- (NSString *)multiscreenKeyWithAutosaveName:(NSString *)key
{
	NSEnumerator	*enumerator = [[NSScreen screens] objectEnumerator];
	NSMutableString	*multiscreenKey = [key mutableCopy];
	NSScreen		*screen;
	
	while ((screen = [enumerator nextObject])) {
		[multiscreenKey appendFormat:@"-%@", NSStringFromRect([screen frame])];
	}
	
	return [multiscreenKey autorelease];
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

		//Unique key for each number of screens
		if ([[NSScreen screens] count] > 1) {
			frameString = [[adium preferenceController] preferenceForKey:[self multiscreenKeyWithAutosaveName:key]
																   group:PREF_GROUP_WINDOW_POSITIONS];

			if (!frameString) {
				//Fall back on the old number-of-screens key
				frameString = [[adium preferenceController] preferenceForKey:[NSString stringWithFormat:@"%@-%i",key,[[NSScreen screens] count]]
																	   group:PREF_GROUP_WINDOW_POSITIONS];
				if (!frameString) {
					//Fall back on the single screen preference if necessary (this is effectively a preference upgrade).
					frameString = [[adium preferenceController] preferenceForKey:key
																		   group:PREF_GROUP_WINDOW_POSITIONS];
				}
			}
			
		} else {
			frameString = [[adium preferenceController] preferenceForKey:key
																   group:PREF_GROUP_WINDOW_POSITIONS];			
		}
		
		if (frameString) {
			NSRect savedFrame = [self savedFrameFromString:frameString];
			if (!NSIsEmptyRect(savedFrame)) {
				[[self window] setFrame:savedFrame display:NO];
			}
		}
	}
}

/*!
 * @brief Show the window, possibly in front of other windows if inFront is YES
 *
 * Will not show the window in front if the currently-key window controller returns
 * NO to <code>shouldResignKeyWindowWithoutUserInput</code>. 
 * @see AIWindowControllerAdditions::shouldResignKeyWindowWithoutUserInput
 */
- (void)showWindowInFrontIfAllowed:(BOOL)inFront
{
	id currentKeyWindowController = [[NSApp keyWindow] windowController];
	if (currentKeyWindowController && ![currentKeyWindowController shouldResignKeyWindowWithoutUserInput]) {
		//Prevent window from showing in front if key window controller disallows it
		inFront = NO;
	}
	if (inFront) {
		[self showWindow:nil];
	} else {
		[[self window] orderWindow:NSWindowBelow relativeTo:[[NSApp mainWindow] windowNumber]];
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

- (NSString *)stringWithSavedFrame
{
	return [[self window] stringWithSavedFrame];
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

		[[adium preferenceController] setPreference:[self stringWithSavedFrame]
											 forKey:((numberOfScreens == 1) ? 
													 key :
													 [self multiscreenKeyWithAutosaveName:key])
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
