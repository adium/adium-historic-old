//
//  ESRankingCell.m
//  Adium
//
//  Created by Evan Schoenberg on 11/1/04.
//

#import "ESRankingCell.h"


@implementation ESRankingCell

static NSColor	*drawColor = nil;

-(void)setPercentage:(float)inPercentage
{
	percentage = inPercentage;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if(percentage != 0){
		//2 pixels left, 4 pixels right
		cellFrame.size.width -= 6;
		cellFrame.origin.x += 2;
		
		//3 pixels top, 3 pixels bottom
		cellFrame.size.height -= 6;
		cellFrame.origin.y += 3;
		
		//Draw in a horizontal area of cellFrame equal to (percentage) of it
		cellFrame.size.width *= percentage;
		
		if(!drawColor) drawColor = [[[NSColor alternateSelectedControlColor] darkenAndAdjustSaturationBy:0.2] retain];

		[drawColor set];
		[[NSBezierPath bezierPathWithRoundedRect:cellFrame radius:0] fill];
	}
}

@end
