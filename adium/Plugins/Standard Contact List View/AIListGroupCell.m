//
//  AIListGroupCell.m
//  Adium
//
//  Created by Adam Iser on Tue Jul 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListGroupCell.h"

#define FLIPPY_TEXT_PADDING		3
#define GROUP_FONT_SIZE			11

#define GROUP_TEXT_ALIGN		NSCenterTextAlignment// NSLeftTextAlignment //NSCenterTextAlignment

@implementation AIListGroupCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListGroupCell	*newCell = [[AIListGroupCell alloc] init];
	[newCell setListObject:listObject];
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
		rect.origin.x += rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
		rect.size.width -= rect.size.height*.4 + rect.size.height*.2 + FLIPPY_TEXT_PADDING;
	}

	[self drawDisplayNameWithFrame:rect];
}

//Draw our display name
//- (NSRect)drawDisplayNameWithFrame:(NSRect)rect
//{	
//	rect = [super drawDisplayNameWithFrame:rect];
//	
//	rect.origin.y -= 1;
//	
//	[textStorage setAttributedString:[self displayNameStringWithAttributes:YES color:[self greenColor]]];
//	NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
//	NSRect	glyphRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
//	[layoutManager drawGlyphsForGlyphRange:glyphRange
//								   atPoint:NSMakePoint(rect.origin.x,
//													   rect.origin.y + (rect.size.height - glyphRect.size.height) / 2.0)];
//	return(rect);
//}


@end
