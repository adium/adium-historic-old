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

@interface AICustomTab (PRIVATE)
- (id)initWithFrame:(NSRect)frameRect forTabViewItem:(NSTabViewItem *)inTabViewItem;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)mouseDragged:(NSEvent *)theEvent;
- (void)mouseUp:(NSEvent *)theEvent;
- (void)drawRect:(NSRect)rect;
- (NSRect)grippyRect;
- (void)resetCursorRects;
@end

@implementation AICustomTab

//Create a new custom tab
+ (id)customTabWithFrame:(NSRect)frameRect forTabViewItem:(NSTabViewItem *)inTabViewItem
{
    return([[[self alloc] initWithFrame:frameRect forTabViewItem:inTabViewItem] autorelease]);
}

//Set the selected state of this tab
- (void)setSelected:(BOOL)inSelected
{
    selected = inSelected;
    [self setNeedsDisplay:YES];
}

//Set the depressed state of this tab
- (void)setDepressed:(BOOL)inDepressed
{
    depressed = inDepressed;
    [self setNeedsDisplay:YES];
}

//Return the tab view item this tab is representing
- (NSTabViewItem *)tabViewItem
{
    return(tabViewItem);
}

//Set the title of this tab
- (void)setTitle:(NSAttributedString *)inTitle
{
    if(inTitle != title){
        [title release];
        title = [inTitle retain];
    }
}

//Return the desired size of this tab
- (NSSize)size
{
    NSImage	*left, *right;

    //Pick the correct images depending on our state
    if(depressed){
        left = tabPushLeft;
        right = tabPushRight;
    }else if(selected){
        left = tabFrontLeft;
        right = tabFrontRight;
    }else{
        left = tabBackLeft;
        right = tabBackRight;
    }

    return( NSMakeSize([left size].width + [title size].width + [right size].width, [left size].height) );
}


// Private ---------------------------------------------------------------------
//init
- (id)initWithFrame:(NSRect)frameRect forTabViewItem:(NSTabViewItem *)inTabViewItem
{
    [super initWithFrame:frameRect];

    tabBackLeft = [[AIImageUtilities imageNamed:@"tab_back_left" forClass:[self class]] retain];
    tabBackMiddle = [[AIImageUtilities imageNamed:@"tab_back_middle" forClass:[self class]] retain];
    tabBackRight = [[AIImageUtilities imageNamed:@"tab_back_right" forClass:[self class]] retain];
    tabFrontLeft = [[AIImageUtilities imageNamed:@"tab_front_left" forClass:[self class]] retain];
    tabFrontMiddle = [[AIImageUtilities imageNamed:@"tab_front_middle" forClass:[self class]] retain];
    tabFrontRight = [[AIImageUtilities imageNamed:@"tab_front_right" forClass:[self class]] retain];
    tabPushLeft = [[AIImageUtilities imageNamed:@"tab_push_left" forClass:[self class]] retain];
    tabPushMiddle = [[AIImageUtilities imageNamed:@"tab_push_middle" forClass:[self class]] retain];
    tabPushRight = [[AIImageUtilities imageNamed:@"tab_push_right" forClass:[self class]] retain];
    
    title = [[NSString stringWithString:@"Custom Tab"] retain];
    tabViewItem = [inTabViewItem retain];
    selected = NO;
    dragging = NO;
    trackingRectTag = 0;
    
    return(self);
}

- (void)dealloc
{
    [title release];
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

//Install cursor rects for our 'grippy' spot
- (void)resetCursorRects
{
    NSCursor	*cursor;

    //Discard any existing rects
    [self discardCursorRects];
    
    if(selected){
        if(!dragging){
            cursor = [AICursorUtilities openGrabHandCursor];

            //Add a cursor rect for our grippy spot
            [self addCursorRect:[self grippyRect] cursor:cursor];
            [cursor setOnMouseEntered:YES];

        }else{
/*            NSRect	visibleRect = [self visibleRect];
            visibleRect.origin.x -= 5;
            visibleRect.size.width += 5;*/
        
            cursor = [AICursorUtilities closedGrabHandCursor];
            //The closed grab cursor needs to stay on throughout the drag
            //For some reason I was having trouble making it stick with a set
            //command...This gets the job done good enough to excuse the nastiness
            //of it :)
            [self addCursorRect:[self visibleRect] cursor:cursor];
            [cursor setOnMouseEntered:YES];
            [cursor setOnMouseExited:YES];
        }
    }
}

//Draw
- (void)drawRect:(NSRect)rect
{
    NSImage	*left, *middle, *right;
    int		titleWidth, leftCapWidth, rightCapWidth, middleSourceWidth, middleRightEdge;
    NSRect	sourceRect, destRect;
    
    //Pick the correct images depending on our state
    if(depressed){
        left = tabPushLeft;
        middle = tabPushMiddle;
        right = tabPushRight;
    }else if(selected){
        left = tabFrontLeft;
        middle = tabFrontMiddle;
        right = tabFrontRight;
    }else{
        left = tabBackLeft;
        middle = tabBackMiddle;
        right = tabBackRight;
    }
    
    //Pre-calc some dimensions
    titleWidth = [title size].width;
    leftCapWidth = [left size].width;
    rightCapWidth = [right size].width;
    middleSourceWidth = [middle size].width;
    middleRightEdge = (rect.origin.x + rect.size.width - rightCapWidth);

    //Draw the left cap
    [left compositeToPoint:NSMakePoint(rect.origin.x,rect.origin.y) operation:NSCompositeSourceOver];

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
        
    //Draw the title
    [title drawAtPoint:NSMakePoint(rect.origin.x + leftCapWidth, rect.origin.y + 4)];
    
    //Draw the right cap
    [right compositeToPoint:NSMakePoint(middleRightEdge, rect.origin.y) operation:NSCompositeSourceOver];
}

//Returns the rect of our grippy spot
- (NSRect)grippyRect
{
    return(NSMakeRect(1, 2, [tabFrontLeft size].width - 2, [tabFrontLeft size].height - 8));
}

//Mouse tracking / Clicking ------
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint	location = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    if(selected && NSPointInRect(location, [self grippyRect])){
        dragging = YES;
        [[self window] invalidateCursorRectsForView:self];
        [(AICustomTabsView *)[self superview] beginDragOfTab:self fromOffset:NSMakeSize(location.x, location.y)];

    }else if(!selected){
        [self setDepressed:YES];
    }
    
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint	location = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if(dragging){
        [(AICustomTabsView *)[self superview] updateDragAtOffset:(int)location.x];
    }else if(!selected){
        if(NSPointInRect(location, [self frame])){
            if(!depressed) [self setDepressed:YES];
        }else{
            if(depressed) [self setDepressed:NO];
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint	location = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if(dragging){

        dragging = NO;
        [[self window] invalidateCursorRectsForView:self];
        [(AICustomTabsView *)[self superview] concludeDrag];

    }else{
        if(NSPointInRect(location, [self frame])){
            //Select our tab
            [[tabViewItem tabView] selectTabViewItem:tabViewItem];
        }
        
        [self setDepressed:NO];
    }
}


@end
