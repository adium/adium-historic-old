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

//Give ourselves more padding
- (int)leftPadding{
	return([super leftPadding] + EDGE_INDENT);
}
- (int)rightPadding{
	return([super rightPadding] + EDGE_INDENT);
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if(![self isSelectionInverted]){
		NSColor	*labelColor = [self labelColor];

		if(labelColor){
			//Retrieve the label and shift it into position
			NSBezierPath *pillPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];
			
			//Fill the label
			[labelColor set];
			[pillPath fill];
		}
	}
}

//Contact label color
- (NSColor *)labelColor
{
	NSColor	*labelColor = [super labelColor];
	return(labelColor ? labelColor : [controlView backgroundColor]);
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if([self isSelectionInverted]){
		AIGradient 	*gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		NSRect 		rect = [self bubbleRectForFrame:cellFrame];
		
		[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:rect]];
	}
}
	
//
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	return(rect);
}

@end
