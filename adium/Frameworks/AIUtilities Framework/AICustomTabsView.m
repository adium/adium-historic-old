/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#define CUSTOM_TABS_OVERLAP	6		//Overlapped pixels between tabs

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

        //Add the tab to our view, and to our tab array
        [self addSubview:tab];
        [tabArray addObject:tab];
    }

    //Bring our active tab front
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

    //Precalc the total width
    xLocation = ([self frame].size.width - [self totalTabWidth]) / 2.0;
    enumerator = [tabArray objectEnumerator];
    while((object = [enumerator nextObject])){
        NSSize	size;
        NSPoint	origin;

        //Get the object's size
        size = [object frame].size;
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

        [object setFrame:NSMakeRect(origin.x, origin.y, [object frame].size.width, [object frame].size.height)];
        
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
    
    //Draw the background
    imageWidth = [tabBackground size].width;
    if(tabBackground && imageWidth){
        xOffset = 0;
        while(xOffset < rect.size.width){
            [tabBackground compositeToPoint:NSMakePoint(rect.origin.x + xOffset,0) operation:NSCompositeSourceOver];
            xOffset += imageWidth;
        }
    }

    //Draw our subviews
    [super drawRect:rect];
}

//Behavior --------------------------------------------------------------------------------
//Change our selection to match the current selected tabViewItem
- (void)tabView:(NSTabView *)inTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    //Set the tab view as selected
    [self moveActiveTabToFront];

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
    xLocation = ([self frame].size.width - [self totalTabWidth]) / 2.0;
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

    //Notify 
    if(tabsChanged){      
        [[NSNotificationCenter defaultCenter] postNotificationName:AITabView_DidChangeOrderOfItems object:tabView];
    }

    return(tabsChanged);
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
        totalWidth += [object frame].size.width - CUSTOM_TABS_OVERLAP;
    }

    return(totalWidth);
}

- (void)moveActiveTabToFront
{
    NSTabViewItem	*selectedTab = [tabView selectedTabViewItem];
    NSEnumerator	*enumerator;
    AICustomTab		*tab;
    
    enumerator = [tabArray objectEnumerator];
    while((tab = [enumerator nextObject])){
        if([tab tabViewItem] == selectedTab){
            [tab setSelected:YES];
            [self bringSubviewToFront:tab]; //Bring the selected view front (to avoid incorrect image overlap)
        }else{
            [tab setSelected:NO];
        }
    }
}

@end



