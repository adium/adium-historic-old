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

#import "AISCLViewController.h"
#import <Adium/Adium.h>
#import "AISCLCell.h"
#import "AISCLOutlineView.h"
#import "AISCLViewPlugin.h"

#define TOOL_TIP_CHECK_INTERVAL		5.0		//Check for mouse movement 5 times a second
#define TOOL_TIP_DELAY 				3		//Number of check intervals of no movement before a tip is displayed

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

- (void)mouseMoved:(NSEvent *)theEvent;
- (void)_showTooltipAtPoint:(NSPoint)screenPoint;
- (void)updateTooltipTrackingRect;
- (void)_desiredSizeChanged;
- (void)_endTrackingMouse;

- (void)_configureTransparencyAndShadows;
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
    contactListView = [[AISCLOutlineView alloc] initWithFrame:NSMakeRect(0,0,100,100)]; //Arbitrary frame
    tooltipTrackingTag = -1;
    trackingMouseMovedEvents = NO;
    tooltipTimer = nil;
    tooltipCount = 0;
    
    //Install the necessary observers
    [[adium notificationCenter] addObserver:self selector:@selector(contactListChanged:) name:Contact_ListChanged object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(contactOrderChanged:) name:Contact_OrderChanged object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(listObjectAttributesChanged:) name:ListObject_AttributesChanged object:nil];
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    //Watch for resolution and screen configuration changes
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(screenParametersChanged:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
        
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
    [[adium notificationCenter] removeObserver:contactListView name:ListObject_AttributesChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Hide any open tooltips
    [self _endTrackingMouse];

    //Close down and release the view
    [contactListView setTarget:nil];
    [contactListView setDataSource:nil];
    [contactListView setDelegate:nil];
    [contactListView release];

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
		[contactListView performFullRecalculation];
	}else{
		//Reload the item, reloading its children if it is expanded
		[contactListView reloadItem:object reloadChildren:[contactListView isItemExpanded:object]];
		[contactListView updateHorizontalSizeForObject:object];
	}
}

//Reload the contact list (if updates aren't delayed)
- (void)contactOrderChanged:(NSNotification *)notification
{
	id		object = [notification object];
	
	if(!object || object == contactList){
		[contactListView reloadData];
	}else{
		[contactListView reloadItem:object reloadChildren:YES];
	}
	
    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:contactListView];
}

//Redisplay the modified object (Attribute change)
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*object = [notification object];
    NSArray		*keys = [[notification userInfo] objectForKey:@"Keys"];

    //Redraw the modified object
    int row = [contactListView rowForItem:object];
    if(row >= 0) [contactListView setNeedsDisplayInRect:[contactListView rectOfRow:row]];
    
    //Resize the contact list horizontally
    if(horizontalResizingEnabled){
        if([keys containsObject:@"Display Name"] || [keys containsObject:@"Left View"] ||
		   [keys containsObject:@"Right View"] || [keys containsObject:@"Right Text"] ||
		   [keys containsObject:@"Left Text"]){
            [contactListView updateHorizontalSizeForObject:object];
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
        BOOL            labelAroundContactOnly = [[prefDict objectForKey:KEY_SCL_LABEL_AROUND_CONTACT] boolValue];
        BOOL            outlineLabels = [[prefDict objectForKey:KEY_SCL_OUTLINE_LABELS] boolValue];
		BOOL			useGradient = [[prefDict objectForKey:KEY_SCL_USE_GRADIENT] boolValue];
		float           labelOpacity = [[prefDict objectForKey:KEY_SCL_LABEL_OPACITY] floatValue];
        
        BOOL            outlineGroups = [[prefDict objectForKey:KEY_SCL_OUTLINE_GROUPS] boolValue];
        NSColor         *outlineGroupsColor = [[prefDict objectForKey:KEY_SCL_OUTLINE_GROUPS_COLOR] representedColor];
        BOOL            labelGroups = [[prefDict objectForKey:KEY_SCL_LABEL_GROUPS] boolValue];
        NSColor         *labelGroupsColor = [[prefDict objectForKey:KEY_SCL_LABEL_GROUPS_COLOR] representedColor];
        
        allowTooltipsInBackground = [[prefDict objectForKey:KEY_SCL_BACKGROUND_TOOLTIPS] boolValue];
        
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


        [contactListView performFullRecalculation];
        
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
	NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	float   		alpha = [[prefDict objectForKey:KEY_SCL_OPACITY] floatValue];
	BOOL			hasShadow = [[prefDict objectForKey:KEY_SCL_SHADOWS] boolValue];
	
	if([contactListView window]){
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

//Called when our view moves to another superview, update the traking rect
- (void)view:(NSView *)inView didMoveToSuperview:(NSView *)inSuperview
{
    //Remove any existing observers (if they exist)
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];

    //Observe scrollview frame changes (so we can update our cursor tracking rect)
    if(inSuperview && [inSuperview superview]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:[inSuperview superview]];
    }
    
    //Observe the window entering and leaving key (for tooltips)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_endTrackingMouse) name:NSWindowDidResignKeyNotification object:[inSuperview window]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSWindowDidBecomeKeyNotification object:[inSuperview window]]; //Force a frame update when window becomes key
    
    //Configure shadow drawing
	[self _configureTransparencyAndShadows];
}

//Frame changed, reinstall cursor tracking rect
- (void)frameDidChange:(NSNotification *)notification
{
    //Update the tooltip tracking rect
    [self updateTooltipTrackingRect];
}

//Double click in outline view
- (IBAction)performDefaultActionOnSelectedContact:(id)sender
{
    AIListObject	*selectedObject;

    selectedObject = [sender itemAtRow:[sender selectedRow]];
	NSLog(@"performDefaultActionOnSelectedContact");
    if([selectedObject isKindOfClass:[AIListGroup class]]){
        //Expand or collapse the group
        if([sender isItemExpanded:selectedObject]){
            [sender collapseItem:selectedObject];
        }else{
            [sender expandItem:selectedObject];
        }
    
    }else if([selectedObject isKindOfClass:[AIListContact class]]){
        //Open a new message with the contact
        AIChat	*chat = [[adium contentController] openChatOnAccount:nil withListObject:selectedObject];
        [[adium interfaceController] setActiveChat:chat];
    }
}

#pragma mark Outline View data source methods

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
        return([contactList objectAtIndex:index]);
    }else{
        return([item objectAtIndex:index]);
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
    if([cell isKindOfClass:[AISCLCell class]]){
        [(AISCLCell *)cell setContact:item];
    }
}

/*
- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
}
*/

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return(@"");
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{    
    AIListObject	*selectedObject = nil;
    NSOutlineView	*outlineView = [notification object];
    int			selectedRow;

    //Get the selected object
    selectedRow = [outlineView selectedRow];
    if(selectedRow >= 0 && selectedRow < [outlineView numberOfRows]){    
        selectedObject = [outlineView itemAtRow:selectedRow];
    }

    //Post a 'contact list selection changed' notification on the interface center
    if(selectedObject){
        NSDictionary	*notificationDict = [NSDictionary dictionaryWithObjectsAndKeys:selectedObject, @"Object", nil];
        [[adium notificationCenter] postNotificationName:Interface_ContactSelectionChanged object:outlineView userInfo:notificationDict];
    
    }else{
        [[adium notificationCenter] postNotificationName:Interface_ContactSelectionChanged object:outlineView userInfo:nil];
    }
    
}

- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    NSMutableArray      *contactArray =  [[adium contactController] allContactsInGroup:item subgroups:YES];
    NSEnumerator        *enumerator = [contactArray objectEnumerator];
    AIListObject        *object;
    [item setExpanded:state];

    while(object=[enumerator nextObject]) {
        [contactListView updateHorizontalSizeForObject:object]; 
    }
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

    //Stop tracking tooltips
    [self _endTrackingMouse];

    //Return the context menu
    return([[adium menuController] contextualMenuWithLocations:[NSArray arrayWithObjects:
        [NSNumber numberWithInt:Context_Contact_Manage],
        [NSNumber numberWithInt:Context_Contact_Action],
        [NSNumber numberWithInt:Context_Contact_NegativeAction],
        [NSNumber numberWithInt:Context_Contact_Additions], nil]
                                                    forContact:[contactListView contact]]);
}

//Auto-resizing support -----------------------------------------------------------------
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
    [[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:contactListView];
}

- (void)screenParametersChanged:(NSNotification *)notification
{
    [contactListView performFullRecalculation];
}

// Tooltips ------------------------------------------------------------------------------------
//Add a tracking rect to catch when the mouse enters/exits our view
- (void)updateTooltipTrackingRect
{
    NSView		*windowContentView = [[contactListView window] contentView];
    NSScrollView	*scrollView = [contactListView enclosingScrollView];
    NSRect	 	trackingRect;
    NSPoint		localPoint;
    BOOL		mouseInside;

    [self _endTrackingMouse]; //Hide any open tooltips

    //Remove the existing tracking rect
    if (tooltipTrackingTag != -1)
        [windowContentView removeTrackingRect:tooltipTrackingTag];


    //Add a new tracking rect
    trackingRect = [scrollView frame];
    trackingRect.size.width = [scrollView contentSize].width; //Adjust to not include the scrollbar
    localPoint = [[contactListView window] convertScreenToBase:[NSEvent mouseLocation]];
    mouseInside = NSPointInRect(localPoint, trackingRect);

    tooltipTrackingTag = [windowContentView addTrackingRect:trackingRect
                                                      owner:self
                                                   userData:scrollView
                                               assumeInside:mouseInside];

    //If the mouse is already inside, start tracking
    if(mouseInside){
        [self mouseEntered:nil];
    }

}

//Called when the mouse enters the view
// - When the mouse enters, we being tracking cursor movement.
// - tooltipCount starts at 0.  It is periodically incremented.
// - If the mouse moves, tooltipCount is reset to 0
// When the user holds the mouse still over the contact list, tooltipCount will eventually get larger than TOOL_TIP_DELAY.  When this happens, we begin displaying tooltips.
- (void)mouseEntered:(NSEvent *)theEvent
{
    if(!trackingMouseMovedEvents){
        trackingMouseMovedEvents = YES;
        [[contactListView window] setAcceptsMouseMovedEvents:YES]; //Start generating mouse-moved events

        //Start our mouse movement timer
        tooltipCount = 0;
        tooltipTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/TOOL_TIP_CHECK_INTERVAL)
                                                         target:self
                                                       selector:@selector(tooltipTimer:)
                                                       userInfo:nil
                                                        repeats:YES] retain];
    }
}

//Increment the tooltipCount variable
- (void)tooltipTimer:(NSTimer *)inTimer
{
    tooltipCount++;

    if(tooltipCount > TOOL_TIP_DELAY){ //If the user has held still long enough
        [self _showTooltipAtPoint:[NSEvent mouseLocation]]; //Show the tooltip
        [tooltipTimer invalidate]; [tooltipTimer release]; tooltipTimer = nil; //Stop the tooltip timer
    }
}

//Called when the mouse leaves the view
- (void)mouseExited:(NSEvent *)theEvent
{
    [self _endTrackingMouse];
}

//Stop tracking mouse events, stop displaying tooltips
- (void)_endTrackingMouse
{
    if(trackingMouseMovedEvents){
        trackingMouseMovedEvents = NO;
        [[contactListView window] setAcceptsMouseMovedEvents:NO]; //Stop generating mouse-moved events
        [self _showTooltipAtPoint:NSMakePoint(0,0)]; //Hide the tooltip
        [tooltipTimer invalidate]; [tooltipTimer release]; tooltipTimer = nil; //Stop the tooltip timer
    }
}

//Called as the mouse moves across the view
- (void)mouseMoved:(NSEvent *)theEvent
{
    if(trackingMouseMovedEvents){
        if(tooltipCount > TOOL_TIP_DELAY){ //If we are displaying tooltips
            //Update the displayed tooltip
            [self _showTooltipAtPoint:[[theEvent window] convertBaseToScreen:[theEvent locationInWindow]]];
        }else{
            //Otherwise, reset tooltipCount to 0 since the mouse has moved
            tooltipCount = 0;
        }
    }
}

//Show the correctly positioned tooltip (Pass a screen point)
//Pass (0,0) to hide the tooltip
- (void)_showTooltipAtPoint:(NSPoint)screenPoint
{
    if(screenPoint.x != 0 && screenPoint.y != 0){
        if( (allowTooltipsInBackground && [NSApp isActive]) || 
            ([[contactListView window] isKeyWindow]) ){
            NSPoint		viewPoint;
            AIListObject	*hoveredObject;
            int			hoveredRow;

            //Extract data from the event
            viewPoint = [contactListView convertPoint:[[contactListView window] convertScreenToBase:screenPoint] fromView:nil];

            //Get the hovered contact
            hoveredRow = [contactListView rowAtPoint:viewPoint];
            hoveredObject = [contactListView itemAtRow:hoveredRow];

            //Show tooltip for it
            [[adium interfaceController] showTooltipForListObject:hoveredObject atPoint:screenPoint];
        }
    }else{
        [[adium interfaceController] showTooltipForListObject:nil atPoint:NSMakePoint(0,0)];
    }
}

@end


