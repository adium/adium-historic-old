//
//  AIListContactBrickCell.m
//  Adium
//
//  Created by Adam Iser on Fri Jul 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactBrickCell.h"
#import "AIListGroupMockieCell.h"

@implementation AIListContactBrickCell

//
#warning hmm
- (int)topPadding{
	return([super topPadding] + 2);
}
- (int)bottomPadding{
	return([super bottomPadding] + 2);
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	[[self labelColor] set];
	[NSBezierPath fillRect:rect];
}

@end
