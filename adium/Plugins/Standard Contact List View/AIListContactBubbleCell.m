//
//  AIListContactBubbleCell.m
//  Adium
//
//  Created by Adam Iser on Thu Jul 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactBubbleCell.h"

#define EDGE_INDENT 			4

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
	if(!drewSelection){
		NSColor	*labelColor = [self labelColor];

		if(labelColor){
			//Retrieve the label and shift it into position
			NSBezierPath *pillPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];
			
			//Fill the label
			[labelColor set];
			[pillPath fill];
		}
		
	}else{
		drewSelection = NO;
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	[self drawBackgroundWithFrame:cellFrame];
	
	NSRect rect = [self bubbleRectForFrame:cellFrame];
	
	rect = NSInsetRect(rect,1,1);
	
	NSBezierPath *pillPath = [NSBezierPath bezierPathWithRoundedRect:rect];
	[pillPath setLineWidth:2.0];
	[[NSColor alternateSelectedControlColor] set];
	[pillPath stroke];
	
	drewSelection = YES;
}
	
//
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	return(rect);
}

@end
