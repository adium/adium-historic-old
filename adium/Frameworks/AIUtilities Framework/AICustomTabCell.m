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

#define ALLOW_CLOSING_INACTIVE_TABS     NO      //Make this a pref eventually

@interface AICustomTabCell (PRIVATE)
- (id)initForTabViewItem:(NSTabViewItem *)inTabViewItem;
@end

//Images (Shared between instances)
static NSImage		*tabBackLeft = nil;
static NSImage		*tabBackMiddle = nil;
static NSImage		*tabBackRight = nil;
static NSImage		*tabFrontLeft = nil;
static NSImage		*tabFrontMiddle = nil;
static NSImage		*tabFrontRight = nil;
static NSImage		*tabCloseFront = nil;
static NSImage		*tabCloseBack = nil;
static NSImage		*tabCloseFrontPressed = nil;
static NSImage		*tabCloseFrontRollover = nil;

#define TAB_CLOSE_LEFTPAD	2	//Padding left of close button
#define TAB_CLOSE_RIGHTPAD	4	//Padding right of close button
#define TAB_CLOSE_Y_OFFSET	4 // 5
#define TAB_RIGHT_PAD		6
#define TAB_MIN_WIDTH		10 //90

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
- (BOOL)isSelected{
    return(selected);
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
    float width = [tabFrontLeft size].width + [tabViewItem sizeOfLabel:NO].width + [tabFrontRight size].width + (TAB_CLOSE_LEFTPAD + [tabCloseFront size].width + TAB_CLOSE_RIGHTPAD) + TAB_RIGHT_PAD;
    
    return( NSMakeSize((width > TAB_MIN_WIDTH ? width : TAB_MIN_WIDTH), [tabFrontLeft size].height) );
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
    static BOOL haveLoadedImages = NO;
    
    [super init];

    //Share these images between all AICustomTabCell instances
    if(!haveLoadedImages){
        tabFrontLeft = [[AIImageUtilities imageNamed:@"Tab_Left" forClass:[self class]] retain];
        tabFrontMiddle = [[AIImageUtilities imageNamed:@"Tab_Middle" forClass:[self class]] retain];
        tabFrontRight = [[AIImageUtilities imageNamed:@"Tab_Right" forClass:[self class]] retain];

        tabBackLeft = [[AIImageUtilities imageNamed:@"TabMask_Left" forClass:[self class]] retain];
        tabBackRight = [[AIImageUtilities imageNamed:@"TabMask_Right" forClass:[self class]] retain];
        tabBackMiddle = [[AIImageUtilities imageNamed:@"TabMask_Middle" forClass:[self class]] retain];

        tabCloseFront = [[AIImageUtilities imageNamed:@"TabClose_Front" forClass:[self class]] retain];
        tabCloseBack = [[AIImageUtilities imageNamed:@"TabClose_Back" forClass:[self class]] retain];
        tabCloseFrontPressed = [[AIImageUtilities imageNamed:@"TabClose_Front_Pressed" forClass:[self class]] retain];
        tabCloseFrontRollover = [[AIImageUtilities imageNamed:@"TabClose_Front_Rollover" forClass:[self class]] retain];

        haveLoadedImages = YES;
    }

    
    //init
    tabViewItem = inTabViewItem;
    trackingClose = NO;
    hoveringClose = NO;
    selected = NO;
    dragging = NO;
    trackingTag = 0;
    closeTrackingTag = 0;

    //Calculate the close button position ahead of time
    closeButtonRect = NSMakeRect([tabFrontLeft size].width + TAB_CLOSE_LEFTPAD,
                                 TAB_CLOSE_Y_OFFSET,
                                 [tabCloseFront size].width,
                                 [tabCloseFront size].height);
        
    return(self);
}

- (void)dealloc
{
    [super dealloc];
}

//Draw
- (void)drawWithFrame:(NSRect)rect inView:(NSView *)controlView
{
    int		leftCapWidth, rightCapWidth, middleSourceWidth, middleRightEdge, middleLeftEdge, tabCloseWidth;
    NSRect	sourceRect, destRect;
    NSSize	labelSize;

    //Pre-calc some dimensions
    labelSize = [tabViewItem sizeOfLabel:NO];
    leftCapWidth = [tabFrontLeft size].width;
    rightCapWidth = [tabFrontRight size].width;
    middleSourceWidth = [tabFrontMiddle size].width;
    middleRightEdge = (rect.origin.x + rect.size.width - rightCapWidth);
    middleLeftEdge = (rect.origin.x + leftCapWidth);
    tabCloseWidth = [tabCloseFront size].width;

    //Background
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

    }else if(highlighted){
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.08] set];
        [NSBezierPath fillRect:NSMakeRect(rect.origin.x + 2, rect.origin.y, rect.size.width - 3, rect.size.height)];
    }

    //
    rect.origin.x += leftCapWidth;
    rect.size.width -= leftCapWidth + rightCapWidth;
    
    //Close Button
    //if([[tabViewItem tabView] numberOfTabViewItems] != 1/* && selected*/){
        NSPoint	destPoint = NSMakePoint(rect.origin.x + TAB_CLOSE_LEFTPAD, rect.origin.y + TAB_CLOSE_Y_OFFSET);

        if(hoveringClose){
            [(trackingClose ? tabCloseFrontPressed : tabCloseFrontRollover) compositeToPoint:destPoint operation:NSCompositeSourceOver];
        }else{
            [(selected ? tabCloseFront : tabCloseBack) compositeToPoint:destPoint operation:NSCompositeSourceOver];
        }

        rect.origin.x += TAB_CLOSE_LEFTPAD + tabCloseWidth + TAB_CLOSE_RIGHTPAD;
        rect.size.width -= (TAB_CLOSE_LEFTPAD + tabCloseWidth + TAB_CLOSE_RIGHTPAD) + TAB_RIGHT_PAD;
    //}
    
    //Draw the title
    destRect = NSMakeRect(rect.origin.x,
                            rect.origin.y + (int)((rect.size.height - labelSize.height) / 2.0), //center it vertically
                            rect.size.width,
                            labelSize.height);
    [tabViewItem drawLabel:YES inRect:destRect];

}

//Hover tracking ----------------------------------------------------------------
//Install tracking rects for our tab and its close button
- (void)addTrackingRectsInView:(NSView *)view withFrame:(NSRect)trackRect cursorLocation:(NSPoint)cursorLocation
{
    NSRect	offsetCloseButtonRect = NSOffsetRect(closeButtonRect, [self frame].origin.x, [self frame].origin.y);

    userData = [[NSDictionary dictionaryWithObjectsAndKeys:view, @"view", nil] retain]; //We have to retain and release the userData ourself
    trackingTag = [view addTrackingRect:trackRect
                                  owner:self
                               userData:userData
                           assumeInside:NSPointInRect(cursorLocation, trackRect)];
    highlighted = NSPointInRect(cursorLocation, trackRect);

    closeUserData = [[NSDictionary dictionaryWithObjectsAndKeys:view, @"view", [NSNumber numberWithBool:YES], @"close", nil] retain]; //We have to retain and release the userData ourself
    closeTrackingTag = [view addTrackingRect:offsetCloseButtonRect
                                       owner:self
                                    userData:closeUserData
                                assumeInside:NSPointInRect(cursorLocation, offsetCloseButtonRect)];
    hoveringClose = NSPointInRect(cursorLocation, offsetCloseButtonRect);
}

//Remove our tracking rects
- (void)removeTrackingRectsFromView:(NSView *)view
{
    [view removeTrackingRect:trackingTag]; trackingTag = 0;
    [userData release]; userData = nil;
    
    [view removeTrackingRect:closeTrackingTag]; closeTrackingTag = 0;
    [closeUserData release]; closeUserData = nil;
}

//Mouse entered our tabs (or close button)
- (void)mouseEntered:(NSEvent *)theEvent
{
    NSRect          offsetCloseButtonRect = NSOffsetRect(closeButtonRect, [self frame].origin.x, [self frame].origin.y);
    NSDictionary    *eventData = [theEvent userData];
    NSView          *view = [eventData objectForKey:@"view"];

    //Set ourself (or our close button) has hovered
    if((ALLOW_CLOSING_INACTIVE_TABS || selected) && [[eventData objectForKey:@"close"] boolValue]){
        hoveringClose = YES;
        [view setNeedsDisplayInRect:offsetCloseButtonRect];
    }else{
        highlighted = YES;
        [view setNeedsDisplayInRect:[self frame]];
    }
}

//Mouse left one of our tabs
- (void)mouseExited:(NSEvent *)theEvent
{
    NSRect          offsetCloseButtonRect = NSOffsetRect(closeButtonRect, [self frame].origin.x, [self frame].origin.y);
    NSDictionary    *eventData = [theEvent userData];
    NSView          *view = [eventData objectForKey:@"view"];

    //Set ourself (or our close button) has not hovered
    if((ALLOW_CLOSING_INACTIVE_TABS || selected) && [[eventData objectForKey:@"close"] boolValue]){
        hoveringClose = NO;
        [view setNeedsDisplayInRect:offsetCloseButtonRect];
    }else{
        highlighted = NO;
        [view setNeedsDisplayInRect:[self frame]];
    }
}

//Mouse tracking / Clicking -----------------------------------------------------
//Mouse-down tracking
- (BOOL)willTrackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
    NSPoint	clickLocation = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect	offsetCloseButtonRect = NSOffsetRect(closeButtonRect, cellFrame.origin.x, cellFrame.origin.y);
    
    if((ALLOW_CLOSING_INACTIVE_TABS || selected) && /*[[tabViewItem tabView] numberOfTabViewItems] != 1 &&*/ NSPointInRect(clickLocation, offsetCloseButtonRect)){
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
    NSRect	offsetCloseButtonRect = NSOffsetRect(closeButtonRect, [self frame].origin.x, [self frame].origin.y);

    trackingClose = YES;
    hoveringClose = YES;
    [controlView setNeedsDisplayInRect:offsetCloseButtonRect];

    return(YES);
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView *)controlView
{
    NSRect	offsetCloseButtonRect = NSOffsetRect(closeButtonRect, [self frame].origin.x, [self frame].origin.y);
    BOOL	hovering = NSPointInRect(currentPoint, offsetCloseButtonRect);

    if(hoveringClose != hovering){
        hoveringClose = hovering;
        [controlView setNeedsDisplayInRect:offsetCloseButtonRect];
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
    trackingClose = NO;
    [controlView setNeedsDisplayInRect:offsetCloseButtonRect];
}

@end
