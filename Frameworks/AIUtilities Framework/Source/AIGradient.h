/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

/*!	@enum AIDirection
 *	A gradient direction.
 */
enum AIDirection {
	AIHorizontal = 0, //Horizontal
	AIVertical //Vertical
};

/*!
 * @class AIGradient
 * @brief Cocoa wrapper around lower level gradient drawing functions.  Draws simple gradients.
 */
@interface AIGradient : NSObject {
	enum AIDirection	 direction;
	NSColor				*color1;
	NSColor				*color2;
}

/*!
 * @brief Create a horiztonal or vertical gradient between two colors
 *
 * @param inColor1 The starting NSColor
 * @param inColor2 The ending NSColor
 * @param inDirection The <tt>AIDirection</tt> for the gradient
 * @result An autoreleased <tt>AIGadient</tt>
 */
+ (AIGradient*)gradientWithFirstColor:(NSColor*)inColor1
						  secondColor:(NSColor*)inColor2
							direction:(enum AIDirection)inDirection;

/*!
 * @brief Create a gradient for a selected control
 *
 * Use the system selectedControl color to create a gradient in the specified direction. This gradient is appropriate
 * for a Tiger-style selected highlight.
 *
 * @param inDirection The <tt>AIDirection</tt> for the gradient
 * @result An autoreleased <tt>AIGradient</tt> for a selected control
 */
+ (AIGradient*)selectedControlGradientWithDirection:(enum AIDirection)inDirection;

/*!
 * @brief Set the first (left or top) color
 *
 * @param inColor The first <tt>NSColor</tt>
 */
- (void)setFirstColor:(NSColor*)inColor;

/*!
 * @brief Return the first (left or top) color
 *
 * @result The first color.
 */
- (NSColor*)firstColor;

/*!
 * @brief Set the second (right or bottom) color
 *
 * @param inColor The second <tt>NSColor</tt>
 */
- (void)setSecondColor:(NSColor*)inColor;

/*!
 * @brief Return the second (right or bottom) color
 *
 * @result The second color
 */
- (NSColor*)secondColor;

/*!
 * @brief Set the direction for the gradient
 *
 * @param inDirection The <tt>AIDirection</tt> for the gradient
 */
- (void)setDirection:(enum AIDirection)inDirection;

/*!
 * @brief Return the direction for the gradient
 *
 * @result The <tt>AIDirection</tt> for the gradient
 */
- (enum AIDirection)direction;

/*!
 * @brief Draw the gradient in an <tt>NSRect</tt>
 *
 * @param rect The <tt>NSRect</tt> in which to render the gradient
 */
- (void)drawInRect:(NSRect)rect;

/*!
 * @brief Draw the gradient in an <tt>NSBezierPath</tt>
 *
 * The gradient will fill the specified path according to its winding rules, transformations, etc.
 *
 * @param inPath The <tt>NSBezierPath</tt> in which to render to gradient
 */
- (void)drawInBezierPath:(NSBezierPath *)inPath;

@end
