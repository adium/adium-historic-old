//
//  AIGradientCell.m
//  Adium XCode
//
//  Created by Chris Serino on Wed Jan 28 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIGradientCell.h"


@implementation AIGradientCell

- (id)init
{
	if (self = [super init]) {
		drawsGradient = NO;
	}
	return self;
}

- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient
{
	drawsGradient = inDrawsGradient;
}

- (BOOL)drawsGradientHighlight
{
	return drawsGradient;
}

- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([self drawsGradientHighlight]) {
		NSColor *highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
		AIGradient *gradient;
		if ([highlightColor isEqual:[NSColor alternateSelectedControlColor]])
			gradient = [AIGradient gradientWithFirstColor:[highlightColor darkenAndAdjustSaturationBy:-0.1] secondColor:[highlightColor darkenAndAdjustSaturationBy:0.1] direction:AIVertical];
		else
			gradient = [AIGradient gradientWithFirstColor:highlightColor secondColor:[highlightColor darkenAndAdjustSaturationBy:0.2] direction:AIVertical];
		[gradient drawInRect:cellFrame];
	} else {
		[(id)super _drawHighlightWithFrame:cellFrame inView:controlView]; 
	}
}

@end
