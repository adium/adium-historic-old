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

#import "AICustomTabCell.h"
#import "AICustomTabsView.h"
#import "AIImageUtilities.h"
#import "AICursorAdditions.h"

@interface AICustomTabCell (PRIVATE)
- (id)initForTabViewItem:(NSTabViewItem *)inTabViewItem;
@end

#define TAB_LABEL_INSET		-4	//Pixels the tab's label is inset into it's endcap
#define TAB_CLOSE_LEFTPAD	0
#define TAB_CLOSE_RIGHTPAD	2
#define TAB_CLOSE_Y_OFFSET	4

@implementation AICustomTabCell

//Create a new custom tab
+ (id)customTabForTabViewItem:(NSTabViewItem *)inTabViewItem
{
    return([[[self alloc] initForTabViewItem:inTabViewItem] autorelease]);
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
}

- (void)setHighlighted:(BOOL)inHighlighted
{
    highlighted = inHighlighted;
}

//Calculated frame for this cell
- (void)setFrame:(NSRect)inFrame
{
    frame = inFrame;
}

- (NSRect)frame
{
    return(frame);
}

//Return the desired size of this tab
- (NSSize)size
{
    return( NSMakeSize([tabFrontLeft size].width + TAB_CLOSE_LEFTPAD + [tabCloseFront size].width + TAB_CLOSE_RIGHTPAD + [tabViewItem sizeOfLabel:NO].width + TAB_CLOSE_LEFTPAD + [tabCloseFront size].width + TAB_CLOSE_RIGHTPAD + [tabFrontRight size].width, [tabFrontLeft size].height) );
}

- (NSComparisonResult)compareWidth:(AICustomTabCell *)tab
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
- (id)initForTabViewItem:(NSTabViewItem *)inTabViewItem
{
    [super init];

    tabFrontLeft = [[AIImageUtilities imageNamed:@"Tab_Left" forClass:[self class]] retain];
    tabFrontMiddle = [[AIImageUtilities imageNamed:@"Tab_Middle" forClass:[self class]] retain];
    tabFrontRight = [[AIImageUtilities imageNamed:@"Tab_Right" forClass:[self class]] retain];

    tabBackLeft = [[AIImageUtilities imageNamed:@"TabMask_Left" forClass:[self class]] retain];
    tabBackRight = [[AIImageUtilities imageNamed:@"TabMask_Right" forClass:[self class]] retain];
    tabBackMiddle = [[AIImageUtilities imageNamed:@"TabMask_Middle" forClass:[self class]] retain];

    tabCloseFront = [[AIImageUtilities imageNamed:@"TabClose_Front" forClass:[self class]] retain];
    tabCloseFrontPressed = [[AIImageUtilities imageNamed:@"TabClose_Front_Pressed" forClass:[self class]] retain];
    
    tabViewItem = [inTabViewItem retain];
    selected = NO;
    dragging = NO;
    trackingTag = 0;

    //
    closeButtonRect = NSMakeRect([tabFrontLeft size].width + TAB_CLOSE_LEFTPAD,
                                 TAB_CLOSE_Y_OFFSET,
                                 [tabCloseFront size].width,
                                 [tabCloseFront size].height);
        
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
    
    [tabCloseFront release];
    [tabCloseFrontPressed release];

    [super dealloc];
}

//Draw
- (void)drawWithFrame:(NSRect)rect inView:(NSView *)controlView
{
    int		leftCapWidth, rightCapWidth, middleSourceWidth, middleRightEdge, middleLeftEdge, middleWidth, tabCloseWidth, tabBadgeWidth;
    NSRect	sourceRect, destRect;
    NSPoint	destPoint;
    NSSize	labelSize;

    //Pre-calc some dimensions
    labelSize = [tabViewItem sizeOfLabel:NO];
    leftCapWidth = [tabFrontLeft size].width;
    rightCapWidth = [tabFrontRight size].width;
    middleSourceWidth = [tabFrontMiddle size].width;
    middleRightEdge = (rect.origin.x + rect.size.width - rightCapWidth);
    middleLeftEdge = (rect.origin.x + leftCapWidth);
    middleWidth = middleRightEdge - middleLeftEdge;
    tabCloseWidth = [tabCloseFront size].width;
    tabBadgeWidth = tabCloseWidth;

    if(selected){
        //Draw left mask
        [tabBackLeft compositeToPoint:NSMakePoint(rect.origin.x, rect.origin.y) operation:NSCompositeSourceOver];

        //Draw the left cap
        [tabFrontLeft compositeToPoint:NSMakePoint(rect.origin.x, rect.origin.y) operation:NSCompositeSourceOver];
    
        //Draw the middle
        sourceRect = NSMakeRect(0, 0, [tabFrontMiddle size].width, [tabFrontMiddle size].height);
        destRect = NSMakeRect(middleLeftEdge, rect.origin.y, sourceRect.size.width, sourceRect.size.height);
    
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
        [tabBackRight compositeToPoint:NSMakePoint(middleRightEdge, rect.origin.y) operation:NSCompositeSourceOver];

        //Draw the right cap
        [tabFrontRight compositeToPoint:NSMakePoint(middleRightEdge, rect.origin.y) operation:NSCompositeSourceOver];

    }

    //Fill our content color
    NSColor	*tabColor = [tabViewItem color];
    if(tabColor && !selected){
        [[tabViewItem color] set];
        [NSBezierPath fillRect:NSMakeRect(rect.origin.x + 2, rect.origin.y, rect.size.width - 3, rect.size.height)];
    }else if(highlighted && !selected){
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.08] set];
        [NSBezierPath fillRect:NSMakeRect(rect.origin.x + 2, rect.origin.y, rect.size.width - 3, rect.size.height)];
    }
    
    //Draw the close widget
    if(selected){
        destPoint = NSMakePoint(rect.origin.x + leftCapWidth + TAB_CLOSE_LEFTPAD, rect.origin.y + TAB_CLOSE_Y_OFFSET);

        if(hoveringClose){
            [tabCloseFrontPressed compositeToPoint:destPoint operation:NSCompositeSourceOver];
        }else{
            [tabCloseFront compositeToPoint:destPoint operation:NSCompositeSourceOver];
        }
    }

    //Draw the title
    destRect = NSMakeRect(rect.origin.x + leftCapWidth + TAB_CLOSE_LEFTPAD + tabCloseWidth + TAB_CLOSE_RIGHTPAD,
                          rect.origin.y + (int)((rect.size.height - labelSize.height) / 2.0), //center it vertically
                          middleWidth - tabCloseWidth - TAB_CLOSE_LEFTPAD - tabBadgeWidth - TAB_CLOSE_RIGHTPAD,
                          labelSize.height);
    [tabViewItem drawLabel:YES inRect:destRect];
}

//Mouse tracking / Clicking -------------------------------------------
- (void)setTrackingTag:(NSTrackingRectTag)inTag{
    trackingTag = inTag;
}
- (NSTrackingRectTag)trackingTag{
    return(trackingTag);
}


- (BOOL)willTrackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
    NSPoint	clickLocation = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect	offsetCloseButtonRect = NSOffsetRect(closeButtonRect, cellFrame.origin.x, cellFrame.origin.y);
    
    if(NSPointInRect(clickLocation, offsetCloseButtonRect)){
        //Track the close button
        [self trackMouse:theEvent
                  inRect:offsetCloseButtonRect
                  ofView:controlView
            untilMouseUp:YES];

        return(YES);
        
    }else{
        return(NO);
        
    }
}

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
    hoveringClose = YES;
    [controlView setNeedsDisplay:YES];

    return(YES);
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
    NSRect	offsetCloseButtonRect = NSOffsetRect(closeButtonRect, [self frame].origin.x, [self frame].origin.y);
    BOOL	hovering = NSPointInRect(currentPoint, offsetCloseButtonRect);

    if(hoveringClose != hovering){
        hoveringClose = hovering;
        [controlView setNeedsDisplay:YES];
    }
    
    return(YES);
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
    NSRect	offsetCloseButtonRect = NSOffsetRect(closeButtonRect, [self frame].origin.x, [self frame].origin.y);
    BOOL	hovering = NSPointInRect(stopPoint, offsetCloseButtonRect);

    if(hovering){
        [(AICustomTabsView *)controlView removeTabViewItem:tabViewItem];
    }
    
    hoveringClose = NO;
    [controlView setNeedsDisplay:YES];
}

@end
