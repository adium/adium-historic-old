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

#import "AICustomTab.h"
#import "AICustomTabsView.h"
#import "AIImageUtilities.h"
#import "AICursorUtilities.h"
#import "AISystemTabRendering.h"

@interface AICustomTab (PRIVATE)
- (id)initWithFrame:(NSRect)frameRect forTabViewItem:(NSTabViewItem *)inTabViewItem;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)drawRect:(NSRect)rect;
- (NSRect)grippyRect;
- (void)resetCursorRects;
@end

#define TAB_LABEL_INSET		3	//Pixels the tab's label is inset into it's endcap
#define TAB_DRAG_DISTANCE 	4	//Distance required before a drag kicks in

@implementation AICustomTab

//Create a new custom tab
+ (id)customTabWithFrame:(NSRect)frameRect forTabViewItem:(NSTabViewItem *)inTabViewItem
{
    return([[[self alloc] initWithFrame:frameRect forTabViewItem:inTabViewItem] autorelease]);
}

//Return the tab view item this tab is representing
- (NSTabViewItem *)tabViewItem
{
    return(tabViewItem);
}

//Set the selected state of this tab
- (void)setSelected:(BOOL)inSelected
{
    selected = inSelected;
    [[self superview] setNeedsDisplay:YES]; //Since tabs overlap, we must redisplay them all
}

//Set the depressed state of this tab
- (void)setDepressed:(BOOL)inDepressed
{
    depressed = inDepressed;
    [[self superview] setNeedsDisplay:YES]; //Since tabs overlap, we must redisplay them all
}

//Return the desired size of this tab
- (NSSize)size
{
    return( NSMakeSize([tabFrontLeft size].width + [tabViewItem sizeOfLabel:NO].width - (TAB_LABEL_INSET * 2) + [tabFrontRight size].width, [tabFrontLeft size].height) ); //the label is inset into each cap
}


// Private ---------------------------------------------------------------------
//init
- (id)initWithFrame:(NSRect)frameRect forTabViewItem:(NSTabViewItem *)inTabViewItem
{
    [super initWithFrame:frameRect];

/*  tabBackLeft = [[AIImageUtilities imageNamed:@"tab_back_left" forClass:[self class]] retain];
    tabBackMiddle = [[AIImageUtilities imageNamed:@"tab_back_middle" forClass:[self class]] retain];
    tabBackRight = [[AIImageUtilities imageNamed:@"tab_back_right" forClass:[self class]] retain];
    tabFrontLeft = [[AIImageUtilities imageNamed:@"tab_front_left" forClass:[self class]] retain];
    tabFrontMiddle = [[AIImageUtilities imageNamed:@"tab_front_middle" forClass:[self class]] retain];
    tabFrontRight = [[AIImageUtilities imageNamed:@"tab_front_right" forClass:[self class]] retain];
    tabPushLeft = [[AIImageUtilities imageNamed:@"tab_push_left" forClass:[self class]] retain];
    tabPushMiddle = [[AIImageUtilities imageNamed:@"tab_push_middle" forClass:[self class]] retain];
    tabPushRight = [[AIImageUtilities imageNamed:@"tab_push_right" forClass:[self class]] retain];
*/
    tabFrontLeft = [[AISystemTabRendering tabFrontLeft] retain];
    tabFrontMiddle = [[AISystemTabRendering tabFrontMiddle] retain];
    tabFrontRight = [[AISystemTabRendering tabFrontRight] retain];
    tabBackLeft = [[AISystemTabRendering tabBackLeft] retain];
    tabBackMiddle = [[AISystemTabRendering tabBackMiddle] retain];
    tabBackRight = [[AISystemTabRendering tabBackRight] retain];
    tabPushLeft = [[AISystemTabRendering tabPushLeft] retain];
    tabPushMiddle = [[AISystemTabRendering tabPushMiddle] retain];
    tabPushRight = [[AISystemTabRendering tabPushRight] retain];
    
    tabViewItem = [inTabViewItem retain];
    selected = NO;
    dragging = NO;
    trackingRectTag = 0;
    
    return(self);
}

- (void)dealloc
{
    [tabViewItem release];

    [tabBackLeft release];
    [tabBackMiddle release];
    [tabBackRight release];
    [tabFrontLeft release];
    [tabFrontMiddle release];
    [tabFrontRight release];
    [tabPushLeft release];
    [tabPushMiddle release];
    [tabPushRight release];

    [super dealloc];
}

//Draw
- (void)drawRect:(NSRect)rect
{
    NSImage	*left, *middle, *right;
    int		leftCapWidth, rightCapWidth, middleSourceWidth, middleRightEdge;
    NSRect	sourceRect, destRect;
    NSSize	labelSize;
    
    //Pick the correct images depending on our state
    if(depressed){
        left = tabPushLeft; middle = tabPushMiddle; right = tabPushRight;
    }else if(selected){
        left = tabFrontLeft; middle = tabFrontMiddle; right = tabFrontRight;
    }else{
        left = tabBackLeft; middle = tabBackMiddle; right = tabBackRight;
    }
    
    //Pre-calc some dimensions
    labelSize = [tabViewItem sizeOfLabel:NO];
    leftCapWidth = [left size].width;
    rightCapWidth = [right size].width;
    middleSourceWidth = [middle size].width;
    middleRightEdge = (rect.origin.x + rect.size.width - rightCapWidth);

    //Draw the left cap
    [left compositeToPoint:NSMakePoint(rect.origin.x, rect.origin.y) operation:NSCompositeSourceOver];

    //Draw the middle
    sourceRect = NSMakeRect(0, 0, [middle size].width, [middle size].height);
    destRect = NSMakeRect(rect.origin.x + leftCapWidth, rect.origin.y, sourceRect.size.width, sourceRect.size.height);

    while(destRect.origin.x < middleRightEdge){
        //Crop
        if((destRect.origin.x + destRect.size.width) > middleRightEdge){
            destRect.size.width -= (destRect.origin.x + destRect.size.width) - middleRightEdge;
        }

        [middle drawInRect:destRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0];
        destRect.origin.x += destRect.size.width;
    }

    //Draw the right cap
    [right compositeToPoint:NSMakePoint(middleRightEdge, rect.origin.y) operation:NSCompositeSourceOver];

    //Draw the title
    destRect = NSMakeRect(rect.origin.x + leftCapWidth - TAB_LABEL_INSET,
                          rect.origin.y + 3 + ((rect.size.height - labelSize.height) / 2.0), //center it vertically
                          labelSize.width,
                          labelSize.height);
    [tabViewItem drawLabel:NO inRect:destRect];
}


//Grippy Spot --------------------------------------------------------------------
//Install cursor rects for our 'grippy' spot
- (void)resetCursorRects
{
    NSCursor	*cursor;

    //Discard any existing rects
    [self discardCursorRects];

    if(dragging){
        cursor = [AICursorUtilities closedGrabHandCursor];
        //The closed grab cursor needs to stay on throughout the drag
        //For some reason I was having trouble making it stick with a set
        //command...This gets the job done good enough to excuse the nastiness
        //of it :)
        [self addCursorRect:[[self superview] visibleRect] cursor:cursor];
        [cursor setOnMouseEntered:YES];
    }
}

//Mouse tracking / Clicking -------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent
{
    clickLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];

    if(!selected){
        [self setDepressed:YES];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint	location = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];	//local to super

    if(dragging){
        //Update an existing drag
        [(AICustomTabsView *)[self superview] updateDragAtOffset:(int)location.x];

    }else{
        if( (clickLocation.x - location.x) > TAB_DRAG_DISTANCE || (clickLocation.x - location.x) < -TAB_DRAG_DISTANCE ||
            (clickLocation.y - location.y) > TAB_DRAG_DISTANCE || (clickLocation.y - location.y) < -TAB_DRAG_DISTANCE ){
            //if we've moved enough, initiate a drag
            [(AICustomTabsView *)[self superview] beginDragOfTab:self fromOffset:NSMakeSize(location.x, location.y)];
            dragging = YES;

        }else{
            //Update the 'pressed' highlighting
            if(!selected){
                if(NSPointInRect(location, [self frame])){
                    if(!depressed) [self setDepressed:YES];
                }else{
                    if(depressed) [self setDepressed:NO];
                }
            }
        }
    }

}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint	location = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if(dragging){
        //End dragging
        dragging = NO;
        [[self window] invalidateCursorRectsForView:self];
        if(![(AICustomTabsView *)[self superview] concludeDrag]){
            [[tabViewItem tabView] selectTabViewItem:tabViewItem];
        }
        [self setDepressed:NO];

    }else{
        if(NSPointInRect(location, [self frame])){
            //Select our tab
            [[tabViewItem tabView] selectTabViewItem:tabViewItem];
        }
        
        [self setDepressed:NO];
    }
}


@end
