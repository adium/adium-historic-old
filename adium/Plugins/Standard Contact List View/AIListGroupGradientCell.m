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
	[[self backgroundGradient] drawInRect:rect];
}

//Gradient (caaache me)
- (AIGradient *)backgroundGradient
{
	return([AIGradient gradientWithFirstColor:[NSColor colorWithCalibratedRed:0.542 green:0.726 blue:1.0 alpha:1.0]
								  secondColor:[NSColor colorWithCalibratedRed:0.416 green:0.660 blue:1.0 alpha:1.0]
									direction:AIVertical]);
}

//Shadow our text to make it prettier
- (NSDictionary *)displayNameAttributes
{
	NSShadow	*shadow = [[[NSShadow alloc] init] autorelease];
	
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow setShadowBlurRadius:2.0];
	[shadow setShadowColor:[NSColor grayColor]];
	
	return([NSDictionary dictionaryWithObject:shadow forKey:NSShadowAttributeName]);
}

@end
