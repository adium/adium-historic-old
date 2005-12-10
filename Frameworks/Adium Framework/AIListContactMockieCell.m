/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIListContactMockieCell.h"
#import "AIListGroupMockieCell.h"
#import "AIListOutlineView.h"
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIGradient.h>

@implementation AIListContactMockieCell

- (id)init
{
	if ((self = [super init]))
	{
			lastBackgroundBezierPath = nil;
	}
	
	return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListContactMockieCell *newCell = [super copyWithZone:zone];
	newCell->lastBackgroundBezierPath = [lastBackgroundBezierPath retain];
	
	return newCell;
}

- (void)dealloc
{
	[lastBackgroundBezierPath release]; lastBackgroundBezierPath = nil;
	
	[super dealloc];
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if (![self cellIsSelected]) {
		int			row = [controlView rowForItem:listObject];
		unsigned	numberOfRows = [controlView numberOfRows];

		NSColor	*labelColor;
		
		//Label color.  If there is no label color we draw the background color (taking care of gridding if needed)
		//We cannot use the regular table background drawing for mockie cells because of the rounded corners
		//at the top and bottom of the groups.
		labelColor = [self labelColor];
		[(labelColor ? labelColor : [self backgroundColor]) set];

		[lastBackgroundBezierPath release];

		if (row == 0) {
			if (numberOfRows > 1) {
				//Draw the top corner rounded if this cell is the first cell in the outline view (only possible if its containing
				//group is not being displayed) but not also the last cell
				lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedTopCorners:rect radius:MOCKIE_RADIUS] retain];

			} else {
				//Draw the entire rect rounded if this cell is the first cell in the outline view (only possible if its containing
				//group is not being displayed) and also the last cell
				lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedRect:rect radius:MOCKIE_RADIUS] retain];
			}

			[lastBackgroundBezierPath fill];
			
		} else if (row >= (numberOfRows-1) || [controlView isExpandable:[controlView itemAtRow:row+1]]) {
			//Draw the bottom corners rounded if this is the last cell in a group
			lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedBottomCorners:rect radius:MOCKIE_RADIUS] retain];
			[lastBackgroundBezierPath fill];
			
		} else {
			//Cells which are not at the top or bottom are simply filled, no rounded path necessary
			lastBackgroundBezierPath = nil;

			[NSBezierPath fillRect:rect];
		}
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if ([self cellIsSelected]) {
		NSColor *highlightColor = [controlView highlightColor];
		AIGradient 	*gradient = highlightColor
			? [AIGradient gradientWithFirstColor:highlightColor
			                         secondColor:[highlightColor darkenAndAdjustSaturationBy:0.4] 
			                           direction:AIVertical]
			: [AIGradient selectedControlGradientWithDirection:AIVertical];
		int			row = [controlView rowForItem:listObject];
		unsigned	numberOfRows = [controlView numberOfRows];

		[lastBackgroundBezierPath release];

		if (row == 0) {
			if (numberOfRows > 1) {
				//Draw the top corner rounded if this cell is the first cell in the outline view (only possible if its containing
				//group is not being displayed) but not also the last cell
				lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedTopCorners:cellFrame radius:MOCKIE_RADIUS] retain];
				
			} else {
				//Draw the entire cellFrame rounded if this cell is the first cell in the outline view (only possible if its containing
				//group is not being displayed) and also the last cell
				lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedRect:cellFrame radius:MOCKIE_RADIUS] retain];
			}
			
			[gradient drawInBezierPath:lastBackgroundBezierPath];
			
		} else if (row >= (numberOfRows-1) || [controlView isExpandable:[controlView itemAtRow:row+1]]) {
			//Draw the bottom corners rounded if this is the last cell in a group
			lastBackgroundBezierPath = [[NSBezierPath bezierPathWithRoundedBottomCorners:cellFrame radius:MOCKIE_RADIUS] retain];
			[gradient drawInBezierPath:lastBackgroundBezierPath];
			
		} else {
			//Cells which are not at the top or bottom are simply filled, no rounded path necessary
			lastBackgroundBezierPath = nil;
			
			[gradient drawInRect:cellFrame];
		}
	}
}

//Because of the rounded corners, we cannot rely on the outline view to draw our grid.  Return NO here to let
//the outline view know we'll be drawing the grid ourself
- (BOOL)drawGridBehindCell
{
	return NO;
}

//User Icon, clipping to the last bezier path (which should have been part of this same drawing operation) if applicable
- (NSRect)drawUserIconInRect:(NSRect)inRect position:(IMAGE_POSITION)position
{
	NSRect	returnRect;
	
	if (lastBackgroundBezierPath) {
		[NSGraphicsContext saveGraphicsState];

		[lastBackgroundBezierPath addClip];
	
		returnRect = [super drawUserIconInRect:inRect position:position];

		[NSGraphicsContext restoreGraphicsState];
	
	} else {
		returnRect = [super drawUserIconInRect:inRect position:position];
	}
	
	return returnRect;
}

@end
