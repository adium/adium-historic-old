//
//  AIContactListOutlineView.m
//  Adium
//
//  Created by Nick Peshek on 6/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIContactListOutlineView.h"
#import "AICoreComponentLoader.h"
#import "AIMultiListWindowController.h"
#import "AISCLViewPlugin.h"
#import <Adium/AIAdium.h>
#import <Adium/AIContactController.h>

@implementation AIContactListOutlineView

/*
 - (void)draggingEnded:(id <NSDraggingInfo>)sender
 {
	 NSLog(@"100 Babies have been eaten to get here.");
	 
	 
	 return [super draggingEnded:sender];
 }
 */

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	isDroppedOutOfView = NO;
	tempDragBoard = nil;
	
	return [super draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	isDroppedOutOfView = YES;
	tempDragBoard = [sender draggingPasteboard];
	
	[super draggingExited:sender];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	if(isDroppedOutOfView && tempDragBoard) {
		if ([[tempDragBoard types] containsObject:@"AIListObjectUniqueIDs"]) {
			NSArray			*dragItemsUniqueIDs = [tempDragBoard propertyListForType:@"AIListObjectUniqueIDs"];
			NSString		*uniqueUID;
			NSEnumerator	*idEnumerator = [dragItemsUniqueIDs objectEnumerator];
			BOOL			listCreated = NO;
			while ((uniqueUID = [idEnumerator nextObject])) {
				NSLog(uniqueUID);
				if (([[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID] isKindOfClass:[AIListGroup class]]) && (!listCreated)) {
					[[(AISCLViewPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"AISCLViewPlugin"] contactListWindowController] createNewSeparableContactListWithObject:[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID]];
					listCreated = YES;
				}
#warning Come here kbotc and check this out.
				// else if ([[[adium contactController] existingListObjectWithUniqueID:uniqueUID] isKindOfClass:[AIListObject class]]) {
				//	[[[adium interfaceController] contactListViewController] addContactToMostRecentList:[[adium contactController] existingListObjectWithUniqueID:uniqueUID]];
				//}
			}
		}
		tempDragBoard = nil;
	}
}
@end
