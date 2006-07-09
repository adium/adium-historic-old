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
#import "AIListGroup.h"
#import "AISCLViewPlugin.h"
#import <Adium/AIAdium.h>
#import <Adium/AIContactController.h>

@implementation AIContactListOutlineView

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
			AIListObject<AIContainingObject>	*contactList = [[self dataSource] contactList];
			NSArray			*dragItemsUniqueIDs = [tempDragBoard propertyListForType:@"AIListObjectUniqueIDs"];
			NSEnumerator	*idEnumerator = [dragItemsUniqueIDs objectEnumerator];
			NSString		*uniqueUID;
			AIListGroup		*newRootObject;
			BOOL			listShouldBeCreated = NO;
			BOOL			rootCreated = NO;
			
			while ((uniqueUID = [idEnumerator nextObject])) {
				//if it's a group, let it make a new list.
				if ([[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID] isKindOfClass:[AIListGroup class]]) {
					listShouldBeCreated = YES;
					if(!rootCreated) {
						newRootObject = [[AIListGroup alloc] initWithUID:[@"Group:" stringByAppendingString:uniqueUID]];
						rootCreated = YES;
					}
					
					[newRootObject addObject:[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID]];
					
					//AIListObject	*containingObject;
					//NSEnumerator	*enumerator = [[(AIListGroup *)[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID] containedObjects] objectEnumerator];
					
					//while((containingObject = [enumerator nextObject])) {
					//	[contactList removeObject:containingObject];
					//}
					
					[contactList removeObject:[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID]];
					if([contactList containsObject:[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID]]) {
						NSLog(@"OMG NOOBZ GG!");
					}
					[[self dataSource] setContactList:contactList];
				}
			}
			if(listShouldBeCreated) {
				if([newRootObject containsObject:[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID]]) {
					NSLog(@"OMG NOOBZ GG 2!");
				}
				[[(AISCLViewPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"AISCLViewPlugin"] contactListWindowController] createNewSeparableContactListWithObject:newRootObject];
			}
		}
		tempDragBoard = nil;
	}
}
@end
