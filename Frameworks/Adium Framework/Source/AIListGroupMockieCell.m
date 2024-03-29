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

#import <Adium/AIListGroupMockieCell.h>
#import <Adium/AIListOutlineView.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIGradient.h>
#import <AIUtilities/AIColorAdditions.h>

@implementation AIListGroupMockieCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListGroupMockieCell *newCell = [super copyWithZone:zone];
	
	for (int i = 0; i < NUMBER_OF_GROUP_STATES; i++) {
		newCell->_mockieGradient[i] = [_mockieGradient[i] retain];
	}
	
	return newCell;
}

//Init
- (id)init
{
	if ((self = [super init]))
	{
		for (int i = 0; i < NUMBER_OF_GROUP_STATES; i++) {
			_mockieGradient[i] = nil;
		}
	}
	
	return self;
}

//Dealloc
- (void)dealloc
{
	[self flushGradientCache];
	[super dealloc];
}

//Draw a regular mockie background for our cell if gradient background drawing is disabled
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	if (drawsBackground) {
		[super drawBackgroundWithFrame:rect];
	} else {
		if (![self cellIsSelected]) {
			[[self backgroundColor] set];
			if ([controlView isItemExpanded:listObject]) {
				[[NSBezierPath bezierPathWithRoundedTopCorners:rect radius:MOCKIE_RADIUS] fill];
			} else {
				[[NSBezierPath bezierPathWithRoundedRect:rect radius:MOCKIE_RADIUS] fill];
			}
		}
	}
}

//Draw a custom selection
- (void)drawSelectionWithFrame:(NSRect)cellFrame
{
	if ([self cellIsSelected]) {
		NSColor *highlightColor = [controlView highlightColor];
		AIGradient 	*gradient = (highlightColor ?
								 [AIGradient gradientWithFirstColor:highlightColor
														secondColor:[highlightColor darkenAndAdjustSaturationBy:0.4] 
														  direction:AIVertical] :
								 [AIGradient selectedControlGradientWithDirection:AIVertical]);

		if ([controlView isItemExpanded:listObject]) {
			[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedTopCorners:cellFrame radius:MOCKIE_RADIUS]];
		} else {
			[gradient drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:cellFrame radius:MOCKIE_RADIUS]];
		}
	}
}

//Remake of the cachedGradient method in AIListGroupCell, except supporting 2 gradients depending on group state
- (NSImage *)cachedGradient:(NSSize)inSize
{
	AIGroupState state = ([controlView isItemExpanded:listObject] ? AIGroupExpanded : AIGroupCollapsed);

	if (!_mockieGradient[state] || !NSEqualSizes(inSize,_mockieGradientSize[state])) {
		[_mockieGradient[state] release];
		_mockieGradient[state] = [[NSImage alloc] initWithSize:inSize];
		_mockieGradientSize[state] = inSize;
		
		[_mockieGradient[state] lockFocus];
		[self drawBackgroundGradientInRect:NSMakeRect(0,0,inSize.width,inSize.height)];
		[_mockieGradient[state] unlockFocus];
	}
	
	return _mockieGradient[state];
}

//Remake of flushGradientCache, supporting 2 gradients depending on group state
- (void)flushGradientCache
{
	for (int i = 0; i < NUMBER_OF_GROUP_STATES; i++) {
		[_mockieGradient[i] release]; _mockieGradient[i] = nil;
		_mockieGradientSize[i] = NSMakeSize(0,0);
	}
}

//Draw our background gradient.  For collapsed groups we draw the caps rounded, for expanded groups we only round the
//upper corners so the group smoothly transitions to the contact below it.
- (void)drawBackgroundGradientInRect:(NSRect)rect
{
	if ([controlView isItemExpanded:listObject]) {
		[[self backgroundGradient] drawInBezierPath:[NSBezierPath bezierPathWithRoundedTopCorners:rect radius:MOCKIE_RADIUS]];
	} else {
		[[self backgroundGradient] drawInBezierPath:[NSBezierPath bezierPathWithRoundedRect:rect radius:MOCKIE_RADIUS]];
	}
}

//Because of the rounded corners, we cannot rely on the outline view to draw our grid.  Return NO here to let
//the outline view know we'll be drawing the grid ourself
- (BOOL)drawGridBehindCell
{
	return NO;
}

@end
