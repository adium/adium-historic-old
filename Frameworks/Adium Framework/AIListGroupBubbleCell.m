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
	[[self backgroundGradient] drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]]];
}

//
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	return(rect);
}

@end
