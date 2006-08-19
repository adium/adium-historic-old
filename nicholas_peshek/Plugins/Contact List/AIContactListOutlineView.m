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
#import "AIContactList.h"
#import "AISCLViewPlugin.h"
#import <Adium/AIAdium.h>
#import <Adium/AIContactController.h>

@implementation AIContactListOutlineView

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	isDroppedOutOfView = [NSNumber numberWithBool:NO];
	tempDragBoard = nil;
	[[(AISCLViewPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"AISCLViewPlugin"] contactListWindowController] selector:@selector(setIsDroppedOutOfView:)
																																			withArgument:(id)isDroppedOutOfView
																																				  toItem:CONTACT_LIST_OUTLINE_VIEW
																																					  on:EVERY];
	return [super draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	isDroppedOutOfView = [NSNumber numberWithBool:YES];
	tempDragBoard = [sender draggingPasteboard];
	[[(AISCLViewPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"AISCLViewPlugin"] contactListWindowController] selector:@selector(setIsDroppedOutOfView:)
																																			withArgument:(id)isDroppedOutOfView
																																				  toItem:CONTACT_LIST_OUTLINE_VIEW
																																					  on:EVERY];
	[super draggingExited:sender];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	if([isDroppedOutOfView boolValue] && tempDragBoard) {
		if ([[tempDragBoard types] containsObject:@"AIListObjectUniqueIDs"]) {
			AIListObject<AIContainingObject>	*contactList = [[self dataSource] contactListRoot];
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
					[contactList removeObject:[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID]];
					[[self dataSource] setContactListRoot:contactList];
				}
			}
			if(listShouldBeCreated) {
				[[(AISCLViewPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"AISCLViewPlugin"] contactListWindowController] createNewSeparableContactListWithObject:newRootObject];
				[[[(AISCLViewPlugin *)[[[AIObject sharedAdiumInstance] componentLoader] pluginWithClassName:@"AISCLViewPlugin"] contactListWindowController] window] setFrameTopLeftPoint:aPoint];
				[[self dataSource] contactListDesiredSizeChanged];
			}
			newRootObject = nil;
		}
		tempDragBoard = nil;
	}
	//Apparently, I'm an idiot, and AIAbstractListController needs this as well. Pass it off to the dataSource and let that deal with it.
	[[self dataSource] outlineView:self draggedImage:anImage endedAt:aPoint operation:operation];
}

- (void)setIsDroppedOutOfView:(NSNumber *)droppedOn
{
	isDroppedOutOfView = droppedOn;
}

//Disable/enable Slideback image.
- (void)dragImage:(NSImage *)anImage
			   at:(NSPoint)baseLocation
		   offset:(NSSize)initialOffset
			event:(NSEvent *)event
	   pasteboard:(NSPasteboard *)pboard
		   source:(id)sourceObject
		slideBack:(BOOL)slideFlag {
	
	if([isDroppedOutOfView boolValue]) {
		if ([[pboard types] containsObject:@"AIListObjectUniqueIDs"]) {
			NSArray			*dragItemsUniqueIDs = [pboard propertyListForType:@"AIListObjectUniqueIDs"];
			NSEnumerator	*idEnumerator = [dragItemsUniqueIDs objectEnumerator];
			NSString		*uniqueUID;
			
			while ((uniqueUID = [idEnumerator nextObject])) {
				if ([[[[AIObject sharedAdiumInstance] contactController] existingListObjectWithUniqueID:uniqueUID] isKindOfClass:[AIListGroup class]]) {
					slideFlag = NO;
				}
			}
		}
	}
	
	[super dragImage:anImage
				  at:baseLocation
			  offset:initialOffset
			   event:event
		  pasteboard:pboard
			  source:sourceObject
		   slideBack:slideFlag];
}
@end
