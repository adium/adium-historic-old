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

- (id)init
{
	[super init];
	
	lastBackgroundBezierPath = nil;
	
	return(self);
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListContactMockieCell *newCell = [super copyWithZone:zone];
	newCell->lastBackgroundBezierPath = [lastBackgroundBezierPath retain];
	
	return(newCell);
}

- (void)dealloc
{
	[lastBackgroundBezierPath release]; lastBackgroundBezierPath = nil;
	
	[super dealloc];
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

		[lastBackgroundBezierPath release];

		//Draw the bottom corners rounded if this is the last cell in a group
		if(row >= [controlView numberOfRows]-1 || [controlView isExpandable:[controlView itemAtRow:row+1]]){
			lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedBottomCorners:rect radius:MOCKIE_RADIUS] retain];
			[lastBackgroundBezierPath fill];
		}else{
			lastBackgroundBezierPath = nil;

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
		
		[lastBackgroundBezierPath release];

		//Draw the bottom corners rounded if this is the last cell in a group
		if(row >= [controlView numberOfRows]-1 || [controlView isExpandable:[controlView itemAtRow:row+1]]){
			lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedBottomCorners:cellFrame radius:MOCKIE_RADIUS] retain];
			[gradient drawInBezierPath:lastBackgroundBezierPath];
		}else{
			lastBackgroundBezierPath = nil;
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

//User Icon, clipping to the last bezier path (which should have been part of this same drawing operation) if applicable
- (NSRect)drawUserIconInRect:(NSRect)inRect position:(IMAGE_POSITION)position
{
	NSRect	returnRect;
	
	if (lastBackgroundBezierPath){
		[NSGraphicsContext saveGraphicsState];

		[lastBackgroundBezierPath setClip];
	
		returnRect = [super drawUserIconInRect:inRect position:position];

		[NSGraphicsContext restoreGraphicsState];
	
	}else{
		returnRect = [super drawUserIconInRect:inRect position:position];
	}
	
	return(returnRect);
}

@end
