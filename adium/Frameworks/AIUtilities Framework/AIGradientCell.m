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
	[super init];
	
	drawsGradient = NO;
	ignoresFocus = NO;

	return self;
}

//Draw Gradient
- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient{
	drawsGradient = inDrawsGradient;
}
- (BOOL)drawsGradientHighlight{
	return(drawsGradient);
}

//Ignore focus (Draw as active regardless of focus)
- (void)setIgnoresFocus:(BOOL)inIgnoresFocus{
	ignoresFocus = inIgnoresFocus;
}
- (BOOL)ignoresFocus{
	return(ignoresFocus);
}

//Draw
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect goodRect = cellFrame;
	goodRect.size.height += 2;
	goodRect.size.width += 4;
	goodRect.origin.x -= 2;
	goodRect.origin.y -= 1;

	if([self drawsGradientHighlight]){
		//Draw the gradient
		AIGradient *gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		[gradient drawInRect:goodRect];
	
		//Draw a line at the light side, to make it look a lot cleaner
		goodRect.size.height = 1;
		[[NSColor alternateSelectedControlColor] set];
		NSRectFillUsingOperation(goodRect,NSCompositeSourceOver);
		
	}else{
		//Draw the regular selection, ignoring focus if desired
		if(ignoresFocus){
			[[NSColor alternateSelectedControlColor] set];
			NSRectFillUsingOperation(goodRect,NSCompositeSourceOver);
		}else{
			[(id)super _drawHighlightWithFrame:cellFrame inView:controlView]; 
		}
	}
	
}

@end
