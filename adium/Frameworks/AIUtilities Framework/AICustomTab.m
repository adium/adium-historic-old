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

#import "AICustomTab.h"
#import "AICustomTabsView.h"
#import "AIImageUtilities.h"
#import "AICursorAdditions.h"
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

#define TAB_LABEL_INSET		-4	//Pixels the tab's label is inset into it's endcap
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

//
- (void)setDrawDivider:(BOOL)inDrawDivider
{
    drawDivider = inDrawDivider;
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

- (NSComparisonResult)compareWidth:(AICustomTab *)tab
{
    int	tabWidth = [tab size].width;
    int	ourWidth = [self size].width;

    if(tabWidth > ourWidth){
        return(NSOrderedAscending);
        
    }else if(tabWidth < ourWidth){
        return(NSOrderedDescending);
        
    }else{
        return(NSOrderedSame);
        
    }
}



// Private ---------------------------------------------------------------------
//init
- (id)initWithFrame:(NSRect)frameRect forTabViewItem:(NSTabViewItem *)inTabViewItem
{
    [super initWithFrame:frameRect];

    tabFrontLeft = [[AIImageUtilities imageNamed:@"Tab_Left.tiff" forClass:[self class]] retain];
    tabFrontMiddle = [[AIImageUtilities imageNamed:@"Tab_Middle.tiff" forClass:[self class]] retain];
    tabFrontRight = [[AIImageUtilities imageNamed:@"Tab_Right.tiff" forClass:[self class]] retain];

    tabBackLeft = [[AIImageUtilities imageNamed:@"TabMask_Left.tiff" forClass:[self class]] retain];
    tabBackRight = [[AIImageUtilities imageNamed:@"TabMask_Right.tiff" forClass:[self class]] retain];
    tabBackMiddle = [[AIImageUtilities imageNamed:@"TabMask_Middle.tiff" forClass:[self class]] retain];

    tabDivider = [[AIImageUtilities imageNamed:@"Tab_Divider.tiff" forClass:[self class]] retain];

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

    [super dealloc];
}

- (BOOL)isFlipped
{
    return(YES);
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return(YES);
}

//Draw
- (void)drawRect:(NSRect)rect
{
    int		leftCapWidth, rightCapWidth, middleSourceWidth, middleRightEdge, middleLeftEdge, middleWidth;
    NSRect	sourceRect, destRect;
    NSSize	labelSize;
      
    //Pre-calc some dimensions
    labelSize = [tabViewItem sizeOfLabel:NO];
    leftCapWidth = [tabFrontLeft size].width;
    rightCapWidth = [tabFrontRight size].width;
    middleSourceWidth = [tabFrontMiddle size].width;
    middleRightEdge = (rect.origin.x + rect.size.width - rightCapWidth);
    middleLeftEdge = (rect.origin.x + leftCapWidth);
    middleWidth = middleRightEdge - middleLeftEdge;

    if(selected){
        //Draw left mask
        [tabBackLeft compositeToPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height) operation:NSCompositeSourceOver];

        //Draw the left cap
        [tabFrontLeft compositeToPoint:NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height) operation:NSCompositeSourceOver];
    
        //Draw the middle
        sourceRect = NSMakeRect(0, 0, [tabFrontMiddle size].width, [tabFrontMiddle size].height);
        destRect = NSMakeRect(middleLeftEdge, rect.origin.y + rect.size.height, sourceRect.size.width, sourceRect.size.height);
    
        while(destRect.origin.x < middleRightEdge){
            //Crop
            if((destRect.origin.x + destRect.size.width) > middleRightEdge){
                sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - middleRightEdge;
            }

            [tabBackMiddle compositeToPoint:destRect.origin fromRect:sourceRect operation:NSCompositeSourceOver];
            [tabFrontMiddle compositeToPoint:destRect.origin fromRect:sourceRect operation:NSCompositeSourceOver];
            destRect.origin.x += destRect.size.width;
        }

        //Draw right mask
        [tabBackRight compositeToPoint:NSMakePoint(middleRightEdge, rect.origin.y + rect.size.height) operation:NSCompositeSourceOver];

        //Draw the right cap
        [tabFrontRight compositeToPoint:NSMakePoint(middleRightEdge, rect.origin.y + rect.size.height) operation:NSCompositeSourceOver];
    }else{
        if(drawDivider){
            //Draw the divider
            [tabDivider compositeToPoint:NSMakePoint(middleRightEdge, rect.origin.y + rect.size.height) operation:NSCompositeSourceOver];
            
        }
        
    }
    
    //Draw the title
    destRect = NSMakeRect(rect.origin.x + leftCapWidth - TAB_LABEL_INSET,
                          rect.origin.y + (int)((rect.size.height - labelSize.height) / 2.0), //center it vertically
                          middleWidth + (TAB_LABEL_INSET * 2),
			  labelSize.height);

    [tabViewItem drawLabel:YES inRect:destRect];
}


//Grippy Spot --------------------------------------------------------------------
//Install cursor rects for our 'grippy' spot
- (void)resetCursorRects
{
    NSCursor	*cursor;

    //Discard any existing rects
    [self discardCursorRects];

    if(dragging){
        cursor = [NSCursor closedGrabHandCursor];
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
    //Select our tab
    [[tabViewItem tabView] selectTabViewItem:tabViewItem];
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
        }
    }

}

- (void)mouseUp:(NSEvent *)theEvent
{
    if(dragging){
        //End dragging
        dragging = NO;
        [[self window] invalidateCursorRectsForView:self];
        [(AICustomTabsView *)[self superview] concludeDrag];

        [[tabViewItem tabView] selectTabViewItem:tabViewItem];
    }
}


@end
