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

@class AIFlexibleTableView, AIFlexibleTableRow;

@interface AIFlexibleTableCell : NSCell {
    AIFlexibleTableRow	*tableRow;
    
    //Background
    NSColor 		*backgroundColor;

    //Padding
    int			leftPadding;
    int			rightPadding;
    int			topPadding;
    int			bottomPadding;

    int			rowSpan;
    BOOL		variableWidth;

    //Size / Drawing
    NSSize		contentSize;
    
    //Opacity
    float               opacity;
    BOOL                isOpaque;
}

- (void)setTableRow:(AIFlexibleTableRow *)inRow;
- (AIFlexibleTableRow *)tableRow;

//Configure
- (void)setBackgroundColor:(NSColor *)inColor;
- (void)setPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom;
- (void)setOpacity:(float)inOpacity;
- (NSColor *)contentBackgroundColor;

//Access
- (NSSize)paddingInset;

//Cursor Tracking
- (BOOL)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView;
- (BOOL)handleMouseDownEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset;
- (NSArray *)menuItemsForEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset;
- (void)selectContentFrom:(NSPoint)source to:(NSPoint)dest offset:(NSPoint)inOffset mode:(int)selectMode;
- (void)deselectContent;
- (NSAttributedString *)selectedString;
- (BOOL)pointIsSelected:(NSPoint)inPoint offset:(NSPoint)inOffset;

//Spanning
- (void)setRowSpan:(int)inRowSpan;
- (int)rowSpan;
- (BOOL)isSpannedInto;

//Sizing
- (NSSize)cellSize;
- (NSSize)contentSize;
- (void)setVariableWidth:(BOOL)inVariableWidth;
- (BOOL)variableWidth;
- (void)sizeCellForWidth:(float)inWidth;
- (int)sizeContentForWidth:(float)inWidth;

//Drawing
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawContentsWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

@end