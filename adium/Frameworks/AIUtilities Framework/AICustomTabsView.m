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
#import "AICustomTab.h"
#import "AIImageUtilities.h"
#import "AIViewAdditions.h"
#import "AISystemTabRendering.h"

@interface AICustomTabsView (PRIVATE)
- (void)awakeFromNib;
- (id)initWithFrame:(NSRect)frameRect;
- (void)rebuildViews;
- (void)reorderViews;
- (void)smoothlyArrangeViews;
- (BOOL)arrangeViewsAbsolute:(BOOL)absolute;
- (void)drawRect:(NSRect)rect;
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)TabView;
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender;
- (void)setFocusedForDrag:(BOOL)value;
- (void)setDragIndex:(int)inIndex;
- (int)totalTabWidth;
- (void)moveActiveTabToFront;
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
    [self rebuildViews];
    [self arrangeViewsAbsolute:YES];
}

//init
- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    
    //Load our images
    tabBackground = [[AISystemTabRendering tabBackground] retain];
    
    [self rebuildViews];
    [self arrangeViewsAbsolute:YES];
    
    return(self);
}

- (void)dealloc
{
    [tabArray release];
    [tabBackground release];
    [tabDivider release];
    [dragTab release];

    [super dealloc];
}

//Rebuild the tabs in this view
- (void)rebuildViews
{
    int	loop;
    
    //Remove any existing custom tabs
    [self removeAllSubviews];
    [tabArray release]; tabArray = [[NSMutableArray alloc] init];
    
    //Insert a custom tab for each tabViewItem
    for(loop = 0;loop < [tabView numberOfTabViewItems];loop++){
        NSTabViewItem		*tabViewItem = [tabView tabViewItemAtIndex:loop];
        AICustomTab		*tab;
        
        //Create a new tab
        tab = [AICustomTab customTabWithFrame:NSMakeRect(0, 0, 100, [self frame].size.height) forTabViewItem:tabViewItem]; //100 is arbitrary
        [tab setSelected:(tabViewItem == [tabView selectedTabViewItem])];
        [tab setFrameSize:[tab size]];

        if(tabViewItem == [tabView selectedTabViewItem]){
            [selectedCustomTab release]; selectedCustomTab = [tab retain];
        }
        
        //Add the tab to our view, and to our tab array
        [self addSubview:tab];
        [tabArray addObject:tab];
    }

    //Bring our active tab front
    [self moveActiveTabToFront];
}

//Correctly sets the layering of all tabs.  Left to right, with selected tab in front.
- (void)reorderViews
{
    NSEnumerator	*enumerator;
    AICustomTab		*tab;

    //Remove all tab views
    [self removeAllSubviews];

    //Add tabs right to left, so left is above right
    enumerator = [tabArray reverseObjectEnumerator];
    while((tab = [enumerator nextObject])){
        [self addSubview:tab];
    }

    //Move the selected tab back front
    [self moveActiveTabToFront];
}

//Starts a smooth animation to put the views in their correct places
- (void)smoothlyArrangeViews
{
    BOOL finished;
    
    finished = [self arrangeViewsAbsolute:NO]; 

    //If all the items aren't in place, we set ourself to adjust them again
    if(!finished){
        viewsRearranging = YES;
        [NSTimer scheduledTimerWithTimeInterval:(1.0/CUSTOM_TABS_FPS) target:self selector:@selector(smoothlyArrangeViews) userInfo:nil repeats:NO];
    }else{
        viewsRearranging = NO;
    }
}

//Re-arrange our views to their correct positions
//returns YES is finished.  Pass NO for a partial movement
- (BOOL)arrangeViewsAbsolute:(BOOL)absolute
{
    NSEnumerator	*enumerator;
    NSView		*object;
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
        NSArray	*sortedTabArray;
        NSEnumerator	*enumerator;
        AICustomTab	*tab;
        int		tabCount = 0;
        int		totalTabWidth = 0;

        //Make a copy of the tabArray sorted by width
        sortedTabArray = [tabArray sortedArrayUsingSelector:@selector(compareWidth:)];

        //Process each tab to determine how many should be squished, and the size they should squish to
        enumerator = [sortedTabArray reverseObjectEnumerator];
        tab = [enumerator nextObject];
        do{
            tabCount++;            
            totalTabWidth += [tab size].width;
            reducedWidth = (totalTabWidth - tabExtraWidth) / tabCount;
                
        }while((tab = [enumerator nextObject]) && reducedWidth <= [tab size].width);

        //Remember the treshold at which tabs are squished
        reduceThreshold = (tab ? [tab size].width : 0);

    }//else{
//        tabXOrigin = (-tabExtraWidth) / 2.0;

//    }

    tabXOrigin = CUSTOM_TABS_LEFT_INDENT;


    //Draw the tabs
    xLocation = tabXOrigin;
    enumerator = [tabArray objectEnumerator];
    while((object = [enumerator nextObject])){
        NSSize	size;
        NSPoint	origin;

        //Get the object's size
        size = [(AICustomTab *)object size];//[object frame].size;

        //If this tab is > next biggest, use the 'reduced' width calculated above
        if(size.width > reduceThreshold){
            size.width = reducedWidth;
        }
        
        origin = NSMakePoint(xLocation, 0 );

        //Move the item closer to its desired location
        if(!absolute){
            if(origin.x > [object frame].origin.x){
                int distance = (origin.x - [object frame].origin.x) * 0.6;
                if(distance < 1) distance = 1;
            
                origin.x = [object frame].origin.x + distance;
                
                if(finished) finished = NO;
            }else if(origin.x < [object frame].origin.x){
                int distance = ([object frame].origin.x - origin.x) * 0.6;
                if(distance < 1) distance = 1;
    
                origin.x = [object frame].origin.x - distance;
                if(finished) finished = NO;
            }
        }

        [object setFrame:NSMakeRect(origin.x, origin.y, size.width, size.height)];
        
        xLocation += size.width - CUSTOM_TABS_OVERLAP; //overlap the tabs a bit
    }

    [self setNeedsDisplay:YES];
    return(finished);    
}

//Draw
- (void)drawRect:(NSRect)rect
{
    int imageWidth;
    int xOffset;

    NSRect	tabFrame;
    NSRect	drawRect;
    
    //Get the active tab's frame
    tabFrame = [selectedCustomTab frame];
    
//tabArray
//selectedTab
    //Paint black over region left of active tab
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.20] set];
//    [[NSColor greenColor] set];
    drawRect = NSMakeRect(rect.origin.x,
                          rect.origin.y + 1,
                          tabFrame.origin.x - rect.origin.x,
                          rect.size.height - 1);
    [NSBezierPath fillRect:drawRect];

//    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.38] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(drawRect.origin.x, drawRect.origin.y + drawRect.size.height - 0.5)
                              toPoint:NSMakePoint(drawRect.origin.x + drawRect.size.width, drawRect.origin.y + drawRect.size.height - 0.5)];


    
    //Paint black over region right of active tab
//    [[NSColor blueColor] set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.20] set];
    drawRect = NSMakeRect(tabFrame.origin.x + tabFrame.size.width,
                          rect.origin.y + 1,
                          (rect.origin.x + rect.size.width) - (tabFrame.origin.x + tabFrame.size.width),
                          rect.size.height - 1);
    [NSBezierPath fillRect:drawRect];

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
    

    
    //Draw black 'tab edge mask' portions on left/right of active tab
    //Draw left & right edges of active tab
    //Draw separators between other tabs



    
    
/*    imageWidth = [tabBackground size].width;
    if(tabBackground && imageWidth){
        xOffset = 0;
        while(xOffset < rect.size.width){
            [tabBackground compositeToPoint:NSMakePoint(rect.origin.x + xOffset,0) operation:NSCompositeSourceOver];
            xOffset += imageWidth;
        }
    }*/

    //Draw our subviews
    [super drawRect:rect];
}


//Behavior --------------------------------------------------------------------------------
//Change our selection to match the current selected tabViewItem
- (void)tabView:(NSTabView *)inTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSEnumerator	*enumerator;
    AICustomTab		*tab;
    NSTabViewItem	*selectedTab = [inTabView selectedTabViewItem];

    enumerator = [tabArray objectEnumerator];
    while((tab = [enumerator nextObject])){
        if([tab tabViewItem] == selectedTab){
            [selectedCustomTab release];
            selectedCustomTab = [tab retain];
        }
    }
    
    //Set the tab view as selected
    selectedTab = [inTabView selectedTabViewItem];
//    [self moveActiveTabToFront];
    [self reorderViews];
    
    //Notify
    [[NSNotificationCenter defaultCenter] postNotificationName:AITabView_DidChangeSelectedItem
                                                        object:tabView
                                                      userInfo:[NSDictionary dictionaryWithObjectsAndKeys:tabViewItem,@"TabViewItem",nil]];
}

//Rebuild our tab list to match the tabView
- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)TabView
{
    [self rebuildViews];
    [self arrangeViewsAbsolute:YES];

    //Notify
    [[NSNotificationCenter defaultCenter] postNotificationName:AITabView_DidChangeNumberOfItems
                                                        object:tabView];
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    [self arrangeViewsAbsolute:YES];
}

//Stop dragging when things are switched to metal mode
- (BOOL)mouseDownCanMoveWindow
{
    return(NO);
}


//Drag tracking ------------------------------------------------------------------------
- (void)beginDragOfTab:(AICustomTab *)inTab fromOffset:(NSSize)inOffset
{
    NSImage		*image;
    NSRect		imageRect;
    NSRect		frame = [inTab frame];

    //Bring the tab's view to the very front (so it isn't overlapped by the other tabs while dragging)
    [self bringSubviewToFront:inTab];

    //Create an image of the tab to drag
    image = [[[NSImage alloc] initWithSize:frame.size] autorelease];
    imageRect = NSMakeRect(0,0,frame.size.width,frame.size.height);
    [image lockFocus];
        [inTab drawRect:imageRect];
    [image unlockFocus];
    
    dragImage = [[[NSImage alloc] initWithSize:frame.size] autorelease];
    [dragImage setBackgroundColor:[NSColor clearColor]];
    [dragImage lockFocus];
        [image dissolveToPoint:NSMakePoint(0,0) fraction:0.8];
    [dragImage unlockFocus];

    //
    tabHasBeenDragged = NO;
    dragInitialOffset = inOffset;
    if(dragTab) [dragTab release];
    dragTab = [inTab retain];
}

- (void)updateDragAtOffset:(int)inOffset
{
    NSEnumerator	*enumerator = [tabArray objectEnumerator];
    AICustomTab		*tab;
    int			xLocation;
    int			index = 0;
    int			dragIndex;
    
    //Figure out where the user is hovering the toolbar item
    xLocation = tabXOrigin;
    while((tab = [enumerator nextObject])){
        NSRect	 frame = [tab frame];

        //Force the X origin (to negate any smoothing effects)
        frame.origin.x = xLocation;
        
        //We move to if:
        //+ this isn't the tab we're dragging
        //+ the cursor is where the tab would be if at this index
        //+ the cursor is NOT in the current frame of the drag tab
        if((dragTab != tab) &&
           (inOffset > frame.origin.x) &&
           (inOffset < frame.origin.x + [dragTab frame].size.width) &&
           (inOffset < [dragTab frame].origin.x || inOffset > ([dragTab frame].origin.x + [dragTab frame].size.width)) ){

            //Mark it
            dragIndex = index;
            tabHasBeenDragged = YES;
        }

        index++;
        xLocation += frame.size.width - CUSTOM_TABS_OVERLAP;
    }

    //Exchange the "tabs" (actually views... we leave the origional tabs in their place)
    if(dragIndex >= 0 && dragIndex <= [tabArray count]){
        int existingIndex = [tabArray indexOfObject:dragTab];
        
        if(existingIndex != dragIndex){
            [tabArray removeObjectAtIndex:existingIndex];
            [tabArray insertObject:dragTab atIndex:dragIndex];

        }
    }

    //Arrange the views
    if(!viewsRearranging){
        [self smoothlyArrangeViews];
    }
}

- (BOOL)concludeDrag
{
    NSEnumerator	*enumerator;
    AICustomTab		*customTab;
    NSTabViewItem	*selectedItem = [tabView selectedTabViewItem];
    int			index = 0;
    BOOL		tabsChanged = NO;

    //Rearrange the tab views
    enumerator = [tabArray objectEnumerator];
    while((customTab = [enumerator nextObject])){
        NSTabViewItem	*customTabView = [customTab tabViewItem];
        
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

    //Correctly order the views
    [self reorderViews];

    //Notify 
    if(tabsChanged){      
        [[NSNotificationCenter defaultCenter] postNotificationName:AITabView_DidChangeOrderOfItems object:tabView];
    }

    return(tabsChanged || tabHasBeenDragged);
}

//Returns the total width of our tab tops
- (int)totalTabWidth
{
    NSEnumerator	*enumerator;
    NSView		*object;
    int			totalWidth = 0;

    totalWidth = CUSTOM_TABS_OVERLAP;
    enumerator = [tabArray objectEnumerator];
    while((object = [enumerator nextObject])){
        totalWidth += [(AICustomTab *)object size].width - CUSTOM_TABS_OVERLAP;
    }

    return(totalWidth);
}

//Move the active tab frontward
- (void)moveActiveTabToFront
{
//    NSTabViewItem	*selectedTab = [tabView selectedTabViewItem];
    NSEnumerator	*enumerator;
    AICustomTab		*tab;
    AICustomTab	*previousTab = nil;
    
    enumerator = [tabArray objectEnumerator];
    while((tab = [enumerator nextObject])){
        if(/*[*/tab/* tabViewItem]*/ ==/* selectedTab*/selectedCustomTab){
            [tab setSelected:YES];
            [self bringSubviewToFront:tab]; //Bring the selected view front (to avoid incorrect image overlap)
            [tab setDrawDivider:NO];
            if(previousTab){
                [previousTab setDrawDivider:NO];
            }
        }else{
            [tab setSelected:NO];
            [tab setDrawDivider:YES];
        }
        
        previousTab = tab;
    }
}

@end



