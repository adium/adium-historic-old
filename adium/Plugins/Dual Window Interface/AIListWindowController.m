/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIListWindowController.h"
#import "AIStatusSelectionView.h"
#import "AIListOutlineView.h"
#import "AIListCell.h"

#define CONTACT_LIST_WINDOW_NIB				@"ContactListWindow"		//Filename of the contact list window nib
#define CONTACT_LIST_WINDOW_TRANSPARENT_NIB @"ContactListWindowTransparent" //Filename of the minimalist transparent version
#define CONTACT_LIST_TOOLBAR				@"ContactList"				//ID of the contact list toolbar
#define	KEY_DUAL_CONTACT_LIST_WINDOW_FRAME	@"Dual Contact List Frame 2"

#define EDGE_CATCH_X				10
#define EDGE_CATCH_Y				40
#define SCROLL_VIEW_PADDING_X		2
#define SCROLL_VIEW_PADDING_Y		2

#define PREF_GROUP_CONTACT_LIST		@"Contact List"
#define KEY_CLWH_WINDOW_POSITION	@"Contact Window Position"
#define KEY_CLWH_HIDE				@"Hide While in Background"


#define TOOL_TIP_CHECK_INTERVAL				45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY						25.0	//Number of check intervals of no movement before a tip is displayed

#define MAX_DISCLOSURE_HEIGHT				13		//Max height/width for our disclosure triangles

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

#define PREF_GROUP_CONTACT_STATUS_COLORING	@"Contact Status Coloring"

@interface AIListWindowController (PRIVATE)
- (void)contactSelectionChanged:(NSNotification *)notification;
- (void)contactListDesiredSizeChanged:(NSNotification *)notification;
- (void)centerWindowOnMainScreenIfNeeded:(NSNotification *)notification;
- (void)windowDidLoad;
- (BOOL)windowShouldClose:(id)sender;
- (NSRect)_desiredWindowFrame;
- (void)_configureAutoResizing;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)_configureToolbar;
@end

@implementation AIListWindowController

//Return a new contact list window controller
+ (AIListWindowController *)listWindowController
{
    return([[[self alloc] init] autorelease]);
}

//Init
- (id)init
{	
    [super initWithWindowNibName:[self nibName]];
	
    //Observe preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    return(self);
}

//Nib to load
- (NSString *)nibName
{
    return(@"");    
}

//Dealloc
- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	
	[toolbarItems release];

    [super dealloc];
}

//Setup the window after it had loaded
- (void)windowDidLoad
{
    NSString	*frameString;
    
    //Toolbar (can not be added to a borderless window)
    if(!borderless) [self _configureToolbar];
    
    //Exclude this window from the window menu (since we add it manually)
    [[self window] setExcludedFromWindowsMenu:YES];
    
    //Restore the window position
    frameString = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_WINDOW_POSITIONS] objectForKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME];
	if(frameString){
		NSRect		windowFrame = NSRectFromString(frameString);
		
		//Don't allow the window to shrink smaller than it's toolbar
		
		NSRect 		contentFrame = [NSWindow contentRectForFrameRect:windowFrame
														   styleMask:[[self window] styleMask]];
		
		if(contentFrame.size.height < [[self window] toolbarHeight]) windowFrame.size.height += [[self window] toolbarHeight] - contentFrame.size.height;
        
		[[self window] setFrame:windowFrame display:YES];
	}
	
    minWindowSize = [[self window] minSize];
	
    //Swap in the contact list view
//    contactListViewController = [[AIStandardListWind contactListViewController] retain];
//    contactListView = [[contactListViewController contactListView] retain];
    [scrollView_contactList setAutoScrollToBottom:NO];
    [scrollView_contactList setAutoHideScrollBar:YES];
//    [[self window] makeFirstResponder:contactListView];
//	[scrollView_contactList setAndSizeDocumentView:contactListView];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contactListDesiredSizeChanged:)
												 name:AIViewDesiredSizeDidChangeNotification
											   object:contactListView];
    
    //Watch for resolution and screen configuration changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(screenParametersChanged:) 
															   name:NSApplicationDidChangeScreenParametersNotification 
															 object:nil];
	
	
	
	[[adium notificationCenter] addObserver:self selector:@selector(contactListChanged:) 
									   name:Contact_ListChanged
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactOrderChanged:)
									   name:Contact_OrderChanged 
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:nil];
	
	[contactListView setDoubleAction:@selector(performDefaultActionOnSelectedContact:)];
	
	//Fetch and update the contact list
    [self contactListChanged:nil];
	
	
	
	
	
	
    //Apply initial preference-based settings
    [self preferencesChanged:nil];
}

//Close the contact list window
- (BOOL)windowShouldClose:(id)sender
{
    //Stop observing
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Close the contact list view
//    [contactListViewController release];
//    [contactListView release];
    
	//Save the window position
	[[adium preferenceController] setPreference:[[self window] stringWithSavedFrame]
                                         forKey:KEY_DUAL_CONTACT_LIST_WINDOW_FRAME
                                          group:PREF_GROUP_WINDOW_POSITIONS];
	
    //Tell the interface to unload our window
	[[adium notificationCenter] postNotificationName:Interface_ContactListDidClose object:self];

    return(YES);
}

//Preferences have changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST])){
		NSDictionary 	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
		int				windowPosition = [[prefDict objectForKey:KEY_CLWH_WINDOW_POSITION] intValue];
		int				level;
		
		switch(windowPosition){
			case 1: level = NSFloatingWindowLevel; break;
			case 2: level = kCGDesktopWindowLevel; break;
			default: level = NSNormalWindowLevel; break;
		}
		[[self window] setLevel:level];
		[[self window] setIgnoresExpose:(windowPosition == 2)]; //Ignore expose while on the desktop


		[[self window] setHidesOnDeactivate:[[prefDict objectForKey:KEY_CLWH_HIDE] boolValue]];
    }
	
    if((notification == nil) || ([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY])){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
		
		//Force auto-resizing on for borderless lists
		if(!borderless){
			autoResizeVertically = [[prefDict objectForKey:KEY_DUAL_RESIZE_VERTICAL] boolValue];
			autoResizeHorizontally = [[prefDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];
		}else{
			autoResizeVertically = YES;
			autoResizeHorizontally = YES;
		}
		
        [self _configureAutoResizing];
    }

    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_CONTACT_LIST_DISPLAY]){
		if([(NSString *)[[notification userInfo] objectForKey:@"Key"] isEqualToString:KEY_SCL_BORDERLESS]){
			[self retain];
			[[adium interfaceController] closeContactList:nil];
			[[adium interfaceController] showContactList:nil];
			[self autorelease];
		}
	}

}


//Interface Container --------------------------------------------------------------------------------------------------
#pragma mark Interface Container
//Make this container active
- (void)makeActive:(id)sender
{
    [self showWindow:nil];
}

//Close this container
- (void)close:(id)sender
{
    //In response to windowShouldClose, the interface controller releases us.  At that point, no one would be retaining
	//this instance of AIContactListWindowController, and we would be deallocated.  The call to [self window] will
	//crash if we are deallocated.  A dirty, but functional fix is to temporarily retain ourself here.
    [self retain];
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
    [self release];
}

//Contact list brought to front
- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidBecomeMain object:self];
}

//Contact list sent back
- (void)windowDidResignKey:(NSNotification *)notification
{
    [[adium notificationCenter] postNotificationName:Interface_ContactListDidResignMain object:self];
}


//Resizing And Positioning ---------------------------------------------------------------------------------------------
#pragma mark Resizing And Positioning
//Configure auto-resizing
- (void)_configureAutoResizing
{
    //Hide the resize indicator if all sizing is being controlled programatically
    [[self window] setShowsResizeIndicator:!(autoResizeVertically && autoResizeHorizontally)];
    
    //Configure the maximum and minimum sizes
    NSRect  currentFrame = [[self window] frame];
    NSSize targetMin = minWindowSize;
    NSSize targetMax = NSMakeSize(10000, 10000);
    
    if(autoResizeHorizontally){
        targetMin.width = currentFrame.size.width;
        targetMax.width = currentFrame.size.width;
    }
    if(autoResizeVertically){
        targetMin.height = currentFrame.size.height;
        targetMax.height = currentFrame.size.height;
    }
    
    [[self window] setMinSize:targetMin];
    [[self window] setMaxSize:targetMax];

	//Update the size as necessary
	[self contactListDesiredSizeChanged:nil];
}

//Dynamically resize the contact list
- (void)contactListDesiredSizeChanged:(NSNotification *)notification
{
    if(autoResizeVertically || autoResizeHorizontally){
        NSRect	desiredFrame = [self _desiredWindowFrame];
        if((desiredFrame.size.width != 0) && (desiredFrame.size.height != 0)){
			NSRect  newFrame = desiredFrame;
			NSRect  oldFrame = [[self window] frame];
			
			if(!NSEqualRects(oldFrame, newFrame)){
				NSSize targetMin = minWindowSize;
				NSSize targetMax = NSMakeSize(10000, 10000);
				if(autoResizeHorizontally) {    
					targetMin.width = newFrame.size.width;
					targetMax.width = newFrame.size.width;
				}else{
					newFrame.size.width = oldFrame.size.width; //no horizontal resize so use old width
					newFrame.origin.x = oldFrame.origin.x;
				}
				
				if(autoResizeVertically){
					targetMin.height = newFrame.size.height;  
					targetMax.height = newFrame.size.height;  
				}else{
					newFrame.size.height = oldFrame.size.height; //no vertical resize so use old height
					newFrame.origin.y = oldFrame.origin.y;
				}
				
				//Resize the window
				[[self window] setFrame:newFrame display:YES animate:NO];
				[[self window] setMinSize:targetMin];
				[[self window] setMaxSize:targetMax];
			}
		}
    }
}

//Size for window zoom
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    return([self _desiredWindowFrame]);
}

//Desired frame of our window
- (NSRect)_desiredWindowFrame
{
#warning ###
	NSWindow    *theWindow = [self window];
	NSRect      currentFrame = [theWindow frame];
    NSRect		newFrame = currentFrame;
/*	
    if([contactListView conformsToProtocol:@protocol(AIAutoSizingView)]){
		NSScreen	*activeScreen;
		NSSize      contactViewPadding, desiredSize;
		NSRect      screenFrame, totalScreenFrame;

        //Get screen frame (We'll need to stay within it)
		activeScreen = [theWindow screen];
        if(!activeScreen) activeScreen = [[NSScreen screens] objectAtIndex:0];
        screenFrame = [activeScreen visibleFrame];
        totalScreenFrame = [activeScreen frame];
		
		//Remember the padding around the contact list view
		contactViewPadding.height = currentFrame.size.height - [scrollView_contactList frame].size.height;
		contactViewPadding.width = currentFrame.size.width - [scrollView_contactList frame].size.width;

        //Calculate desired width and height
		desiredSize = [(NSView<AIAutoSizingView> *)contactListView desiredSize];
        if(autoResizeHorizontally){
            newFrame.size.width = desiredSize.width + contactViewPadding.width + SCROLL_VIEW_PADDING_X;
        }else{
            newFrame.size.width = currentFrame.size.width;
        }
        newFrame.size.height = desiredSize.height + contactViewPadding.height + SCROLL_VIEW_PADDING_Y;
        
        if(newFrame.size.height > screenFrame.size.height){
            newFrame.size.height = screenFrame.size.height;
            if(autoResizeHorizontally){
                newFrame.size.width += 16; //Factor scrollbar into width
            }
        }
		
        //If the window is near the right edge of the screen, keep it near that edge
        if(autoResizeHorizontally &&
		   (currentFrame.origin.x + currentFrame.size.width) + EDGE_CATCH_X > (screenFrame.origin.x + screenFrame.size.width)){

			newFrame.origin.x = currentFrame.origin.x + (currentFrame.size.width - newFrame.size.width);
			if((newFrame.origin.x + newFrame.size.width) < (screenFrame.origin.x + EDGE_CATCH_X)){
				newFrame.origin.x = screenFrame.origin.x - newFrame.size.width + EDGE_CATCH_X;
			}
		}
        
		//If the window is not near the bottom edge of the screen, keep its titlebar in place
		if(currentFrame.origin.y > screenFrame.origin.y + EDGE_CATCH_Y ||
		   currentFrame.origin.y + currentFrame.size.height + EDGE_CATCH_Y > screenFrame.origin.y + screenFrame.size.height){
			newFrame.origin.y += currentFrame.size.height - newFrame.size.height;
		}
		
	}*/
	
	return(newFrame);
}

	
//Prevent the system from altering our window positioning
- (BOOL)shouldCascadeWindows
{
    return(NO);
}










//Notifications
//Reload the contact list
- (void)contactListChanged:(NSNotification *)notification
{
	id		object = [notification object];
	//Redisplay and resize
	if(!object || object == contactList){
		[contactList release]; contactList = [[[adium contactController] contactList] retain];
		[contactListView reloadData];
#warning ###		[contactListView _performFullRecalculation];
	}else{
		NSDictionary	*userInfo = [notification userInfo];
		AIListGroup		*containingGroup = [userInfo objectForKey:@"ContainingGroup"];
		
		if(!containingGroup || containingGroup == contactList){
			//Reload the whole tree if the containing group is our root
			[contactListView reloadData];
#warning ###			[contactListView _performFullRecalculation];
		}else{
			//We need to reload the contaning group since this notification is posted when adding and removing objects.
			//Reloading the actual object that changed will produce no results since it may not be on the list.
			[contactListView reloadItem:containingGroup reloadChildren:YES];
		}
		
		//Factor the width of this item into our total
#warning ###		[contactListView updateHorizontalSizeForObject:object];
	}
}

//Reload the contact list (if updates aren't delayed)
- (void)contactOrderChanged:(NSNotification *)notification
{
	id		object = [notification object];
	
	if(!object || (object == contactList)){ //Treat a nil object as equivalent to the contact list
		[contactListView reloadData];
#warning ###		[contactListView _performFullRecalculation];
	}else{
		if([object containingGroup]) [contactListView reloadItem:[object containingGroup] reloadChildren:YES];
	}
}

//Redisplay the modified object (Attribute change)
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*object = [notification object];
    NSArray			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
    //Redraw the modified object
	//	if (object){
	//		int row = [contactListView rowForItem:object];
	//		if(row >= 0) [contactListView setNeedsDisplayInRect:[contactListView rectOfRow:row]];
	//    }else{
	//		[contactListView setNeedsDisplay:YES];
	//	}
	[contactListView redisplayItem:[notification object]];
	
    //Resize the contact list horizontally
    if(horizontalResizingEnabled){
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









//Double click in outline view
- (IBAction)performDefaultActionOnSelectedContact:(id)sender
{
    AIListObject	*selectedObject = [sender itemAtRow:[sender selectedRow]];
	
    if([selectedObject isKindOfClass:[AIListGroup class]]){
        //Expand or collapse the group
        if([sender isItemExpanded:selectedObject]){
            [sender collapseItem:selectedObject];
        }else{
            [sender expandItem:selectedObject];
        }
		
    }else if([selectedObject isKindOfClass:[AIListContact class]]){
        //Open a new message with the contact
		AIListContact	*contact = (AIListContact *)selectedObject;
		
		//If the contact is a meta contact, find the preferred contact for it
		if ([contact isKindOfClass:[AIMetaContact class]]){
			contact = [[adium contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
																 forListContact:contact];
		}
		
		[[adium interfaceController] setActiveChat:[[adium contentController] openChatWithContact:contact]];
		
    }
}

- (AIListCell *)outlineViewDataCell
{
	return([[AIListCell alloc] init]);
}



//Outline View data source ---------------------------------------------------------------------------------------------
#pragma mark Outline View data source
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
		return((index >= 0 && index < [contactList count]) ? [contactList objectAtIndex:index] : nil);
    }else{
        return((index >= 0 && index < [item count]) ? [item objectAtIndex:index] : nil);
    }
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForColumn:(NSTableColumn *)column
{
	return([self outlineViewDataCell]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if([item isKindOfClass:[AIListGroup class]]){
        return(YES);
    }else{
        return(NO);
    }
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil){
        return([contactList visibleCount]);
    }else{
        return([item visibleCount]);
    }
}

// outlineView:willDisplayCell: The outline view is about to tell one of our cells to draw
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    //Before one of our cells gets told to draw, we need to make sure it knows what contact it's drawing for.
	[(AIListCell *)cell setListObject:item];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return(@"");
}

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


- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    NSMutableArray      *contactArray = [[adium contactController] allContactsInGroup:item subgroups:YES onAccount:nil];

    [item setExpanded:state];
#warning ###	[contactListView updateHorizontalSizeForObjects:contactArray]; 
	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    return([item isExpanded]);
}


- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent
{
    NSPoint	location;
    int		row;
    id		item;

    //Get the clicked item
    location = [outlineView convertPoint:[theEvent locationInWindow] fromView:[[outlineView window] contentView]];
    row = [outlineView rowAtPoint:location];
    item = [outlineView itemAtRow:row];

    //Select the clicked row and bring the window forward
    [outlineView selectRow:row byExtendingSelection:NO];
    [[outlineView window] makeKeyAndOrderFront:nil];

    //Hide any open tooltip
    [self hideTooltip];

    //Return the context menu
	AIListObject	*listObject = (AIListObject *)[contactListView firstSelectedItem];
	NSArray			*locationsArray;
	if ([listObject isKindOfClass:[AIListGroup class]]){
		locationsArray = [NSArray arrayWithObjects:
			[NSNumber numberWithInt:Context_Group_Manage],
			[NSNumber numberWithInt:Context_Contact_Action],
			[NSNumber numberWithInt:Context_Contact_ListAction],
			[NSNumber numberWithInt:Context_Contact_NegativeAction],
			[NSNumber numberWithInt:Context_Contact_Additions], nil];
	}else{
		locationsArray = [NSArray arrayWithObjects:
			[NSNumber numberWithInt:Context_Contact_Manage],
			[NSNumber numberWithInt:Context_Contact_Action],
			[NSNumber numberWithInt:Context_Contact_ListAction],
			[NSNumber numberWithInt:Context_Contact_NegativeAction],
			[NSNumber numberWithInt:Context_Contact_Additions], nil];	
	}
	
    return([[adium menuController] contextualMenuWithLocations:locationsArray
												 forListObject:listObject]);
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
#warning ###	float	capHeight = [[contactListView groupFont] capHeight];
#warning ###	NSImage	*image, *altImage;
#warning ###	
#warning ###	//The triangle can only get so big before it starts to get clipped, so we restrict it's size as necessary
#warning ###	if(capHeight > MAX_DISCLOSURE_HEIGHT) capHeight = MAX_DISCLOSURE_HEIGHT;
#warning ###
#warning ###	//Apply this new size to the images
#warning ###	image = [cell image];
#warning ###	altImage = [cell alternateImage];
	
#warning ###	//Resize the iamges
#warning ###	[image setScalesWhenResized:YES];
#warning ###	[image setSize:NSMakeSize(capHeight, capHeight)];
#warning ###	[altImage setScalesWhenResized:YES];
#warning ###	[altImage setSize:NSMakeSize(capHeight, capHeight)];

#warning ###	//Set them back and center
#warning ###	[cell setAlternateImage:altImage];
#warning ###	[cell setImage:image];
#warning ###	[cell setImagePosition:NSImageOnly];
#warning ###	[cell setHighlightsBy:NSContentsCellMask];
} 


- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
	//Kill any selections
	[outlineView deselectAll:nil];
    [self _stopTrackingMouse];

	//Begin the drag
	if(dragItems) [dragItems release];
	dragItems = [items retain];

	[pboard declareTypes:[NSArray arrayWithObjects:@"AIListObject",nil] owner:self];
	[pboard setString:@"Private" forType:@"AIListObject"];

	return(YES);
}
//
- (NSDragOperation)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSString	*avaliableType = [[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"AIListObject"]];
	
	//No longer in a drag, so allow tooltips again
	//No dropping into contacts
    if([avaliableType isEqualToString:@"AIListObject"]){
		id	primaryDragItem = [dragItems objectAtIndex:0];
		
		if([primaryDragItem isKindOfClass:[AIListGroup class]]){
			//Disallow dragging groups into or onto other objects
			if(item != nil){
				if([item isKindOfClass:[AIListGroup class]]){
					[outlineView setDropItem:nil dropChildIndex:[[item containingGroup] indexOfObject:item]];
				}else{
					[outlineView setDropItem:nil dropChildIndex:[[[item containingGroup] containingGroup] indexOfObject:[item containingGroup]]];
				}
			}
			
		}else{
			//Disallow dragging contacts onto anything besides a group
			if(index == -1 && ![item isKindOfClass:[AIListGroup class]]){
				[outlineView setDropItem:[item containingGroup] dropChildIndex:[[item containingGroup] indexOfObject:item]];
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
		
		//Move the list object to it's new location
		if([item isKindOfClass:[AIListGroup class]]){
			[[adium contactController] moveListObjects:dragItems
											   toGroup:item
												 index:index];
		}
	}

    return(YES);
}


//Auto-resizing support ------------------------------------------------------------------------------------------------
#pragma mark Auto-resizing support
- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
    [self _desiredSizeChanged];
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    [self _desiredSizeChanged];
}

- (void)_desiredSizeChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification
														object:contactListView];
}

- (void)screenParametersChanged:(NSNotification *)notification
{
#warning ###    [contactListView _performFullRecalculation];
}


//Tooltips (Cursor rects) ----------------------------------------------------------------------------------------------
//We install a cursor rect for our enclosing scrollview.  When the cursor is within this rect, we track it's
//movement.  If our scrollview changes, or the size of our scrollview changes, we must re-install our rect.
#pragma mark Tooltips (Cursor rects)
//Our enclosing scrollview is going to be changed, stop all cursor tracking
- (void)view:(NSView *)inView willMoveToSuperview:(NSView *)newSuperview
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
	[self _removeCursorRect];
}

//We've been moved to a new scrollview, resume cursor tracking
//View is being added to a new superview
- (void)view:(NSView *)inView didMoveToSuperview:(NSView *)newSuperview
{	
    if(newSuperview && [newSuperview superview]){
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(frameDidChange:)
													 name:NSViewFrameDidChangeNotification 
												   object:[newSuperview superview]];
	}
	
	[self performSelector:@selector(_installCursorRect) withObject:nil afterDelay:0.0001];
}

- (void)view:(NSView *)inView didMoveToWindow:(NSWindow *)window
{
	[self _configureTransparencyAndShadows];
	
	windowHidesOnDeactivate = [window hidesOnDeactivate];
}

- (void)window:(NSWindow *)inWindow didBecomeMain:(NSNotification *)notification
{	
	[self _startTrackingMouse];
}

- (void)window:(NSWindow *)inWindow didResignMain:(NSNotification *)notification
{	
	[self _stopTrackingMouse];
}

//Our enclosing scrollview has changed size, reset cursor tracking
- (void)frameDidChange:(NSNotification *)notification
{
	[self _removeCursorRect];
	[self _installCursorRect];
}

//Install the cursor rect for our enclosing scrollview
- (void)_installCursorRect
{
	if(tooltipTrackingTag == -1){
		NSScrollView	*scrollView = [contactListView enclosingScrollView];
		NSRect	 		trackingRect;
		BOOL			mouseInside;
		
		//Add a new tracking rect (The size of our scroll view minus the scrollbar)
		trackingRect = [scrollView frame];
		trackingRect.size.width = [scrollView contentSize].width;
		mouseInside = NSPointInRect([[contactListView window] convertScreenToBase:[NSEvent mouseLocation]], trackingRect);
		tooltipTrackingTag = [[[contactListView window] contentView] addTrackingRect:trackingRect
																			   owner:self
																			userData:scrollView
																		assumeInside:mouseInside];
		
		//If the mouse is already inside, begin tracking the mouse immediately
		if(mouseInside) [self _startTrackingMouse];
	}
}

//Remove the cursor rect
- (void)_removeCursorRect
{
	if(tooltipTrackingTag != -1){
		[[[contactListView window] contentView] removeTrackingRect:tooltipTrackingTag];
		tooltipTrackingTag = -1;
		[self _stopTrackingMouse];
	}
}


//Tooltips (Cursor movement) -------------------------------------------------------------------------------------------
//We use a timer to poll the location of the mouse.  Why do this instead of using mouseMoved: events?
// - Webkit eats mouseMoved: events, even when those events occur elsewhere on the screen
// - mouseMoved: events do not work when Adium is in the background
#pragma mark Tooltips (Cursor movement)
//Mouse entered our list, begin tracking it's movement
- (void)mouseEntered:(NSEvent *)theEvent
{
	[self _startTrackingMouse];
}

//Mouse left our list, cease tracking
- (void)mouseExited:(NSEvent *)theEvent
{
	[self _stopTrackingMouse];
}

//Start tracking mouse movement
- (void)_startTrackingMouse
{
	if(!tooltipMouseLocationTimer){
		tooltipCount = 0;
		tooltipMouseLocationTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/TOOL_TIP_CHECK_INTERVAL)
																	  target:self
																	selector:@selector(mouseMovementTimer:)
																	userInfo:nil
																	 repeats:YES] retain];
	}
}

//Stop tracking mouse movement
- (void)_stopTrackingMouse
{
	[self _showTooltipAtPoint:NSMakePoint(0,0)];
	[self _killMouseMovementTimer];
}

- (void)_killMouseMovementTimer
{
	[tooltipMouseLocationTimer invalidate];
	[tooltipMouseLocationTimer release];
	tooltipMouseLocationTimer = nil;
	tooltipCount = 0;
	lastMouseLocation = NSMakePoint(0,0);
}

//Time to poll mouse location
- (void)mouseMovementTimer:(NSTimer *)inTimer
{
	NSPoint mouseLocation = [NSEvent mouseLocation];
	if (tooltipShouldDisplay && NSPointInRect(mouseLocation,[[contactListView window] frame])){
		//tooltipCount is used for delaying the appearence of tooltips.  We reset it to 0 when the mouse moves.  When
		//the mouse is left still tooltipCount will eventually grow greater than TOOL_TIP_DELAY, and we will begin
		//displaying the tooltips
		if(tooltipCount > TOOL_TIP_DELAY){
			[self _showTooltipAtPoint:mouseLocation];
			
		}else{
			if(!NSEqualPoints(mouseLocation,lastMouseLocation)){
				lastMouseLocation = mouseLocation;
				tooltipCount = 0; //reset tooltipCount to 0 since the mouse has moved
			} else {
				tooltipCount++;
			}
		}
	}else{
		//Failsafe for if the mouse is outside the window yet the timer is still firing
		[self _stopTrackingMouse];
	}
}

//Tooltips (Display) -------------------------------------------------------------------------------------------
#pragma mark Tooltips (Display)
//Hide any active tooltip and reset the initial appearance delay
- (void)hideTooltip
{
	[self _showTooltipAtPoint:NSMakePoint(0,0)];
	tooltipCount = 0;
}

//Show a tooltip at the specified screen point.
//If point is (0,0) or the window is hidden, the tooltip will be hidden and tracking stopped
- (void)_showTooltipAtPoint:(NSPoint)screenPoint
{
	if(!NSEqualPoints(tooltipLocation, screenPoint)){
		AIListObject	*hoveredObject = nil;
		NSWindow		*window = [contactListView window];
		
		if (screenPoint.x != 0 && screenPoint.y != 0){
			if([window isVisible] && (!windowHidesOnDeactivate || [NSApp isActive])){
				NSPoint			viewPoint;
				int				hoveredRow;
				
				//Extract data from the event
				viewPoint = [contactListView convertPoint:[window convertScreenToBase:screenPoint] fromView:nil];
				
				//Get the hovered contact
				hoveredRow = [contactListView rowAtPoint:viewPoint];
				hoveredObject = [contactListView itemAtRow:hoveredRow];
			}else{
				[self _killMouseMovementTimer];
			}
		}
		
		[[adium interfaceController] showTooltipForListObject:hoveredObject atScreenPoint:screenPoint onWindow:window];
		tooltipLocation = screenPoint;
	}
}

@end
