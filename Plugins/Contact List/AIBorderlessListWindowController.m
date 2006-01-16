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

#import "AIBorderlessListWindowController.h"
#import "AIBorderlessListController.h"

@implementation AIBorderlessListWindowController

//Borderless nib
+ (NSString *)nibName
{
    return @"ContactListWindowBorderless";
}

- (Class)listControllerClass
{
	return [AIBorderlessListController class];
}

- (void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[super dealloc];
}

#warning this seems like it would mess up people with more than one screen
//Ensure we're on the main screen on load
- (void)windowDidLoad
{
	//Clear the minimum size before our window restores its position and size; a borderless window can be any size it wants
	[[self window] setMinSize:NSZeroSize];

	[super windowDidLoad];
	
	NSWindow *window = [self window];
	if (![window screen]) {
		[window constrainFrameRect:[window frame] toScreen:[NSScreen mainScreen]];
	}
}

/*
 * @brief Slide the window to a given point
 *
 * windowSlidOffScreenEdgeMask must already be set to the resulting offscreen mask (or 0 if the window is sliding on screen)
 *
 * A borderless window can do whatever it wants; animate the sucker offscreen.
 */
- (void)slideWindowToPoint:(NSPoint)inPoint
{
	NSWindow	*myWindow = [self window];
	NSRect		newFrame = [[self window] frame];
	
	newFrame.origin = inPoint;

	[myWindow setFrame:newFrame
			   display:YES
			   animate:YES];

	if (!windowSlidOffScreenEdgeMask) {
		/* When the window is offscreen, there are no constraints on its size, for example it will grow downwards as much as
		 * it needs to to accomodate new rows.  Now that it's onscreen, there are constraints.
		 */
		[contactListController contactListDesiredSizeChanged];			
	}	
}

@end
