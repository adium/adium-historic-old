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
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//
- (void)setBackgroundColor:(NSColor *)inBackgroundColor gradientColor:(NSColor *)inGradientColor
{
	if(inBackgroundColor != backgroundColor){
		[backgroundColor release];
		backgroundColor = [inBackgroundColor retain];
	}
	if(inGradientColor != gradientColor){
		[gradientColor release];
		gradientColor = [inGradientColor retain];
	}
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
	return([AIGradient gradientWithFirstColor:backgroundColor
								  secondColor:gradientColor
									direction:AIVertical]);
}

//Shadow our text to make it prettier
- (NSDictionary *)additionalLabelAttributes
{
	NSShadow	*shadow = [[[NSShadow alloc] init] autorelease];
	
	[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
	[shadow setShadowBlurRadius:2.0];
	[shadow setShadowColor:[NSColor grayColor]];
	
	return([NSDictionary dictionaryWithObject:shadow forKey:NSShadowAttributeName]);
}

@end
