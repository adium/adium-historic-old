//
//  AIListGroupCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupCell.h"

#define VERTICAL_GROUP_PADDING	2
#define GROUP_FONT_SIZE			11

#define GROUP_TEXT_ALIGN		NSCenterTextAlignment

//NSLeftTextAlignment		= 0, /* Visually left aligned */
//NSRightTextAlignment	= 1, /* Visually right aligned */
//NSCenterTextAlignment	= 2,



@implementation AIListGroupCell

- (NSSize)cellSize
{
	return(NSMakeSize(0, (int)[[self font] defaultLineHeightForFont] + (VERTICAL_GROUP_PADDING * 2)));
}

- (NSTextAlignment)textAlignment
{
	return(GROUP_TEXT_ALIGN);
}

- (NSColor *)flippyColor
{
	return([NSColor blackColor]);
}

- (NSFont *)font
{
	return([NSFont boldSystemFontOfSize:GROUP_FONT_SIZE]);
}

- (NSColor *)textColor
{
	return([NSColor blackColor]);
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
		rect.origin.x += rect.size.height*.4 + rect.size.height*.2;
		rect.size.width -= rect.size.height*.4 + rect.size.height*.2;
	}
		
	[self drawDisplayNameWithFrame:rect];
}




//Flippy Drawing


//



@end
