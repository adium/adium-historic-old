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

#import "AIFlexibleTableFramedTextCell.h"

//Default Padding
#define FRAME_PAD_LEFT 		7
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
- (void)_updateColorsWithAlpha;
@end

@implementation AIFlexibleTableFramedTextCell

//Create a new framed cell
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
    framePadLeft = FRAME_PAD_LEFT;
    framePadRight = FRAME_PAD_RIGHT;
    framePadTop = FRAME_PAD_TOP;
    framePadBottom = FRAME_PAD_BOTTOM;
    
    return(self);
}

//init
- (id)initWithAttributedString:(NSAttributedString *)inString
{
    drawTopDivider = NO;    
    [self setDrawSides:NO];

    [super initWithAttributedString:inString];
    return self;
}

//dealloc
- (void)dealloc
{
    [borderColor release];
    [bubbleColor release];
    [dividerColor release];
    [borderColorOpaque release];
    [bubbleColorOpaque release];
    [dividerColorOpaque release];
	
    [super dealloc];
}

//Set the internal padding
- (void)setInternalPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom
{
    framePadLeft = inLeft;
    framePadRight = inRight;
    framePadTop = inTop;
    framePadBottom = inBottom;
}

//Toggle display of the top border
- (void)setDrawTop:(BOOL)inDrawTop
{
    drawTop = inDrawTop;
}

//Toggle display of the top divider line
- (void)setDrawTopDivider:(BOOL)inDrawTopDivider
{
    drawTopDivider = inDrawTopDivider;
}

//Toggle display of the bottom border
- (void)setDrawBottom:(BOOL)inDrawBottom
{
    drawBottom = inDrawBottom;
}

//Toggle display of the side borders
- (void)setDrawSides:(BOOL)inDrawSides
{
    drawSides = inDrawSides;
}   

//Set the frame, border, and divider colors
- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor borderColor:(NSColor *)inBorderColor dividerColor:(NSColor *)inDividerColor
{
    if(borderColorOpaque != inBorderColor){
        [borderColorOpaque release];
        borderColorOpaque = [inBorderColor retain];
    }
    if(bubbleColorOpaque != inBubbleColor){
        [bubbleColorOpaque release];
        bubbleColorOpaque = [inBubbleColor retain];
    }
    if(dividerColorOpaque != inDividerColor){
        [dividerColorOpaque release];
        dividerColorOpaque = [inDividerColor retain];
    }
    [self _updateColorsWithAlpha];
}

- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor
{
	if(bubbleColorOpaque != inBubbleColor){
        [bubbleColorOpaque release];
        bubbleColorOpaque = [inBubbleColor retain];
		
		[bubbleColor release];
		bubbleColor = [[bubbleColorOpaque colorWithAlphaComponent:opacity] retain];
    }
}

- (NSColor *)contentBackgroundColor
{
	return bubbleColor;
}

- (void)setOpacity:(float)inOpacity
{
    //Update the opacity
    [super setOpacity:inOpacity];
    //Now update our cached transparent colors
    [self _updateColorsWithAlpha];
}

- (void)_updateColorsWithAlpha
{
    [borderColor release];
    borderColor = [[borderColorOpaque colorWithAlphaComponent:opacity] retain];
    
    [bubbleColor release];
    bubbleColor = [[bubbleColorOpaque colorWithAlphaComponent:opacity] retain];

    [dividerColor release];
    dividerColor = [[dividerColorOpaque colorWithAlphaComponent:opacity] retain];
}

//Adjust for our padding
- (int)sizeContentForWidth:(float)inWidth
{
    inWidth -= (framePadLeft + framePadRight);
    int newHeight = [super sizeContentForWidth:inWidth] + (framePadTop + framePadBottom);

    if(drawBottom) newHeight++; //Give ourselves another pixel for the bottom border
    
    if(drawBottom && drawTop && newHeight < (FRAME_RADIUS * 2)){
        newHeight = (FRAME_RADIUS * 2);
    }
    
    return([super sizeContentForWidth:inWidth] + (framePadTop + framePadBottom));
}

//Adjust for our padding
- (BOOL)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView
{
    offset.x += framePadLeft;
    offset.y += framePadBottom;

    return([super resetCursorRectsAtOffset:offset visibleRect:visibleRect inView:controlView]);
}

//Adjust for our padding
- (BOOL)handleMouseDownEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    inPoint.x -= framePadLeft;
    inPoint.y -= framePadBottom;
    inOffset.x += framePadLeft;
    inOffset.y += framePadBottom;

    return([super handleMouseDownEvent:theEvent atPoint:inPoint offset:inOffset]);
}

//Adjust for our padding
- (NSArray *)menuItemsForEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    inPoint.x -= framePadLeft;
    inPoint.y -= framePadBottom;
    inOffset.x += framePadLeft;
    inOffset.y += framePadBottom;
    
    return([super menuItemsForEvent:theEvent atPoint:inPoint offset:inOffset]);
}

//Adjust for our padding
- (BOOL)pointIsSelected:(NSPoint)inPoint offset:(NSPoint)inOffset
{
    inPoint.x -= framePadLeft;
    inPoint.y -= framePadBottom;
    inOffset.x += framePadLeft;
    inOffset.y += framePadBottom;

    return([super pointIsSelected:inPoint offset:inOffset]);
}

//Change this cell's selection
- (void)selectContentFrom:(NSPoint)source to:(NSPoint)dest offset:(NSPoint)inOffset mode:(int)selectMode
{
    source.x -= framePadLeft;
    source.y -= framePadBottom;
    dest.x -= framePadLeft;
    dest.y -= framePadBottom;
    inOffset.x += framePadLeft;
    inOffset.y += framePadBottom;

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
    inFrame.origin.x += framePadLeft;
    inFrame.size.width -= framePadLeft + framePadRight;
    inFrame.origin.y += framePadTop;
    inFrame.size.height -= ((drawTop ? framePadTop : framePadTop) + (drawBottom ? framePadBottom : framePadBottom));

    [super drawContentsWithFrame:inFrame inView:controlView];
}

//Draw the top bubble separation divider
- (void)_drawBubbleDividerInRect:(NSRect)frame
{
    if(dividerColor){
        float dividerSpace = framePadLeft + 1;
        
        [dividerColor set];
        [NSBezierPath fillRect:NSMakeRect(frame.origin.x+dividerSpace,frame.origin.y,frame.size.width-dividerSpace,frame.size.height)];

        //fill the sides, where the line is not, with the bubble color
        [bubbleColor set];
        [NSBezierPath fillRect:NSMakeRect(frame.origin.x,frame.origin.y,dividerSpace,frame.size.height)];
        [NSBezierPath fillRect:NSMakeRect(frame.origin.x+frame.size.width-dividerSpace,frame.origin.y,dividerSpace,frame.size.height)];
        
    }
    
    if(borderColor && drawSides){        
        NSBezierPath        *path = [NSBezierPath bezierPath];
        NSAffineTransform	*aliasShift;
        
        //Set up a shift transformation to align our lines to a pixel (and prevent anti-aliasing)
        aliasShift = [NSAffineTransform transform];
        [aliasShift translateXBy:ALIAS_SHIFT_X yBy:0];
        
        //
        [path setLineWidth:1.0];
        
        [path moveToPoint:NSMakePoint(frame.origin.x, frame.origin.y)];
        [path lineToPoint:NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height )];
        [path moveToPoint:NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y)];
        [path lineToPoint:NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height)];
        
        [path transformUsingAffineTransform:aliasShift];
        [borderColor set];
        [path stroke];
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
            NSBezierPath        *path = [NSBezierPath bezierPath];
            NSAffineTransform	*aliasShift;
            
            //Set up a shift transformation to align our lines to a pixel (and prevent anti-aliasing)
            aliasShift = [NSAffineTransform transform];
            [aliasShift translateXBy:ALIAS_SHIFT_X yBy:0];
            
            //
            [path setLineWidth:1.0];
            
            [path moveToPoint:NSMakePoint(frame.origin.x, frame.origin.y)];
            [path lineToPoint:NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height)];
            [path moveToPoint:NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y)];
            [path lineToPoint:NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height)];
            
            [path transformUsingAffineTransform:aliasShift];
            [path stroke];
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

