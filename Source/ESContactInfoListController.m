//
//  ESContactInfoListController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/9/04.
//

#import "ESContactInfoListController.h"

@implementation ESContactInfoListController

//The superclass's implementation does not expand metaContacts
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
		if (hideRoot){
			if([contactList isKindOfClass:[AIMetaContact class]]){
				return((index >= 0 && index < [(AIMetaContact *)contactList uniqueContainedObjectsCount]) ?
					   [(AIMetaContact *)contactList uniqueObjectAtIndex:index] : 
					   nil);
			}else{
				return((index >= 0 && index < [(AIListGroup *)contactList containedObjectsCount]) ? [contactList objectAtIndex:index] : nil);
			}
		}else{
			return contactList;
		}
    }else{
		if ([item isKindOfClass:[AIMetaContact class]]){
			return((index >= 0 && index < [(AIMetaContact *)item uniqueContainedObjectsCount]) ? 
				   [(AIMetaContact *)item uniqueObjectAtIndex:index] : 
				   nil);
		}else{
			return((index >= 0 && index < [(AIListGroup *)item containedObjectsCount]) ? [item objectAtIndex:index] : nil);
		}
    }
}

//The superclass's implementation does not expand metaContacts
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
		if(hideRoot){
			if ([contactList isKindOfClass:[AIMetaContact class]]){
				return([(AIMetaContact *)contactList uniqueContainedObjectsCount]);
			}else{
				return([(AIListGroup *)contactList containedObjectsCount]);
			}
		}else{
			return(1);
		}
    }else{
		if([item isKindOfClass:[AIMetaContact class]]){
			return([(AIMetaContact *)item uniqueContainedObjectsCount]);
		}else{
			return([(AIListGroup *)item containedObjectsCount]);
		}
    }
}

//The superclass's implementation does not expand metaContacts
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[AIMetaContact class]] || [item isKindOfClass:[AIListGroup class]]){
        return(YES);
    }else{
        return(NO);
    }
}

//Change the info window as the selection changes
- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == contactListView){
		unsigned selectedRow;
		if ((selectedRow = [contactListView selectedRow]) != -1){
			[(AIContactInfoWindowController *)delegate configureForListObject:[contactListView itemAtRow:selectedRow]];
		}
	}
}

//
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
	NSPasteboard	*draggingPasteboard = [info draggingPasteboard];
    NSString		*avaliableType = [draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
	//No dropping into contacts
    if([avaliableType isEqualToString:@"AIListObject"]){
		
		id	primaryDragItem = nil;
		
		//If we don't have drag items, we are dragging from another instance; build our own dragItems array
		//using the supplied internalObjectIDs
		if (!dragItems){
			if ([[draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]){
				NSArray			*dragItemsUniqueIDs;
				NSMutableArray	*arrayOfDragItems;
				NSString		*uniqueID;
				NSEnumerator	*enumerator;
					
				dragItemsUniqueIDs = [draggingPasteboard propertyListForType:@"AIListObjectUniqueIDs"];
				arrayOfDragItems = [NSMutableArray array];
				
				enumerator = [dragItemsUniqueIDs objectEnumerator];
				while (uniqueID = [enumerator nextObject]){
					[arrayOfDragItems addObject:[[adium contactController] existingListObjectWithUniqueID:uniqueID]];
				}

				//We will release this when the drag is completed
				dragItems = [arrayOfDragItems retain];
			}
		}

		primaryDragItem = [dragItems objectAtIndex:0];			

		if([primaryDragItem isKindOfClass:[AIListGroup class]]){
			//Disallow dragging groups into the contact info window
			return(NSDragOperationNone);
			
		}else{
			//Disallow dragging contacts into anything besides the contact list
			if(index == -1){

				//The contactList is 'nil' to the outlineView
				[outlineView setDropItem:nil dropChildIndex:[outlineView rowForItem:item]];
			}
		}
	}
	
	return(NSDragOperationPrivate);
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	NSPasteboard	*draggingPasteboard = [info draggingPasteboard];
    NSString	*availableType = [draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
    
	//No longer in a drag, so allow tooltips again
    if([availableType isEqualToString:@"AIListObject"]){
		
		//If we don't have drag items, we are dragging from another instance; build our own dragItems array
		//using the supplied internalObjectIDs
		if (!dragItems){
			if ([[draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]){
				NSArray			*dragItemsUniqueIDs;
				NSMutableArray	*arrayOfDragItems;
				NSString		*uniqueID;
				NSEnumerator	*enumerator;
				
				dragItemsUniqueIDs = [draggingPasteboard propertyListForType:@"AIListObjectUniqueIDs"];
				arrayOfDragItems = [NSMutableArray array];
				
				enumerator = [dragItemsUniqueIDs objectEnumerator];
				while (uniqueID = [enumerator nextObject]){
					[arrayOfDragItems addObject:[[adium contactController] existingListObjectWithUniqueID:uniqueID]];
				}
				
				//We will release this when the drag is completed
				dragItems = [arrayOfDragItems retain];
			}
		}
		
		//The tree root is not associated with our root contact list group, so we need to make that association here
		if(item == nil) item = contactList;
		
		//Move the list object to its new location
		if([item isKindOfClass:[AIMetaContact class]]){
			
			NSMutableArray	*realDragItems = [NSMutableArray array];
			NSEnumerator	*enumerator;
			AIListObject	*aDragItem;
			
			if (index == [outlineView numberOfRows]){
				index = [item containedObjectsCount];
			}else{
				//The outline view has one unique contact for each service/UID combination, while the metacontact
				//has a containedObjectsArray with multiple contacts for each.  We want to find which item is at
				//our drop row, then determine the index in the metacontact of that item.  That's the index we move to.
				index = [(AIMetaContact *)item indexOfObject:[outlineView itemAtRow:index]];
			}
			
			enumerator = [dragItems objectEnumerator];
			while (aDragItem = [enumerator nextObject]){
				if ([aDragItem isMemberOfClass:[AIListContact class]]){
					//For listContacts, add all contacts with the same service and UID (on all accounts)
					[realDragItems addObjectsFromArray:[[adium contactController] allContactsWithService:[aDragItem service] 
																									 UID:[aDragItem UID]]];
				}else{
					[realDragItems addObject:aDragItem];
				}
			}
			
			[[adium contactController] moveListObjects:realDragItems toGroup:item index:index];
			[outlineView reloadData];
		}
	}
	
    return(YES);
}

- (void)outlineView:(NSOutlineView *)outlineView draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
	if (operation == NSDragOperationNone){
		NSLog(@"None!");
	}
}


//Due to a bug in NSDrawer, convertPoint:fromView reports a point too low by the trailingOffset 
//when our contact list is in a drawer.
- (AIListObject *)contactListItemAtScreenPoint:(NSPoint)screenPoint
{
	NSPoint			viewPoint = [contactListView convertPoint:[[contactListView window] convertScreenToBase:screenPoint] fromView:[[contactListView window] contentView]];
	
	viewPoint.y += [(AIContactInfoWindowController *)delegate drawerTrailingOffset];
	
	AIListObject	*hoveredObject = [contactListView itemAtRow:[contactListView rowAtPoint:viewPoint]];
	
	return(hoveredObject);
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
