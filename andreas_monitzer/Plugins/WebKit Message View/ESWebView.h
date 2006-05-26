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

#import "WebKitPrivateDefinitions.h"

@interface ESWebView : WebView {
	id		draggingDelegate;
	BOOL	allowsDragAndDrop;
	BOOL	shouldForwardEvents;
	BOOL	transparentBackground;
}

/*!
 *	@brief Sets background transparency on/off
 */
- (void)setDrawsBackground:(BOOL)flag;

/*!
 *	@return whether background transparency is on or off
 */
- (BOOL)drawsBackground;

/*!
 *	@brief Sets the font family used in webkit's preferences for adium
 */
- (void)setFontFamily:(NSString *)familyName;

/*!
 *	@brief Gets the font family used in webkit's preferences for adium
 */
- (NSString *)fontFamily;

/*!
 *	@brief Sets the delegate used for drag and drop operations
 */
- (void)setDraggingDelegate:(id)inDelegate;

/*!
 *	@brief Sets whether drag and drop is allowed
 */
- (void)setAllowsDragAndDrop:(BOOL)flag;

/*!
 *	@brief ???
 */
- (void)setShouldForwardEvents:(BOOL)flag;

@end
