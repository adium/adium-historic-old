//
//  AIListController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/9/04.
//

#import "AIListController.h"

#define EDGE_CATCH_X				40
#define EDGE_CATCH_Y				40

#define	MENU_BAR_HEIGHT				22

#define KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN		@"Contact List Docked To Bottom"

typedef enum {
	AIDockToBottom_No = 0,
    AIDockToBottom_VisibleFrame,
	AIDockToBottom_TotalFrame
} DOCK_BOTTOM_TYPE;

@interface AIListController (PRIVATE)
- (NSRect)_desiredWindowFrameUsingDesiredWidth:(BOOL)useDesiredWidth desiredHeight:(BOOL)useDesiredHeight;
- (void)contactListChanged:(NSNotification *)notification;
@end

@implementation AIListController

- (id)initWithContactListView:(AIListOutlineView *)inContactListView inScrollView:(AIAutoScrollView *)inScrollView_contactList delegate:(id<AIListControllerDelegate>)inDelegate
{
	[super initWithContactListView:inContactListView inScrollView:inScrollView_contactList delegate:inDelegate];
	
	[contactListView setDrawHighlightOnlyWhenMain:YES];

    autoResizeVertically = NO;
    autoResizeHorizontally = NO;
	maxWindowWidth = 10000;
	forcedWindowWidth = -1;
	
	//Observe contact list content and display changes
	[[adium notificationCenter] addObserver:self selector:@selector(contactListChanged:) 
									   name:Contact_ListChanged
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactOrderChanged:)
									   name:Contact_OrderChanged 
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:nil];

	//Observe group expansion for resizing
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outlineViewUserDidExpandItem:)
												 name:AIOutlineViewUserDidExpandItemNotification
											   object:contactListView];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outlineViewUserDidCollapseItem:)
												 name:AIOutlineViewUserDidCollapseItemNotification
											   object:contactListView];
	
	//Observe list objects for visiblity changes
	[[adium contactController] registerListObjectObserver:self];

	//Recall how the contact list was docked last time Adium was open
	dockToBottomOfScreen = [[[adium preferenceController] preferenceForKey:KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN
																	group:PREF_GROUP_WINDOW_POSITIONS] intValue];

	[self contactListChanged:nil];
	
	return(self);
}

//Setup the window after it has loaded
- (void)configureViewsAndTooltips
{
	[super configureViewsAndTooltips];
	
	//Listen to when the list window moves (so we can remember which edge we're docked to)
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidMove:)
												 name:NSWindowDidMoveNotification
											   object:[contactListView window]];
}

- (void)dealloc
{
	//Remember how the contact list is currently docked for next time
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:dockToBottomOfScreen]
										 forKey:KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN
										  group:PREF_GROUP_WINDOW_POSITIONS];
	
    //Stop observing
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[adium contactController] unregisterListObjectObserver:self];
	
	[super dealloc];
}

//Resizing And Positioning ---------------------------------------------------------------------------------------------
#pragma mark Resizing And Positioning
//Dynamically resize the contact list
- (void)contactListDesiredSizeChanged
{
    if(autoResizeVertically || autoResizeHorizontally){
		NSWindow	*theWindow = [contactListView window];
		
		NSRect  currentFrame = [theWindow frame];
        NSRect	desiredFrame = [self _desiredWindowFrameUsingDesiredWidth:(autoResizeHorizontally || (forcedWindowWidth != -1))
															desiredHeight:autoResizeVertically];

		if(!NSEqualRects(currentFrame, desiredFrame)){
			//We must set the min/max first, otherwise our setFrame will be restricted by them and not produce the
			//expected results
			[theWindow setMinSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : minWindowSize.width),
											 (autoResizeVertically ? desiredFrame.size.height : minWindowSize.height))];
			[theWindow setMaxSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : 10000),
											 (autoResizeVertically ? desiredFrame.size.height : 10000))];

			[theWindow setFrame:desiredFrame display:YES animate:NO];
		}
    }
}

//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return([self _desiredWindowFrameUsingDesiredWidth:YES desiredHeight:YES]);
}

//Window moved, remember which side the user has docked it to
- (void)windowDidMove:(NSNotification *)notification
{
	NSWindow	*theWindow = [contactListView window];
	NSRect		windowFrame = [theWindow frame];
	NSScreen	*theWindowScreen = [theWindow screen];

	NSRect		boundingFrame = [theWindowScreen frame];
	NSRect		visibleBoundingFrame = [theWindowScreen visibleFrame];
	
	//First, see if they are now within EDGE_CATCH_Y of the total boundingFrame
	if((windowFrame.origin.y < boundingFrame.origin.y + EDGE_CATCH_Y) &&
	   (windowFrame.origin.y + windowFrame.size.height < boundingFrame.origin.y + boundingFrame.size.height - EDGE_CATCH_Y)){
		dockToBottomOfScreen = AIDockToBottom_TotalFrame;
	}else{
		//Then, check for the (possibly smaller) visibleBoundingFrame
		if((windowFrame.origin.y < visibleBoundingFrame.origin.y + EDGE_CATCH_Y) &&
		   (windowFrame.origin.y + windowFrame.size.height < visibleBoundingFrame.origin.y + visibleBoundingFrame.size.height - EDGE_CATCH_Y)){
			dockToBottomOfScreen = AIDockToBottom_VisibleFrame;
		}else{
			dockToBottomOfScreen = AIDockToBottom_No;
		}
	}
}


//Desired frame of our window - if one of the BOOL values is NO, don't modify that value from the current frame
- (NSRect)_desiredWindowFrameUsingDesiredWidth:(BOOL)useDesiredWidth desiredHeight:(BOOL)useDesiredHeight
{
	NSRect      windowFrame, viewFrame, newWindowFrame, screenFrame, visibleScreenFrame, boundingFrame;
	NSWindow	*theWindow = [contactListView window];
	NSScreen	*currentScreen = [theWindow screen];

	windowFrame = [theWindow frame];
	newWindowFrame = windowFrame;
	viewFrame = [scrollView_contactList frame];
	screenFrame = [currentScreen frame];
	visibleScreenFrame = [currentScreen visibleFrame];

	//Width
	if(useDesiredWidth){
		if(forcedWindowWidth != -1){
			//If auto-sizing is disabled, use the specified width
			newWindowFrame.size.width = forcedWindowWidth;
		}else{
			//Subtract the current size of the view from our frame
			newWindowFrame.size.width -= viewFrame.size.width;
			
			//Now, figure out how big the view wants to be and add that to our frame
			newWindowFrame.size.width += [contactListView desiredWidth];

			//Don't get bigger than our maxWindowWidth
			if(newWindowFrame.size.width > maxWindowWidth){
				newWindowFrame.size.width = maxWindowWidth;
			}else if(newWindowFrame.size.width < 0){
				newWindowFrame.size.width = 0;	
			}

			//Anchor to the appropriate screen edge
			if((windowFrame.origin.x + windowFrame.size.width) + EDGE_CATCH_X > (visibleScreenFrame.origin.x + visibleScreenFrame.size.width)){
				newWindowFrame.origin.x = (windowFrame.origin.x + windowFrame.size.width) - newWindowFrame.size.width;
			}else{
				newWindowFrame.origin.x = windowFrame.origin.x;

			}
		}		
	}
	
	/*
	 If the window is against the left or right edges of the screen AND the user did not dock to the visibleFrame last,
		we use the full screenFrame as our bound.
	 The edge check is used since most users' docks will not extend to the edges of the screen.
	 Alternately, if the user docked to the total frame last, we can safely use the full screen even if we aren't
		on the edge.
	*/
	BOOL windowOnEdge = ((newWindowFrame.origin.x < screenFrame.origin.x + EDGE_CATCH_X) ||
						 ((newWindowFrame.origin.x + newWindowFrame.size.width) > (screenFrame.origin.x + screenFrame.size.width - EDGE_CATCH_X)));
	if((windowOnEdge && (dockToBottomOfScreen != AIDockToBottom_VisibleFrame)) ||
	   (dockToBottomOfScreen == AIDockToBottom_TotalFrame)){
		NSArray *screens;
		
		boundingFrame = screenFrame;
		
		//We still cannot violate the menuBar, so account for it here if we are on the menuBar screen.
		if ((screens = [NSScreen screens]) &&
			([screens count]) &&
			(currentScreen == [screens objectAtIndex:0])){
			boundingFrame.size.height -= MENU_BAR_HEIGHT;
		}
		
	}else{
		boundingFrame = visibleScreenFrame;
	}
	
	//Height
	if(useDesiredHeight){
		//Subtract the current size of the view from our frame
		newWindowFrame.size.height -= viewFrame.size.height;
		
		//Now, figure out how big the view wants to be and add that to our frame
		newWindowFrame.size.height += [contactListView desiredHeight];
		
		//Vertical positioning and size if we are placed on a screen
		if(newWindowFrame.size.height >= boundingFrame.size.height){
			//If the window is bigger than the screen, keep it on the screen
			newWindowFrame.size.height = boundingFrame.size.height;
			newWindowFrame.origin.y = boundingFrame.origin.y;
		}else{
			//A Non-full height window is anchrored to the appropriate screen edge
			if(dockToBottomOfScreen == AIDockToBottom_No){
				//If the user did not dock to the bottom in any way last, the origin should move up
				newWindowFrame.origin.y = (windowFrame.origin.y + windowFrame.size.height) - newWindowFrame.size.height;
			}else{
				//If the user did dock (either to the full screen or the visible screen), the origin should remain in place.
				newWindowFrame.origin.y = windowFrame.origin.y;				
			}
		}
		
		//We must never request a height of 0 or OS X will completely move us off the screen
		if(newWindowFrame.size.height == 0) newWindowFrame.size.height = 1;

		//Keep the window from hanging off any Y screen edge (This is optional and could be removed if this annoys people)
		if(NSMaxY(newWindowFrame) > NSMaxY(boundingFrame)) newWindowFrame.origin.y = NSMaxY(boundingFrame) - newWindowFrame.size.height;
		if(NSMinY(newWindowFrame) < NSMinY(boundingFrame)) newWindowFrame.origin.y = NSMinY(boundingFrame);			
	}

	if(useDesiredWidth){
		//We must never request a width of 0 or OS X will completely move us off the screen
		if(newWindowFrame.size.width == 0) newWindowFrame.size.width = 1;

		//Keep the window from hanging off any X screen edge (This is optional and could be removed if this annoys people)
		if(NSMaxX(newWindowFrame) > NSMaxX(boundingFrame)) newWindowFrame.origin.x = NSMaxX(boundingFrame) - newWindowFrame.size.width;
		if(NSMinX(newWindowFrame) < NSMinX(boundingFrame)) newWindowFrame.origin.x = NSMinX(boundingFrame);
	}

	return(newWindowFrame);
}

- (void)setMinWindowSize:(NSSize)inSize {
	minWindowSize = inSize;
}
- (void)setMaxWindowWidth:(int)inWidth {
	maxWindowWidth = inWidth;
}
- (void)setAutoresizeHorizontally:(BOOL)flag {
	autoResizeHorizontally = flag;
}
- (void)setAutoresizeVertically:(BOOL)flag {
	autoResizeVertically = flag;	
}
- (void)setForcedWindowWidth:(int)inWidth {
	forcedWindowWidth = inWidth;
}

//Content Updating -----------------------------------------------------------------------------------------------------
#pragma mark Content Updating
//Reload the contact list
- (void)contactListChanged:(NSNotification *)notification
{
	id		object = [notification object];

	//Redisplay and resize
	if(!object || object == contactList){
		[self setContactListRoot:[[adium contactController] contactList]];
	}else{
		NSDictionary	*userInfo = [notification userInfo];
		AIListGroup		*containingGroup = [userInfo objectForKey:@"ContainingGroup"];

		if(!containingGroup || containingGroup == contactList){
			//Reload the whole tree if the containing group is our root
			[contactListView reloadData];
		}else{
			//We need to reload the contaning group since this notification is posted when adding and removing objects.
			//Reloading the actual object that changed will produce no results since it may not be on the list.
			[contactListView reloadItem:containingGroup reloadChildren:YES];
		}
	}

	[self contactListDesiredSizeChanged];
}

//Update auto-resizing when object visibility changes
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if([inModifiedKeys containsObject:@"VisibleObjectCount"]){
		//If the visible count changes, we'll need to resize our list - but we wait until the group is resorted
		//to actually perform the resizing.  This prevents the scrollbar from flickering up and some issues with
		//us resizing before the outlineview is aware that the view has grown taller/shorter.
		needsAutoResize = YES;
	}

	return(nil);
}

//Update the contact list (if updates aren't delayed)
- (void)contactOrderChanged:(NSNotification *)notification
{
	id		object = [[notification object] containingObject];

	//The notification passes the contact who's order changed.  This means that we must reload the group containing
	//that contact in order to correctly update the list.
	if(!object || (object == contactList)){ //Treat a nil object as equivalent to the contact list
		[contactListView reloadData];
	}else{
		[contactListView reloadItem:object reloadChildren:YES];
	}

	//If we need a resize we can do that now that the outline view has been reloaded
	if(needsAutoResize){
		[self contactListDesiredSizeChanged];
		needsAutoResize = NO;
	}
}

//Redisplay the modified object (Attribute change)
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*object = [notification object];
    NSSet			*keys = [[notification userInfo] objectForKey:@"Keys"];

	//Redraw the modified object (or the whole list, if object is nil)
	[contactListView redisplayItem:object];

    //Resize the contact list horizontally
    if(autoResizeHorizontally){
		if(([keys containsObject:@"Display Name"] || [keys containsObject:@"Long Display Name"])){
			[self contactListDesiredSizeChanged];
		}
    }
}

//
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{    
    //Post a 'contact list selection changed' notification on the interface center
	//If we post this notification immediately, our outline view may not yet be key, and contact controller
	//will return nil for 'selectedListObject'.  If we wait until we're back in the main run loop, the
	//outline view will be set as key for certain, and everything will work as expected.
	[self performSelector:@selector(_delayedNotify) withObject:nil afterDelay:0.0001];
}
- (void)_delayedNotify{
	[[adium notificationCenter] postNotificationName:Interface_ContactSelectionChanged object:nil];
}

//
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
	BOOL		allowContactDrop = ([info draggingSourceOperationMask] == NSDragOperationCopy);
	
	//No dropping into contacts
    if([avaliableType isEqualToString:@"AIListObject"]){
		id	primaryDragItem = [dragItems objectAtIndex:0];
		
		if([primaryDragItem isKindOfClass:[AIListGroup class]]){
			//Disallow dragging groups into or onto other objects
			if(item != nil){
				if([item isKindOfClass:[AIListGroup class]]){
					[outlineView setDropItem:nil dropChildIndex:[[item containingObject] indexOfObject:item]];
				}else{
					[outlineView setDropItem:nil dropChildIndex:[[[item containingObject] containingObject] indexOfObject:[item containingObject]]];
				}
			}
			
		}else{
			//Disallow dragging contacts onto anything besides a group
			if(index == NSOutlineViewDropOnItemIndex && ![item isKindOfClass:[AIListGroup class]]){
				if (allowContactDrop){
					[outlineView setDropItem:item dropChildIndex:NSOutlineViewDropOnItemIndex];
				}else{
					AIListObject	*containingObject = [item containingObject];
					[outlineView setDropItem:((containingObject == contactList) ? nil : containingObject)
							  dropChildIndex:[[item containingObject] indexOfObject:item]];
				}
			}
			
		}
		
		if(index == NSOutlineViewDropOnItemIndex && ![item isKindOfClass:[AIListGroup class]]){
			return(allowContactDrop ? NSDragOperationCopy : NSDragOperationNone);
		}
	}
	
	return(NSDragOperationPrivate);
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
    NSString	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
    if([availableType isEqualToString:@"AIListObject"]){
		//The tree root is not associated with our root contact list group, so we need to make that association here
		if(item == nil) item = contactList;
		
		//Move the list object to its new location
		if([item isKindOfClass:[AIListGroup class]]){
			[[adium contactController] moveListObjects:dragItems toGroup:item index:index];
			
		}else if ([item isKindOfClass:[AIListContact class]]){
			AIMetaContact						*metaContact;
			AIListObject<AIContainingObject> 	*oldContainingObject;
			float								oldIndex;

			//Keep track of where it was before
			oldContainingObject = [[item containingObject] retain];;
			oldIndex = [item orderIndex];
			
			//Group the dragged items plus the destination into a metaContact
			metaContact = [[adium contactController] groupListContacts:[dragItems arrayByAddingObject:item]];
			
			//Position the metaContact in the group & index the drop point was before
			[[adium contactController] moveListObjects:[NSArray arrayWithObject:metaContact] toGroup:oldContainingObject index:oldIndex];
			
			[oldContainingObject release];
		}
	}
	
	[super outlineView:outlineView acceptDrop:info item:item childIndex:index];
	
    return(YES);
}

- (void)outlineViewUserDidExpandItem:(NSNotification *)notification
{
	[self contactListDesiredSizeChanged];
}

- (void)outlineViewUserDidCollapseItem:(NSNotification *)notification
{
	[self contactListDesiredSizeChanged];
}

@end
