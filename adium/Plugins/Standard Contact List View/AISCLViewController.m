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
#import <unistd.h>
#import "AISCLViewController.h"
#import "AISCLCell.h"
#import "AISCLOutlineView.h"
#import "AISCLViewPlugin.h"

#define TOOL_TIP_CHECK_INTERVAL				45.0	//Check for mouse X times a second
#define TOOL_TIP_DELAY						25.0	//Number of check intervals of no movement before a tip is displayed

#define MAX_DISCLOSURE_HEIGHT				13		//Max height/width for our disclosure triangles

#define	PREF_GROUP_DUAL_WINDOW_INTERFACE	@"Dual Window Interface"
#define KEY_DUAL_RESIZE_HORIZONTAL			@"Autoresize Horizontal"

@interface AISCLViewController (PRIVATE)
- (void)contactListChanged:(NSNotification *)notification;
- (void)contactOrderChanged:(NSNotification *)notification;
- (void)contactAttributesChanged:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)frameDidChange:(NSNotification *)notification;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)_installCursorRect;
- (void)_removeCursorRect;
- (void)_startTrackingMouse;
- (void)_stopTrackingMouse;
- (void)_killMouseMovementTimer;
- (void)_showTooltipAtPoint:(NSPoint)screenPoint;
- (void)_desiredSizeChanged;
- (void)_configureTransparencyAndShadows;
- (void)_hideTooltip;
- (void)_endTrackingMouse;
@end

@interface NSObject (_AIRespondsToUpdateShadows)
- (void)setUpdateShadowsWhileScrolling:(BOOL)update;
@end

@implementation AISCLViewController

+ (AISCLViewController *)contactListViewController
{
    return([[[self alloc] init] autorelease]);    
}

- (AISCLViewController *)init
{
    [super init];

    //Init
    tooltipTrackingTag = -1;
	inDrag = NO;
	windowHidesOnDeactivate = NO;
	dragItems = nil;
	tooltipMouseLocationTimer = nil;
    tooltipCount = 0;
	lastMouseLocation = NSMakePoint(0,0);
	tooltipLocation = NSMakePoint(0,0);
	
	contactListView = [[AISCLOutlineView alloc] initWithFrame:NSMakeRect(0,0,100,100)]; //Arbitrary frame
	
	//
	[contactListView registerForDraggedTypes:[NSArray arrayWithObject:@"AIListObject"]];
	
    //Install the necessary observers
    [[adium notificationCenter] addObserver:self selector:@selector(contactListChanged:) 
									   name:Contact_ListChanged
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactOrderChanged:)
									   name:Contact_OrderChanged 
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) 
									   name:ListObject_AttributesChanged
									 object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged 
									 object:nil];

	
	
    //Watch for resolution and screen configuration changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(screenParametersChanged:) 
															   name:NSApplicationDidChangeScreenParametersNotification 
															 object:nil];
	
    [contactListView setTarget:self];
    [contactListView setDataSource:self];
    [contactListView setDelegate:self];
    [contactListView setDoubleAction:@selector(performDefaultActionOnSelectedContact:)];

	//Fetch and update the contact list
    [self contactListChanged:nil];
	
    //Apply the preferences to our view - needs to happen _after_ fetching & updating the contact list
    [self preferencesChanged:nil];
				
    return(self);
}

- (void)dealloc
{    
    //Remove observers (general)
    [[adium notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	
    //Hide any open tooltips
	[self _removeCursorRect];
	
    //Close down and release the view
    [contactListView setTarget:nil];
    [contactListView setDataSource:nil];
    [contactListView setDelegate:nil];
    [contactListView release]; contactListView = nil;

    [super dealloc];
}

//Return our contact list view
- (NSView *)contactListView
{
    return(contactListView);
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
		[contactListView _performFullRecalculation];
	}else{
		NSDictionary	*userInfo = [notification userInfo];
		AIListGroup		*containingGroup = [userInfo objectForKey:@"ContainingGroup"];
		
		if(!containingGroup || containingGroup == contactList){
			//Reload the whole tree if the containing group is our root
			[contactListView reloadData];
			[contactListView _performFullRecalculation];
		}else{
			//We need to reload the contaning group since this notification is posted when adding and removing objects.
			//Reloading the actual object that changed will produce no results since it may not be on the list.
			[contactListView reloadItem:containingGroup reloadChildren:YES];
		}
		
		//Factor the width of this item into our total
		[contactListView updateHorizontalSizeForObject:object];
	}
}

//Reload the contact list (if updates aren't delayed)
- (void)contactOrderChanged:(NSNotification *)notification
{
	id		object = [notification object];
	
	if(!object || (object == contactList)){ //Treat a nil object as equivalent to the contact list
		[contactListView reloadData];
		[contactListView _performFullRecalculation];
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
    int row = [contactListView rowForItem:object];
    if(row >= 0) [contactListView setNeedsDisplayInRect:[contactListView rectOfRow:row]];
    
    //Resize the contact list horizontally
    if(horizontalResizingEnabled){
		if (object){
			if([keys containsObject:@"Display Name"] || [keys containsObject:@"Left View"] ||
			   [keys containsObject:@"Right View"] || [keys containsObject:@"Right Text"] ||
			   [keys containsObject:@"Left Text"]){
				[contactListView updateHorizontalSizeForObject:object];
			}
		}else{
			[contactListView _performFullRecalculation];	
		}
    }
}

//A contact list preference has changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST_DISPLAY] == 0){
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
		
        NSColor		*color = [[prefDict objectForKey:KEY_SCL_CONTACT_COLOR] representedColor];
        NSColor		*groupColor = [[prefDict objectForKey:KEY_SCL_GROUP_COLOR] representedColor];
        BOOL		alternatingGrid = [[prefDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue];
        BOOL		customGroupColor = [[prefDict objectForKey:KEY_SCL_CUSTOM_GROUP_COLOR] boolValue];
        BOOL		boldGroups = [[prefDict objectForKey:KEY_SCL_BOLD_GROUPS] boolValue];
        
        BOOL		showLabels = [[prefDict objectForKey:KEY_SCL_SHOW_LABELS] boolValue];
        BOOL		labelAroundContactOnly = [[prefDict objectForKey:KEY_SCL_LABEL_AROUND_CONTACT] boolValue];
        BOOL		outlineLabels = [[prefDict objectForKey:KEY_SCL_OUTLINE_LABELS] boolValue];
		BOOL		useGradient = [[prefDict objectForKey:KEY_SCL_USE_GRADIENT] boolValue];
		float		labelOpacity = [[prefDict objectForKey:KEY_SCL_LABEL_OPACITY] floatValue];

        //outlineGroups only works on Panther or better
        BOOL		outlineGroups = ([[prefDict objectForKey:KEY_SCL_OUTLINE_GROUPS] boolValue] && [NSApp isOnPantherOrBetter]);
        NSColor		*outlineGroupsColor = [[prefDict objectForKey:KEY_SCL_OUTLINE_GROUPS_COLOR] representedColor];
		
        BOOL		labelGroups = [[prefDict objectForKey:KEY_SCL_LABEL_GROUPS] boolValue];
        NSColor		*labelGroupsColor = [[prefDict objectForKey:KEY_SCL_LABEL_GROUPS_COLOR] representedColor];
        
        float		alpha = [[prefDict objectForKey:KEY_SCL_OPACITY] floatValue];
		
				
		//Opacity, Shadows
		[self _configureTransparencyAndShadows];
		
        //Contact and group fonts
        NSFont  *font = [[prefDict objectForKey:KEY_SCL_FONT] representedFont];
		NSFont	*boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
		if(!boldFont) boldFont = font;
		[contactListView setFont:font];
		[contactListView setGroupFont:(boldGroups ? boldFont : font)];
		
        //Row Height and spacing
        float 	fontHeight = [font defaultLineHeightForFont];
        if(boldFont){
            float boldHeight = [boldFont defaultLineHeightForFont];            
            if(boldHeight > fontHeight) fontHeight = boldHeight;
        }
        [contactListView setRowHeight:fontHeight];
        [contactListView setIntercellSpacing:NSMakeSize(3.0,[[prefDict objectForKey:KEY_SCL_SPACING] floatValue])];      
		
		
		/////////////////////////
		{
			float capHeight = [[contactListView groupFont] capHeight];
			[contactListView setIndentationPerLevel:(capHeight > MAX_DISCLOSURE_HEIGHT ? MAX_DISCLOSURE_HEIGHT : capHeight)];
		}
		///////////////
		
		
		
		
        NSColor		*backgroundColor = [[prefDict objectForKey:KEY_SCL_BACKGROUND_COLOR] representedColorWithAlpha:alpha];
        NSColor		*gridColor = [[prefDict objectForKey:KEY_SCL_GRID_COLOR] representedColorWithAlpha:alpha];
          
        //Colors
        [contactListView setShowLabels:showLabels];
        if (showLabels) {
            [contactListView setOutlineLabels:outlineLabels];
			[contactListView setUseGradient:useGradient];
            [contactListView setLabelOpacity:labelOpacity];
        }
        
        [contactListView setLabelAroundContactOnly:labelAroundContactOnly];
        [contactListView setColor:color];
        [contactListView setGroupColor:(customGroupColor ? groupColor : color)];
        [contactListView setBackgroundColor:backgroundColor];
        [(NSScrollView *)[[contactListView superview] superview] setDrawsBackground:NO];
        
        if (outlineGroups)
            [contactListView setOutlineGroupColor:outlineGroupsColor];          
        else
            [contactListView setOutlineGroupColor:nil];
        
        if (labelGroups)
            [contactListView setLabelGroupColor:labelGroupsColor];
        else
            [contactListView setLabelGroupColor:nil];
        
        //Grid
        [contactListView setDrawsAlternatingRows:alternatingGrid];
        [contactListView setAlternatingRowColor:gridColor];

		[contactListView _performFullRecalculation];
    }
   
    //Resizing
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DUAL_WINDOW_INTERFACE] == 0){
        //This is sloppy, we shouldn't be reading the interface plugin's preferences
        //We need to convert the desired size of SCLOutlineView to a lazy cache, so we can always tell it to resize from here
        //and not care what the interface is doing with the information.
        NSDictionary    *notOurPrefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];
        horizontalResizingEnabled = [[notOurPrefDict objectForKey:KEY_DUAL_RESIZE_HORIZONTAL] boolValue];
    }

}

//Configure the transparency and shadowing of the window containing our list
- (void)_configureTransparencyAndShadows
{
	if([contactListView window]){
		NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
		float   		alpha = [[prefDict objectForKey:KEY_SCL_OPACITY] floatValue];
		BOOL			hasShadow = [[prefDict objectForKey:KEY_SCL_SHADOWS] boolValue];
				
		//Shadow
		[[contactListView window] setHasShadow:hasShadow];
		if([[contactListView enclosingScrollView] respondsToSelector:@selector(setUpdateShadowsWhileScrolling:)]){
			[[contactListView enclosingScrollView] setUpdateShadowsWhileScrolling:((alpha != 1.0) && hasShadow)];
		}
		[[contactListView window] setOpaque:(alpha == 1.0)];
		[contactListView setUpdateShadowsWhileDrawing:((alpha != 1.0) && hasShadow)];

		//Force a redraw of the window and shadow
		[[contactListView window] compatibleInvalidateShadow];
		[[contactListView window] setViewsNeedDisplay:YES];
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
	[(AISCLCell *)cell setListObject:item];
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
	[contactListView updateHorizontalSizeForObjects:contactArray]; 
	
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
	AIListObject	*listObject = [contactListView listObject];
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
	float	capHeight = [[contactListView groupFont] capHeight];
	NSImage	*image, *altImage;
	
	//The triangle can only get so big before it starts to get clipped, so we restrict it's size as necessary
	if(capHeight > MAX_DISCLOSURE_HEIGHT) capHeight = MAX_DISCLOSURE_HEIGHT;

	//Apply this new size to the images
	image = [cell image];
	altImage = [cell alternateImage];
	
	//Resize the iamges
	[image setScalesWhenResized:YES];
	[image setSize:NSMakeSize(capHeight, capHeight)];
	[altImage setScalesWhenResized:YES];
	[altImage setSize:NSMakeSize(capHeight, capHeight)];

	//Set them back and center
	[cell setAlternateImage:altImage];
	[cell setImage:image];
	[cell setImagePosition:NSImageOnly];
	[cell setHighlightsBy:NSContentsCellMask];
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
    if([avaliableType compare:@"AIListObject"] == 0){
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
    if([availableType compare:@"AIListObject"] == 0){
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
    [contactListView _performFullRecalculation];
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

		if((screenPoint.x != 0 && screenPoint.y != 0) && [window isVisible] && (!windowHidesOnDeactivate || [NSApp isActive])){
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
		
		[[adium interfaceController] showTooltipForListObject:hoveredObject atScreenPoint:screenPoint onWindow:window];
		tooltipLocation = screenPoint;
	}
}
	
@end
