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

/*!
 * @class AIAlternatingRowTableView
 * @brief An <tt>NSTableView</tt> subclass supporting alternating rows.
 *
 */
@interface AIAlternatingRowTableView : NSTableView {
	BOOL	acceptFirstMouse;
    BOOL	drawsAlternatingRows;
    NSColor	*alternatingRowColor;
}

/*!
 * @brief Set if the table view draws a grid, alternating by rows
 *
 * The grid will be drawn alternating between the background color and the color specified by setAlternatingRowColor:, which has a sane, light blue default.
 * @param flag YES if the alternating rows should be drawn
 */
- (void)setDrawsAlternatingRows:(BOOL)flag;

/*!
 * @brief Set the color used for drawing alternating row backgrounds.
 *
 * Ignored if drawsAlternatingRows is NO.
 * @param color The <tt>NSColor</tt> to use for drawing alternating row backgrounds.
 */
- (void)setAlternatingRowColor:(NSColor *)color;

/*!
 * @brief Set the return value of -(BOOL)acceptsFirstMouse
 *
 * See the <tt>NSView</tt> documentation for details.
 * @param acceptFirstMouse The new value to return for -(BOOL)acceptsFirstMouse
 */
- (void)setAcceptsFirstMouse:(BOOL)acceptFirstMouse;

@end

@interface NSObject (AITableViewDelegateDeleteSupport)
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView;
@end

