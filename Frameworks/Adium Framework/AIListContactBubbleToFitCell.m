//
//  AIListContactBubbleToFitCell.m
//  Adium
//
//  Created by Adam Iser on Wed Aug 04 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactBubbleToFitCell.h"


@implementation AIListContactBubbleToFitCell

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

	rect.size.width = [displayName size].width + [self leftPadding] + [self rightPadding];
	return(rect);
}

@end
