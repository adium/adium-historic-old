//
//  AIListGroupBubbleCell.m
//  Adium
//
//  Created by Adam Iser on 8/12/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupBubbleCell.h"

#define EDGE_INDENT 			4

@implementation AIListGroupBubbleCell

- (id)init
{
	[super init];
	
	outlineBubble = NO;
	outlineBubbleLineWidth = 1.0;
	drawBubble = YES;
	
	return(self);
}
//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Give ourselves extra padding to compensate for the rounded bubble
- (int)leftPadding{
	return([super leftPadding] + EDGE_INDENT);
}
- (int)rightPadding{
	return([super rightPadding] + EDGE_INDENT);
}

//Draw a regular bubble background for our cell if gradient background drawing is disabled
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if (drawBubble){
		if(drawsBackground){
			[super drawBackgroundWithFrame:[self bubbleRectForFrame:rect]];
		}else{
			if(![self cellIsSelected]){
				NSBezierPath	*bezierPath;
				
				[[self backgroundColor] set];
				bezierPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];
				
				[bezierPath fill];
				
				if(outlineBubble){
					[bezierPath setLineWidth:outlineBubbleLineWidth];
					[[self textColor] set];
					[bezierPath stroke];
				}
			}
		}
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if([self cellIsSelected]){
		AIGradient	*gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:cellFrame]]];
	}
}

//Draw our background gradient bubble
- (void)drawBackgroundGradientInRect:(NSRect)inRect
{
	if (drawBubble){
		NSBezierPath	*bezierPath;
		
		bezierPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:inRect]];
		[[self backgroundGradient] drawInBezierPath:bezierPath];
		
		if(outlineBubble){
			[bezierPath setLineWidth:outlineBubbleLineWidth];
			[[self textColor] set];
			[bezierPath stroke];
		}
	}
}


//Pass drawing rects through this method before drawing a bubble.  This allows us to make adjustments to bubble
//positioning and size.
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	return(rect);
}

//Because of the rounded corners, we cannot rely on the outline view to draw our grid.  Return NO here to let
//the outline view know we'll be drawing the grid ourself
- (BOOL)drawGridBehindCell
{
	return(NO);
}

- (void)setOutlineBubble:(BOOL)flag
{
	outlineBubble = flag;
}
- (void)setOutlineBubbleLineWidth:(float)inWidth
{
	outlineBubbleLineWidth = inWidth;
}

- (void)setHideBubble:(BOOL)flag
{
	drawBubble = !(flag);
}

@end
