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
	if ((self = [super init])) {
		drawsGradient = NO;
		ignoresFocus = NO;
		maxSize = NSZeroSize;
	}
	
	return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	[newCell setDrawsGradientHighlight:drawsGradient];
	[newCell setIgnoresFocus:ignoresFocus];
	
	return newCell;
}

//Draw Gradient
- (void)setDrawsGradientHighlight:(BOOL)inDrawsGradient
{
	drawsGradient = inDrawsGradient;
}
- (BOOL)drawsGradientHighlight
{
	return drawsGradient;
}

//Ignore focus (Draw as active regardless of focus)
- (void)setIgnoresFocus:(BOOL)inIgnoresFocus
{
	ignoresFocus = inIgnoresFocus;
}
- (BOOL)ignoresFocus
{
	return ignoresFocus;
}

- (void)setMaxSize:(NSSize)inMaxSize
{
	maxSize = inMaxSize;
}

//Draw with the selected-control colours.
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([self drawsGradientHighlight]) {
		//Draw the gradient
		AIGradient *gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		[gradient drawInRect:cellFrame];
		
		//Draw a line at the light side, to make it look a lot cleaner
		cellFrame.size.height = 1;
		[[NSColor alternateSelectedControlColor] set];
		NSRectFillUsingOperation(cellFrame,NSCompositeSourceOver);
		
	} else {
		//Draw the regular selection, ignoring focus if desired
		if (ignoresFocus) {
			[[NSColor alternateSelectedControlColor] set];
			NSRectFillUsingOperation(cellFrame,NSCompositeSourceOver);
		} else {
			[(id)super _drawHighlightWithFrame:cellFrame inView:controlView]; 
		}
	}
	
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage	*img = [self image];
	
	if (img) {
		//Handle flipped axis
		[img setFlipped:![img isFlipped]];
		
		//Size and location
		//Get image metrics
		NSSize	imgSize = [img size];
		NSRect	imgRect = NSMakeRect(0, 0, imgSize.width, imgSize.height);
		
		//Scaling
		NSRect	targetRect = cellFrame;
		
		//Determine the correct maximum size, taking into account maxSize and our cellFrame.
		NSSize	ourMaxSize = cellFrame.size;
		if ((maxSize.width != 0) && (ourMaxSize.width > maxSize.width)) {
			ourMaxSize.width = maxSize.width;
		}
		if ((maxSize.height != 0) && (ourMaxSize.height > maxSize.height)) {
			ourMaxSize.height = maxSize.height;
		}

		if ((imgSize.height > ourMaxSize.height) ||
			(imgSize.width  >  ourMaxSize.width)) {
			
			if (imgSize.width > imgSize.height) {
				//Give width priority: Make the height change by the same proportion as the width will change
				targetRect.size.width = ourMaxSize.width;
				targetRect.size.height = imgSize.height * (targetRect.size.width / imgSize.width);
			} else {
				//Give height priority: Make the width change by the same proportion as the height will change
				targetRect.size.height = ourMaxSize.height;
				targetRect.size.width = imgSize.width * (targetRect.size.height / imgSize.height);
			}
		} else {
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
