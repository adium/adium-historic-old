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

#define TAB_DRAG_DISTANCE 	4	//Distance required before a drag kicks in

@interface AICustomTabsView (PRIVATE)
- (void)rebuildCells;
- (void)smoothlyArrangeCells;
- (BOOL)arrangeCellsAbsolute:(BOOL)absolute;
- (int)totalTabWidth;
- (void)_beginDragOfTab:(AICustomTabCell *)inTabCell fromOffset:(NSSize)inOffset;
- (void)_updateDragAtOffset:(int)inOffset;
- (BOOL)_concludeDrag;
- (AICustomTabCell *)_cellAtPoint:(NSPoint)clickLocation;
@end

#define CUSTOM_TABS_FPS		30.0		//Animation speed
#define CUSTOM_TABS_OVERLAP	2		//Overlapped pixels between tabs
#define CUSTOM_TABS_LEFT_INDENT	6

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
    
    //Load our images
    tabDivider = [[AIImageUtilities imageNamed:@"Tab_Divider" forClass:[self class]] retain];

    //Configure out tab cells    
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
    NSRect		tabFrame;
    NSRect		drawRect;
    
    //Get the active tab's frame
    tabFrame = [selectedCustomTabCell frame];

    //Paint black over region left of active tab
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.20] set];
    drawRect = NSMakeRect(rect.origin.x,
                          rect.origin.y + 1,
                          tabFrame.origin.x - rect.origin.x,
                          rect.size.height - 1);
    [NSBezierPath fillRect:drawRect];

    //Draw the black tab line left of active tab
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.38] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(drawRect.origin.x, drawRect.origin.y + drawRect.size.height - 0.5)
                              toPoint:NSMakePoint(drawRect.origin.x + drawRect.size.width, drawRect.origin.y + drawRect.size.height - 0.5)];

    //Paint black over region right of active tab
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.20] set];
    drawRect = NSMakeRect(tabFrame.origin.x + tabFrame.size.width,
                          rect.origin.y + 1,
                          (rect.origin.x + rect.size.width) - (tabFrame.origin.x + tabFrame.size.width),
                          rect.size.height - 1);
    [NSBezierPath fillRect:drawRect];

    //Draw the black tab line right of active tab
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.38] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(drawRect.origin.x, drawRect.origin.y + drawRect.size.height - 0.5)
                              toPoint:NSMakePoint(drawRect.origin.x + drawRect.size.width, drawRect.origin.y + drawRect.size.height - 0.5)];

    //Bottom edge light
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.16] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + 1.5)
                              toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + 1.5)];

    //Bottom edge dark
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.41] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, rect.origin.y + 0.5)
                              toPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + 0.5)];

    //Draw our tabs
    enumerator = [tabCellArray objectEnumerator];
    tabCell = [enumerator nextObject];
    while((nextTabCell = [enumerator nextObject]) || tabCell){
        NSRect	cellFrame = [tabCell frame];

        //Draw the tab cell
        [tabCell drawWithFrame:cellFrame inView:self];

        //Draw the divider
        if(tabCell != selectedCustomTabCell && (!nextTabCell || nextTabCell != selectedCustomTabCell)){
            [tabDivider compositeToPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width - 1, cellFrame.origin.y) operation:NSCompositeSourceOver];
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

    //Redisplay
    [self setNeedsDisplay:YES];

    //Inform our delegate
    if([delegate respondsToSelector:@selector(customTabView:didSelectTabViewItem:)]){
        [delegate customTabView:self didSelectTabViewItem:tabViewItem];
    }
}

//Rebuild our tab list to match the tabView
- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)TabView
{
    [self rebuildCells];

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

    totalWidth = CUSTOM_TABS_OVERLAP;
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        totalWidth += [tabCell size].width - CUSTOM_TABS_OVERLAP;
    }

    return(totalWidth);
}


//Clicking & Dragging ----------------------------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint		clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    AICustomTabCell	*tabCell = [self _cellAtPoint:clickLocation];

    //Remember for dragging
    lastClickLocation = clickLocation;

    if(tabCell == selectedCustomTabCell){
        //Give the tab cell a chance to handle tracking
        [tabCell willTrackMouse:theEvent inRect:[tabCell frame] ofView:self];
        
    }else if(tabCell != nil){
        //Select the tab
        [tabView selectTabViewItem:[tabCell tabViewItem]];

    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint	clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    if(draggingATabCell){
        //Update an existing drag
        [self _updateDragAtOffset:(int)clickLocation.x];

    }else{
        if( (lastClickLocation.x - clickLocation.x) > TAB_DRAG_DISTANCE || (lastClickLocation.x - clickLocation.x) < -TAB_DRAG_DISTANCE ||
            (lastClickLocation.y - clickLocation.y) > TAB_DRAG_DISTANCE || (lastClickLocation.y - clickLocation.y) < -TAB_DRAG_DISTANCE ){
            //if we've moved enough, initiate a drag
            [self _beginDragOfTab:selectedCustomTabCell fromOffset:NSMakeSize(clickLocation.x, clickLocation.y)];
        }
    }
    
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if(draggingATabCell){
        [self _concludeDrag];
    }
}

- (void)_beginDragOfTab:(AICustomTabCell *)inTabCell fromOffset:(NSSize)inOffset
{
    NSImage		*image;
    NSRect		imageRect;
    NSRect		frame = [inTabCell frame];

    //Create an image of the tab to drag
    image = [[[NSImage alloc] initWithSize:frame.size] autorelease];
    imageRect = NSMakeRect(0,0,frame.size.width,frame.size.height);
    [image lockFocus];
    [inTabCell drawWithFrame:imageRect inView:self];
    [image unlockFocus];

    dragImage = [[[NSImage alloc] initWithSize:frame.size] autorelease];
    [dragImage setBackgroundColor:[NSColor clearColor]];
    [dragImage lockFocus];
    [image dissolveToPoint:NSMakePoint(0,0) fraction:0.8];
    [dragImage unlockFocus];

    //
    draggingATabCell = YES;
    tabHasBeenDragged = NO;
    dragInitialOffset = inOffset;
    if(dragTabCell) [dragTabCell release];
    dragTabCell = [inTabCell retain];
}

- (void)_updateDragAtOffset:(int)inOffset
{
    NSEnumerator	*enumerator = [tabCellArray objectEnumerator];
    AICustomTabCell	*tabCell;
    int			xLocation;
    int			index = 0;
    int			dragIndex;

    //Figure out where the user is hovering the toolbar item
    xLocation = tabXOrigin;
    while((tabCell = [enumerator nextObject])){
        NSRect	 frame = [tabCell frame];

        //Force the X origin (to negate any smoothing effects)
        frame.origin.x = xLocation;

        //We move to if:
        //+ this isn't the tab we're dragging
        //+ the cursor is where the tab would be if at this index
        //+ the cursor is NOT in the current frame of the drag tab
        if((dragTabCell != tabCell) &&
           (inOffset > frame.origin.x) &&
           (inOffset < frame.origin.x + [dragTabCell frame].size.width) &&
           (inOffset < [dragTabCell frame].origin.x || inOffset > ([dragTabCell frame].origin.x + [dragTabCell frame].size.width)) ){

            //Mark it
            dragIndex = index;
            tabHasBeenDragged = YES;
        }

        index++;
        xLocation += frame.size.width - CUSTOM_TABS_OVERLAP;
    }

    //Exchange the "tabs" (actually views... we leave the origional tabs in their place)
    if(dragIndex >= 0 && dragIndex <= [tabCellArray count]){
        int existingIndex = [tabCellArray indexOfObject:dragTabCell];

        if(existingIndex != dragIndex){
            [tabCellArray removeObjectAtIndex:existingIndex];
            [tabCellArray insertObject:dragTabCell atIndex:dragIndex];

        }
    }

    //Arrange the views
    if(!viewsRearranging){
        [self smoothlyArrangeCells];
    }
}

- (BOOL)_concludeDrag
{
    NSEnumerator	*enumerator;
    AICustomTabCell	*tabCell;
    NSTabViewItem	*selectedItem = [tabView selectedTabViewItem];
    int			index = 0;
    BOOL		tabsChanged = NO;

    draggingATabCell = NO;

    //Rearrange the tab views
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        NSTabViewItem	*customTabView = [tabCell tabViewItem];

        if([tabView tabViewItemAtIndex:index] != customTabView){
            tabsChanged = YES;
            [customTabView retain];
            [tabView removeTabViewItem:customTabView];
            [tabView insertTabViewItem:customTabView atIndex:index];
            [customTabView release];
        }

        index++;
    }

    [tabView selectTabViewItem:selectedItem];

    //Inform our delegate
    if([delegate respondsToSelector:@selector(customTabViewDidChangeOrderOfTabViewItems:)]){
        [delegate customTabViewDidChangeOrderOfTabViewItems:self];
    }

    return(tabsChanged || tabHasBeenDragged);
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
//Starts a smooth animation to put the views in their correct places
- (void)smoothlyArrangeCells
{
    BOOL finished;

    finished = [self arrangeCellsAbsolute:NO];

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

    int		reducedWidth = 0;
    int		reduceThreshold = 1000000;
    int		tabExtraWidth;
    int		totalTabWidth;

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

    tabXOrigin = CUSTOM_TABS_LEFT_INDENT;

    //Position the tabs
    xLocation = tabXOrigin;
    enumerator = [tabCellArray objectEnumerator];
    while((tabCell = [enumerator nextObject])){
        NSSize	size;
        NSPoint	origin;

        //Get the object's size
        size = [tabCell size];//[object frame].size;

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

            xLocation += size.width - CUSTOM_TABS_OVERLAP; //overlap the tabs a bit
    }

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



