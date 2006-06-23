//
//  AIContactListOutlineView.m
//  Adium
//
//  Created by Nick Peshek on 6/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIContactListOutlineView.h"
#import "AIMultiListWindowController.h"
#import "AISCLViewPlugin.h"
#import <Adium/AIAdium.h>
#import <Adium/AIContactController.h>
#import <Adium/AIInterfaceController.h>


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
	return [super draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	isDroppedOutOfView = YES;
	[super draggingExited:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	BOOL	dragSucceeded = NO;
	if(isDroppedOutOfView) {
		if ([[[sender draggingPasteboard] types] containsObject:@"AIListObjectUniqueIDs"]) {
			NSArray			*dragItemsUniqueIDs = [[sender draggingPasteboard] propertyListForType:@"AIListObjectUniqueIDs"];
			NSString		*uniqueUID;
			NSEnumerator	*idEnumerator = [dragItemsUniqueIDs objectEnumerator];
			BOOL			listCreated = NO;
			while ((uniqueUID = [idEnumerator nextObject])) {
				if (([[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID] isKindOfClass:[AIListGroup class]]) && (!listCreated)) {
					[[[[[AIObject sharedAdiumInstance] interfaceController] contactListPlugin] contactListWindowController] createNewSeparableContactListWithObject:[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID]];
					listCreated = YES;
					dragSucceeded = YES;
				}
#warning Come here kbotc and check this out.
				// else if ([[[adium contactController] existingListObjectWithUniqueID:uniqueUID] isKindOfClass:[AIListObject class]]) {
				//	[[[adium interfaceController] contactListViewController] addContactToMostRecentList:[[adium contactController] existingListObjectWithUniqueID:uniqueUID]];
				//}
			}
		}
	}
	return dragSucceeded;
}
@end
