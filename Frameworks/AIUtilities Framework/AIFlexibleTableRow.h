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

@class AIFlexibleTableView;

@interface AIFlexibleTableRow : NSObject {
    AIFlexibleTableView	*tableView;
    NSArray		*cellArray;
    int			height;
    BOOL		spansRows;
    BOOL		isSpannedInto;
    id                  representedObject;
    float               headIndent;
    
    int                 tag;
}

+ (id)rowWithCells:(NSArray *)inCells representedObject:(id)inRepresentedObject;
- (void)drawAtPoint:(NSPoint)point visibleRect:(NSRect)visibleRect inView:(NSView *)controlView;
- (BOOL)resetCursorRectsAtOffset:(NSPoint)offset visibleRect:(NSRect)visibleRect inView:(NSView *)controlView;
- (void)updateSpanningAndResizeRow:(BOOL)resize;
- (BOOL)spansRows;
- (BOOL)isSpannedInto;
- (id)representedObject;

- (id)cellWithClass:(Class)theClass;
- (id)lastCellWithClass:(Class)theClass;
- (NSArray *)cellsWithClass:(Class)theClass;

- (BOOL)handleMouseDownEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset;
- (NSArray *)menuItemsForEvent:(NSEvent *)theEvent atPoint:(NSPoint)inPoint offset:(NSPoint)inOffset;
- (void)selectContentFrom:(NSPoint)source to:(NSPoint)dest offset:(NSPoint)inOffset mode:(int)selectMode;
- (void)deselectContent;
- (NSAttributedString *)selectedString;
- (BOOL)pointIsSelected:(NSPoint)inPoint offset:(NSPoint)inOffset;

- (int)sizeRowForWidth:(int)inWidth;
- (int)height;
- (void)setHeadIndent:(float)inHeadIndent;
- (float)headIndent;

- (void)setTableView:(AIFlexibleTableView *)inView;
- (AIFlexibleTableView *)tableView;

- (void)setTag:(int)inTag;
- (int)tag;

- (void)setOpacity:(float)opacity;
@end
