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

#import <Cocoa/Cocoa.h>

@class AIFlexibleTableView, AIFlexibleTableColumn;

@interface AIFlexibleTableCell : NSCell {
    AIFlexibleTableView	*tableView;

    //Background
    NSColor 		*backgroundColor;
    NSColor 		*gradientColor;

    //Padding
    int			leftPadding;
    int			rightPadding;
    int			topPadding;
    int			bottomPadding;

    //Size / Drawing
    BOOL		drawContents;
    NSSize		cellSize;
    NSRect		frame;
    NSColor		*dividerColor;
    BOOL		selected;
}

- (void)setTableView:(AIFlexibleTableView *)inView;

//Configure
- (void)setBackgroundColor:(NSColor *)inColor;
- (void)setBackgroundGradientFrom:(NSColor *)inColorA to:(NSColor *)inColorB;
- (void)setDrawContents:(BOOL)inValue;
- (void)setPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom;
- (void)setDividerColor:(NSColor *)inColor;
- (void)setSelected:(BOOL)inSelected;

//Access
- (NSSize)paddingInset;

//Selection
- (int)characterIndexAtPoint:(NSPoint)point;
- (BOOL)selectFrom:(int)sourceIndex to:(int)destIndex;
- (NSAttributedString *)stringFromIndex:(int)sourceIndex to:(int)destIndex;

//Cursor Tracking
- (BOOL)resetCursorRectsInView:(NSView *)controlView visibleRect:(NSRect)visibleRect;
- (BOOL)handleMouseDown:(NSEvent *)theEvent;
- (BOOL)usesCursorRects;

//Sizing
- (NSSize)cellSize;
- (void)sizeCellForWidth:(float)inWidth;

//Drawing
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)setFrame:(NSRect)inFrame;
- (NSRect)frame;

@end