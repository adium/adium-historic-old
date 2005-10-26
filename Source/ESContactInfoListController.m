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

#import "AIContactController.h"
#import "AIContactInfoWindowController.h"
#import "ESContactInfoListController.h"
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIMetaContact.h>

@implementation ESContactInfoListController

//The superclass's implementation does not expand metaContacts
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if (item == nil) {
		if (hideRoot) {
			if ([contactList isKindOfClass:[AIMetaContact class]]) {
				return (index >= 0 && index < [(AIMetaContact *)contactList uniqueContainedObjectsCount] ?
					   [(AIMetaContact *)contactList uniqueObjectAtIndex:index] : 
					   nil);
			} else {
				return (index >= 0 && index < [(AIListGroup *)contactList containedObjectsCount]) ? [contactList objectAtIndex:index] : nil;
			}
		} else {
			return contactList;
		}
    } else {
		if ([item isKindOfClass:[AIMetaContact class]]) {
			return (index >= 0 && index < [(AIMetaContact *)item uniqueContainedObjectsCount] ? 
				   [(AIMetaContact *)item uniqueObjectAtIndex:index] : 
				   nil);
		} else {
			return (index >= 0 && index < [(AIListGroup *)item containedObjectsCount]) ? [item objectAtIndex:index] : nil;
		}
    }
}

//The superclass's implementation does not expand metaContacts
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
		if (hideRoot) {
			if ([contactList isKindOfClass:[AIMetaContact class]]) {
				return [(AIMetaContact *)contactList uniqueContainedObjectsCount];
			} else {
				return [(AIListGroup *)contactList containedObjectsCount];
			}
		} else {
			return 1;
		}
    } else {
		if ([item isKindOfClass:[AIMetaContact class]]) {
			return [(AIMetaContact *)item uniqueContainedObjectsCount];
		} else {
			return [(AIListGroup *)item containedObjectsCount];
		}
    }
}

//The superclass's implementation does not expand metaContacts
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[AIMetaContact class]] || [item isKindOfClass:[AIListGroup class]]) {
        return YES;
    } else {
        return NO;
    }
}

/*!
 * @brief Change the info window as the selection changes
 *
 * We want to configure for contact-specific information when a contact is selected in the drawer
 * If no row is selected, we configure for the contactList root (the metaContact itself)
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	if (!aNotification || [aNotification object] == contactListView) {
		int selectedRow = [contactListView selectedRow];

		[delegate contactInfoListControllerSelectionDidChangeToListObject:((selectedRow != -1) ?
																		   [contactListView itemAtRow:selectedRow] :
																		   contactList)];
	}
}

/*!
 * @brief Remove the selected rows from the metaContact
 */
- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)outlineView
{
	[(AIContactInfoWindowController *)delegate removeContact:outlineView];
}

/*!
 * @brief Validate a drag and drop operation
 */
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
	NSPasteboard	*draggingPasteboard = [info draggingPasteboard];
    NSString		*avaliableType = [draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
	//No dropping into contacts
    if ([avaliableType isEqualToString:@"AIListObject"]) {
		
		id	primaryDragItem = nil;
		
		//If we don't have drag items, we are dragging from another instance; build our own dragItems array
		//using the supplied internalObjectIDs
		if (!dragItems) {
			if ([[draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]) {
				NSArray			*dragItemsUniqueIDs;
				NSMutableArray	*arrayOfDragItems;
				NSString		*uniqueID;
				NSEnumerator	*enumerator;
					
				dragItemsUniqueIDs = [draggingPasteboard propertyListForType:@"AIListObjectUniqueIDs"];
				arrayOfDragItems = [NSMutableArray array];
				
				enumerator = [dragItemsUniqueIDs objectEnumerator];
				while ((uniqueID = [enumerator nextObject])) {
					[arrayOfDragItems addObject:[[adium contactController] existingListObjectWithUniqueID:uniqueID]];
				}

				//We will release this when the drag is completed
				dragItems = [arrayOfDragItems retain];
			}
		}

		primaryDragItem = [dragItems objectAtIndex:0];			

		if ([primaryDragItem isKindOfClass:[AIListGroup class]]) {
			//Disallow dragging groups into the contact info window
			return NSDragOperationNone;
			
		} else {
			//Disallow dragging contacts into anything besides the contact list
			if (index == NSOutlineViewDropOnItemIndex) {

				//The contactList is 'nil' to the outlineView
				[outlineView setDropItem:nil dropChildIndex:[outlineView rowForItem:item]];
			}
		}
	}
	
	return NSDragOperationPrivate;
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	NSPasteboard	*draggingPasteboard = [info draggingPasteboard];
    NSString	*availableType = [draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];

	//No longer in a drag, so allow tooltips again
    if ([availableType isEqualToString:@"AIListObject"]) {
		
		//If we don't have drag items, we are dragging from another instance; build our own dragItems array
		//using the supplied internalObjectIDs
		if (!dragItems) {
			if ([[draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]) {
				NSArray			*dragItemsUniqueIDs;
				NSMutableArray	*arrayOfDragItems;
				NSString		*uniqueID;
				NSEnumerator	*enumerator;
				
				dragItemsUniqueIDs = [draggingPasteboard propertyListForType:@"AIListObjectUniqueIDs"];
				arrayOfDragItems = [NSMutableArray array];
				
				enumerator = [dragItemsUniqueIDs objectEnumerator];
				while ((uniqueID = [enumerator nextObject])) {
					[arrayOfDragItems addObject:[[adium contactController] existingListObjectWithUniqueID:uniqueID]];
				}
				
				//We will release this when the drag is completed
				dragItems = [arrayOfDragItems retain];
			}
		}

		//The tree root is not associated with our root contact list group, so we need to make that association here
		if (item == nil) item = contactList;
		
		//Move the list object to its new location
		if ([item isKindOfClass:[AIMetaContact class]]) {
			
			NSMutableArray	*realDragItems = [NSMutableArray array];
			NSEnumerator	*enumerator;
			AIListObject	*aDragItem;
			
			if (index == [outlineView numberOfRows]) {
				index = [item containedObjectsCount];
			} else {
				//The outline view has one unique contact for each service/UID combination, while the metacontact
				//has a containedObjectsArray with multiple contacts for each.  We want to find which item is at
				//our drop row, then determine the index in the metacontact of that item.  That's the index we move to.
				index = [(AIMetaContact *)item indexOfObject:[outlineView itemAtRow:index]];
			}
			
			enumerator = [dragItems objectEnumerator];
			while ((aDragItem = [enumerator nextObject])) {
				if ([aDragItem isMemberOfClass:[AIListContact class]]) {
					//For listContacts, add all contacts with the same service and UID (on all accounts)
					[realDragItems addObjectsFromArray:[[[adium contactController] allContactsWithService:[aDragItem service] 
																									  UID:[aDragItem UID]
																							 existingOnly:YES] allObjects]];
				} else {
					[realDragItems addObject:aDragItem];
				}
			}
			
			[[adium contactController] moveListObjects:realDragItems toGroup:item index:index];
			[outlineView reloadData];
		}
	}

	//Call super and return its value
    return [super outlineView:outlineView acceptDrop:info item:item childIndex:index];
}

//Due to a bug in NSDrawer, convertPoint:fromView reports a point too low by the trailingOffset 
//when our contact list is in a drawer.
- (AIListObject *)contactListItemAtScreenPoint:(NSPoint)screenPoint
{
	NSPoint			viewPoint = [contactListView convertPoint:[[contactListView window] convertScreenToBase:screenPoint] fromView:[[contactListView window] contentView]];
	
	viewPoint.y += [(AIContactInfoWindowController *)delegate drawerTrailingOffset];
	
	AIListObject	*hoveredObject = [contactListView itemAtRow:[contactListView rowAtPoint:viewPoint]];
	
	return hoveredObject;
}

//We want to just show UIDs whereever possible
- (BOOL)useAliasesInContactListAsRequested
{
	return NO;
}

//We don't want to change text colors based on the user's status or state
- (BOOL)shouldUseContactTextColors{
	return NO;
}
	
@end
