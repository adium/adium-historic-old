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

#import "AIFlexibleTableTextCell.h"

@interface AIFlexibleTableFramedTextCell : AIFlexibleTableTextCell {
    BOOL        drawTopDivider;
    BOOL		drawTop;
    BOOL		drawBottom;
    BOOL        drawSides;
    
    NSColor 	*borderColorOpaque;
    NSColor		*bubbleColorOpaque;
    NSColor		*dividerColorOpaque;
    
    NSColor 	*borderColor;
    NSColor		*bubbleColor;
    NSColor		*dividerColor;
    
    int			framePadLeft;
    int			framePadRight;
    int			framePadTop;
    int			framePadBottom;
    
}
+ (AIFlexibleTableFramedTextCell *)cellWithAttributedString:(NSAttributedString *)inString;

- (id)initWithAttributedString:(NSAttributedString *)inString;

- (void)setInternalPaddingLeft:(int)inLeft top:(int)inTop right:(int)inRight bottom:(int)inBottom;
- (void)setDrawTopDivider:(BOOL)inDrawTopDivider;
- (void)setDrawTop:(BOOL)inDrawTop;
- (void)setDrawBottom:(BOOL)inDrawBottom;
- (void)setDrawSides:(BOOL)inDrawSides;

- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor borderColor:(NSColor *)inBorderColor dividerColor:(NSColor *)inDividerColor;
- (void)setFrameBackgroundColor:(NSColor *)inBubbleColor;

@end
