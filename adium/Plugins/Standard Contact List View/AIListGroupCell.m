//
//  AIListGroupCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupCell.h"


@implementation AIListGroupCell

- (NSSize)cellSize
{
	return(NSMakeSize(0, 20));
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect inView:(NSView *)controlView
{
	//Draw flippy
	[[NSColor whiteColor] set];
	
	NSBezierPath	*arrowPath = [NSBezierPath bezierPath];
	[arrowPath moveToPoint:NSMakePoint(rect.origin.x + 8, rect.origin.y + (rect.size.height/2.0) - rect.size.height*.3)];
	[arrowPath relativeLineToPoint:NSMakePoint( 0, rect.size.height*.6)];
	[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.4, -rect.size.height*.3)];
	[arrowPath closePath];
	[arrowPath fill];

	rect.origin.x += 16;
	rect.size.width -= 16;
	
	
	[self drawDisplayNameWithFrame:rect inView:controlView];
}




//Flippy Drawing


//



@end
