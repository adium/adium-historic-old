//
//  AIFlexibleTableFramedTextCell.m
//  Adium
//
//  Created by Adam Iser on Tue Sep 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIFlexibleTableFramedTextCell.h"

#define FRAME_PAD_LEFT 		7
#define FRAME_FLAT_PAD_LEFT     10
#define FRAME_PAD_RIGHT 	5
#define FRAME_PAD_TOP 		2
#define FRAME_PAD_BOTTOM 	2
#define FRAME_RADIUS		8
#define FRAME_FLAT_HEIGHT	1
#define DIVIDER_FLAT_HEIGHT	1
#define ALIAS_SHIFT_X		0.5
#define ALIAS_SHIFT_Y		0.5

@interface AIFlexibleTableFramedTextCell (PRIVATE)
- (void)_drawBubbleTopInRect:(NSRect)frame;
- (void)_drawBubbleMiddleInRect:(NSRect)frame;
- (void)_drawBubbleBottomInRect:(NSRect)frame;
- (void)_drawFlatTopInRect:(NSRect)frame;
- (void)_drawFlatBottomInRect:(NSRect)frame;
- (void)_drawBubbleDividerInRect:(NSRect)frame;
@end

@implementation AIFlexibleTableFramedTextCell

+ (AIFlexibleTableFramedTextCell *)cellWithAttributedString:(NSAttributedString *)inString
{
    return([[[self alloc] initWithAttributedString:inString] autorelease]);
}

//init
- (id)init
{
    [super init];

    borderColor = nil;
    bubbleColor = nil;
    
    return(self);
}

- (id)initWithAttributedString:(NSAttributedString *)inString
{
    drawTopDivider = NO;
    drawSides = YES;    
    suppressTopLeftCorner = NO;
    suppressTopRightCorner = NO;
    suppressBottomRightCorner = NO;
    suppressBottomLeftCorner = NO;
    suppressTopBorder = NO;
    suppressBottomBorder = NO;

    [super initWithAttributedString:inString];
    return self;
}

//dealloc
- (void)dealloc
{
    [borderColor release];
    [bubbleColor release];
    [dividerColor release];
    
    [super dealloc];
}

//
- (void)setDrawTop:(BOOL)inDrawTop
{
    drawTop = inDrawTop;
}

//
- (void)setDrawTopDivider:(BOOL)inDrawTopDivider
{
    drawTopDivider = inDrawTopDivider;
}

//
- (void)setDrawBottom:(BOOL)inDrawBottom
{
    drawBottom = inDrawBottom;
}

- (void)setDrawSides:(BOOL)inDrawSides
{
    drawSides = inDrawSides;
}   

- (void)setSuppressTopRightCorner:(BOOL)inSuppressTopRightCorner
{
    suppressTopRightCorner = inSuppressTopRightCorner;
}

- (void)setSuppressTopLeftCorner:(BOOL)inSuppressTopLeftCorner
{
    suppressTopLeftCorner = inSuppressTopLeftCorner;
}

- (void)setSuppressBottomRightCorner:(BOOL)inSuppressBottomRightCorner
{
    suppressBottomRightCorner = inSuppressBottomRightCorner;
}

- (void)setSuppressBottomLeftCorner:(BOOL)inSuppressBottomLeftCorner
{
    suppressBottomLeftCorner = inSuppressBottomLeftCorner;
}

- (void)setSuppressTopBorder:(BOOL)inSuppressTopBorder
{
    suppressTopBorder = inSuppressTopBorder;
}

- (void)setSuppressBottomBorder:(BOOL)inSuppressBottomBorder
{
    suppressBottomBorder = inSuppressBottomBorder;
}

- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor borderColor:(NSColor *)inBorderColor dividerColor:(NSColor *)inDividerColor
{
    if(borderColor != inBorderColor){
        [borderColor release];
        borderColor = [inBorderColor retain];
    }
    if(bubbleColor != inBubbleColor){
        [bubbleColor release];
        bubbleColor = [inBubbleColor retain];
    }
    if(dividerColor != inDividerColor){
        [dividerColor release];
        dividerColor = [inDividerColor retain];
    }
}

//Adjust for our padding
- (int)sizeContentForWidth:(float)inWidth
{
    inWidth -= (FRAME_PAD_LEFT + FRAME_PAD_RIGHT);
    int newHeight = [super sizeContentForWidth:inWidth] + (FRAME_PAD_TOP + FRAME_PAD_BOTTOM);

    if(drawBottom) newHeight++; //Give ourselves another pixel for the bottom border
    
    if(drawBottom && drawTop && newHeight < (FRAME_RADIUS * 2)){
        newHeight = (FRAME_RADIUS * 2);
    }
    
    return([super sizeContentForWidth:inWidth] + (FRAME_PAD_TOP + FRAME_PAD_BOTTOM));
}

//Adjust for our padding
- (BOOL)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    offset.x += FRAME_PAD_LEFT;
    offset.y += FRAME_PAD_BOTTOM;

    return([super resetCursorRectsAtOffset:offset visibleRect:visibleRect inView:controlView]);
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

    [super selectContentFrom:source to:dest offset:inOffset mode:selectMode];
}
    
//Draw our contents
- (void)drawContentsWithFrame:(NSRect)inFrame inView:(NSView *)controlView
{
    NSAffineTransform	*aliasShift;
    NSRect              cellFrame = inFrame;

    //Set up a shift transformation to align our lines to a pixel (and prevent anti-aliasing)
    aliasShift = [NSAffineTransform transform];
    [aliasShift translateXBy:ALIAS_SHIFT_X yBy:ALIAS_SHIFT_Y];

    //Draw the top (bubble separation) divider
    if(drawTopDivider){
        [self _drawBubbleDividerInRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, DIVIDER_FLAT_HEIGHT)];
        cellFrame.origin.y += DIVIDER_FLAT_HEIGHT;
        cellFrame.size.height -= DIVIDER_FLAT_HEIGHT;
    }
    
    //Draw the bubble top and bottom
    if(drawSides){
        if(drawTop){
            [self _drawBubbleTopInRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, FRAME_RADIUS)];
            cellFrame.origin.y += FRAME_RADIUS;
            cellFrame.size.height -= FRAME_RADIUS;
        }
        
        if(drawBottom){
            [self _drawBubbleBottomInRect:NSMakeRect(cellFrame.origin.x, (cellFrame.origin.y + cellFrame.size.height) - FRAME_RADIUS - 1, cellFrame.size.width, FRAME_RADIUS)];
            cellFrame.size.height -= FRAME_RADIUS;
        }
        
    }else{
        if(drawTop){
            [self _drawFlatTopInRect:NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, FRAME_FLAT_HEIGHT)];
            cellFrame.origin.y += FRAME_FLAT_HEIGHT;
            cellFrame.size.height -= FRAME_FLAT_HEIGHT;
        }
        
        if(drawBottom){
            [self _drawFlatBottomInRect:NSMakeRect(cellFrame.origin.x, (cellFrame.origin.y + cellFrame.size.height) - FRAME_FLAT_HEIGHT, cellFrame.size.width, FRAME_FLAT_HEIGHT)];
            cellFrame.size.height -= FRAME_FLAT_HEIGHT;
        }

    }

    //Draw the bubble middle
    [self _drawBubbleMiddleInRect:cellFrame];
    
    //Draw our text content
    inFrame.origin.x += (drawSides ? FRAME_PAD_LEFT : FRAME_FLAT_PAD_LEFT);
    inFrame.size.width -= (drawSides ? FRAME_PAD_LEFT : FRAME_FLAT_PAD_LEFT) + FRAME_PAD_RIGHT;
    /*if(drawTop) */inFrame.origin.y += FRAME_PAD_TOP;
    inFrame.size.height -= ((drawTop ? FRAME_PAD_TOP : FRAME_PAD_TOP) + (drawBottom ? FRAME_PAD_BOTTOM : FRAME_PAD_BOTTOM));

    [super drawContentsWithFrame:inFrame inView:controlView];
}

//Draw the top bubble separation divider
- (void)_drawBubbleDividerInRect:(NSRect)frame
{
    if(dividerColor){
        [dividerColor set];
        [NSBezierPath fillRect:frame];
    }
    if(borderColor){
        [borderColor set];
        [NSBezierPath fillRect:NSMakeRect(frame.origin.x, frame.origin.y, 1, frame.size.height)];
        [NSBezierPath fillRect:NSMakeRect(frame.origin.x + frame.size.width, frame.origin.y, 1, frame.size.height)];
    }
}

//Draw the top border of a flat frame
- (void)_drawFlatTopInRect:(NSRect)frame
{
    if(borderColor){
        [borderColor set];
        [NSBezierPath fillRect:frame];
    }
}

//Draw the bottom border of a flat frame
- (void)_drawFlatBottomInRect:(NSRect)frame
{
    if(borderColor){
        [borderColor set];
        [NSBezierPath fillRect:frame];
    }
}

//Draw the top border of a rounded frame
- (void)_drawBubbleTopInRect:(NSRect)frame
{
    NSBezierPath        *path = [NSBezierPath bezierPath];
    NSAffineTransform	*aliasShift;
    int                 frameRadius = frame.size.height;
        
    //Set up a shift transformation to align our lines to a pixel (and prevent anti-aliasing)
    aliasShift = [NSAffineTransform transform];
    [aliasShift translateXBy:ALIAS_SHIFT_X yBy:ALIAS_SHIFT_Y];
    
    //
    [path setLineWidth:1.0];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(frame.origin.x + frameRadius, frame.origin.y + frameRadius)
                                     radius:frameRadius
                                 startAngle:180
                                   endAngle:270
                                  clockwise:NO];
    [path lineToPoint:NSMakePoint((frame.origin.x + frame.size.width) - frameRadius, frame.origin.y)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint((frame.origin.x + frame.size.width) - frameRadius, frame.origin.y + frameRadius)
                                     radius:frameRadius
                                 startAngle:270
                                   endAngle:0
                                  clockwise:NO];
    
    //
    [bubbleColor set];
    [path fill];
    [path transformUsingAffineTransform:aliasShift];
    if(borderColor){
        [borderColor set];
        [path stroke];
    }
}

//Draw the middle of a flat/rounded frame
- (void)_drawBubbleMiddleInRect:(NSRect)frame
{
    //Draw the middle of the bubble
    [bubbleColor set];
    [NSBezierPath fillRect:frame];

    //Draw the side borders along the middle
    if(borderColor){
        [borderColor set];
        if(drawSides){
            [NSBezierPath strokeLineFromPoint:NSMakePoint(frame.origin.x + ALIAS_SHIFT_X, frame.origin.y)
                                      toPoint:NSMakePoint(frame.origin.x + ALIAS_SHIFT_X, frame.origin.y + frame.size.height)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(frame.origin.x + frame.size.width + ALIAS_SHIFT_X, frame.origin.y)
                                      toPoint:NSMakePoint(frame.origin.x + frame.size.width + ALIAS_SHIFT_X, frame.origin.y + frame.size.height)];
        }
    }
}

//Draw the bottom border of a rounded frame
- (void)_drawBubbleBottomInRect:(NSRect)frame
{
    NSBezierPath        *path = [NSBezierPath bezierPath];
    NSAffineTransform	*aliasShift;
    int                 frameRadius = frame.size.height;    
    
    //Set up a shift transformation to align our lines to a pixel (and prevent anti-aliasing)
    aliasShift = [NSAffineTransform transform];
    [aliasShift translateXBy:ALIAS_SHIFT_X yBy:ALIAS_SHIFT_Y];
    
    //
    [path setLineWidth:1.0];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(frame.origin.x + frameRadius, frame.origin.y)
                                     radius:frameRadius
                                 startAngle:180
                                   endAngle:90
                                  clockwise:YES];
    [path lineToPoint:NSMakePoint((frame.origin.x + frame.size.width) - frameRadius, frame.origin.y + frameRadius)];
    [path appendBezierPathWithArcWithCenter:NSMakePoint((frame.origin.x + frame.size.width) - frameRadius, frame.origin.y)
                                     radius:frameRadius
                                 startAngle:90
                                   endAngle:0
                                  clockwise:YES];

    //
    [bubbleColor set];
    [path fill];
    [path transformUsingAffineTransform:aliasShift];
    if(borderColor){
        [borderColor set];
        [path stroke];
    }
}




@end

