//
//  AIListController.m
//  Adium
//
//  Created by Evan Schoenberg on 9/9/04.
//

#import "AIListController.h"

#define EDGE_CATCH_X				10
#define EDGE_CATCH_Y				40

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
    [self contactListChanged:nil];
	
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contactListDesiredSizeChanged:)
												 name:AIViewDesiredSizeDidChangeNotification
											   object:contactListView];

	return(self);
}

- (void)dealloc
{
    //Stop observing
    [[adium notificationCenter] removeObserver:self];
	
	[super dealloc];
}

//Resizing And Positioning ---------------------------------------------------------------------------------------------
#pragma mark Resizing And Positioning
//Dynamically resize the contact list
- (void)contactListDesiredSizeChanged:(NSNotification *)notification
{
    if(autoResizeVertically || autoResizeHorizontally){
		NSWindow	*theWindow = [contactListView window];
		
		NSRect  currentFrame = [theWindow frame];
        NSRect	desiredFrame = [self _desiredWindowFrameUsingDesiredWidth:(autoResizeHorizontally || (forcedWindowWidth != -1))
															desiredHeight:autoResizeVertically];

		if(!NSEqualRects(currentFrame, desiredFrame)){
			[theWindow setFrame:desiredFrame display:YES animate:NO];
			[theWindow setMinSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : minWindowSize.width),
											 (autoResizeVertically ? desiredFrame.size.height : minWindowSize.height))];
			[theWindow setMaxSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : 10000),
											 (autoResizeVertically ? desiredFrame.size.height : 10000))];
		}
    }
}

//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return([self _desiredWindowFrameUsingDesiredWidth:YES desiredHeight:YES]);
}

//Desired frame of our window - if one of the BOOL values is NO, don't modify that value from the current frame
- (NSRect)_desiredWindowFrameUsingDesiredWidth:(BOOL)useDesiredWidth desiredHeight:(BOOL)useDesiredHeight
{
	NSRect      windowFrame, viewFrame, newWindowFrame, screenFrame, visibleScreenFrame;
	NSWindow	*theWindow = [contactListView window];
	NSScreen	*currentScreen = [theWindow screen];
	
	windowFrame = [theWindow frame];
	newWindowFrame = windowFrame;//NSMakeRect(windowFrame, 0, windowFrame.size.width, windowFrame.size.height);
		viewFrame = [scrollView_contactList frame];
		
		screenFrame = [currentScreen frame];
		visibleScreenFrame = [currentScreen visibleFrame];
		
		//Width
		if(useDesiredWidth){
			if (forcedWindowWidth != -1){
				newWindowFrame.size.width = forcedWindowWidth;
			}else{
				//Subtract the current size of the view from our frame
				//newWindowSize.width -= viewFrame.size.width;
				newWindowFrame.size.width -= viewFrame.size.width;
				
				//Now, figure out how big the view wants to be and add that to our frame
				//newWindowSize.width += desiredViewSize.width;
				newWindowFrame.size.width += [contactListView desiredWidth];
				
				//Don't get bigger than our maxWindowWidth
				if (newWindowFrame.size.width > maxWindowWidth) newWindowFrame.size.width = maxWindowWidth;
				
				if ((windowFrame.origin.x + windowFrame.size.width) + EDGE_CATCH_X > (visibleScreenFrame.origin.x + visibleScreenFrame.size.width)){
					
					newWindowFrame.origin.x = windowFrame.origin.x + (windowFrame.size.width - newWindowFrame.size.width);
					if((newWindowFrame.origin.x + newWindowFrame.size.width) < (visibleScreenFrame.origin.x + EDGE_CATCH_X)){
						newWindowFrame.origin.x = visibleScreenFrame.origin.x - newWindowFrame.size.width + EDGE_CATCH_X;
					}
				}
			}
		}
		
		//Height
		if(useDesiredHeight){
			NSRect		applicableScreenFrame;
			
			//Subtract the current size of the view from our frame
			//newWindowSize.width -= viewFrame.size.width;
			newWindowFrame.size.height -= viewFrame.size.height;
			
			//Now, figure out how big the view wants to be and add that to our frame
			//newWindowSize.width += desiredViewSize.width;
			newWindowFrame.size.height += [contactListView desiredHeight];
			
			/* If the window is against the left or right edges of the screen, 
				use the screenFrame rather than the visibleScreenFrame as most users' docks do not extend all the way across
				the bottom. */
			if ((newWindowFrame.origin.x < screenFrame.origin.x + EDGE_CATCH_X) ||
				((newWindowFrame.origin.x + newWindowFrame.size.width) < (screenFrame.origin.x + screenFrame.size.width - EDGE_CATCH_X))){
				applicableScreenFrame = screenFrame;
			}else{
				applicableScreenFrame = visibleScreenFrame;
			}
			
			//Don't let the new frame be taller than the applicable screen frame's height.
			//		if (newWindowFrame.size.height > applicableScreenFrame.size.height){
			//			newWindowFrame.size.height = applicableScreenFrame.size.height;
			//		}
			
			//If the window is not near the bottom edge of the screen, or the titlebar is near the top,
			//keep the titlebar in place
			if((windowFrame.origin.y > applicableScreenFrame.origin.y + EDGE_CATCH_Y) ||
			   (windowFrame.origin.y + windowFrame.size.height > applicableScreenFrame.origin.y + applicableScreenFrame.size.height - EDGE_CATCH_Y)){
				newWindowFrame.origin.y = windowFrame.origin.y + (windowFrame.size.height - newWindowFrame.size.height);
			}else{
				newWindowFrame.origin.y = windowFrame.origin.y;
			}
			
			//If the new window frame has an origin below the applicable screen frame, correct the situation
			if (newWindowFrame.origin.y < applicableScreenFrame.origin.y + 1){
				newWindowFrame.origin.y = applicableScreenFrame.origin.y + 1;
			}
			
			//Keep the window from going off the top of the visible area (which means not under the menu bar, too)
			float visibleScreenTop = (visibleScreenFrame.origin.y+visibleScreenFrame.size.height);
			
			if((newWindowFrame.origin.y + newWindowFrame.size.height) > visibleScreenTop){
				//If the window would go above the top of the screen (the menu bar), set the origin to the origin of
				//whichever is our applicable screen...
				newWindowFrame.origin.y = applicableScreenFrame.origin.y + 1;
				//...and set our height to the maximal height which will fit on the visible screen from that origin.
				newWindowFrame.size.height = visibleScreenTop - newWindowFrame.origin.y;
			}
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
	
	[self contactListDesiredSizeChanged:nil];
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
}

//Redisplay the modified object (Attribute change)
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*object = [notification object];
    NSArray			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
    //Redraw the modified object
	[contactListView redisplayItem:object];
	
    //Resize the contact list horizontally
    if(autoResizeHorizontally){
		if (object){
			if([keys containsObject:@"Display Name"] || [keys containsObject:@"Left View"] ||
			   [keys containsObject:@"Right View"] || [keys containsObject:@"Right Text"] ||
			   [keys containsObject:@"Left Text"]){
#warning ###				[contactListView updateHorizontalSizeForObject:object];
			}
		}else{
#warning ###			[contactListView _performFullRecalculation];	
		}
    }
}

//
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{    
	//Reftesh
	[contactListView setNeedsDisplay:YES];
	
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
			if(index == -1 && ![item isKindOfClass:[AIListGroup class]]){
				[outlineView setDropItem:[item containingObject] dropChildIndex:[[item containingObject] indexOfObject:item]];
			}
			
		}
		
		if(index == -1 && ![item isKindOfClass:[AIListGroup class]]){
			return(NSDragOperationNone);
		}
	}
	
	return(NSDragOperationPrivate);
}

//
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
    NSString	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
    
	//No longer in a drag, so allow tooltips again
    if([availableType isEqualToString:@"AIListObject"]){
		//The tree root is not associated with our root contact list group, so we need to make that association here
		if(item == nil) item = contactList;
		
		//Move the list object to its new location
		if([item isKindOfClass:[AIListGroup class]]){
			[[adium contactController] moveListObjects:dragItems toGroup:item index:index];
		}
	}
	
	[super outlineView:outlineView acceptDrop:info item:item childIndex:index];
	
    return(YES);
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	[self contactListDesiredSizeChanged:nil];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	[self contactListDesiredSizeChanged:nil];
}

@end
