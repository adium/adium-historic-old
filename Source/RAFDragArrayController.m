//
//  RAFDragArrayController.m
//  Adium
//
//  Created by Augie Fackler on 7/6/05.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "RAFDragArrayController.h"
#import "AIObject.h"
#import "AIListObject.h"
#import "AIMetaContact.h"
#import "AIListGroup.h"
#import "AIContactController.h"
#import "AIAccount.h"

@implementation RAFDragArrayController

- (void)awakeFromNib
{
    // we want the same types as the contact list
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:@"AIListObject", @"AIListObjectUniqueIDs",nil]];
    [tableView setAllowsMultipleSelection:YES];
	adium = [AIObject sharedAdiumInstance];
	[super awakeFromNib];
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
#warning We should be able to drag to ourselves, at the very least -durin42
    return NO;
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
    
    NSDragOperation dragOp = NSDragOperationCopy;

    if ([info draggingSource] == tableView) {
		dragOp =  NSDragOperationMove;
    }
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
	BOOL accept = NO;
    if (row < 0)
		row = 0;
	
	if ([[[info draggingPasteboard] types] containsObject:@"AIListObjectUniqueIDs"]) {
		NSArray			*dragItemsUniqueIDs = [[info draggingPasteboard] propertyListForType:@"AIListObjectUniqueIDs"];
		NSString *uniqueUID;
		NSEnumerator *idEnumerator = [dragItemsUniqueIDs objectEnumerator];
		while ((uniqueUID = [idEnumerator nextObject]))
			[self addListObjectToList:[[adium contactController] existingListObjectWithUniqueID:uniqueUID]];
		accept = YES;
	}
		
    return accept;
}

- (void)addListObjectToList:(AIListObject *)listObject
{
	AIListObject *tmp;
	NSEnumerator *groupEnum;
	if ([listObject isMemberOfClass:[AIListGroup class]]) {
		groupEnum = [[(AIListGroup *)listObject listContacts] objectEnumerator];
		while ((tmp = [groupEnum nextObject]))
			[self addListObjectToList:tmp];
	} else if ([listObject isMemberOfClass:[AIMetaContact class]]) {
		groupEnum = [[(AIMetaContact *)listObject listContacts] objectEnumerator];
		while ((tmp = [groupEnum nextObject]))
			[self addListObjectToList:tmp];
	} else if ([listObject isMemberOfClass:[AIListContact class]]) {
		//if the account for this contact is connected...
		if ([[[(AIListContact *)listObject account] statusObjectForKey:@"Online"] boolValue])
			[self  addObject:listObject];
	}
}

@end
