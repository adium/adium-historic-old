//
//  AIListGroupBubbleToFitCell.m
//  Adium
//
//  Created by Adam Iser on 8/12/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupBubbleToFitCell.h"

@implementation AIListGroupBubbleToFitCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Adjust the bubble rect to tightly fit our label string
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	NSAttributedString	*displayName = [[NSAttributedString alloc] initWithString:[self labelString]
																	   attributes:[self labelAttributes]];
	
	rect.size.width = [displayName size].width + [self leftPadding] + [self rightPadding] + [self flippyIndent];
	return(rect);
}

@end
