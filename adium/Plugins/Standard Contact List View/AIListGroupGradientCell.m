//
//  AIListGroupGradientCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupGradientCell.h"


@implementation AIListGroupGradientCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListGroupGradientCell	*newCell = [[AIListGroupGradientCell alloc] init];
	[newCell setListObject:listObject];
	return(newCell);
}

//
- (NSColor *)flippyColor
{
	return([NSColor whiteColor]);
}

- (NSColor *)textColor
{
	return([NSColor whiteColor]);
}

//Draw a gradient behind our group
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	AIGradient	*gradient = [AIGradient gradientWithFirstColor:[NSColor colorWithCalibratedRed:0.542 green:0.726 blue:1.0 alpha:1.0]
												   secondColor:[NSColor colorWithCalibratedRed:0.416 green:0.660 blue:1.0 alpha:1.0]
													 direction:AIVertical];
	[gradient drawInRect:rect];
}


@end
