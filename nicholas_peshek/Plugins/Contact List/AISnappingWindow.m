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

#import <Adium/AIAdium.h>
#import "AICoreComponentLoader.h"
#import "AIListWindowController.h"
#import "AIListController.h"
#import "AIListGroup.h"
#import "AIListObject.h"
#import "AIMultiListWindowController.h"
#import "AISCLViewPlugin.h"
#import "AISnappingWindow.h"

@interface AISnappingWindow (PRIVATE)
- (void)mergeContactListWindow:(NSWindow *)currentWindow withWindow:(NSWindow *)otherWindow;
@end

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
	NSEnumerator	*windows = [[NSApp windows] objectEnumerator];
	
	while ((otherWindow = [windows nextObject]) && !alreadyChanged) {
		otherWindowFrame = [otherWindow frame];
		if (!([NSStringFromRect(([self frame])) isEqual:NSStringFromRect(otherWindowFrame)]) && [otherWindow isVisible] && [otherWindow isKindOfClass:[AISnappingWindow class]]) {
			if (!alreadyChanged && (fabs(NSMinY(otherWindowFrame) - NSMaxY((*inWindowFrame))) <= BORDERLESS_WINDOW_DOCKING_DISTANCE) && (NSMinX(otherWindowFrame) < NSMaxX(*inWindowFrame)) && (NSMaxX(otherWindowFrame) > NSMinX(*inWindowFrame))) {
				(*inWindowFrame).origin.y += NSMinY(otherWindowFrame) - NSMaxY((*inWindowFrame));
				if((fabs(otherWindowFrame.origin.x - (*inWindowFrame).origin.x)) <= BORDERLESS_WINDOW_DOCKING_DISTANCE) {
					(*inWindowFrame).origin.x = otherWindowFrame.origin.x;
					windowToSnapTo = otherWindow;
				}
				alreadyChanged = YES;
			}
			if (!alreadyChanged && (fabs(NSMaxY(otherWindowFrame) - NSMinY((*inWindowFrame))) <= BORDERLESS_WINDOW_DOCKING_DISTANCE) && (NSMinX(otherWindowFrame) < NSMaxX(*inWindowFrame)) && (NSMaxX(otherWindowFrame) > NSMinX(*inWindowFrame))) {
				(*inWindowFrame).origin.y = NSMaxY(otherWindowFrame);
				if((fabs(otherWindowFrame.origin.x - (*inWindowFrame).origin.x)) <= BORDERLESS_WINDOW_DOCKING_DISTANCE) {
					(*inWindowFrame).origin.x = otherWindowFrame.origin.x;
					windowToSnapTo = otherWindow;
				}
				alreadyChanged = YES;
			}
		}
	}
	
	//Window's all moved around, return if we moved it!
	return alreadyChanged;
}

- (void)mouseUp:(NSEvent *)theEvent
{
	//A quick efficiency check. If we didn't link to a window during the drag, don't bother doing anything.
	if(windowToSnapTo) {
	//Check if the x origin coordinates match, this means that they're still linked.
		if([self frame].origin.x == [windowToSnapTo frame].origin.x) {
		//The window was dragged to the top of another window.
			if([self frame].origin.y == NSMaxY([windowToSnapTo frame])) {
				[self mergeContactListWindow:windowToSnapTo withWindow:self];
		//The window was dragged to the bottom of another window.
			} else if ([self frame].origin.y == ([self frame].origin.y + NSMinY([windowToSnapTo frame]) - NSMaxY([self frame]))) {
				[self mergeContactListWindow:self withWindow:windowToSnapTo];
			}
		}
		windowToSnapTo = nil;
	}
	[super mouseUp:theEvent];
}

- (void)mergeContactListWindow:(NSWindow *)currentWindow withWindow:(NSWindow *)otherWindow
{
	AIListObject<AIContainingObject>	*groupToMergeWith = [[(AIListWindowController  *)[otherWindow windowController] listController] contactListRoot];
	
	AIListObject<AIContainingObject>	*containingObject;
	NSEnumerator						*enumerator = [[[[(AIListWindowController  *)[currentWindow windowController] listController] contactListRoot] containedObjects] objectEnumerator];
	
	while((containingObject = [enumerator nextObject])) {
		[groupToMergeWith addObject:containingObject];
	}
	
	[[(AIListWindowController  *)[otherWindow windowController] master] setContactListRoot:groupToMergeWith];
	[[(AISCLViewPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"AISCLViewPlugin"] contactListWindowController] destroyListController:[[currentWindow windowController] master]];
}
- (void)mouseUp:(NSEvent *)theEvent
{
	if(windowToSnapTo) {
		if([self frame].origin.x == [windowToSnapTo frame].origin.x) {
			if([self frame].origin.y == NSMaxY([windowToSnapTo frame])) {
				[self mergeContactListWindow:windowToSnapTo withWindow:self];
			} else if ([self frame].origin.y += NSMinY([windowToSnapTo frame]) - NSMaxY([self frame])) {
				[self mergeContactListWindow:self withWindow:windowToSnapTo];
			}
		}
	}
	[super mouseUp:theEvent];
}
@end
