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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AICustomTabsView.h"
#import "AICustomTabCell.h"
#import "AIImageUtilities.h"
#import "AIViewAdditions.h"
#import "AIMessageWindowController.h"
#import "AIMessageViewController.h"
#import "AIMessageTabViewItem.h"
#import "AIEventAdditions.h"

@interface AICustomTabsView (PRIVATE)
- (void)arrangeCellsAndAnimate:(BOOL)animate;
- (void)_arrangeCellTimer:(NSTimer *)inTimer;
- (BOOL)_arrangeCellsAbsolute:(BOOL)absolute;
- (void)_acceptDropAtScreenPoint:(NSPoint)inPoint;
- (void)rebuildCells;
- (int)_totalTabWidth;
- (void)_updateDragAtOffset:(int)inOffset;
- (BOOL)_concludeDrag;
- (AICustomTabCell *)_cellAtPoint:(NSPoint)clickLocation;
- (void)_startTrackingCursor;
- (void)_stopTrackingCursor;
- (NSArray *)acceptableDragTypes;
- (void)_insertDraggedTabAtIndex:(int)index preserveSelection:(BOOL)doNotSelect;
- (NSPoint)_updateHoverAtScreenPoint:(NSPoint)inPoint;
- (void)_drawBackgroundInRect:(NSRect)rect withFrame:(NSRect)viewFrame selectedTabRect:(NSRect)tabFrame;
+ (NSImage *)dragWindowImageForWindow:(NSWindow *)window customTabsView:(AICustomTabsView *)customTabsView tabCell:(AICustomTabCell *)tabCell;
+ (void)moveDragFloaterToPoint:(NSPoint)inPoint;
+ (NSImage *)dragTabImageForTabCell:(AICustomTabCell *)tabCell inCustomTabsView:(AICustomTabsView *)customTabsView;
@end

#define TAB_DRAG_DISTANCE 	3                       //Distance required before a drag kicks in
#define TAB_CELL_IDENTIFIER     @"Tab Cell Identifier"

#define CUSTOM_TABS_FPS		30.0                    //Animation speed
#define CUSTOM_TABS_STEP        0.6
#define CUSTOM_TABS_SLOW_STEP   0.1
#define CUSTOM_TABS_OVERLAP	2                       //Overlapped pixels between tabs
#define CUSTOM_TABS_INDENT	3                       //Indent on left and right of tabbar

#define NSAppKitVersionNumber10_2_3 663.6               //to fix some problems with gcc 3.1

//objects shared by all instances of AICustomTabsView
static  AICustomTabCell         *dragTabCell = nil;     //Custom tab cell being dragged
static  AICustomTabsView        *sourceTabBar = nil;    //source tabBar of the drag
static  AICustomTabsView        *destTabBar = nil;      //destination tabBar of the drag
static  AICustomTabsView        *activeTabBar = nil;    //tabBar currently being hovered by the drag

static  ESFloater               *dragTabFloater = nil;      //Drag floater window
static  ESFloater               *dragWindowFloater = nil;   //Drag floater window

static  NSSize                  dragOffset;             //Offset of cursor on dragged image
static  NSSize                  dragCellSize;           //Size of the cell being dragged

@implementation AICustomTabsView

//Create a new custom tab view
+ (id)customTabViewWithFrame:(NSRect)frameRect
{
    return([[[self alloc] initWithFrame:frameRect] autorelease]);
}

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
    arrangeCellTimer = nil;
    selectedCustomTabCell = nil;
    removingLastTabHidesWindow = YES;
    tabDivider = [[AIImageUtilities imageNamed:@"Tab_Divider" forClass:[self class]] retain];
        
    //register as a drag observer
    [self unregisterDraggedTypes];
    [self registerForDraggedTypes:[self acceptableDragTypes]];

    //Configure our tab cells
    [self rebuildCells];

    return(self);
}

//
- (void)dealloc
{
    [arrangeCellTimer invalidate]; [arrangeCellTimer release]; arrangeCellTimer = nil;
    [tabCellArray release];
    [tabDivider release];
    [selectedCustomTabCell release];
    [super dealloc];
}

//Set our delegate
- (void)setDelegate:(id <AICustomTabsViewDelegate>)inDelegate
{
    delegate = inDelegate;
    
    //Update our accepted drag types
    [self unregisterDraggedTypes];
    [self registerForDraggedTypes:[self acceptableDragTypes]];
    
}
- (id <AICustomTabsViewDelegate>)delegate
{
    return(delegate);
}

//Allow tab switching from the background
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return(YES);
}

//Stop dragging in metal mode
- (BOOL)mouseDownCanMoveWindow
{
    return(NO);
}

//Draw
- (void)drawRect:(NSRect)rect
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell, *nextTabCell;
    NSRect		tabFrame;

    //Get the active tab's frame
    tabFrame = [selectedCustomTabCell frame];
    
    //If our selected tab is being dragged, use a frame size width of 0 to 'hide' it
    if(selectedCustomTabCell == dragTabCell || activeTabBar == self){
        tabFrame.size.width = 0;
    }
    
    //Draw our background
    [self _drawBackgroundInRect:rect withFrame:[self frame] selectedTabRect:tabFrame];

    //Draw our tabs
    enumerator = [tabCellArray objectEnumerator];
    tabCell = [enumerator nextObject];
    while((nextTabCell = [enumerator nextObject]) || tabCell){
        NSRect	cellFrame = [tabCell frame];

        if(NSIntersectsRect(cellFrame, rect) && (tabCell != dragTabCell) ){ //Don't draw out of view tabs, and tabs being dragged
            BOOL    wasSelected = NO;
            
            //(If dragging, temporarily deselect this cell)
            if(activeTabBar == self && [tabCell isSelected]){
                wasSelected = YES;
                [tabCell setHighlighted:NO];
                [tabCell setSelected:NO];
            }
            
            //Draw the tab cell
            [tabCell drawWithFrame:cellFrame inView:self];

            //Draw the divider
            if(sourceTabBar == self || activeTabBar == self || (tabCell != selectedCustomTabCell && (!nextTabCell || nextTabCell != selectedCustomTabCell)) ){
                [tabDivider compositeToPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width - 2, cellFrame.origin.y) operation:NSCompositeSourceOver];
            }

            //(Restore selection)
            if(wasSelected) [tabCell setSelected:YES];
        }

        tabCell = nextTabCell;
    }
}

//Draw our background strip
- (void)_drawBackgroundInRect:(NSRect)rect withFrame:(NSRect)viewFrame selectedTabRect:(NSRect)tabFrame
{
    NSRect		drawRect;
    NSPoint		drawPointA, drawPointB;

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

//Returns number of tab view items (Returns the number of visible tabs if a drag is happening from this bar)
- (int)numberOfTabViewItems
{
    if(sourceTabBar == self){
        return([tabView numberOfTabViewItems]-1);
    }else{
        return([tabView numberOfTabViewItems]);
    }
}

//Does removing the last tab of a window cause that window to hide?
- (void)setRemovingLastTabHidesWindow:(BOOL)inValue
{
    removingLastTabHidesWindow = inValue;
}
- (BOOL)removingLastTabHidesWindow{
    return(removingLastTabHidesWindow);
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

    //Reset cursor tracking
    [self _stopTrackingCursor];
    [self _startTrackingCursor];
    
    //Inform our delegate
    if([delegate respondsToSelector:@selector(customTabView:didSelectTabViewItem:)]){
        [delegate customTabView:self didSelectTabViewItem:tabViewItem];
    }
}

//Rebuild our tab list to match the tabView
- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)inTabView
{
    //Rebuild cells (If this was called by the tab view)
    if(inTabView){
        [self rebuildCells];        
    }

    //Inform our delegate
    if([delegate respondsToSelector:@selector(customTabViewDidChangeNumberOfTabViewItems:)]){
        [delegate customTabViewDidChangeNumberOfTabViewItems:self];
    }
}

//Intercept frame changes and correctly resize our tabs
- (void)setFrame:(NSRect)frameRect
{
    //Resize
    [super setFrame:frameRect];
    [self arrangeCellsAndAnimate:NO];

    //Reset cursor tracking
    [self _stopTrackingCursor];
    [self _startTrackingCursor];
}

//Rebuild the tab cells for this view
- (void)rebuildCells
{
    int	loop;
    
    [self _stopTrackingCursor];

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
    [self arrangeCellsAndAnimate:NO];

    [self _startTrackingCursor];
}


//Cursor Tracking -----------------------------------------------------------------------
//Start tracking the cursor
- (void)_startTrackingCursor
{
    //Track only if we're within a valid window
    if([self window]){
        NSEnumerator		*enumerator;
        AICustomTabCell		*tabCell;
        NSPoint			localPoint;

        //Local mouse location
        localPoint = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
        localPoint = [self convertPoint:localPoint fromView:nil];

        //Install tracking rects for each tab
        enumerator = [tabCellArray objectEnumerator];
        while((tabCell = [enumerator nextObject])){            
            NSRect trackRect = [tabCell frame];

            //Compensate for overlap
            trackRect.origin.x += CUSTOM_TABS_OVERLAP;
            trackRect.size.width -= CUSTOM_TABS_OVERLAP;

            //add the tracking tags
            [tabCell addTrackingRectsInView:self withFrame:trackRect cursorLocation:localPoint];
        }
    }
}

//Stop tracking the cursor
- (void)_stopTrackingCursor
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;

    //Remove the tracking rect for each open tab
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        [tabCell removeTrackingRectsFromView:self];
    }
}


//Clicking & Dragging ----------------------------------------------------------------
//
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint		clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    AICustomTabCell	*tabCell = [self _cellAtPoint:clickLocation];

    //Remember for dragging
    lastClickLocation = clickLocation;

    if(tabCell){
        //Give the tab cell a chance to handle tracking
        if(![tabCell willTrackMouse:theEvent inRect:[tabCell frame] ofView:self]){
            if(![NSEvent cmdKey]){ //Allow background dragging
                [tabView selectTabViewItem:[tabCell tabViewItem]];
            }
        }
    }
}

//
- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint             clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    AICustomTabCell     *dragCell;

    //if we're not in the middle of a drag already and we've moved enough, attempt to initiate a drag 
    if(sourceTabBar != self){        
        if( (lastClickLocation.x - clickLocation.x) > TAB_DRAG_DISTANCE || (lastClickLocation.x - clickLocation.x) < -TAB_DRAG_DISTANCE ||
            (lastClickLocation.y - clickLocation.y) > TAB_DRAG_DISTANCE || (lastClickLocation.y - clickLocation.y) < -TAB_DRAG_DISTANCE ){

            //Perform a tab drag
            if(lastClickLocation.x != -1 && lastClickLocation.y != -1){ //See note below about lastClickLocation
                if(dragCell = [self _cellAtPoint:lastClickLocation]){
                    hoverIndex = [tabCellArray indexOfObject:dragCell]; //Start our hover index where the tab was originally placed
                    [AICustomTabsView dragTabCell:dragCell fromCustomTabsView:self withEvent:theEvent];
                }
            }
            
            //When dragging quickly, mouseDragged may be called multiple times.  We only want to drag once, no matter what.
            //This is achieved by only allowing a drag if lastClickLocation is valid.  lastClickLocation will only be valid
            //for the first mouseDragged event, allowing others to be easily ignored.
            lastClickLocation = NSMakePoint(-1,-1);
        }
    }
}


// Context menu ------------------------------------------------------------------------
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    NSPoint		clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    AICustomTabCell	*tabCell = [self _cellAtPoint:clickLocation];

    //Pass this on to our delegate
    if(tabCell && [delegate respondsToSelector:@selector(customTabView:menuForTabViewItem:)]){
        return([delegate customTabView:self menuForTabViewItem:[tabCell tabViewItem]]);
    }
    return(nil);
}


// Cell Positioning -----------------------------------------------------------------------
//Correctly arrange our cells.  If animate is YES, the cells will be smoothly moved into position
- (void)arrangeCellsAndAnimate:(BOOL)animate
{
    if(animate){
        if(!arrangeCellTimer){ //Ignore the request if animation is already occuring            
            arrangeCellTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/CUSTOM_TABS_FPS) target:self selector:@selector(_arrangeCellTimer:) userInfo:nil repeats:YES] retain];
        }       
    }else{
        [self _arrangeCellsAbsolute:YES];
    }
}

//Animation timer
- (void)_arrangeCellTimer:(NSTimer *)inTimer
{    
    //When all the items are in place we stop this timer
    if([self _arrangeCellsAbsolute:NO]){
        [arrangeCellTimer invalidate]; [arrangeCellTimer release]; arrangeCellTimer = nil;
    }
}

//Re-arrange our views to their correct positions.  Returns YES is finished.  Pass NO for a partial movement
- (BOOL)_arrangeCellsAbsolute:(BOOL)absolute
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;
    int			xLocation;
    BOOL		finished = YES;
    int                 tabExtraWidth;
    int                 totalTabWidth;
    int                 reducedWidth = 0;
    int                 reduceThreshold = 1000000;

    //Get the total tab width
    totalTabWidth = [self _totalTabWidth];

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

    //Position the tabs
    xLocation = CUSTOM_TABS_INDENT;
    enumerator = [tabCellArray objectEnumerator];
    int index = 0;

    while((tabCell = [enumerator nextObject])){
        if(tabCell != dragTabCell){ //Skip the cell being dragged if it's in our tab bar
            NSSize	size;
            NSPoint	origin;
            
            //Make a gap to signify that the dragged cell can be dropped here
            if(activeTabBar == self && index == hoverIndex){
                xLocation += dragCellSize.width - CUSTOM_TABS_OVERLAP;
            }
            
            //Get the object's size
            size = [tabCell size];
            
            //If this tab is > next biggest, use the 'reduced' width calculated above
            if(size.width > reduceThreshold){
                size.width = reducedWidth;
            }
            
            //Move the tab closer to its desired location
            origin = NSMakePoint(xLocation, 0 );
            if(!absolute){
                if(origin.x > [tabCell frame].origin.x){
                    int distance = (origin.x - [tabCell frame].origin.x) * ([NSEvent shiftKey] ? CUSTOM_TABS_SLOW_STEP : CUSTOM_TABS_STEP);
                    if(distance < 1) distance = 1;
                    
                    origin.x = [tabCell frame].origin.x + distance;
                    
                    if(finished) finished = NO;
                }else if(origin.x < [tabCell frame].origin.x){
                    int distance = ([tabCell frame].origin.x - origin.x) * ([NSEvent shiftKey] ? CUSTOM_TABS_SLOW_STEP : CUSTOM_TABS_STEP);
                    if(distance < 1) distance = 1;
                    
                    origin.x = [tabCell frame].origin.x - distance;
                    if(finished) finished = NO;
                }
            }
            [tabCell setFrame:NSMakeRect(origin.x, origin.y, size.width, size.height)];
            
            //Move to the next tab
            xLocation += size.width - CUSTOM_TABS_OVERLAP; //overlap the tabs a bit
            
            index++;
        }
    }
    
    //Force a redisplay
    [self setNeedsDisplay:YES];

    return(finished);
}

//Returns cell at the specified point
- (AICustomTabCell *)_cellAtPoint:(NSPoint)clickLocation
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;

    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        if(NSPointInRect(clickLocation, [tabCell frame])) break;
    }

    return(tabCell);
}

//Returns the total width of our tab cells
- (int)_totalTabWidth
{
    int			totalWidth = CUSTOM_TABS_OVERLAP + (CUSTOM_TABS_INDENT * 2);
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;
    
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        totalWidth += [tabCell size].width - CUSTOM_TABS_OVERLAP;
    }
    
    return(totalWidth);
}


//Drag destination methods ------------------------------------------------------------------------
//Return the drag types we accept
- (NSArray *)acceptableDragTypes
{
    NSArray *types = nil;
    
    if([delegate respondsToSelector:@selector(customTabViewAcceptableDragTypes:)]){
        types = [delegate customTabViewAcceptableDragTypes:self];
    }
    
    return(types ? [types arrayByAddingObject:TAB_CELL_IDENTIFIER] : [NSArray arrayWithObject:TAB_CELL_IDENTIFIER]);
}

//Return YES for acceptance
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return(YES);
}

//Perform the drag operation (switching around the tabs)
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard    *pboard = [sender draggingPasteboard];
    NSString        *type = [pboard availableTypeFromArray:[NSArray arrayWithObject:TAB_CELL_IDENTIFIER]];
    BOOL            success = NO;

    if(type && [type isEqualToString:TAB_CELL_IDENTIFIER]){
        BOOL    backgroundDrag = [[pboard stringForType:@"DoNotSelect"] intValue];
        
        //Finish the drag
        destTabBar = self; //This drag ended on us
        [self draggingExited:nil];
        
        //Perform the tab switching
        [self _insertDraggedTabAtIndex:hoverIndex preserveSelection:backgroundDrag];
        
        success = YES;
        
    }else{
        AICustomTabCell	*tabCell = [self _cellAtPoint:[sender draggingLocation]];

        if(tabCell != nil){            
            if([delegate respondsToSelector:@selector(customTabView:didAcceptDragPasteboard:onTabViewItem:)]){
                success = [delegate customTabView:self didAcceptDragPasteboard:pboard onTabViewItem:[tabCell tabViewItem]];
            }
        }
    }
    
    return(success);
}

//Add the dragging tab to this tab bar
- (void)_insertDraggedTabAtIndex:(int)index preserveSelection:(BOOL)doNotSelect
{
    NSTabViewItem       *tabViewItem = [dragTabCell tabViewItem];
    NSTabViewItem       *tabViewItemToSelect = tabViewItem;
    int                 existingIndex = [tabView indexOfTabViewItem:tabViewItem];
    
    //Handle dragging within a tab bar on our own (we can do a cleaner job of it than the delegate)
    if(existingIndex != NSNotFound){
        if(doNotSelect) tabViewItemToSelect = [tabView selectedTabViewItem]; //Preserve selection if desired
        [tabViewItem retain];
        [tabView removeTabViewItem:tabViewItem];
        [tabView insertTabViewItem:tabViewItem atIndex:index];
        [tabViewItem release];
        [self rebuildCells];

        //Update the selected tab
        [tabView selectTabViewItem:tabViewItemToSelect];
        
        //Inform our delegate of the re-order
        if([delegate respondsToSelector:@selector(customTabViewDidChangeOrderOfTabViewItems:)]){
            [delegate customTabViewDidChangeOrderOfTabViewItems:self];
        }

    }else{
        //Pass cross bar dragging directly to the delegate
        if([[sourceTabBar delegate] respondsToSelector:@selector(customTabView:didMoveTabViewItem:toCustomTabView:index:screenPoint:)]){
            [[sourceTabBar delegate] customTabView:sourceTabBar didMoveTabViewItem:[dragTabCell tabViewItem] toCustomTabView:self index:index screenPoint:NSMakePoint(-1,-1)];
        }
        
        //Update the selected tab
        if(!doNotSelect){
            [tabView selectTabViewItem:[dragTabCell tabViewItem]];
        }
    }
}


//Dragging Destination Tracking ------------------------------------------------------------------------------------------------
//Called when a drag enters this toolbar
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPoint		location = [self convertPoint:[sender draggingLocation] fromView:nil];
    NSPasteboard 	*pboard = [sender draggingPasteboard];
    NSString 		*type = [pboard availableTypeFromArray:[NSArray arrayWithObject:TAB_CELL_IDENTIFIER]];
    NSDragOperation	operation = NSDragOperationNone;

    //Disable mouse tracking while we are being hovered
    [self _stopTrackingCursor];

    //
    if(type && [type isEqualToString:TAB_CELL_IDENTIFIER]){ //got a tab
            operation = NSDragOperationPrivate;

            //Set ourself as the active tab bar
            activeTabBar = self;

            //Update our view for the hovering
            [self _updateHoverAtScreenPoint:location];
            [self arrangeCellsAndAnimate:YES];
            
    }else{ //got something else
        operation = NSDragOperationCopy;
            
    }
    
    //Pass along to the windowController, as well
    if([[[self window] windowController] respondsToSelector:@selector(draggingEntered:)]){
        [[[self window] windowController] draggingEntered:sender];
    }
    
    return(operation);
}

//Called continuously as the drag is over the tab bar
- (unsigned int)draggingUpdated:(id <NSDraggingInfo>)sender {
    NSPoint		location = [self convertPoint:[sender draggingLocation] fromView:nil];
    NSPasteboard 	*pboard = [sender draggingPasteboard];
    NSString 		*type = [pboard availableTypeFromArray:[NSArray arrayWithObject:TAB_CELL_IDENTIFIER]];
    NSDragOperation	operation = NSDragOperationNone;
    
    if(type && [type isEqualToString:TAB_CELL_IDENTIFIER]) { //got a tab
            operation = NSDragOperationPrivate;

            //Update our view for the hovering (We only move the tab, moving the window looks jumpy)
            [dragTabFloater moveFloaterToPoint:[self _updateHoverAtScreenPoint:location]];

            [self arrangeCellsAndAnimate:YES];
            
    }else{ //got something else
        AICustomTabCell	*tabCell = [self _cellAtPoint:location];
        
        if(tabCell != nil){
            operation = NSDragOperationCopy;
            
            //Select the tab being hovered
            if([tabView selectedTabViewItem] != [tabCell tabViewItem]){
                [tabView selectTabViewItem:[tabCell tabViewItem]];
            }
        }
    }
    
    return operation;
}

//Called when the drag exits this tab bar; should restore the pre-hover arrangement
- (void)draggingExited:(id <NSDraggingInfo>)sender
{    
    //Clean up dragging
    activeTabBar = nil;
    [self arrangeCellsAndAnimate:YES];

    //Turn mouse tracking back on
    [self _startTrackingCursor];

    //Pass event along to the windowController
    if([[[self window] windowController] respondsToSelector:@selector(draggingExited:)]){
        [[[self window] windowController] draggingExited:sender];
    }
}

//Determines the correct drop index for the hovered tab, and returns the desired screen location for it
//We ignore frame origins in here, since they are being slid all around and relying on them will cause jiggyness.  Instead, we step through each cell and use only it's width.
- (NSPoint)_updateHoverAtScreenPoint:(NSPoint)inPoint
{    
    NSEnumerator 	*enumerator;
    AICustomTabCell	*tabCell;
    float               lastLocation = CUSTOM_TABS_INDENT;

    //Figure out where the user is hovering the tabcell item
    hoverIndex = 0;
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        if(sourceTabBar != self || tabCell != dragTabCell){ //We ignore the cell being dragged (if it's in our tab bar)               
            //Once we reach the hover point, we know the desired drop index and can exit.
            if(inPoint.x < lastLocation + (([tabCell frame].size.width + dragCellSize.width) / 2.0) ) break;

            //Move past this tab
            hoverIndex++;
            lastLocation += [tabCell frame].size.width - CUSTOM_TABS_OVERLAP;
        }
    }
    
    //Special case: Tab is to the right of all our tabs, the drop index is set to after our last tab
    if(hoverIndex >= [tabCellArray count]) hoverIndex = [tabCellArray count];

    return([[self window] convertBaseToScreen:[self convertPoint:NSMakePoint(lastLocation,0) toView:nil]]);
}


//Dragging Source ------------------------------------------------------------------------------------------------
//Drag a tab cell.  For dragging within a tab bar and between tab bars.
+ (void)dragTabCell:(AICustomTabCell *)inTabCell fromCustomTabsView:(AICustomTabsView *)sourceView withEvent:(NSEvent *)inEvent
{
    NSPasteboard 	*pboard;
    NSImage             *blankImage, *dragTabImage, *dragWindowImage;
    NSRect		frame = [inTabCell frame];
    NSPoint             clickLocation = [inEvent locationInWindow];
    NSPoint             startPoint;
    BOOL                sourceWindowWillHide;
    BOOL                useCustomDraggingCode = (NSAppKitVersionNumber > NSAppKitVersionNumber10_2_3);
    
    //Setup
    dragTabCell = [inTabCell retain]; //Make sure this doesn't go anywhere until the drag is complete
    dragCellSize = [inTabCell frame].size;
    sourceTabBar = [sourceView retain];
    destTabBar = nil;

    //Determine if the source window will hide as a result of this drag
    sourceWindowWillHide = ([sourceTabBar removingLastTabHidesWindow] && [sourceTabBar numberOfTabViewItems] < 1);

    //Setup the active tab bar (if the mouse if moved quickly, the drag may begin outside of a tab bar)
    if(!sourceWindowWillHide && NSPointInRect(clickLocation, [sourceView frame])){
        activeTabBar = sourceView;
    }else{
        activeTabBar = nil;
    }
    
    //Picked up a tab for dragging, which means that the tab count of the source tabbar has changed.  Let the delegate know.
    [sourceTabBar tabViewDidChangeNumberOfTabViewItems:nil];
    
    //We use our own custom code for the drag image, and just create an blank image to satisfy the system's dragging code.
    blankImage = [[[NSImage alloc] initWithSize:frame.size] autorelease];
    
    //Create the images (one of the tab, and one of the window it would produce) for our custom drag code
    //Our custom drag image code (the floating windows) screws up drag tracking events in anything before panther (10.3).
    //On earlier systems we fall back to using the stock dragging code
    dragTabImage = [AICustomTabsView dragTabImageForTabCell:inTabCell inCustomTabsView:sourceTabBar];
    dragWindowImage = [AICustomTabsView dragWindowImageForWindow:[sourceTabBar window] customTabsView:sourceTabBar tabCell:inTabCell];
    if(!dragTabImage || !dragWindowImage) useCustomDraggingCode = NO; //Fall back to stock dragging on failure
    
    if(useCustomDraggingCode){
        dragTabFloater = [ESFloater floaterWithImage:dragTabImage frame:NO];
        [dragTabFloater setVisible:(!sourceWindowWillHide) animate:NO];
        [dragTabFloater setMaxOpacity:1.0];
        
        dragWindowFloater = [ESFloater floaterWithImage:dragWindowImage frame:YES];
        [dragWindowFloater setVisible:(sourceWindowWillHide) animate:NO];
        [dragWindowFloater setMaxOpacity:/*1.0*/ 0.75];
    }

    //Adjust the drag offset so the cursor is atleast always touching the tab drag image (Is there a macro that can do this ?)
    dragOffset = NSMakeSize([inTabCell frame].origin.x - clickLocation.x, [inTabCell frame].origin.y - clickLocation.y);
    if(dragOffset.width > [inTabCell frame].size.width) dragOffset.width = [inTabCell frame].size.width;
    if(dragOffset.width < -[inTabCell frame].size.width) dragOffset.width = -[inTabCell frame].size.width;
    if(dragOffset.height > [inTabCell frame].size.height) dragOffset.height = [inTabCell frame].size.height;
    if(dragOffset.height < -[inTabCell frame].size.height) dragOffset.height = -[inTabCell frame].size.height;

    //Position the drag floater
    if(useCustomDraggingCode){
        startPoint = [[inEvent window] convertBaseToScreen:[inEvent locationInWindow]];
        startPoint = NSMakePoint(startPoint.x + dragOffset.width, startPoint.y + dragOffset.height);
        [AICustomTabsView moveDragFloaterToPoint:startPoint];
    }
        
    //Hide the source window
    if(sourceWindowWillHide){
        [[sourceTabBar window] setAlphaValue:0.0];
    }

    //Update the source tab bar to correctly hide the tab being dragged
    [sourceTabBar arrangeCellsAndAnimate:NO];

    //Perform the drag
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObjects:TAB_CELL_IDENTIFIER, @"DoNotSelect", nil] owner:self];
    [pboard setString:TAB_CELL_IDENTIFIER forType:TAB_CELL_IDENTIFIER]; //useless data to satisfy the pboard; our important data is in the static dragTabCell
    [pboard setString:[[NSNumber numberWithInt:[NSEvent cmdKey]] stringValue] forType:@"DoNotSelect"]; //useful only when moving in the same window
    [[inEvent window] dragImage:(useCustomDraggingCode ? blankImage : [AICustomTabsView dragTabImageForTabCell:inTabCell inCustomTabsView:sourceTabBar])
                             at:NSMakePoint(clickLocation.x + dragOffset.width, clickLocation.y + dragOffset.height)
                         offset:NSMakeSize(0,0)
                          event:inEvent
                     pasteboard:pboard
                         source:self
                      slideBack:NO];

    //Cleanup
    [dragTabFloater close:nil]; dragTabFloater = nil;
    [dragWindowFloater close:nil]; dragWindowFloater= nil;
    [dragTabCell release]; dragTabCell = nil;
}

//Invoked in the dragging source as the drag begins
+ (void)draggedImage:(NSImage *)image beganAt:(NSPoint)screenPoint
{
    //Treat the initial drag just like an updated drag
    [self draggedImage:image movedTo:screenPoint];
}

//Invoked in the dragging source as the drag moves
+ (void)draggedImage:(NSImage *)image movedTo:(NSPoint)screenPoint
{
    [dragTabFloater setVisible:(activeTabBar != nil) animate:YES];
    [dragWindowFloater setVisible:(activeTabBar == nil) animate:YES];

    //If the floater isn't in a tabbar, we position it
    if(!activeTabBar){
        [AICustomTabsView moveDragFloaterToPoint:screenPoint];
    }
}

//Invoked in the dragging source as the drag ends
+ (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    AICustomTabsView    *tempSourceBar = sourceTabBar;
    
    if(!destTabBar){
        screenPoint.x -= CUSTOM_TABS_INDENT;
        //If the drop wasn't into a tab bar, we handle it here
        if([[sourceTabBar delegate] respondsToSelector:@selector(customTabView:didMoveTabViewItem:toCustomTabView:index:screenPoint:)]){
            [[sourceTabBar delegate] customTabView:self didMoveTabViewItem:[dragTabCell tabViewItem] toCustomTabView:nil index:-1 screenPoint:screenPoint];
        }
    }

    //Cleanup drag
    sourceTabBar = nil;

    //Finished dragging, which means that the tab count of the source tabbar has changed.  Let the delegate know
    [tempSourceBar tabViewDidChangeNumberOfTabViewItems:nil];
    [tempSourceBar arrangeCellsAndAnimate:NO];        
    [tempSourceBar release];
}

//Prevents dragging of tabs to another application
+ (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return(isLocal ? NSDragOperationEvery : NSDragOperationNone);
}

//Position the drag floater(s)
+ (void)moveDragFloaterToPoint:(NSPoint)inPoint
{
    [dragTabFloater moveFloaterToPoint:inPoint];
    [dragWindowFloater moveFloaterToPoint:NSMakePoint(inPoint.x - CUSTOM_TABS_INDENT, inPoint.y)]; //Offset left a bit so the tab lines up on both images
}

//Returns a drag image for the passed tab cell
+ (NSImage *)dragTabImageForTabCell:(AICustomTabCell *)tabCell inCustomTabsView:(AICustomTabsView *)customTabsView
{
    NSImage     *dragTabImage = nil;
    
    if([customTabsView canDraw]){
        dragTabImage = [[[NSImage alloc] init] autorelease];
        [customTabsView lockFocus];
        [dragTabImage addRepresentation:[[NSBitmapImageRep alloc] initWithFocusedViewRect:[tabCell frame]]];
        [customTabsView unlockFocus];    
    }

    return(dragTabImage);
}

//Returns a drag window image for the passed window/bar/cell
+ (NSImage *)dragWindowImageForWindow:(NSWindow *)window customTabsView:(AICustomTabsView *)customTabsView tabCell:(AICustomTabCell *)tabCell
{
    NSView      *contentView = [[tabCell tabViewItem]  view];
    NSImage     *dragWindowImage = nil;
    NSImage     *contentImage, *tabImage;    
    NSPoint     insertPoint;

    if([customTabsView canDraw] && [contentView canDraw]){
        //Get an image of the tab
        tabImage = [[NSImage alloc] init];
        [customTabsView lockFocus];
        [tabImage addRepresentation:[[NSBitmapImageRep alloc] initWithFocusedViewRect:[tabCell frame]]];
        [customTabsView unlockFocus];
        
        //Get an image of the tabView content view
        contentImage = [[[NSImage alloc] init] autorelease];
        [contentView lockFocus];
        [contentImage addRepresentation:[[NSBitmapImageRep alloc] initWithFocusedViewRect:[contentView frame]]];
        [contentView unlockFocus];
        
        //Create a drag image the size of the window
        dragWindowImage = [[NSImage alloc] initWithSize:[[window contentView] frame].size];
        [dragWindowImage setBackgroundColor:[NSColor clearColor]];
        [dragWindowImage lockFocus];
        
        //Draw the tabbar and tab
        [customTabsView _drawBackgroundInRect:[customTabsView frame] withFrame:[customTabsView frame] selectedTabRect:NSMakeRect(0,0,0,0)];
        insertPoint = [customTabsView frame].origin;
        insertPoint.x += CUSTOM_TABS_INDENT; //Line the tab up a bit more realistically
        [tabImage compositeToPoint:insertPoint operation:NSCompositeCopy];
        
        //Draw the content
        [contentImage compositeToPoint:[[[tabCell tabViewItem] tabView] frame].origin operation:NSCompositeCopy];
        
        [dragWindowImage unlockFocus];
    }
    
    return(dragWindowImage);
}

@end

