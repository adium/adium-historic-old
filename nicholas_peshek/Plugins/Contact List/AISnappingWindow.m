//
//  AISnappingWindow.h
//  Adium
//
//  Created by Nicholas Peshek on Sun May 02 2006.
//  Copyright (c) 2004-2006 The Adium Team. All rights reserved.
//

/*!
* @class AISnappingWindow
 * @brief An AIBoderlessWindow subclass which snaps to window edges
 *
 * An AIBoderlessWindow subclass which snaps to window edges.
 */

#import "AISnappingWindow.h"
#import <AIUtilities/AIDockingWindow.h>


@implementation AISnappingWindow

//Dock the passed window frame to another window if it's close enough then dock it to the screen edges
- (BOOL)dockWindowFrame:(NSRect *)inWindowFrame toScreenFrame:(NSRect)inScreenFrame
{
	BOOL	alreadyChanged = NO;
	
	//If option is held down, don't snap to anything.
	if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
		return alreadyChanged;
	}
	
	//Dock to screen edge before docking to other windows.
	alreadyChanged = [super dockWindowFrame:inWindowFrame toScreenFrame:inScreenFrame];
	
	NSRect			otherWindowFrame;
	NSWindow		*otherWindow;
#warning KBOTC: MAKE THIS INTO A PROPER CONTROLLER THAT ONLY GETS CONTACT LIST WINDOWS
	NSEnumerator	*windows = [[NSApp windows] objectEnumerator];
	
	while ((otherWindow = [windows nextObject]) && !alreadyChanged) {
		otherWindowFrame = [otherWindow frame];
		if (!([NSStringFromRect((*inWindowFrame)) isEqual:NSStringFromRect(otherWindowFrame)]) && [otherWindow isVisible] && [otherWindow isKindOfClass:[AIDockingWindow class]]) {
			if (!alreadyChanged && fabs(NSMinY(otherWindowFrame) - NSMinY((*inWindowFrame))) <= BORDERLESS_WINDOW_DOCKING_DISTANCE) {
				(*inWindowFrame).origin.y = otherWindowFrame.origin.y;
				alreadyChanged = YES;
			}
			if (!alreadyChanged && fabs(NSMinY(otherWindowFrame) - NSMaxY((*inWindowFrame))) <= BORDERLESS_WINDOW_DOCKING_DISTANCE) {
				(*inWindowFrame).origin.y += NSMinY(otherWindowFrame) - NSMaxY((*inWindowFrame));
				alreadyChanged = YES;
			}
			if (!alreadyChanged && fabs(NSMaxY(otherWindowFrame) - NSMinY((*inWindowFrame))) <= BORDERLESS_WINDOW_DOCKING_DISTANCE) {
				(*inWindowFrame).origin.y = NSMaxY(otherWindowFrame);
				alreadyChanged = YES;
			}
			if (!alreadyChanged && fabs(NSMaxY(otherWindowFrame) - NSMaxY((*inWindowFrame))) <= BORDERLESS_WINDOW_DOCKING_DISTANCE) {
				(*inWindowFrame).origin.y += NSMaxY(otherWindowFrame) - NSMaxY((*inWindowFrame));
				alreadyChanged = YES;
			}
		}
	}
	
	//Window's all moved around, return if we moved it!
	return alreadyChanged;
}
@end
