//
//  AIListGroupCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupCell.h"

#define FLIPPY_TEXT_PADDING		3

@implementation AIListGroupCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Padding.  Gives our cell a bit of edge padding so the user icon and name do not touch the sides
- (int)topPadding{
	return([super topPadding] + 1);
}
- (int)bottomPadding{
	return([super bottomPadding] + 1);
}
- (int)leftPadding{
	return([super leftPadding] + 2);
}
- (int)rightPadding{
	return([super rightPadding] + 4);
}

- (NSSize)cellSize
{
	NSSize	size = [super cellSize];

	return(NSMakeSize(0, [[self font] defaultLineHeightForFont] + size.height));
}

- (int)cellWidth
{
	NSAttributedString	*displayName = [[NSAttributedString alloc] initWithString:[self labelString]
																	   attributes:[self labelAttributes]];
	return([super cellWidth] + [self flippyIndent] + [displayName size].width + 1);
}

- (NSColor *)flippyColor
{
	return([self textColor]);
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	//Draw flippy
	[[self flippyColor] set];
	
	NSBezierPath	*arrowPath = [NSBezierPath bezierPath];
	NSPoint			center = NSMakePoint(rect.origin.x + rect.size.height*.4, rect.origin.y + (rect.size.height/2.0));

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

	if([self textAlignment] != NSCenterTextAlignment){
		rect.origin.x += rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
		rect.size.width -= rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
	}

	[self drawDisplayNameWithFrame:rect];
}

- (int)flippyIndent
{
	if([self textAlignment] != NSCenterTextAlignment){
		NSSize size = [self cellSize];
		return(size.height*.4 + size.height*.2 + FLIPPY_TEXT_PADDING);
	}else{
		return(0);
	}
}

@end
