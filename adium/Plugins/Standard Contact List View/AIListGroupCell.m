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

- (NSColor *)flippyColor
{
	return([NSColor blackColor]);
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect inView:(NSView *)controlView
{
	//Draw flippy
	[[self flippyColor] set];
	
	NSBezierPath	*arrowPath = [NSBezierPath bezierPath];
	NSPoint			center = NSMakePoint(rect.origin.x + 10, rect.origin.y + (rect.size.height/2.0));
	
	if([controlView isItemExpanded:listObject]){
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*.3, center.y - rect.size.height*.15)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.6, 0)];
		[arrowPath relativeLineToPoint:NSMakePoint(-rect.size.height*.3, rect.size.height*.4)];		
	}else{
		[arrowPath moveToPoint:NSMakePoint(center.x - rect.size.height*.2, center.y - rect.size.height*.3)];
		[arrowPath relativeLineToPoint:NSMakePoint( 0, rect.size.height*.6)];
		[arrowPath relativeLineToPoint:NSMakePoint( rect.size.height*.4, -rect.size.height*.3)];		
	}
		
	[arrowPath closePath];
	[arrowPath fill];

	rect.origin.x += rect.size.height*.7;
	rect.size.width -= rect.size.height*.7;
	
	
	[self drawDisplayNameWithFrame:rect inView:controlView];
}




//Flippy Drawing


//



@end
