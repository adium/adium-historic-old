//
//  AIFlexibleTableFramedTextCell.m
//  Adium
//
//  Created by Adam Iser on Tue Sep 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableFramedTextCell.h"

#define FRAME_PAD_LEFT 		7
#define FRAME_PAD_RIGHT 	5
#define FRAME_PAD_TOP 		2
#define FRAME_PAD_BOTTOM 	1
#define FRAME_RADIUS		8
#define ALIAS_SHIFT_X		0.5
#define ALIAS_SHIFT_Y		0.5

@implementation AIFlexibleTableFramedTextCell

//init
- (id)init
{
    [super init];

    borderColor = nil;
    bubbleColor = nil;
    
    return(self);
}

//dealloc
- (void)dealloc
{
    [borderColor release];
    [bubbleColor release];
    
    [super dealloc];
}

//
- (void)setDrawTop:(BOOL)inDrawTop
{
    drawTop = inDrawTop;
}

//
- (void)setDrawBottom:(BOOL)inDrawBottom
{
    drawBottom = inDrawBottom;
}

//
- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor borderColor:(NSColor *)inBorderColor
{
    if(borderColor != inBorderColor){
        [borderColor release];
        borderColor = [inBorderColor retain];
    }
    if(bubbleColor != inBubbleColor){
        [bubbleColor release];
        bubbleColor = [inBubbleColor retain];
    }
}

//Adjust for our padding
- (int)sizeContentForWidth:(float)inWidth
{
    inWidth -= (FRAME_PAD_LEFT + FRAME_PAD_RIGHT);
    int newHeight = [super sizeContentForWidth:inWidth] + (FRAME_PAD_TOP + FRAME_PAD_BOTTOM);

    if(drawBottom && drawTop && newHeight < (FRAME_RADIUS * 2)){
        newHeight = (FRAME_RADIUS * 2);
    }
    
    return([super sizeContentForWidth:inWidth] + (FRAME_PAD_TOP + FRAME_PAD_BOTTOM));
}

//Adjust for our padding
- (void)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    offset.x += FRAME_PAD_LEFT;
    offset.y += FRAME_PAD_BOTTOM;

    [super resetCursorRectsAtOffset:offset visibleRect:visibleRect inView:controlView];
}

//Adjust for our padding
- (BOOL)handleMouseDownEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    inPoint.x -= FRAME_PAD_LEFT;
    inPoint.y -= FRAME_PAD_BOTTOM;
    inOffset.x += FRAME_PAD_LEFT;
    inOffset.y += FRAME_PAD_BOTTOM;

    return([super handleMouseDownEvent:theEvent atPoint:inPoint offset:inOffset]);
}

//Adjust for our padding
- (BOOL)pointIsSelected:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    inPoint.x -= FRAME_PAD_LEFT;
    inPoint.y -= FRAME_PAD_BOTTOM;
    inOffset.x += FRAME_PAD_LEFT;
    inOffset.y += FRAME_PAD_BOTTOM;

    return([super pointIsSelected:inPoint offset:inOffset]);
}

//Change this cell's selection
- (void)selectContentFrom:(NSPoint)source to:(NSPoint)dest offset:(NSPoint)inOffset mode:(int)selectMode
{
    source.x -= FRAME_PAD_LEFT;
    source.y -= FRAME_PAD_BOTTOM;
    dest.x -= FRAME_PAD_LEFT;
    dest.y -= FRAME_PAD_BOTTOM;
    inOffset.x += FRAME_PAD_LEFT;
    inOffset.y += FRAME_PAD_BOTTOM;

    return([super selectContentFrom:source to:dest offset:inOffset mode:selectMode]);
}
    
//Draw our contents
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSAffineTransform	*aliasShift;
    NSPoint 		topLeft, topRight, bottomLeft, bottomRight;

    //Set up a shift transformation to align our lines to a pixel (and prevent anti-aliasing)
    aliasShift = [NSAffineTransform transform];
    [aliasShift translateXBy:ALIAS_SHIFT_X yBy:ALIAS_SHIFT_Y];

    //Precalculate the basic 4 corners
    topLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y);
    topRight = NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y);
    bottomLeft = NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height);
    bottomRight = NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + cellFrame.size.height);
    
    if(drawTop){
        NSBezierPath	*path = [NSBezierPath bezierPath];

        [path appendBezierPathWithArcWithCenter:NSMakePoint(topLeft.x + FRAME_RADIUS, topLeft.y + FRAME_RADIUS)
                                         radius:FRAME_RADIUS
                                     startAngle:180
                                       endAngle:270
                                      clockwise:NO];
        [path lineToPoint:NSMakePoint(topRight.x - FRAME_RADIUS, topRight.y)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(topRight.x - FRAME_RADIUS, topRight.y + FRAME_RADIUS)
                                         radius:FRAME_RADIUS
                                     startAngle:270
                                       endAngle:0
                                      clockwise:NO];

        [bubbleColor set];
        [path fill];
        [path transformUsingAffineTransform:aliasShift];
        if(borderColor){
            [borderColor set];
            [path stroke];
        }
    }

    [bubbleColor set];
    [NSBezierPath fillRect:NSMakeRect(topLeft.x,
                                      (drawTop ? topLeft.y + FRAME_RADIUS : topLeft.y),
                                      bottomRight.x - topLeft.x,
                                      bottomRight.y - topLeft.y - (drawTop ? FRAME_RADIUS : 0) - (drawBottom ? FRAME_RADIUS : 0))];

    if(borderColor){
        [borderColor set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(topLeft.x + ALIAS_SHIFT_X, (drawTop ? topLeft.y + FRAME_RADIUS : topLeft.y) + ALIAS_SHIFT_Y)
                                toPoint:NSMakePoint(bottomLeft.x + ALIAS_SHIFT_X, (drawBottom ? bottomLeft.y - FRAME_RADIUS : bottomLeft.y) + ALIAS_SHIFT_Y)];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(topRight.x + ALIAS_SHIFT_X, (drawTop ? topRight.y + FRAME_RADIUS : topRight.y) + ALIAS_SHIFT_Y)
                                toPoint:NSMakePoint(bottomRight.x + ALIAS_SHIFT_X, (drawBottom ? bottomRight.y - FRAME_RADIUS : bottomRight.y) + ALIAS_SHIFT_Y)];
    }
    
    if(drawBottom){
        NSBezierPath	*path = [NSBezierPath bezierPath];

        [path appendBezierPathWithArcWithCenter:NSMakePoint(bottomLeft.x + FRAME_RADIUS, bottomLeft.y - FRAME_RADIUS)
                                         radius:FRAME_RADIUS
                                     startAngle:180
                                       endAngle:90
                                      clockwise:YES];
        [path lineToPoint:NSMakePoint(bottomRight.x - FRAME_RADIUS, bottomRight.y)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(bottomRight.x - FRAME_RADIUS, bottomRight.y - FRAME_RADIUS)
                                         radius:FRAME_RADIUS
                                     startAngle:90
                                       endAngle:0
                                      clockwise:YES];

        [bubbleColor set];
        [path fill];
        [path transformUsingAffineTransform:aliasShift];
        if(borderColor){
            [borderColor set];
            [path stroke];
        }
    }

    cellFrame.origin.x += FRAME_PAD_LEFT;
    cellFrame.size.width -= FRAME_PAD_LEFT + FRAME_PAD_RIGHT;
    if(drawTop) cellFrame.origin.y += FRAME_PAD_TOP;
    cellFrame.size.height -= ((drawTop ? FRAME_PAD_TOP : 0) + (drawBottom ? FRAME_PAD_BOTTOM : 0));

    [super drawContentsWithFrame:cellFrame inView:controlView];
}

@end

