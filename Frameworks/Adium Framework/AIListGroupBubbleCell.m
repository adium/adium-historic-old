/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIListGroupBubbleCell.h"
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIGradient.h>
#import <AIUtilities/AIColorAdditions.h>

#define EDGE_INDENT 			4

@implementation AIListGroupBubbleCell

- (id)init
{
	if ((self = [super init]))
	{
		outlineBubble = NO;
		outlineBubbleLineWidth = 1.0;
		drawBubble = YES;
	}
	
	return self;
}

//Give ourselves extra padding to compensate for the rounded bubble
- (int)leftPadding{
	return [super leftPadding] + EDGE_INDENT;
}
- (int)rightPadding{
	return [super rightPadding] + EDGE_INDENT;
}

//Draw a regular bubble background for our cell if gradient background drawing is disabled
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if (drawBubble) {
		if (drawsBackground) {
			[super drawBackgroundWithFrame:[self bubbleRectForFrame:rect]];
		} else {
			if (![self cellIsSelected]) {
				NSBezierPath	*bezierPath;
				
				[[self backgroundColor] set];
				bezierPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:rect]];
				
				[bezierPath fill];
				
				if (outlineBubble) {
					[bezierPath setLineWidth:outlineBubbleLineWidth];
					[[self textColor] set];
					[bezierPath stroke];
				}
			}
		}
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if ([self cellIsSelected]) {
		NSColor *highlightColor = [controlView highlightColor];
		AIGradient 	*gradient = (highlightColor ?
								 [AIGradient gradientWithFirstColor:highlightColor
														secondColor:[highlightColor darkenAndAdjustSaturationBy:0.4] 
														  direction:AIVertical] :
								 [AIGradient selectedControlGradientWithDirection:AIVertical]);
		[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:cellFrame]]];
	}
}

//Draw our background gradient bubble
- (void)drawBackgroundGradientInRect:(NSRect)inRect
{
	if (drawBubble) {
		NSBezierPath	*bezierPath;
		
		bezierPath = [NSBezierPath bezierPathWithRoundedRect:[self bubbleRectForFrame:inRect]];
		[[self backgroundGradient] drawInBezierPath:bezierPath];
		
		if (outlineBubble) {
			[bezierPath setLineWidth:outlineBubbleLineWidth];
			[[self textColor] set];
			[bezierPath stroke];
		}
	}
}


//Pass drawing rects through this method before drawing a bubble.  This allows us to make adjustments to bubble
//positioning and size.
- (NSRect)bubbleRectForFrame:(NSRect)rect
{
	return rect;
}

//Because of the rounded corners, we cannot rely on the outline view to draw our grid.  Return NO here to let
//the outline view know we'll be drawing the grid ourself
- (BOOL)drawGridBehindCell
{
	return NO;
}

- (void)setOutlineBubble:(BOOL)flag
{
	outlineBubble = flag;
}
- (void)setOutlineBubbleLineWidth:(float)inWidth
{
	outlineBubbleLineWidth = inWidth;
}

- (void)setHideBubble:(BOOL)flag
{
	drawBubble = !(flag);
}

@end
