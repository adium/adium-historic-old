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

@class AIListObject, AISCLOutlineView;

@interface AIListCell : NSCell {
	NSView			*controlView;
    AIListObject	*listObject;
    BOOL			isGroup;
	
	NSTextAlignment	textAlignment;
	
	int				topSpacing;
	int				bottomSpacing;
	int				topPadding;
	int				bottomPadding;

	int				leftPadding;
	int				rightPadding;
	int				leftSpacing;
	int				rightSpacing;
	
	NSFont			*font;
	NSImage			*genericUserIcon;
}

- (void)setListObject:(AIListObject *)inObject;
- (BOOL)isGroup;
- (void)setControlView:(NSView *)inControlView;

//Display options 
- (void)setFont:(NSFont *)inFont;
- (NSFont *)font;
- (void)setTextAlignment:(NSTextAlignment)inAlignment;
- (NSTextAlignment)textAlignment;

//Cell sizing and padding
- (NSSize)cellSize;
- (void)setSplitVerticalSpacing:(int)inSpacing;
- (void)setTopSpacing:(int)inSpacing;
- (int)topSpacing;
- (void)setBottomSpacing:(int)inSpacing;
- (int)bottomSpacing;
- (void)setLeftSpacing:(int)inSpacing;
- (int)leftSpacing;
- (void)setRightSpacing:(int)inSpacing;
- (int)rightSpacing;
- (void)setSplitVerticalPadding:(int)inPadding;
- (void)setTopPadding:(int)inPadding;
- (void)setBottomPadding:(int)inPadding;
- (int)topPadding;
- (int)bottomPadding;
- (void)setLeftPadding:(int)inPadding;
- (int)leftPadding;
- (void)setRightPadding:(int)inPadding;
- (int)rightPadding;
	
//Drawing
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawSelectionWithFrame:(NSRect)rect;
- (void)drawBackgroundWithFrame:(NSRect)rect;
- (void)drawContentWithFrame:(NSRect)rect;
- (NSRect)drawDisplayNameWithFrame:(NSRect)inRect;
- (NSString *)labelString;
- (NSDictionary *)labelAttributes;
- (NSDictionary *)additionalLabelAttributes;
- (NSColor *)textColor;
- (BOOL)isSelectionInverted;
- (BOOL)drawGridBehindCell;

@end
