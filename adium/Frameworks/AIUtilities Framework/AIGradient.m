/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AIGradient.h"

@interface AIGradient (PRIVATE)

- (id)initWithFirstColor:(NSColor*)inColor1
			 secondColor:(NSColor*)inColor2
			   direction:(AIDirection)inDirection;
- (void)_drawInRect:(NSRect)inRect useTransparency:(BOOL)useTransparency;

@end

@implementation AIGradient

#pragma mark Class Initialization
+ (AIGradient*)gradientWithFirstColor:(NSColor*)inColor1
						  secondColor:(NSColor*)inColor2
							direction:(AIDirection)inDirection
{
	return ([[[self alloc] initWithFirstColor:inColor1 secondColor:inColor2 direction:inDirection] autorelease]);
}

+ (AIGradient*)selectedControlGradientWithDirection:(AIDirection)inDirection
{
	NSColor *selectedColor = [NSColor alternateSelectedControlColor];
	
	return ([self gradientWithFirstColor:[selectedColor darkenAndAdjustSaturationBy:-0.1] secondColor:[selectedColor darkenAndAdjustSaturationBy:0.1] direction:inDirection]);
}

- (void)dealloc {
	[color1 release];
	[color2 release];
	[super dealloc];
}

#pragma mark Private

- (id)initWithFirstColor:(NSColor*)inColor1
			 secondColor:(NSColor*)inColor2
			   direction:(AIDirection)inDirection
{
	if (self = [self init]) {		
		[self setFirstColor:inColor1];
		[self setSecondColor:inColor2];
		[self setDirection:inDirection];
	}
	return self;
}

- (void)_drawInRect:(NSRect)inRect useTransparency:(BOOL)useTransparency
{
	NSColor *currentColor;
	NSColor *newColor1;
	NSColor *newColor2;
	float   fraction;
	int		x;
	
	if (useTransparency) {
		newColor1 = color1;
		newColor2 = color2;
	} else {
		newColor1 = [color1 colorWithAlphaComponent:1.0];
		newColor2 = [color2 colorWithAlphaComponent:1.0];
	}
	
	if (direction == AIVertical) {
		for (x=0;x<inRect.size.height;x++)
		{
			NSRect newRect = NSMakeRect(inRect.origin.x,inRect.origin.y + x,inRect.size.width,1);
			fraction = (float)(x / inRect.size.height);
			
			currentColor = [newColor1 blendedColorWithFraction:fraction ofColor:newColor2];
			[currentColor set];
			NSRectFillUsingOperation(newRect, NSCompositeSourceAtop);
		}
	} else {
		for (x=0;x<inRect.size.width;x++)
		{
			NSRect newRect = NSMakeRect(inRect.origin.x + x,inRect.origin.y,1,inRect.size.height);
			fraction = (float)(x / inRect.size.width);
			
			currentColor = [newColor1 blendedColorWithFraction:fraction ofColor:newColor2];
			[currentColor set];
			NSRectFillUsingOperation(newRect, NSCompositeSourceAtop);
		}
	}
}

#pragma mark Accessor Methods

- (void)setFirstColor:(NSColor*)inColor
{
	if (color1) {
		[color1 release]; color1 = nil;
	}
	color1 = [inColor retain];
}
- (NSColor*)firstColor
{
	return color1;
}

- (void)setSecondColor:(NSColor*)inColor
{
	if (color2) {
		[color2 release]; color2 = nil;
	}
	color2 = [inColor retain];
}
- (NSColor*)secondColor
{
	return color1;
}

- (void)setDirection:(AIDirection)inDirection
{
	direction = inDirection;
}
- (AIDirection)direction
{
	return direction;
}

#pragma mark Drawing

- (void)drawInRect:(NSRect)rect
{
	[self _drawInRect:rect useTransparency:YES];
}

- (void)drawInBezierPath:(NSBezierPath *)inPath fraction:(float)inFraction
{
	NSRect				inPathBounds = [inPath bounds];
	NSSize				inPathBoundsSize = inPathBounds.size;
	
	if ( (inPathBoundsSize.width > 0) && (inPathBoundsSize.height > 0) ) {
		
		NSImage				*image = [[NSImage alloc] initWithSize:inPathBounds.size];
		NSAffineTransform   *trans = [NSAffineTransform transform];
		NSBezierPath		*tempPath = [inPath copy];
		NSPoint				keepPoint = inPathBounds.origin;
		
		[trans translateXBy:(-1.0f * keepPoint.x) yBy:(-1.0f * keepPoint.y)];
		[tempPath transformUsingAffineTransform:trans];
		
		[image lockFocus];
		[tempPath fill];
		[self _drawInRect:[tempPath bounds] useTransparency:NO];
		[image unlockFocus];
		
		[image setFlipped:NO];
		[image drawAtPoint:keepPoint 
				  fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
				 operation:NSCompositeSourceOver
				  fraction:inFraction];
		
		[image release];	
	}
}

@end
