//
//  AIListGroupGradientCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupGradientCell.h"


@implementation AIListGroupGradientCell

//Draw a gradient behind our group
- (void)drawBackgroundWithFrame:(NSRect)rect inView:(NSView *)controlView
{
	AIGradient	*gradient = [AIGradient gradientWithFirstColor:[NSColor colorWithCalibratedRed:0.542 green:0.726 blue:1.0 alpha:1.0]
												   secondColor:[NSColor colorWithCalibratedRed:0.416 green:0.660 blue:1.0 alpha:1.0]
													 direction:AIVertical];
	[gradient drawInRect:rect];
}


@end
