//
//  AIListContactMockieCell.m
//  Adium
//
//  Created by Adam Iser on Sun Aug 01 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIListContactMockieCell.h"
#import "AIListGroupMockieCell.h"
#import "AIListOutlineView.h"

@implementation AIListContactMockieCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	id newCell = [super copyWithZone:zone];
	return(newCell);
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	int		row = [controlView rowForItem:listObject];
	NSColor	*labelColor;
	
	//Label color.  If there is no label color we draw the background color (taking care of gridding if needed)
	//We cannot use the regular table background drawing for mockie cells because of the rounded corners
	//at the top and bottom of the groups.
	labelColor = [self labelColor];
	if(!labelColor) labelColor = (drawGrid ? [controlView backgroundColorForRow:row] : [controlView backgroundColor]);
	[labelColor set];

	//Draw the bottom corners rounded if this is the last cell in a group
	if(row >= [controlView numberOfRows]-1 || [controlView isExpandable:[controlView itemAtRow:row+1]]){
		[[NSBezierPath bezierPathWithRoundedBottomCorners:rect radius:MOCKIE_RADIUS] fill];
	}else{
		[NSBezierPath fillRect:rect];
	}
}

//No need to the grid if we have a status color to draw
- (BOOL)drawGridBehindCell
{
	return(NO);
}

//
- (void)setDrawsGrid:(BOOL)inValue
{
	drawGrid = inValue;
}

@end
