//
//  AIListContactBubbleCell.m
//  Adium
//
//  Created by Adam Iser on Thu Jul 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactBubbleCell.h"
#import "AIListOutlineView.h"

#define EDGE_INDENT 			4

@interface AIListContactBubbleCell (PRIVATE)

@end

@implementation AIListContactBubbleCell

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

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if(![self cellIsSelected]){
		int		row = [controlView rowForItem:listObject];
		NSColor	*labelColor;
		
		//Label color.  If there is no label color we draw the background color (taking care of gridding if needed)
		//We cannot use the regular table background drawing for bubble cells because of our rounded corners
		labelColor = [self labelColor];
		[(labelColor ? labelColor : [self backgroundColor]) set];
		
		//Draw our background with rounded corners
		[[NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]] fill];
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if([self cellIsSelected]){
		AIGradient 	*gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		NSRect 		rect = [self bubbleRectForFrame:cellFrame];
		
		//Draw our bubble with the selected control gradient
		[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:rect]];
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

@end
