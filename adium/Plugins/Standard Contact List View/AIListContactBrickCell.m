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

//No need to the grid if we have a status color to draw
- (BOOL)drawGridBehindCell
{
	return([self labelColor] == nil);
}

//Default to more edge padding
- (int)topPadding{
	return([super topPadding] + 2);
}
- (int)bottomPadding{
	return([super bottomPadding] + 2);
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSColor	*labelColor = [self labelColor];
	if(labelColor){
		[labelColor set];
		[NSBezierPath fillRect:rect];
	}
}

@end
