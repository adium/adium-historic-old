//
//  AIGradientCell.m
//  Adium
//
//  Created by Chris Serino on Wed Jan 28 2004.
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
		AIGradient *gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		NSRect goodRect = cellFrame;
		goodRect.size.height += 2;
		goodRect.size.width += 4;
		goodRect.origin.x -= 2;
		goodRect.origin.y -= 1;

		/* The following code changes the color to gray if the view isn't key.
		 
		 NSColor *highlightColor = [self highlightColorWithFrame:cellFrame inView:controlView];
		AIGradient *gradient;
		if ([highlightColor isEqual:[NSColor alternateSelectedControlColor]])
			gradient = [AIGradient gradientWithFirstColor:[highlightColor darkenAndAdjustSaturationBy:-0.1] secondColor:[highlightColor darkenAndAdjustSaturationBy:0.1] direction:AIVertical];
		else
			gradient = [AIGradient gradientWithFirstColor:[highlightColor darkenAndAdjustSaturationBy:0.15] secondColor:[highlightColor darkenAndAdjustSaturationBy:0.4] direction:AIVertical];
		[gradient drawInRect:cellFrame];
		*/
		
		[gradient drawInRect:goodRect];
		goodRect.size.height = 1;
		[[NSColor alternateSelectedControlColor] set];
		NSRectFillUsingOperation(goodRect,NSCompositeSourceOver);
	} else {
		[(id)super _drawHighlightWithFrame:cellFrame inView:controlView]; 
	}
}

@end
