/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIOutlineView.h"

@interface AIOutlineView (PRIVATE)
- (void)_initOutlineView;
@end

@implementation AIOutlineView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initOutlineView];
    return(self);
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self _initOutlineView];
    return(self);
}

- (void)_initOutlineView
{
	//
}

//Allow our delegate to specify context menus
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    if([[self delegate] respondsToSelector:@selector(outlineView:menuForEvent:)]){
        return([[self delegate] outlineView:self menuForEvent:theEvent]);
    }else{
        return(nil);
    }
}

//Default to a more intelligent vertical line scroll
- (void)tile
{
    [super tile];
    [[self enclosingScrollView] setVerticalLineScroll:([self rowHeight] + [self intercellSpacing].height)];
}

//Navigate outline view with the keyboard, send select actions to delegate
- (void)keyDown:(NSEvent *)theEvent
{
    if(!([theEvent modifierFlags] & NSCommandKeyMask)){
		if([theEvent keyCode] == NSDeleteFunctionKey || [theEvent keyCode] == 127){ //Delete
			if([[self dataSource] respondsToSelector:@selector(outlineViewDeleteSelectedRows:)]){
				[[self dataSource] outlineViewDeleteSelectedRows:self];
			}
			
		}else if([theEvent keyCode] == 36){ //Enter or return
			//doubleAction is NULL by default
			SEL doubleActionSelector = [self doubleAction];
			if (doubleActionSelector){
				[[self delegate] performSelector:doubleActionSelector withObject:self];
			}
			
        }else if([theEvent keyCode] == 123){ //left
            id 	object = [self itemAtRow:[self selectedRow]];
            if(object && [self isExpandable:object] && [self isItemExpanded:object]){
				[self collapseItem:object];
            }
			
        }else if([theEvent keyCode] == 124){ //right
            id 	object = [self itemAtRow:[self selectedRow]];
            if(object && [self isExpandable:object] && ![self isItemExpanded:object]){
				[self expandItem:object];
            }
			
        }else{
			[super keyDown:theEvent];
		}
	}else{
		[super keyDown:theEvent];
	}
}


//Collapse/expand memory -----------------------------------------------------------------------------------------------
#pragma mark Collapse/expand memory
//The notifications NSOutlineViewItemDidExpand/Collapse are posted when the outline view is reloaded, making it 
//impossible to tell when a user expanded/collapsed a group (since there will be tons of false notifications sent
//out when reloading).  As a fix, we implement two new notifications that ONLY get posted when THE USER expands
//or collapses a group.
- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren
{
	[super expandItem:item expandChildren:expandChildren];
	
	if(!ignoreExpandCollapse){
		//General expand notification
		[[NSNotificationCenter defaultCenter] postNotificationName:AIOutlineViewUserDidExpandItemNotification
															object:self
														  userInfo:[NSDictionary dictionaryWithObject:item forKey:@"Object"]];
		
		//Inform our delegate directly
		if([[self delegate] respondsToSelector:@selector(outlineView:setExpandState:ofItem:)]){
			[[self delegate] outlineView:self setExpandState:YES ofItem:item];
		}
	}
}
- (void)collapseItem:(id)item collapseChildren:(BOOL)collapseChildren
{
	[super collapseItem:item collapseChildren:collapseChildren];

	if(!ignoreExpandCollapse){
		//General expand notification
		[[NSNotificationCenter defaultCenter] postNotificationName:AIOutlineViewUserDidCollapseItemNotification
															object:self
														  userInfo:[NSDictionary dictionaryWithObject:item forKey:@"Object"]];
		
		//Inform our delegate directly
		if([[self delegate] respondsToSelector:@selector(outlineView:setExpandState:ofItem:)]){
			[[self delegate] outlineView:self setExpandState:NO ofItem:item];
		}
	}
}

//Preserve selection and group expansion through a reload
- (void)reloadData
{
//	NSArray		*selectedItems;
	
	/* This code is to correct what I consider a bug with NSOutlineView.
	Basically, if reloadData is called from 'outlineView:setObjectValue:forTableColumn:byItem:' while the last
	row is edited in a way that will reduce the # of rows in the table view, things will crash within system code.
	This crash is evident in many versions of Adium.  When renaming the last contact on the contact list to the name
	of a contact who already exists on the list, Adium will delete the original contact, reducing the # of rows in
	the outline view in the midst of the cell editing, causing the crash.  The fix is to delay reloading until editing
	of the last row is complete.  As an added benefit, we skip the delayed reloading if the outline view had been
	reloaded since the edit, and the reload is no longer necessary.
	*/
    if([self numberOfRows] != 0 && ([self editedRow] == [self numberOfRows] - 1) && !needsReload){
        needsReload = YES;
        [self performSelector:@selector(_reloadData) withObject:nil afterDelay:0.0001];
		
    }else{
        needsReload = NO;
#warning I think selected items needs to be monitored at the time selections are made and removed... this crashes.
//		selectedItems = [self arrayOfSelectedItems];
		[super reloadData];
	
		//After reloading data, we correctly expand/collapse all groups
		if([[self delegate] respondsToSelector:@selector(outlineView:expandStateOfItem:)]){
			id		delegate = [self delegate];
			int 	numberOfRows = [delegate outlineView:self numberOfChildrenOfItem:nil];
			int 	row;
			
			//go through all items
			for(row = 0; row < numberOfRows; row++){
				id item = [delegate outlineView:self child:row ofItem:nil];
				
				//If the item is expandable, correctly expand/collapse it
				if([delegate outlineView:self isItemExpandable:item]){
					ignoreExpandCollapse = YES;
					if([delegate outlineView:self expandStateOfItem:item]){
						[self expandItem:item];
					}else{
						[self collapseItem:item];
					}
					ignoreExpandCollapse = NO;
				}
			}
		}
		
		//Restore (if possible) the previously selected objects
//		[self selectItemsInArray:selectedItems];
	}
}

//Here we skip the delayed reload if another reload has already occured before the delay could fire
- (void)_reloadData{
    if(needsReload) [self reloadData];
}

//Preserve selection through a reload
- (void)reloadItem:(id)item reloadChildren:(BOOL)reloadChildren
{
	//See warning in -(void)reloadData
//	NSArray		*selectedItems = [self arrayOfSelectedItems];

	[super reloadItem:item reloadChildren:reloadChildren];
	
	//Restore (if possible) the previously selected object
//	[self selectItemsInArray:selectedItems];
}

#pragma mark Dragging
//Draging ------------------------------------------
//Invoked in the dragging source as the drag ends
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{	
	if ([[self delegate] respondsToSelector:@selector(outlineView:draggedImage:endedAt:operation:)]){
		[[self delegate] outlineView:self draggedImage:image endedAt:screenPoint operation:operation];
	}
}

//Prevent dragging of items to another application
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return(isLocal ? NSDragOperationEvery : NSDragOperationNone);
}

@end
