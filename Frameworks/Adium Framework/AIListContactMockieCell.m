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
	if(![self cellIsSelected]){
		int		row = [controlView rowForItem:listObject];
		NSColor	*labelColor;
		
		//Label color.  If there is no label color we draw the background color (taking care of gridding if needed)
		//We cannot use the regular table background drawing for mockie cells because of the rounded corners
		//at the top and bottom of the groups.
		labelColor = [self labelColor];
		[(labelColor ? labelColor : [self backgroundColor]) set];
		
		//Draw the bottom corners rounded if this is the last cell in a group
		if(row >= [controlView numberOfRows]-1 || [controlView isExpandable:[controlView itemAtRow:row+1]]){
			[[NSBezierPath bezierPathWithRoundedBottomCorners:rect radius:MOCKIE_RADIUS] fill];
		}else{
			[NSBezierPath fillRect:rect];
		}
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if([self cellIsSelected]){
		AIGradient	*gradient = [AIGradient selectedControlGradientWithDirection:AIVertical];
		int			row = [controlView rowForItem:listObject];
		
		//Draw the bottom corners rounded if this is the last cell in a group
		if(row >= [controlView numberOfRows]-1 || [controlView isExpandable:[controlView itemAtRow:row+1]]){
			[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedBottomCorners:cellFrame radius:MOCKIE_RADIUS]];
		}else{
			[gradient drawInRect:cellFrame];
		}
	}
}

//Because of the rounded corners, we cannot rely on the outline view to draw our grid.  Return NO here to let
//the outline view know we'll be drawing the grid ourself
- (BOOL)drawGridBehindCell
{
	return(NO);
}

@end
