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

- (void)windowDidLoad
{
	//Clear the minimum size before our window restores its position and size; a borderless window can be any size it wants
	[[self window] setMinSize:NSZeroSize];

	[super windowDidLoad];
}

/*!
 * @brief Used by the interface controller to know that despite having no NSWindowCloseButton, our window can be closed
 */
- (BOOL)windowPermitsClose
{
	return YES;
}

/*!
 * @brief Slide the window to a given point
 *
 * windowSlidOffScreenEdgeMask must already be set to the resulting offscreen mask (or 0 if the window is sliding on screen)
 *
 * A standard window (titlebar window) will crash if told to setFrame completely offscreen. Also, using our own movement we can more precisely
 * control the movement speed and acceleration.
 */
- (void)slideWindowToPoint:(NSPoint)inPoint
{	
	NSWindow	*myWindow = [self window];
	
	if ((windowSlidOffScreenEdgeMask == AINoEdges) &&
		(previousAlpha > 0.0)) {
		//Before sliding onscreen, restore any previous alpha value
		[myWindow setAlphaValue:previousAlpha];
		previousAlpha = 0.0;
	}

	manualWindowMoveToPoint([self window],
							inPoint,
							windowSlidOffScreenEdgeMask,
							contactListController,
							NO);
	
	if (windowSlidOffScreenEdgeMask == AINoEdges) {
		/* When the window is offscreen, there are no constraints on its size, for example it will grow downwards as much as
		 * it needs to to accomodate new rows.  Now that it's onscreen, there are constraints.
		 */
		[contactListController contactListDesiredSizeChanged];			
	} else {
		//After sliding off screen, go to an alpha value of 0 to hide our 1 px remaining on screen
		previousAlpha = [myWindow alphaValue];
		[myWindow setAlphaValue:0.0];
	}
}

@end
