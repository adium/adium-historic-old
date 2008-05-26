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

#import "AIListController.h"
#import "AIAnimatingListOutlineView.h"
#import "AIListWindowController.h"
#import <Adium/AIChat.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AISortController.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListOutlineView.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIFunctions.h>

#define EDGE_CATCH_X						40.0f
#define EDGE_CATCH_Y						40.0f

#define	MENU_BAR_HEIGHT				22

#define KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN	[NSString stringWithFormat:@"Contact List Docked To Bottom:%@", [[self contactList] contentsBasedIdentifier]]

#define PREF_GROUP_APPEARANCE		@"Appearance"

@interface AIListController (PRIVATE)
- (void)contactListChanged:(NSNotification *)notification;
@end

@implementation AIListController


- (id)initWithContactList:(AIListObject<AIContainingObject> *)aContactList
			inOutlineView:(AIListOutlineView *)inContactListView
			 inScrollView:(AIAutoScrollView *)inScrollView_contactList
				 delegate:(id<AIListControllerDelegate>)inDelegate
{
	if ((self = [self initWithContactListView:inContactListView inScrollView:inScrollView_contactList delegate:inDelegate])) {
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
		
		[contactListView addObserver:self
						  forKeyPath:@"desiredHeight" 
							 options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) 
							 context:NULL];
		
		[self setContactListRoot:(aContactList ? aContactList : [[adium contactController] contactList])];

		//Recall how the contact list was docked last time Adium was open
		dockToBottomOfScreen = [[[adium preferenceController] preferenceForKey:KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN
																		 group:PREF_GROUP_WINDOW_POSITIONS] intValue];
		
		//Observe preference changes
		[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	}

	return self;
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

- (void)close
{	
    //Stop observing
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[adium preferenceController] unregisterPreferenceObserver:self];

	[self autorelease];
}

- (void)dealloc
{
	[contactListView removeObserver:self forKeyPath:@"desiredHeight"];
	
	[super dealloc];
}


- (void)preferencesChangedForGroup:(NSString *)group 
							   key:(NSString *)key
							object:(AIListObject *)object 
					preferenceDict:(NSDictionary *)prefDict 
						 firstTime:(BOOL)firstTime
{
	[(AIAnimatingListOutlineView *)contactListView setEnableAnimation:[[prefDict objectForKey:KEY_CL_ANIMATE_CHANGES] boolValue]];
}

//Resizing And Positioning ---------------------------------------------------------------------------------------------
#pragma mark Resizing And Positioning
//Dynamically resize the contact list
- (void)contactListDesiredSizeChanged
{
	NSWindow	*theWindow;

    if ((autoResizeVertically || autoResizeHorizontally) &&
		(theWindow = [contactListView window]) &&
		[(AIListWindowController *)[theWindow windowController] windowSlidOffScreenEdgeMask] == AINoEdges) {
		
		NSRect  currentFrame = [theWindow frame];
        NSRect	desiredFrame = [self _desiredWindowFrameUsingDesiredWidth:(autoResizeHorizontally || (forcedWindowWidth != -1))
															desiredHeight:autoResizeVertically];

		if (!NSEqualRects(currentFrame, desiredFrame)) {
			//We must set the min/max first, otherwise our setFrame will be restricted by them and not produce the
			//expected results
			float toolbarHeight = (autoResizeVertically ? [theWindow toolbarHeight] : 0);
			
			[theWindow setMinSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : minWindowSize.width),
											 (autoResizeVertically ? (desiredFrame.size.height - toolbarHeight) : minWindowSize.height))];
			[theWindow setMaxSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : 10000),
											 (autoResizeVertically ? (desiredFrame.size.height - toolbarHeight) : 10000))];

			[theWindow setFrame:desiredFrame display:YES animate:NO];
		}
    }
}

/*!
 * @brief The window will be sliding on screen momentarily
 *
 * This is sent by the AIListWindowController. We take this opportunity to perform autosizing as appropriate.
 * The window is actually off-screen and should remain as such; we therefore perform sizing but maintain an appropriate origin such that
 * the window won't be seen.
 */
- (void)contactListWillSlideOnScreen
{
	NSWindow	*theWindow;
	
    if ((autoResizeVertically || autoResizeHorizontally) &&
		(theWindow = [contactListView window])) {
		NSRect currentFrame, savedFrame, desiredFrame;
		
		
		currentFrame = [theWindow frame];
		/* Pretend, for autosizing purposes, we're where we'll be once we're done sliding on screen. This allows sizing relative to screen edges and the dock
		 * to work properly. We'll return to our previous origin after performing size checking.
		 */
		savedFrame = [(AIListWindowController *)[theWindow windowController] savedFrame];
		[theWindow setFrame:savedFrame display:NO animate:NO];
        
		desiredFrame = [self _desiredWindowFrameUsingDesiredWidth:(autoResizeHorizontally || (forcedWindowWidth != -1))
													desiredHeight:autoResizeVertically];

		if (!NSEqualRects(savedFrame, desiredFrame)) {
			/* We must set the min/max first, otherwise our setFrame will be restricted by them and not produce the
			 * expected results
			 */
			float toolbarHeight = (autoResizeVertically ? [theWindow toolbarHeight] : 0);
			NSRect offscreenFrame = desiredFrame;
			[theWindow setMinSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : minWindowSize.width),
											 (autoResizeVertically ? (desiredFrame.size.height - toolbarHeight) : minWindowSize.height))];
			[theWindow setMaxSize:NSMakeSize((autoResizeHorizontally ? desiredFrame.size.width : 10000),
											 (autoResizeVertically ? (desiredFrame.size.height - toolbarHeight) : 10000))];

			//Adjust the origin to remain offscreen
			offscreenFrame.origin.x = NSMinX(currentFrame);

			if ([(AIListWindowController *)[theWindow windowController] windowSlidOffScreenEdgeMask] & AIMinXEdgeMask) {
				offscreenFrame.origin.x -= NSWidth(desiredFrame) - NSWidth(currentFrame);
			}

			[theWindow setFrame:offscreenFrame display:NO animate:NO];

			//Note the new desired frame so that we'll slide to that position
			[(AIListWindowController *)[theWindow windowController] setSavedFrame:desiredFrame];

		} else {
			//Nothing to do. Return to our actual current frame, unchanged.
			[theWindow setFrame:currentFrame display:NO animate:NO];
		}
    }
}

//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return [self _desiredWindowFrameUsingDesiredWidth:YES desiredHeight:YES];
}

//Window moved, remember which side the user has docked it to
- (void)windowDidMove:(NSNotification *)notification
{
	NSWindow	*theWindow = [contactListView window];
	NSRect		windowFrame = [theWindow frame];
	NSScreen	*theWindowScreen = [theWindow screen];

	NSRect		boundingFrame = [theWindowScreen frame];
	NSRect		visibleBoundingFrame = [theWindowScreen visibleFrame];
	
	AIDockToBottomType oldDockToBottom = dockToBottomOfScreen;

	//First, see if they are now within EDGE_CATCH_Y of the total boundingFrame
	if ((windowFrame.origin.y < boundingFrame.origin.y + EDGE_CATCH_Y) &&
	   ((windowFrame.origin.y + windowFrame.size.height) < (boundingFrame.origin.y + boundingFrame.size.height - EDGE_CATCH_Y))) {
		dockToBottomOfScreen = AIDockToBottom_TotalFrame;
			} else {
		//Then, check for the (possibly smaller) visibleBoundingFrame
		if ((windowFrame.origin.y < visibleBoundingFrame.origin.y + EDGE_CATCH_Y) &&
		   ((windowFrame.origin.y + windowFrame.size.height) < (visibleBoundingFrame.origin.y + visibleBoundingFrame.size.height - EDGE_CATCH_Y))) {
			dockToBottomOfScreen = AIDockToBottom_VisibleFrame;
		} else {
			dockToBottomOfScreen = AIDockToBottom_No;
		}
	}

	//Remember how the contact list is currently docked for next time
	if (oldDockToBottom != dockToBottomOfScreen) {
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:dockToBottomOfScreen]
											 forKey:KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN
											  group:PREF_GROUP_WINDOW_POSITIONS];
	}
}

//Desired frame of our window - if one of the BOOL values is NO, don't modify that value from the current frame
- (NSRect)_desiredWindowFrameUsingDesiredWidth:(BOOL)useDesiredWidth desiredHeight:(BOOL)useDesiredHeight
{
	NSRect      windowFrame, viewFrame, newWindowFrame, screenFrame, visibleScreenFrame, boundingFrame;
	NSWindow	*theWindow = [contactListView window];
	NSScreen	*currentScreen = [theWindow screen];
	int			desiredHeight = [contactListView desiredHeight];
	BOOL		anchorToRightEdge = NO;
	
	windowFrame = [theWindow frame];
	newWindowFrame = windowFrame;
	viewFrame = [scrollView_contactList frame];
	
	if (!currentScreen) currentScreen = [(AIListWindowController *)[theWindow windowController] windowLastScreen];
	if (!currentScreen) currentScreen = [NSScreen mainScreen];

	screenFrame = [currentScreen frame]; 
	visibleScreenFrame = [currentScreen visibleFrame];
	
    //Width
	if (useDesiredWidth) {
		if (forcedWindowWidth != -1) {
			//If auto-sizing is disabled, use the specified width
			newWindowFrame.size.width = forcedWindowWidth;
		} else {
			/* Using horizontal auto-sizing, so find and determine our new width
			 *
			 * First, subtract the current size of the view from our frame
			 */
			newWindowFrame.size.width -= viewFrame.size.width;
			
			//Now, figure out how big the view wants to be and add that to our frame
			newWindowFrame.size.width += [contactListView desiredWidth];
			
			//Don't get bigger than our maxWindowWidth
			if (newWindowFrame.size.width > maxWindowWidth) {
				newWindowFrame.size.width = maxWindowWidth;
			} else if (newWindowFrame.size.width < 0) {
				newWindowFrame.size.width = 0;	
			}
		}

		//Anchor to the appropriate screen edge
		anchorToRightEdge = ((currentScreen && ((NSMaxX(windowFrame) + EDGE_CATCH_X) >= NSMaxX(visibleScreenFrame))) ||
							 [(AIListWindowController *)[theWindow windowController] windowSlidOffScreenEdgeMask] == AIMaxXEdgeMask);
		if (anchorToRightEdge) {
			newWindowFrame.origin.x = NSMaxX(windowFrame) - NSWidth(newWindowFrame);
		} else {
			newWindowFrame.origin.x = NSMinX(windowFrame);
		}
	}

	/*
	 * Compute boundingFrame for window
	 *
	 * If the window is against the left or right edges of the screen AND the user did not dock to the visibleFrame last,
	 * we use the full screenFrame as our bound.
	 * The edge check is used since most users' docks will not extend to the edges of the screen.
	 * Alternately, if the user docked to the total frame last, we can safely use the full screen even if we aren't
	 * on the edge.
	 */
	BOOL windowOnEdge = ((NSMinX(newWindowFrame) < NSMinX(screenFrame) + EDGE_CATCH_X) ||
						 (NSMaxX(newWindowFrame) > (NSMaxX(screenFrame) - EDGE_CATCH_X)));

	if ((windowOnEdge && (dockToBottomOfScreen != AIDockToBottom_VisibleFrame)) ||
	   (dockToBottomOfScreen == AIDockToBottom_TotalFrame)) {
		NSArray *screens;

		boundingFrame = screenFrame;

		//We still should not violate the menuBar, so account for it here if we are on the menuBar screen.
		if ((screens = [NSScreen screens]) &&
			([screens count]) &&
			(currentScreen == [screens objectAtIndex:0])) {
			boundingFrame.size.height -= MENU_BAR_HEIGHT;
		}

	} else {
		boundingFrame = visibleScreenFrame;
	}

	//Height
	if (useDesiredHeight) {
		//Subtract the current size of the view from our frame
		newWindowFrame.size.height -= viewFrame.size.height;

		//Now, figure out how big the view wants to be and add that to our frame
		newWindowFrame.size.height += desiredHeight;

		//Vertical positioning and size if we are placed on a screen
		if (NSHeight(newWindowFrame) >= NSHeight(boundingFrame)) {
			//If the window is bigger than the screen, keep it on the screen
			newWindowFrame.size.height = NSHeight(boundingFrame);
			newWindowFrame.origin.y = NSMinY(boundingFrame);
		} else {
			//A non-full height window is anchored to the appropriate screen edge
			if (dockToBottomOfScreen == AIDockToBottom_No) {
				//If the user did not dock to the bottom in any way last, the origin should move up
				newWindowFrame.origin.y = NSMaxY(windowFrame) - NSHeight(newWindowFrame);
			} else {
				//If the user did dock (either to the full screen or the visible screen), the origin should remain in place.
				newWindowFrame.origin.y = NSMinY(windowFrame);	
			}
		}

		//We must never request a height of 0 or OS X will completely move us off the screen
		if (newWindowFrame.size.height == 0) newWindowFrame.size.height = 1;

		//Keep the window from hanging off any Y screen edge (This is optional and could be removed if this annoys people)
		if (NSMaxY(newWindowFrame) > NSMaxY(boundingFrame)) newWindowFrame.origin.y = NSMaxY(boundingFrame) - newWindowFrame.size.height;
		if (NSMinY(newWindowFrame) < NSMinY(boundingFrame)) newWindowFrame.origin.y = NSMinY(boundingFrame);		
	}

	if (useDesiredWidth) {
		/* If the desired height plus any toolbar height exceeds the height we determined, we will be showing a scroller; 
		 * expand horizontally to take that into account.  The magic number 2 fixes this method for use with our borderless
		 * windows... I'm not sure why it's needed, but it doesn't hurt anything.
		 */
		if (desiredHeight + (NSHeight(windowFrame) - NSHeight(viewFrame)) > NSHeight(newWindowFrame) + 2) {
			float scrollerWidth = [NSScroller scrollerWidthForControlSize:[[scrollView_contactList verticalScroller] controlSize]];
			newWindowFrame.size.width += scrollerWidth;
			
			if (anchorToRightEdge) {
				newWindowFrame.origin.x -= scrollerWidth;
			}
		}
		
		//We must never request a width of 0 or OS X will completely move us off the screen
		if (newWindowFrame.size.width == 0) newWindowFrame.size.width = 1;

		//Keep the window from hanging off any X screen edge (This is optional and could be removed if this annoys people)
		if (NSMaxX(newWindowFrame) > NSMaxX(boundingFrame)) newWindowFrame.origin.x = NSMaxX(boundingFrame) - NSWidth(newWindowFrame);
		if (NSMinX(newWindowFrame) < NSMinX(boundingFrame)) newWindowFrame.origin.x = NSMinX(boundingFrame);
	}
	
	return newWindowFrame;
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
/*!
 * @brief The entire contact list, or an entire group, changed
 *
 * This indicates that an entire group changed -- the contact list is just a giant group, so that includes the entire
 * contact list changing.  Reload the appropriate object.
 */
- (void)contactListChanged:(NSNotification *)notification
{
	id		object = [notification object];

	//Redisplay and resize
	if (!object || object == contactList) {
		[contactListView reloadData];

	} else {
		NSDictionary	*userInfo = [notification userInfo];
		AIListGroup		*containingGroup = [userInfo objectForKey:@"ContainingGroup"];

		if (!containingGroup || containingGroup == contactList) {
			//Reload the whole tree if the containing group is our root
			
		} else {
			/* We need to reload the contaning group since this notification is posted when adding and removing objects.
			 * Reloading the actual object that changed will produce no results since it may not be on the list.
			 */
			[contactListView reloadItem:containingGroup reloadChildren:YES];
		}
	}
}

- (AIListObject<AIContainingObject> *)contactList
{
	return contactList;
}

- (AIListOutlineView *)contactListView
{
	return contactListView;
}

/*!
 * @brief Order of contacts changed
 *
 * The notification's object is the contact whose order changed.  
 * We must reload the group containing that contact in order to correctly update the list.
 */
- (void)contactOrderChanged:(NSNotification *)notification
{
	id		object = [[notification object] containingObject];

	//Treat a nil object as equivalent to the whole contact list
	if (!object || (object == contactList)) {
		[contactListView reloadData];
	} else {
		[contactListView reloadItem:object reloadChildren:YES];
	}
}

/*!
 * @brief List object attributes changed
 *
 * Resize horizontally if desired and the display name changed
 */
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
	NSSet	*keys;
	
	[super listObjectAttributesChanged:notification];
	
    keys = [[notification userInfo] objectForKey:@"Keys"];

    //Resize the contact list horizontally
    if (autoResizeHorizontally) {
		if (([keys containsObject:@"Display Name"] || [keys containsObject:@"Long Display Name"])) {
			[self contactListDesiredSizeChanged];
		}
    }
}

/*!
 * @brief The outline view selection changed
 *
 * On the next run loop, post Interface_ContactSelectionChanged.  Why wait for the next run loop?
 * If we post this notification immediately, our outline view may not yet be key, and the contact controller
 * will return nil for 'selectedListObject'.  If we wait, the outline view will be definitely be set as key, and
 * everything will work as expected.
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{   
	[[adium notificationCenter] performSelector:@selector(postNotificationName:object:)
									 withObject:Interface_ContactSelectionChanged
									 withObject:nil
									 afterDelay:0];
}

#pragma mark Drag & Drop

/*! 
 * @brief Method to check if operations need to be performed
 */
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSArray			*types = [[info draggingPasteboard] types];
	NSDragOperation retVal = NSDragOperationNone;
	
	//No dropping into contacts
	BOOL allowBetweenContactDrop = (index == NSOutlineViewDropOnItemIndex);

	if ([types containsObject:@"AIListObject"]) {
		if (index != NSOutlineViewDropOnItemIndex && (![[[adium contactController] activeSortController] canSortManually])) {
			//Don't drag if automatic sort is on
			//disable drop between for non-Manual Sort.
			return NSDragOperationNone;
		}
		
		NSEnumerator *enumerator = [dragItems objectEnumerator];
		id			 dragItem;
		BOOL		 hasGroup = NO, hasNonGroup = NO;
		while ((dragItem = [enumerator nextObject])) {
			if ([dragItem isKindOfClass:[AIListGroup class]])
				hasGroup = YES;
			if (![dragItem isKindOfClass:[AIListGroup class]])
				hasNonGroup = YES;
			if (hasGroup && hasNonGroup) break;
		}
		
		//Don't allow a drop within the contact list or within a group if we contain a mixture of groups and non-groups (e.g. contacts)
		if (hasGroup && hasNonGroup) return NSDragOperationNone;
		
		id	primaryDragItem = [dragItems objectAtIndex:0];
		
		if ([primaryDragItem isKindOfClass:[AIListGroup class]]) {
			//Disallow dragging groups into or onto other objects
			if (item != nil) {
				if ([item isKindOfClass:[AIListGroup class]]) {
					// In between objects
					[outlineView setDropItem:nil dropChildIndex:[[item containingObject] indexOfObject:item]];
				} else {
					// On top of an object
					[outlineView setDropItem:nil dropChildIndex:[[[item containingObject] containingObject] indexOfObject:[item containingObject]]];
				}
			}
			
		} else {
			//We have one or more contacts. Don't allow them to drop on the contact list itself
			if (!item && [[adium contactController] useContactListGroups]) {
				/* The user is hovering on the contact list itself.
				 * If groups are shown at all, assuming we have any items in the list at all, she is hovering just below
				 * a group or an item in a group.
				 * Do this right by shifting the drop to object above.
				 */
				id itemAboveProposedIndex = [outlineView itemAtRow:(index - 1)];
				if (!itemAboveProposedIndex) {
					//At the very end, presumably
					itemAboveProposedIndex = [outlineView itemAtRow:([outlineView numberOfRows] - 1)];
				}
				
				if ([itemAboveProposedIndex isKindOfClass:[AIListGroup class]]) {
					[outlineView setDropItem:itemAboveProposedIndex dropChildIndex:NSOutlineViewDropOnItemIndex];
				} else {
					[outlineView setDropItem:[itemAboveProposedIndex containingObject] dropChildIndex:NSOutlineViewDropOnItemIndex];					
				}
				
			}
		}
		
		if ((index == NSOutlineViewDropOnItemIndex) && [item isKindOfClass:[AIListContact class]] && ([info draggingSource] == [self contactListView])) {
			//Dropping into a contact or attaching groups: Copy
			if (([contactListView rowForItem:primaryDragItem] == -1) ||
				[primaryDragItem isKindOfClass:[AIListContact class]]) {
				retVal = NSDragOperationCopy;
			} else {
				retVal = NSDragOperationMove;
			}
		
		} else {
			//Otherwise, it's either a move into a group or a manual reordering
			if (!item || [outlineView isExpandable:item]) {
				//Figure out where we would insert the dragged item if the sort controller manages the location and it's going into an expandable item
				AISortController *sortController = [[adium contactController] activeSortController];
				//XXX If we can sort manually but the sort controller also has some control (e.g. status sort with manual ordering), we should get a hint and make use of it.
				if (![sortController canSortManually]) {
					//If we're dragging a group, force a drop onto the contact list itself, and determine the destination location accordingly
					if ([primaryDragItem isKindOfClass:[AIListGroup class]]) item = nil;
					
					int indexForInserting = [sortController indexForInserting:[dragItems objectAtIndex:0]
																  intoObjects:(item ? [item containedObjects] : [[[adium contactController] contactList] containedObjects])];
					/*
					 For example, to specify a drop on an item I, you specify item as 1 and index as NSOutlineViewDropOnItemIndex.
					 To specify a drop between child 2 and 3 of item I, you specify item as I and index as 3 (children are a zero-based index).
					 To specify a drop on an unexpandable item 1, you specify item as I and index as NSOutlineViewDropOnItemIndex.
					 */
					[outlineView setDropItem:item dropChildIndex:indexForInserting];
				}
			}
			
			retVal = NSDragOperationPrivate;
		}

	} else if ([types containsObject:NSFilenamesPboardType] ||
			   [types containsObject:NSRTFPboardType] ||
			   [types containsObject:NSURLPboardType] ||
			   [types containsObject:NSStringPboardType]) {
		retVal = ((item && [item isKindOfClass:[AIListContact class]]) ? NSDragOperationLink : NSDragOperationNone);

	} else if (!allowBetweenContactDrop) {
		retVal = NSDragOperationNone;
	}

	return retVal;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	BOOL		success = YES;
	NSPasteboard *draggingPasteboard = [info draggingPasteboard];
	NSString	*availableType = [draggingPasteboard availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
    if ([availableType isEqualToString:@"AIListObject"]) {
		//Kill the selection now, (in a more finder-esque way)
		[outlineView deselectAll:nil];

		//The tree root is not associated with our root contact list group, so we need to make that association here
		if (item == nil) 
			item = contactList;

		//Move the list object to its new location
		if ([item isKindOfClass:[AIListGroup class]]) {
			if (item != [[adium contactController] offlineGroup]) {
				[[adium contactController] moveListObjects:dragItems intoObject:item index:index];
				
				[[adium notificationCenter] postNotificationName:@"Contact_ListChanged"
														  object:item
														userInfo:nil];
			} else {
				success = NO;
			}
			
		} else if ([item isMemberOfClass:[AIMetaContact class]]) {
			//Ordering gets implemented here.
			NSString	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
			
			//No longer in a drag, so allow tooltips again
			if ([availableType isEqualToString:@"AIListObject"]) {
				
				//If we don't have drag items, we are dragging from another instance; build our own dragItems array
				//using the supplied internalObjectIDs
				if (!dragItems) {
					if ([[[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObjectUniqueIDs"]] isEqualToString:@"AIListObjectUniqueIDs"]) {
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
					
					[[adium contactController] moveListObjects:realDragItems intoObject:item index:index];
					[outlineView reloadData];
				}
			}
			
			//Call super and return its value
			return [super outlineView:outlineView acceptDrop:info item:item childIndex:index];
			
			
		} else if ([item isKindOfClass:[AIListContact class]]) {
			NSString	*promptTitle;
			
			//Appropriate prompt
			if ([dragItems count] == 1) {
				promptTitle = [NSString stringWithFormat:AILocalizedString(@"Combine %@ and %@?","Title of the prompt when combining two contacts. Each %@ will be filled with a contact name."), [[dragItems objectAtIndex:0] displayName], [item displayName]];
			} else {
				promptTitle = [NSString stringWithFormat:AILocalizedString(@"Combine these contacts with %@?","Title of the prompt when combining two or more contacts with another.  %@ will be filled with a contact name."),[item displayName]];
			}
			
			//Metacontact creation, prompt the user
			NSDictionary	*context = [NSDictionary dictionaryWithObjectsAndKeys:
				item, @"item",
				dragItems, @"dragitems", nil];
			
			NSBeginInformationalAlertSheet(promptTitle,
										   AILocalizedString(@"Combine","Button title for accepting the action of combining multiple contacts into a metacontact"),
										   AILocalizedString(@"Cancel",nil),
										   nil,
										   nil,
										   self,
										   @selector(mergeContactSheetDidEnd:returnCode:contextInfo:),
										   nil,
										   [context retain], //we're responsible for retaining the content object
										   AILocalizedString(@"Once combined, Adium will treat these contacts as a single individual both on your contact list and when sending messages.\n\nYou may un-combine these contacts by getting info on the combined contact.","Explanation of metacontact creation"));
		}
	} else if ([[[info draggingPasteboard] types] containsObject:NSFilenamesPboardType]) {
		//Drag and Drop file transfer for the contact list.
		NSString		*file;
		NSArray			*files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		NSEnumerator	*enumerator = [files objectEnumerator];

		AIListContact	*targetFileTransferContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																							  forListContact:item];
		if (targetFileTransferContact) {
			while ((file = [enumerator nextObject])) {
				[[adium fileTransferController] sendFile:file toListContact:targetFileTransferContact];
			}
		} else {
			AILogWithSignature(@"No contact available to receive files");
			NSBeep();
		}

	} else if ([[[info draggingPasteboard] types] containsObject:NSRTFPboardType] ||
				[[[info draggingPasteboard] types] containsObject:NSURLPboardType] ||
				[[[info draggingPasteboard] types] containsObject:NSStringPboardType]) {
		//Drag and drop text sending via the contact list.
		if ([item isKindOfClass:[AIListContact class]]) {
			/* This will send the message. Alternately, we could just insert it into the text view... */
			AIChat							*chat;
			AIContentMessage				*messageContent;
			NSAttributedString				*messageAttributedString = nil;
			
			if([[[info draggingPasteboard] types] containsObject:NSRTFPboardType]) {
				//for RTF data, we want to preserve the formatting, so use dataForType:
				messageAttributedString = [NSAttributedString stringWithData:[[info draggingPasteboard] dataForType:NSRTFPboardType]];
			}
			else if([[[info draggingPasteboard] types] containsObject:NSURLPboardType]) {
				//NSURLPboardType contains an NSURL object
				messageAttributedString = [NSAttributedString stringWithString:[[NSURL URLFromPasteboard:[info draggingPasteboard]]absoluteString]];
			}
			else if([[[info draggingPasteboard] types] containsObject:NSStringPboardType]) {
				//this is just plain text, so stringForType: works fine
				messageAttributedString = [NSAttributedString stringWithString:[[info draggingPasteboard]stringForType:NSStringPboardType]];
			}
			
			if(messageAttributedString && [messageAttributedString length] !=0) {
				chat = [[adium chatController] openChatWithContact:(AIListContact *)item
												onPreferredAccount:YES];
				messageContent = [AIContentMessage messageInChat:chat
													  withSource:[chat account]
													 destination:[chat listObject]
															date:nil
														 message:messageAttributedString
													   autoreply:NO];
			
				[[adium contentController] sendContentObject:messageContent];
			}
			else {
				success = NO;
			}

		} else {
			success = NO;
		}
	}
	
	[super outlineView:outlineView acceptDrop:info item:item childIndex:index];

	//XXX Is this actually needed?
	[self contactListChanged:nil];
	
    return success;
}

- (void)mergeContactSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSDictionary	*context = (NSDictionary *)contextInfo;

	if (returnCode == 1) {
		AIListObject	*item = [context objectForKey:@"item"];
		NSArray			*draggedItems = [context objectForKey:@"dragitems"];
		AIMetaContact	*metaContact;

		//Keep track of where it was before
		AIListObject<AIContainingObject> *oldContainingObject = [[item containingObject] retain];
		float oldIndex = [item orderIndex];
		
		//Group the destination and then the dragged items into a metaContact
		metaContact = [[adium contactController] groupListContacts:[[NSArray arrayWithObject:item] arrayByAddingObjectsFromArray:draggedItems]];

		//Position the metaContact in the group & index the drop point was before
		[[adium contactController] moveListObjects:[NSArray arrayWithObject:metaContact]
										intoObject:oldContainingObject
											 index:oldIndex];
		
		[oldContainingObject release];
	}

	[context release]; //We are responsible for retaining & releasing the context dict
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == contactListView && [keyPath isEqualToString:@"desiredHeight"]) {
		if ([[change objectForKey:NSKeyValueChangeNewKey] intValue] != [[change objectForKey:NSKeyValueChangeOldKey] intValue])
			[self contactListDesiredSizeChanged];
		
	}
}

#pragma mark Preferences

- (AIContactListWindowStyle)windowStyle
{
	NSNumber	*windowStyleNumber = [[adium preferenceController] preferenceForKey:KEY_LIST_LAYOUT_WINDOW_STYLE 
																			  group:PREF_GROUP_APPEARANCE];
	return (windowStyleNumber ? [windowStyleNumber intValue] : AIContactListWindowStyleStandard);
}



@end
