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

//
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
#warning need a real fix here
	rect.size.width = [[self displayNameStringWithAttributes:NO] size].width;
	return(rect);
}

@end
