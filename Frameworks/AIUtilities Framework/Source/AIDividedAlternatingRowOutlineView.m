/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2007, Christopher Harms  (Chris.Harms@gmail.com)                              |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIDividedAlternatingRowOutlineView.h"


@implementation AIDividedAlternatingRowOutlineView

#pragma mark Drawing
/*
 * @brief Draw a divider if wanted for this item
 */ 
- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect
{
	//Getting the object for this row
	id item = [[self dataSource] outlineView:self child:rowIndex ofItem:nil];
	AIDividerPosition dividerPosition = AIDividerPositionNone;
	
	//Does the dataSource know what we want to know?
	if ([[self dataSource] respondsToSelector:@selector(outlineView:dividerPositionForItem:)]) {
		//Position of the divider
		dividerPosition = [[self dataSource] outlineView:self dividerPositionForItem:item];
	}
	
	if (dividerPosition != AIDividerPositionIsDivider) {
		//Call [super drawRow:clipRect:]
		[super drawRow:rowIndex clipRect:clipRect];

		if (dividerPosition == AIDividerPositionNone) {
			//We don't need you here, anymore
			return;
		}
	}
	
	//Set-up context
	[NSGraphicsContext saveGraphicsState];
	
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	NSRect rowRect = [self rectOfRow:rowIndex];
	
	//This could be done better. Ask the dataSource for color and width!
	[[NSColor headerColor] set];
	[NSBezierPath setDefaultLineWidth:1.5];

	//Drawing the divider
	switch (dividerPosition) {
		case AIDividerPositionAbove:
			//Divider above the current item
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rowRect)+5, NSMinY(rowRect))
									  toPoint:NSMakePoint(NSMaxX(rowRect)-5, NSMinY(rowRect))];
			break;
			
		case AIDividerPositionBelow:
			//Divider below the current item
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rowRect)+5, NSMaxY(rowRect))
									  toPoint:NSMakePoint(NSMaxX(rowRect)-5, NSMaxY(rowRect))];
			break;
			
		case AIDividerPositionIsDivider:
			//The item itself is the divider
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rowRect)+5, (NSMaxY(rowRect)+NSMinY(rowRect)) / 2.0)
									  toPoint:NSMakePoint(NSMaxX(rowRect)-5, (NSMaxY(rowRect)+NSMinY(rowRect)) / 2.0)];
			break;
			
		case AIDividerPositionNone:
			//This is not supposed to happen, but I dislike warnings
			break;
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

@end
