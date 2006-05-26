//
//  RAFDragArrayController.m
//  Adium
//
//  Created by Augie Fackler on 7/6/05.
//  Copyright 2006 The Adium Team. All rights reserved.
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
	//Begin the drag
	if (dragItems != rows) {
		[dragItems release];
		dragItems = [rows retain];
	}
	
	[pboard declareTypes:[NSArray arrayWithObjects:@"AIListObject",@"AIListObjectUniqueIDs",nil] owner:self];
	[pboard setString:@"Private" forType:@"AIListObject"];

#warning take this debug code out when we're sure this DnD operation stuff works
	if (dragItems) {
		NSEnumerator	*enumerator = [dragItems objectEnumerator];
		AIListObject	*listObject;
		while ((listObject = [enumerator nextObject])) {
			NSLog(@"dragging %@",[listObject internalObjectID]);
		}
	}
	
	
	return YES;
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
	//Provide an array of internalObjectIDs which can be used to reference all the dragged contacts
	if ([type isEqualToString:@"AIListObjectUniqueIDs"]) {
		
		if (dragItems) {
			NSMutableArray	*dragItemsArray = [NSMutableArray array];
			NSEnumerator	*enumerator = [dragItems objectEnumerator];
			AIListObject	*listObject;
			
			while ((listObject = [enumerator nextObject])) {
				[dragItemsArray addObject:[listObject internalObjectID]];
			}
			
			[sender setPropertyList:dragItemsArray forType:@"AIListObjectUniqueIDs"];
		}
	}
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
