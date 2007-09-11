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
#import "AIListWindowController.h"
#import "AIAnimatingListOutlineView.h"
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

#define KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN		@"Contact List Docked To Bottom"

#define PREF_GROUP_APPEARANCE		@"Appearance"

@interface AIListController (PRIVATE)
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
	
	//Recall how the contact list was docked last time Adium was open
	dockToBottomOfScreen = [[[adium preferenceController] preferenceForKey:KEY_CONTACT_LIST_DOCKED_TO_BOTTOM_OF_SCREEN
																	group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	[contactListView addObserver:self forKeyPath:@"desiredHeight" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
	
	[self contactListChanged:nil];

    //Observe preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_LIST];
	
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
		[self setContactListRoot:[[adium contactController] contactList]];
	} else {
		NSDictionary	*userInfo = [notification userInfo];
		AIListGroup		*containingGroup = [userInfo objectForKey:@"ContainingGroup"];

		if (!containingGroup || containingGroup == contactList) {
			//Reload the whole tree if the containing group is our root
			[contactListView reloadData];
		} else {
			/* We need to reload the contaning group since this notification is posted when adding and removing objects.
			 * Reloading the actual object that changed will produce no results since it may not be on the list.
			 */
			[contactListView reloadItem:containingGroup reloadChildren:YES];
		}
	}
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

/*! 
 * @brief Method to check if operations need to be performed
 *
 *
 */
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSArray	*types = [[info draggingPasteboard] types];
	NSDragOperation retVal = NSDragOperationNone;
	BOOL allowBetweenContactDrop = (index==NSOutlineViewDropOnItemIndex);
	//No dropping into contacts
	if ([types containsObject:@"AIListObject"]) {
		if (index != NSOutlineViewDropOnItemIndex && (![[[adium contactController] activeSortController] canSortManually])) {
			//disable drop between for non-Manual Sort.
			return NSDragOperationNone;
		}
		id	primaryDragItem = [dragItems objectAtIndex:0];
		
		if ([primaryDragItem isKindOfClass:[AIListGroup class]]) {
			//Disallow dragging groups into or onto other objects
			if (item != nil) {
				if ([item isKindOfClass:[AIListGroup class]]) {
					[outlineView setDropItem:nil dropChildIndex:[[item containingObject] indexOfObject:item]];
				} else {
					[outlineView setDropItem:nil dropChildIndex:[[[item containingObject] containingObject] indexOfObject:[item containingObject]]];
				}
			}
			
		} else {
			//Disallow dragging contacts onto anything besides a group
			if (allowBetweenContactDrop == YES && ![item isKindOfClass:[AIListGroup class]]) {
				[outlineView setDropItem:item dropChildIndex:NSOutlineViewDropOnItemIndex];
			}
		}
		
		if (index == NSOutlineViewDropOnItemIndex && [item isKindOfClass:[AIListContact class]]) {
			//Dropping into a contact: Copy
			retVal = NSDragOperationCopy;
		
		} else {
			//Otherwise, it's either a move into a group or a manual reordering
			retVal = NSDragOperationPrivate;
		}

	} else if ([types containsObject:NSFilenamesPboardType] ||
			   [types containsObject:NSRTFPboardType]) {
		retVal = ((item && [item isKindOfClass:[AIListContact class]]) ? NSDragOperationLink : NSDragOperationNone);

	} else if (!allowBetweenContactDrop) {
		retVal = NSDragOperationNone;
	}
	return retVal;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	BOOL		success = YES;
	NSString	*availableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
    if ([availableType isEqualToString:@"AIListObject"]) {
		//Kill the selection now, (in a more finder-esque way)
		[outlineView deselectAll:nil];
		//The tree root is not associated with our root contact list group, so we need to make that association here
		if (item == nil) item = contactList;

		//Move the list object to its new location
		if ([item isKindOfClass:[AIListGroup class]]) {
			if (item != [[adium contactController] offlineGroup]) {
				[[adium contactController] moveListObjects:dragItems intoObject:item index:index];
			} else {
				success = NO;
			}
			
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
		
		while ((file = [enumerator nextObject])) {
			AIListContact	*targetFileTransferContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																									forListContact:item];
			[[adium fileTransferController] sendFile:file toListContact:targetFileTransferContact];
		}

	} else if ([[[info draggingPasteboard] types] containsObject:NSRTFPboardType]) {
		//Drag and drop text sending via the contact list.
		if ([item isKindOfClass:[AIListContact class]]) {
			/* This will send the message. Alternately, we could just insert it into the text view... */
			AIChat							*chat;
			AIContentMessage				*messageContent;
			
			chat = [[adium chatController] openChatWithContact:(AIListContact *)item
											onPreferredAccount:YES];
			messageContent = [AIContentMessage messageInChat:chat
												  withSource:[chat account]
												 destination:[chat listObject]
														date:nil
													 message:[NSAttributedString stringWithData:[[info draggingPasteboard] dataForType:NSRTFPboardType]]
												   autoreply:NO];
			
			[[adium contentController] sendContentObject:messageContent];
		} else {
			success = NO;
		}
	}
	
	[super outlineView:outlineView acceptDrop:info item:item childIndex:index];
	
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
		AIListObject<AIContainingObject> *oldContainingObject = [[item containingObject] retain];;
		float oldIndex = [item orderIndex];
		
		//Group the dragged items plus the destination into a metaContact
		metaContact = [[adium contactController] groupListContacts:[draggedItems arrayByAddingObject:item]];
		
		//Position the metaContact in the group & index the drop point was before
		[[adium contactController] moveListObjects:[NSArray arrayWithObject:metaContact]
										intoObject:oldContainingObject
											 index:oldIndex];
		
		[oldContainingObject release];
	}

	[context release]; //We are responsible for retaining & releasing the context dict
}

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
