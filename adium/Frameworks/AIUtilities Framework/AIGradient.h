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

typedef enum {
	AIHorizontal = 0,
	AIVertical
} AIDirection;

@interface AIGradient : NSObject {
	AIDirection		direction;
	NSColor			*color1;
	NSColor			*color2;
}

+ (AIGradient*)gradientWithFirstColor:(NSColor*)inColor1
						  secondColor:(NSColor*)inColor2
							direction:(AIDirection)inDirection;
+ (AIGradient*)selectedControlGradientWithDirection:(AIDirection)inDirection;

- (void)setFirstColor:(NSColor*)inColor;
- (NSColor*)firstColor;

- (void)setSecondColor:(NSColor*)inColor;
- (NSColor*)secondColor;

- (void)setDirection:(AIDirection)inDirection;
- (AIDirection)direction;

- (void)drawInRect:(NSRect)rect;
- (void)drawInBezierPath:(NSBezierPath *)inPath;

@end
