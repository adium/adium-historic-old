//
//  AIGradientImageCell.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 3/12/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AIGradientImageCell.h"
#import "AIGradient.h"

@implementation AIGradientImageCell
- (id)init
{
	if((self = [super init])) {
		drawsGradient = NO;
		ignoresFocus = NO;
	}
	
	return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	[newCell setDrawsGradientHighlight:drawsGradient];
	[newCell setIgnoresFocus:ignoresFocus];
	
	return(newCell);
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

//Draw with the selected-control colours.
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSLog(@"%i: %@",[self drawsGradientHighlight],NSStringFromRect(cellFrame));
	if([self drawsGradientHighlight]){
		//Draw the gradient
		AIGradient *gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		[gradient drawInRect:cellFrame];
		
		//Draw a line at the light side, to make it look a lot cleaner
		cellFrame.size.height = 1;
		[[NSColor alternateSelectedControlColor] set];
		NSRectFillUsingOperation(cellFrame,NSCompositeSourceOver);
		
	}else{
		//Draw the regular selection, ignoring focus if desired
		if(ignoresFocus){
			[[NSColor alternateSelectedControlColor] set];
			NSRectFillUsingOperation(cellFrame,NSCompositeSourceOver);
		}else{
			[(id)super _drawHighlightWithFrame:cellFrame inView:controlView]; 
		}
	}
	
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage	*img = [self image];
	
	if(img){
		//Handle flipped axis
		[img setFlipped:![img isFlipped]];
		
		//Size and location
		//Get image metrics
		NSSize	imgSize = [img size];
		NSRect	imgRect = NSMakeRect(0, 0, imgSize.width, imgSize.height);
		
		//Scaling
		NSRect	targetRect = cellFrame;
		if ((imgSize.height > cellFrame.size.height) ||
			(imgSize.width  >  cellFrame.size.width)) {
			
			if ((imgSize.height / cellFrame.size.height) >
				(imgSize.width / cellFrame.size.width)) {
				targetRect.size.width  = roundf(imgSize.width  / (imgSize.height / cellFrame.size.height));
			} else {
				targetRect.size.height = roundf(imgSize.height / (imgSize.width  / cellFrame.size.width));
			}
			
		}else{
			targetRect.size.width = imgSize.width;
			targetRect.size.height = imgSize.height;
		}
		
		//Centering
		targetRect = NSOffsetRect(targetRect, round((cellFrame.size.width - targetRect.size.width) / 2), round((cellFrame.size.height - targetRect.size.height) / 2));
		
		//Draw Image
		[img drawInRect:targetRect
			   fromRect:imgRect
			  operation:NSCompositeSourceOver 
			   fraction:([self isEnabled] ? 1.0 : 0.5)];
		
		//Clean-up
		[img setFlipped:![img isFlipped]];
	}
}

//Super doesn't appear to handle the isHighlighted flag correctly, so we handle it to be safe.
- (void)setHighlighted:(BOOL)flag
{
	[self setState:(flag ? NSOnState : NSOffState)];
	isHighlighted = flag;
}
- (BOOL)isHighlighted
{
	return isHighlighted;
}


@end
