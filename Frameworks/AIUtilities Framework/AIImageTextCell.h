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

#import "AIGradientCell.h"

/*!
 * @class AIImageTextCell
 * @brief A cell which displays an image and one or two lines of text
 *
 * This <tt>AIGradientCell</tt> subclass displays in image on the left and one or two lines of text centered vertically in the space remaining for the cell
 */
@interface AIImageTextCell : AIGradientCell {
    NSFont 		*font;
    NSString	*subString;
	float		maxImageWidth;
}

/*
 * @brief Set the font for drawing the stringValue of the cell
 *
 * The set font is used for drawing the stringValue of the cell.
 * @param inFont The <tt>NSFont</tt> to use.
 */
- (void)setFont:(NSFont *)inFont;

/*
 * @brief Returns the font used for drawing the stringValue of the cell
 *
 * Returns the font used for drawing the stringValue of the cell
 * @return An <tt>NSFont</tt>
 */
- (NSFont *)font;

/*
 * @brief Set a string to be drawn underneath the stringValue of the cell
 *
 * If non-nil, this string will be drawn underneath the stringValue of the cell.  The two will, together, be vertically centered (when not present, the stringValue alone is vertically centered). It is drawn in with the system font, at size 10.
 */
- (void)setSubString:(NSString *)inSubString;

/*
 * @brief Set the maximum width of the image drawn on the left
 *
 * Set the maximum width of the image drawn on the left.  The default value is 24.
 */
- (void)setMaxImageWidth:(float)inMaxImageWidth;

@end
