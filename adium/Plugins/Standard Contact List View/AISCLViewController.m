//
//  AISCLViewController.m
//  Adium
//
//  Created by Adam Iser on Sat Apr 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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
- (void)itemDidExpand:(NSNotification *)notification;
- (void)itemDidCollapse:(NSNotification *)notification;
- (void)frameDidChange:(NSNotification *)notification;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)_endTrackingMouse;
- (void)mouseMoved:(NSEvent *)theEvent;
- (void)_showTooltipAtPoint:(NSPoint)screenPoint;
- (void)expandCollapseGroup:(AIListGroup *)inGroup subgroups:(BOOL)subgroups supergroups:(BOOL)supergroups outlineView:(NSOutlineView *)inView;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidExpand:) name:NSOutlineViewItemDidExpandNotification object:contactListView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidCollapse:) name:NSOutlineViewItemDidCollapseNotification object:contactListView];

    [contactListView setTarget:self];
    [contactListView setDataSource:self];
    [contactListView setDelegate:self];
    [contactListView setDoubleAction:@selector(performDefaultActionOnSelectedContact:)];
    [self expandCollapseGroup:contactList subgroups:YES supergroups:NO outlineView:contactListView]; //Correctly expand/collapse groups

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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:[contactListView window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:[contactListView window]];

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
    [self expandCollapseGroup:contactList subgroups:YES supergroups:NO outlineView:contactListView]; //Correctly expand/collapse groups
}

//Reload the contact list (if updates aren't delayed)
- (void)contactOrderChanged:(NSNotification *)notification
{
    if(![[owner contactController] holdContactListUpdates]){
        AIListObject		*object = [notification object];
        
        //Redisplay
        [contactListView reloadData];

        //Correctly expand/collapse the groups
        if(!object){ //If passed nil, expand the entire contact list
            [self expandCollapseGroup:nil subgroups:YES supergroups:NO outlineView:contactListView];

        }else if([object isKindOfClass:[AIListGroup class]]){ //If passed a group, expand it and all groups above it
            [self expandCollapseGroup:(AIListGroup *)object subgroups:NO supergroups:YES outlineView:contactListView];
            
        }else if([object isKindOfClass:[AIListContact class]]){ //If passed a contact, expand its containing group and all groups above it
            [self expandCollapseGroup:[object containingGroup] subgroups:NO supergroups:YES outlineView:contactListView];

        }
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
        NSColor		*backgroundColor = [[prefDict objectForKey:KEY_SCL_BACKGROUND_COLOR] representedColorWithAlpha:alpha];
        NSColor		*gridColor = [[prefDict objectForKey:KEY_SCL_GRID_COLOR] representedColorWithAlpha:alpha];
        BOOL		alternatingGrid = [[prefDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue];
        
        //Display
        [contactListView setFont:font];
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
    //Remove any existing observer (if one exists)
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:nil];
    
    //Observe scrollview frame changes (so we can update our cursor tracking rect)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:[inSuperview superview]];

    //Observe the window entering and leaving key (for tooltips)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_endTrackingMouse) name:NSWindowDidResignKeyNotification object:[inSuperview window]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSWindowDidBecomeKeyNotification object:[inSuperview window]]; //Force a frame update when window becomes key
}

//Expand & collapse a group
- (void)itemDidExpand:(NSNotification *)notification
{
    [[[notification userInfo] objectForKey:@"NSObject"] setExpanded:YES];
}
- (void)itemDidCollapse:(NSNotification *)notification
{
    [[[notification userInfo] objectForKey:@"NSObject"] setExpanded:NO];
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

//Correctly sets the contact groups as expanded or collapsed, depending on their saved state
- (void)expandCollapseGroup:(AIListGroup *)inGroup subgroups:(BOOL)subgroups supergroups:(BOOL)supergroups outlineView:(NSOutlineView *)inView
{
    NSEnumerator	*enumerator;
    AIListObject	*object;
    
    if(!inGroup) inGroup = contactList;

    //Expand/Collapse the group that was passed to us
    if(inGroup != contactList){
        ([inGroup isExpanded] ? [inView expandItem:inGroup] : [inView collapseItem:inGroup]);
    }
    
    //Expand/Collapse its supergroups
    if(supergroups){
        AIListGroup	*containingGroup = [inGroup containingGroup];
        
        if(containingGroup){
            //Expand the supergroup
            [self expandCollapseGroup:containingGroup subgroups:NO supergroups:YES outlineView:inView];

            //Correctly expand/collapse the group
            ([containingGroup isExpanded] ? [inView expandItem:containingGroup] : [inView collapseItem:containingGroup]);
        }
    }
    
    //Expand/Collapse its subgroups
    enumerator = [inGroup objectEnumerator];
    while((object = [enumerator nextObject])){
        if([object isKindOfClass:[AIListGroup class]]){
            //Correctly expand/collapse the group
            ([(AIListGroup *)object isExpanded] ? [inView expandItem:object] : [inView collapseItem:object]);

            //Expand/collapse any subgroups
            if(subgroups){
                [self expandCollapseGroup:(AIListGroup *)object subgroups:YES supergroups:NO outlineView:inView];
            }
        }
    }
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
    tooltipTrackingTag = [windowContentView addTrackingRect:trackingRect
                                                      owner:self
                                                   userData:scrollView
                                               assumeInside:mouseInside];

    //If the mouse is already inside, start tracking
    localPoint = [[contactListView window] convertScreenToBase:[NSEvent mouseLocation]];
    mouseInside = NSPointInRect(localPoint, [scrollView frame]);
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
    trackingMouseMovedEvents = NO;
    [[contactListView window] setAcceptsMouseMovedEvents:NO]; //Stop generating mouse-moved events
    [self _showTooltipAtPoint:NSMakePoint(0,0)]; //Hide the tooltip
    [tooltipTimer invalidate]; [tooltipTimer release]; tooltipTimer = nil; //Stop the tooltip timer
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





