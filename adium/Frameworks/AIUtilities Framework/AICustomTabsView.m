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

#import "AICustomTabsView.h"
#import "AICustomTabCell.h"
#import "AIImageUtilities.h"
#import "AIViewAdditions.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIMessageViewController.h"
#import "AIMessageTabViewItem.h"
#import "AIEventAdditions.h"

@interface AICustomTabsView (PRIVATE)
- (void)rebuildCells;
- (void)smoothlyArrangeCells;
- (BOOL)arrangeCellsAbsolute:(BOOL)absolute;
- (int)totalTabWidth;
- (void)_beginDragOfTabWithEvent:(NSEvent *)theEvent;
- (void)_updateDragAtOffset:(int)inOffset;
- (BOOL)_concludeDrag;
- (AICustomTabCell *)_cellAtPoint:(NSPoint)clickLocation;
- (void)_startTrackingCursor;
- (void)_stopTrackingCursor;
- (NSArray *)acceptableDragTypes;
- (void)setFocusedForDrag:(BOOL)value;
- (void)insertDraggedTabAtIndex:(int)index overridingSelectionIfAppropriate:(BOOL)doNotSelect;
@end

#define TAB_DRAG_DISTANCE 	4               //Distance required before a drag kicks in
#define TAB_CELL_IDENTIFIER     @"Tab Cell Identifier"

#define CUSTOM_TABS_FPS		30.0		//Animation speed
#define CUSTOM_TABS_OVERLAP	2		//Overlapped pixels between tabs
#define CUSTOM_TABS_INDENT	3

static  AICustomTabCell	*dragTabCell;

@implementation AICustomTabsView

//Create a new custom tab view
+ (id)customTabViewWithFrame:(NSRect)frameRect
{
    return([[[self alloc] initWithFrame:frameRect] autorelease]);
}

//Private ------------------------------------------------------------------------------
//Configure the tabs when awaking from a nib
- (void)awakeFromNib
{
    //since the tab view is likely to initialize after this custom tab view,
    //causing the configure inside of init to not work, we configure again
    //here when we know the tab view has loaded.
    [self rebuildCells];
}

//init
- (id)initWithFrame:(NSRect)frameRect
{
    //Init
    [super initWithFrame:frameRect];
    tabCellArray = nil;
    selectedCustomTabCell = nil;
    dragTabCell = nil;
    draggedIndex = -1;
    
    //Load our images
    tabDivider = [[AIImageUtilities imageNamed:@"Tab_Divider" forClass:[self class]] retain];

    //register as a drag observer:
    [self registerForDraggedTypes:[self acceptableDragTypes]];

    //Configure our tab cells
    [self rebuildCells];

    return(self);
}

//
- (void)dealloc
{
    [tabCellArray release];
    [tabDivider release];
    [selectedCustomTabCell release];
    [super dealloc];
}

//Set our delegate
- (void)setDelegate:(id <AICustomTabsViewDelegate>)inDelegate
{
    delegate = inDelegate;
}

//Set our owner - needed only if we're going to be transferring message tabs via the interfaceController
- (void)setOwner:(AIAdium *)inOwner;
{
    owner = inOwner;
    [owner retain];
}

//Allow tab switching from the background
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return(YES);
}

//Rebuild the tab cells for this view
- (void)rebuildCells
{
    int	loop;

    //Remove any existing tab cells
    [tabCellArray release]; tabCellArray = [[NSMutableArray alloc] init];

    //Create a tab cell for each tabViewItem
    for(loop = 0;loop < [tabView numberOfTabViewItems];loop++){
        NSTabViewItem		*tabViewItem = [tabView tabViewItemAtIndex:loop];
        AICustomTabCell		*tabCell;

        //Create a new tab cell
        tabCell = [AICustomTabCell customTabForTabViewItem:tabViewItem];
        [tabCell setSelected:(tabViewItem == [tabView selectedTabViewItem])];

        //Update our direct reference to the selected cell
        if(tabViewItem == [tabView selectedTabViewItem]){
            [selectedCustomTabCell release]; selectedCustomTabCell = [tabCell retain];
        }

        //Add the tab cell to our array
        [tabCellArray addObject:tabCell];
    }

    //Arrange our cells
    [self arrangeCellsAbsolute:YES];
}

//Draw
- (void)drawRect:(NSRect)rect
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell, *nextTabCell;
    NSRect		tabFrame, viewFrame;
    NSRect		drawRect;
    NSPoint		drawPointA, drawPointB;

    //Get the active tab's frame
    tabFrame = [selectedCustomTabCell frame];
    viewFrame = [self frame];

    //Paint black over region left of active tab
    drawRect = NSMakeRect(viewFrame.origin.x,
                          viewFrame.origin.y + 1,
                          tabFrame.origin.x - viewFrame.origin.x,
                          viewFrame.size.height - 1);
    if(NSIntersectsRect(drawRect, rect)){
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.20] set];
        [NSBezierPath fillRect:NSIntersectionRect(drawRect, rect)];
    }

    //Draw the black tab line left of active tab
    drawPointA = NSMakePoint(drawRect.origin.x, drawRect.origin.y + drawRect.size.height - 0.5);
    drawPointB = NSMakePoint(drawRect.origin.x + drawRect.size.width, drawRect.origin.y + drawRect.size.height - 0.5);
    if(drawPointA.y > rect.origin.y && drawPointA.y < NSMaxY(rect)){
        //Crop line to fit within drawn rect
        if(drawPointA.x < rect.origin.x) drawPointA.x = rect.origin.x;
        if(drawPointB.x > NSMaxX(rect)) drawPointB.x = NSMaxX(rect);
        
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.38] set];
        [NSBezierPath strokeLineFromPoint:drawPointA toPoint:drawPointB];
    }

    //Paint black over region right of active tab
    drawRect = NSMakeRect(tabFrame.origin.x + tabFrame.size.width,
                          viewFrame.origin.y + 1,
                          (viewFrame.origin.x + viewFrame.size.width) - (tabFrame.origin.x + tabFrame.size.width),
                          viewFrame.size.height - 1);
    if(NSIntersectsRect(drawRect, rect)){
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.20] set];
        [NSBezierPath fillRect:NSIntersectionRect(drawRect, rect)];
    }

    //Draw the black tab line right of active tab
    drawPointA = NSMakePoint(drawRect.origin.x, drawRect.origin.y + drawRect.size.height - 0.5);
    drawPointB = NSMakePoint(drawRect.origin.x + drawRect.size.width, drawRect.origin.y + drawRect.size.height - 0.5);
    if(drawPointA.y > rect.origin.y && drawPointA.y < NSMaxY(rect)){
        //Crop line to fit within drawn rect
        if(drawPointA.x < rect.origin.x) drawPointA.x = rect.origin.x;
        if(drawPointB.x > NSMaxX(rect)) drawPointB.x = NSMaxX(rect);
        
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.38] set];
        [NSBezierPath strokeLineFromPoint:drawPointA toPoint:drawPointB];
    }

    //Bottom edge light
    drawPointA = NSMakePoint(viewFrame.origin.x, viewFrame.origin.y + 1.5);
    drawPointB = NSMakePoint(viewFrame.origin.x + viewFrame.size.width, viewFrame.origin.y + 1.5);
    if(drawPointA.y > rect.origin.y && drawPointA.y < NSMaxY(rect)){
        //Crop line to fit within drawn rect
        if(drawPointA.x < rect.origin.x) drawPointA.x = rect.origin.x;
        if(drawPointB.x > NSMaxX(rect)) drawPointB.x = NSMaxX(rect);
        
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.16] set];
        [NSBezierPath strokeLineFromPoint:drawPointA toPoint:drawPointB];
    }
    
    //Bottom edge dark
    drawPointA = NSMakePoint(viewFrame.origin.x, viewFrame.origin.y + 0.5);
    drawPointB = NSMakePoint(viewFrame.origin.x + viewFrame.size.width, viewFrame.origin.y + 0.5);
    if(drawPointA.y > rect.origin.y && drawPointA.y < NSMaxY(rect)){
        //Crop line to fit within drawn rect
        if(drawPointA.x < rect.origin.x) drawPointA.x = rect.origin.x;
        if(drawPointB.x > NSMaxX(rect)) drawPointB.x = NSMaxX(rect);

        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.41] set];
        [NSBezierPath strokeLineFromPoint:drawPointA toPoint:drawPointB];
    }

    //Draw our tabs
    enumerator = [tabCellArray objectEnumerator];
    tabCell = [enumerator nextObject];
    while((nextTabCell = [enumerator nextObject]) || tabCell){
        NSRect	cellFrame = [tabCell frame];

        if(NSIntersectsRect(cellFrame, rect)){
            //Draw the tab cell
            [tabCell drawWithFrame:cellFrame inView:self];

            //Draw the divider
            if(tabCell != selectedCustomTabCell && (!nextTabCell || nextTabCell != selectedCustomTabCell)){
                [tabDivider compositeToPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width - 2, cellFrame.origin.y) operation:NSCompositeSourceOver];
            }
        }

        tabCell = nextTabCell;
    }
}


//Behavior --------------------------------------------------------------------------------
//Close a tab view item
- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem
{
    //Inform our delegate
    if([delegate respondsToSelector:@selector(customTabView:shouldCloseTabViewItem:)]){
        [delegate customTabView:self shouldCloseTabViewItem:tabViewItem];
    }

    //Remove the item (If the delegate didn't already)
    if([tabView indexOfTabViewItem:tabViewItem] != NSNotFound){
        [tabView removeTabViewItem:tabViewItem];
    }
}


//Change our selection to match the current selected tabViewItem
- (void)tabView:(NSTabView *)inTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;
    NSTabViewItem	*selectedTab = [inTabView selectedTabViewItem];

    //Set old cell for a redisplay
    [self setNeedsDisplayInRect:[selectedCustomTabCell frame]];

    //Record the new selected tab cell, and correctly set it as selected
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        if([tabCell tabViewItem] == selectedTab){
            [tabCell setSelected:YES];
            [selectedCustomTabCell release];
            selectedCustomTabCell = [tabCell retain];
        }else{
            [tabCell setSelected:NO];
        }
    }

    //Redisplay new cell
    [self setNeedsDisplayInRect:[selectedCustomTabCell frame]];

    //Inform our delegate
    if([delegate respondsToSelector:@selector(customTabView:didSelectTabViewItem:)]){
        [delegate customTabView:self didSelectTabViewItem:tabViewItem];
    }
}

//Rebuild our tab list to match the tabView
- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)TabView
{
    //Stop cursor tracking
    [self _stopTrackingCursor];

    //Rebuild cells
    [self rebuildCells];

    //new
    if(dragTabCell){
        if(!viewsRearranging) [self smoothlyArrangeCells];
    }else{
        [self arrangeCellsAbsolute:YES]; //Force all our items into the correct spot
    }
    
    //Start cursor tracking
    [self _startTrackingCursor];

    //Inform our delegate
    if([delegate respondsToSelector:@selector(customTabViewDidChangeNumberOfTabViewItems:)]){
        [delegate customTabViewDidChangeNumberOfTabViewItems:self];
    }
}

//Intercept frame changes and correctly resize our tabs
- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self arrangeCellsAbsolute:YES];

    //Reset cursor tracking
    [self _stopTrackingCursor];
    [self _startTrackingCursor];
}

//Stop dragging in metal mode
- (BOOL)mouseDownCanMoveWindow
{
    return(NO);
}

//Returns the total width of our tab tops
- (int)totalTabWidth
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;
    int			totalWidth = 0;

    totalWidth = CUSTOM_TABS_OVERLAP + (CUSTOM_TABS_INDENT * 2);
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        totalWidth += [tabCell size].width - CUSTOM_TABS_OVERLAP;
    }

    return(totalWidth);
}


//Cursor Tracking -----------------------------------------------------------------------
- (void)_startTrackingCursor
{
    //Track only if we're within a valid window
    if([self window]){
        NSEnumerator		*enumerator;
        AICustomTabCell		*tabCell;
        NSTrackingRectTag	trackingTag;
        NSPoint			localPoint;

        //Local mouse location
        localPoint = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
        localPoint = [self convertPoint:localPoint fromView:nil];

        //Install a tracking rect for each open tab
        enumerator = [tabCellArray objectEnumerator];
        while((tabCell = [enumerator nextObject])){
            NSRect trackRect = [tabCell frame];

            //Compensate for overlap
            trackRect.origin.x += CUSTOM_TABS_OVERLAP;
            trackRect.size.width -= CUSTOM_TABS_OVERLAP;

            //add the tracking tag
            trackingTag = [self addTrackingRect:trackRect owner:self userData:tabCell assumeInside:NSPointInRect(localPoint, trackRect)];
            [tabCell setTrackingTag:trackingTag];
        }
    }
}

- (void)_stopTrackingCursor
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;

    //Remove the tracking rect for each open tab
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
            [self removeTrackingRect:[tabCell trackingTag]];
            [tabCell setTrackingTag:0];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    AICustomTabCell	*tabCell = [theEvent userData];

    [tabCell setHighlighted:YES];
    [self setNeedsDisplayInRect:[tabCell frame]];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    AICustomTabCell	*tabCell = [theEvent userData];

    [tabCell setHighlighted:NO];
    [self setNeedsDisplayInRect:[tabCell frame]];
}



//Clicking & Dragging ----------------------------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint		clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    AICustomTabCell	*tabCell = [self _cellAtPoint:clickLocation];

    //Remember for dragging
    lastClickLocation = clickLocation;

    if(tabCell){
        //Give the tab cell a chance to handle tracking
        if(![tabCell willTrackMouse:theEvent inRect:[tabCell frame] ofView:self]
            && ![NSEvent cmdKey]){
            //Select the tab (if we're not holding down cmd)
            [tabView selectTabViewItem:[tabCell tabViewItem]];
        }
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint	clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    //if we're not in the middle of a drag already and we've moved enough, attempt to initiate a drag 
    if(!draggingATabCell){
        if( (lastClickLocation.x - clickLocation.x) > TAB_DRAG_DISTANCE || (lastClickLocation.x - clickLocation.x) < -TAB_DRAG_DISTANCE ||
            (lastClickLocation.y - clickLocation.y) > TAB_DRAG_DISTANCE || (lastClickLocation.y - clickLocation.y) < -TAB_DRAG_DISTANCE ){
            [self _beginDragOfTabWithEvent:theEvent];
        }
    }
}


- (void)mouseUp:(NSEvent *)theEvent
{

}

//Drag tracking methods ------------------------------------------------------------------------
//Called when a drag enters this toolbar
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard 	*pboard = [sender draggingPasteboard];
    NSString 		*type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSRTFPboardType,TAB_CELL_IDENTIFIER,nil]];
    NSDragOperation	operation = NSDragOperationNone;

    if (type) {
	if ([type isEqualToString:NSRTFPboardType]) { //got RTF data
	    operation = NSDragOperationCopy;
	} else if ([type isEqualToString:TAB_CELL_IDENTIFIER]) { //got a tab
            hoverSize = [[sender draggedImage] size]; //want to know how much space to allow for the hover
	    [self setFocusedForDrag:YES];
            operation = NSDragOperationPrivate;
	}
    }
    return(operation);
}

//Called continuously as the drag is over the tab bar
- (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPoint		dragLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
    NSPasteboard 	*pboard = [sender draggingPasteboard];
    NSString 		*type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSRTFPboardType,TAB_CELL_IDENTIFIER,nil]];
    

    NSDragOperation	operation = NSDragOperationNone;

    if (type) {
	if ([type isEqualToString:NSRTFPboardType]) { //got RTF data
	    AICustomTabCell	*tabCell = [self _cellAtPoint:dragLocation];
	    if(tabCell != nil) {
		if ( [tabView selectedTabViewItem] != [tabCell tabViewItem] ) //Select the tab
		    [tabView selectTabViewItem:[tabCell tabViewItem]];

		operation = NSDragOperationCopy;
	    }
	    
	} else if ([type isEqualToString:TAB_CELL_IDENTIFIER]) { //got a tab
	    NSEnumerator 	*enumerator = [tabCellArray objectEnumerator];
	    AICustomTabCell	*tabCell;
	    int			dragXLocation = [sender draggingLocation].x - [self frame].origin.x;
	    int			lastLocation = 0;
	    int			index = -1;
            int                 foundIndex = -1;
            
	    //Figure out where the user is hovering the tabcell item
	    while((tabCell = [enumerator nextObject])){
                if (tabCell != dragTabCell) { //don't want to look at the cell we're dragging
		NSRect	 frame = [tabCell frame];
                index++;
                if((dragXLocation > lastLocation) && (dragXLocation < frame.origin.x + (frame.size.width / 2.0) ) ){
                    foundIndex = index;
		    break;
		}
		lastLocation = frame.origin.x;
                }
	    }
	    //If they're off to the right, the index is one past the last index - that is, the count
	    if(foundIndex == -1 && dragXLocation > lastLocation) foundIndex = [tabCellArray count];

	    //Set the new drag index if it's not already set
	    if(hoverIndex != foundIndex){
		hoverIndex = foundIndex;
		if(!viewsRearranging){
		    [self smoothlyArrangeCells];
		}
	    }

	    if(foundIndex != -1){ //OperationPrivate if finding an index was sucessful
		operation = NSDragOperationPrivate;
	    }
//            else NSLog(@"Operation none!");
	}
    }
    
    return operation;
}

//Called when the drag exits this tab bar; should restore the pre-hover arrangement
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    NSPasteboard 	*pboard = [sender draggingPasteboard];
    NSString 		*type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER,nil]];

    if(type){
        //Stop tracking the drag
        hoverIndex = -1;
        [self setFocusedForDrag:NO];
        
        //Let all the views settle back into place
        if(!viewsRearranging){
            [self smoothlyArrangeCells];
        }
    }
}

//Dragging Source ---------------------------------------------------------------------------------
//Initiate a drag
- (void)_beginDragOfTabWithEvent:(NSEvent *)theEvent
{
    NSPoint		clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    AICustomTabCell     *inTabCell = [self _cellAtPoint:clickLocation];
        
    draggedIndex = [tabCellArray indexOfObject:inTabCell];
    
    //dragging around outside the tabs but in the tab bar can trigger an event we don't want.  Make sure we've got a real tab.
    if(draggedIndex != NSNotFound) {
        NSImage		*image;
        NSRect		imageRect;
        NSRect		frame = [inTabCell frame];
        
        draggingATabCell = YES;
        tabHasBeenDragged = NO;
        
        dragTabCell = [inTabCell retain]; //we keep retaining until the window disappears... the possible interactions between windows are just too difficult to trace autorelease pools and such
        
        //Don't manually track the cursor during the dragging fun and games
        [self _stopTrackingCursor];
            
        //Create an image of the tab to drag
        image = [[[NSImage alloc] initWithSize:frame.size] autorelease];
        imageRect = NSMakeRect(0,0,frame.size.width,frame.size.height);
        [image lockFocus];
        [inTabCell drawWithFrame:imageRect inView:self];
        [image unlockFocus];
        
        dragImage = [[[NSImage alloc] initWithSize:frame.size] autorelease];
        [dragImage setBackgroundColor:[NSColor clearColor]];
        [dragImage lockFocus];
        [image dissolveToPoint:NSMakePoint(0,0) fraction:0.9];
        [dragImage unlockFocus];
        
        NSPasteboard 	*pboard;
        
        //Put information on the pasteboard
        pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
        [pboard declareTypes:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER, @"CommandKey",nil] owner:self];
        [pboard setString:TAB_CELL_IDENTIFIER forType:TAB_CELL_IDENTIFIER]; //useless data to satisfy the pboard; our important data is in the static dragTabCell
        [pboard setString:[[NSNumber numberWithInt:[NSEvent cmdKey]] stringValue] forType:@"CommandKey"]; //useful only when moving in the same window
        //Perform the drag
        draggedOffset = NSMakeSize((clickLocation.x - frame.origin.x), (clickLocation.y - frame.origin.y));

        if ([tabView numberOfTabViewItems] == 1)
            draggingLastItem = YES;
        else
            draggingLastItem = NO;
        
        [self retain];
        [self dragImage:dragImage
                     at:NSMakePoint(clickLocation.x - draggedOffset.width, clickLocation.y - draggedOffset.height)
                 offset:NSMakeSize(0,0)
                  event:theEvent pasteboard:pboard source:self slideBack:NO];
        [self release];
        
        draggingATabCell = NO;
        dragTabCell = nil;  //perhaps causing a release crash earlier; for memory optimization, check into this
    }
}

//Invoked as the drag begins
- (void)draggedImage:(NSImage *)image beganAt:(NSPoint)screenPoint
{
    //Arrange the views (without our friend the dragging tab - this should leave a 'hover' space for it in the present location)
    if(!viewsRearranging) {
        [self smoothlyArrangeCells];
    }
    
}

//Invoked as the drag ends
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    BOOL finishUp = NO;
    
    //Dragged to no destination, open a new window and remove tab from this one
    if(operation == NSDragOperationNone) {
        [[owner interfaceController] transferMessageTabContainer:[dragTabCell tabViewItem] toWindow:nil atIndex:-1 withTabBarAtPoint:screenPoint];
        finishUp = YES;
    }
    
    //Dragged to another tab bar
    if(operation == NSDragOperationPrivate && ![tabCellArray containsObject:dragTabCell]) {
        finishUp = YES;
    }
    
    //if we tried to do this dragging the last tab out of the window, this would crash nastily as delegate has been released but we don't know it yet
    if (finishUp && !draggingLastItem) { 
        //Inform our delegate
        if ( [delegate respondsToSelector:@selector(customTabViewDidChangeNumberOfTabViewItems:)]){
            [delegate customTabViewDidChangeNumberOfTabViewItems:self];
        }
        
        draggedIndex = -1; //so smoothlyArrangeCells won't hide our cute lil' cell

        if(!viewsRearranging){
            [self smoothlyArrangeCells];
        }
        //Reset the cursor tracking just to be safe
        [self _stopTrackingCursor];
        [self _startTrackingCursor];
    }
}

//Drag destination methods ------------------------------------------------------------------------

- (NSArray *)acceptableDragTypes {
    return [NSArray arrayWithObjects:NSRTFPboardType,TAB_CELL_IDENTIFIER,nil];
}

//Return YES for acceptance
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return(YES);
}

//importing of data should occur here - add tab to this window and to the tab bar
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSRTFPboardType,TAB_CELL_IDENTIFIER,nil]];
               NSPoint		dragLocation = [self convertPoint:[sender draggingLocation] fromView:nil]; 
    if (type) {
        if ([type isEqualToString:NSRTFPboardType]) { //got RTF data

            AICustomTabCell	*tabCell = [self _cellAtPoint:dragLocation];
            if (tabCell != nil) {
                AIMessageTabViewItem * theTabViewItem = (AIMessageTabViewItem *)[tabCell tabViewItem];
                [[theTabViewItem messageViewController] addToTextEntryView:[NSAttributedString stringWithData:[pboard dataForType:NSRTFPboardType]]];
                return YES;
            }
        }
        
        else if ([type isEqualToString:TAB_CELL_IDENTIFIER]) { //got a tab
            if(hoverIndex >= 0 && hoverIndex <= [tabCellArray count]){
                int	dropIndex = hoverIndex;
                
                //Stop hovering
                hoverIndex = -1;
                
                //Set the frame of the item that was dragged to where the user dropped it, so it will smoothly slide from that position to where it belongs.  This looks cleaner than just 'snapping' the item from where it used to be.
                if(focusedForDrag && dragTabCell){
                    NSPoint	localDrop;
                    
                    localDrop = [sender draggingLocation];
                    
                    //Set our frame to where we were dropped
                    NSRect theFrame = [dragTabCell frame];
                    theFrame.origin = NSMakePoint(localDrop.x - draggedOffset.width, localDrop.y - draggedOffset.height);
                    [dragTabCell setFrame:theFrame];
                }
                
                //Move/insert the item
                BOOL doNotSelect = ([[pboard stringForType:@"CommandKey"] intValue]);
                [self insertDraggedTabAtIndex:dropIndex overridingSelectionIfAppropriate:doNotSelect];            
                [self setFocusedForDrag:NO];
                
                return(YES);
            }
        }
    }
    return NO; //if we made it here, the drag operation didn't work
}
    
//redisplay as necessary here
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
}

//Add the dragging tab to this tab bar
- (void)insertDraggedTabAtIndex:(int)index overridingSelectionIfAppropriate:(BOOL)doNotSelect
{
    NSEnumerator		*enumerator;
    AICustomTabCell		*tabCell;
    NSTabViewItem               *previouslySelectedTabViewItem = nil;
    int rearrangeIndex = 0;
    draggedIndex = -1; //this way smoothlyArrangeCells will show our tab if it had been hiding it
    
    //if the tab is already in this tabView somewhere, just need to reorder - it's quicker to do it ourselves than to make it propagate all the way through the interface chain of command
    if ([tabCellArray containsObject:dragTabCell] ) {  //found the tab in our array
        if (doNotSelect) {
            previouslySelectedTabViewItem = [tabView selectedTabViewItem];
        }
        
        //Exchange the "tabs" (actually views... we leave the origional tabs in their place)
        if(index >= 0 && index <= [tabCellArray count]){
            int existingIndex = [tabCellArray indexOfObject:dragTabCell];
            if(existingIndex != index){
                [tabCellArray removeObjectAtIndex:existingIndex];
                if (index < [tabCellArray count]) {
                    [tabCellArray insertObject:dragTabCell atIndex:index];
                } else {
                    [tabCellArray addObject:dragTabCell];
                }
            }
        }
        
        //Rearrange the tab views
        enumerator = [tabCellArray objectEnumerator];
        while((tabCell = [enumerator nextObject])){
            NSTabViewItem	*customTabView = [tabCell tabViewItem];
            
            if([tabView tabViewItemAtIndex:rearrangeIndex] != customTabView){
                [customTabView retain];
                if ([tabView indexOfTabViewItem:customTabView] != NSNotFound)
                    [tabView removeTabViewItem:customTabView];
                if (rearrangeIndex < [tabView numberOfTabViewItems]) {
                    [tabView insertTabViewItem:customTabView atIndex:rearrangeIndex];
                } else {
                    [tabView addTabViewItem:customTabView];   
                }
                [customTabView release];
            }
            rearrangeIndex++;
        }
        
    } else { //not already in this window - just let the interfaceController handle it
        [[owner interfaceController] transferMessageTabContainer:[dragTabCell tabViewItem] toWindow:[[self window] windowController] atIndex:index withTabBarAtPoint:NSMakePoint(0,0)];
    }            
    
    //Inform our delegate
    if([delegate respondsToSelector:@selector(customTabViewDidChangeNumberOfTabViewItems:)]){
        [delegate customTabViewDidChangeNumberOfTabViewItems:self];
    }
    
    //Arrange the views
    if(!viewsRearranging){
        [self smoothlyArrangeCells];
    }
    
    //Select our new friend if desired, otherwise make sure we're still in the right selection (our original selection)
    if (doNotSelect) {
        if (previouslySelectedTabViewItem) {
            [tabView selectTabViewItem:previouslySelectedTabViewItem];
        }
    } else { 
        [tabView selectTabViewItem:[dragTabCell tabViewItem]];
    }
}
// Context menu ------------------------------------------------------------------------
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    //Darken the clicked tab
    NSPoint		clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    AICustomTabCell	*tabCell = [self _cellAtPoint:clickLocation];

    if(tabCell){
        //Pass this on to our delegate
        if([delegate respondsToSelector:@selector(customTabView:menuForTabViewItem:)]){
            return([delegate customTabView:self menuForTabViewItem:[tabCell tabViewItem]]);
        }
    }

    return(nil);
}

// Cell Positioning -----------------------------------------------------------------------

//Set whether we're focused for a drag or not
- (void)setFocusedForDrag:(BOOL)value
{
    if(focusedForDrag != value){
        focusedForDrag = value;
        [self setKeyboardFocusRingNeedsDisplayInRect:[self frame]];
        [self setNeedsDisplay:YES];
    }
}

//Starts a smooth animation to put the views in their correct places
- (void)smoothlyArrangeCells
{
    BOOL finished = [self arrangeCellsAbsolute:NO];
   // BOOL finished = [self arrangeCellsAbsolute:YES];

    //If all the items aren't in place, we set ourself to adjust them again
    if(!finished){
        viewsRearranging = YES;
        [NSTimer scheduledTimerWithTimeInterval:(1.0/CUSTOM_TABS_FPS) target:self selector:@selector(smoothlyArrangeCells) userInfo:nil repeats:NO];
    }else{
        viewsRearranging = NO;
    }
}

//Re-arrange our views to their correct positions
//returns YES is finished.  Pass NO for a partial movement
- (BOOL)arrangeCellsAbsolute:(BOOL)absolute
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;
    int			xLocation;
    BOOL		finished = YES;

    int		tabExtraWidth;
    int		totalTabWidth;
    int		reducedWidth = 0;
    int		reduceThreshold = 1000000;

    //Get the total tab width
    totalTabWidth = [self totalTabWidth];

    //If the tabs are too wide, we need to shrink the bigger ones down
    tabExtraWidth = totalTabWidth - [self frame].size.width;
    if(tabExtraWidth > 0){
        NSArray		*sortedTabArray;
        NSEnumerator	*enumerator;
        int		tabCount = 0;
        int		totalTabWidth = 0;

        //Make a copy of the tabArray sorted by width
        sortedTabArray = [tabCellArray sortedArrayUsingSelector:@selector(compareWidth:)];

        //Process each tab to determine how many should be squished, and the size they should squish to
        enumerator = [sortedTabArray reverseObjectEnumerator];
        tabCell = [enumerator nextObject];
        do{
            tabCount++;
            totalTabWidth += [tabCell size].width;
            reducedWidth = (totalTabWidth - tabExtraWidth) / tabCount;

        }while((tabCell = [enumerator nextObject]) && reducedWidth <= [tabCell size].width);

        //Remember the treshold at which tabs are squished
        reduceThreshold = (tabCell ? [tabCell size].width : 0);
    }

    tabXOrigin = CUSTOM_TABS_INDENT;

    //Position the tabs
    xLocation = tabXOrigin;
    enumerator = [tabCellArray objectEnumerator];
    int index = 0;
    while((tabCell = [enumerator nextObject])){
        NSSize	size;
        NSPoint	origin;

        //Make a gap before the current cell if the user is dragging something which originated in this tabview, at or after the current cell
        //or if dragging something from another tab
        if( (index == hoverIndex) && ( (index <= draggedIndex) || draggedIndex == -1 ) ){
            xLocation += hoverSize.width - CUSTOM_TABS_OVERLAP;
        } 
        
        //Get the object's size
        size = [tabCell size];

        //If this is the tab we are dragging, make its width 0 so we don't see it
        if (index == draggedIndex){
            size.width = 0;
            size.height = 0;
            //size.width = 1;
        }
        
        //If this tab is > next biggest, use the 'reduced' width calculated above
        if(size.width > reduceThreshold){
            size.width = reducedWidth;
        }

        origin = NSMakePoint(xLocation, 0 );

        //Move the item closer to its desired location
        if(!absolute){
            if(origin.x > [tabCell frame].origin.x){
                int distance = (origin.x - [tabCell frame].origin.x) * 0.6;
                if(distance < 1) distance = 1;

                origin.x = [tabCell frame].origin.x + distance;

                if(finished) finished = NO;
            }else if(origin.x < [tabCell frame].origin.x){
                int distance = ([tabCell frame].origin.x - origin.x) * 0.6;
                if(distance < 1) distance = 1;

                origin.x = [tabCell frame].origin.x - distance;
                if(finished) finished = NO;
            }
        }
        
        [tabCell setFrame:NSMakeRect(origin.x, origin.y, size.width, size.height)];

        //no need to change the location if we've already done the Hover Thang
        if (index != draggedIndex) {
            xLocation += size.width - CUSTOM_TABS_OVERLAP; //overlap the tabs a bit
        }
        
        //Make a gap after the current cell if the user is dragging something which originated in this tabview, before the current cell
        if( (index == hoverIndex) && ( (index > draggedIndex) && (draggedIndex != -1) ) ){
            xLocation += hoverSize.width - CUSTOM_TABS_OVERLAP;
        } 
        
        index++;
    }

    //Redisplay
    [self setNeedsDisplay:YES];

    return(finished);
}

- (AICustomTabCell *)_cellAtPoint:(NSPoint)clickLocation
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;

    //Determine the clicked cell
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        if(NSPointInRect(clickLocation, [tabCell frame])) break;
    }

    return(tabCell);
}


@end



