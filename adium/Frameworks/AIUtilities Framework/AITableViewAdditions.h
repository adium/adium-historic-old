/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@interface NSTableView (AITableViewAdditions)

- (int)indexOfTableColumn:(NSTableColumn *)inColumn;
- (int)indexOfTableColumnWithIdentifier:(id)inIdentifier;

@end

#ifndef MAC_OS_X_VERSION_10_4
@interface NSTableView (TigerCompatibility)
/* The column auto resizing style controls resizing in response to a table view frame change.
Compatability Note: This method replaces -setAutoresizesAllColumnsToFit:.
*/
typedef enum {
    /* Turn off column autoresizing
    */
    NSTableViewNoColumnAutoresizing = 0,
	
    /* Autoresize all columns by distributing equal shares of space simultaeously
    */
    NSTableViewUniformColumnAutoresizingStyle,
	
    /* Autoresize each table column one at a time.  Proceed to the next column when 
	the current column can no longer be autoresized (when it reaches maximum/minimum size).
    */
    NSTableViewSequentialColumnAutoresizingStyle,        // Start with the last autoresizable column, proceed to the first.
    NSTableViewReverseSequentialColumnAutoresizingStyle, // Start with the first autoresizable column, proceed to the last.
	
    /* Autoresize only one table column one at a time.  When that table column can no longer be
	resized, stop autoresizing.  Normally you should use one of the Sequential autoresizing
	modes instead.
    */
    NSTableViewLastColumnOnlyAutoresizingStyle,
    NSTableViewFirstColumnOnlyAutoresizingStyle
} NSTableViewColumnAutoresizingStyle;

- (void)setColumnAutoresizingStyle:(NSTableViewColumnAutoresizingStyle)style;

@end

@interface NSTableColumn (TigerCompatibility)
	enum {
    NSTableColumnNoResizing = 0, // Disallow any kind of resizing.
    NSTableColumnAutoresizingMask = ( 1 << 0 ),     // This column can be resized as the table is resized.
    NSTableColumnUserResizingMask = ( 1 << 1 ),     // The user can resize this column manually.
};

- (void)setResizingMask:(int)resizingMask;

@end
#endif