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

#define TOOL_TIP_CHECK_INTERVAL	5.0	//Check for mouse movement 5 times a second
#define TOOL_TIP_DELAY 		3	//Number of check intervals of no movement before a tip is displayed

@interface AISCLViewController (PRIVATE)
- (AISCLViewController *)initWithOwner:(id)inOwner;
- (void)contactListChanged:(NSNotification *)notification;
- (void)contactOrderChanged:(NSNotification *)notification;
- (void)contactAttributesChanged:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)frameDidChange:(NSNotification *)notification;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)_endTrackingMouse;
- (void)mouseMoved:(NSEvent *)theEvent;
- (void)_showTooltipAtPoint:(NSPoint)screenPoint;
- (void)updateTooltipTrackingRect;
@end

@implementation AISCLViewController

+ (AISCLViewController *)contactListViewControllerWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);    
}

- (AISCLViewController *)initWithOwner:(id)inOwner
{
    [super init];

    //Init
    contactListView = [[AISCLOutlineView alloc] init];
    owner = [inOwner retain];
    tooltipTrackingTag = 0;
    trackingMouseMovedEvents = NO;
    tooltipTimer = nil;
    tooltipCount = 0;

    //Apply the preferences to our view
    [self preferencesChanged:nil];

    //Install the necessary observers
    [[owner notificationCenter] addObserver:self selector:@selector(contactListChanged:) name:Contact_ListChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(contactOrderChanged:) name:Contact_OrderChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(contactAttributesChanged:) name:Contact_AttributesChanged object:nil];
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

//    [contactListView setIndentationPerLevel:0];
    [contactListView setTarget:self];
    [contactListView setDataSource:self];
    [contactListView setDelegate:self];
    [contactListView setDoubleAction:@selector(performDefaultActionOnSelectedContact:)];

    //Fetch and update the contact list
    [self contactListChanged:nil];
    
    return(self);
}

- (void)closeView
{
    //Remove observers (general)
    [[owner notificationCenter] removeObserver:self name:Contact_ListChanged object:nil];
    [[owner notificationCenter] removeObserver:self name:Contact_OrderChanged object:nil];
    [[owner notificationCenter] removeObserver:self name:Contact_AttributesChanged object:nil];
    [[owner notificationCenter] removeObserver:self name:Preference_GroupChanged object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewItemDidExpandNotification object:contactListView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewItemDidCollapseNotification object:contactListView];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
    
    //Hide any open tooltips
    [self _endTrackingMouse];

    //Close down and release the view
    [contactListView setTarget:nil];
    [contactListView setDataSource:nil];
    [contactListView setDelegate:nil];
    [contactListView release];
    [owner release];
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
    //Fetch the new contact list
    [contactList release]; contactList = [[[owner contactController] contactList] retain];

    //Redisplay
    [contactListView reloadData];
}

//Reload the contact list (if updates aren't delayed)
- (void)contactOrderChanged:(NSNotification *)notification
{
    if(![[owner contactController] holdContactListUpdates]){        
        [contactListView reloadData]; //Redisplay
    }
}

//Redisplay the modified object
- (void)contactAttributesChanged:(NSNotification *)notification
{
    AIListContact	*contact = [notification object];

    if(contact){ //Simply redraw the modified contact
        int row = [contactListView rowForItem:contact];

        if(row >= 0){
            [contactListView setNeedsDisplayInRect:[contactListView rectOfRow:row]];
        }
    }
}

//A contact list preference has changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_CONTACT_LIST] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
        NSFont		*font = [[prefDict objectForKey:KEY_SCL_FONT] representedFont];
        float		alpha = [[prefDict objectForKey:KEY_SCL_OPACITY] floatValue];
        NSColor		*color = [[prefDict objectForKey:KEY_SCL_GROUP_COLOR] representedColor];
        NSColor		*invertedColor = [[prefDict objectForKey:KEY_SCL_GROUP_COLOR_INVERTED] representedColor];
        NSColor		*backgroundColor = [[prefDict objectForKey:KEY_SCL_BACKGROUND_COLOR] representedColorWithAlpha:alpha];
        NSColor		*gridColor = [[prefDict objectForKey:KEY_SCL_GRID_COLOR] representedColorWithAlpha:alpha];
        BOOL		alternatingGrid = [[prefDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue];

        //Cap the font to size 12
        
        
        //Display
        [contactListView setFont:font];
        [contactListView setColor:color andInvertedColor:invertedColor];
        [contactListView setRowHeight:[font defaultLineHeightForFont]];
        [contactListView setBackgroundColor:backgroundColor];
        
        //Grid
        [contactListView setDrawsAlternatingRows:alternatingGrid];
        [contactListView setAlternatingRowColor:gridColor];

        /*
            For this view to be transparent, it's containing window must be set as non-opaque.  It would make sense to use: [[contactListView window] setOpaque:(alpha == 100.0)];

            However, setting a window to opaque causes it's contents to be shadowed.  It is a pain (and a major speed hit) to maintain shadows beneath the contact list text.  A little trick to prevent the window manager from shadowing the window content is to set the window itself as non-opaque.  The contents of a window that is non-opaque will not cast a shadow.  Setting the window's alpha value to 0.9999999 removes the shadowing without giving the slightest appearance of opacity to the window titlebar and widgets.
            */
        [[contactListView window] setAlphaValue:(alpha == 100.0 ? 1.0 : 0.9999999)];

    }
}

//Called when our view moves to another superview, update the traking rect
- (void)view:(NSView *)inView didMoveToSuperview:(NSView *)inSuperview
{
    //Remove any existing observers (if they exists)
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

    if([selectedObject isKindOfClass:[AIListGroup class]]){
        //Expand or collapse the group
        if([sender isItemExpanded:selectedObject]){
            [sender collapseItem:selectedObject];
        }else{
            [sender expandItem:selectedObject];
        }
    
    }else{
        NSDictionary	*notificationDict;

        //Open a new message with the contact
        notificationDict = [NSDictionary dictionaryWithObjectsAndKeys:selectedObject, @"To", nil];
        [[owner notificationCenter] postNotificationName:Interface_InitiateMessage object:nil userInfo:notificationDict];
    }
}

// Outline View data source methods
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(item == nil){
        return([contactList sortedObjectAtIndex:index]);
    }else{
        return([item sortedObjectAtIndex:index]);
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
        return([contactList sortedCount]);
    }else{
        return([item sortedCount]);
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
        [[owner notificationCenter] postNotificationName:Interface_ContactSelectionChanged object:outlineView userInfo:notificationDict];
    
    }else{
        [[owner notificationCenter] postNotificationName:Interface_ContactSelectionChanged object:outlineView userInfo:nil];
    
    }
}

- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
    [item setExpanded:state];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView expandStateOfItem:(id)item
{
    return([item isExpanded]);
}

//Manual Ordering support
- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard
{
    return(YES);
}

- (NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    return(NSDragOperationPrivate);
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
    return(YES);
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
        if([[contactListView window] isKeyWindow]){
            NSPoint		viewPoint;
            AIListObject	*hoveredObject;
            int			hoveredRow;

            //Extract data from the event
            viewPoint = [contactListView convertPoint:[[contactListView window] convertScreenToBase:screenPoint] fromView:nil];

            //Get the hovered contact
            hoveredRow = [contactListView rowAtPoint:viewPoint];
            hoveredObject = [contactListView itemAtRow:hoveredRow];

            //Show tooltip for it
            [[owner interfaceController] showTooltipForListObject:hoveredObject atPoint:screenPoint];
        }
    }else{
        [[owner interfaceController] showTooltipForListObject:nil atPoint:NSMakePoint(0,0)];
    }
}

@end





